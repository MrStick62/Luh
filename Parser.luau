--!strict

local Token = require("./Token")
type Token = Token.Token

local Ast = require("./Ast")
type Expression = Ast.Expression

local Parser = {}
Parser.__index = Parser

type ParserData = {
    Current: number,
    Tokens: { Token },
}

export type Parser = typeof(setmetatable({} :: ParserData, Parser))

function Parser.New(Tokens: { Token }): Parser
    local Self = {}

    Self.Current = 1
    Self.Tokens = Tokens

    return setmetatable(Self, Parser)
end

function Parser.IsAtEnd(Self: Parser, Offset: number?): boolean
    return Self:PeekToken().Type == Token.Types.EOF
end

function Parser.Advance(Self: Parser): Token
    Self.Current += 1
    return Self:PreviousToken()
end

function Parser.PeekToken(Self: Parser): Token
    return Self.Tokens[Self.Current]
end

function Parser.PreviousToken(Self: Parser): Token
    return Self.Tokens[Self.Current - 1]
end

function Parser.Check(Self: Parser, Type: number): boolean
    if Self:IsAtEnd() then
        return false
    end

    return Self.Tokens[Self.Current].Type == Type
end

function Parser.Match(Self: Parser, ...: number): boolean
    for _, Type in {...} do
        if Self:PeekToken().Type == Type then
            return true
        end
    end

    return false
end

function Parser.ParseExpression(Self: Parser): Expression
    return Self:ParseOr()
end

function Parser.ParseOr(Self: Parser): Expression
    local Expression = Self:ParseOr()

    while Self:Match(Token.Types.Or) do
        local Operator = Self:Advance()
        local Right = Self:ParseAnd()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseAnd(Self: Parser): Expression
    local Expression = Self:ParseEquality()

    while Self:Match(Token.Types.And) do
        local Operator = Self:Advance()
        local Right = Self:ParseEquality()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseEquality(Self: Parser): Expression
    local Expression = Self:ParseComparison()

    while Self:Match(Token.Types.Equal, Token.Types.NotEqual) do
        local Operator = Self:Advance()
        local Right = Self:ParseComparison()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseComparison(Self: Parser): Expression
    local Expression = Self:ParseComparison()

    while Self:Match(Token.Types.Greater, Token.Types.GreaterEqual, Token.Types.Less, Token.Types.LessEqual) do
        local Operator = Self:Advance()
        local Right = Self:ParseTerm()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseTerm(Self: Parser): Expression
    local Expression = Self:ParseFactor()

    while Self:Match(Token.Types.Plus, Token.Types.Minus) do
        local Operator = Self:Advance()
        local Right = Self:ParseFactor()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseFactor(Self: Parser): Expression
    local Expression = Self:ParseUnary()
    
    while Self:Match(Token.Types.Star, Token.Types.Slash, Token.Types.Modulo) do
        local Operator = Self:Advance()
        local Right = Self:ParseUnary()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseUnary(Self: Parser): Expression
    if Self:Match(Token.Types.Plus, Token.Types.Minus, Token.Types.Not) then
        local Operator = Self:Advance()
        return Ast.UnaryExpression(Operator, Self:ParseUnary())
    end

    return Self:ParsePrimary()
end

function Parser.ParsePrimary(Self: Parser): Expression
    local Current = Self:Advance()

    if Current.Type == Token.Types.LeftParenthesis then
        return Self:ParseExpression()
    end

    return Ast.LiteralExpression(Current)
end


return Parser