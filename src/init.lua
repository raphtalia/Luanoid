local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local t = require(script.Types).Luanoid
local Animator = require(script.Animator)
local CharacterController = require(script.CharacterController)
local CharacterState = require(script.CharacterState)
local FSM = require(script.FSM)

local StateHandlers = {
    Dead = require(script.StateHandlers.Dead),
    FallingAndPhysics = require(script.StateHandlers.FallingAndPhysics),
    IdlingAndWalking = require(script.StateHandlers.IdlingAndWalking),
    Jumping = require(script.StateHandlers.Jumping),
}

local Constants = require(script.Constants)
local IS_SERVER = Constants.IS_SERVER
local IS_CLIENT = Constants.IS_CLIENT

local applyHumanoidDescription = require(script.Util.applyHumanoidDescription)
local buildRigFromAttachments = require(script.Util.buildRigFromAttachments)

local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local Luanoid = {
    CharacterState,
}
local LUANOID_METATABLE = {}
function LUANOID_METATABLE:__index(i)
    if i == "MoveDirection" then
        return self.Character:GetAttribute("MoveDirection")
    elseif i == "LookDirection" then
        return self.Character:GetAttribute("LookDirection")
    elseif i == "Health" then
        return self.Character:GetAttribute("Health")
    elseif i == "MaxHealth" then
        return self.Character:GetAttribute("MaxHealth")
    elseif i == "WalkSpeed" then
        return self.Character:GetAttribute("WalkSpeed")
    elseif i == "JumpPower" then
        return self.Character:GetAttribute("JumpPower")
    elseif i == "HipHeight" then
        return self.Character:GetAttribute("HipHeight")
    elseif i == "MaxSlopeAngle" then
        return self.Character:GetAttribute("MaxSlopeAngle")
    elseif i == "AutoRotate" then
        return self.Character:GetAttribute("AutoRotate")
    elseif i == "Jump" then
        return self.Character:GetAttribute("Jump")
    elseif i == "Animator" then
        return rawget(self, "_animator")
    elseif i == "CharacterController" then
        return rawget(self, "_characterController")
    elseif i == "Character" then
        return rawget(self, "_character")
    elseif i == "Floor" then
        return rawget(self, "_floor")
    elseif i == "FloorMaterial" then
        local floor = self.Floor
        return if floor then Enum.Material[floor.Material] else nil
    elseif i == "Mover" then
        return self.RootPart.Mover
    elseif i == "Aligner" then
        return self.RootPart.Aligner
    elseif i == "RootPart" then
        return self.Character:FindFirstChild("HumanoidRootPart")
    elseif i == "RigChanged" then
        return rawget(self, "_rigChanged")
    elseif i == "AccessoryEquipped" then
        return rawget(self, "_accessoryEquipped")
    elseif i == "AccessoryUnequipping" then
        return rawget(self, "_accessoryUnequipping")
    elseif i == "Died" then
        return rawget(self, "_died")
    elseif i == "FallingDown" then
        return rawget(self, "_fallingDown")
    elseif i == "FreeFalling" then
        return rawget(self, "_freeFalling")
    elseif i == "HealthChanged" then
        return rawget(self, "_healthChanged")
    elseif i == "Jumping" then
        return rawget(self, "_jumping")
    elseif i == "MoveToFinished" then
        return rawget(self, "_moveToFinished")
    elseif i == "Seated" then
        return rawget(self, "_seated")
    elseif i == "StateChanged" then
        return rawget(self, "_stateChanged")
    elseif i == "Touched" then
        return rawget(self, "_touched")
    elseif i == "Destroying" then
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
        self.Character:SetAttribute("Health", v)
    elseif i == "MaxHealth" then
        t.MaxHealth(v)
        self.Character:SetAttribute("MaxHealth", v)
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

        if self.CharacterController then
            self.CharacterController:Stop()
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
        self.Character:SetAttribute("FloorMaterial", if v then v.Material.Name else nil)
    else
        error(i.. " is not a valid member of Luanoid or is unassignable", 2)
    end
end

function Luanoid.new(existingCharacter)
    t.new(existingCharacter)

    local self = setmetatable({
        RigParts = {},
        RigMotors6Ds = {},

        _character = Instance.new("Model"),
        _floor = nil,
        _characterState = CharacterState.Idling,
        _animator = nil,
        _characterController = nil,
        _moveToPromise = nil,

        _rigChanged = Signal.new(),
        _accessoryEquipped = Signal.new(),
        _accessoryUneqipping = Signal.new(),
        _died = Signal.new(),
        _freeFalling = Signal.new(),
        _healthChanged = Signal.new(),
        _jumping = Signal.new(),
        _moveToFinished = Signal.new(),
        _seated = Signal.new(), -- TODO: Implement
        _stateChanged = Signal.new(),
        _touched = Signal.new(), -- TODO: Implement
        _destroying = Signal.new(),
    }, LUANOID_METATABLE)
    local character = self.Character
    character:SetAttribute("MoveDirection", Vector3.new())
    character:SetAttribute("LookDirection", Vector3.new())
    character:SetAttribute("Health", 100)
    character:SetAttribute("MaxHealth", 100)
    character:SetAttribute("WalkSpeed", 16)
    character:SetAttribute("JumpPower", 50)
    character:SetAttribute("HipHeight", 2)
    character:SetAttribute("MaxSlopeAngle", 89)
    character:SetAttribute("AutoRotate", true)
    character:SetAttribute("Jump", false)

    local moveDirAttachment = Instance.new("Attachment")
    moveDirAttachment.Name = "MoveDirection"

    local lookDirAttachment = Instance.new("Attachment")
    lookDirAttachment.Name = "LookDirection"

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
    -- aligner.Attachment1 = lookDirAttachment
    aligner.Parent = humanoidRootPart

    moveDirAttachment.Parent = humanoidRootPart
    lookDirAttachment.Parent = Terrain

    local accessoriesFolder = Instance.new("Folder")
    accessoriesFolder.Name = "Accessories"
    accessoriesFolder.Parent = character

    self.Name = "Luanoid"
    self.Animator = Animator.new(self)

    local characterController = CharacterController.new(self, CharacterState, FSM)
    characterController.States[CharacterState.Physics].Entered:Connect(StateHandlers.FallingAndPhysics.entered)
    characterController.States[CharacterState.Physics].Leaving:Connect(StateHandlers.FallingAndPhysics.leaving)
    characterController.States[CharacterState.Physics].Step:Connect(StateHandlers.FallingAndPhysics.step)
    characterController.States[CharacterState.Idling].Entered:Connect(StateHandlers.IdlingAndWalking.entered)
    characterController.States[CharacterState.Idling].Leaving:Connect(StateHandlers.IdlingAndWalking.leaving)
    characterController.States[CharacterState.Idling].Step:Connect(StateHandlers.IdlingAndWalking.step)
    characterController.States[CharacterState.Walking].Entered:Connect(StateHandlers.IdlingAndWalking.entered)
    characterController.States[CharacterState.Walking].Leaving:Connect(StateHandlers.IdlingAndWalking.leaving)
    characterController.States[CharacterState.Walking].Step:Connect(StateHandlers.IdlingAndWalking.step)
    characterController.States[CharacterState.Jumping].Entered:Connect(StateHandlers.Jumping.entered)
    characterController.States[CharacterState.Jumping].Leaving:Connect(StateHandlers.Jumping.leaving)
    characterController.States[CharacterState.Jumping].Step:Connect(StateHandlers.Jumping.step)
    characterController.States[CharacterState.Falling].Entered:Connect(StateHandlers.FallingAndPhysics.entered)
    characterController.States[CharacterState.Falling].Leaving:Connect(StateHandlers.FallingAndPhysics.leaving)
    characterController.States[CharacterState.Falling].Step:Connect(StateHandlers.FallingAndPhysics.step)
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

    character.AncestryChanged:Connect(function()
        if not character:IsDescendantOf(game.Workspace) then
            if self.RootPart.Parent == character then
                self.CharacterController:Stop()
            else
                --[[
                    We don't pause the simulation to allow the Dead
                    CharacterState handler to run.
                ]]
                self:ChangeState(CharacterState.Dead)
            end
        end
    end)

    character:GetAttributeChangedSignal("Health"):Connect(function()
        self.HealthChanged:Fire(character:GetAttribute("Health"))
    end)

    return self
end

function LUANOID_METATABLE:Destroy()
    self.Destroying:Fire()
    self.CharacterController:Stop()
    self.Character:Destroy()
end

function LUANOID_METATABLE:SetRig(rig)
    t.SetRig(rig)

    self:RemoveRig()

    local character = self.Character
    local rootPart = self.RootPart
    local rigParts = rawget(self, "RigParts")
    local motor6ds = rawget(self, "RigMotors6Ds")

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

    self.RigChanged:Fire(character)
end

function LUANOID_METATABLE:RemoveRig()
    local rigParts = rawget(self, "RigParts")

    for _,limb in ipairs(rigParts) do
        limb:Destroy()
    end

    table.clear(rigParts)
    table.clear(rawget(self, "RigMotors6Ds"))
end

function LUANOID_METATABLE:ApplyDescription(humanoidDescription)
    t.ApplyDescription(humanoidDescription)
    if IS_CLIENT then
        error("ApplyDescription() is currently not implemented on the client", 2)
    end
    applyHumanoidDescription(self, humanoidDescription)
end

-- function LUANOID_METATABLE:GetAppliedDescription()
--     TODO: Implement
-- end

function LUANOID_METATABLE:BuildRigFromAttachments()
    buildRigFromAttachments(self.Character)
end

function LUANOID_METATABLE:TakeDamage(damage)
    t.TakeDamage(damage)
    self.Health = math.max(self.Health - damage, 0)
end

function LUANOID_METATABLE:Move(moveDirection, relativeToCamera)
    t.Move(moveDirection, relativeToCamera)
    if relativeToCamera then
        self.MoveDirection = CurrentCamera.CFrame:VectorToWorldSpace(moveDirection)
    else
        self.MoveDirection = moveDirection
    end
end

function LUANOID_METATABLE:MoveTo(location, part, targetRadius, timeout)
    t.MoveTo(location, part, targetRadius, timeout)
    targetRadius = targetRadius or 2
    timeout = timeout or 8

    local currentMoveTo = rawget(self, "_moveToPromise")
    if currentMoveTo then
        currentMoveTo:Cancel()
        rawset(self, "_moveToPromise", nil)
    end

    return Promise.new(function(resolve, _, onCancel)
        local rootPart = self.RootPart
        local hipHeight = self.HipHeight
        local moveToStartTick = tick()

        local distance
        repeat
            local target = if location and part then (part.CFrame * location).Position else location or part.Position
            distance = ((rootPart.Position - Vector3.new(0, hipHeight, 0)) - target).Magnitude

            self:Move((target - rootPart.Position).Unit)

            task.wait()
        until onCancel() or distance < targetRadius or (timeout > 0 and tick() - moveToStartTick > timeout)

        self:Move(Vector3.new())
        rawset(self, "_moveToPromise", nil)

        if distance < targetRadius then
            resolve(true)
            self.MoveToFinished:Fire(true)
        else
            resolve(false)
            self.MoveToFinished:Fire(false)
        end
    end)
end

function LUANOID_METATABLE:AddAccessory(accessory, base, pivot)
    t.AddAccessory(accessory, base, pivot)
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

    self.AccessoryEquipped:Fire(accessory)

    return self
end

function LUANOID_METATABLE:RemoveAccessory(accessory)
    t.RemoveAccessory(accessory)
    self.AccessoryUnequipping:Fire(accessory)
    accessory:Destroy()
end

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

function LUANOID_METATABLE:GetNetworkOwner()
    local owner = self.Character:GetAttribute("NetworkOwner")
    return if owner then Players[owner] else nil
end

function LUANOID_METATABLE:SetNetworkOwner(owner)
    t.SetNetworkOwner(owner)

    local character = self.Character
    character:SetAttribute("NetworkOwner", if owner then owner.Name else nil)
    if character:IsDescendantOf(workspace) and IS_SERVER then
        self.RootPart:SetNetworkOwner(owner)
    end
end

function LUANOID_METATABLE:IsNetworkOwner()
    local networkOwner = self.Character:GetAttribute("NetworkOwner")

    if IS_SERVER then
        return networkOwner == nil
    elseif IS_CLIENT then
        return networkOwner == LocalPlayer.Name
    end
end

function LUANOID_METATABLE:GetState()
    return rawget(self, "_characterState")
end

function LUANOID_METATABLE:ChangeState(newState)
    t.ChangeState(newState)

    rawset(self, "_characterState", newState)
    self.Character:SetAttribute("CharacterState", newState.Name)

    local curState = self:GetState()
    if newState ~= curState then
        rawset(self, "_state", newState)
        self.StateChanged:Fire(newState, curState)
    end
end

return Luanoid
