--!strict

local Token = {}
Token.__index = Token

type TokenData = {
    Type: number,
    Lexeme: string,
    Location: number,
}

export type Token = typeof(setmetatable({} :: TokenData, Token))

function Token.New(Type: number, Lexeme: string, Location: number): Token
    local Self = {}

    Self.Type = Type
    Self.Lexeme = Lexeme
    Self.Location = Location

    return setmetatable(Self, Token)
end

Token.Types = {
    EOF = 0,

    -- Character values
    Modulo = string.byte('%'),
    LeftParenthesis = string.byte('('),
    RightParenthesis = string.byte(')'),
    Star = string.byte('*'),
    Plus = string.byte('+'),
    Comma = string.byte(','),
    Minus = string.byte('-'),
    Dot = string.byte('.'),
    Slash = string.byte('/'),
    Less = string.byte('<'),
    Equals = string.byte('='),
    Greater = string.byte('>'),
    LeftBrace = string.byte('{'),
    RightBrace = string.byte('}'),

    -- Beyond byte values 256+
    Equal = 256,
    LessEqual = 257,
    GreaterEqual = 258,
    NotEqual = 259,
    DoublePlus = 260,
    -- Do NOT add unary double plus or double minus. Adds ambiguity to which statement it belongs to without semicolon for explicit statement end.

    -- Literals
    Identifier = 288,
    String = 289,
    Number = 290,

    -- Keywords
    And = 320,
    Break = 321,
    Do = 322,
    Else = 323,
    Elseif = 324,
    End = 325,
    False = 326,
    For = 327,
    Fun = 328,
    If = 329,
    In = 330,
    Nil = 331,
    Not = 332,
    Or = 333,
    Return = 334,
    Then = 335,
    True = 336,
    Type = 337,
    Var = 338,
    While = 339,
}

return Token