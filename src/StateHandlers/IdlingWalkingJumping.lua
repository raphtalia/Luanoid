local CharacterState = require(script.Parent.Parent.CharacterState)

local Constants = require(script.Parent.Parent.Constants)
local FRAMERATE = Constants.FRAMERATE
local STIFFNESS = Constants.STIFFNESS
local DAMPING = Constants.DAMPING
local PRECISION = Constants.PRECISION
local POP_TIME = Constants.POP_TIME

local function StepSpring(framerate, position, velocity, destination, stiffness, damping, precision)
	local displacement = position - destination
	local springForce = -stiffness * displacement
	local dampForce = -damping * velocity

	local acceleration = springForce + dampForce
	local newVelocity = velocity + acceleration * framerate
	local newPosition = position + velocity * framerate

	if math.abs(newVelocity) < precision and math.abs(destination - newPosition) < precision then
		return destination, 0
	end

	return newPosition, newVelocity
end

local IdlingWalkingJumping = {}

function IdlingWalkingJumping.entered(characterController)
    local luanoid = characterController.Luanoid
    -- We get the state since we don't know if its Idling, Walking, or Jumping
    local curState = luanoid:GetState()
    luanoid.Animator:PlayAnimation(curState.Name)
    if curState == CharacterState.Jumping then
        luanoid.Jumping:Fire(true)
        local rootPart = luanoid.RootPart
        rootPart:ApplyImpulse(Vector3.new(0, luanoid.JumpPower * rootPart.AssemblyMass, 0))
    end
end

function IdlingWalkingJumping.leaving(characterController)
    local luanoid = characterController.Luanoid
    local curState = luanoid:GetState()
    luanoid.Animator:StopAnimation(curState.Name)
    if curState == CharacterState.Jumping then
        luanoid.Jumping:Fire(false)
    end
end

function IdlingWalkingJumping.step(characterController, dt)
    local luanoid = characterController.Luanoid
    local rootPart = luanoid.RootPart
    local hipHeight = luanoid.HipHeight
    local velocity = rootPart.AssemblyLinearVelocity
    local currentVelocityX = velocity.X
    local currentVelocityY = velocity.Y
    local currentVelocityZ = velocity.Z
    local mover = luanoid.Mover
    local aligner = luanoid.Aligner
    local curState = luanoid:GetState()
    local isJumping = curState == CharacterState.Jumping
    local upDir = characterController.UpDirection

    -- Inverting the X just works
    local lookDir = luanoid.LookDirection
    lookDir = Vector3.new(-lookDir.X, 0, lookDir.Z)

    if not isJumping or (isJumping and characterController.CanRedirectJump) then
        local groundPos = if isJumping then nil else characterController.RaycastResult.Position
        local targetVelocity = Vector3.new()

        local moveDir = luanoid.MoveDirection
        moveDir = Vector3.new(moveDir.X, 0, moveDir.Z) -- Would explode if Y wasn't 0
        if moveDir.Magnitude > 0 then
            targetVelocity = Vector3.new(moveDir.X, 0, moveDir.Z).Unit * luanoid.WalkSpeed
        end

        characterController.Stores.accumulatedTime = (characterController.Stores.accumulatedTime or 0) + dt

        while characterController.Stores.accumulatedTime >= FRAMERATE do
            characterController.Stores.accumulatedTime -= FRAMERATE

            currentVelocityX, characterController.Stores.currentAccelerationX = StepSpring(
                FRAMERATE,
                currentVelocityX,
                characterController.Stores.currentAccelerationX or 0,
                targetVelocity.X,
                STIFFNESS,
                DAMPING,
                PRECISION
            )

            currentVelocityZ, characterController.Stores.currentAccelerationZ = StepSpring(
                FRAMERATE,
                currentVelocityZ,
                characterController.Stores.currentAccelerationZ or 0,
                targetVelocity.Z,
                STIFFNESS,
                DAMPING,
                PRECISION
            )
        end

        local g = workspace.Gravity
        local aUp
        if not isJumping then
            local targetHeight = groundPos.Y + hipHeight + rootPart.Size.Y / 2
            local currentHeight = rootPart.Position.Y
            aUp = g + 2*((targetHeight - currentHeight) - currentVelocityY*POP_TIME)/(POP_TIME^2)
            local deltaHeight = math.max((targetHeight - currentHeight)*1.01, 0)
            deltaHeight = math.min(deltaHeight, hipHeight)
            local maxUpVelocity = math.sqrt(2.0*g*deltaHeight)
            local maxUpImpulse = math.max((maxUpVelocity - currentVelocityY)*60, 0)
            aUp = math.min(aUp, maxUpImpulse)
            aUp = math.max(-1, aUp)
        end

        local aX = characterController.Stores.currentAccelerationX
        local aZ = characterController.Stores.currentAccelerationZ

        if not isJumping then
            local normal = characterController.RaycastResult.Normal
            local maxSlopeAngle = math.rad(luanoid.MaxSlopeAngle)
            local maxInclineTan = math.tan(maxSlopeAngle)
            local maxInclineStartTan = math.tan(math.max(0, maxSlopeAngle - math.rad(2.5)))
            local steepness = math.clamp((Vector2.new(normal.X, normal.Z).Magnitude/normal.Y - maxInclineStartTan) / (maxInclineTan - maxInclineStartTan), 0, 1)
            if steepness > 0 then
                -- deflect control acceleration off slope normal, discarding the parallell component
                local aControl = Vector3.new(aX, 0, aZ)
                local dot = math.min(0, normal:Dot(aControl)) -- clamp below 0, don't subtract forces away from normal
                local aInto = normal*dot
                local aPerp = aControl - aInto
                local aNew = aPerp
                aNew = aControl:Lerp(aNew, steepness)
                aX, aZ = aNew.X, aNew.Z
                -- mass on a frictionless incline: net acceleration = g * sin(incline angle)
                local aGravity = Vector3.new(0, -g, 0)
                dot = math.min(0, normal:Dot(aGravity))
                aInto = normal*dot
                aPerp = aGravity - aInto
                aNew = aPerp
                aX, aZ = aX + aNew.X*steepness, aZ + aNew.Z*steepness
                aUp = aUp + aNew.Y*steepness
                aUp = math.max(0, aUp)
            end
        end

        mover.Enabled = true
        aligner.Enabled = true
        mover.Force = characterController:GetGravityForce() + Vector3.new(aX, if isJumping then 0 else aUp, aZ) * rootPart.AssemblyMass

        -- Look direction stuff
        if luanoid.AutoRotate and moveDir.Magnitude > 0 then
            luanoid.LookDirection = moveDir
        end

        aligner.Attachment0.CFrame = CFrame.lookAt(Vector3.new(), lookDir, upDir)

        if curState == CharacterState.Walking then
            local animationTrack = luanoid.Animator.AnimationTracks.Walking
            if animationTrack then
                animationTrack:AdjustSpeed(luanoid.WalkSpeed / 16)
            end
        end
    else
        mover.Enabled = false
        aligner.Enabled = true

        aligner.Attachment0.CFrame = CFrame.lookAt(Vector3.new(), lookDir, upDir)
    end
end

return IdlingWalkingJumping
