--!strict

local Reference = {}
Reference.__index = Reference

type ReferenceData = {
    Wrapper: { [any]: any },
    Index: any,
    Mutable: boolean,
}

export type Reference = typeof(setmetatable({} :: ReferenceData, Reference))

function Reference.New(Value: any, Mutable: boolean?): Reference
    local Self = {}

    Self.Wrapper = { Value }
    Self.Index = 1
    Self.Mutable = Mutable or false

    return setmetatable(Self, Reference)
end

function Reference.FromTable(Wrapper: { [any]: any }, Index: any): Reference
    local Self = {}

    Self.Wrapper = Wrapper
    Self.Index = Index
    Self.Mutable = true

    return setmetatable(Self, Reference)
end

function Reference.Get(Self: Reference): any
    return Self.Wrapper[Self.Index]
end

function Reference.Set(Self: Reference, Value: any): boolean
    if Self.Mutable then
        Self.Wrapper[Self.Index] = Value
        return true
    end

    return false
end

return Reference