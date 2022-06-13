local RunService = game:GetService("RunService")
local Packages = game:GetService("ReplicatedStorage").Packages

if not RunService:IsRunning() then
    -- Test run using run-in-roblox
    task.wait(1)
    RunService:Run()
end

require(Packages.TestEZ).TestBootstrap:run({ Packages.Luanoid })
