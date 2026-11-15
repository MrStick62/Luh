--!strict

local Luh = require("./Luh")

local Script = [[

var start = clock.now()

fun IsPrime(n)
    if n < 2 then
        return false
    end

    for i = 2, n ^ 0.5 do
        if n % i == 0 then
            return false
        end
    end

    return true
end

fun CountPrimes(limit)
    var count = 0

    for i = 2, limit do
        if IsPrime(i) then
            count = count + 1
        end
    end

    return count
end

print(CountPrimes(100000))

print(clock.now() - start)

]]

Luh.Run(Script)