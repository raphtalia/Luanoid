"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[954],{15631:function(n){n.exports=JSON.parse('{"functions":[{"name":"_loadAnimation","desc":"","params":[{"name":"animation","desc":"","lua_type":"Animation"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","private":true,"source":{"line":112,"path":"src/Animator.lua"}},{"name":"LoadAnimation","desc":"Loads an animation into the Animator under a name that can be used to play\\nit later.","params":[{"name":"name","desc":"","lua_type":"string"},{"name":"animation","desc":"","lua_type":"Animation"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":129,"path":"src/Animator.lua"}},{"name":"PlayAnimation","desc":"Plays an animation loaded previously. Remaining arguments are passed to\\n`AnimationTrack:Play()`.","params":[{"name":"name","desc":"","lua_type":"string"},{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","source":{"line":157,"path":"src/Animator.lua"}},{"name":"StopAnimation","desc":"Stops a playing AnimationTrack. Remaining arguments are passed to\\n`AnimationTrack:Stop()`.","params":[{"name":"name","desc":"","lua_type":"string"},{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","source":{"line":178,"path":"src/Animator.lua"}},{"name":"StopAnimations","desc":"Stops all currently playing AnimationTracks. Arguments are passed to\\n`AnimationTrack:Stop()`.","params":[{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","source":{"line":198,"path":"src/Animator.lua"}},{"name":"UnloadAnimation","desc":"Unloads an animation from the Animator.","params":[{"name":"name","desc":"","lua_type":"string"}],"returns":[],"function_type":"method","source":{"line":211,"path":"src/Animator.lua"}},{"name":"UnloadAnimations","desc":"Unloads all animations from the Animator.","params":[],"returns":[],"function_type":"method","source":{"line":235,"path":"src/Animator.lua"}}],"properties":[{"name":"Luanoid","desc":"Reference to the Luanoid this CharacterController is attached to.\\n    ","lua_type":"Luanoid","readonly":true,"source":{"line":29,"path":"src/Animator.lua"}},{"name":"AnimationController","desc":"Reference to the AnimationController used internally.\\n    ","lua_type":"AnimationController","readonly":true,"source":{"line":35,"path":"src/Animator.lua"}},{"name":"Animator","desc":"Reference to the Animator used internally.\\n    ","lua_type":"Animator","readonly":true,"source":{"line":41,"path":"src/Animator.lua"}},{"name":"AnimationTracks","desc":"References to the loaded AnimationTracks.\\n    ","lua_type":"{[string]: AnimationTrack}","readonly":true,"source":{"line":47,"path":"src/Animator.lua"}},{"name":"AnimationPlayed","desc":"Fires after `PlayAnimation()` is executed.\\n    ","lua_type":"Signal<(animationTrack: AnimationTrack)>","readonly":true,"source":{"line":53,"path":"src/Animator.lua"}},{"name":"AnimationStopped","desc":"Fires after `StopAnimation()` is executed.\\n    ","lua_type":"Signal<(animationTrack: AnimationTrack)>","readonly":true,"source":{"line":59,"path":"src/Animator.lua"}},{"name":"AnimationLoaded","desc":"Fires after `LoadAnimation()` is executed.\\n    ","lua_type":"Signal<(animationTrack: AnimationTrack)>","readonly":true,"source":{"line":65,"path":"src/Animator.lua"}},{"name":"AnimationUnloading","desc":"Fires while `UnloadAnimation()` is executing.\\n    ","lua_type":"Signal<(animationTrack: AnimationTrack)>","readonly":true,"source":{"line":71,"path":"src/Animator.lua"}}],"types":[],"name":"Animator","desc":"Animators are\\nresponsible for playing animations on the Luanoid primarily through the\\nCharacterController. Luanoids can accept different Animators by setting the\\n`Animator` property on them.\\n\\nAnimations loaded on the server before the Client Luanoid is created will\\nautomatically be replicated.\\n\\nSee [Custom Animators](/docs/customAnimators) for writing your own\\nAnimator.","source":{"line":18,"path":"src/Animator.lua"}}')}}]);