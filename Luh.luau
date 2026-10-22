--!strict

local Lexer = require("Lexer")

local Luh = {}

Luh.HadError = false

function Luh.Run(Source: string)
    local SourceLexer = Lexer.New(Source)

    for _, Token in SourceLexer:ScanTokens() do
        print(Token)
    end
end

function Luh.Report(Line: number, Where: string, Message: string)
    print(`[line {Line}] Error{Where}: {Message}`)
    Luh.HadError = true
end

return Luh