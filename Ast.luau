--!strict

local Token = require("./Token")
type Token = Token.Token

local Ast = {}
Ast.__index = {}

export type BinaryOperator = "+" | "-" | "*" | "/" | "//" | "==" | "~=" | "<" | "<=" | ">" | ">=" | "and" | "or"
export type UnaryOperator = "not" | "+" | "-"

export type AstType = "BinaryExpression" | "UnaryExpression"

type AstData = {
    Type: AstType,
}

export type Ast = typeof(setmetatable({} :: AstData, Ast))

export type LiteralExpression = {
    Type: "Literal",
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

export type Expression = LiteralExpression | BinaryExpression | UnaryExpression

function Ast.LiteralExpression(Value: Token): LiteralExpression
    local Self = {} :: LiteralExpression

    Self.Type = "Literal"
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

return Ast