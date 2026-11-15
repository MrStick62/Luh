--!strict

local Error = require("./Error")

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
    Environment: Environment,
}

export type Interpreter = typeof(setmetatable({} :: InterpreterData, Interpreter))

function Interpreter.New(): Interpreter
    local Self = {}

    Self.GlobalEnvironment = Environment.New()
    Self.Environment = Self.GlobalEnvironment

    return setmetatable(Self, Interpreter)
end

function Interpreter.LoadGlobal(Self: Interpreter, Identifier: string, Value: any)
    Self.GlobalEnvironment:Define(Identifier, Value)
end

function Interpreter.Run(Self: Interpreter, Statements: { Statement })
    local Ok, Err: Jump | RuntimeError = xpcall(
        function()
            for _, Statement in Statements do
                Self:EvaluateStatement(Statement)
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
                Error.Report(Err.Keyword.Location, `Attempt to call {Err.Keyword.Lexeme} statement outside of a loop`, Error.Type.Runtime)
            end
        elseif Err.Type == "__runtimeerror" then
            Error.Report(Err.Token.Location, Err.Message, Error.Type.Runtime)
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

function Interpreter.EvaluateStatement(Self: Interpreter, Statement: Statement): ()
    local Function = Interpreter.StatementMap[Statement.Type]
    Function(Self, Statement)
end

function Interpreter.EvaluateExpressionStatement(Self: Interpreter, Statement: ExpressionStatement)
    Self:EvaluateExpression(Statement.Expression)
end

function Interpreter.EvaluateVariableStatement(Self: Interpreter, Statement: VariableStatement)
    local Right = Self:EvaluateTupleExpression(Statement.Initializers)

    for i, Identifier in Statement.Identifiers do
        Self.Environment:Define(Identifier.Lexeme, Right[i])
    end
end

function Interpreter.EvaluateDoStatement(Self: Interpreter, Statement: DoStatement)
    local Scope = Environment.New(Self.Environment)
    Self:EvaluateBlock(Statement.Statements, Scope)
end

function Interpreter.EvaluateIfStatement(Self: Interpreter, Statement: IfStatement)
    local Scope = Environment.New(Self.Environment)
    if Self:EvaluateExpression(Statement.Default.Condition):Get() then
        Self:EvaluateBlock(Statement.Default.Body, Scope)
    else
        for _, Elseif in Statement.Elseif do
            if Self:EvaluateExpression(Elseif.Condition):Get() then
                Self:EvaluateBlock(Elseif.Body, Scope)
                return
            end
        end

        Self:EvaluateBlock(Statement.Else, Scope)
    end
end

function Interpreter.EvaluateWhileStatement(Self: Interpreter, Statement: WhileStatement)
    while Self:EvaluateExpression(Statement.Condition):Get() do
        local Scope = Environment.New(Self.Environment)
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

function Interpreter.EvaluateForStatement(Self: Interpreter, Statement: ForStatement)
    local CounterValue = Self:EvaluateExpression(Statement.Initial):Get()
    if typeof(CounterValue) ~= "number" then
        Interpreter.Error(Statement.Keyword, `Expected number for 'for' counter, got {typeof(CounterValue)}`)
    end

    local Limit = Self:EvaluateExpression(Statement.Limit):Get()
    if typeof(Limit) ~= "number" then
        Interpreter.Error(Statement.Keyword, `Expected number for 'for' limit, got {typeof(Limit)}`)
    end

    local Increment = Statement.Increment and Self:EvaluateExpression(Statement.Increment):Get() or 1
    if typeof(Increment) ~= "number" then
        Interpreter.Error(Statement.Keyword, `Expected number for 'for' increment, got {typeof(Increment)}`)
    end

    local Direction = math.sign(Increment)

    while true do
        if Direction == 1 and CounterValue > Limit or Direction == -1 and CounterValue < Limit then
            break
        end

        local Scope = Environment.New(Self.Environment)
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

function Interpreter.EvaluateForEachStatement(Self: Interpreter, Statement: ForEachStatement)
    local Target = Self:EvaluateTupleExpression(Statement.Arguments)

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

        local Scope = Environment.New(Self.Environment)

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

--[[
function Interpreter.EvaluateForEachOverride(Self: Interpreter, Target: (...any) -> ...any, Statement: ForEachStatement)
    

    while true do
        local Values = Target(Statement.Keyword, {})

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
]]

function Interpreter.EvaluateFunctionStatement(Self: Interpreter, Statement: FunctionStatement)
    local Source = Statement.Identifiers[1]

    if #Statement.Identifiers == 1 then
        Self.Environment:Define(Source.Lexeme, Self:FunctionToValue(Statement.Parameters, Statement.Body))
        return
    end

    local Table = Self.Environment:Find(Source.Lexeme)

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

    Current[Identifier.Lexeme] = Self:FunctionToValue(Statement.Parameters, Statement.Body)
end

function Interpreter.EvaluateJumpStatement(Self: Interpreter, Statement: JumpStatement)
    local Tuple = {}
    Tuple.n = #Statement.Tuple

    for i, Value in Statement.Tuple do
        Tuple[i] = Self:EvaluateExpression(Value):Get()
    end

    Interpreter.Jump(Statement.Keyword, Tuple)
end

function Interpreter.EvaluateBlock(Self: Interpreter, Statements: { Statement }, Environment: Environment)
    local Outside = Self.Environment
    Self.Environment = Environment

    for _, Statement in Statements do
        Self:EvaluateStatement(Statement)
    end

    Self.Environment = Outside
end

function Interpreter.CatchJump(Self: Interpreter, Statements: { Statement }, Environment: Environment): Jump?
    local PreviousEnvironment = Self.Environment

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

    Self.Environment = PreviousEnvironment

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

function Interpreter.FunctionToValue(Self: Interpreter, Parameters: { Token }, Body: { Statement }): (Token, { any }) -> (any)
    local Outside = Environment.New(Self.Environment)

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

--[[
function Interpreter.ToLuhFunction(Func: (...any) -> ...any)
    return function(Caller: Token, Arguments: { any })
        local Result = nil

        local Ok, Err = xpcall(
            function(...)
                Result = table.pack(Func(table.unpack(Arguments)))
            end,
            function(Err)
                return Err
            end)

        if not Ok then
            Interpreter.Error(Caller, Err)
        end

        return Result or { n = 0 }
    end
end
]]

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
} :: { [string]: (Self: Interpreter, Statement: Statement) -> () }

----------------------------
-- Evaluating Expressions --
----------------------------

function Interpreter.EvaluateTupleExpression(Self: Interpreter, Expressions: { Expression }, Offset: number?): Tuple
    local Results = {}

    local Index = 1 + (Offset or 0)

    if #Expressions > 0 then
        for i = 1, #Expressions - 1 do
            Results[Index] = Self:EvaluateExpression(Expressions[i]):Get()
            Index += 1
        end

        local Tuple = Self:EvaluateExpression(Expressions[#Expressions]):GetAll()
        for i = 1, Tuple.n do
            Results[Index] = Tuple[i]
            Index += 1
        end
    end

    Results.n = Index - 1
    return Results
end

function Interpreter.EvaluateExpression(Self: Interpreter, Expression: Expression): Reference
    local Function = Interpreter.ExpressionMap[Expression.Type]
    return Function and Function(Self, Expression)
end

function Interpreter.EvaluateBinaryExpression(Self: Interpreter, Expression: BinaryExpression): Reference
    local BinaryFunction = Interpreter.BinaryFunctions[Expression.Operator.Type]
    local Left = Self:EvaluateExpression(Expression.Left):Get()
    return BinaryFunction and Reference.New(BinaryFunction(Self, Expression.Operator, Left, Expression.Right))
end

function Interpreter.EvaluateUnaryExpression(Self: Interpreter, Expression: UnaryExpression): Reference
    local UnaryFunction = Interpreter.UnaryFunctions[Expression.Operator.Type]
    return UnaryFunction and Reference.New(UnaryFunction(Self, Expression.Operator, Self:EvaluateExpression(Expression.Expression):Get()))
end

function Interpreter.EvaluateAssignmentExpression(Self: Interpreter, Expression: AssignmentExpression): Reference
    local AssignmentFunction = Interpreter.AssignmentFunctions[Expression.Operator.Type]

    if not AssignmentFunction then
        return Reference.New(nil)
    end

    local Right = Self:EvaluateTupleExpression(Expression.Right)

    for i, Identifier in Expression.Left do
        local Left = Self:EvaluateExpression(Identifier)
        AssignmentFunction(Self, Left, Expression.Operator, Right[i])
    end
    
    return Reference.New(nil)
end

function Interpreter.EvaluateLiteralExpression(Self: Interpreter, Expression: LiteralExpression): Reference
    local Evaluation = Interpreter.LiteralEvaluations[Expression.Value.Type]
    return Evaluation and Evaluation(Self, Expression.Value)
end

function Interpreter.EvaluateCallExpression(Self: Interpreter, Expression: CallExpression): Reference
    local Function = Self:EvaluateExpression(Expression.Function):Get()

    if typeof(Function) ~= "function" then
        Interpreter.Error(Expression.Token, `Attempt to call a {typeof(Function)} value`)
    end

    local Arguments = Self:EvaluateTupleExpression(Expression.Arguments)

    return Reference.Tuple(Function(table.unpack(Arguments, 1, Arguments.n)))
end

function Interpreter.EvaluateSelfCallExpression(Self: Interpreter, Expression: SelfCallExpression): Reference
    local Table = Self:EvaluateExpression(Expression.Left):Get()

    if typeof(Table) ~= "table" then
        Interpreter.Error(Expression.Operator, `Attempt to index {typeof(Table)} with '{Expression.Name.Lexeme}'`)
    end

    local Function = Table[Expression.Name.Lexeme]

    if typeof(Function) ~= "function" then
        Interpreter.Error(Expression.Operator, `Attempt to call a {typeof(Function)} value`)
    end

    local Arguments = Self:EvaluateTupleExpression(Expression.Arguments, 1)
    Arguments[1] = Table

    return Reference.Tuple(Function(table.unpack(Arguments, 1, Arguments.n)))
end

function Interpreter.EvaluateGetExpression(Self: Interpreter, Expression: GetExpression): Reference
    local Table = Self:EvaluateExpression(Expression.Left):Get()

    if typeof(Table) ~= "table" then
        Interpreter.Error(Expression.Operator, `Attempt to index {typeof(Table)} with '{Expression.Name.Lexeme}'`)
    end

    return Reference.FromTable(Table, Expression.Name.Lexeme)
end

function Interpreter.EvaluateIndexExpression(Self: Interpreter, Expression: IndexExpression): Reference
    local Table = Self:EvaluateExpression(Expression.Left):Get()
    local Index = Self:EvaluateExpression(Expression.Index):Get()

    if typeof(Table) ~= "table" then
        Interpreter.Error(Expression.Operator, `Attempt to index {typeof(Table)} with {typeof(Index)}`)
    end

    return Reference.FromTable(Table, Index)
end

function Interpreter.EvaluateFunctionExpression(Self: Interpreter, Expression: FunctionExpression): Reference
    return Reference.New(Self:FunctionToValue(Expression.Parameters, Expression.Body))
end

function Interpreter.EvaluateTableExpression(Self: Interpreter, Expression: TableExpression): Reference
    local Table = {}

    local ArrayIndex = 1

    for _, Pair in Expression.Elements do
        local Key: any = ArrayIndex

        if Pair.Key then
            if Pair.Key.Type == "LiteralExpression" then
                Key = Pair.Key.Value.Lexeme
            else
                Key = Self:EvaluateExpression(Pair.Key):Get()
            end
        else
            ArrayIndex += 1
        end

        Table[Key] = Self:EvaluateExpression(Pair.Value):Get()
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

Interpreter.BinaryFunctions = {
    [Token.Types.Plus] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        -- Why am I manually passing self only here? Try fixing it. See what kind of wrath the Luau Language Server inflicts upon you. God help us all.
        local Right = Interpreter.EvaluateExpression(Self, RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left + Right
        end

        if Interpreter.HasMetaMethod(Left, "__add") or Interpreter.HasMetaMethod(Right, "__add") then
            return Left + Right
        end

        Interpreter.Error(Operator, `Attempt to add {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Minus] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left - Right
        end

        if Interpreter.HasMetaMethod(Left, "__sub") or Interpreter.HasMetaMethod(Right, "__sub") then
            return Left - Right
        end

        Interpreter.Error(Operator, `Attempt to subtract {LeftType} and {RightType}`)     
        return nil
    end,
    [Token.Types.Star] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left * Right
        end

        if Interpreter.HasMetaMethod(Left, "__mul") or Interpreter.HasMetaMethod(Right, "__mul") then
            return Left * Right
        end

        Interpreter.Error(Operator, `Attempt to multiply {LeftType} and {RightType}`)          
        return nil
    end,
    [Token.Types.Slash] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left / Right
        end

        if Interpreter.HasMetaMethod(Left, "__div") or Interpreter.HasMetaMethod(Right, "__div") then
            return Left / Right
        end

        Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)   
        return nil
    end,
    [Token.Types.DoubleSlash] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
             return Left // Right
        end

        if Interpreter.HasMetaMethod(Left, "__idiv") or Interpreter.HasMetaMethod(Right, "__idiv") then
            return Left // Right
        end

        Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)          
        return nil
    end,
    [Token.Types.Modulo] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left % Right
        end

        if Interpreter.HasMetaMethod(Left, "__mod") or Interpreter.HasMetaMethod(Right, "__mod") then
            return Left % Right
        end

        Interpreter.Error(Operator, `Attempt to compute the remainder of {LeftType} and {RightType}`)   
        return nil
    end,
    [Token.Types.Karat] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left ^ Right
        end

        if Interpreter.HasMetaMethod(Left, "__pow") or Interpreter.HasMetaMethod(Right, "__pow") then
            return Left ^ Right
        end

        Interpreter.Error(Operator, `Attempt to raise {LeftType} to the power of {RightType}`)
        return nil
    end,
    [Token.Types.DoubleDot] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        if Interpreter.HasMetaMethod(Left, "__concat") or Interpreter.HasMetaMethod(Right, "__concat") then
            return Left .. Right
        end

        return tostring(Left) .. tostring(Right)
    end,
    [Token.Types.And] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        return Left and Self:EvaluateExpression(RightExpr):Get()
    end,
    [Token.Types.Or] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        return Left or Self:EvaluateExpression(RightExpr):Get()
    end,
    [Token.Types.Xor] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        return not Left and Right or not Right and Left or (Left ~= Right or Left ~= true and Left ~= false) and nil
    end,
    [Token.Types.Equal] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        return Left == Right
    end,
    [Token.Types.NotEqual] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        return Left ~= Right
    end,
    [Token.Types.Greater] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left > Right
        end

        if Interpreter.HasMetaMethod(Left, "__le") or Interpreter.HasMetaMethod(Right, "__le") then
            return Left > Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.GreaterEqual] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Left >= Right
        end

        if Interpreter.HasMetaMethod(Left, "__lt") or Interpreter.HasMetaMethod(Right, "__lt") then
            return Left >= Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)
        return nil
    end,
    [Token.Types.Less] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Reference.New(Left < Right)
        end

        if Interpreter.HasMetaMethod(Left, "__lt") or Interpreter.HasMetaMethod(Right, "__lt") then
            return Left < Right
        end

        Interpreter.Error(Operator, `Attempt to compare {LeftType} and {RightType}`)    
        return nil
    end,
    [Token.Types.LessEqual] = function(Self: Interpreter, Operator: Token, Left: any, RightExpr: Expression): any
        local Right = Self:EvaluateExpression(RightExpr):Get()

        local LeftType, RightType = typeof(Left), typeof(Right)
        if LeftType == "number" and RightType == "number" then
            return Reference.New(Left <= Right)
        end

        if Interpreter.HasMetaMethod(Left, "__le") or Interpreter.HasMetaMethod(Right, "__le") then
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
        if Interpreter.HasMetaMethod(Value, "__unm") then
            return Value.__unm(Operator, { Value })
        end

        if Interpreter.HasMetaMethod(Value, "__mul") then
            return Value.__mul(Operator, { -1, Value })
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

        if Interpreter.HasMetaMethod(Value, "__len") then
            return Value.__len(Operator, { Value })
        end

        return #Value
    end
} :: { [number]: (Self: Interpreter, Operator: Token, Value: any) -> any }

Interpreter.AssignmentFunctions = {
    [Token.Types.Equals] = function(Self: Interpreter, Left: Reference, Operator: Token, Value: any): Reference
        if not Left:Set(Value) then
            Interpreter.Error(Operator, `Attempt to assign non-mutable value`)
        end
        
        return Left
    end,
    [Token.Types.PlusEquals] = function(Self: Interpreter, Left: Reference, Operator: Token, Value: any): Reference
        local LeftValue = Left:Get()

        local LeftType, RightType = typeof(LeftValue), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to add {LeftType} and {RightType}`)
        end
        
        local Result = LeftValue + Value
        if not Left:Set(Result) then
            Interpreter.Error(Operator, `Attempt to assign non-mutable value`)
        end

        return Result
    end,
    [Token.Types.MinusEquals] = function(Self: Interpreter, Left: Reference, Operator: Token, Value: any): Reference
        local LeftValue = Left:Get()

        local LeftType, RightType = typeof(LeftValue), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to subtract {LeftType} and {RightType}`)
        end
        
        local Result = LeftValue - Value
        if not Left:Set(Result) then
            Interpreter.Error(Operator, `Attempt to assign non-mutable value`)
        end

        return Result
    end,
    [Token.Types.StarEquals] = function(Self: Interpreter, Left: Reference, Operator: Token, Value: any): Reference
        local LeftValue = Left:Get()

        local LeftType, RightType = typeof(LeftValue), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to multiply {LeftType} and {RightType}`)
        end
        
        local Result = LeftValue * Value
        if not Left:Set(Result) then
            Interpreter.Error(Operator, `Attempt to assign non-mutable value`)
        end

        return Result
    end,
    [Token.Types.SlashEquals] = function(Self: Interpreter, Left: Reference, Operator: Token, Value: any): Reference
        local LeftValue = Left:Get()

        local LeftType, RightType = typeof(LeftValue), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)
        end
        
        local Result = LeftValue / Value
        if not Left:Set(Result) then
            Interpreter.Error(Operator, `Attempt to assign non-mutable value`)
        end

        return Result
    end,
    [Token.Types.DoubleSlashEquals] = function(Self: Interpreter, Left: Reference, Operator: Token, Value: any): Reference
        local LeftValue = Left:Get()

        local LeftType, RightType = typeof(LeftValue), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to divide {LeftType} and {RightType}`)
        end
        
        local Result = LeftValue // Value
        if not Left:Set(Result) then
            Interpreter.Error(Operator, `Attempt to assign non-mutable value`)
        end

        return Result
    end,
    [Token.Types.ModuloEquals] = function(Self: Interpreter, Left: Reference, Operator: Token, Value: any): Reference
        local LeftValue = Left:Get()

        local LeftType, RightType = typeof(LeftValue), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to compute the remainder of {LeftType} and {RightType}`)
        end
        
        local Result = LeftValue % Value
        if not Left:Set(Result) then
            Interpreter.Error(Operator, `Attempt to assign non-mutable value`)
        end

        return Result
    end,
    [Token.Types.KaratEquals] = function(Self: Interpreter, Left: Reference, Operator: Token, Value: any): Reference
        local LeftValue = Left:Get()

        local LeftType, RightType = typeof(LeftValue), typeof(Value)
        if LeftType ~= "number" or RightType ~= "number" then
            Interpreter.Error(Operator, `Attempt to raise {LeftType} to the power of {RightType}`)
        end
        
        local Result = LeftValue ^ Value
        if not Left:Set(Result) then
            Interpreter.Error(Operator, `Attempt to assign non-mutable value`)
        end

        return Result
    end,
} :: { [number]: (Self: Interpreter, Identifier: Reference, Operator: Token, Value: any) -> any }

Interpreter.LiteralEvaluations = {
    [Token.Types.Number] = function(Self: Interpreter, Token: Token): Reference
        return Reference.New(tonumber(Token.Lexeme))
    end,
    [Token.Types.Identifier] = function(Self: Interpreter, Token: Token): Reference
        local Result = Self.Environment:Find(Token.Lexeme)

        if not Result then
            Interpreter.Error(Token, `Attempt to access undefined variable '{Token.Lexeme}'`)
        end

        return Result or Reference.New(nil)
    end,
    [Token.Types.String] = function(Self: Interpreter, Token: Token): Reference
        return Reference.New(Token.Lexeme)
    end,
    [Token.Types.True] = function(Self: Interpreter, Token: Token): Reference
        return Reference.New(true)
    end,
    [Token.Types.False] = function(Self: Interpreter, Token: Token): Reference
        return Reference.New(false)
    end,
    [Token.Types.Nil] = function(Self: Interpreter, Token: Token): Reference
        return Reference.New(nil)
    end,
} :: { [number]: (Self: Interpreter, Token: Token) -> Reference }

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
} :: { [string]: (Self: Interpreter, Expression: Expression) -> any }

return Interpreter