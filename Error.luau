--!strict

local Location = require("./Location")
type Location = Location.Location

local Error = {}
Error.__index = Error

type ErrorData = {
    ShouldHalt: boolean,
    Listeners: { (Location: Location, Message: string) -> () }
}

export type Error = typeof(setmetatable({} :: ErrorData, Error))

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


function Error.New(): Error
    local Self = {}

    Self.ShouldHalt = false
    Self.Listeners = {}

    return setmetatable(Self, Error)
end

function Error.Listen(Self: Error, Function: (Location: Location, Message: string) -> ())
    table.insert(Self.Listeners, Function)
end

function Error.Broadcast(Self: Error, Location: Location, Message: string)
    for _, Listener in Self.Listeners do
        Listener(Location, Message)
    end
end

function Error.Report(Self: Error, Location: Location, Message: string, Type: number)
    Self:Broadcast(Location, `[line {Location.Line}] {TypeText[Type]} Error: {Message}`)

    Self.ShouldHalt = true
end

return Error