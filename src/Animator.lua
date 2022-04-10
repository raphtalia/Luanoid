local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)

local t = require(script.Parent.Types).Animator

--[=[
    @class Animator
    Animators are
    responsible for playing animations on the Luanoid primarily through the
    CharacterController. Luanoids can accept different Animators by setting the
    `Animator` property on them.

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
    local self = {
        Luanoid = luanoid,
        AnimationController = Instance.new("AnimationController"),
        Animator = Instance.new("Animator"),
        AnimationTracks = {},

        AnimationPlayed = Signal.new(),
        AnimationStopped = Signal.new(),
        AnimationLoaded = Signal.new(),
        AnimationUnloading = Signal.new(),
    }

    self.AnimationController.Parent = self.Luanoid.Character
    self.Animator.Parent = self.AnimationController

    return setmetatable(self, ANIMATOR_METATABLE)
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
    t.LoadAnimation(name, animation)
    if not self.Luanoid.Character:IsDescendantOf(workspace) then
        error("LoadAnimation() can only be called while Luanoid is in the workspace", 2)
    end

    local animationTrack = self.Animator:LoadAnimation(animation)
    self.AnimationTracks[name] = animationTrack
    self.AnimationLoaded:Fire(name, animationTrack)

    return animationTrack
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
