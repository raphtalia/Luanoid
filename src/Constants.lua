local RunService = game:GetService("RunService")

return {
    RAYCAST_CUSHION = 2,

    FRAMERATE = 1 / 240,
    STIFFNESS = 300,
    DAMPING = 30,
    PRECISION = 0.001,
    POP_TIME = 0.05,

    IS_CLIENT = RunService:IsClient(),
    IS_SERVER = RunService:IsServer(),
}
