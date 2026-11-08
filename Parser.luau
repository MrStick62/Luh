--!strict

local Error = require("./Error")
local Token = require("./Token")
type Token = Token.Token

local Ast = require("./Ast")
type Expression = Ast.Expression
type Statement = Ast.Statement

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

function Parser.Error(Token: Token, Message: string)
    if Token.Type == Token.Types.EOF then
        Error.Report(Token.Location, Message, Error.Type.Syntax)
    else
        Error.Report(Token.Location, Message, Error.Type.Syntax)
    end
end

function Parser.IsAtEnd(Self: Parser): boolean
    return if not Self:PeekToken() or Self:PeekToken().Type == Token.Types.EOF then true else false
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

function Parser.Match(Self: Parser, ...: number): boolean
    if Self:IsAtEnd() then
        return false
    end

    for _, Type in {...} do
        if Self:PeekToken().Type == Type then
            return true
        end
    end

    return false
end

function Parser.Parse(Self: Parser): { Statement }
    local Statements = {}

    while not Self:IsAtEnd() do
        table.insert(Statements, Self:ParseStatement())
    end

    return Statements
end

function Parser.ParseStatement(Self: Parser): Statement
    if Self:Match(Token.Types.Var) then
        Self:Advance()
        return Self:ParseVar()
    end

    if Self:Match(Token.Types.Do) then
        Self:Advance()
        return Self:ParseDo()
    end

    return Ast.ExpressionStatement(Self:ParseExpression())
end

function Parser.ParseVar(Self: Parser): Statement
    local Identifier = Self:Advance()
    if Identifier.Type ~= Token.Types.Identifier then
        Parser.Error(Identifier, `Expected identifier, got '{Identifier.Lexeme}'`)
    end

    local Initializer = nil
    if Self:Match(Token.Types.Equals) then
        Self:Advance()

        Initializer = Self:ParseExpression()
    end

    return Ast.VariableStatement(Identifier, Initializer)
end

function Parser.ParseDo(Self: Parser): Statement
    local Statements = {}

    local DoToken = Self:PreviousToken()

    while not Self:Match(Token.Types.End) and not Self:IsAtEnd() do
        table.insert(Statements, Self:ParseStatement())
    end

    if Self:Match(Token.Types.End) then
        Self:Advance()
    else
        Parser.Error(DoToken, `Expected 'end' to close 'do'`)
    end

    return Ast.DoStatement(Statements)
end

--[[
function Parser.ParseCommaExpression(Self: Parser): Expression
    local Expression = Self:ParseExpression()

    while Self:Match(Token.Types.Comma) do
        local Operator = Self:Advance()
        local Right = Self:ParseExpression()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end
]]

function Parser.ParseExpression(Self: Parser): Expression
    return Self:ParseAssignmentExpression()
end

function Parser.ParseAssignmentExpression(Self: Parser): Expression
    local Expression = Self:ParseXor()

    
    if Self:Match(Token.Types.Equals, Token.Types.PlusEquals, Token.Types.MinusEquals, Token.Types.StarEquals, 
            Token.Types.SlashEquals, Token.Types.DoubleSlashEquals, Token.Types.ModuloEquals, Token.Types.KaratEquals) then

        local Operator = Self:Advance()

        if Expression.Type ~= "LiteralExpression" or Expression.Value.Type ~= Token.Types.Identifier then
            return Expression
        end

        local Right = Self:ParseAssignmentExpression()
        return Ast.AssignmentExpression(Expression.Value, Operator, Right)
    end

    return Expression
end

function Parser.ParseXor(Self: Parser): Expression
    local Expression = Self:ParseOr()

    while Self:Match(Token.Types.Xor) do
        local Operator = Self:Advance()
        local Right = Self:ParseOr()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseOr(Self: Parser): Expression
    local Expression = Self:ParseAnd()

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
    local Expression = Self:ParseConcatenation()

    while Self:Match(Token.Types.Greater, Token.Types.GreaterEqual, Token.Types.Less, Token.Types.LessEqual) do
        local Operator = Self:Advance()
        local Right = Self:ParseConcatenation()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseConcatenation(Self: Parser): Expression
    local Expression = Self:ParseTerm()

    while Self:Match(Token.Types.DoubleDot) do
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
    
    while Self:Match(Token.Types.Star, Token.Types.Slash, Token.Types.DoubleSlash, Token.Types.Modulo) do
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

    return Self:ParseExponent()
end

function Parser.ParseExponent(Self: Parser): Expression
    local Expression = Self:ParsePrimary()

    while Self:Match(Token.Types.Karat) do
        local Operator = Self:Advance()
        local Right = Self:ParsePrimary()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParsePrimary(Self: Parser): Expression
    if Self:Match(Token.Types.LeftParenthesis) then
        Self:Advance()
        --local Expression = Self:ParseCommaExpression()
        local Expression = Self:ParseExpression()

        local Close = Self:PeekToken()
        if Close.Type == Token.Types.RightParenthesis then
            Self:Advance()
        else
            Parser.Error(Close, "Expected ')' to close expression.")
        end

        return Expression
    end

    if not Self:Match(Token.Types.Identifier, Token.Types.Number, Token.Types.String, Token.Types.Nil, Token.Types.True, Token.Types.False) then
        if Self:IsAtEnd() then
            Parser.Error(Self:PreviousToken(), `Expected expression, reached the end of the script`)
        else
            Parser.Error(Self:PeekToken(), `Expected expression, got '{Self:PeekToken().Lexeme}'`)
        end
    end

    return Ast.LiteralExpression(Self:Advance())
end


return Parser