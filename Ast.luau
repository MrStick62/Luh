--!strict

local Token = require("./Token")
type Token = Token.Token

local Ast = {}

export type LiteralExpression = {
    Type: "LiteralExpression",
    Value: Token,
}

export type BinaryExpression = {
    Type: "BinaryExpression",
    Left: Expression,
    Operator: Token,
    Right: Expression,
}

export type UnaryExpression = {
    Type: "UnaryExpression",
    Operator: Token,
    Expression: Expression,
}

export type AssignmentExpression = {
    Type: "AssignmentExpression",
    Identifier: Token,
    Operator: Token,
    Expression: Expression,
}

export type CallExpression = {
    Type: "CallExpression",
    Token: Token,
    Function: Expression,
    Arguments: { Expression },
}

export type FunctionExpression = {
    Type: "FunctionExpression",
    Parameters: { Token },
    Body: { Statement },
}

export type Expression = LiteralExpression | BinaryExpression | UnaryExpression | AssignmentExpression | CallExpression | FunctionExpression

export type ExpressionStatement = {
    Type: "ExpressionStatement",
    Expression: Expression,
}

export type VariableStatement = {
    Type: "VariableStatement",
    Identifier: Token,
    Initializer: Expression?,
}

export type DoStatement = {
    Type: "DoStatement",
    Statements: { Statement },
}

export type Conditional = {
    Condition: Expression,
    Body: { Statement }
}

export type IfStatement = {
    Type: "IfStatement",
    Default: Conditional,
    Elseif: { Conditional },
    Else: { Statement },
}

export type WhileStatement = {
    Type: "WhileStatement",
    Condition: Expression,
    Body: { Statement },
}

export type ForStatement = {
    Type: "ForStatement",
    Keyword: Token,
    Identifier: Token,
    Initial: Expression,
    Limit: Expression,
    Increment: Expression?,
    Body: { Statement },
}

export type FunctionStatement = {
    Type: "FunctionStatement",
    Identifier: Token,
    Parameters: { Token },
    Body: { Statement },
}

export type JumpStatement = {
    Type: "JumpStatement",
    Keyword: Token,
    Value: Expression?,
}

export type Statement = ExpressionStatement | VariableStatement | DoStatement | IfStatement | WhileStatement | ForStatement | FunctionStatement | JumpStatement

export type Ast = Expression

function Ast.LiteralExpression(Value: Token): LiteralExpression
    local Self = {} :: LiteralExpression

    Self.Type = "LiteralExpression"
    Self.Value = Value

    return Self
end

function Ast.BinaryExpression(Left: Expression, Operator: Token, Right: Expression): BinaryExpression
    local Self = {} :: BinaryExpression

    Self.Type = "BinaryExpression"
    Self.Left = Left
    Self.Operator = Operator
    Self.Right = Right

    return Self
end

function Ast.UnaryExpression(Operator: Token, Expression: Expression): UnaryExpression
    local Self = {} :: UnaryExpression
    
    Self.Type = "UnaryExpression"
    Self.Operator = Operator
    Self.Expression = Expression

    return Self
end

function Ast.AssignmentExpression(Identifier: Token, Operator: Token, Expression: Expression): AssignmentExpression
    local Self = {} :: AssignmentExpression

    Self.Type = "AssignmentExpression"
    Self.Identifier = Identifier
    Self.Operator = Operator
    Self.Expression = Expression

    return Self
end

function Ast.CallExpression(Token: Token, Function: Expression, Arguments: { Expression }): CallExpression
    local Self = {} :: CallExpression

    Self.Type = "CallExpression"
    Self.Token = Token
    Self.Function = Function
    Self.Arguments = Arguments

    return Self
end

function Ast.FunctionExpression(Parameters: { Token }, Body: { Statement }): FunctionExpression
    local Self = {} :: FunctionExpression

    Self.Type = "FunctionExpression"
    Self.Parameters = Parameters
    Self.Body = Body

    return Self
end

function Ast.ExpressionStatement(Expression: Expression): ExpressionStatement
    local Self = {} :: ExpressionStatement

    Self.Type = "ExpressionStatement"
    Self.Expression = Expression

    return Self
end

function Ast.VariableStatement(Identifier: Token, Initializer: Expression?): VariableStatement
    local Self = {} :: VariableStatement

    Self.Type = "VariableStatement"
    Self.Identifier = Identifier
    Self.Initializer = Initializer

    return Self
end

function Ast.DoStatement(Statements: { Statement }): DoStatement
    local Self = {} :: DoStatement

    Self.Type = "DoStatement"
    Self.Statements = Statements

    return Self
end

function Ast.Conditional(Condition: Expression, Body: { Statement }): Conditional
    local Self = {}
    
    Self.Condition = Condition
    Self.Body = Body

    return Self
end

function Ast.IfStatement(Default: Conditional, ElseIf: { Conditional }, Else: { Statement }): IfStatement
    local Self = {} :: IfStatement

    Self.Type = "IfStatement"
    Self.Default = Default
    Self.Elseif = ElseIf
    Self.Else = Else

    return Self
end

function Ast.WhileStatement(Condition: Expression, Body: { Statement }): WhileStatement
    local Self = {} :: WhileStatement

    Self.Type = "WhileStatement"
    Self.Condition = Condition
    Self.Body = Body

    return Self
end

function Ast.ForStatement(Token: Token, Identifier: Token, Initial: Expression, Limit: Expression, Increment: Expression?, Body: { Statement }): ForStatement
    local Self = {} :: ForStatement

    Self.Type = "ForStatement"
    Self.Keyword = Token
    Self.Identifier = Identifier
    Self.Initial = Initial
    Self.Limit = Limit
    Self.Increment = Increment
    Self.Body = Body

    return Self
end

function Ast.FunctionStatement(Identifier: Token, Parameters: { Token }, Body: { Statement }): FunctionStatement
    local Self = {} :: FunctionStatement

    Self.Type = "FunctionStatement"
    Self.Identifier = Identifier
    Self.Parameters = Parameters
    Self.Body = Body

    return Self
end

function Ast.JumpStatement(Keyword: Token, Value: Expression?): JumpStatement
    local Self = {} :: JumpStatement

    Self.Type = "JumpStatement"
    Self.Keyword = Keyword
    Self.Value = Value

    return Self
end

return Ast