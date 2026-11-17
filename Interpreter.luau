--!strict

local Error = require("./Error")
type Error = Error.Error

local Reference = require("./Reference")
type Reference = Reference.Reference
type Tuple = Reference.Tuple

local Environment = require("./Environment")
type Environment = Environment.Environment

local Token = require("./Token")
type Token = Token.Token

local Ast = require("./Ast")

type LiteralExpression = Ast.LiteralExpression
type BinaryExpression = Ast.BinaryExpression
type UnaryExpression = Ast.UnaryExpression
type AssignmentExpression = Ast.AssignmentExpression
type CallExpression = Ast.CallExpression
type SelfCallExpression = Ast.SelfCallExpression
type GetExpression = Ast.GetExpression
type IndexExpression = Ast.IndexExpression
type FunctionExpression = Ast.FunctionExpression
type TableExpression = Ast.TableExpression
type Expression = Ast.Expression

type ExpressionStatement = Ast.ExpressionStatement
type VariableStatement = Ast.VariableStatement
type DoStatement = Ast.DoStatement
type IfStatement = Ast.IfStatement
type WhileStatement = Ast.WhileStatement
type ForStatement = Ast.ForStatement
type ForEachStatement = Ast.ForEachStatement
type FunctionStatement = Ast.FunctionStatement
type JumpStatement = Ast.JumpStatement
type Statement = Ast.Statement

type RuntimeError = {
    Type: "__runtimeerror",
    Token: Token,
    Message: string,
}

type Jump = {
    Type: "__jump",
    Keyword: Token,
    Tuple: Tuple,
}

local Interpreter = {}
Interpreter.__index = Interpreter

type InterpreterData = {
    GlobalEnvironment: Environment,
    Error: Error,
}

export type Interpreter = typeof(setmetatable({} :: InterpreterData, Interpreter))

function Interpreter.New(Error: Error): Interpreter
    local Self = {}

    Self.GlobalEnvironment = Environment.New()
    Self.Error = Error

    return setmetatable(Self, Interpreter)
end

function Interpreter.LoadGlobal(Self: Interpreter, Identifier: string, Value: any)
    if typeof(Value) == "table" then
        table.freeze(Value)
    end

    Self.GlobalEnvironment:Define(Identifier, Value, true)
end

function Interpreter.Run(Self: Interpreter, Statements: { Statement })
    local Ok, Err: Jump | RuntimeError = xpcall(
        function()
            local Environment = Environment.New()
            for _, Statement in Statements do
                Self:EvaluateStatement(Environment, Statement)
            end
        end,
        function(Err)
            if typeof(Err) == "table" then
                return Err
            end

            return debug.traceback(tostring(Err), 2)
        end)

    if not Ok then
        if Err.Type == "__jump" then
            if Err.Keyword.Type == Token.Types.Return then
                return Err.Tuple
            else
                Self.Error:Report(Err.Keyword.Location, `Attempt to call {Err.Keyword.Lexeme} statement outside of a loop`, Error.Type.Runtime)
            end
        elseif Err.Type == "__runtimeerror" then
            Self.Error:Report(Err.Token.Location, Err.Message, Error.Type.Runtime)
        else
            error(Err, 0)
        end
    end

    return { n = 0 }
end

function Interpreter.Error(Token: Token, Message: string)
    error({
        Type = "__runtimeerror",
        Token = Token,
        Message = Message,
    }, 0)
end

function Interpreter.Jump(Keyword: Token, Tuple: Tuple)
    error({
        Type = "__jump",
        Keyword = Keyword,
        Tuple = Tuple,
    }, 0)
end

---------------------------
-- Evaluating Statements --
---------------------------

function Interpreter.EvaluateStatement(Self: Interpreter, Environment: Environment, Statement: Statement): ()
    local Function = Interpreter.StatementMap[Statement.Type]
    Function(Self, Environment, Statement)
end

function Interpreter.EvaluateExpressionStatement(Self: Interpreter, Environment: Environment, Statement: ExpressionStatement)
    Self:EvaluateExpression(Environment, Statement.Expression)
end

function Interpreter.EvaluateVariableStatement(Self: Interpreter, Environment: Environment, Statement: VariableStatement)
    local Right = Self:EvaluateTupleExpression(Environment, Statement.Initializers)

    for i, Identifier in Statement.Identifiers do
        Environment:Define(Identifier.Lexeme, Right[i])
    end
end

function Interpreter.EvaluateDoStatement(Self: Interpreter, Environment: Environment, Statement: DoStatement)
    local Scope = Environment.New(Environment)
    Self:EvaluateBlock(Statement.Statements, Scope)
end

function Interpreter.EvaluateIfStatement(Self: Interpreter, Environment: Environment, Statement: IfStatement)
    local Scope = Environment.New(Environment)
    if Self:EvaluateExpression(Environment, Statement.Default.Condition):Get() then
        Self:EvaluateBlock(Statement.Default.Body, Scope)
    else
        for _, Elseif in Statement.Elseif do
            if Self:EvaluateExpression(Environment, Elseif.Condition):Get() then
                Self:EvaluateBlock(Elseif.Body, Scope)
                return
            end
        end

        Self:EvaluateBlock(Statement.Else, Scope)
    end
end

function Interpreter.EvaluateWhileStatement(Self: Interpreter, Environment: Environment, Statement: WhileStatement)
    while Self:EvaluateExpression(Environment, Statement.Condition):Get() do
        local Scope = Environment.New(Environment)
        local Jump = Self:CatchJump(Statement.Body, Scope)
        if Jump then
            if Jump.Keyword.Type == Token.Types.Break then
                break
            elseif Jump.Keyword.Type == Token.Types.Continue then
                continue
            elseif Jump.Keyword.Type == Token.Types.Return then
                Interpreter.Jump(Jump.Keyword, Jump.Tuple)
            end
        end
    end
end

function Interpreter.EvaluateForStatement(Self: Interpreter, Environment: Environment, Statement: ForStatement)
    local CounterValue = Self:EvaluateExpression(Environment, Statement.Initial):Get()
    if typeof(CounterValue) ~= "number" then
        Interpreter.Error(Statement.Keyword, `Expected number for 'for' counter, got {typeof(CounterValue)}`)
    end

    local Limit = Self:EvaluateExpression(Environment, Statement.Limit):Get()
    if typeof(Limit) ~= "number" then
        Interpreter.Error(Statement.Keyword, `Expected number for 'for' limit, got {typeof(Limit)}`)
    end

    local Increment = Statement.Increment and Self:EvaluateExpression(Environment, Statement.Increment):Get() or 1
    if typeof(Increment) ~= "number" then
        Interpreter.Error(Statement.Keyword, `Expected number for 'for' increment, got {typeof(Increment)}`)
    end

    local Direction = math.sign(Increment)

    while true do
        if Direction == 1 and CounterValue > Limit or Direction == -1 and CounterValue < Limit then
            break
        end

        local Scope = Environment.New(Environment)
        Scope:Define(Statement.Identifier.Lexeme, CounterValue)
        local Jump = Self:CatchJump(Statement.Body, Scope)
        
        CounterValue += Increment

        if Jump then
            if Jump.Keyword.Type == Token.Types.Break then
                break
            elseif Jump.Keyword.Type == Token.Types.Continue then
                continue
            elseif Jump.Keyword.Type == Token.Types.Return then
                Interpreter.Jump(Jump.Keyword, Jump.Tuple)
            end
        end
    end
end

function Interpreter.EvaluateForEachStatement(Self: Interpreter, Environment: Environment, Statement: ForEachStatement)
    local Target = Self:EvaluateTupleExpression(Environment, Statement.Arguments)

    local Iterator = next

    if Interpreter.HasMetaMethod(Target[1], "__iter") then
        Target = table.pack(getmetatable(Target[1]).__iter(Target[1]))
    end

    if typeof(Target[1]) == "function" then
        Iterator = Target[1]
        table.remove(Target, 1)
    elseif typeof(Target) ~= "table" then
        Interpreter.Error(Statement.Keyword, `Attempt to iterate over {typeof(Target)} value`)
    end

    while true do
        local Results = table.pack(Iterator(table.unpack(Target)))

        Target[2] = Results[1]

        if Results[1] == nil then
            break
        end

        local Scope = Environment.New(Environment)

        for i = 1, #Statement.Identifiers do
            Scope:Define(Statement.Identifiers[i].Lexeme, Results[i])
        end

        local Jump = Self:CatchJump(Statement.Body, Scope)
        if Jump then
            if Jump.Keyword.Type == Token.Types.Break then
                break
            elseif Jump.Keyword.Type == Token.Types.Continue then
                continue
            elseif Jump.Keyword.Type == Token.Types.Return then
                Interpreter.Jump(Jump.Keyword, Jump.Tuple)
            end
        end
    end
end

function Interpreter.EvaluateFunctionStatement(Self: Interpreter, Environment: Environment, Statement: FunctionStatement)
    local Source = Statement.Identifiers[1]

    if #Statement.Identifiers == 1 then
        Self.GlobalEnvironment:Define(Source.Lexeme, Self:FunctionToValue(Environment, Statement.Parameters, Statement.Body))
        return
    end

    local Table = Environment:Find(Source.Lexeme) or Self.GlobalEnvironment:Find(Source.Lexeme)

    if not Table then
        Interpreter.Error(Source, `Attempt to access undefined variable '{Source.Lexeme}'`)
        return
    end

    local Current = Table:Get()
    for i = 2, #Statement.Identifiers - 1 do
        if typeof(Current) ~= "table" then
            Interpreter.Error(Statement.Identifiers[i], `Attempt to index {typeof(Current)} with '{Statement.Identifiers[i].Lexeme}'`)
        end

        Current = Current[Statement.Identifiers[i].Lexeme]
    end

    local Identifier = Statement.Identifiers[#Statement.Identifiers]
    if typeof(Current) ~= "table" then
        Interpreter.Error(Identifier, `Attempt to index {typeof(Current)} with '{Identifier.Lexeme}'`)
    end

    Current[Identifier.Lexeme] = Self:FunctionToValue(Environment, Statement.Parameters, Statement.Body)
end

function Interpreter.EvaluateJumpStatement(Self: Interpreter, Environment: Environment, Statement: JumpStatement)
    local Tuple = {}
    Tuple.n = #Statement.Tuple

    for i, Value in Statement.Tuple do
        Tuple[i] = Self:EvaluateExpression(Environment, Value):Get()
    end

    Interpreter.Jump(Statement.Keyword, Tuple)
end

function Interpreter.EvaluateBlock(Self: Interpreter, Statements: { Statement }, Environment: Environment)
    for _, Statement in Statements do
        Self:EvaluateStatement(Environment, Statement)
    end
end

function Interpreter.CatchJump(Self: Interpreter, Statements: { Statement }, Environment: Environment): Jump?
    local Ok, Err: RuntimeError | Jump = xpcall(
        function()
            Self:EvaluateBlock(Statements, Environment)
        end, 
        function(Err)
            if typeof(Err) == "table" then
                return Err
            end

            return debug.traceback(tostring(Err), 2)
        end)

    if not Ok then
        if Err.Type == "__jump" then
            return Err
        elseif Err.Type == "__runtimeerror" then
            Interpreter.Error(Err.Token, Err.Message)
        else
            error(Err, 0)
        end
    end

    return nil
end

function Interpreter.FunctionToValue(Self: Interpreter, Environment: Environment, Parameters: { Token }, Body: { Statement }): (Token, { any }) -> (any)
    local Outside = Environment.New(Environment)

    return function(...: any): ...any
        local Arguments = {...}
        local Scope = Environment.New(Outside)

        for i, Parameter in Parameters do
            Scope:Define(Parameter.Lexeme, Arguments[i])
        end

        local Return = Self:CatchJump(Body, Scope)

        if Return then
            if Return.Keyword.Type == Token.Types.Return then
                return table.unpack(Return.Tuple, 1, Return.Tuple.n)
            end
        end

        return nil
    end
end

Interpreter.StatementMap = {
    ExpressionStatement = Interpreter.EvaluateExpressionStatement,
    VariableStatement = Interpreter.EvaluateVariableStatement,
    DoStatement = Interpreter.EvaluateDoStatement,
    IfStatement = Interpreter.EvaluateIfStatement,
    WhileStatement = Interpreter.EvaluateWhileStatement,
    ForStatement = Interpreter.EvaluateForStatement,
    ForEachStatement = Interpreter.EvaluateForEachStatement,
    FunctionStatement = Interpreter.EvaluateFunctionStatement,
    JumpStatement = Interpreter.EvaluateJumpStatement,
} :: { [string]: (Self: Interpreter, Environment: Environment, Statement: Statement) -> () }

----------------------------
-- Evaluating Expressions --
----------------------------

function Interpreter.EvaluateTupleExpression(Self: Interpreter, Environment: Environment, Expressions: { Expression }, Offset: number?): Tuple
    local Results = {}

    local Index = 1 + (Offset or 0)

    if #Expressions > 0 then
        for i = 1, #Expressions - 1 do
            Results[Index] = Self:EvaluateExpression(Environment, Expressions[i]):Get()
            Index += 1
        end

        local Tuple = Self:EvaluateExpression(Environment, Expressions[#Expressions]):GetAll()
        for i = 1, Tuple.n do
            Results[Index] = Tuple[i]
            Index += 1
        end
    end

    Results.n = Index - 1
    return Results
end

function Interpreter.EvaluateExpression(Self: Interpreter, Environment: Environment, Expression: Expression): Reference
    local Function = Interpreter.ExpressionMap[Expression.Type]
    return Function and Function(Self, Environment, Expression)
end

function Interpreter.EvaluateBinaryExpression(Self: Interpreter, Environment: Environment, Expression: BinaryExpression): Reference
    local BinaryFunction = Interpreter.BinaryFunctions[Expression.Operator.Type]
    local Left = Self:EvaluateExpression(Environment, Expression.Left):Get()
    return BinaryFunction and Reference.New(BinaryFunction(Self, Environment, Expression.Operator, Left, Expression.Right))
end

function Interpreter.EvaluateUnaryExpression(Self: Interpreter, Environment: Environment, Expression: UnaryExpression): Reference
    local UnaryFunction = Interpreter.UnaryFunctions[Expression.Operator.Type]
    return UnaryFunction and Reference.New(UnaryFunction(Self, Expression.Operator, Self:EvaluateExpression(Environment, Expression.Expression):Get()))
end

function Interpreter.EvaluateAssignmentExpression(Self: Interpreter, Environment: Environment, Expression: AssignmentExpression): Reference
    local AssignmentFunction = Interpreter.AssignmentFunctions[Expression.Operator.Type]

    if not AssignmentFunction then
        return Reference.New(nil)
    end

    local Right = Self:EvaluateTupleExpression(Environment, Expression.Right)

    local Results = {}
    for i, Identifier in Expression.Left do
        local Left = Self:EvaluateExpression(Environment, Identifier)
        local Result = AssignmentFunction(Left:Get(), Expression.Operator, Right[i])

        if not Left:Set(Result) then
            Interpreter.Error(Expression.Operator, `Attempt to assign non-mutable value`)
        end

        Results[i] = Result
    end
    
    return Reference.Tuple(table.unpack(Results, 1, #Expression.Left))
end

function Interpreter.EvaluateLiteralExpression(Self: Interpreter, Environment: Environment, Expression: LiteralExpression): Reference
    local Evaluation = Interpreter.LiteralEvaluations[Expression.Value.Type]
    return Evaluation and Evaluation(Self, Environment, Expression.Value)
end

function Interpreter.EvaluateCallExpression(Self: Interpreter, Environment: Environment, Expression: CallExpression): Reference
    local Function = Self:EvaluateExpression(Environment, Expression.Function):Get()

    if typeof(Function) ~= "function" then
        Interpreter.Error(Expression.Token, `Attempt to call a {typeof(Function)} value`)
    end

    local Arguments = Self:EvaluateTupleExpression(Environment, Expression.Arguments)

    local Result = Reference.New(nil)

    local OK, Err = xpcall(
        function(...)
            Result = Reference.Tuple(Function(table.unpack(Arguments, 1, Arguments.n)))
        end, 
        function(Err)
            return Err
        end)

    if not OK then
        Interpreter.Error(Expression.Token, Err)
    end

    return Result
end

function Interpreter.EvaluateSelfCallExpression(Self: Interpreter, Environment: Environment, Expression: SelfCallExpression): Reference
    local Table = Self:EvaluateExpression(Environment, Expression.Left):Get()

    if typeof(Table) ~= "table" then
        Interpreter.Error(Expression.Operator, `Attempt to index {typeof(Table)} with '{Expression.Name.Lexeme}'`)
    end

    local Function = Table[Expression.Name.Lexeme]

    if typeof(Function) ~= "function" then
        Interpreter.Error(Expression.Operator, `Attempt to call a {typeof(Function)} value`)
    end

    local Arguments = Self:EvaluateTupleExpression(Environment, Expression.Arguments, 1)
    Arguments[1] = Table

    return Reference.Tuple(Function(table.unpack(Arguments, 1, Arguments.n)))
end

function Interpreter.EvaluateGetExpression(Self: Interpreter, Environment: Environment, Expression: GetExpression): Reference
    local Table = Self:EvaluateExpression(Environment, Expression.Left):Get()

    if typeof(Table) ~= "table" then
        Interpreter.Error(Expression.Operator, `Attempt to index {typeof(Table)} with '{Expression.Name.Lexeme}'`)
    end

    return Reference.FromTable(Table, Expression.Name.Lexeme)
end

function Interpreter.EvaluateIndexExpression(Self: Interpreter, Environment: Environment, Expression: IndexExpression): Reference
    local Table = Self:EvaluateExpression(Environment, Expression.Left):Get()
    local Index = Self:EvaluateExpression(Environment, Expression.Index):Get()

    if typeof(Table) ~= "table" then
        Interpreter.Error(Expression.Operator, `Attempt to index {typeof(Table)} with {typeof(Index)}`)
    end

    return Reference.FromTable(Table, Index)
end

function Interpreter.EvaluateFunctionExpression(Self: Interpreter, Environment: Environment, Expression: FunctionExpression): Reference
    return Reference.New(Self:FunctionToValue(Environment, Expression.Parameters, Expression.Body))
end

function Interpreter.EvaluateTableExpression(Self: Interpreter, Environment: Environment, Expression: TableExpression): Reference
    local Table = {}

    local ArrayIndex = 1

    for _, Pair in Expression.Elements do
        local Key: any = ArrayIndex

        if Pair.Key then
            if Pair.Key.Type == "LiteralExpression" then
                Key = Pair.Key.Value.Lexeme
            else
                Key = Self:EvaluateExpression(Environment, Pair.Key):Get()
            end
        else
            ArrayIndex += 1
        end

        Table[Key] = Self:EvaluateExpression(Environment, Pair.Value):Get()
    end

    return Reference.New(Table)
end

function Interpreter.HasMetaMethod(Table: any, Method: string): boolean
    local Meta = getmetatable(Table)
    if typeof(Meta) == "table" and typeof(Meta[Method]) == "function" then
        return true
    end

    return false
end

function Interpreter.TryAdd(Left: any, Operator: Token, Right: any): any
    local LeftType, RightType = typeof(Left), typeof(Right)
    if LeftType == "number" and RightType == "number" then
        return Left + Right
    end

    if Interpreter.HasMetaMethod(Left, "__add") or Interpreter.HasMetaMethod(Right, "__add") then
        return Left + Right
    end

    Interpreter.Error(Operator, `Attempt to add {LeftType} and {RightType}`)
    return nil
end

function Interpreter.TrySubtract(Left: any, Operator: Token, Right: any): any
    local LeftType, RightType = typeof(Left), typeof(Right)
    if LeftType == "number" and RightType == "number" then
        return Left - Right
    end

    if Interpreter.HasMetaMethod(Left, "__sub") or Interpreter.HasMetaMethod(Right, "__sub") then
        return Left - Right
    end

    Interpreter.Error(Operator, `Attempt to subtract {LeftType} and {RightType}`)     
    return nil
end

function Interpreter.TryMultiply(Left: any, Operator: Token, Right: any): any
    local LeftType, RightType = typeof(Left), typeof(Right)
    if LeftType == "number" and RightType == "number" then
        return Left * Right
    end

    if Interpreter.HasMetaMethod(Left, "__mul") or Interpreter.HasMetaMethod(Right, "__mul") then
        return Left * Right
    end

    Interpreter.Error(Operator, `Attempt to multiply {LeftType} and {RightType}`)          
    return nil
end

function Interpreter.TryDivide(Left: any, Operator: Token, Right: any): any
    local LeftType, RightType = typeof(Left), typeof(Right)
    if LeftType == "number" and RightType == "number" then
        return Left / Right
    end

    if Interpreter.HasMetaMethod(Left, "__div") or Interpreter.HasMetaMethod(Right, "__div") then
        return Left / Right
    end

    Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)   
    return nil
end

function Interpreter.TryFloorDivide(Left: any, Operator: Token, Right: any): any
    local LeftType, RightType = typeof(Left), typeof(Right)
    if LeftType == "number" and RightType == "number" then
            return Left // Right
    end

    if Interpreter.HasMetaMethod(Left, "__idiv") or Interpreter.HasMetaMethod(Right, "__idiv") then
        return Left // Right
    end

    Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)          
    return nil
end

function Interpreter.TryModulo(Left: any, Operator: Token, Right: any): any
    local LeftType, RightType = typeof(Left), typeof(Right)
    if LeftType == "number" and RightType == "number" then
        return Left % Right
    end

    if Interpreter.HasMetaMethod(Left, "__mod") or Interpreter.HasMetaMethod(Right, "__mod") then
        return Left % Right
    end

    Interpreter.Error(Operator, `Attempt to compute the remainder of {LeftType} and {RightType}`)   
    return nil
end

function Interpreter.TryPower(Left: any, Operator: Token, Right: any): any
    local LeftType, RightType = typeof(Left), typeof(Right)
    if LeftType == "number" and RightType == "number" then
        return Left ^ Right
    end

    if Interpreter.HasMetaMethod(Left, "__pow") or Interpreter.HasMetaMethod(Right, "__pow") then
        return Left ^ Right
    end

    Interpreter.Error(Operator, `Attempt to raise {LeftType} to the power of {RightType}`)
    return nil
end

Interpreter.BinaryFunctions = {
    [Token.Types.Plus] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        -- Why am I manually passing self only here? Try fixing it. See what kind of wrath the Luau Language Server inflicts upon you. God help us all.
        local Right = Interpreter.EvaluateExpression(Self, Environment, RightExpr):Get()

        return Interpreter.TryAdd(Left, Operator, Right)
    end,
    [Token.Types.Minus] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return Interpreter.TrySubtract(Left, Operator, Right)
    end,
    [Token.Types.Star] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return Interpreter.TryMultiply(Left, Operator, Right)
    end,
    [Token.Types.Slash] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return Interpreter.TryDivide(Left, Operator, Right)
    end,
    [Token.Types.DoubleSlash] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return Interpreter.TryFloorDivide(Left, Operator, Right)
    end,
    [Token.Types.Modulo] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return Interpreter.TryModulo(Left, Operator, Right)
    end,
    [Token.Types.Karat] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return Interpreter.TryPower(Left, Operator, Right)
    end,
    [Token.Types.DoubleDot] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        if Interpreter.HasMetaMethod(Left, "__concat") or Interpreter.HasMetaMethod(Right, "__concat") then
            return Left .. Right
        end

        return tostring(Left) .. tostring(Right)
    end,
    [Token.Types.And] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        return Left and Self:EvaluateExpression(Environment, RightExpr):Get()
    end,
    [Token.Types.Or] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        return Left or Self:EvaluateExpression(Environment, RightExpr):Get()
    end,
    [Token.Types.Xor] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return not Left and Right or not Right and Left or (Left ~= Right or Left ~= true and Left ~= false) and nil
    end,
    [Token.Types.Equal] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return Left == Right
    end,
    [Token.Types.NotEqual] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        return Left ~= Right
    end,
    [Token.Types.Greater] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left > Right
        end

        if LeftType == "string" and RightType == "string" then
            return Left > Right
        end

        if Interpreter.HasMetaMethod(Left, "__le") or Interpreter.HasMetaMethod(Right, "__le") then
            return Left > Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.GreaterEqual] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left >= Right
        end

        if LeftType == "string" and RightType == "string" then
            return Left >= Right
        end

        if Interpreter.HasMetaMethod(Left, "__lt") or Interpreter.HasMetaMethod(Right, "__lt") then
            return Left >= Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Less] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left < Right
        end

        if LeftType == "string" and RightType == "string" then
            return Left < Right
        end

        if Interpreter.HasMetaMethod(Left, "__lt") or Interpreter.HasMetaMethod(Right, "__lt") then
            return Left < Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)    
        return nil
    end,
    [Token.Types.LessEqual] = function(Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(Environment, RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left <= Right
        end

        if LeftType == "string" and RightType == "string" then
            return Left <= Right
        end

        if Interpreter.HasMetaMethod(Left, "__le") or Interpreter.HasMetaMethod(Right, "__le") then
            return Left <= Right
        end
        
        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
} :: { [number]: (Self: Interpreter, Environment: Environment, Operator: Token, Left: any, RightExpr: Expression) -> any }

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
        if Interpreter.HasMetaMethod(Value, "__unm") then
            return -Value
        end

        if Interpreter.HasMetaMethod(Value, "__mul") then
            return -1 * Value
        end

        if typeof(Value) ~= "number" then
            Interpreter.Error(Operator, `Attempt to use unary '-' on {typeof(Value)}`)
        end
        
        return -Value
    end,
    [Token.Types.Not] = function(Self: Interpreter, Operator: Token, Value: any): any
        return not Value
    end,
    [Token.Types.Hash] = function(Self: Interpreter, Operator: Token, Value: any): any
        local Type = typeof(Value)
        if Type ~= "table" then
            Interpreter.Error(Operator, `Attempt to get the size of {typeof(Value)}`)
        end

        return #Value
    end
} :: { [number]: (Self: Interpreter, Operator: Token, Value: any) -> any }

Interpreter.AssignmentFunctions = {
    [Token.Types.Equals] = function(Left: any, Operator: Token, Right: any) return Right end,
    [Token.Types.PlusEquals] = Interpreter.TryAdd,
    [Token.Types.MinusEquals] = Interpreter.TrySubtract,
    [Token.Types.StarEquals] = Interpreter.TryMultiply,
    [Token.Types.SlashEquals] = Interpreter.TryDivide,
    [Token.Types.DoubleSlashEquals] = Interpreter.TryFloorDivide,
    [Token.Types.ModuloEquals] = Interpreter.TryModulo,
    [Token.Types.KaratEquals] = Interpreter.TryPower,
} :: { [number]: (Left: any, Operator: Token, Right: any) -> any }

Interpreter.LiteralEvaluations = {
    [Token.Types.Number] = function(Self: Interpreter, Environment: Environment, Token: Token): Reference
        return Reference.New(tonumber(Token.Lexeme))
    end,
    [Token.Types.Identifier] = function(Self: Interpreter, Environment: Environment, Token: Token): Reference
        local Result = Environment:Find(Token.Lexeme) or Self.GlobalEnvironment:Find(Token.Lexeme)

        if not Result then
            Interpreter.Error(Token, `Attempt to access undefined variable '{Token.Lexeme}'`)
        end

        return Result or Reference.New(nil)
    end,
    [Token.Types.String] = function(Self: Interpreter, Environment: Environment, Token: Token): Reference
        return Reference.New(Token.Lexeme)
    end,
    [Token.Types.True] = function(Self: Interpreter, Environment: Environment, Token: Token): Reference
        return Reference.New(true)
    end,
    [Token.Types.False] = function(Self: Interpreter, Environment: Environment, Token: Token): Reference
        return Reference.New(false)
    end,
    [Token.Types.Nil] = function(Self: Interpreter, Environment: Environment, Token: Token): Reference
        return Reference.New(nil)
    end,
} :: { [number]: (Self: Interpreter, Environment: Environment, Token: Token) -> Reference }

Interpreter.ExpressionMap = {
    LiteralExpression = Interpreter.EvaluateLiteralExpression,
    UnaryExpression = Interpreter.EvaluateUnaryExpression,
    BinaryExpression = Interpreter.EvaluateBinaryExpression,
    AssignmentExpression = Interpreter.EvaluateAssignmentExpression,
    CallExpression = Interpreter.EvaluateCallExpression,
    SelfCallExpression = Interpreter.EvaluateSelfCallExpression,
    GetExpression = Interpreter.EvaluateGetExpression,
    IndexExpression = Interpreter.EvaluateIndexExpression,
    FunctionExpression = Interpreter.EvaluateFunctionExpression,
    TableExpression = Interpreter.EvaluateTableExpression,
} :: { [string]: (Self: Interpreter, Environment: Environment, Expression: Expression) -> any }

return Interpreter