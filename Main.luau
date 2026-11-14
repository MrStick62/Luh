--!strict

local Luh = require("./Luh")

local Script = [[

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

var V1, V2 = Vector3.New(2, 2, 2), Vector3.New(1, 2, 3)
print(V1:ToString(2))

]]

Luh.Run(Script)