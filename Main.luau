--!strict

local Luh = require("./Luh")

local Script = [[
var a = 1

do
    var a = a + 3
    do
        var a = 5
        a
    end
    a
end
a
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