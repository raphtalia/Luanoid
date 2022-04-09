---
sidebar_position: 1
---

# Getting Started

Luanoids are an alternative to Roblox Humanoids originally written by [LPGhatguy](https://github.com/LPGhatguy) as a [2018 Hack Week project](https://github.com/LPGhatguy/luanoid).

## Installation

Luanoid can be installed with [Wally](https://wally.run) by adding it to the `[dependencies]` section of your `wally.toml` file.

```toml
[package]
name = "your_name/your_project"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
Luanoid = "raphtalia/luanoid@^1"
```

## Limitations

- :white_check_mark: - Fully supported
- :warning: - Partially supported
- :soon: - Not yet supported
- :x: - Will not be supported

|        Feature         |       Status       | Notes                                                                                                                                                        |
| :--------------------: | :----------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|      Accessories       | :white_check_mark: | Can only be applied on the server                                                                                                                            |
|        Packages        |     :warning:      | Can only be applied on the server, Anthro packages will not be skilled properly work due to the lack of a Humanoid                                           |
|        Clothing        |     :warning:      | See [Clothing Support](clothingSupport)                                                                                                                      |
|       Animations       | :white_check_mark: | Must be loaded first on the server                                                                                                                           |
|        Swimming        |       :soon:       |                                                                                                                                                              |
|        Climbing        |       :soon:       | Implementation will likely require climbable Instances to have a "Climbable" [tag](https://developer.roblox.com/en-us/api-reference/class/CollectionService) |
|        Sitting         |       :soon:       |                                                                                                                                                              |
| Custom CharacterStates |       :soon:       | Easier for developers to use their own CharacterStates                                                                                                       |
|         Tools          |        :x:         | At most support for equipping/dequipping tools may be added, any further support would be difficult due to lack of support with non-humanoid characters      |
