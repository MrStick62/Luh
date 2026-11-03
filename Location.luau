local Location = {}
Location.__index = Location

type LocationData = {
    Line: number,
    Offset: number,
    Length: number,
}

export type Location = typeof(setmetatable({} :: LocationData, Location))

function Location.New(Line: number, Offset: number, Length: number): Location
    local Self = {}

    Self.Line = Line
    Self.Offset = Offset
    Self.Length = Length

    return setmetatable(Self, Location)
end

return Location