---
sidebar_position: 1
---

# Getting Started

Luanoids are an alternative to Roblox Humanoids originally written by [LPGhatguy](https://github.com/LPGhatguy) as a
[2018 Hack Week project](https://github.com/LPGhatguy/luanoid).

## Installation

Luanoid can be installed with [Wally](https://wally.run) by adding it to the `[dependencies]` section of your
`wally.toml` file.

```toml
[package]
name = "your_name/your_project"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
Luanoid = "raphtalia/luanoid@^1"
```

## Usage

The example below it will create a Luanoid character and have it walk somewhere.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Luanoid = require(ReplicatedStorage.Packages.Luanoid)

-- L15 is used to abbreviate Luanoid R15
local l15 = Luanoid.new()
l15:SetRig(ReplicatedStorage.DoguXCV:Clone())
l15.Character.Parent = workspace

l15:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(72938051), Enum.HumanoidRigType.R15)
l15.CharacterController:Start()

-- MoveTo() returns a Promise
if l15:MoveTo(Vector3.new(32, 0, 32)):expect() then
    print("reached target! :D")
else
    print("failed to reach target :(")
end
```

In the top-level [examples](https://github.com/raphtalia/Luanoid/tree/69a7b165676599fd2bcc132ee999a686a9eefbf5/examples)
directory there are binaries and source-code for for examples with
[server-side characters](https://github.com/raphtalia/Luanoid/tree/69a7b165676599fd2bcc132ee999a686a9eefbf5/examples/serverSideCharacters)
which is the same behavior as normal Roblox characters. Then there is an example of
[client-side characters](https://github.com/raphtalia/Luanoid/tree/69a7b165676599fd2bcc132ee999a686a9eefbf5/examples/clientSideCharacters)
where on the server each character is represented only as a HumanoidRootPart and the client applies the rig and
cosmetics. The source-code is reliant on a character model that cannot be synced with Rojo so for quick access you can
download the binaries, or download the character model from the assets directory and place it in ReplicatedStorage.

## Limitations

- :white_check_mark: - Fully supported
- :warning: - Partially supported
- :soon: - Not yet supported
- :x: - Will not be supported

|        Feature         |       Status       | Notes                                                                                                                                                        |
| :--------------------: | :----------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|      Accessories       | :white_check_mark: |                                                                                                                                                              |
|        Packages        |     :warning:      | Anthro packages will not be skinned properly work due to the lack of a Humanoid                                                                              |
|        Clothing        |     :warning:      | See [Clothing Support](clothingSupport)                                                                                                                      |
|       Animations       | :white_check_mark: |                                                                                                                                                              |
|        Swimming        |       :soon:       |                                                                                                                                                              |
|        Climbing        |       :soon:       | Implementation will likely require climbable Instances to have a "Climbable" [tag](https://developer.roblox.com/en-us/api-reference/class/CollectionService) |
|        Sitting         |       :soon:       |                                                                                                                                                              |
| Custom CharacterStates |       :soon:       | Easier for developers to use their own CharacterStates                                                                                                       |
|         Tools          |        :x:         | At most support for equipping/dequipping tools may be added, any further support would be difficult due to lack of support with non-humanoid characters      |
