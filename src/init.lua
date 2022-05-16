local Players = game:GetService("Players")

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)
local t = require(script.Types).Luanoid
local Animator = require(script.Animator)
local CharacterController = require(script.CharacterController)
local CharacterState = require(script.CharacterState)
local FSM = require(script.FSM)

local StateHandlers = {
    Dead = require(script.StateHandlers.Dead),
    FallingPhysics = require(script.StateHandlers.FallingPhysics),
    IdlingWalkingJumping = require(script.StateHandlers.IdlingWalkingJumping),
}

local Constants = require(script.Constants)
local IS_SERVER = Constants.IS_SERVER
local IS_CLIENT = Constants.IS_CLIENT

local applyDescription = require(script.Util.applyDescription)
local buildRigFromAttachments = require(script.Util.buildRigFromAttachments)
local fixSuperclass = require(script.Util.fixSuperclass)

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

--[=[
    @class Luanoid
]=]
--[=[
    @within Luanoid
    @prop CharacterState EnumList<CharacterState>
]=]
local Luanoid = {
    CharacterState = CharacterState,
}
local LUANOID_METATABLE = {}
function LUANOID_METATABLE:__index(i)
    if i == "Name" then
        --[=[
            @within Luanoid
            @prop Name string
            A non-unique identifier of the Luanoid
        ]=]
        return self.Character.Name
    elseif i == "MoveDirection" then
        --[=[
            @within Luanoid
            @prop MoveDirection Vector3
            Describes the direction that the Luanoid is walking in, as a unit
            vector along the X/Z axis.
        ]=]
        return self.Character:GetAttribute("MoveDirection")
    elseif i == "LookDirection" then
        --[=[
            @within Luanoid
            @prop LookDirection Vector3
            Describes the direction that the Luanoid is facing, as a unit vector
            along the X/Z axis.
        ]=]
        return self.Character:GetAttribute("LookDirection")
    elseif i == "Health" then
        --[=[
            @within Luanoid
            @prop Health number
            Describes the current health of the Luanoid.
        ]=]
        return self.Character:GetAttribute("Health")
    elseif i == "MaxHealth" then
        --[=[
            @within Luanoid
            @prop MaxHealth number
            Describes the maximum health of the Luanoid.
        ]=]
        return self.Character:GetAttribute("MaxHealth")
    elseif i == "WalkSpeed" then
        --[=[
            @within Luanoid
            @prop WalkSpeed number
            A reference to a part whose position is trying to be reached by a
            Luanoid.
        ]=]
        return self.Character:GetAttribute("WalkSpeed")
    elseif i == "JumpPower" then
        --[=[
            @within Luanoid
            @prop JumpPower number
            Determines how much upwards force is applied to the Luanoid when
            jumping.
        ]=]
        return self.Character:GetAttribute("JumpPower")
    elseif i == "HipHeight" then
        --[=[
            @within Luanoid
            @prop HipHeight number
            Describes the maximum health of the Luanoid.
        ]=]
        return self.Character:GetAttribute("HipHeight")
    elseif i == "MaxSlopeAngle" then
        --[=[
            @within Luanoid
            @prop MaxSlopeAngle number
            Determines the distance off the ground the RootPart should be.
        ]=]
        return self.Character:GetAttribute("MaxSlopeAngle")
    elseif i == "AutoRotate" then
        --[=[
            @within Luanoid
            @prop AutoRotate boolean
            AutoRotate sets whether or not the Luanoid will automatically
            rotate to face in the direction they are moving in.
        ]=]
        return self.Character:GetAttribute("AutoRotate")
    elseif i == "Jump" then
        --[=[
            @within Luanoid
            @prop Jump boolean
            If set to true, it will cause the Luanoid to jump.
        ]=]
        return self.Character:GetAttribute("Jump")
    elseif i == "Animator" then
        --[=[
            @within Luanoid
            @readonly
            @prop Animator Animator
            A reference to the Animator responsible assigned to the Luanoid.
        ]=]
        return rawget(self, "_animator")
    elseif i == "CharacterController" then
        --[=[
            @within Luanoid
            @prop CharacterController CharacterController
            A reference to the CharacterController assigned to the Luanoid.
        ]=]
        return rawget(self, "_characterController")
    elseif i == "Character" then
        --[=[
            @within Luanoid
            @readonly
            @prop Character Model
            A model controlled by the Luanoid
        ]=]
        return rawget(self, "_character")
    elseif i == "Floor" then
        --[=[
            @within Luanoid
            @prop Floor BasePart
            A reference to the Instance the Luanoid is currently standing on.
            If the luanoid isn't standing on anything, the value of this
            property will be nil. Although this property is not read-only it
            should only be edited by StateControllers.
        ]=]
        return rawget(self, "_floor")
    elseif i == "FloorMaterial" then
        --[=[
            @within Luanoid
            @readonly
            @prop FloorMaterial Material
            Describes the Material that the Luanoid is currently standing on.
            If the Luanoid isn’t standing on anything, the value of this
            property will be Air.
        ]=]
        local floor = self.Floor
        return if floor then floor.Material else Enum.Material.Air
    elseif i == "Mover" then
        --[=[
            @within Luanoid
            @readonly
            @prop Mover VectorForce
            A force that is applied to the Luanoid’s RootPart to move it.
            Intended only for use in CharacterControllers.
        ]=]
        return self.RootPart.Mover
    elseif i == "Aligner" then
        --[=[
            @within Luanoid
            @readonly
            @prop Aligner AlignOrientation
            A force that is applied to the Luanoid’s RootPart to orient it.
            Intended only for use in CharacterControllers.
        ]=]
        return self.RootPart.Aligner
    elseif i == "RootPart" then
        --[=[
            @within Luanoid
            @readonly
            @prop RootPart BasePart
            A reference to the Luanoid's HumanoidRootPart. Despite Luanoids not
            having Humanoids the RootPart maintains Humanoid in its name for
            better compatibility.
        ]=]
        return self.Character:FindFirstChild("HumanoidRootPart")
    elseif i == "RigChanged" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop RigChanged Signal (character: Model)
            Fires after `SetRig()` finishes executing.
        ]=]
        return rawget(self, "_rigChanged")
    elseif i == "AccessoryAdded" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop AccessoryAdded Signal (accessory: Accessory | Model | BasePart)
            Fires after `AddAccessory()` finishes executing.
        ]=]
        return rawget(self, "_accessoryAdded")
    elseif i == "AccessoryRemoving" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop AccessoryRemoving Signal (accessory: Accessory | Model | BasePart)
            Fires after `RemoveAccessory()` finishes executing.
        ]=]
        return rawget(self, "_accessoryRemoving")
    elseif i == "Died" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop Died Signal (isDead: boolean)
            Fires after entering or while leaving `CharacterState.Dead`
        ]=]
        return rawget(self, "_died")
    elseif i == "FreeFalling" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop FreeFalling Signal (isFreeFalling: boolean)
            Fires after entering or while leaving `CharacterState.FreeFalling`
        ]=]
        return rawget(self, "_freeFalling")
    elseif i == "HealthChanged" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop HealthChanged Signal (newHealth: number)
            Fires after Health is changed
        ]=]
        return rawget(self, "_healthChanged")
    elseif i == "Jumping" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop Jumping Signal (isJumping: boolean)
            Fires after entering or while leaving `CharacterState.Jumping`
        ]=]
        return rawget(self, "_jumping")
    elseif i == "MoveToFinished" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop MoveToFinished Signal (success: boolean)
            Fires after a promise from `MoveTo()` resolves.
        ]=]
        return rawget(self, "_moveToFinished")
    elseif i == "Seated" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @unreleased
            @prop Seated Signal
        ]=]
        return rawget(self, "_seated")
    elseif i == "StateChanged" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop StateChanged Signal (newState: CharacterState)
            Fires after the Luanoid's state is changed.
        ]=]
        return rawget(self, "_stateChanged")
    elseif i == "Touched" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @unreleased
            @prop Touched Signal
        ]=]
        return rawget(self, "_touched")
    elseif i == "Destroying" then
        --[=[
            @within Luanoid
            @readonly
            @tag event
            @prop Destroying Signal
            Fires while `Destroy()` is executing.
        ]=]
        return rawget(self, "_destroying")
    else
        return LUANOID_METATABLE[i] or error(i.. " is not a valid member of Luanoid", 2)
    end
end
function LUANOID_METATABLE:__newindex(i, v)
    if i == "Name" then
        self.Character.Name = v
    elseif i == "MoveDirection" then
        t.MoveDirection(v)
        if v.Magnitude > 0 then
            -- Avoids NaN values
            v = v.Unit
        end
        self.Character:SetAttribute("MoveDirection", Vector3.new(v.X, 0, v.Z))
    elseif i == "LookDirection" then
        t.LookDirection(v)
        self.Character:SetAttribute("LookDirection", v)
    elseif i == "Health" then
        t.Health(v)
        self.Character:SetAttribute("Health", math.min(v, self.MaxHealth))
    elseif i == "MaxHealth" then
        t.MaxHealth(v)
        self.Character:SetAttribute("MaxHealth", v)
        self.Character:SetAttribute("Health", math.min(self.Health, v))
    elseif i == "WalkSpeed" then
        t.WalkSpeed(v)
        self.Character:SetAttribute("WalkSpeed", v)
    elseif i == "JumpPower" then
        t.JumpPower(v)
        self.Character:SetAttribute("JumpPower", v)
    elseif i == "HipHeight" then
        t.HipHeight(v)
        self.Character:SetAttribute("HipHeight", v)
    elseif i == "MaxSlopeAngle" then
        t.MaxSlopeAngle(v)
        self.Character:SetAttribute("MaxSlopeAngle", v)
    elseif i == "AutoRotate" then
        t.AutoRotate(v)
        self.Character:SetAttribute("AutoRotate", v)
    elseif i == "Jump" then
        t.Jump(v)
        self.Character:SetAttribute("Jump", v)
    elseif i == "Animator" then
        t.Animator(v)

        if self.Animator then
            self.Animator:StopAnimations()
        end

        rawset(self, "_animator", v)
    elseif i == "CharacterController" then
        t.CharacterController(v)

        if self.CharacterController then
            self.CharacterController:Stop()
        end

        rawset(self, "_characterController", v)
    elseif i == "Floor" then
        t.Floor(v)
        rawset(self, "_floor", v)
        self.Character:SetAttribute("FloorMaterial", if v then v.Material.Name else "Air")
    else
        error(i.. " is not a valid member of Luanoid or is unassignable", 2)
    end
end

function Luanoid:constructor(existingCharacter)
    -- roblox-ts compatibility
    t.new(existingCharacter)

    fixSuperclass(self, Luanoid, LUANOID_METATABLE)

    --[=[
        @within Luanoid
        @private
        @prop RigParts {BasePart}
        List of parts in the current rig.
    ]=]
    rawset(self, "RigParts", {})
    --[=[
        @within Luanoid
        @private
        @prop RigMotors6Ds {Motor6D}
        List of motors in the current rig.
    ]=]
    rawset(self, "RigMotors6Ds", {})
    --[=[
        @within Luanoid
        @private
        @prop MoveToPromise Promise<boolean>
        Promise for the current MoveTo operation.
    ]=]
    -- rawset(self, "MoveToPromise", nil)
    rawset(self, "_character", existingCharacter or Instance.new("Model"))
    -- rawset(self, "_floor", nil)
    rawset(self, "_characterState", CharacterState.Idling)
    -- rawset(self, "_animator", nil)
    -- rawset(self, "_characterController", nil)

    rawset(self, "_rigChanged", Signal.new())
    rawset(self, "_accessoryAdded", Signal.new())
    rawset(self, "_accessoryRemoving", Signal.new())
    rawset(self, "_died", Signal.new())
    rawset(self, "_freeFalling", Signal.new())
    rawset(self, "_healthChanged", Signal.new())
    rawset(self, "_jumping", Signal.new())
    rawset(self, "_moveToFinished", Signal.new())
    rawset(self, "_seated", Signal.new()) -- TODO: Implement
    rawset(self, "_stateChanged", Signal.new())
    rawset(self, "_touched", Signal.new()) -- TODO: Implement
    rawset(self, "_destroying", Signal.new())

    local character = self.Character
    character:SetAttribute("MoveDirection", Vector3.new())
    character:SetAttribute("LookDirection", Vector3.new(0, 0, -1)) -- TODO: Default this to the RootPart's front direction
    character:SetAttribute("Health", 100)
    character:SetAttribute("MaxHealth", 100)
    character:SetAttribute("WalkSpeed", 16)
    character:SetAttribute("JumpPower", 50)
    character:SetAttribute("HipHeight", 2)
    character:SetAttribute("MaxSlopeAngle", 89)
    character:SetAttribute("AutoRotate", true)
    character:SetAttribute("Jump", false)

    if not existingCharacter then
        local moveDirAttachment = Instance.new("Attachment")
        moveDirAttachment.Name = "MoveDirection"

        local humanoidRootPart = Instance.new("Part")
        humanoidRootPart.Name = "HumanoidRootPart"
        humanoidRootPart.Transparency = 1
        humanoidRootPart.Size = Vector3.new(1, 1, 1)
        humanoidRootPart.RootPriority = 127
        humanoidRootPart.Parent = character

        local mover = Instance.new("VectorForce")
        mover.Name = "Mover"
        mover.RelativeTo = Enum.ActuatorRelativeTo.World
        mover.ApplyAtCenterOfMass = true
        mover.Attachment0 = moveDirAttachment
        mover.Force = Vector3.new()
        mover.Parent = humanoidRootPart

        local aligner = Instance.new("AlignOrientation")
        aligner.Name = "Aligner"
        aligner.Mode = Enum.OrientationAlignmentMode.OneAttachment
        aligner.Responsiveness = 20
        aligner.Attachment0 = moveDirAttachment
        aligner.Parent = humanoidRootPart

        moveDirAttachment.Parent = humanoidRootPart

        local accessoriesFolder = Instance.new("Folder")
        accessoriesFolder.Name = "Accessories"
        accessoriesFolder.Parent = character

        self.Name = "Luanoid"
    end

    self.Animator = Animator.new(self)

    local characterController = CharacterController.new(self, CharacterState, FSM)
    characterController.States[CharacterState.Physics].Entered:Connect(StateHandlers.FallingPhysics.entered)
    characterController.States[CharacterState.Physics].Leaving:Connect(StateHandlers.FallingPhysics.leaving)
    characterController.States[CharacterState.Physics].Step:Connect(StateHandlers.FallingPhysics.step)
    characterController.States[CharacterState.Idling].Entered:Connect(StateHandlers.IdlingWalkingJumping.entered)
    characterController.States[CharacterState.Idling].Leaving:Connect(StateHandlers.IdlingWalkingJumping.leaving)
    characterController.States[CharacterState.Idling].Step:Connect(StateHandlers.IdlingWalkingJumping.step)
    characterController.States[CharacterState.Walking].Entered:Connect(StateHandlers.IdlingWalkingJumping.entered)
    characterController.States[CharacterState.Walking].Leaving:Connect(StateHandlers.IdlingWalkingJumping.leaving)
    characterController.States[CharacterState.Walking].Step:Connect(StateHandlers.IdlingWalkingJumping.step)
    characterController.States[CharacterState.Jumping].Entered:Connect(StateHandlers.IdlingWalkingJumping.entered)
    characterController.States[CharacterState.Jumping].Leaving:Connect(StateHandlers.IdlingWalkingJumping.leaving)
    characterController.States[CharacterState.Jumping].Step:Connect(StateHandlers.IdlingWalkingJumping.step)
    characterController.States[CharacterState.Falling].Entered:Connect(StateHandlers.FallingPhysics.entered)
    characterController.States[CharacterState.Falling].Leaving:Connect(StateHandlers.FallingPhysics.leaving)
    characterController.States[CharacterState.Falling].Step:Connect(StateHandlers.FallingPhysics.step)
    characterController.States[CharacterState.Dead].Entered:Connect(StateHandlers.Dead.entered)
    characterController.States[CharacterState.Dead].Leaving:Connect(StateHandlers.Dead.leaving)
    characterController.States[CharacterState.Dead].Step:Connect(StateHandlers.Dead.step)
    self.CharacterController = characterController

    local localNetworkOwner
    if IS_CLIENT then
        localNetworkOwner = Players.LocalPlayer
    end

    if not self:GetNetworkOwner() then
        --[[
            If we are on a Client the localNetworkOwner is the player while on
            the server the localNetworkOwner is nil which represents the
            server.
        ]]
        self:SetNetworkOwner(localNetworkOwner)
    end

    -- TODO: Replace when Destroying is enabled
    character.AncestryChanged:Connect(function()
        if not character:IsDescendantOf(game.Workspace) then
            self.CharacterController:Stop()
        end
    end)

    character:GetAttributeChangedSignal("Health"):Connect(function()
        self.HealthChanged:Fire(character:GetAttribute("Health"))
    end)
end

--[=[
    @within Luanoid
    Creates a new Luanoid.

    @param existingCharacter Model
    @return Luanoid
]=]
function Luanoid.new(existingCharacter)
    local self = setmetatable({}, LUANOID_METATABLE)
    Luanoid.constructor(self, existingCharacter)

    return self
end

--[=[
    @within Luanoid
    @method Destroy
    Destroys the Luanoid.
]=]
function LUANOID_METATABLE:Destroy()
    self.Destroying:Fire()
    self.CharacterController:Stop()
    self.Character:Destroy()
end

--[=[
    @within Luanoid
    @method SetRig
    @param rig Model
    Assigns a rigged model as the Luanoid's character.
]=]
function LUANOID_METATABLE:SetRig(rig)
    t.SetRig(rig)

    self:RemoveRig()

    local character = self.Character
    local rootPart = self.RootPart
    local rigParts = rawget(self, "RigParts")
    local motor6ds = rawget(self, "RigMotors6Ds")
    local accessories = {}

    for _,accessory in ipairs(rig:GetChildren()) do
        if accessory:IsA("Accessory") then
            table.insert(accessories, accessory)
            accessory.Parent = nil
        end
    end

    for _,v in ipairs(rig:GetDescendants()) do
        if v.Parent.Name == "HumanoidRootPart" then
            v.Parent = rootPart
        end
        if v:IsA("Motor6D") then
            table.insert(motor6ds, v)

            if v.Part0.Name == "HumanoidRootPart" then
                v.Part0 = rootPart
            end
            if v.Part1.Name == "HumanoidRootPart" then
                v.Part1 = rootPart
            end
        elseif v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            table.insert(rigParts, v)
            v.CanCollide = false
            v.Parent = character
        end
    end
    rootPart.Size = rig.HumanoidRootPart.Size
    rig:Destroy()

    for _,accessory in ipairs(accessories) do
        self:AddAccessory(accessory)
    end

    self.RigChanged:Fire(character)
end

--[=[
    @within Luanoid
    @method RemoveRig
    Removes the Luanoid's current character rig.
]=]
function LUANOID_METATABLE:RemoveRig()
    local rigParts = rawget(self, "RigParts")

    for _,limb in ipairs(rigParts) do
        limb:Destroy()
    end

    table.clear(rigParts)
    table.clear(rawget(self, "RigMotors6Ds"))
end

--[=[
    @within Luanoid
    @method ApplyDescription
    @param humanoidDescription HumanoidDescription
    @param rigType HumanoidRigType
    Makes the character's look match that of the passed in HumanoidDescription.
    If no `rigType` is provided a new rig will not be applied. Setting
    `HumanoidDescription.Shirt` and `HumanoidDescription.Pants` to any negative
    value will have it ignore the rig's current shirt and pants rather than
    clearing them.
]=]
function LUANOID_METATABLE:ApplyDescription(humanoidDescription, rigType)
    t.ApplyDescription(humanoidDescription, rigType)
    applyDescription(self, humanoidDescription, rigType)
end

--[=[
    @within Luanoid
    @unreleased
    @method GetAppliedDescription
    @return HumanoidDescription
    Returns HumanoidDescription which describes its current look.
]=]
-- function LUANOID_METATABLE:GetAppliedDescription()
--     TODO: Implement
-- end

--[=[
    @within Luanoid
    @method BuildRigFromAttachments
    Assembles a tree of Motor6D joints by attaching together Attachment objects
    in a Luanoid's character.
]=]
function LUANOID_METATABLE:BuildRigFromAttachments()
    buildRigFromAttachments(self.Character)
end

--[=[
    @within Luanoid
    @method TakeDamage
    @param damage number
    Lowers the health of the Luanoid by the given positive amount.
]=]
function LUANOID_METATABLE:TakeDamage(damage)
    t.TakeDamage(damage)
    self.Health = math.max(self.Health - damage, 0)
end

--[=[
    @within Luanoid
    @method Move
    @param moveDirection Vector3
    @param relativeToCamera boolean?
    Causes the Lumanoid to walk in the given direction.
]=]
function LUANOID_METATABLE:Move(moveDirection, relativeToCamera)
    t.Move(moveDirection, relativeToCamera)
    if relativeToCamera then
        self.MoveDirection = CurrentCamera.CFrame:VectorToWorldSpace(moveDirection)
    else
        self.MoveDirection = moveDirection
    end
end

--[=[
    @within Luanoid
    @method MoveTo
    @param location Vector3?
    @param part BasePart?
    @param targetRadius number?
    @param timeout number?
    @return Promise<boolean>
    Causes the Luanoid to attempt to walk to the given location and part. Use a
    timeout of 0 for no timeout. The returned promise can also be cancelled.
]=]
function LUANOID_METATABLE:MoveTo(location, part, targetRadius, timeout)
    t.MoveTo(location, part, targetRadius, timeout)
    targetRadius = targetRadius or 2
    timeout = timeout or 8

    local currentMoveTo = rawget(self, "MoveToPromise")
    if currentMoveTo then
        currentMoveTo:cancel()
        rawset(self, "MoveToPromise", nil)
    end

    return Promise.new(function(resolve, _, onCancel)
        local rootPart = self.RootPart
        local moveToStartTick = tick()

        local distance
        repeat
            local target = if location and part then (part.CFrame * location).Position else location or part.Position
            distance = ((rootPart.Position - Vector3.new(0, rootPart.Size.Y / 2 + self.HipHeight, 0)) - target).Magnitude

            self:Move((target - rootPart.Position).Unit)

            task.wait()
        until onCancel() or distance < targetRadius or (timeout > 0 and tick() - moveToStartTick > timeout)

        self:Move(Vector3.new())
        rawset(self, "MoveToPromise", nil)

        if distance < targetRadius then
            resolve(true)
            self.MoveToFinished:Fire(true)
        else
            resolve(false)
            self.MoveToFinished:Fire(false)
        end
    end)
end

--[=[
    @within Luanoid
    @method AddAccessory
    @param accessory Accessory | Model | BasePart
    @param base (Attachment | BasePart)?
    @param pivot CFrame?
    Adds an accessory to the Luanoid's character.
]=]
function LUANOID_METATABLE:AddAccessory(accessory, base, pivot)
    t.AddAccessory(accessory, base, pivot)
    if #rawget(self, "RigParts") == 0 then
        error("Rig must be mounted first before adding accessories", 2)
    end
    local character = self.Character

    local existingWeldConstraint = accessory:FindFirstChild("AccessoryWeldConstraint", true)
    if existingWeldConstraint then
        existingWeldConstraint:Destroy()
    end

    local primaryPart = accessory
    if accessory:IsA("Accessory") then
        -- Accessory is a Roblox accessory
        primaryPart = accessory.Handle
        local attachment0 = primaryPart:FindFirstChildWhichIsA("Attachment")
        local attachment1 = self.Character:FindFirstChild(attachment0.Name, true)
        base = attachment1.Parent

        primaryPart.CanCollide = false
        primaryPart.CFrame = attachment1.WorldCFrame * attachment0.CFrame:Inverse()
    else
        -- Accessory is a BasePart or Model
        if accessory:IsA("Model") then
            primaryPart = accessory.PrimaryPart
        end
        if not pivot then
            if base:IsA("BasePart") then
                pivot = base.CFrame
            elseif base:IsA("Attachment") then
                pivot = base.WorldCFrame
                base = base.Parent
            end
        end

        accessory:PivotTo(pivot)
    end

    local weldConstraint = Instance.new("WeldConstraint")
    weldConstraint.Name = "AccessoryWeldConstraint"
    weldConstraint.Part0 = primaryPart
    weldConstraint.Part1 = base
    weldConstraint.Parent = primaryPart
    accessory.Parent = character.Accessories

    self.AccessoryAdded:Fire(accessory)

    return self
end

--[=[
    @within Luanoid
    @method RemoveAccessory
    @param accessory Accessory | Model | BasePart
    Removes an accessory from the Luanoid's character.
]=]
function LUANOID_METATABLE:RemoveAccessory(accessory)
    t.RemoveAccessory(accessory)
    if accessory.Parent == self.Character.Accessories then
        self.AccessoryRemoving:Fire(accessory)
        accessory:Destroy()
    else
        error("Accessory is not attached to this Luanoid", 2)
    end
end

--[=[
    @within Luanoid
    @method GetAccessories
    @return {(Accessory | Model | BasePart)}
    Returns a list of all accessories attached to the Luanoid.
]=]
function LUANOID_METATABLE:GetAccessories(attachment)
    t.GetAccessories(attachment)
    if attachment then
        local accessories = {}

        for _,accessory in ipairs(self.Character.Accessories:GetChildren()) do
            local weldConstraint = accessory:FindFirstChild("AccessoryWeldConstraint")
            if weldConstraint.Part0 == attachment.Parent or weldConstraint.Part1 == attachment.Parent then
                table.insert(accessories, accessory)
            end
        end

        return accessories
    else
        return self.Character.Accessories:GetChildren()
    end
end

--[=[
    @within Luanoid
    @method RemoveAccessories
    Removes all accessories from the Luanoid.
]=]
function LUANOID_METATABLE:RemoveAccessories()
    for _,accessory in ipairs(self.Character.Accessories:GetChildren()) do
        self.AccessoryRemoving:Fire(accessory)
        accessory:Destroy()
    end
end

--[=[
    @within Luanoid
    @method GetNetworkOwner
    @return Player
    Returns the current player who is the network owner of the Luanoid, or nil in
    case of the server.
]=]
function LUANOID_METATABLE:GetNetworkOwner()
    local owner = self.Character:GetAttribute("NetworkOwner")
    return if owner then Players[owner] else nil
end

--[=[
    @within Luanoid
    @method SetNetworkOwner
    @param player Player
    Sets the given player as network owner for this Luanoid. When `player` is
    nil, the server will be the owner instead of a player.
]=]
function LUANOID_METATABLE:SetNetworkOwner(owner)
    t.SetNetworkOwner(owner)

    local character = self.Character
    character:SetAttribute("NetworkOwner", if owner then owner.Name else nil)
    if character:IsDescendantOf(workspace) and IS_SERVER then
        self.RootPart:SetNetworkOwner(owner)
    end
end

--[=[
    @within Luanoid
    @method IsNetworkOwner
    @return boolean
    Returns if the current machine is the network owner of the Luanoid.
]=]
function LUANOID_METATABLE:IsNetworkOwner()
    local networkOwner = self.Character:GetAttribute("NetworkOwner")

    if IS_SERVER then
        return networkOwner == nil
    elseif IS_CLIENT then
        return networkOwner == LocalPlayer.Name
    end
end

--[=[
    @within Luanoid
    @method GetState
    @return CharacterState
    Returns the Luanoid's current CharacterState.
]=]
function LUANOID_METATABLE:GetState()
    return rawget(self, "_characterState")
end

--[=[
    @within Luanoid
    @method ChangeState
    @param state CharacterState
    Set the Luanoid to the given CharacterState.
]=]
function LUANOID_METATABLE:ChangeState(newState)
    t.ChangeState(newState)

    local curState = self:GetState()
    if newState ~= curState then
        rawset(self, "_characterState", newState)
        self.Character:SetAttribute("CharacterState", newState.Name)
        self.StateChanged:Fire(newState, curState)
    end
end

-- roblox-ts compatability
Luanoid.default = Luanoid
return Luanoid
