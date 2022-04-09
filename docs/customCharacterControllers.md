---
sidebar_position: 2
---

# Custom CharacterControllers

The provided CharacterController gives a large degree of customization allowing you to change behavior for entering or leaving a state or the entire state. If you find this doesn't meet your needs you can swap the CharacterController for an entirely new one.

## Customizing provided controller

To add to existing behavior we simply need to bind to the events that fire when the state is entered or left or running. In this example the character will float in the air when walking and on every step of the simulation they walk faster.

```lua
    local npc = Luanoid.new()

    npc.CharacterController.States[Luanoid.CharacterState.Walking].Entered:Connect(function()
        npc.HipHeight += 10
    end)

    npc.CharacterController.States[Luanoid.CharacterState.Walking].Leaving:Connect(function()
        npc.HipHeight -= 10
        npc.WalkSpeed = 16
    end)

    npc.CharacterController.States[Luanoid.CharacterState.Walking].Step:Connect(function()
        npc.WalkSpeed += 0.1
    end)
```

To remove behavior we can just disconnect all connections to the events. The code sample below will remove the automatic playing and pausing of the Walking animation.

```lua
    local npc = Luanoid.new()

    npc.CharacterController.States[Luanoid.CharacterState.Walking].Entered:DisconnectAll()
    npc.CharacterController.States[Luanoid.CharacterState.Walking].Leaving:DisconnectAll()
```

## Starting from scratch

CharacterControllers simply need to be tables with at least a `Start()` and `Stop()` function. It is suggestioned to look at the provided [CharacterController](https://github.com/raphtalia/Luanoid/blob/8a9b1ee080467dd2b3c1c438de767ea8eec9b3bd/src/CharacterController.lua) as a guide for writing your own.

```lua
local CharacterController = {}

function CharacterController.Start()

end

function CharacterController.Stop()
    --[[
        NOTE:
        Your CharacterController will automatically be stopped if a new
        CharacterController is assigned, the Luanoid is being destroyed, or the
        character is parented outside the Workspace.
    ]]
end

return CharacterController
```

Forces to use to move and orient the character

- `Luanoid.Mover`
- `Luanoid.Aligner`

Properties to take into consideration for determining state

- `Luanoid.MoveDirection`
- `Luanoid.LookDirection`
- `Luanoid.Health`
- `Luanoid.WalkSpeed`
- `Luanoid.JumpPower`
- `Luanoid.HipHeight`
- `Luanoid.MaxSlopeAngle`
- `Luanoid.AutoRotate`
- `Luanoid.Jump`

Properties to update

- `Luanoid.Floor`

Events to fire when states change

- `Luanoid.Died`
- `Luanoid.FreeFalling`
- `Luanoid.Jumping`
