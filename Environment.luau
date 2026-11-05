--!strict

local Environment = {}
Environment.__index = Environment

type EnvironmentData = {
    Values: { [string]: any },
}

export type Environment = typeof(setmetatable({} :: EnvironmentData, Environment))

function Environment.New(): Environment
    local Self = {}

    Self.Values = {}

    return setmetatable(Self, Environment)
end

function Environment.Define(Self: Environment, Identifier: string, Value: any)
    Self.Values[Identifier] = Value
end

function Environment.Get(Self: Environment, Identifier: string): any
    return Self.Values[Identifier]
end

return Environment