--[[
    Behaves like Humanoid:BuildRigFromAttachments() but returns a rigged model.
    This wasn't implemented in the Luanoids as a method as I don't like the
    idea of needing a Luanoid object simply to rig a model.
    Source-code:
    https://developer.roblox.com/en-us/api-reference/function/Humanoid/BuildRigFromAttachments
]]

local function createJoint(jointName: string, att0: Attachment, att1: Attachment)
	local part0,part1 = att0.Parent,att1.Parent
	local newMotor = part1:FindFirstChild(jointName)

	if not (newMotor and newMotor:IsA("Motor6D")) then
		newMotor = Instance.new("Motor6D")
	end

	newMotor.Name = jointName

	newMotor.Part0 = part0
	newMotor.Part1 = part1

	newMotor.C0 = att0.CFrame
	newMotor.C1 = att1.CFrame

	newMotor.Parent = part1
end

local function buildJointsFromAttachments(part: BasePart, characterParts: {BasePart})
	if not part then
		return
	end

	-- first, loop thru all of the part's children to find attachments
	for _,attachment in pairs(part:GetChildren()) do
		if attachment:IsA("Attachment") then
			-- only do joint build from "RigAttachments"
			local attachmentName = attachment.Name
			local findPos = attachmentName:find("RigAttachment")
			if findPos then
				-- also don't make double joints (there is the same named
                -- rigattachment under two parts)
				local jointName = attachmentName:sub(1,findPos-1)
				if not part:FindFirstChild(jointName) then
					-- try to find other part with same rig attachment name
					for _,characterPart in pairs(characterParts) do
						if part ~= characterPart then
							local matchingAttachment = characterPart:FindFirstChild(attachmentName)
							if matchingAttachment and matchingAttachment:IsA("Attachment") then
								createJoint(jointName,attachment,matchingAttachment)
								buildJointsFromAttachments(characterPart,characterParts)
								break
							end
						end
					end
				end
			end
		end
	end
end

return function(rig)
	local rootPart = rig.HumanoidRootPart
	assert(rootPart,"Humanoid has no HumanoidRootPart.")

	local characterParts = {}

	for _,descendant in ipairs(rig:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(characterParts,descendant)
		end
	end

	buildJointsFromAttachments(rootPart,characterParts)
end
