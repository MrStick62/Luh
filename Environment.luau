--!strict

local Environment = {}
Environment.__index = Environment

type EnvironmentData = {
    Values: { [string]: { Value: any } },
}

export type Environment = typeof(setmetatable({} :: EnvironmentData, Environment))

function Environment.New(Outside: Environment?): Environment
    local Self = {}

    Self.Values = {}

    if Outside then
        for Index, Value in Outside.Values do
            Self.Values[Index] = Value
        end
    end

    return setmetatable(Self, Environment)
end

function Environment.Define(Self: Environment, Identifier: string, Value: any)
    Self.Values[Identifier] = { Value = Value }
end

function Environment.Assign(Self: Environment, Identifier: string, Value: any): boolean
    if Self.Values[Identifier] then
        Self.Values[Identifier].Value = Value
        return true
    end

    return false
end

function Environment.Get(Self: Environment, Identifier: string): any
    local Value = Self.Values[Identifier]
    return Value and Value.Value
end

return Environment