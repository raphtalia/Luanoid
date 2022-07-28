-- Finite State Machine

local CharacterState = require(script.Parent.CharacterState)

local Constants = require(script.Parent.Constants)
local RAYCAST_CUSHION = Constants.RAYCAST_CUSHION

return function (characterController)
    local luanoid = characterController.Luanoid
    local rootPart = luanoid.RootPart
    local curState = luanoid:GetState()
    local groundDistanceGoal = luanoid.HipHeight + rootPart.Size.Y / 2 + RAYCAST_CUSHION
    local currentVelocityY = rootPart.AssemblyLinearVelocity.Y
    local raycastResult = characterController.RaycastResult

    local newState
    if luanoid.Health <= 0 then
        newState = CharacterState.Dead
    else
        if rootPart:GetRootPart() == rootPart then
            if curState == CharacterState.Jumping then
                if currentVelocityY < 0 then
                    -- We passed the peak of the jump and are now falling downward
                    newState = CharacterState.Falling

                    luanoid.Floor = nil
                end
            else
                if raycastResult and (rootPart.Position - raycastResult.Position).Magnitude < groundDistanceGoal then
                    -- We are grounded
                    if luanoid.Jump and characterController:GetStateElapsedTime() > 0.2 and (curState == CharacterState.Walking or curState == CharacterState.Idling) then
                        -- Jump has a cooldown after hitting the ground
                        newState = CharacterState.Jumping
                    else
                        local moveDir = luanoid.MoveDirection
                        moveDir = Vector3.new(moveDir.X, 0, moveDir.Z) -- Would explode if Y wasn't 0
                        if moveDir.Magnitude > 0 then
                            newState = CharacterState.Walking
                        else
                            newState = CharacterState.Idling
                        end
                    end

                    luanoid.Floor = raycastResult.Instance
                else
                    newState = CharacterState.Falling

                    luanoid.Floor = nil
                end
            end
        else
            -- HRP isn't RootPart so Character is likely welded to something
            newState = CharacterState.Physics

            luanoid.Floor = nil
        end
    end
    luanoid.Jump = false

    return newState or curState
end
