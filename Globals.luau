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
end

return Globals