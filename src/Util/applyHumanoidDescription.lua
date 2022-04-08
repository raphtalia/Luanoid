--[[
    Applies HumanoidDescriptions to R15-like rigs such as Dogu15.
]]

local InsertService = game:GetService("InsertService")
local MarketPlaceService = game:GetService("MarketplaceService")
local buildRigFromAttachments = require(script.Parent.buildRigFromAttachments)

local Constants = require(script.Parent.Parent.Constants)
local IS_SERVER = Constants.IS_SERVER

local animationCache do
    if IS_SERVER then
        animationCache = Instance.new("Folder")
        animationCache.Name = "AnimationCache"
        animationCache.Parent = script
    else
        animationCache = script:FindFirstChild("AnimationCache")
    end
end

local function getAnimation(animationId: number): Animation
    local animation = animationCache:FindFirstChild(tostring(animationId))

    if not animation then
        local assetTypeId
        local success, asset = pcall(MarketPlaceService.GetProductInfo, MarketPlaceService, animationId)
        if success then
            assetTypeId = asset.AssetTypeId
        else
            --[[
                Roblox for some reason is now giving error 429 when calling
                this API in Studio, so we now assume it is Asset Type 24
                rather than checking to be sure.
            ]]
            assetTypeId = 24
        end

        if assetTypeId == 24 then
            animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://".. animationId
        else
            animation = InsertService:LoadAsset(animationId):FindFirstChildWhichIsA("Animation", true)
        end

        animation.Name = tostring(animationId)
        animation.Parent = animationCache
    end

    return animation
end

local function getFace(faceId: number): Decal
    return InsertService:LoadAsset(faceId):FindFirstChildWhichIsA("Decal", true)
end

local function getLimbParts(limbId: number): {BasePart}
    local assetTypeId = MarketPlaceService:GetProductInfo(limbId).AssetTypeId

    if assetTypeId == 17 then
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Size = Vector3.new(2, 1, 1)

        local mesh = InsertService:LoadAsset(limbId).Mesh
        mesh.Parent = head

        local faceCenterAttachment = Instance.new("Attachment")
        faceCenterAttachment.Name = "FaceCenterAttachment"
        faceCenterAttachment.Position = mesh.FaceCenterAttachment.Value
        faceCenterAttachment.Parent = head

        local faceFrontAttachment = Instance.new("Attachment")
        faceFrontAttachment.Name = "FaceFrontAttachment"
        faceFrontAttachment.Position = mesh.FaceFrontAttachment.Value
        faceFrontAttachment.Parent = head

        local hairAttachment = Instance.new("Attachment")
        hairAttachment.Name = "HairAttachment"
        hairAttachment.Position = mesh.HairAttachment.Value
        hairAttachment.Parent = head

        local hatAttachment = Instance.new("Attachment")
        hatAttachment.Name = "HatAttachment"
        hatAttachment.Position = mesh.HatAttachment.Value
        hatAttachment.Parent = head

        local neckRigAttachment = Instance.new("Attachment")
        neckRigAttachment.Name = "NeckRigAttachment"
        neckRigAttachment.Position = mesh.NeckRigAttachment.Value
        neckRigAttachment.Parent = head

        mesh:ClearAllChildren()
        return {head}
    else
        return InsertService:LoadAsset(limbId).R15Fixed:GetChildren()
    end
end

local function applyAnimation(luanoid, animationId: number, animationName: string): AnimationTrack
    return luanoid.Animator:LoadAnimation(getAnimation(animationId), animationName)
end

local function applyLimb(character: Model, limbId: number): nil
    for _,part in pairs(getLimbParts(limbId)) do
        part.Material = Enum.Material.SmoothPlastic
        part.CanCollide = false
        part.Parent = character
    end
end

local function decorate(parts: {BasePart}, color: Color3, textureId: string): nil
    for _,part in ipairs(parts) do
        if part then
            if color then
                part.Color = color
            end

            if textureId then
                part.TextureID = textureId
            end
        end
    end
end

local function breakAndDestroy(parts: {BasePart}): nil
    for _,part in ipairs(parts) do
        if part then
            part:BreakJoints()
            part:Destroy()
        end
    end
end

return function(luanoid, humanoidDescription: HumanoidDescription): nil
    local character = luanoid.Character

    if humanoidDescription.ClimbAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.ClimbAnimation, "Climbing").Priority = Enum.AnimationPriority.Movement
    end
    if humanoidDescription.FallAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.FallAnimation, "Falling").Priority = Enum.AnimationPriority.Movement
    end
    if humanoidDescription.IdleAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.IdleAnimation, "Idling").Priority = Enum.AnimationPriority.Movement
    end
    if humanoidDescription.JumpAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.JumpAnimation, "Jumping").Priority = Enum.AnimationPriority.Movement
    end
    if humanoidDescription.RunAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.RunAnimation, "Running").Priority = Enum.AnimationPriority.Movement
    end
    if humanoidDescription.SwimAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.SwimAnimation, "Swimming").Priority = Enum.AnimationPriority.Movement
    end
    if humanoidDescription.WalkAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.WalkAnimation, "Walking").Priority = Enum.AnimationPriority.Movement
    end

    local head = character:FindFirstChild("Head")
    local leftUpperArm = character:FindFirstChild("LeftUpperArm")
    local leftLowerArm = character:FindFirstChild("LeftLowerArm")
    local leftHand = character:FindFirstChild("LeftHand")
    local leftUpperLeg = character:FindFirstChild("LeftUpperLeg")
    local leftLowerLeg = character:FindFirstChild("LeftLowerLeg")
    local leftFoot = character:FindFirstChild("LeftFoot")
    local rightUpperArm = character:FindFirstChild("RightUpperArm")
    local rightLowerArm = character:FindFirstChild("RightLowerArm")
    local rightHand = character:FindFirstChild("RightHand")
    local rightUpperLeg = character:FindFirstChild("RightUpperLeg")
    local rightLowerLeg = character:FindFirstChild("RightLowerLeg")
    local rightFoot = character:FindFirstChild("RightFoot")
    local upperTorso = character:FindFirstChild("UpperTorso")
    local lowerTorso = character:FindFirstChild("LowerTorso")

    if humanoidDescription.Head ~= 0 then
        breakAndDestroy {
            head,
        }
        applyLimb(character, humanoidDescription.Head)
    end
    if humanoidDescription.LeftArm ~= 0 then
        breakAndDestroy {
            leftUpperArm,
            leftLowerArm,
            leftHand,
        }
        applyLimb(character, humanoidDescription.LeftArm)
    end
    if humanoidDescription.LeftLeg ~= 0 then
        breakAndDestroy {
            leftUpperLeg,
            leftLowerLeg,
            leftFoot,
        }
        applyLimb(character, humanoidDescription.LeftLeg)
    end
    if humanoidDescription.RightArm ~= 0 then
        breakAndDestroy {
            rightUpperArm,
            rightLowerArm,
            rightHand,
        }
        applyLimb(character, humanoidDescription.RightArm)
    end
    if humanoidDescription.RightLeg ~= 0 then
        breakAndDestroy {
            rightUpperLeg,
            rightLowerLeg,
            rightFoot,
        }
        applyLimb(character, humanoidDescription.RightLeg)
    end
    if humanoidDescription.Torso ~= 0 then
        breakAndDestroy {
            upperTorso,
            lowerTorso,
        }
        applyLimb(character, humanoidDescription.Torso)
    end
    buildRigFromAttachments(character)

    local shirtId = if humanoidDescription.Shirt ~= 0 then InsertService:LoadAsset(humanoidDescription.Shirt).Shirt.ShirtTemplate else nil
    local pantsId = if humanoidDescription.Shirt ~= 0 then InsertService:LoadAsset(humanoidDescription.Pants).Pants.PantsTemplate else nil
    decorate({ head }, humanoidDescription.HeadColor)
    decorate({ leftUpperArm, leftLowerArm, leftHand }, humanoidDescription.LeftArmColor, shirtId)
    decorate({ leftUpperLeg, leftLowerLeg, leftFoot }, humanoidDescription.LeftLegColor, pantsId)
    decorate({ rightUpperArm, rightLowerArm, rightHand }, humanoidDescription.RightArmColor, shirtId)
    decorate({ rightUpperLeg, rightLowerLeg, rightFoot }, humanoidDescription.RightLegColor, pantsId)
    decorate({ upperTorso, lowerTorso }, humanoidDescription.TorsoColor, shirtId)

    if humanoidDescription.Face ~= 0 then
        local existingFace = character.Head:FindFirstChild("face")
        if existingFace then
            existingFace:Destroy()
        end

        getFace(humanoidDescription.Face).Parent = character.Head
    end

    -- TODO: Make this handle custom accessory names
    local accessoryIds = {}
    table.insert(accessoryIds, humanoidDescription.BackAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.FaceAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.FrontAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.HairAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.HatAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.NeckAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.ShouldersAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.WaistAccessory:split(","))

    for _,accessoryGroup in pairs(accessoryIds) do
        for _,accessoryId in pairs(accessoryGroup) do
            accessoryId = tonumber(accessoryId)

            -- Sometimes the accessoryId is nil, not sure why
            if accessoryId then
                local accessory = InsertService:LoadAsset(accessoryId):FindFirstChildWhichIsA("Accessory")
                luanoid:AddAccessory(accessory)
            end
        end
    end
end
