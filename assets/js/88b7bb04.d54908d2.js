"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[56],{68175:function(e){e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Creates a new CharacterController.","params":[{"name":"luanoid","desc":"","lua_type":"Luanoid"},{"name":"states","desc":"","lua_type":"CharacterState"},{"name":"fsm","desc":"","lua_type":"(characterController: CharacterController) -> CharacterState"}],"returns":[{"desc":"","lua_type":"CharacterController"}],"function_type":"static","source":{"line":140,"path":"src/CharacterController.lua"}},{"name":"CastCollideOnly","desc":"Casts a ray while ignoring all Instances with `CanCollide` set to `false`.\\nIntended for use primarily within the CharacterController.","params":[{"name":"origin","desc":"","lua_type":"Vector3"},{"name":"dir","desc":"","lua_type":"Vector3"}],"returns":[{"desc":"","lua_type":"RaycastResult"}],"function_type":"method","source":{"line":187,"path":"src/CharacterController.lua"}},{"name":"GetStateElapsedTime","desc":"Returns the elapsed time since the Luanoid entering its current state.","params":[],"returns":[{"desc":"","lua_type":"number"}],"function_type":"method","source":{"line":216,"path":"src/CharacterController.lua"}},{"name":"Start","desc":"Starts the CharacterController\'s simulation.","params":[],"returns":[],"function_type":"method","source":{"line":225,"path":"src/CharacterController.lua"}},{"name":"Stop","desc":"Stops the CharacterController\'s simulation.","params":[],"returns":[],"function_type":"method","source":{"line":244,"path":"src/CharacterController.lua"}},{"name":"_step","desc":"Performs a single step of the CharacterController\'s simulation.","params":[{"name":"dt","desc":"","lua_type":"number"}],"returns":[],"function_type":"method","private":true,"source":{"line":261,"path":"src/CharacterController.lua"}}],"properties":[{"name":"Luanoid","desc":"Reference to the Luanoid this CharacterController is attached to.\\n        ","lua_type":"Luanoid","readonly":true,"source":{"line":32,"path":"src/CharacterController.lua"}},{"name":"RaycastParams","desc":"RaycastParams used to cast to the ground underneath the Luanoid\'s character.\\n        ","lua_type":"RaycastParams","source":{"line":39,"path":"src/CharacterController.lua"}},{"name":"Running","desc":"Whether the CharacterController is currently running.\\n        ","lua_type":"boolean","readonly":true,"source":{"line":47,"path":"src/CharacterController.lua"}},{"name":"FiniteStateMachine","desc":"Callback that returns a `CharacterState` the Luanoid should currently be in.\\n        ","lua_type":"(characterController: CharacterController) -> CharacterState","source":{"line":54,"path":"src/CharacterController.lua"}},{"name":"States","desc":"Table of signals fired when a state is entered, leaving, or stepped.\\n        ","lua_type":"{[CharacterState]: { Entered: Signal, Leaving: Signal, Step: Signal }}","readonly":true,"source":{"line":62,"path":"src/CharacterController.lua"}},{"name":"LastState","desc":"The previous CharacterState applied to the Launoid.\\n        ","lua_type":"CharacterState","readonly":true,"source":{"line":70,"path":"src/CharacterController.lua"}},{"name":"StateEnterTick","desc":"The time the Luanoid entered its current CharacterState using `tick()`.\\n        ","lua_type":"number","readonly":true,"source":{"line":78,"path":"src/CharacterController.lua"}},{"name":"StateEnterPosition","desc":"The position the Luanoid entered its current CharacterState.\\n        ","lua_type":"Vector3","readonly":true,"source":{"line":86,"path":"src/CharacterController.lua"}},{"name":"RaycastResult","desc":"The CharacterController casts a ray to the ground from the corners\\nand center of the RootPart. This is the result of the ray hitting\\nclosest to the RootPart.\\n        ","lua_type":"RaycastResult","readonly":true,"source":{"line":96,"path":"src/CharacterController.lua"}},{"name":"RaycastResults","desc":"All rays casted by the CharacterController on this step of the\\nsimulation.\\n        ","lua_type":"{RaycastResult}","readonly":true,"source":{"line":105,"path":"src/CharacterController.lua"}},{"name":"Stores","desc":"Container for data to be stored and shared between the state\\nhandlers and FiniteStateMachine.\\n        ","lua_type":"{[string]: any}","source":{"line":113,"path":"src/CharacterController.lua"}}],"types":[],"name":"CharacterController","desc":"CharacterControllers are responsible for the state handling and physics of\\nthe Luanoid such as movement. Luanoids can accept different\\nCharacterControllers by setting the `CharacterController` propery on them.\\n\\nSee [Custom CharacterControllers](/docs/customCharacterControllers) for\\nwriting your own CharacterController.","source":{"line":21,"path":"src/CharacterController.lua"}}')}}]);