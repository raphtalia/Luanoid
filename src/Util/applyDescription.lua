--[[
    Applies HumanoidDescriptions to R15 and R6 rigs
]]
local Players = game:GetService("Players")

local buildRigFromAttachments = require(script.Parent.buildRigFromAttachments)

local function decorate(limb: BasePart?, color: Color3, textureId: string?): nil
    if limb then
        if textureId and limb:IsA("MeshPart") then
            limb.TextureID = textureId
        end
        limb.Color = color
    end
end

-- TODO: Implement support for body scaling with existing rigs
return function(luanoid, humanoidDescription: HumanoidDescription, rigType: Enum.HumanoidRigType): nil
    local rig = Players:CreateHumanoidModelFromDescription(humanoidDescription, rigType or Enum.HumanoidRigType.R15)
    local character = luanoid.Character

    luanoid.Animator:LoadAnimation("Climbing", rig.Animate.climb:FindFirstChildWhichIsA("Animation")).Priority = Enum.AnimationPriority.Movement
    luanoid.Animator:LoadAnimation("Falling", rig.Animate.fall:FindFirstChildWhichIsA("Animation")).Priority = Enum.AnimationPriority.Movement
    luanoid.Animator:LoadAnimation("Idling", rig.Animate.idle:FindFirstChildWhichIsA("Animation")).Priority = Enum.AnimationPriority.Movement
    luanoid.Animator:LoadAnimation("Jumping", rig.Animate.jump:FindFirstChildWhichIsA("Animation")).Priority = Enum.AnimationPriority.Movement
    luanoid.Animator:LoadAnimation("Running", rig.Animate.run:FindFirstChildWhichIsA("Animation")).Priority = Enum.AnimationPriority.Movement
    luanoid.Animator:LoadAnimation("Walking", rig.Animate.walk:FindFirstChildWhichIsA("Animation")).Priority = Enum.AnimationPriority.Movement

    local shirtId = if humanoidDescription.Shirt > 0 then rig.Shirt.ShirtTemplate else if humanoidDescription.Shirt == 0 then "" else nil
    local pantsId = if humanoidDescription.Pants > 0 then rig.Pants.PantsTemplate else if humanoidDescription.Shirt == 0 then "" else nil
    if rigType == Enum.HumanoidRigType.R15 then
        -- Only R15 rigs have Swimming animations
        luanoid.Animator:LoadAnimation("Swimming", rig.Animate.swim:FindFirstChildWhichIsA("Animation")).Priority = Enum.AnimationPriority.Movement
        luanoid.Animator:LoadAnimation("SwimIdling", rig.Animate.swimidle:FindFirstChildWhichIsA("Animation")).Priority = Enum.AnimationPriority.Movement

        -- Only R15 rigs support clothing at the moment
        rig.LeftUpperArm.TextureID = shirtId
        rig.LeftLowerArm.TextureID = shirtId
        rig.LeftHand.TextureID = shirtId
        rig.RightUpperArm.TextureID = shirtId
        rig.RightLowerArm.TextureID = shirtId
        rig.RightHand.TextureID = shirtId
        rig.UpperTorso.TextureID = shirtId
        rig.LowerTorso.TextureID = shirtId
        rig.LeftUpperLeg.TextureID = pantsId
        rig.LeftLowerLeg.TextureID = pantsId
        rig.LeftFoot.TextureID = pantsId
        rig.RightUpperLeg.TextureID = pantsId
        rig.RightLowerLeg.TextureID = pantsId
        rig.RightFoot.TextureID = pantsId
    elseif not rigType then
        local head = character:FindFirstChild("Head")
        if head then
            head.Color = humanoidDescription.HeadColor

            local existingFace = head:FindFirstChild("face")
            if existingFace then
                existingFace:Destroy()
            end

            -- Headless doesn't have a face
            local newFace = rig.Head:FindFirstChild("face")
            if newFace then
                newFace.Parent = head
            end
        end

        decorate(character:FindFirstChild("LeftUpperArm"), humanoidDescription.LeftArmColor, shirtId)
        decorate(character:FindFirstChild("LeftLowerArm"), humanoidDescription.LeftArmColor, shirtId)
        decorate(character:FindFirstChild("LeftHand"), humanoidDescription.LeftArmColor, shirtId)
        decorate(character:FindFirstChild("RightUpperArm"), humanoidDescription.RightArmColor, shirtId)
        decorate(character:FindFirstChild("RightLowerArm"), humanoidDescription.RightArmColor, shirtId)
        decorate(character:FindFirstChild("RightHand"), humanoidDescription.RightArmColor, shirtId)
        decorate(character:FindFirstChild("UpperTorso"), humanoidDescription.TorsoColor, shirtId)
        decorate(character:FindFirstChild("LowerTorso"), humanoidDescription.TorsoColor, shirtId)
        decorate(character:FindFirstChild("LeftUpperLeg"), humanoidDescription.LeftLegColor, pantsId)
        decorate(character:FindFirstChild("LeftLowerLeg"), humanoidDescription.LeftLegColor, pantsId)
        decorate(character:FindFirstChild("LeftFoot"), humanoidDescription.LeftLegColor, pantsId)
        decorate(character:FindFirstChild("RightUpperLeg"), humanoidDescription.RightLegColor, pantsId)
        decorate(character:FindFirstChild("RightLowerLeg"), humanoidDescription.RightLegColor, pantsId)
        decorate(character:FindFirstChild("RightFoot"), humanoidDescription.RightLegColor, pantsId)

        decorate(character:FindFirstChild("Left Arm"), humanoidDescription.LeftArmColor)
        decorate(character:FindFirstChild("Right Arm"), humanoidDescription.RightArmColor)
        decorate(character:FindFirstChild("Torso"), humanoidDescription.TorsoColor)
        decorate(character:FindFirstChild("Left Leg"), humanoidDescription.LeftLegColor)
        decorate(character:FindFirstChild("Right Leg"), humanoidDescription.RightLegColor)
    end

    for _,part in ipairs(rig:GetChildren()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.SmoothPlastic
            -- Just makes selecting R6 characters easier
            part.Locked = false
        end
    end

    if rigType then
        luanoid:SetRig(rig)
        buildRigFromAttachments(character)
    else
        for _,accessory in ipairs(rig:GetChildren()) do
            if accessory:IsA("Accessory") then
                luanoid:AddAccessory(accessory)
            end
        end
    end

    rig:Destroy()
end
