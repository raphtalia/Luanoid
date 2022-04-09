---
sidebar_position: 4
---

# Clothing Support

<img src="/Luanoid/clothingSupportTextureID.png" alt="Clothing with Mesh.TextureID" height="250"/>

The default way clothing is applied is by setting `MeshPart.TextureID` on body parts to the clothing's asset ID. This results in textures not supporting transparency and taking on the background color the of asset.

<img src="/Luanoid/clothingSupportPBR.png" alt="Clothing with SurfaceAppearance" height="250"/>
<img src="/Luanoid/clothingSupportNative.png" alt="Clothing with native support" height="250"/>

A solution that allows for transparency with body part colors is to use a [`SurfaceAppearance`](https://developer.roblox.com/en-us/api-reference/class/SurfaceAppearance) in each body part with `SurfaceAppearance.ColorMap` set to the clothing's asset ID. This solution still has problems though such as shirts not being able to overlap the pants on the torso.

This solution is not applied as the default because `SurfaceAppearance.ColorMap` is not a scriptable property. So all clothes used must be generated as SurfaceAppearances before runtime and cloned into the characters when needed.
