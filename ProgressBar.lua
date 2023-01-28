--[[
    Feel free to report any issues or send me suggestions of what you'd like to see (NoTwistedHere#6703)
    (or you could just fork this)
]]

local Colours = { --// I'm English, it's not a spelling mistake
    ["#"] = 0.25;
    [-1] = "\x1b[0m";
    [0] = "\x1b[31m";
    [0.25] = "\x1b[33m";
    [0.5] = "\x1b[36m";
    [0.75] = "\x1b[32m";
    [1] = "\x1b[92m";
}

local ProgressBar = {}

local function Ret(Option, Default)
    if Option == nil then
        return Default
    end

    return Option
end

function ProgressBar.new(MaxSize, Max, Options)
    return setmetatable({
        _Progress = 0;
        _Percentage = 0;
        MaxSize = MaxSize;
        Max = Max;
        UseColours = Ret(Options.UseColours, true);
        Colours = Ret(Options.Colours, Colours)
    }, {
        __index = ProgressBar
    })
end

function ProgressBar:GetColour(NumPerc)
    if not self.UseColours then
        return Colours[-1];
    end

    local E = NumPerc % self.Colours["#"]

    return self.Colours[NumPerc - E]
end

function ProgressBar:WriteBar(Progress, Percentage)
    local End = ""

    if Progress == self._Progress then
        return;
    end

    if self._CursorSaved then
        rconsoleprint("\x1b[u")
    end

    local Colour = self:GetColour(Progress / self.MaxSize)

    rconsoleprint(Colour)

    for i = 1, Progress do
        End ..= "#"
    end

    End ..= self.Colours[-1]

    for i = 1, self.MaxSize - Progress do
        End ..= "."
    end

    End ..= Colour

    rconsoleprint(Colour)

    rconsoleprint(`\x1b[{#tostring(self._Percentage) + 2 + self.MaxSize}D`)
    rconsoleprint(`{End} {Percentage}%`)
    rconsoleprint(self.Colours[-1])
    rconsoleprint("\x1b[s")

    self._CursorSaved = true
    self._Progress = Progress
    self._Percentage = Percentage
end

function ProgressBar:Update(Current)
    self:WriteBar(math.floor(self.MaxSize * Current / self.Max), math.floor(100 * Current / self.Max))
end

return ProgressBar