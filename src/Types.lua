local t = require(game:GetService("ReplicatedStorage").Packages.t)

local CustomAccessory = t.union(t.instanceIsA("Accessory"), t.instanceIsA("Model"), t.instanceIsA("BasePart"))
return {
    Luanoid = {
        Name = function(v)
            assert(t.string(v))
        end,

        MoveDirection = function(v)
            assert(t.Vector3(v))
        end,

        LookDirection = function(v)
            assert(t.Vector3(v))
        end,

        Health = function(v)
            assert(t.numberMin(0)(v))
        end,

        MaxHealth = function(v)
            assert(t.numberMin(0)(v))
        end,

        WalkSpeed = function(v)
            assert(t.numberMin(0)(v))
        end,

        JumpPower = function(v)
            assert(t.numberMin(0)(v))
        end,

        HipHeight = function(v)
            assert(t.numberMin(0)(v))
        end,

        MaxSlopeAngle = function(v)
            assert(t.numberMin(0)(v))
        end,

        AutoRotate = function(v)
            assert(t.boolean(v))
        end,

        Jump = function(v)
            assert(t.boolean(v))
        end,

        Animator = function(v)
            assert(t.interface({
                LoadAnimation = t.callback,
                PlayAnimation = t.callback,
                StopAnimation = t.callback,
                StopAnimations = t.callback,
            })(v))
        end,

        CharacterController = function(v)
            assert(t.interface({
                Start = t.callback,
                Stop = t.callback,
            })(v))
        end,

        Floor = function(v)
            assert(t.optional(t.instanceIsA("BasePart"))(v))
        end,

        new = function(existingCharacter)
            assert(t.optional(t.intersection(t.instanceOf("Model"), t.children({
                HumanoidRootPart = t.intersection(t.instanceIsA("BasePart"), t.children({
                    Mover = t.instanceOf("VectorForce"),
                    Aligner = t.instanceOf("AlignOrientation"),
                    MoveDirection = t.instanceOf("Attachment"),
                })),
                Accessories = t.instanceOf("Folder"),
            })))(existingCharacter))
        end,

        SetRig = function(rig)
            assert(t.intersection(t.instanceOf("Model"), t.children({
                HumanoidRootPart = t.instanceIsA("BasePart"),
            }))(rig))
        end,

        ApplyDescription = function(humanoidDescription, rigType)
            assert(t.tuple(t.instanceOf("HumanoidDescription"), t.optional(t.enum(Enum.HumanoidRigType)))(humanoidDescription, rigType))
        end,

        TakeDamage = function(damage)
            assert(t.numberPositive(damage))
        end,

        Move = function(moveDirection, relativeToCamera)
            assert(t.tuple(t.Vector3, t.optional(t.boolean))(moveDirection, relativeToCamera))
        end,

        MoveTo = function(location, part, targetRadius, timeout)
            assert(t.tuple(t.optional(t.Vector3), t.optional(t.instanceIsA("BasePart")), t.optional(t.numberPositive), t.optional(t.numberMin(0)))(location, part, targetRadius, timeout))
        end,

        AddAccessory = function(accessory, base, pivot)
            assert(t.tuple(
                CustomAccessory,
                t.optional(t.union(
                    t.instanceIsA("Attachment"),
                    t.instanceIsA("BasePart")
                )),
                t.optional(t.CFrame)
            )(accessory, base, pivot))
        end,

        RemoveAccessory = function(accessory)
            assert(CustomAccessory(accessory))
        end,

        GetAccessories = function(attachment)
            assert(t.optional(t.instanceIsA("Attachment"))(attachment))
        end,

        SetNetworkOwner = function(owner)
            assert(t.optional(t.instanceOf("Player"))(owner))
        end,

        ChangeState = function(newState)
            -- Doesn't check for exact CharacterState match for support for custom CharacterStates
            assert(t.table(newState))
        end,
    },
    Animator = {
        LoadAnimation = function(name, animation)
            assert(t.tuple(t.string, t.instanceOf("Animation"))(name, animation))
        end,

        PlayAnimation = function(name)
            assert(t.string(name))
        end,

        StopAnimation = function(name)
            assert(t.string(name))
        end,

        UnloadAnimation = function(name)
            assert(t.string(name))
        end,
    },
    CharacterController = {
        RaycastParams = function(v)
            assert(t.RaycastParams(v))
        end,

        FiniteStateMachine = function(v)
            assert(t.callback(v))
        end,

        new = function(luanoid, states, logic)
            assert(t.tuple(t.table, t.table, t.callback)(luanoid, states, logic))
        end
    }
}
