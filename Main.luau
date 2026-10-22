--!strict

local Luh = require("./Luh")

local Script = [[
local short = "bruh"
local value = x * (5 + 2) / 8

if 1 ~= 2 then
end
]]

Luh.Run(Script)