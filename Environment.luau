--!strict

local Environment = {}
Environment.__index = Environment

type EnvironmentData = {
    Values: { [string]: any },
    Outside: Environment?,
}

export type Environment = typeof(setmetatable({} :: EnvironmentData, Environment))

function Environment.New(Outside: Environment?): Environment
    local Self = {}

    Self.Values = {}
    Self.Outside = Outside

    return setmetatable(Self, Environment)
end

function Environment.Define(Self: Environment, Identifier: string, Value: any)
    Self.Values[Identifier] = Value
end

function Environment.Assign(Self: Environment, Identifier: string, Value: any): boolean
    if Self.Values[Identifier] then
        Self.Values[Identifier] = Value
        return true
    end

    return Self.Outside ~= nil and Self.Outside:Assign(Identifier, Value)
end

function Environment.Get(Self: Environment, Identifier: string): any
    local Value = Self.Values[Identifier]
    return Value ~= nil and Value or Self.Outside and Self.Outside:Get(Identifier)
end

return Environment