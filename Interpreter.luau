--!strict

local Error = require("./Error")

local Environment = require("./Environment")
type Environment = Environment.Environment

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
type ForStatement = Ast.ForStatement
type Statement = Ast.Statement

type RuntimeError = {
    Token: Token,
    Message: string,
}

local Interpreter = {}
Interpreter.__index = Interpreter

type InterpreterData = {
    Environment: Environment,
}

export type Interpreter = typeof(setmetatable({} :: InterpreterData, Interpreter))

function Interpreter.New(): Interpreter
    local Self = {}

    Self.Environment = Environment.New()

    return setmetatable(Self, Interpreter)
end

function Interpreter.Run(Self: Interpreter, Statements: { Statement })
    local Ok, Err = xpcall(
        function()
            for _, Statement in Statements do
                Self:EvaluateStatement(Statement)
            end
        end,
        function(Err: RuntimeError): RuntimeError
            return Err
        end)

    if not Ok then
        Error.Report(Err.Token.Location, Err.Message, Error.Type.Runtime)
        return
    end
end

function Interpreter.Error(Token: Token, Message: string): ()
    error({
        Token = Token,
        Message = Message,
    }, 0)
end

---------------------------
-- Evaluating Statements --
---------------------------

function Interpreter.EvaluateStatement(Self: Interpreter, Statement: Statement): ()
    local Function = Interpreter.StatementMap[Statement.Type]
    Function(Self, Statement)
end

function Interpreter.EvaluateExpressionStatement(Self: Interpreter, Statement: ExpressionStatement)
    print(`{Self:EvaluateExpression(Statement.Expression)}`)
end

function Interpreter.EvaluateVariableStatement(Self: Interpreter, Statement: VariableStatement)
    local Value = Statement.Initializer and Self:EvaluateExpression(Statement.Initializer)
    Self.Environment:Define(Statement.Identifier.Lexeme, Value)
end

function Interpreter.EvaluateDoStatement(Self: Interpreter, Statement: DoStatement)
    local Scope = Environment.New(Self.Environment)
    Self:EvaluateBlock(Statement.Statements, Scope)
end

function Interpreter.EvaluateIfStatement(Self: Interpreter, Statement: IfStatement)
    local Scope = Environment.New(Self.Environment)
    if Self:EvaluateExpression(Statement.Default.Condition) then
        Self:EvaluateBlock(Statement.Default.Body, Scope)
    else
        for _, Elseif in Statement.Elseif do
            if Self:EvaluateExpression(Elseif.Condition) then
                Self:EvaluateBlock(Elseif.Body, Scope)
                return
            end
        end

        Self:EvaluateBlock(Statement.Else, Scope)
    end
end

function Interpreter.EvaluateWhileStatement(Self: Interpreter, Statement: WhileStatement)
    while Self:EvaluateExpression(Statement.Condition) do
        local Scope = Environment.New(Self.Environment)
        Self:EvaluateBlock(Statement.Body, Scope)
    end
end

function Interpreter.EvaluateForStatement(Self: Interpreter, Statement: ForStatement)
    local CounterValue = Self:EvaluateExpression(Statement.Initial)
    if typeof(CounterValue) ~= "number" then
        Interpreter.Error(Statement.Token, `Expected number for 'for' counter, got {typeof(CounterValue)}`)
    end

    local Limit = Self:EvaluateExpression(Statement.Limit)
    if typeof(Limit) ~= "number" then
        Interpreter.Error(Statement.Token, `Expected number for 'for' limit, got {typeof(Limit)}`)
    end

    local Increment = Statement.Increment and Self:EvaluateExpression(Statement.Increment) or 1
    if typeof(Increment) ~= "number" then
        Interpreter.Error(Statement.Token, `Expected number for 'for' increment, got {typeof(Increment)}`)
    end

    local Direction = math.sign(Increment)

    while true do
        if Direction == 1 and CounterValue > Limit or Direction == -1 and CounterValue < Limit then
            break
        end

        local Scope = Environment.New(Self.Environment)
        Scope:Define(Statement.Identifier.Lexeme, CounterValue)
        Self:EvaluateBlock(Statement.Body, Scope)

        CounterValue += Increment
    end
end

function Interpreter.EvaluateBlock(Self: Interpreter, Statements: { Statement }, Environment: Environment)
    local Outside = Self.Environment
    Self.Environment = Environment

    for _, Statement in Statements do
        Self:EvaluateStatement(Statement)
    end

    Self.Environment = Outside
end

Interpreter.StatementMap = {
    ExpressionStatement = Interpreter.EvaluateExpressionStatement,
    VariableStatement = Interpreter.EvaluateVariableStatement,
    DoStatement = Interpreter.EvaluateDoStatement,
    IfStatement = Interpreter.EvaluateIfStatement,
    WhileStatement = Interpreter.EvaluateWhileStatement,
    ForStatement = Interpreter.EvaluateForStatement,
} :: { [string]: (Self: Interpreter, Statement: Statement) -> () }

----------------------------
-- Evaluating Expressions --
----------------------------

function Interpreter.EvaluateExpression(Self: Interpreter, Expression: Expression): any
    local Function = Interpreter.ExpressionMap[Expression.Type]
    return Function and Function(Self, Expression)
end

function Interpreter.EvaluateBinaryExpression(Self: Interpreter, Expression: BinaryExpression): any
    local BinaryFunction = Interpreter.BinaryFunctions[Expression.Operator.Type]
    local Left = Self:EvaluateExpression(Expression.Left)
    return BinaryFunction and BinaryFunction(Self, Expression.Operator, Left, Expression.Right)
end

function Interpreter.EvaluateUnaryExpression(Self: Interpreter, Expression: UnaryExpression): any
    local UnaryFunction = Interpreter.UnaryFunctions[Expression.Operator.Type]
    return UnaryFunction and UnaryFunction(Self, Expression.Operator, Self:EvaluateExpression(Expression.Expression))
end

function Interpreter.EvaluateAssignmentExpression(Self: Interpreter, Expression: AssignmentExpression): any
    local AssignmentFunction = Interpreter.AssignmentFunctions[Expression.Operator.Type]
    local Right = Self:EvaluateExpression(Expression.Expression)
    return AssignmentFunction and AssignmentFunction(Self, Expression.Identifier, Expression.Operator, Right)
end

function Interpreter.EvaluateLiteralExpression(Self: Interpreter, Expression: LiteralExpression): any
    local Evaluation = Interpreter.LiteralEvaluations[Expression.Value.Type]
    return Evaluation and Evaluation(Self, Expression.Value.Lexeme)
end

Interpreter.BinaryFunctions = {
    [Token.Types.Plus] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        -- Why am I manually passing self only here? Try fixing it. See what kind of wrath the Luau Language Server inflicts upon you. God help us all.
        local Right = Interpreter.EvaluateExpression(Self, RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left + Right
        end

        Interpreter.Error(Operator, `Attempt to add {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Minus] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left - Right
        end

        Interpreter.Error(Operator, `Attempt to subtract {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Star] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left * Right
        end

        Interpreter.Error(Operator, `Attempt to multiply {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Slash] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left / Right
        end

        Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.DoubleSlash] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)
        
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left // Right
        end

        Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Modulo] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left % Right
        end

        Interpreter.Error(Operator, `Attempt to compute the remainder of {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Karat] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left ^ Right
        end

        Interpreter.Error(Operator, `Attempt to raise {LeftType} to the power of {RightType}`)
        return nil
    end,
    [Token.Types.DoubleDot] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "string" and RightType == "string" then
            return Left .. Right
        end

         Interpreter.Error(Operator, `Attempt to concatenate {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.And] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        return Left and Self:EvaluateExpression(RightExpr)
    end,
    [Token.Types.Or] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        return Left or Self:EvaluateExpression(RightExpr)
    end,
    [Token.Types.Xor] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        return not Left and Right or not Right and Left or (Left ~= Right or Left ~= true and Left ~= false) and nil
    end,
    [Token.Types.Equal] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        return Left == Self:EvaluateExpression(RightExpr)
    end,
    [Token.Types.NotEqual] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        return Left ~= Self:EvaluateExpression(RightExpr)
    end,
    [Token.Types.Greater] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left > Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.GreaterEqual] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left >= Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Less] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left < Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.LessEqual] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr)
        
        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left <= Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
} :: { [number]: (Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression) -> any }

Interpreter.UnaryFunctions = {
    [Token.Types.Plus] = function(Self: Interpreter, Operator: Token, Value: any): any
        local Type = typeof(Value)
        if Type == "number" then
            return Value
        end

        Interpreter.Error(Operator, `Attempt to use unary '+' on {typeof(Value)}`)
        return nil
    end,
    [Token.Types.Minus] = function(Self: Interpreter, Operator: Token, Value: any): any
        local Type = typeof(Value)
        if Type == "number" then
            return -Value
        end

        Interpreter.Error(Operator, `Attempt to use unary '-' on {typeof(Value)}`)
        return nil
    end,
    [Token.Types.Not] = function(Self: Interpreter, Operator: Token, Value: any): any
        return not Value
    end,
} :: { [number]: (Self: Interpreter, Operator: Token, Value: any) -> any }

Interpreter.AssignmentFunctions = {
    [Token.Types.Equals] = function(Self: Interpreter, Identifier: Token, Operator: Token, Value: any): any
        if Self.Environment:Assign(Identifier.Lexeme, Value) then
            return Value
        end

        Interpreter.Error(Identifier, `Unknown identifier '{Identifier.Lexeme}'`)
        return nil
    end,
    [Token.Types.PlusEquals] = function(Self: Interpreter, Identifier: Token, Operator: Token, Value: any): any
        local Left = Self.Environment:Get(Identifier.Lexeme)

        local LeftType, RightType = typeof(Left), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to add {LeftType} and {RightType}`)
            return nil
        end
        
        local Result = Left + Value
        Self.Environment:Assign(Identifier.Lexeme, Result)
        return Result
    end,
    [Token.Types.MinusEquals] = function(Self: Interpreter, Identifier: Token, Operator: Token, Value: any): any
        local Left = Self.Environment:Get(Identifier.Lexeme)

        local LeftType, RightType = typeof(Left), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to subtract {LeftType} and {RightType}`)
            return nil
        end
        
        local Result = Left - Value
        Self.Environment:Assign(Identifier.Lexeme, Result)
        return Result
    end,
    [Token.Types.StarEquals] = function(Self: Interpreter, Identifier: Token, Operator: Token, Value: any): any
        local Left = Self.Environment:Get(Identifier.Lexeme)

        local LeftType, RightType = typeof(Left), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to multiply {LeftType} and {RightType}`)
            return nil
        end
        
        local Result = Left * Value
        Self.Environment:Assign(Identifier.Lexeme, Result)
        return Result
    end,
    [Token.Types.SlashEquals] = function(Self: Interpreter, Identifier: Token, Operator: Token, Value: any): any
        local Left = Self.Environment:Get(Identifier.Lexeme)

        local LeftType, RightType = typeof(Left), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)
            return nil
        end
        
        local Result = Left / Value
        Self.Environment:Assign(Identifier.Lexeme, Result)
        return Result
    end,
    [Token.Types.DoubleSlashEquals] = function(Self: Interpreter, Identifier: Token, Operator: Token, Value: any): any
        local Left = Self.Environment:Get(Identifier.Lexeme)

        local LeftType, RightType = typeof(Left), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)
            return nil
        end
        
        local Result = Left // Value
        Self.Environment:Assign(Identifier.Lexeme, Result)
        return Result
    end,
    [Token.Types.ModuloEquals] = function(Self: Interpreter, Identifier: Token, Operator: Token, Value: any): any
        local Left = Self.Environment:Get(Identifier.Lexeme)

        local LeftType, RightType = typeof(Left), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to calculate the remainder of {LeftType} and {RightType}`)
            return nil
        end
        
        local Result = Left % Value
        Self.Environment:Assign(Identifier.Lexeme, Result)
        return Result
    end,
    [Token.Types.KaratEquals] = function(Self: Interpreter, Identifier: Token, Operator: Token, Value: any): any
        local Left = Self.Environment:Get(Identifier.Lexeme)

        local LeftType, RightType = typeof(Left), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to raise {LeftType} to the power of {RightType}`)
            return nil
        end
        
        local Result = Left ^ Value
        Self.Environment:Assign(Identifier.Lexeme, Result)
        return Result
    end,
} :: { [number]: (Self: Interpreter, Identifier: Token, Operator: Token, Value: any) -> any }

Interpreter.LiteralEvaluations = {
    [Token.Types.Number] = function(Self: Interpreter, Lexeme: string): any
        return tonumber(Lexeme)
    end,
    [Token.Types.Identifier] = function(Self: Interpreter, Lexeme: string): any
        return Self.Environment:Get(Lexeme)
    end,
    [Token.Types.String] = function(Self: Interpreter, Lexeme: string): any
        return Lexeme
    end,
    [Token.Types.True] = function(Self: Interpreter, Lexeme: string): any
        return true
    end,
    [Token.Types.False] = function(Self: Interpreter, Lexeme: string): any
        return false
    end,
    [Token.Types.Nil] = function(Self: Interpreter, Lexeme: string): any
        return nil
    end,
} :: { [number]: (Self: Interpreter, Lexeme: string) -> any }

Interpreter.ExpressionMap = {
    LiteralExpression = Interpreter.EvaluateLiteralExpression,
    UnaryExpression = Interpreter.EvaluateUnaryExpression,
    BinaryExpression = Interpreter.EvaluateBinaryExpression,
    AssignmentExpression = Interpreter.EvaluateAssignmentExpression,
} :: { [string]: (Self: Interpreter, Expression: Expression) -> any }

return Interpreter