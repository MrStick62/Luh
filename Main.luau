--!strict

local Luh = require("./Luh")

local State = Luh.NewState(require("./Script").Content)

if State then
    State:Run()
    
    local Main = State:GetGlobal("Main")
    if typeof(Main) == "function" then
        Main({ "Hello, World!" })
    end
end

--Luh.Run(require("./Script").Content)