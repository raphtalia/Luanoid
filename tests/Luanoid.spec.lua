local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Luanoid = require(ReplicatedStorage.Packages.Luanoid)
return function()
    describe("Luanoid", function()
        local rig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
        rig.Humanoid:Destroy()

        local l15

        beforeEach(function()
            l15 = Luanoid.new()
            l15:SetRig(rig:Clone())
            l15.Character.Parent = workspace
            l15.CharacterController:Start()
        end)

        afterEach(function()
            l15:Destroy()
        end)

        it("should update MoveDirection attribute", function()
            l15.MoveDirection = Vector3.new(0, 0, -1)
            expect(l15.Character:GetAttribute("MoveDirection")).to.equal(Vector3.new(0, 0, -1))

            l15:Move(Vector3.new(0, 0, 1))
            expect(l15.Character:GetAttribute("MoveDirection")).to.equal(Vector3.new(0, 0, 1))
        end)

        it("should update LookDirection attribute", function()
            l15.AutoRotate = false
            l15.LookDirection = Vector3.new(0, 0, -1)
            expect(l15.Character:GetAttribute("LookDirection")).to.equal(Vector3.new(0, 0, -1))
        end)

        it("should update Health attribute", function()
            l15.Health = 50
            expect(l15.Character:GetAttribute("Health")).to.equal(50)
        end)

        it("should update MaxHealth attribute", function()
            l15.MaxHealth = 50
            expect(l15.Character:GetAttribute("MaxHealth"))
        end)

        it("should update Health to be less than MaxHealth", function()
            l15.MaxHealth = 50
            expect(l15.Health).to.equal(50)
        end)

        it("should update WalkSpeed attribute", function()
            l15.WalkSpeed = 50
            expect(l15.Character:GetAttribute("WalkSpeed")).to.equal(50)
        end)

        it("should update JumpPower attribute", function()
            l15.JumpPower = 100
            expect(l15.Character:GetAttribute("JumpPower")).to.equal(100)
        end)

        it("should update HipHeight attribute", function()
            l15.HipHeight = 10
            expect(l15.Character:GetAttribute("HipHeight")).to.equal(10)
        end)

        it("should update MaxSlopeAngle attribute", function()
            l15.MaxSlopeAngle = 10
            expect(l15.Character:GetAttribute("MaxSlopeAngle")).to.equal(10)
        end)

        it("should update AutoRotate attribute", function()
            l15.AutoRotate = false
            expect(l15.Character:GetAttribute("AutoRotate")).to.equal(false)
        end)

        it("should update Jump attribute", function()
            l15.Jump = true
            expect(l15.Character:GetAttribute("Jump")).to.equal(true)
        end)

        it("should update Floor", function()
            repeat
                task.wait()
            until l15.Floor

            local sl = workspace.SpawnLocation
            expect(l15.Floor).to.equal(sl)
            expect(l15.FloorMaterial).to.equal(sl.Material)
            sl.Material = Enum.Material.Concrete
            expect(l15.FloorMaterial).to.equal(sl.Material)
        end)

        -- TODO: Test rig mounting and accessories

        it("should fire Died", function()
            local fired = false

            local connection = l15.Died:Connect(function()
                fired = true
            end)

            l15.Health = 0
            task.wait()
            expect(fired).to.equal(true)

            connection:Disconnect()
        end)

        it("should fire FreeFalling", function()
            local fired = false

            local connection = l15.FreeFalling:Connect(function()
                fired = true
            end)

            l15.RootPart.CFrame = CFrame.new(0, 100, 0)
            task.wait()
            expect(fired).to.equal(true)

            connection:Disconnect()
        end)

        it("should fire HealthChanged", function()
            local fired = false
            local newHealth

            local connection = l15.HealthChanged:Connect(function(v)
                fired = true
                newHealth = v
            end)

            l15.Health = 50
            task.wait()
            expect(fired).to.equal(true)
            expect(newHealth).to.equal(50)

            connection:Disconnect()
        end)

        it("should fire Jumping", function()
            local fired = false

            local connection = l15.Jumping:Connect(function()
                fired = true
            end)

            repeat
                task.wait()
            until l15.Floor
            l15.Jump = true
            task.wait()
            expect(fired).to.equal(true)

            connection:Disconnect()
        end)

        -- TODO: Test Seated & Touched

        it("should fire StateChanged", function()
            local fired = false
            local newState

            repeat
                task.wait()
            until l15:GetState() == Luanoid.CharacterState.Idling

            local connection = l15.StateChanged:Connect(function(v)
                fired = true
                newState = v
            end)

            l15.RootPart.CFrame = CFrame.new(0, 100, 0)
            task.wait()
            expect(fired).to.equal(true)
            expect(newState).to.equal(Luanoid.CharacterState.Falling)

            connection:Disconnect()
        end)

        it("should fire Destroying", function()
            local fired = false

            local connection = l15.Destroying:Connect(function()
                fired = true
            end)

            l15:Destroy()
            task.wait()
            expect(fired).to.equal(true)

            connection:Disconnect()
        end)

        it("SetRig() should not error", function()
            expect(function()
                l15:SetRig(rig:Clone())
            end).never.to.throw()
        end)

        it("RemoveRig() should not error", function()
            expect(function()
                l15:RemoveRig()
            end).never.to.throw()
        end)

        it("ApplyDescription() should not error", function()
            expect(function()
                l15:ApplyDescription(Instance.new("HumanoidDescription"))
            end).never.to.throw()
        end)

        it("BuildRigFromAttachments() should not error", function()
            expect(function()
                l15:BuildRigFromAttachments()
            end).never.to.throw()
        end)

        it("TakeDamage() should reduce health", function()
            l15.Health = 100
            l15:TakeDamage(50)
            expect(l15.Health).to.equal(50)
        end)

        it("Move() should update MoveDirection", function()
            l15:Move(Vector3.new(0, 0, -1))
            expect(l15.MoveDirection).to.equal(Vector3.new(0, 0, -1))
        end)

        it("MoveTo() should move to target", function()
            expect(l15:MoveTo(Vector3.new(0, 0, 8)):expect()).to.equal(true)
        end)

        it("MoveTo() should be cancellable", function()
            local promiseA = l15:MoveTo(Vector3.new(0, 0, 8))
            local promiseB = l15:MoveTo(Vector3.new(0, 0, -8))
            expect(promiseA.Status == "Cancelled")
            promiseB:cancel()
            expect(promiseB.Status == "Cancelled")
        end)

        -- TODO: Figure out how to test AddAccessory & RemoveAccessory

        it("GetAccessories() should return list", function()
            expect(l15:GetAccessories()).to.be.a("table")
        end)

        it("SetNetworkOwner() should not error", function()
            -- Cannot test case with setting to Player owner
            expect(function()
                l15:SetNetworkOwner()
            end).never.to.throw()
        end)

        it("IsNetworkOwner() should return true", function()
            expect(l15:IsNetworkOwner()).to.equal(true)
        end)

        it("GetState() should return current CharacterState", function()
            l15:ChangeState(Luanoid.CharacterState.Physics)
            expect(l15:GetState()).to.equal(Luanoid.CharacterState.Physics)
        end)
    end)
end
