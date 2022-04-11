local FallingPhysics = {}

function FallingPhysics.entered(characterController)
    local luanoid = characterController.Luanoid
    luanoid.FreeFalling:Fire(true)

    local rootPart = luanoid.RootPart
	local assemblyVel = rootPart.AssemblyLinearVelocity
	if math.abs(assemblyVel.Y) > 100 then
		rootPart.AssemblyLinearVelocity = Vector3.new(assemblyVel.X, 0, assemblyVel.Z)
	end

	luanoid.Animator:PlayAnimation("Falling")
end

function FallingPhysics.leaving(characterController)
    local luanoid = characterController.Luanoid
    luanoid.FreeFalling:Fire(false)

    local rootPart = luanoid.RootPart
	local assemblyVel = rootPart.AssemblyLinearVelocity
	if math.abs(assemblyVel.Y) > 100 then
		rootPart.AssemblyLinearVelocity = Vector3.new(assemblyVel.X, 0, assemblyVel.Z)
	end

	luanoid.Animator:StopAnimation("Falling")
end

function FallingPhysics.step(characterController)
    local luanoid = characterController.Luanoid
    luanoid.Mover.Enabled = false
	luanoid.Aligner.Enabled = false

	local rootPart = luanoid.RootPart
	local assemblyVel = rootPart.AssemblyLinearVelocity
	-- if assemblyVel.Y > 15 then
    --     --[[
    --         Stops the Luanoid from bouncing back up when falling from high
    --         speeds. A longer than usual raycast is used due to the Luanoids
    --         often not detecting the ground in time.
    --     ]]
	-- 	local raycastResult = characterController:CastCollideOnly(rootPart.Position, Vector3.new(0, -20, 0))

	-- 	if raycastResult then
	-- 		rootPart.AssemblyLinearVelocity = Vector3.new(assemblyVel.X, 0, assemblyVel.Z)
	-- 		rootPart.CFrame *= CFrame.new(0, raycastResult.Position.Y + luanoid.HipHeight + rootPart.Size.Y / 2 - rootPart.Position.Y, 0)
	-- 	end
	-- else
	if assemblyVel.Magnitude < 0.1 and characterController:GetStateElapsedTime() > 1 then
		-- Jumps the player if they're stuck
		rootPart:ApplyImpulse(Vector3.new(0, rootPart.AssemblyMass * luanoid.JumpPower, 0))
	end
end

return FallingPhysics
