local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local t = require(script.Parent.Types).CharacterController

local Constants = require(script.Parent.Constants)
local RAYCAST_CUSHION = Constants.RAYCAST_CUSHION
local IS_SERVER = Constants.IS_SERVER

local CharacterController = {}
local CHARACTER_CONTROLLER_METATABLE = {}

function CHARACTER_CONTROLLER_METATABLE:__index(i)
    if i == "Luanoid" then
        return rawget(self, "_luanoid")
    elseif i == "RaycastParams" then
        return rawget(self, "_raycastParams")
    elseif i == "Running" then
        return rawget(self, "_running")
    elseif i == "FiniteStateMachine" then
        error("FiniteStateMachine is write-only", 2)
    elseif i == "States" then
        return rawget(self, "_states")
    elseif i == "LastState" then
        return rawget(self, "_lastState")
    elseif i == "StateEnterTick" then
        return rawget(self, "_stateEnterTick")
    elseif i == "StateEnterPosition" then
        return rawget(self, "_stateEnterPosition")
    elseif i == "RaycastResult" then
        return rawget(self, "_raycastResult")
    elseif i == "RaycastResults" then
        return rawget(self, "_raycastResults")
    elseif i == "Stores" then
        return rawget(self, "_stores")
    else
        return CHARACTER_CONTROLLER_METATABLE[i] or error(i.. " is not a valid member of CharacterController", 2)
    end
end

function CHARACTER_CONTROLLER_METATABLE:__newindex(i, v)
    if i == "RaycastParams" then
        t.RaycastParams(v)
        rawset(self, "_raycastParams", v)
    elseif i == "FiniteStateMachine" then
        t.FiniteStateMachine(v)
        rawset(self, "_finiteStateMachine", v)
    else
        error(i.. " is not a valid member of CharacterController or is unassignable", 2)
    end
end

function CharacterController.new(luanoid, states, fsm)
    t.new(luanoid, states, fsm)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { luanoid.Character }
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true

    local self = {
        _luanoid = luanoid,
        _raycastParams = raycastParams,
        _finiteStateMachine = fsm,
        _running = false,
        _heartbeat = nil,
        _states = {},

        -- Data used to compute future states
        _lastState = nil,
        _stateEnterTick = 0,
        _stateEnterPosition = Vector3.new(),
        _raycastResult = nil,
        _raycastResults = nil,

        -- Place for state handlers to read/write values to
        _stores = {}
    }

    for _,state in ipairs(states:GetEnumItems()) do
        self._states[state] = {
            Entered = Signal.new(),
            Leaving = Signal.new(),
            Step = Signal.new(),
        }
    end

    return setmetatable(self, CHARACTER_CONTROLLER_METATABLE)
end

function CHARACTER_CONTROLLER_METATABLE:CastCollideOnly(origin, dir)
    local originalFilter = self.RaycastParams.FilterDescendantsInstances
    local tempFilter = self.RaycastParams.FilterDescendantsInstances

    repeat
        local result = workspace:Raycast(origin, dir, self.RaycastParams)
        if result then
            if result.Instance.CanCollide then
                self.RaycastParams.FilterDescendantsInstances = originalFilter
                return result
            else
                table.insert(tempFilter, result.Instance)
                self.RaycastParams.FilterDescendantsInstances = tempFilter
                origin = result.Position
                dir = dir.Unit * (dir.Magnitude - (origin - result.Position).Magnitude)
            end
        else
            self.RaycastParams.FilterDescendantsInstances = originalFilter
            return nil
        end
    until not result
end

function CHARACTER_CONTROLLER_METATABLE:GetStateElapsedTime()
    return tick() - self._stateEnterTick
end

function CHARACTER_CONTROLLER_METATABLE:Start()
    local heartbeat = rawget(self, "_heartbeat")
    if not heartbeat or (heartbeat and not heartbeat.Connected) then
        -- Fire the entered event to run any setup code for the initial state
        self.States[self.Luanoid:GetState()].Entered:Fire(self, 0)

        rawset(self, "_heartbeat", RunService.Heartbeat:Connect(function(dt)
            self:_step(dt)
        end))

        rawset(self, "_running", true)
    end
end

function CHARACTER_CONTROLLER_METATABLE:Stop()
    local heartbeat = rawget(self, "_heartbeat")

    if heartbeat then
        heartbeat:Disconnect()
        rawset(self, "_running", false)
        rawset(self, "_heartbeat", nil)
    end
end

function CHARACTER_CONTROLLER_METATABLE:_step(dt)
    local luanoid = self.Luanoid
    local rootPart = luanoid.RootPart

    if not rootPart:IsGrounded() then
        local correctNetworkOwner = luanoid:GetNetworkOwner()
        if IS_SERVER and correctNetworkOwner ~= rootPart:GetNetworkOwner() then
            --[[
                Roblox has automatically assigned a NetworkOwner
                when it shouldn't have. This can cause Luanoids'
                physics to become highly unstable.
            ]]
            rootPart:SetNetworkOwner(correctNetworkOwner)
        end

        local hrpSize = rootPart.Size
        local rayDir = Vector3.new(0, -(luanoid.HipHeight + hrpSize.Y / 2) - RAYCAST_CUSHION, 0)
        local center = self:CastCollideOnly(
            rootPart.Position,
            rayDir
        )
        local topleft = self:CastCollideOnly(
            (rootPart.CFrame * CFrame.new(-hrpSize.X/2, 0, -hrpSize.Z/2)).Position,
            rayDir
        )
        local topright = self:CastCollideOnly(
            (rootPart.CFrame * CFrame.new(hrpSize.X/2, 0, -hrpSize.Z/2)).Position,
            rayDir
        )
        local bottomleft = self:CastCollideOnly(
            (rootPart.CFrame * CFrame.new(-hrpSize.X/2, 0, hrpSize.Z/2)).Position,
            rayDir
        )
        local bottomright = self:CastCollideOnly(
            (rootPart.CFrame * CFrame.new(hrpSize.X/2, 0, hrpSize.Z/2)).Position,
            rayDir
        )
        local raycastResults = {
            center,
            topleft,
            topright,
            bottomleft,
            bottomright,
        }

        table.sort(raycastResults, function(a, b)
            return (a and a.Position.Y or -math.huge) > (b and b.Position.Y or -math.huge)
        end)

        --[[
            self.RaycastResult will be the RaycastResult with the highest
            altitude while self.RaycastResults will detail all Raycasts
        ]]
        rawset(self, "_raycastResult", raycastResults[1])
        rawset(self, "_raycastResults", {
            Center = center,
            TopLeft = topleft,
            TopRight = topright,
            bottomleft = bottomleft,
            bottomright = bottomright,
        })

        local curState = luanoid:GetState()
        local newState = rawget(self, "_finiteStateMachine")(self, dt)
        if newState ~= curState then
            self.States[curState].Leaving:Fire(self, dt)

            luanoid:ChangeState(newState)
            rawset(self, "_lastState", curState)
            rawset(self, "_stateEnterTick", tick())
            rawset(self, "_stateEnterPosition", rootPart.Position)

            self.States[newState].Entered:Fire(self, dt)
        end

        self.States[newState].Step:Fire(self, dt)
    end
end

return CharacterController
