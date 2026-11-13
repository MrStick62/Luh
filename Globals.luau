--!strict

local Interpreter = require("./Interpreter")
type Interpreter = Interpreter.Interpreter

local Globals = {}

function Globals.Load(Interpreter: Interpreter)
    Interpreter:LoadGlobal(
        "print", 
        function(Arguments: { any }) 
            print(tostring(Arguments[1]))
        end
    )

    Interpreter:LoadGlobal(
        "tostring", 
        function(Arguments: { any }) 
            return tostring(Arguments[1])
        end
    )

    Interpreter:LoadGlobal(
        "table",
        { hehe = "Hello, World!" }
    )
end

return Globals