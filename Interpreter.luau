--!strict

local Error = require("./Error")

local Token = require("./Token")
type Token = Token.Token

local Ast = require("./Ast")
type LiteralExpression = Ast.LiteralExpression
type UnaryExpression = Ast.UnaryExpression
type BinaryExpression = Ast.BinaryExpression
type Expression = Ast.Expression
type Ast = Ast.Ast

type RuntimeError = {
    Token: Token,
    Message: string,
}

local Interpreter = {}

function Interpreter.Run(Expression: Expression)
    local Result = nil

    local Ok, Err: RuntimeError = xpcall(
        function()
            Result = Interpreter.EvaluateExpression(Expression)
        end,
        function(Err: RuntimeError): RuntimeError
            return Err
        end)

    if not Ok then
        Error.Report(Err.Token.Location, Err.Message, Error.Type.Runtime)
        return
    end

    print(`{tonumber(Result)}`)
end

function Interpreter.Error(Token: Token, Message: string): ()
    error({
        Token = Token,
        Message = Message,
    }, 0)
end

function Interpreter.EvaluateExpression(Expression: Expression): any
    local Function = Interpreter.ExpressionMap[Expression.Type]
    return Function and Function(Expression)
end

function Interpreter.EvaluateBinary(Expression: BinaryExpression): any
    local BinaryFunction = Interpreter.BinaryFunctions[Expression.Operator.Type]
    local Left, Right = Interpreter.EvaluateExpression(Expression.Left), Interpreter.EvaluateExpression(Expression.Right)
    return BinaryFunction and BinaryFunction(Expression.Operator, Left, Right)
end

function Interpreter.EvaluateUnary(Expression: UnaryExpression): any
    local UnaryFunction = Interpreter.UnaryFunctions[Expression.Operator.Type]
    return UnaryFunction and UnaryFunction(Expression.Operator, Interpreter.EvaluateExpression(Expression.Expression))
end

function Interpreter.EvaluateLiteral(Expression: LiteralExpression): any
    local Evaluation = Interpreter.LiteralEvaluations[Expression.Value.Type]
    return Evaluation and Evaluation(Expression.Value.Lexeme)
end

Interpreter.BinaryFunctions = {
    [Token.Types.Plus] = function(Operator: Token, Left: any, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left + Right
        end

        Interpreter.Error(Operator, `Attempt to add {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.Minus] = function(Operator: Token, Left: any, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left - Right
        end

        Interpreter.Error(Operator, `Attempt to subtract {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.Star] = function(Operator: Token, Left: any, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left * Right
        end

        Interpreter.Error(Operator, `Attempt to multiply {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.Slash] = function(Operator: Token, Left: any, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left / Right
        end

        Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.DoubleSlash] = function(Operator: Token, Left: any, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left // Right
        end

        Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.Modulo] = function(Operator: Token, Left: any, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left % Right
        end

        Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.And] = function(Operator: Token, Left: any, Right: any): any
        return Left and Right
    end,
    [Token.Types.Or] = function(Operator: Token, Left, Right: any): any
        return Left or Right
    end,
    [Token.Types.Equal] = function(Operator: Token, Left, Right: any): any
        return Left == Right
    end,
    [Token.Types.NotEqual] = function(Operator: Token, Left, Right: any): any
        return Left ~= Right
    end,
    [Token.Types.Greater] = function(Operator: Token, Left, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left > Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.GreaterEqual] = function(Operator: Token, Left, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left >= Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.Less] = function(Operator: Token, Left, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left < Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}.`)
        return nil
    end,
    [Token.Types.LessEqual] = function(Operator: Token, Left, Right: any): any
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left <= Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}.`)
        return nil
    end,
} :: { [number]: (Operator: Token, Left: any, Right: any) -> any }

Interpreter.UnaryFunctions = {
    [Token.Types.Plus] = function(Operator: Token, Value: any): any
        local Type = typeof(Value)
        if Type == "number" then
            return Value
        end

        Interpreter.Error(Operator, `Attempt to use unary '+' on {typeof(Value)}.`)
        return nil
    end,
    [Token.Types.Minus] = function(Operator: Token, Value: any): any
        local Type = typeof(Value)
        if Type == "number" then
            return -Value
        end

        Interpreter.Error(Operator, `Attempt to use unary '-' on {typeof(Value)}.`)
        return nil
    end,
    [Token.Types.Not] = function(Operator: Token, Value: any): any
        return not Value
    end,
} :: { [number]: (Operator: Token, Value: any) -> any }

Interpreter.LiteralEvaluations = {
    [Token.Types.Number] = function(Lexeme: string): any
        return tonumber(Lexeme)
    end,
    [Token.Types.Identifier] = function(Lexeme: string): any
        return
    end,
    [Token.Types.String] = function(Lexeme: string): any
        return Lexeme
    end,
} :: { [number]: (Lexeme: string) -> any }

Interpreter.ExpressionMap = {
    LiteralExpression = Interpreter.EvaluateLiteral,
    UnaryExpression = Interpreter.EvaluateUnary,
    BinaryExpression = Interpreter.EvaluateBinary,
} :: { [string]: (Tree: Ast) -> any }

return Interpreter