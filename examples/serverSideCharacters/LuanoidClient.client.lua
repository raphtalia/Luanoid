local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Luanoid = require(ReplicatedStorage.Packages.Luanoid)
local PlayerModule = require(script.Parent:WaitForChild("PlayerModule"))

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local currentLuanoid

local function makeLuanoid(character)
    character:WaitForChild("HumanoidRootPart")

    local luanoid = Luanoid.new(character)
    if Players:GetPlayerFromCharacter(character) == LocalPlayer then
        luanoid.CharacterController:Start()
        Camera.CameraSubject = luanoid.RootPart
        Camera.CameraType = Enum.CameraType.Custom
        currentLuanoid = luanoid
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
playerAdded(LocalPlayer)

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
