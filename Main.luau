--!strict

local Luh = require("./Luh")

local Script = [[

if 2 then
    1 + 2
elseif false then
    2 + 2
else
    2 + 3
end
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