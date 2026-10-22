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
    local SourceLength = #Self.Source

    while Self.Current <= SourceLength do
        Self.Start = Self.Current
        Self:ScanToken()
    end

    return Self.Tokens
end

function Lexer.ScanToken(Self: Lexer)
    local Char = Self.Source:sub(Self.Current, Self.Current)

    local Action = Lexer.ReadChar[Char]

    if Action then
        Action(Self)
    else
        Error.Report(Self.Line, "", `Unexpected character '{Char}'`, Error.Severity.Halt)
    end

    Self.Current += 1
end

function Lexer.AddToken(Self: Lexer, Type: number)
    local Lexeme = Self.Source:sub(Self.Start, Self.Current)
    table.insert(Self.Tokens, Token.New(Type, Lexeme, Self.Line))
end

function Lexer.Match(Self: Lexer, Char: string): boolean
    Self.Current += 1

    if Self.Current > #Self.Source then
        return false
    end

    return Self.Source:sub(Self.Current, Self.Current) == Char
end

Lexer.ReadChar = {
    ['('] = function(Self: Lexer) Self:AddToken(Token.Types.LeftParenthesis) end,
    [')'] = function(Self: Lexer) Self:AddToken(Token.Types.RightParenthesis) end,
    ['{'] = function(Self: Lexer) Self:AddToken(Token.Types.LeftBrace) end,
    ['}'] = function(Self: Lexer) Self:AddToken(Token.Types.RightBrace) end,
    [','] = function(Self: Lexer) Self:AddToken(Token.Types.Comma) end,
    ['.'] = function(Self: Lexer) Self:AddToken(Token.Types.Dot) end,
    ['-'] = function(Self: Lexer) Self:AddToken(Token.Types.Minus) end,
    ['+'] = function(Self: Lexer) Self:AddToken(Token.Types.Plus) end,
    [';'] = function(Self: Lexer) Self:AddToken(Token.Types.Comma) end,
    ['*'] = function(Self: Lexer) Self:AddToken(Token.Types.Star) end,
    ['~'] = function(Self: Lexer)
        if Self:Match('=') then
            Self:AddToken(Token.Types.NotEquals)
            return
        end

        local Char = Self.Source:sub(Self.Current, Self.Current)
        Error.Report(Self.Line, "", `Expected '=' to follow '~', but got '{Char}'`, Error.Severity.Halt)
    end,
} :: { [string] : (Self: Lexer) -> () }

return Lexer