--!strict

local Error = require("./Error")
local Token = require("./Token")
type Token = Token.Token

local Ast = require("./Ast")
type LiteralExpression = Ast.LiteralExpression
type BinaryExpression = Ast.BinaryExpression
type UnaryExpression = Ast.UnaryExpression
type AssignmentExpression = Ast.AssignmentExpression
type Expression = Ast.Expression

type ExpressionStatement = Ast.ExpressionStatement
type VariableStatement = Ast.VariableStatement
type DoStatement = Ast.DoStatement
type IfStatement = Ast.IfStatement
type WhileStatement = Ast.WhileStatement
type Statement = Ast.Statement

type SyntaxError = {
    Token: Token,
    Message: string,
}

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
    error({
        Token = Token,
        Message = Message,
    }, 0)
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

    local Ok, Err = xpcall(
        function() 
            while not Self:IsAtEnd() do
                table.insert(Statements, Self:ParseStatement())
            end
        end, 
        function(Err: SyntaxError): SyntaxError
            return Err
        end)

    if not Ok then
        Error.Report(Err.Token.Location, Err.Message, Error.Type.Syntax)
    end

    return Statements
end

function Parser.ParseStatement(Self: Parser): Statement
    local Statement = Parser.StatementMap[Self:PeekToken().Type]
    if Statement then
        return Statement(Self)
    end

    return Ast.ExpressionStatement(Self:ParseExpression())
end

function Parser.ParseVar(Self: Parser): Statement
    Self:Advance()

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

function Parser.ParseBlock(Self: Parser, StartToken: Token): { Statement }
    local Statements = {}

    while not Self:Match(Token.Types.End) and not Self:IsAtEnd() do
        table.insert(Statements, Self:ParseStatement())
    end

    if Self:Match(Token.Types.End) then
        Self:Advance()
    else
        Parser.Error(StartToken, `Expected 'end' to close '{StartToken.Lexeme}' statement`)
    end

    return Statements
end

function Parser.ParseDo(Self: Parser): Statement
    return Ast.DoStatement(Self:ParseBlock(Self:Advance()))
end

-- I don't like this implementation. Take a look at this and clean it up later
function Parser.ParseIf(Self: Parser): Statement
    local IfToken = Self:Advance()

    local Condition = Self:ParseExpression()
    
    local ThenToken = Self:Advance()
    if ThenToken.Type ~= Token.Types.Then then
        Parser.Error(ThenToken, `Expected 'then' when parsing if statement, got {ThenToken.Lexeme}`)
    end

    local Body = {}
    local ElseIf = {}
    local Else = {}

    while not Self:Match(Token.Types.End) do
        while not Self:Match(Token.Types.Elseif, Token.Types.Else, Token.Types.End) and not Self:IsAtEnd() do
            if #ElseIf > 0 then
                table.insert(ElseIf[#ElseIf].Body, Self:ParseStatement())
            else
                table.insert(Body, Self:ParseStatement())
            end
        end

        if Self:Match(Token.Types.Elseif) then
            Self:Advance()
            local ElseIfExpression = Self:ParseExpression()

            local ElseIfThenToken = Self:Advance()
            if ThenToken.Type ~= Token.Types.Then then
                Parser.Error(ElseIfThenToken, `Expected 'then' when parsing 'if' statement, got {ThenToken.Lexeme}`)
            end

            table.insert(ElseIf, Ast.Conditional(ElseIfExpression, {}))
        elseif Self:Match(Token.Types.Else) then
            Else = Self:ParseBlock(Self:Advance())
            break
        end
    end

    if Self:Match(Token.Types.End) then
        Self:Advance()
    elseif not Else then
        Parser.Error(IfToken, `Expected 'end' to close if statement`)
    end

    return Ast.IfStatement(Ast.Conditional(Condition, Body), ElseIf, Else)
end

function Parser.ParseWhile(Self: Parser): Statement
    local WhileToken = Self:Advance()

    local Condition = Self:ParseExpression()

    local DoToken = Self:Advance()
    if DoToken.Type ~= Token.Types.Do then
        Parser.Error(DoToken, `Expected 'do' when parsing while loop, got '{DoToken.Lexeme}'`)
    end

    local Body = Self:ParseBlock(WhileToken)

    return Ast.WhileStatement(Condition, Body)
end

function Parser.ParseFor(Self: Parser): Statement
    local ForToken = Self:Advance()

    if not Self:Match(Token.Types.Identifier) then
        Parser.Error(Self:PeekToken(), `Expected identifier when parsing for loop, got '{Self:PeekToken().Lexeme}'`)
    end

    local Identifier = Self:Advance()

    if not Self:Match(Token.Types.Equals) then
        Parser.Error(Self:PeekToken(), `Expected '=' when parsing assignment, got '{Self:PeekToken().Lexeme}'`)
    end

    Self:Advance()

    local Initial = Self:ParseExpression() 
    
    if Self:Match(Token.Types.Comma) then
        Self:Advance()
    else
        Parser.Error(Self:PeekToken(), `Expected comma when parsing for loop, got '{Self:PeekToken().Lexeme}'`)
    end

    local Target = Self:ParseExpression()

    local Increment = nil
    if Self:Match(Token.Types.Comma) then
        Self:Advance()
        Increment = Self:ParseExpression()
    end

    local DoToken = Self:Advance()
    if DoToken.Type ~= Token.Types.Do then
        Parser.Error(DoToken, `Expected 'do' when parsing for loop, got '{DoToken.Lexeme}'`)
    end

    local Body = Self:ParseBlock(ForToken)

    return Ast.ForStatement(ForToken, Identifier, Initial, Target, Increment, Body)
end

function Parser.ParseFun(Self: Parser): Statement
    local FunctionToken = Self:Advance()

    if not Self:Match(Token.Types.Identifier) then
        Parser.Error(Self:PeekToken(), `Expected identifier when parsing function, got '{Self:PeekToken().Lexeme}'`)
    end

    local Identifier = Self:Advance()

    if not Self:Match(Token.Types.LeftParenthesis) then
        Parser.Error(Self:PeekToken(), `Expected '(' when parsing function, got '{Self:PeekToken().Lexeme}'`) 
    end

    Self:Advance()

    local Parameters = {}

    if not Self:Match(Token.Types.RightParenthesis) then
        repeat
            if not Self:Match(Token.Types.Identifier) then
                Parser.Error(Self:PeekToken(), `Expected identifier when parsing function parameters, got '{Self:PeekToken().Lexeme}'`)
            end

            table.insert(Parameters, Self:Advance())
        until not (Self:Match(Token.Types.Comma) and Self:Advance())
    end

    if not Self:Match(Token.Types.RightParenthesis) then
        Parser.Error(FunctionToken, `Expected ')' when parsing function,`)
    end

    Self:Advance()

    local Body = Self:ParseBlock(FunctionToken)

    return Ast.FunctionStatement(Identifier, Parameters, Body)
end

Parser.StatementMap = {
    [Token.Types.Var] = Parser.ParseVar,
    [Token.Types.Do] = Parser.ParseDo,
    [Token.Types.If] = Parser.ParseIf,
    [Token.Types.While] = Parser.ParseWhile,
    [Token.Types.For] = Parser.ParseFor,
    [Token.Types.Fun] = Parser.ParseFun,
}

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
    local Expression = Self:ParseCall()

    while Self:Match(Token.Types.Karat) do
        local Operator = Self:Advance()
        local Right = Self:ParseCall()
        Expression = Ast.BinaryExpression(Expression, Operator, Right)
    end

    return Expression
end

function Parser.ParseCall(Self: Parser): Expression
    local Expression = Self:ParsePrimary()

    while Self:Match(Token.Types.LeftParenthesis) do
        Self:Advance()

        local Arguments = {}

        if not Self:Match(Token.Types.RightParenthesis) then
            repeat
                table.insert(Arguments, Self:ParseExpression())
            until not (Self:Match(Token.Types.Comma) and Self:Advance())
        end

        if not Self:Match(Token.Types.RightParenthesis) then
            Parser.Error(Self:PeekToken(), `Expected ')' to close function call`)
        end

        Self:Advance()

        Expression = Ast.CallExpression(Expression, Arguments)
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