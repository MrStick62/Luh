--!strict

local Location = require("./Location")
type Location = Location.Location

local Error = require("./Error")
local Lexer = require("./Lexer")
local Parser = require("./Parser")
local Interpreter = require("./Interpreter")
local Globals = require("./Globals")

local Luh = {}

local function OnError(Source: string, Location: Location, Message: string)
    print(Message)
    print(Source:split('\n')[Location.Line])
    print(`{string.rep(' ', Location.Offset)}{string.rep('^', Location.Length)}`)
end

function Luh.Run(Source: string)
    Error.Listen(function(Location: Location, Message: string)
        OnError(Source, Location, Message)
    end)

    local SourceLexer = Lexer.New(Source)
    local Tokens = SourceLexer:ScanTokens()

    if Error.ShouldHalt then
        return
    end

    local TokenParser = Parser.New(Tokens)
    local Expression = TokenParser:Parse()

    if Error.ShouldHalt then
        return
    end

    local TreeInterpreter = Interpreter.New()

    Globals.Load(TreeInterpreter)

    local Output = TreeInterpreter:Run(Expression)
end

return Luh