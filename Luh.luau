--!strict

local Location = require("./Location")
type Location = Location.Location

local Error = require("./Error")
local Lexer = require("./Lexer")
local Parser = require("./Parser")
local Interpreter = require("./Interpreter")

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

    --[[
    for _, Token in SourceLexer:ScanTokens() do
        print(Token.Lexeme)
    end
    ]]

    if Error.ShouldHalt then
        print("Lexer failed. Exiting.")
        return
    end

    local TokenParser = Parser.New(Tokens)
    local Expression = TokenParser:Parse()

    if Error.ShouldHalt then
        print("Parse failed. Exiting.")
        return
    end

    local TreeInterpreter = Interpreter.New()
    TreeInterpreter:Run(Expression)
end

return Luh