--!strict

local Luh = require("./Luh")

local Script = [[

for i, v in { 2, 6, 1 } do
    print(i .. v)
end

fun Hello()
    return 2, nil, 3, nil, nil, 5
end

var x, y, z, w, a, b, c = nil, Hello(), 1
print(x .. y .. z .. w .. a .. b .. c)


var Add = {}

fun Add.__add(Self, X)
    return Self.x, X
end

var Table = meta({x = 1}, Add)
print(1, Table + 2)


fun ipairs(tbl)
    var i = 0
    return fun()
        i += 1
        var Value = tbl[i]
        return Value and i, Value
    end
end

for i, v in ipairs({ 3, 2 }) do
    print(i .. v)
end

for i, v in { 5, 6, 7 } do
    print(i .. v)
end

fun Hello()
    return 2, nil, 3, nil, nil, 5
end

var x, y, z, w, a, b, c = nil, Hello()
print(x .. y .. z .. w .. a .. b .. c)

var Vector3 = {}
Vector3.__index = Vector3

fun Vector3.New(X, Y, Z)
    var Self = {}

    Self.X = X
    Self.Y = Y
    Self.Z = Z

    return meta(Self, Vector3)
end

fun Vector3.__add(Self, Value)
    return Vector3.New(Self.X + Value.X, Self.Y + Value.Y, Self.Z + Value.Z)
end

fun Vector3.__sub(Self, Value)
    return Vector3.New(Self.X - Value.X, Self.Y - Value.Y, Self.Z - Value.Z)
end

fun Vector3.__mul(Self, Value)
    return Vector3.New(Self.X * Value, Self.Y * Value, Self.Z * Value)
end

fun Vector3.__div(Self, Value)
    return Vector3.New(Self.X * Value, Self.Y * Value, Self.Z * Value)
end

fun Vector3.__len(Self)
    return math.sqrt(Self.X^2 + Self.Y^2 + Self.Z^2)
end

fun Vector3.__tostring(Self)
    return "X: " .. Self.X .. ", Y: " .. Self.Y .. ", Z: " .. Self.Z    
end

fun Vector3.ToString(Self, x)
    return "X: " .. Self.X * x .. ", Y: " .. Self.Y * x .. ", Z: " .. Self.Z * x
end

fun Vector3.__iter(Self)
    var Order = {
        { i = "X", v = Self.X },
        { i = "Y", v = Self.Y },
        { i = "Z", v = Self.Z },
    }
    return fun(t, i)
        i += 1
        var Pair = Order[i]
        if not Pair then
            return nil
        end
        return i, Pair.v
    end, Self, 0
end

var V1, V2 = Vector3.New(2, 2, 2), Vector3.New(1, 2, 3)
var V3 = V1 + V2
print(V3:ToString(2))

for i, v in V1 do
    print(i .. v)
end

]]

Luh.Run(Script)