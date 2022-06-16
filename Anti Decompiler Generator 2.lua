local AlphabeticalCharset = {}
local Blacklisted = { "\"", "'", "[", "]", "%" }
local Operators = { "+", "-", "*", "/", "^" }
local Options = {
    function(Table) return ("%s"):format(RandomInteger(1, 2) == 1 and GenerateTable(Table, RandomInteger(2, 5)) or RandomlyPickFrom(Table)) end;
    function(Table) return ("%s"):format(GenerateComplexEquation(RandomInteger(3, 13), RandomInteger(2, 5), RandomInteger(5, 55))) end;
    function(Table) return ("[==[%s]==]"):format(RandomCharacters(RandomInteger(80, 150))) end;
    function(Table) return ("[==[%s]==]"):format(RandomCharacters(RandomInteger(300, 500))) end;
    function(Table) return GenerateTable(Table, RandomInteger(3, 6)) end;
}

for i = 48, 57 do table.insert(AlphabeticalCharset, string.char(i)) end
for i = 65, 90 do table.insert(AlphabeticalCharset, string.char(i)) end
for i = 97, 122 do table.insert(AlphabeticalCharset, string.char(i)) end

function RandomInteger(Min, Max)
    return Random.new():NextInteger(Min, Max)
end

function RandomNumber(Min, Max)
    return Random.new():NextNumber(Min, Max)
end

function CountTable(Table)
    local Count = 0

    for _ in next, Table do
        Count += 1
    end

    return Count
end

function RandomlyPickFrom(Table, ReturnIndex)
    local RND = RandomInteger(1, CountTable(Table))
    local Count = 0

    for i, v in next, Table do
        Count += 1

        if Count == RND then
            return ReturnIndex and i or v
        end
    end
end

function _RandomCharacters(Length, CustomCharset)
    if CustomCharset then
        return Length > 0 and _RandomCharacters(Length - 1, CustomCharset) .. RandomlyPickFrom(CustomCharset) or ""
    end

    local _Random = utf8.char(RandomInteger(1, 1114111))

    repeat
        _Random = utf8.char(RandomInteger(1, 1114111))
    until not table.find(Blacklisted, _Random)

    return Length > 0 and _RandomCharacters(Length - 1, CustomCharset) .. _Random or ""
end

function RandomCharacters(Length, CustomCharset)
    local Thousands = Length / 1000
    local LeftOver = (Thousands - math.floor(Thousands)) * 1000
    local Result = ""

    for i = 1, math.floor(Thousands) do
        Result ..= _RandomCharacters(1000, CustomCharset)
    end

    if LeftOver > 0 then
        Result ..= _RandomCharacters(LeftOver, CustomCharset)
    end

    return Result
end

--[[function GetRandomGlobal(Type, Return)
    local Valid = {}

    for i, v in next, Globals[Type] do
        if v.Return == Return then
            table.insert(Valid, v)
        end
    end

    return RandomlyPickFrom(Valid)
end]]

function GenerateEquation(Min, Max)
    return ("%s %s %s"):format(RandomInteger(Min, Max), RandomlyPickFrom(Operators), RandomInteger(Min, Max))
end

function GenerateMath(Min, Max)
    local Chars = RandomCharacters(RandomInteger(Min, Max))
    local Math = RandomlyPickFrom({"os.clock()", "tick()", "math.abs(%s)", "math.pow(%s, %s)", "math.rad(%s)", "math.rad(%s)", "math.log(%s, %s)", "math.ldexp(%s, %s)", "math.floor(%s)", "math.exp(%s)", ("string.len(\"%s\")"):format(Chars), ("utf8.len(\"%s\")"):format(Chars)})

    return Math:format(RandomInteger(Min, Max), RandomInteger(Min, Max))
end

function GenerateComplexEquation(Equations, Min, Max, Variables)
    local Result = GenerateEquation(Min, Max)
    local NewOptions = {
        function() return ("#%s"):format(RandomlyPickFrom(Variables)) end;
        function() return ("%s"):format(RandomlyPickFrom(Variables)) end;
    }

    for i = 1, Equations - 1 do
        Result = ("%s %s %s"):format((RandomInteger(1, 2) == 1 and "(%s)" or "%s"):format(Result), RandomlyPickFrom(Operators), RandomInteger(1, 2) == 1 and (Variables and RandomlyPickFrom(NewOptions) or RandomNumber(Min, Max)) or GenerateMath(Min, Max))
    end

    return Result
end

function GenerateVariable(Prefix, Names)
    local Prefix, Name = Prefix or "%s";
    local Names = Names or {}

    repeat
        Name = (Prefix):format(RandomCharacters(RandomInteger(5, 12), AlphabeticalCharset))
    until not table.find(Names, Name)
    
    table.insert(Names, Name)

    return Name
end

function GenerateTable(Table, Number)
    local Result = "{"
    local Rand = Number or RandomInteger(80, 100)

    for i = 1, Rand do
        Result ..= ("%s%s\n"):format(RandomlyPickFrom(Options)(Table), i == Rand and "" or ";")
    end

    return Result.."}"
end

function GenerateFunction(Variables, Name)
    local Variables = {}
    local Result = ("function %s(%s)"):format(Name or GenerateVariable("__%s", Variables), (function() local End, Rand = "", RandomInteger(6, 16) for i = 1, Rand do End ..= GenerateVariable("_%s_", Variables) .. (i == Rand and "" or ", ") end return End end)())
    local Rand = RandomInteger(8, 12)

    for i = 1, Rand do
        Result ..= ("local %s = %s%s\n"):format(GenerateVariable("__%s__", Variables), RandomlyPickFrom(Options)(Variables), ";")
    end

    --[[for i = 1, Number2 or RandomInteger(12, 22) do
        Result ..= (i == 1 and "" or ", ") .. RandomlyPickFrom(Options)(Variables)
    end]]

    return Result .. " end"
end

function GenerateNew()
    local Variables, NoV = {}, RandomInteger(6, 16)
    local NewOptions = {
        function() return GenerateFunction(Variables, "") end;
        function() return GenerateTable(Variables) end;
        function() return GenerateComplexEquation(RandomInteger(3, 13), RandomInteger(2, 5), RandomInteger(5, 55)) end;
    }
    local Result = ("local %s = %s"):format((function() local End = "" for i = 1, NoV do End ..= GenerateVariable("_%s_", Variables) .. (i == NoV and "" or ", ") end return End end)(),  (function() local End = "" for i = 1, NoV do End ..= RandomlyPickFrom(NewOptions)() .. (i == NoV and ";" or ", ") end return End end)())

    return Result
end

setclipboard(GenerateNew())