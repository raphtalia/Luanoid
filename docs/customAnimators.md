---
sidebar_position: 3
---

# Custom Animators

Animators simply need to be tables with at least the following functions.

```lua
local Animator = {}

function Animator.LoadAnimation(animation, name)

end

function Animator.PlayAnimation(name)

end

function Animator.StopAnimation(name)

end

function Animator.StopAnimations()

end

return Animator
```
