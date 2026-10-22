--!strict

local Lexer = {}
Lexer.__index = Lexer

type LexerData = {
    Source: string,
}

export type Lexer = typeof(setmetatable({} :: LexerData, Lexer))

local TokenTypes = {
    LeftParenthesis = 1,
    RightParenthesis = 2,
    LeftBrace = 3,
    RightBrace = 4,
    Comma = 4,
    Dot = 5,
    Minus = 6,
    Plus = 7,
    Semicolon = 8,
    Slash = 9,
    Star = 10,

    Equals = 11,
    Bang = 12,
    BangEquals = 13,
    DoubleEquals = 14,
    Greater = 15,
    GreaterEquals = 16,
    Less = 17,
    LessEquals = 18,

    Identifier = 19,
    String = 20,
    Number = 21,

    And = 22,
    Class = 23,
    Else = 24,
    False = 25,
    Fun = 26,
    -- not done!!
}

function Lexer.New(Source: string): Lexer
    local Self = {}

    Self.Source = Source

    return setmetatable(Self, Lexer)
end

function Lexer.ScanTokens(Self: Lexer): { string }

    return {}
end

return Lexer