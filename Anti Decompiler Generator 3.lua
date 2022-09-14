--// I would like to note this won't be finished as I'm not trying to release an anti decompiler for v3

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
        return RandomlyPickFrom(CustomCharset) .. (Length > 0 and _RandomCharacters(Length - 1, CustomCharset) or "")
    end

    return utf8.char(RandomInteger(0, 1114111)) .. (Length > 0 and _RandomCharacters(Length - 1) or "")
end

function RandomCharacters(Length, CustomCharset)
    local Thousands = Length / 1000
    local LeftOver = (Thousands - math.floor(Thousands)) * 1000
    local Result = ""

    if Length <= 0 then
        return ""
    end

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
    local Math = RandomlyPickFrom({"os.clock()", "tick()", "math.abs(%s)", "math.pow(%s, %s)", "math.rad(%s)", "math.rad(%s)", "math.log(%s, %s)", "math.ldexp(%s, %s)", "math.floor(%s)", "math.exp(%s)", ("string.len([===[%s]===])"):format(Chars), ("utf8.len([===[%s]===])"):format(Chars)})

    if Math:match("%[===%[") then
        return Math
    end

    return Math:format(RandomNumber(Min, Max), RandomNumber(Min, Max))
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
        local Picked = RandomlyPickFrom(Options)(Variables)
        local Variable = GenerateVariable("__%s__", Variables)
        Result ..= ("local %s = %s%s\n"):format(Variable, Picked, ";")

        if Picked:sub(1, 1) == "{" then
            for i = 1, RandomInteger(5, 12) do
                Result ..= ("local %s = %s%s\n"):format(GenerateVariable("__%s__", Variables), Variable .. ("[%s]"):format(RandomInteger(5, 9e2)), ";")
            end
        end
    end

    --[[for i = 1, Number2 or RandomInteger(12, 22) do
        Result ..= (i == 1 and "" or ", ") .. RandomlyPickFrom(Options)(Variables)
    end]]

    return Result .. " end"
end


function GenerateNew()
    local Result = "if (function() return false end) and 0/0 * 2 == 0/0 then\nlocal "
    local Variables, NoV = {}, RandomInteger(6, 16)

    local NewOptions = {
        function() return GenerateFunction(Variables, "") end;
        function() return GenerateTable(Variables) end;
        function() return GenerateComplexEquation(RandomInteger(3, 13), RandomNumber(0, 12), RandomNumber(15, 9e3)) end;
    }
    
    for i = 1, NoV do
        Result ..= GenerateVariable("_%s_", Variables) .. (i == NoV and " = " or ", ")
    end

    for i = 1, NoV do
        Result ..= RandomlyPickFrom(NewOptions)() .. (i == NoV and ";" or ", ")
    end

    return Result .. "\nend"
end

writefile("Anti-Decompiler.lua", GenerateNew())
warn("done")
