--!strict

local Location = require("./Location")
type Location = Location.Location

local Token = {}
Token.__index = Token

type TokenData = {
    Type: number,
    Lexeme: string,
    Location: Location,
}

export type Token = typeof(setmetatable({} :: TokenData, Token))

function Token.New(Type: number, Lexeme: string, Location: Location): Token
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
    Colon = string.byte(':'),
    Less = string.byte('<'),
    Equals = string.byte('='),
    Greater = string.byte('>'),
    Karat = string.byte('^'),
    LeftBrace = string.byte('{'),
    RightBrace = string.byte('}'),

    -- Beyond byte values 256+
    Equal = 256,
    LessEqual = 257,
    GreaterEqual = 258,
    NotEqual = 259,
    DoubleSlash = 260,
    DoubleDot = 261,
    PlusEquals = 262,
    MinusEquals = 263,
    StarEquals = 264,
    SlashEquals = 265,
    DoubleSlashEquals = 266,
    ModuloEquals = 267,
    KaratEquals = 268,

    -- Literals
    Identifier = 288,
    String = 289,
    Number = 290,

    -- Keywords
    And = 320,
    Break = 321,
    Continue = 322,
    Do = 323,
    Else = 324,
    Elseif = 325,
    End = 326,
    False = 327,
    For = 328,
    Fun = 329,
    If = 330,
    In = 331,
    Nil = 332,
    Not = 333,
    Or = 334,
    Return = 335,
    Then = 336,
    True = 337,
    Type = 338,
    Var = 339,
    While = 340,
    Xor = 341,
}

return Token