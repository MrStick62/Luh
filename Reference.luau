--!strict

local Reference = {}
Reference.__index = Reference

type ReferenceData = {
    Wrapper: { [any]: any },
    Indices: { any },
    Mutable: boolean,
    Size: number,
}

export type Reference = typeof(setmetatable({} :: ReferenceData, Reference))

export type Tuple = typeof(table.pack())

function Reference.New(Value: any, Mutable: boolean?): Reference
    local Self = {}

    Self.Wrapper = { Value }
    Self.Indices = { 1 }
    Self.Mutable = Mutable or false
    Self.Size = 1

    return setmetatable(Self, Reference)
end

function Reference.Tuple(Tuple: Tuple): Reference
    local Self = {}

    
    Self.Wrapper = {}
    Self.Indices = {}
    Self.Mutable = false
    Self.Size = Tuple.n

    for i = 1, Tuple.n do
        Self.Wrapper[i] = Tuple[i]
        Self.Indices[i] = i
    end

    return setmetatable(Self, Reference)
end

function Reference.FromTable(Wrapper: { [any]: any }, Index: any): Reference
    local Self = {}

    Self.Wrapper = Wrapper
    Self.Indices = { Index }
    Self.Mutable = true
    Self.Size = 1

    return setmetatable(Self, Reference)
end

function Reference.Get(Self: Reference): any
    return Self.Wrapper[Self.Indices[1]]
end

function Reference.GetAll(Self: Reference): Tuple
    local Out = {}
    Out.n = Self.Size

    for i, Index in Self.Indices do
        Out[i] = Self.Wrapper[Index]
    end

    return Out
end

function Reference.Set(Self: Reference, Value: any): boolean
    if Self.Mutable then
        Self.Wrapper[Self.Indices[1]] = Value
        return true
    end

    return false
end

return Reference