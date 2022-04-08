local Dead = {}

function Dead.entered(stateController)
    local luanoid = stateController.Luanoid
    luanoid.Died:Fire(true)
    -- luanoid.Animator:StopAnimations()
    stateController:Stop()
end

function Dead.leaving(stateController)
    stateController.Luanoid.Died:Fire(false)
end

function Dead.step(stateController)
    local luanoid = stateController.Luanoid
    luanoid.Mover.Enabled = false
    luanoid.Aligner.Enabled = false
    stateController:Stop()
end

return Dead
