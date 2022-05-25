local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Parent.Signal)

local t = require(script.Parent.Types).CharacterController

local Constants = require(script.Parent.Constants)
local RAYCAST_CUSHION = Constants.RAYCAST_CUSHION
local IS_SERVER = Constants.IS_SERVER

--[=[
    @class CharacterController
    CharacterControllers are responsible for the state handling and physics of
    the Luanoid such as movement. Luanoids can accept different
    CharacterControllers by setting the `CharacterController` propery on them.

    See [Custom CharacterControllers](/docs/customCharacterControllers) for
    writing your own CharacterController.
]=]
local CharacterController = {}
local CHARACTER_CONTROLLER_METATABLE = {}

function CHARACTER_CONTROLLER_METATABLE:__index(i)
    if i == "Luanoid" then
        --[=[
            @within CharacterController
            @readonly
            @prop Luanoid Luanoid
            Reference to the Luanoid this CharacterController is attached to.
        ]=]
        return rawget(self, "_luanoid")
    elseif i == "RaycastParams" then
        --[=[
            @within CharacterController
            @prop RaycastParams RaycastParams
            RaycastParams used to cast to the ground underneath the Luanoid's character.
        ]=]
        return rawget(self, "_raycastParams")
    elseif i == "CanRedirectJump" then
        --[=[
            @within CharacterController
            @prop CanRedirectJump boolean
            Whether or not the Luanoid can "walk" when jumping. Default is
            `true` to behave more like Humanoids.
        ]=]
        return rawget(self, "_canRedirectJump")
    elseif i == "Running" then
        --[=[
            @within CharacterController
            @readonly
            @prop Running boolean
            Whether the CharacterController is currently running.
        ]=]
        return rawget(self, "_running")
    elseif i == "FiniteStateMachine" then
        --[=[
            @within CharacterController
            @prop FiniteStateMachine (characterController: CharacterController) -> CharacterState
            Callback that returns a `CharacterState` the Luanoid should currently be in.
        ]=]
        error("FiniteStateMachine is write-only", 2)
    elseif i == "States" then
        --[=[
            @within CharacterController
            @readonly
            @prop States {[CharacterState]: { Entered: Signal, Leaving: Signal, Step: Signal }}
            Table of signals fired when a state is entered, leaving, or stepped.
        ]=]
        return rawget(self, "_states")
    elseif i == "LastState" then
        --[=[
            @within CharacterController
            @readonly
            @prop LastState CharacterState
            The previous CharacterState applied to the Launoid.
        ]=]
        return rawget(self, "_lastState")
    elseif i == "StateEnterTick" then
        --[=[
            @within CharacterController
            @readonly
            @prop StateEnterTick number
            The time the Luanoid entered its current CharacterState using `tick()`.
        ]=]
        return rawget(self, "_stateEnterTick")
    elseif i == "StateEnterPosition" then
        --[=[
            @within CharacterController
            @readonly
            @prop StateEnterPosition Vector3
            The position the Luanoid entered its current CharacterState.
        ]=]
        return rawget(self, "_stateEnterPosition")
    elseif i == "RaycastResult" then
        --[=[
            @within CharacterController
            @readonly
            @prop RaycastResult RaycastResult
            The CharacterController casts a ray to the ground from the corners
            and center of the RootPart. This is the result of the ray hitting
            closest to the RootPart.
        ]=]
        return rawget(self, "_raycastResult")
    elseif i == "RaycastResults" then
        --[=[
            @within CharacterController
            @readonly
            @prop RaycastResults {RaycastResult}
            All rays casted by the CharacterController on this step of the
            simulation.
        ]=]
        return rawget(self, "_raycastResults")
    elseif i == "Stores" then
        --[=[
            @within CharacterController
            @prop Stores {[string]: any}
            Container for data to be stored and shared between the state
            handlers and FiniteStateMachine.
        ]=]
        return rawget(self, "_stores")
    else
        return CHARACTER_CONTROLLER_METATABLE[i] or error(i.. " is not a valid member of CharacterController", 2)
    end
end

function CHARACTER_CONTROLLER_METATABLE:__newindex(i, v)
    if i == "RaycastParams" then
        t.RaycastParams(v)
        rawset(self, "_raycastParams", v)
    elseif i == "CanRedirectJump" then
        t.CanRedirectJump(v)
        rawset(self, "_canRedirectJump", v)
    elseif i == "FiniteStateMachine" then
        t.FiniteStateMachine(v)
        rawset(self, "_finiteStateMachine", v)
    else
        error(i.. " is not a valid member of CharacterController or is unassignable", 2)
    end
end

--[=[
    @within CharacterController
    Creates a new CharacterController.

    @param luanoid Luanoid
    @param states CharacterState
    @param fsm (characterController: CharacterController) -> CharacterState
    @return CharacterController
]=]
function CharacterController.new(luanoid, states, fsm)
    t.new(luanoid, states, fsm)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { luanoid.Character }
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true

    local self = {
        _luanoid = luanoid,
        _raycastParams = raycastParams,
        _canRedirectJump = true,
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

--[=[
    @within CharacterController
    @method CastCollideOnly
    @param origin Vector3
    @param dir Vector3
    @return RaycastResult
    Casts a ray while ignoring all Instances with `CanCollide` set to `false`.
    Intended for use primarily within the CharacterController.
]=]
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

--[=[
    @within CharacterController
    @method GetStateElapsedTime
    @return number
    Returns the elapsed time since the Luanoid entering its current state.
]=]
function CHARACTER_CONTROLLER_METATABLE:GetStateElapsedTime()
    return tick() - self._stateEnterTick
end

--[=[
    @within CharacterController
    @method Start
    Starts the CharacterController's simulation.
]=]
function CHARACTER_CONTROLLER_METATABLE:Start()
    if not self.Luanoid.Character:IsDescendantOf(workspace) then
        error("Start() can only be called while Luanoid is in the workspace", 2)
    end

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

--[=[
    @within CharacterController
    @method Stop
    Stops the CharacterController's simulation.
]=]
function CHARACTER_CONTROLLER_METATABLE:Stop()
    local heartbeat = rawget(self, "_heartbeat")

    if heartbeat then
        heartbeat:Disconnect()
        rawset(self, "_running", false)
        rawset(self, "_heartbeat", nil)
    end
end

--[=[
    @within CharacterController
    @private
    @method _step
    @param dt number
    Performs a single step of the CharacterController's simulation.
]=]
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
            BottomLeft = bottomleft,
            BottomRight = bottomright,
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
