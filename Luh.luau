--!strict

local Error = require("./Error")
local Lexer = require("./Lexer")
local Parser = require("./Parser")

local Luh = {}

local function OnError(Message: string)
    print(Message)
end

function Luh.Run(Source: string)
    Error.Listen(OnError)

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
    TokenParser:Parse()

    if Error.ShouldHalt then
        print("Parse failed. Exiting.")
        return
    end
end

return Luh