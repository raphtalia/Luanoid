local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)

local t = require(script.Parent.Types).Animator

local Animator = {}
local ANIMATOR_METATABLE = {}
ANIMATOR_METATABLE.__index = ANIMATOR_METATABLE

function Animator.new(luanoid)
    local self = {
        Luanoid = luanoid,
        AnimationController = Instance.new("AnimationController"),
        Animator = Instance.new("Animator"),
        AnimationTracks = {},

        AnimationPlayed = Signal.new(),
        AnimationStopped = Signal.new(),
        AnimationLoaded = Signal.new(),
        AnimationUnloaded = Signal.new(),
    }

    self.AnimationController.Parent = self.Luanoid.Character
    self.Animator.Parent = self.AnimationController

    return setmetatable(self, ANIMATOR_METATABLE)
end

function ANIMATOR_METATABLE:LoadAnimation(animation, name)
    t.LoadAnimation(animation, name)
    if not self.Luanoid.Character:IsDescendantOf(workspace) then
        error("LoadAnimation() can only be called while Luanoid is in the workspace", 2)
    end

    local animationTrack = self.Animator:LoadAnimation(animation)
    self.AnimationTracks[name] = animationTrack
    self.AnimationLoaded:Fire(name, animationTrack)

    return animationTrack
end

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

function ANIMATOR_METATABLE:StopAnimations(...)
    for name, animationTrack in ipairs(self.Animator:GetPlayingAnimationTracks()) do
        animationTrack:Stop(...)
        self.AnimationStopped:Fire(name, animationTrack)
    end
end

function ANIMATOR_METATABLE:UnloadAnimation(name)
    t.UnloadAnimation(name)

    local animationTrack = self.AnimationTracks[name]

    if animationTrack then
        animationTrack:Destroy()
        self.AnimationTracks[name] = nil
        self.AnimationUnloaded:Fire(name, animationTrack)
    else
        warn("AnimationTrack not found: "..name)
    end
end

function ANIMATOR_METATABLE:UnloadAnimations()
    for name, animation in pairs(self.AnimationTracks) do
        animation:Destroy()
        self.AnimationUnloaded:Fire(name, animation)
    end

    table.clear(self.AnimationTracks)
end

return Animator
