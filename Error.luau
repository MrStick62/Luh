--!strict

local Error = {}

local Listeners = {}

Error.ShouldHalt = false

Error.Severity = {
    Warning = 1,
    Halt = 2,
}

local SeverityText = {
    [Error.Severity.Warning] = "Warning",
    [Error.Severity.Halt] = "Error",
}

function Error.Listen(Function: (Message: string) -> ())
    table.insert(Listeners, Function)
end

function Error.Broadcast(Message: string)
    for _, Listener in Listeners do
        Listener(Message)
    end
end

function Error.Report(Line: number, Where: string, Message: string, Severity: number)
    Error.Broadcast((`[line {Line}] {SeverityText[Severity]}{#Where > 0 and ` {Where}` or ""}: {Message}`))

    if Severity == Error.Severity.Halt then
        Error.ShouldHalt = true
    end
end

return Error