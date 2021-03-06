local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Luanoid = require(ReplicatedStorage.Packages.Luanoid)

local function makeLuanoid(player)
    local luanoid = Luanoid.new()
    local character = luanoid.Character
    --[[
        Luanoids use a custom SetNetworkOwner() method due to Roblox's tendancy
        to reset the NetworkOwner to automatic network ownership which is
        not favorable for characters.

        Another reason is the NetworkOwner is set
        as an attribute for clients to know when they are the NetworkOwner due
        to clients not able to use GetNetworkOwner() which is necessary to
        determine if they are the currently expected machine to simulate the
        Luanoid.
    ]]
    luanoid:SetNetworkOwner(player)
    luanoid.Name = player.Name
    luanoid.RootPart.CFrame = CFrame.new(0, 5, 0)
    character.Parent = workspace
    local userId = player.UserId
    luanoid:ApplyDescription(
        if userId > 0 then Players:GetHumanoidDescriptionFromUserId(player.UserId) else Instance.new("HumanoidDescription"),
        Enum.HumanoidRigType.R15
    )
    player.Character = character
end

for _,player in pairs(Players:GetPlayers()) do
    makeLuanoid(player)
end

Players.PlayerAdded:Connect(makeLuanoid)
