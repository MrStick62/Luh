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
    Left: { Expression },
    Operator: Token,
    Right: { Expression },
}

export type CallExpression = {
    Type: "CallExpression",
    Token: Token,
    Function: Expression,
    Arguments: { Expression },
}

export type SelfCallExpression = {
    Type: "SelfCallExpression",
    Left: Expression,
    Operator: Token,
    Name: Token,
    Arguments: { Expression }
}

export type GetExpression = {
    Type: "GetExpression",
    Left: Expression,
    Operator: Token,
    Name: Token,
}

export type IndexExpression = {
    Type: "IndexExpression",
    Left: Expression,
    Operator: Token,
    Index: Expression,
}

export type FunctionExpression = {
    Type: "FunctionExpression",
    Parameters: { Token },
    Body: { Statement },
}

export type TableExpression = {
    Type: "TableExpression",
    Elements: { { Key: Expression?, Value: Expression } }
}

export type Expression = LiteralExpression | BinaryExpression | UnaryExpression | AssignmentExpression | CallExpression | SelfCallExpression | GetExpression | IndexExpression | FunctionExpression | TableExpression

export type ExpressionStatement = {
    Type: "ExpressionStatement",
    Expression: Expression,
}

export type VariableStatement = {
    Type: "VariableStatement",
    Identifiers: { Token },
    Initializers: { Expression },
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
    Identifiers: { Token },
    Parameters: { Token },
    Body: { Statement },
}

export type JumpStatement = {
    Type: "JumpStatement",
    Keyword: Token,
    Tuple: { Expression },
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

function Ast.AssignmentExpression(Left: { Expression }, Operator: Token, Right: { Expression }): AssignmentExpression
    local Self = {} :: AssignmentExpression

    Self.Type = "AssignmentExpression"
    Self.Left = Left
    Self.Operator = Operator
    Self.Right = Right

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

function Ast.SelfCallExpression(Left: Expression, Operator: Token, Name: Token, Arguments: { Expression }): SelfCallExpression
    local Self = {} :: SelfCallExpression

    Self.Type = "SelfCallExpression"
    Self.Left = Left
    Self.Operator = Operator
    Self.Name = Name
    Self.Arguments = Arguments

    return Self
end

function Ast.GetExpression(Left: Expression, Operator: Token, Name: Token): GetExpression
    local Self = {} :: GetExpression

    Self.Type = "GetExpression"
    Self.Left = Left
    Self.Operator = Operator
    Self.Name = Name

    return Self
end

function Ast.IndexExpression(Left: Expression, Operator: Token, Index: Expression): IndexExpression
    local Self = {} :: IndexExpression

    Self.Type = "IndexExpression"
    Self.Left = Left
    Self.Operator = Operator
    Self.Index = Index

    return Self
end

function Ast.FunctionExpression(Parameters: { Token }, Body: { Statement }): FunctionExpression
    local Self = {} :: FunctionExpression

    Self.Type = "FunctionExpression"
    Self.Parameters = Parameters
    Self.Body = Body

    return Self
end

function Ast.TableExpression(Elements: { { Key: Expression?, Value: Expression } }): TableExpression
    local Self = {} :: TableExpression

    Self.Type = "TableExpression"
    Self.Elements = Elements

    return Self
end

function Ast.ExpressionStatement(Expression: Expression): ExpressionStatement
    local Self = {} :: ExpressionStatement

    Self.Type = "ExpressionStatement"
    Self.Expression = Expression

    return Self
end

function Ast.VariableStatement(Identifiers: { Token }, Initializers: { Expression }): VariableStatement
    local Self = {} :: VariableStatement

    Self.Type = "VariableStatement"
    Self.Identifiers = Identifiers
    Self.Initializers = Initializers

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

function Ast.FunctionStatement(Identifiers: { Token }, Parameters: { Token }, Body: { Statement }): FunctionStatement
    local Self = {} :: FunctionStatement

    Self.Type = "FunctionStatement"
    Self.Identifiers = Identifiers
    Self.Parameters = Parameters
    Self.Body = Body

    return Self
end

function Ast.JumpStatement(Keyword: Token, Value: { Expression }): JumpStatement
    local Self = {} :: JumpStatement

    Self.Type = "JumpStatement"
    Self.Keyword = Keyword
    Self.Tuple = Value

    return Self
end

return Ast