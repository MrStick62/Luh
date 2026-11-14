--!strict

local Luh = require("./Luh")

local Script = [[

var Vector3 = {}
Vector3.__index = Vector3

fun Vector3.New(X, Y, Z)
    var Self = {}

    Self.X = X
    Self.Y = Y
    Self.Z = Z

    return meta(Self, Vector3)
end

fun Vector3.__add(Left, Right)
    return Vector3.New(Left.X + Right.X, Left.Y + Right.Y, Left.Z + Right.Z)
end

fun Vector3.__sub(Left, Right)
    return Vector3.New(Left.X - Right.X, Left.Y - Right.Y, Left.Z - Right.Z)
end

fun Vector3.__mul(Left, Right)
    if typeof(Left) == "table" then
        return Vector3.New(Left.X * Right, Left.Y * Right, Left.Z * Right)
    else
        return Vector3.New(Left * Right.X, Left * Right.Y, Left * Right.Z)
    end
end


fun Vector3.__div(Left, Right)
    if typeof(Left) == "table" then
        return Vector3.New(Left.X * Right, Left.Y * Right, Left.Z * Right)
    else
        return Vector3.New(Left * Right.X, Left * Right.Y, Left * Right.Z)
    end
end

fun Vector3.__len(Self)
    return math.sqrt(Self.X^2 + Self.Y^2 + Self.Z^2)
end

fun Vector3.__tostring(Self)
    return "X: " .. Self.X .. ", Y: " .. Self.Y .. ", Z: " .. Self.Z    
end

var V1 = Vector3.New(2, 2, 2)
var V2 = Vector3.New(1, 2, 3)
print((V2 + V1) * #V1)

]]

Luh.Run(Script)