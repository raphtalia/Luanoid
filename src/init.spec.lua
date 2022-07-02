local Luanoid = require(script.Parent)

return function()
    describe("Luanoid", function()
        local l15
        local sl = workspace:WaitForChild("SpawnLocation")
        local bp = workspace:WaitForChild("Baseplate")

        local function resetL15pos()
            l15.RootPart.CFrame = CFrame.new(0, 5, 0)
        end

        local function waitForFloor()
            repeat
                task.wait()
            until l15.Floor
        end

        beforeEach(function()
            l15 = Luanoid.new()
            l15.Character.Parent = workspace
            resetL15pos()
            l15:ApplyDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
            l15.CharacterController:Start()
        end)

        afterEach(function()
            l15:Destroy()
            sl.Material = Enum.Material.Plastic
            sl.CanCollide = true
            -- bp.Material = Enum.Material.Plastic
            -- bp.CanCollide = true
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
            waitForFloor()

            expect(l15.Floor).to.equal(sl)
            expect(l15.FloorMaterial).to.equal(sl.Material)
            sl.Material = Enum.Material.Concrete
            expect(l15.FloorMaterial).to.equal(sl.Material)
        end)

        it("should respect collision", function()
            -- ignores floor without collision
            sl.CanCollide = false
            resetL15pos()
            waitForFloor()
            expect(l15.Floor).to.equal(bp)

            -- detects floor previously without collision
            sl.CanCollide = true
            resetL15pos()
            waitForFloor()
            expect(l15.Floor).to.equal(sl)
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

            waitForFloor()
            task.wait(0.5) -- Wait for jump cooldown to expire
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

        it("RemoveRig() should not error", function()
            expect(function()
                l15:RemoveRig()
            end).never.to.throw()
        end)

        local testDescription = Instance.new("HumanoidDescription")
        local bodyColor = Color3.new(0, 1, 0)
        testDescription.HairAccessory = "4332970160"
        testDescription.HatAccessory = "3810248423"
        testDescription.HeadColor = bodyColor
        testDescription.LeftArmColor = bodyColor
        testDescription.LeftLegColor = bodyColor
        testDescription.RightArmColor = bodyColor
        testDescription.RightLegColor = bodyColor
        testDescription.TorsoColor = bodyColor
        testDescription.Face = 209994875
        testDescription.Pants = 3925758563
        testDescription.Shirt = 227710697
        -- Currently we do not test scaling as it is not fully implemented

        it("ApplyDescription() should keep rig", function()
            local character = l15.Character
            local rigParts = {unpack(rawget(l15, "RigParts"))}
            l15:ApplyDescription(testDescription)
            for _,part in ipairs(rigParts) do
                expect(part.Parent).to.equal(character)
            end
            expect(character:FindFirstChild("Humanoid")).to.equal(nil)
            expect(character:FindFirstChild("Animate")).to.equal(nil)
            expect(character:FindFirstChild("Shirt")).to.equal(nil)
            expect(character:FindFirstChild("Pants")).to.equal(nil)
            expect(character:FindFirstChild("Body Colors")).to.equal(nil)
            expect(character.Accessories:FindFirstChild("Black Bow"):IsA("Accessory")).to.equal(true)
            expect(character.Accessories:FindFirstChild("Bun with Waves"):IsA("Accessory")).to.equal(true)
            expect(character.Head.Color).to.equal(bodyColor)
            expect(character.LeftUpperArm.Color).to.equal(bodyColor)
            expect(character.LeftLowerArm.Color).to.equal(bodyColor)
            expect(character.LeftHand.Color).to.equal(bodyColor)
            expect(character.RightUpperArm.Color).to.equal(bodyColor)
            expect(character.RightLowerArm.Color).to.equal(bodyColor)
            expect(character.RightHand.Color).to.equal(bodyColor)
            expect(character.LeftUpperLeg.Color).to.equal(bodyColor)
            expect(character.LeftLowerLeg.Color).to.equal(bodyColor)
            expect(character.LeftFoot.Color).to.equal(bodyColor)
            expect(character.RightUpperLeg.Color).to.equal(bodyColor)
            expect(character.RightLowerLeg.Color).to.equal(bodyColor)
            expect(character.RightFoot.Color).to.equal(bodyColor)
            expect(character.UpperTorso.Color).to.equal(bodyColor)
            expect(character.LowerTorso.Color).to.equal(bodyColor)
            expect(character.Head.face.Texture:match("209713952")).to.never.equal(nil)
            expect(character.LeftUpperArm.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.LeftLowerArm.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.LeftHand.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.RightUpperArm.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.RightLowerArm.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.RightHand.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.UpperTorso.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.LowerTorso.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.LeftUpperLeg.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.LeftLowerLeg.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.LeftFoot.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.RightUpperLeg.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.RightLowerLeg.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.RightFoot.TextureID:match("3925758521")).to.never.equal(nil)
        end)

        it("ApplyDescription() should apply R15 rig", function()
            local character = l15.Character
            local rigParts = {unpack(rawget(l15, "RigParts"))}
            l15:ApplyDescription(testDescription, Enum.HumanoidRigType.R15)
            for _,part in ipairs(rigParts) do
                expect(part.Parent).to.equal(nil)
            end
            expect(character:FindFirstChild("Humanoid")).to.equal(nil)
            expect(character:FindFirstChild("Animate")).to.equal(nil)
            expect(character:FindFirstChild("Shirt")).to.equal(nil)
            expect(character:FindFirstChild("Pants")).to.equal(nil)
            expect(character:FindFirstChild("Body Colors")).to.equal(nil)
            expect(character.Accessories:FindFirstChild("Black Bow"):IsA("Accessory")).to.equal(true)
            expect(character.Accessories:FindFirstChild("Bun with Waves"):IsA("Accessory")).to.equal(true)
            expect(character.Head.Color).to.equal(bodyColor)
            expect(character.LeftUpperArm.Color).to.equal(bodyColor)
            expect(character.LeftLowerArm.Color).to.equal(bodyColor)
            expect(character.LeftHand.Color).to.equal(bodyColor)
            expect(character.RightUpperArm.Color).to.equal(bodyColor)
            expect(character.RightLowerArm.Color).to.equal(bodyColor)
            expect(character.RightHand.Color).to.equal(bodyColor)
            expect(character.LeftUpperLeg.Color).to.equal(bodyColor)
            expect(character.LeftLowerLeg.Color).to.equal(bodyColor)
            expect(character.LeftFoot.Color).to.equal(bodyColor)
            expect(character.RightUpperLeg.Color).to.equal(bodyColor)
            expect(character.RightLowerLeg.Color).to.equal(bodyColor)
            expect(character.RightFoot.Color).to.equal(bodyColor)
            expect(character.UpperTorso.Color).to.equal(bodyColor)
            expect(character.LowerTorso.Color).to.equal(bodyColor)
            expect(character.Head.face.Texture:match("209713952")).to.never.equal(nil)
            expect(character.LeftUpperArm.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.LeftLowerArm.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.LeftHand.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.RightUpperArm.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.RightLowerArm.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.RightHand.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.UpperTorso.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.LowerTorso.TextureID:match("227710696")).to.never.equal(nil)
            expect(character.LeftUpperLeg.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.LeftLowerLeg.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.LeftFoot.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.RightUpperLeg.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.RightLowerLeg.TextureID:match("3925758521")).to.never.equal(nil)
            expect(character.RightFoot.TextureID:match("3925758521")).to.never.equal(nil)
        end)

        it("ApplyDescription() should apply R6 rig", function()
            local character = l15.Character
            local rigParts = {unpack(rawget(l15, "RigParts"))}
            l15:ApplyDescription(testDescription, Enum.HumanoidRigType.R6)
            for _,part in ipairs(rigParts) do
                expect(part.Parent).to.equal(nil)
            end
            expect(character:FindFirstChild("Humanoid")).to.equal(nil)
            expect(character:FindFirstChild("Animate")).to.equal(nil)
            expect(character:FindFirstChild("Shirt")).to.equal(nil)
            expect(character:FindFirstChild("Pants")).to.equal(nil)
            expect(character:FindFirstChild("Body Colors")).to.equal(nil)
            expect(character.Accessories:FindFirstChild("Black Bow"):IsA("Accessory")).to.equal(true)
            expect(character.Accessories:FindFirstChild("Bun with Waves"):IsA("Accessory")).to.equal(true)
            expect(character.Head.Color).to.equal(bodyColor)
            expect(character["Left Arm"].Color).to.equal(bodyColor)
            expect(character["Right Arm"].Color).to.equal(bodyColor)
            expect(character["Left Leg"].Color).to.equal(bodyColor)
            expect(character["Right Leg"].Color).to.equal(bodyColor)
            expect(character["Torso"].Color).to.equal(bodyColor)
            expect(character.Head.face.Texture:match("209713952")).to.never.equal(nil)
        end)

        it("ApplyDescription() should support faceless rigs", function()
            local humanoidDescription = Instance.new("HumanoidDescription")
            humanoidDescription.Head = 134082579

            expect(function()
                l15:ApplyDescription(humanoidDescription)
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
