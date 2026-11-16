--!strict

local Token = require("./Token")
type Token = Token.Token

local Interpreter = require("./Interpreter")
type Interpreter = Interpreter.Interpreter

local Globals = {}

function Globals.Load(Interpreter: Interpreter)
    Interpreter:LoadGlobal("print", print)
    Interpreter:LoadGlobal("tostring", tostring)
    Interpreter:LoadGlobal("assert", assert)
    Interpreter:LoadGlobal("error", error)

    Interpreter:LoadGlobal("table", {
        clear = table.clear,
        clone = table.clone,
        concat = table.concat,
        create = table.create,
        find = table.find,
        freeze = table.freeze,
        insert = table.insert,
        isfrozen = table.isfrozen,
        maxn = table.maxn,
        move = table.move,
        pack = table.pack,
        remove = table.remove,
        sort = table.sort,
        unpack = table.unpack,
    })

    Interpreter:LoadGlobal("clock", {
        date = os.date,
        now = os.clock,
        time = os.time,
    })

    Interpreter:LoadGlobal("meta", {
        set = setmetatable,
        get = getmetatable,
    })

    Interpreter:LoadGlobal("math", {
        abs = math.abs,
        acos = math.acos,
        asin = math.asin,
        atan = math.atan,
        atan2 = math.atan2,
        ceil = math.ceil,
        clamp = math.clamp,
        cos = math.cos,
        cosh = math.cosh,
        deg = math.deg,
        e = math.e,
        exp = math.exp,
        floor = math.floor,
        fmod = math.fmod,
        frexp = math.frexp,
        inf = math.huge,
        isfinite = math.isfinite,
        isinf = math.isinf,
        isnan = math.isnan,
        ldexp = math.ldexp,
        lerp = math.lerp,
        log = math.log,
        log10 = math.log10,
        map = math.map,
        max = math.max,
        min = math.min,
        modf = math.modf,
        nan = math.nan,
        nosie = math.noise,
        phi = math.phi,
        pi = math.pi,
        pow = math.pow,
        rad = math.rad,
        random = math.random,
        randomseed = math.randomseed,
        round = math.round,
        sign = math.sign,
        sin = math.sin,
        sinh = math.sinh,
        sqrt = math.sqrt,
        sqrt2 = math.sqrt2,
        tan = math.tan,
        tanh = math.tanh,
        tau = math.tau,
    })
end

return Globals