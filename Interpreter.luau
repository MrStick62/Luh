--!strict

local Error = require("./Error")

local Token = require("./Token")
type Token = Token.Token

local Ast = require("./Ast")
type LiteralExpression = Ast.LiteralExpression
type UnaryExpression = Ast.UnaryExpression
type Expression = Ast.Expression
type Ast = Ast.Ast

local Interpreter = {}

function Interpreter.EvaluateExpression(Expression: Expression): any
    local Function = Interpreter.ExpressionMap[Expression.Type]
    return Function and Function(Expression)
end

function Interpreter.EvaluateUnary(Expression: UnaryExpression): any
    local UnaryFunction = Interpreter.UnaryFunctions[Expression.Operator.Type]
    return UnaryFunction and UnaryFunction(Interpreter.EvaluateExpression(Expression))
end

function Interpreter.EvaluateLiteral(Expression: LiteralExpression): any
    local Lexeme = Expression.Value.Lexeme
    return tonumber(Lexeme) or Lexeme
end

Interpreter.UnaryFunctions = {
    [Token.Types.Plus] = function(Value: any): any
        return tonumber(Value)
    end,
    [Token.Types.Minus] = function(Value: any): any
        local Number = tonumber(Value)
        return Number and -Number
    end,
    [Token.Types.Not] = function(Value: any): any
        return not Value
    end,
} :: { [number]: (Value: any) -> any }

Interpreter.ExpressionMap = {
    LiteralExpression = Interpreter.EvaluateLiteral,
    UnaryExpression = Interpreter.EvaluateUnary,
} :: { [string]: (Tree: Ast) -> any }

return Interpreter