--!strict

local Token = {}
Token.__index = Token

type TokenData = {
    Type: number,
    Lexeme: string,
    Line: number,
}

export type Token = typeof(setmetatable({} :: TokenData, Token))

function Token.New(Type: number, Lexeme: string, Line: number): Token
    local Self = {}

    Self.Type = Type
    Self.Lexeme = Lexeme
    Self.Line = Line

    return setmetatable(Self, Token)
end

Token.Types = {
    -- Symbols
    LeftParenthesis = 1,
    RightParenthesis = 2,
    LeftBrace = 3,
    RightBrace = 4,
    Comma = 5,
    Dot = 6,
    Minus = 7,
    Plus = 8,
    Semicolon = 9,
    Slash = 10,
    Star = 11,

    -- Comparison
    Equals = 12,
    NotEquals = 13,
    DoubleEquals = 14,
    Greater = 15,
    GreaterEquals = 16,
    Less = 17,
    LessEquals = 18,

    -- Literals
    Identifier = 19,
    String = 20,
    Number = 21,

    -- Keywords
    Local = 22,
    Nil = 23,
    True = 24,
    False = 25,
    Not = 26,
    And = 27,
    Or = 28,
    Fun = 29,
    End = 30,
    While = 31,
    Do = 32,
    If = 33,
    Then = 34,
    Else = 35,
    Type = 36,
    Return = 37,
}

return Token