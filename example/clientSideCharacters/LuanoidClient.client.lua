local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Luanoid = require(ReplicatedStorage.Packages.Luanoid)
local PlayerModule = require(ReplicatedStorage.Packages.PlayerModule)

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local DoguXCV = ReplicatedStorage:WaitForChild("DoguXCV")

local currentLuanoid

local function makeLuanoid(character)
    character:WaitForChild("HumanoidRootPart")

    local luanoid = Luanoid.new(character)
    luanoid:SetRig(DoguXCV:Clone())

    local player = Players:GetPlayerFromCharacter(character)
    if player then
        local userId = player.UserId
        luanoid:ApplyDescription(if userId > 0 then Players:GetHumanoidDescriptionFromUserId(player.UserId) else Instance.new("HumanoidDescription"))

        if player == LocalPlayer then
            luanoid.CharacterController:Start()
            Camera.CameraSubject = luanoid.RootPart
	        Camera.CameraType = Enum.CameraType.Custom
            currentLuanoid = luanoid
        end
    end
end

local function playerAdded(player)
    if player.Character then
        makeLuanoid(player.Character)
    end

    player.CharacterAdded:Connect(makeLuanoid)
end

for _,player in pairs(Players:GetPlayers()) do
    playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)

--[[
    This simply taps into the existing Roblox character scripts and sets the
    Luanoid's MoveDirection based on the camera every frame.
]]
RunService.Heartbeat:Connect(function()
	if currentLuanoid and currentLuanoid.Character.Parent then
		local activeController = PlayerModule.controls.activeController

		if activeController then
			if activeController.jumpRequested then
				currentLuanoid.Jump = true
			end

            --[[
                Sometimes moveVector is nil despite there being UserInput, this
                is likely a PlayerModule issue.
            ]]
			currentLuanoid:Move(activeController.moveVector, true)
		end
	end
end)
