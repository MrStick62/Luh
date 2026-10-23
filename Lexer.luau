--!strict

local Error = require("./Error")
local Token = require("./Token")
type Token = Token.Token

local Lexer = {}
Lexer.__index = Lexer

type LexerData = {
    Source: string,
    Tokens: { Token },

    Start: number,
    Current: number,
    Line: number,
}

export type Lexer = typeof(setmetatable({} :: LexerData, Lexer))

function Lexer.New(Source: string): Lexer
    local Self = {}

    Self.Source = Source
    Self.Tokens = {}

    Self.Start = 1
    Self.Current = 1
    Self.Line = 2

    return setmetatable(Self, Lexer)
end

function Lexer.ScanTokens(Self: Lexer): { Token }
    while not Self:IsAtEnd() do
        Self.Start = Self.Current
        Self:ScanToken()
    end

    return Self.Tokens
end

function Lexer.ScanToken(Self: Lexer)
    local Char = Self:PeekChar()

    local Action = Lexer.ReadChar[Char]

    if Action then
        Action(Self)
        return
    end

    if Self:IsDigit(Char) then
        Self:ReadNumber()
        return
    end

    if Self:IsAlpha(Char) then
        Self:ReadIdentifier()
        return
    end

    Error.Report(Self.Line, "", `Unexpected character '{Char}'`, Error.Severity.Halt)
    Self:Consume()
end

function Lexer.GetCurrentLexeme(Self: Lexer): string
    return Self.Source:sub(Self.Start, Self.Current - 1)
end

function Lexer.AddToken(Self: Lexer, Type: number)
    table.insert(Self.Tokens, Token.New(Type, Self:GetCurrentLexeme(), Self.Start))
end

function Lexer.Consume(Self: Lexer)
    Self.Current += 1
end

function Lexer.AddLine(Self: Lexer)
    Self.Line += 1
end

function Lexer.PeekChar(Self: Lexer, Offset: number?): string
    local Index = Self.Current + (Offset or 0)
    return Self.Source:sub(Index, Index)
end

function Lexer.IsAtEnd(Self: Lexer)
    return Self.Current > #Self.Source
end

function Lexer.IsDigit(Self: Lexer, Char: string): boolean
    local Num = Char:byte()
    return string.byte('0') <= Num and Num <= string.byte('9')
end

function Lexer.IsAlpha(Self: Lexer, Char: string): boolean
    local Num = Char:byte()
    local IsLower = string.byte('a') <= Num and Num <= string.byte('z')
    local IsUpper = string.byte('A') <= Num and Num <= string.byte('Z')
    return IsUpper or IsLower
end

function Lexer.ReadNumber(Self: Lexer)
    while Self:IsDigit(Self:PeekChar()) do
        Self:Consume()
    end

    if Self:PeekChar() == '.' and Self:IsDigit(Self:PeekChar(1)) then
        Self:Consume()

        while Self:IsDigit(Self:PeekChar()) do
            Self:Consume()
        end
    end

    Self:AddToken(Token.Types.Number)
end

function Lexer.ReadIdentifier(Self: Lexer)
    while Self:IsAlpha(Self:PeekChar()) do
        Self:Consume()
    end

    local Word = Self:GetCurrentLexeme()
    Self:AddToken(Lexer.Keywords[Word] or Token.Types.Identifier)
end

Lexer.ReadChar = {
    ['#'] = function(Self: Lexer)
        while Self:PeekChar() ~= '\n' and not Self:IsAtEnd() do
            Self:Consume()
        end
    end,
    ['('] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.LeftParenthesis)
    end,
    [')'] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.RightParenthesis)
    end,
    ['{'] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.LeftBrace)
    end,
    ['}'] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.RightBrace)
    end,
    [','] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.Comma)
    end,
    ['.'] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.Dot)
    end,
    ['-'] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.Minus)
    end,
    ['+'] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.Plus)
    end,
    ['*'] = function(Self: Lexer) 
        Self:Consume()
        Self:AddToken(Token.Types.Star)
    end,
    ['/'] = function(Self: Lexer)
        Self:Consume()

        if Self:PeekChar() == '/' then
            Self:Consume()
            Self:AddToken(Token.Types.DoubleSlash)
            return
        end

        Self:AddToken(Token.Types.Slash)
    end,
    ['='] = function(Self: Lexer) 
        Self:Consume()

        if Self:PeekChar() == '=' then
            Self:Consume()
            Self:AddToken(Token.Types.Equal)
            return
        end
        
        Self:AddToken(Token.Types.Equals)
    end,
    ['~'] = function(Self: Lexer)
        Self:Consume()

        if Self:PeekChar() == '=' then
            Self:Consume()
            Self:AddToken(Token.Types.NotEquals)
            return
        end

        local Char = Self.Source:sub(Self.Current, Self.Current)
        Error.Report(Self.Line, "", `Expected '=' to follow '~', but got '{Char}'`, Error.Severity.Halt)
    end,
    ['>'] = function(Self: Lexer)
        Self:Consume()

        if Self:PeekChar() == "=" then
            Self:Consume()
            Self:AddToken(Token.Types.GreaterEqual)
            return
        end

        Self:AddToken(Token.Types.Greater)
    end,
    ['<'] = function(Self: Lexer)
        Self:Consume()

        if Self:PeekChar() == "=" then
            Self:Consume()
            Self:AddToken(Token.Types.LessEqual)
            return
        end

        Self:AddToken(Token.Types.Less)
    end,
    ['"'] = function(Self: Lexer)
        Self:Consume()

        while Self:PeekChar() ~= '"' and not Self:IsAtEnd() do
            Self:Consume()
        end

        if Self:IsAtEnd() then
            Error.Report(Self.Line, "", "Unterminated string", Error.Severity.Halt)
            return
        end

        -- Trim outside parenthesis
        Self.Start += 1
        Self:AddToken(Token.Types.String)
        Self:Consume()
    end,
    [' '] = function(Self: Lexer) 
        Self:Consume()
    end,
    ['\r'] = function(Self: Lexer) 
        Self:Consume()
    end,
    ['\t'] = function(Self: Lexer) 
        Self:Consume()
    end,
    ['\n'] = function(Self: Lexer)
        Self:Consume()
        Self:AddLine()
    end
} :: { [string] : (Self: Lexer) -> () }

Lexer.Keywords = {
    And = Token.Types.And,
    Break = Token.Types.Break,
    Do = Token.Types.Do,
    Else = Token.Types.Else,
    Elseif = Token.Types.Elseif,
    End = Token.Types.End,
    False = Token.Types.False,
    For = Token.Types.For,
    Fun = Token.Types.Fun,
    If = Token.Types.If,
    In = Token.Types.In,
    Nil = Token.Types.Nil,
    Not = Token.Types.Not,
    Or = Token.Types.Or,
    Return = Token.Types.Return,
    Then = Token.Types.Then,
    True = Token.Types.True,
    Type = Token.Types.Type,
    Var = Token.Types.Var,
    While = Token.Types.While,
}

return Lexer