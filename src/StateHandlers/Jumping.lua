local Jumping = {}

function Jumping.entered(stateController)
    local luanoid = stateController.Luanoid
    luanoid.Jumping:Fire(true)
    local rootPart = luanoid.RootPart
    rootPart:ApplyImpulse(Vector3.new(0, luanoid.JumpPower * rootPart.AssemblyMass, 0))
    luanoid.Animator:PlayAnimation("Jumping")
end

function Jumping.leaving(stateController)
    local luanoid = stateController.Luanoid
    luanoid.Jumping:Fire(false)
    luanoid.Animator:StopAnimation("Jumping")
end

function Jumping.step(stateController)
    local luanoid = stateController.Luanoid
    luanoid.Mover.Enabled = false
    luanoid.Aligner.Enabled = true

    if luanoid.LookDirection.Magnitude > 0 then
        -- luanoid.Aligner.Attachment1.CFrame = CFrame.lookAt(Vector3.new(), luanoid.LookDirection)
        luanoid.Aligner.Attachment0.CFrame = CFrame.lookAt(Vector3.new(), luanoid.LookDirection)
    end
end

return Jumping
