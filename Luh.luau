--!strict

local Lexer = require("./Lexer")
local Error = require("./Error")

local Luh = {}

local function OnError(Message: string)
    print(Message)
end

function Luh.Run(Source: string)
    Error.Listen(OnError)

    local SourceLexer = Lexer.New(Source)

    for _, Token in SourceLexer:ScanTokens() do
        print(Token.Lexeme)
    end
end

return Luh