--!strict

local Token = require("./Token")
type Token = Token.Token

local Interpreter = require("./Interpreter")
type Interpreter = Interpreter.Interpreter

local Globals = {}

function Globals.Load(Interpreter: Interpreter)
    Interpreter:LoadGlobal("print", print)
    Interpreter:LoadGlobal("tostring", tostring)
    Interpreter:LoadGlobal("meta", setmetatable)

    Interpreter:LoadGlobal("assert", assert)

    Interpreter:LoadGlobal("clock", {
        now = os.clock,
        time = os.time,
    })
end

return Globals