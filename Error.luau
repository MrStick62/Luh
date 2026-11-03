--!strict

local Location = require("./Location")
type Location = Location.Location

local Error = {}

local Listeners = {}

Error.ShouldHalt = false

Error.Type = {
    Lexer = 1,
    Syntax = 2,
    Runtime = 3,
}

local TypeText = {
    [Error.Type.Lexer] = "Lexer",
    [Error.Type.Syntax] = "Syntax",
    [Error.Type.Runtime] = "Runtime",
}

function Error.Listen(Function: (Location: Location, Message: string) -> ())
    table.insert(Listeners, Function)
end

function Error.Broadcast(Location: Location, Message: string)
    for _, Listener in Listeners do
        Listener(Location, Message)
    end
end

function Error.Report(Location: Location, Message: string, Type: number)
    Error.Broadcast(Location, `[line {Location.Line}] {TypeText[Type]} Error: {Message}`)

    Error.ShouldHalt = true
end

return Error