--!strict

local Lexer = {}
Lexer.__index = Lexer

type LexerData = {
    Source: string,
}

export type Lexer = typeof(setmetatable({} :: LexerData, Lexer))

function Lexer.New(Source: string): Lexer
    local Self = {}

    Self.Source = Source

    return setmetatable(Self, Lexer)
end

function Lexer.ScanTokens(Self: Lexer): { string }

    return {}
end

return Lexer