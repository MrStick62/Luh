--!strict

local Luh = require("./Luh")

local Script = [[
var str = "Hello, "
str .. "World!"
var num = 3 .. 2
(-num ^ 2)
num or (5 + 200) / 8.5
2 * (5 + 200) / 8.5
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