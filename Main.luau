--!strict

local Luh = require("./Luh")

local Script = [[

fun Fibonacci(n)
    if n <= 1 then
        return n
    end

    var first = 1
    var second = 1

    for i = 3, n do
        var curr = first + second
        first = second
        second = curr
    end

    return second
end

var index = 5
print("Fib[" .. index .. "]: " .. Fibonacci(index))

]]

--[[

local Script = [[
2 or (5 + 200) / 8.5
var short = "bruh"
var value = x * (5 + 200) / 8.5

<!

<!

This comment spans multiple lines!
yipee!

!>

!>

if 1 ~= 2 then
end

]]

Luh.Run(Script)