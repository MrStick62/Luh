--!strict

local Location = require("./Location")
type Location = Location.Location

local Error = require("./Error")
type Error = Error.Error

local Lexer = require("./Lexer")
type Lexer = Lexer.Lexer

local Parser = require("./Parser")
type Parser = Parser.Parser

local Interpreter = require("./Interpreter")
type Interpreter = Interpreter.Interpreter

local Globals = require("./Globals")

local LuhState = {}
LuhState.__index = LuhState

type LuhStateData = {
    Error: Error,
    Lexer: Lexer,
    Parser: Parser,
    Interpreter: Interpreter,
}

export type LuhState = typeof(setmetatable({} :: LuhStateData, LuhState))

function LuhState.New(Source: string): LuhState?
    local Self = {}

    Self.Error = Error.New()

    Self.Error:Listen(function(Location: Location, Message: string)
        print(Message)
        print(Source:split('\n')[Location.Line])
        print(`{string.rep(' ', Location.Offset)}{string.rep('^', Location.Length)}`)
    end)

    Self.Lexer = Lexer.New(Source, Self.Error)
    local Tokens = Self.Lexer:ScanTokens()

    if Self.Error.ShouldHalt then
        return nil
    end

    Self.Parser = Parser.New(Tokens, Self.Error)
    local Ast = Self.Parser:Parse()

    if Self.Error.ShouldHalt then
        return nil
    end

    Self.Interpreter = Interpreter.New(Self.Error)

    Globals.Load(Self.Interpreter)

    Self.Interpreter:Run(Ast)

    return setmetatable(Self, LuhState)
end

function LuhState.GetGlobal(Self: LuhState, Identifier: string)
    local Reference = Self.Interpreter.GlobalEnvironment:Find(Identifier)

    return Reference and Reference:Get()
end

function LuhState.SetGlobal(Self: LuhState, Identifier: string, Value: any)
end

local Luh = {}

function Luh.NewState(Source: string)
    return LuhState.New(Source)
end

return Luh