local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)

local t = require(script.Parent.Types).Animator

--[=[
    @class Animator
    Animators are
    responsible for playing animations on the Luanoid primarily through the
    CharacterController. Luanoids can accept different Animators by setting the
    `Animator` property on them.

    Animations loaded on the server before the Client Luanoid is created will
    automatically be replicated.

    See [Custom Animators](/docs/customAnimators) for writing your own
    Animator.
]=]
local Animator = {}
local ANIMATOR_METATABLE = {}
ANIMATOR_METATABLE.__index = ANIMATOR_METATABLE

function Animator.new(luanoid)
    --[=[
        @within Animator
        @readonly
        @prop Luanoid Luanoid
        Reference to the Luanoid this CharacterController is attached to.
    ]=]
    --[=[
        @within Animator
        @readonly
        @prop AnimationController AnimationController
        Reference to the AnimationController used internally.
    ]=]
    --[=[
        @within Animator
        @readonly
        @prop Animator Animator
        Reference to the Animator used internally.
    ]=]
    --[=[
        @within Animator
        @readonly
        @prop AnimationTracks {[string]: AnimationTrack}
        References to the loaded AnimationTracks.
    ]=]
    --[=[
        @within Animator
        @readonly
        @tag event
        @prop AnimationPlayed Signal (animationTrack: AnimationTrack)
        Fires after `PlayAnimation()` is executed.
    ]=]
    --[=[
        @within Animator
        @readonly
        @tag event
        @prop AnimationStopped Signal (animationTrack: AnimationTrack)
        Fires after `StopAnimation()` is executed.
    ]=]
    --[=[
        @within Animator
        @readonly
        @tag event
        @prop AnimationLoaded Signal (animationTrack: AnimationTrack)
        Fires after `LoadAnimation()` is executed.
    ]=]
    --[=[
        @within Animator
        @readonly
        @tag event
        @prop AnimationUnloading Signal (animationTrack: AnimationTrack)
        Fires while `UnloadAnimation()` is executing.
    ]=]
    local self =  setmetatable({
        Luanoid = luanoid,
        AnimationController = nil,
        Animator = nil,
        AnimationTracks = {},

        AnimationPlayed = Signal.new(),
        AnimationStopped = Signal.new(),
        AnimationLoaded = Signal.new(),
        AnimationUnloading = Signal.new(),
    }, ANIMATOR_METATABLE)
    local character = luanoid.Character

    if character:FindFirstChild("AnimationController") then
        self.AnimationController = character.AnimationController
        local animator = character.AnimationController.Animator
        self.Animator = animator

        -- TODO: Figure out how to replicate newly created server animations after Client Luanoid is created
        for _,animation in ipairs(animator:GetChildren()) do
            self:_loadAnimation(animation)
        end
    else
        local animationController = Instance.new("AnimationController")
        local animator = Instance.new("Animator")
        animationController.Parent = character
        animator.Parent = animationController
        self.AnimationController = animationController
        self.Animator = animator
    end

    return self
end

--[=[
    @within Animator
    @private
    @method _loadAnimation
    @param animation Animation
    @return AnimationTrack
]=]
function ANIMATOR_METATABLE:_loadAnimation(animation)
    local name = animation.name
    local animationTrack = self.Animator:LoadAnimation(animation)
    self.AnimationTracks[name] = animationTrack
    self.AnimationLoaded:Fire(name, animationTrack)
    return animationTrack
end

--[=[
    @within Animator
    @method LoadAnimation
    @param name string
    @param animation Animation
    @return AnimationTrack
    Loads an animation into the Animator under a name that can be used to play
    it later.
]=]
function ANIMATOR_METATABLE:LoadAnimation(name, animation)
    -- TODO: Possibly convert this to a Promise to allow loading animations outside of Workspace and resolve with the AnimationTrack later
    t.LoadAnimation(name, animation)
    if not self.Luanoid.Character:IsDescendantOf(workspace) then
        error("LoadAnimation() can only be called while Luanoid is in the workspace", 2)
    end

    local existingAnimation = self.Animator:FindFirstChild(name)
    if existingAnimation then
        existingAnimation:Destroy()
    end

    -- Replication of animations from Server to Client
    animation = animation:Clone()
    animation.Name = name
    animation.Parent = self.Animator

    return self:_loadAnimation(animation)
end

--[=[
    @within Animator
    @method PlayAnimation
    @param name string
    @param ... any
    Plays an animation loaded previously. Remaining arguments are passed to
    `AnimationTrack:Play()`.
]=]
function ANIMATOR_METATABLE:PlayAnimation(name, ...)
    t.PlayAnimation(name)

    local animationTrack = self.AnimationTracks[name]

    if animationTrack then
        animationTrack:Play(...)
        self.AnimationPlayed:Fire(name, animationTrack)
    else
        warn("AnimationTrack not found: "..name)
    end
end

--[=[
    @within Animator
    @method StopAnimation
    @param name string
    @param ... any
    Stops a playing AnimationTrack. Remaining arguments are passed to
    `AnimationTrack:Stop()`.
]=]
function ANIMATOR_METATABLE:StopAnimation(name, ...)
    t.StopAnimation(name)

    local animationTrack = self.AnimationTracks[name]

    if animationTrack then
        animationTrack:Stop(...)
        self.AnimationStopped:Fire(name, animationTrack)
    else
        warn("AnimationTrack not found: "..name)
    end
end

--[=[
    @within Animator
    @method StopAnimations
    @param ... any
    Stops all currently playing AnimationTracks. Arguments are passed to
    `AnimationTrack:Stop()`.
]=]
function ANIMATOR_METATABLE:StopAnimations(...)
    for name, animationTrack in ipairs(self.Animator:GetPlayingAnimationTracks()) do
        animationTrack:Stop(...)
        self.AnimationStopped:Fire(name, animationTrack)
    end
end

--[=[
    @within Animator
    @method UnloadAnimation
    @param name string
    Unloads an animation from the Animator.
]=]
function ANIMATOR_METATABLE:UnloadAnimation(name)
    t.UnloadAnimation(name)

    local animationTrack = self.AnimationTracks[name]

    if animationTrack then
        self.AnimationUnloading:Fire(name, animationTrack)
        animationTrack:Destroy()
        self.AnimationTracks[name] = nil

        local animation = self.Animator:FindFirstChild(name)
        if animation then
            animation:Destroy()
        end
    else
        warn("AnimationTrack not found: "..name)
    end
end

--[=[
    @within Animator
    @method UnloadAnimations
    Unloads all animations from the Animator.
]=]
function ANIMATOR_METATABLE:UnloadAnimations()
    for name, animation in pairs(self.AnimationTracks) do
        self.AnimationUnloading:Fire(name, animation)
        animation:Destroy()
    end

    table.clear(self.AnimationTracks)
end

return Animator
