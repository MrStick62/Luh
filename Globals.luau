--!strict

local Token = require("./Token")
type Token = Token.Token

local Interpreter = require("./Interpreter")
type Interpreter = Interpreter.Interpreter

local Reference = require("./Reference")

local Globals = {}

function Globals.ToLuhFunction(Func: (...any) -> ...any)
    return function(Caller: Token, Arguments: { any })
        local Result = nil

        local Ok, Err = xpcall(
            function(...)
                Result = table.pack(Func(table.unpack(Arguments)))
            end,
            function(Err)
                return Err
            end)

        if not Ok then
            Interpreter.Error(Caller, Err)
        end

        return Result or { n = 0 }
    end
end

function Globals.Load(Interpreter: Interpreter)

    Interpreter:LoadGlobal("print", Globals.ToLuhFunction(print))
    Interpreter:LoadGlobal("meta", Globals.ToLuhFunction(setmetatable))

    Interpreter:LoadGlobal("insert", Globals.ToLuhFunction(table.insert))
    Interpreter:LoadGlobal("unpack", Globals.ToLuhFunction(table.unpack))
    
    --[[
    Interpreter:LoadGlobal(
        "print", 
        function(Caller: Token, Arguments: { any }) 
            if #Arguments == 0 then
                print()
                return { Size = 0 }
            end

            if #Arguments ~= 1 then
                Interpreter.Error(Caller, `Function 'print' expects 1 argument, but got {#Arguments}`)
            end

            if Interpreter.HasMetaMethod(Arguments[1], "__tostring") then
                print(Arguments[1].__tostring(Caller, { Arguments[1] })[1])
                return { Size = 0 }
            end

            print(tostring(Arguments[1]))
            return { Size = 0 }
        end
    )

    Interpreter:LoadGlobal(
        "tostring", 
        function(Caller: Token, Arguments: { any }) 
            if #Arguments ~= 1 then
                Interpreter.Error(Caller, `Function 'tostring' expects 1 argument, but got {#Arguments}`)
            end

            if Interpreter.HasMetaMethod(Arguments[1], "__tostring") then
                return Arguments[1].__tostring(Caller, { Arguments[1] })
            end

            return { tostring(Arguments[1]), Size = 1 }
        end
    )

    Interpreter:LoadGlobal(
        "typeof", 
        function(Caller: Token, Arguments: { any }) 
            if #Arguments ~= 1 then
                Interpreter.Error(Caller, `Function 'typeof' expects 1 argument, but got {#Arguments}`)
            end

            return { typeof(Arguments[1]), Size = 1 }
        end
    )

    Interpreter:LoadGlobal(
        "math", 
        {
            sqrt = function(Caller: Token, Arguments: { any })
                if #Arguments ~= 1 then
                    Interpreter.Error(Caller, `Function 'sqrt' expects 1 argument, but got {#Arguments}`)
                end

                if typeof(Arguments[1]) ~= "number" then
                    Interpreter.Error(Caller, `Attempt to call 'sqrt' on {typeof(Arguments[1])}`)
                end

                return { math.sqrt(Arguments[1]), Size = 1 }
            end
        }
    )


    Interpreter:LoadGlobal(
        "meta",
        function(Caller: Token, Arguments: { any })
            if #Arguments ~= 2 then
                Interpreter.Error(Caller, `Function 'meta' expects 2 arguments, but got {#Arguments}`)
            end

            local Table = Arguments[1]
            local Behavior = Arguments[2]

            if typeof(Table) ~= "table" or typeof(Behavior) ~= "table" then
                Interpreter.Error(Caller, `Attempt to call 'meta' on {typeof(Table)} and {typeof(Behavior)}`)
            end

            return { setmetatable(Table, Behavior), Size = 1 }
        end
    )

    Interpreter:LoadGlobal(
        "table",
        {}
    )
    ]]
end

return Globals