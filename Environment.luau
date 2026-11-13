--!strict

local Reference = require("./Reference")
type Reference = Reference.Reference

local Environment = {}
Environment.__index = Environment

type EnvironmentData = {
    Map: { [string]: Reference },
}

export type Environment = typeof(setmetatable({} :: EnvironmentData, Environment))

function Environment.New(Outside: Environment?): Environment
    local Self = {}

    Self.Map = {}

    if Outside then
        for Index, Reference in Outside.Map do
            Self.Map[Index] = Reference
        end
    end

    return setmetatable(Self, Environment)
end

function Environment.Define(Self: Environment, Identifier: string, Value: any, Constant: boolean?)
    Self.Map[Identifier] = Reference.New(Value, not Constant)
end

function Environment.Assign(Self: Environment, Identifier: string, Value: any): boolean
    if Self.Map[Identifier] then
        Self.Map[Identifier]:Set(Value)
        return true
    end

    return false
end

function Environment.Find(Self: Environment, Identifier: string): Reference?
    return Self.Map[Identifier]
end

return Environment