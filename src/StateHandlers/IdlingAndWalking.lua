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

local IdlingAndWalking = {}

function IdlingAndWalking.entered(stateController)
    local luanoid = stateController.Luanoid
    -- We get the state since we don't know if its Idling or Walking
    luanoid.Animator:PlayAnimation(luanoid:GetState().Name)
end

function IdlingAndWalking.leaving(stateController)
    local luanoid = stateController.Luanoid
    luanoid.Animator:StopAnimation(luanoid:GetState().Name)
end

function IdlingAndWalking.step(stateController, dt)
    local luanoid = stateController.Luanoid
    local rootPart = luanoid.RootPart
    local hipHeight = luanoid.HipHeight
    local velocity = rootPart.AssemblyLinearVelocity
    local currentVelocityX = velocity.X
    local currentVelocityY = velocity.Y
    local currentVelocityZ = velocity.Z
    local mover = luanoid.Mover
    local aligner = luanoid.Aligner
    local groundPos = stateController.RaycastResult.Position
    local targetVelocity = Vector3.new()

    local moveDir = luanoid.MoveDirection
    moveDir = Vector3.new(moveDir.X, 0, moveDir.Z) -- Would explode if Y wasn't 0
    if moveDir.Magnitude > 0 then
        targetVelocity = Vector3.new(moveDir.X, 0, moveDir.Z).Unit * luanoid.WalkSpeed
    end

    stateController.Stores.accumulatedTime = (stateController.Stores.accumulatedTime or 0) + dt

    while stateController.Stores.accumulatedTime >= FRAMERATE do
        stateController.Stores.accumulatedTime -= FRAMERATE

        currentVelocityX, stateController.Stores.currentAccelerationX = StepSpring(
            FRAMERATE,
            currentVelocityX,
            stateController.Stores.currentAccelerationX or 0,
            targetVelocity.X,
            STIFFNESS,
            DAMPING,
            PRECISION
        )

        currentVelocityZ, stateController.Stores.currentAccelerationZ = StepSpring(
            FRAMERATE,
            currentVelocityZ,
            stateController.Stores.currentAccelerationZ or 0,
            targetVelocity.Z,
            STIFFNESS,
            DAMPING,
            PRECISION
        )
    end

    local g = workspace.Gravity
    local targetHeight = groundPos.Y + hipHeight + rootPart.Size.Y / 2
    local currentHeight = rootPart.Position.Y
    local aUp = g + 2*((targetHeight - currentHeight) - currentVelocityY*POP_TIME)/(POP_TIME^2)
    local deltaHeight = math.max((targetHeight - currentHeight)*1.01, 0)
    deltaHeight = math.min(deltaHeight, hipHeight)
    local maxUpVelocity = math.sqrt(2.0*g*deltaHeight)
    local maxUpImpulse = math.max((maxUpVelocity - currentVelocityY)*60, 0)
    aUp = math.min(aUp, maxUpImpulse)
    aUp = math.max(-1, aUp)

    local aX = stateController.Stores.currentAccelerationX
    local aZ = stateController.Stores.currentAccelerationZ

    local normal = stateController.RaycastResult.Normal
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

    mover.Enabled = true
    aligner.Enabled = true
    mover.Force = Vector3.new(aX, aUp, aZ) * rootPart.AssemblyMass

    -- Look direction stuff
    if moveDir.Magnitude > 0 and luanoid.AutoRotate then
        luanoid.LookDirection = moveDir
    end

    local lookDir = luanoid.LookDirection
    if lookDir.Magnitude > 0 then
        -- Inverting the X just works
        aligner.Attachment0.CFrame = CFrame.lookAt(Vector3.new(), Vector3.new(-lookDir.X, 0, lookDir.Z))
    end

    local animationTrack = luanoid.Animator.AnimationTracks.Walking
    if animationTrack then
        animationTrack:AdjustSpeed(luanoid.WalkSpeed / 16)
    end
end

return IdlingAndWalking
