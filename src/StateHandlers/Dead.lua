local Dead = {}

function Dead.entered(characterController)
    local luanoid = characterController.Luanoid
    luanoid.Died:Fire(true)
    -- luanoid.Animator:StopAnimations()
    characterController:Stop()
end

function Dead.leaving(characterController)
    characterController.Luanoid.Died:Fire(false)
end

function Dead.step(characterController)
    local luanoid = characterController.Luanoid
    luanoid.Mover.Enabled = false
    luanoid.Aligner.Enabled = false
    characterController:Stop()
end

return Dead
