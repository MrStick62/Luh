--!strict

local Token = require("./Token")
type Token = Token.Token

local Ast = {}
Ast.__index = {}

export type AstType = "BinaryExpression" | "UnaryExpression"

type AstData = {
    Type: AstType,
}

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

export type Expression = LiteralExpression | BinaryExpression | UnaryExpression | AssignmentExpression

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

export type Statement = ExpressionStatement | VariableStatement | DoStatement

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

return Ast