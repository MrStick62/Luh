--!strict

local Luh = require("./Luh")

local Script = [[

for i = 1, 10000 do
    print(i)
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