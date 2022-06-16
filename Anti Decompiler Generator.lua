local Result = [[]]
local AlphabeticalCharset = {}
local Blacklisted = {"\"", "'", "[", "]"}
for i = 48, 57 do table.insert(AlphabeticalCharset, string.char(i)) end
for i = 65, 90 do table.insert(AlphabeticalCharset, string.char(i)) end
for i = 97, 122 do table.insert(AlphabeticalCharset, string.char(i)) end

local function _RandomCharacters(Length, CustomCharset)
	local CustomCharset = type(CustomCharset) == "table" and CustomCharset or nil
	if CustomCharset then
		return Length > 0 and _RandomCharacters(Length - 1, CustomCharset) .. CustomCharset[Random.new():NextInteger(1, #CustomCharset)] or ""
	end

    local _Random = Random.new():NextInteger(1, 1114111)
    local Character = utf8.char(_Random)

    if table.find(Blacklisted, Character) then
        return _RandomCharacters(Length)
    end

	return Length > 0 and _RandomCharacters(Length - 1) .. Character or ""
end

local function RandomCharacters(Length, CustomCharset)
	local Count = Length / 1000
	local Resulting = Count - math.floor(Count)
	local Result = ""
	for i = 1, math.floor(Count) do
		Result ..= _RandomCharacters(1000, CustomCharset)
	end

	if Resulting > 0 then
		Result ..= _RandomCharacters(Resulting * 1000, CustomCharset)
	end

	return Result
end

local VariableNames = {}
local TableNames = {}
local GlobalVariables = {"pcall", "xpcall", "spawn", "delay", "task.spawn", "wait", "task.wait", "task.delay", "Random.new", "debug.info", "Instance.new", "tick", "newproxy", "RaycastParams.new", "assert", "utf8.char", "getmetatable", "setmetatable", "table.find", "string.format", "string.rep", "string.gsub", "string.sub", "os.clock", "debug.traceback"}
local Funny = {[[\"\\\"]], [[\\]], [[\'\\\"]]}

do
    local GenerateFunction, GenerateTable, GenerateTable2;
    local function GenerateVariable(Prefix, Table)
        local Prefix = Prefix or "%s"
        local Name = (Prefix):format(RandomCharacters(Random.new():NextInteger(3, 6), AlphabeticalCharset))

        if Table then
            if table.find(Table, Name) then
                return GenerateVariable(Prefix, Table)
            end

            table.insert(Table, Name)
        end

        return Name
    end

	for i = 1, 3 do
        local Name = GenerateVariable("__%s__", VariableNames)
        local Rand = Random.new():NextInteger(1, 2)
        if Rand == 1 then
		    Result ..= ("\nlocal %s = {%d, %d, {}, {%d}, {{%d}}}"):format(Name, Random.new():NextInteger(0, 9), Random.new():NextInteger(0, 9), Random.new():NextInteger(0, 9), Random.new():NextInteger(0, 9))
        elseif Rand == 2 then
            local EndResult = ("\nlocal %s = {%d, %d, {}, {%d}"):format(Name, Random.new():NextInteger(0, 9), Random.new():NextInteger(0, 9), Random.new():NextInteger(0, 9))
            for _ = 1, Random.new():NextInteger(2, 5) do
                local Rand2 = Random.new():NextInteger(1, 2)
                if Rand2 == 1 then
                    EndResult ..= (", \"%s\""):format(RandomCharacters(4))
                    continue;
                end

                EndResult ..= (", {%d, {}}"):format(Random.new():NextInteger(0, 9))
            end

            Result ..= EndResult.."}"
        end
	end

	GenerateTable2 = function()
		return ("{%d, [[%s]]}"):format(Random.new():NextNumber(20, 3000), RandomCharacters(Random.new():NextInteger(350, 400)))
	end

	GenerateTable = function(Table, Number)
        local Table = Table or VariableNames
		local EndResult = ("{%d, %d, %d, {{}, %d"):format(Random.new():NextInteger(0, 9), Random.new():NextInteger(0, 9), Random.new():NextInteger(0, 9), Random.new():NextInteger(0, 9))
		for _ = 1, Number or 180 do
			local Rand = Random.new():NextInteger(1, 15)
			if Rand == 1 then
				EndResult ..= (", {%s}"):format(Table[Random.new():NextInteger(1, #Table)])
			elseif Rand == 2 then
				EndResult ..= (", {#%s - #%s}"):format(Table[Random.new():NextInteger(1, #Table)], Table[Random.new():NextInteger(1, #Table)])
			elseif Rand == 3 then
				EndResult ..= (", {%s == %s}"):format(Table[Random.new():NextInteger(1, #Table)], Table[Random.new():NextInteger(1, #Table)])
			elseif Rand == 4 then
				EndResult ..= (", #{%s} + #{%s}"):format(Table[Random.new():NextInteger(1, #Table)], Table[Random.new():NextInteger(1, #Table)])
			elseif Rand == 6 then
				EndResult ..= (", {%s, {%s}}"):format(Table[Random.new():NextInteger(1, #Table)], Table[Random.new():NextInteger(1, #Table)])
			elseif Rand == 7 then
				EndResult ..= (", #%s * %d"):format(Table[Random.new():NextInteger(1, #Table)], Random.new():NextInteger(1, 2) == 1 and Random.new():NextNumber(1, 3) or Random.new():NextNumber(5e5, 9e9))
			elseif Rand == 8 then
				EndResult ..= (", #%s - #\"%s\""):format(Table[Random.new():NextInteger(1, #Table)], RandomCharacters(Random.new():NextInteger(4, 8)))
            elseif Rand == 9 then
                EndResult ..= (", %d ^ %d"):format(Random.new():NextNumber(1, 9), Random.new():NextNumber(1, 9))
            elseif Rand == 10 then
                if Random.new():NextInteger(1, 2) == 1 then
                    EndResult ..= (", %s"):format(GlobalVariables[Random.new():NextInteger(1, #GlobalVariables)])
                    continue;
                end

                EndResult ..= (", {%s, {%s}}"):format(GlobalVariables[Random.new():NextInteger(1, #GlobalVariables)], GlobalVariables[Random.new():NextInteger(1, #GlobalVariables)])
            elseif Rand == 11 then
                EndResult ..= (", {tick() - (tick() / %d)}"):format(Random.new():NextNumber(1, 20))
			elseif Rand == 12 then
				EndResult ..= (", \"%s\""):format(Funny[Random.new():NextInteger(1, #Funny)])
			elseif Rand == 13 then
				EndResult ..= (", [==[%s]==]"):format(RandomCharacters(Random.new():NextInteger(130, 140)))
            elseif Rand == 14 then
                EndResult ..= (", [==[%s]==]"):format(RandomCharacters(600))
            elseif Rand == 15 then
                EndResult ..= (", %s"):format(GenerateFunction("function(%s)", " "))
            elseif Rand == 16 then
                --EndResult ..= (", {%s(%s, %s)}"):format(GlobalVariables[Random.new():NextInteger(1, #GlobalVariables)], Random.new():NextNumber(1, 9), Table[Random.new():NextInteger(1, #Table)])
			end
		end

		return EndResult..("}, %s}"):format(GenerateTable2())
	end

    GenerateFunction = function(Prefix, TabWidth)
        local Prefix = Prefix or ("local function %s(%s)"):format(GenerateVariable("__%s"), "%s")
        local VariableNames2 = {}
        for i = 1, 12 do
            GenerateVariable("_%s_", VariableNames2)
        end

        local EndResult = (Prefix):format((function() local End = "" for i,v in next, VariableNames2 do End ..= ("%s%s"):format(v, i == #VariableNames2 and "" or ", ") end return End end)())
        local CustomTabWidth = TabWidth
        local TabWidth = CustomTabWidth or "\n    "

        for i = 1, Random.new():NextInteger(8, 12) do
            local Rand = Random.new():NextInteger(1, 5)
            if Rand == 1 then
                EndResult ..= ("%slocal %s = %s;"):format(TabWidth, GenerateVariable("__%s__", VariableNames2), GenerateTable(VariableNames2, 2, 8))
            elseif Rand == 2 then
                EndResult ..= ("%slocal %s = [=[%s]=];"):format(TabWidth, GenerateVariable("__%s__", VariableNames2), RandomCharacters(35))
            elseif Rand == 3 then
                EndResult ..= ("%slocal %s = (tick() / task.wait()) ^ %d;"):format(TabWidth, GenerateVariable("__%s__", VariableNames2), Random.new():NextNumber(3, 8))
            elseif Rand == 4 then
                EndResult ..= ("%slocal %s = #\"%s\" - %d;"):format(TabWidth, GenerateVariable("__%s__", VariableNames2), RandomCharacters(Random.new():NextInteger(5, 15)), Random.new():NextInteger(2, 25))
            elseif Rand == 5 then
                EndResult ..= ("%slocal %s = task.spawn(%s, %s);"):format(TabWidth, GenerateVariable("__%s__", VariableNames2), GlobalVariables[Random.new():NextInteger(1, #GlobalVariables)], (function() local Result = "" local _Rand = Random.new():NextInteger(3, 6) for i = 1, _Rand do Result ..= ("%s%s"):format(VariableNames2[Random.new():NextInteger(1, #VariableNames2)], i == _Rand and "" or ", ") end return Result end)())
            end
        end

        for i = 1, Random.new():NextInteger(22, 30) do
            local Rand = Random.new():NextInteger(1, 6)
            if Rand == 1 then
                EndResult ..= ("%s%s = %s;"):format(TabWidth, VariableNames2[Random.new():NextInteger(1, #VariableNames2)], VariableNames2[Random.new():NextInteger(1, #VariableNames2)])
            elseif Rand == 2 then
                EndResult ..= ("%s%s = #%s * #\"%s\";"):format(TabWidth, VariableNames2[Random.new():NextInteger(1, #VariableNames2)], VariableNames2[Random.new():NextInteger(1, #VariableNames2)], RandomCharacters(Random.new():NextInteger(12, 20), Random.new():NextInteger(1, 2) == 1 and AlphabeticalCharset))
            elseif Rand == 3 then
                EndResult ..= ("%s%s = (tick() / task.wait()) ^ %d;"):format(TabWidth, VariableNames2[Random.new():NextInteger(1, #VariableNames2)], Random.new():NextNumber(3, 8))
            elseif Rand == 4 then
                EndResult ..= ("%s%s = %s[%d] .. \"%s\";"):format(TabWidth, VariableNames2[Random.new():NextInteger(1, #VariableNames2)], VariableNames2[Random.new():NextInteger(1, #VariableNames2)], Random.new():NextInteger(1, 8), RandomCharacters(Random.new():NextInteger(15, 30)))
            elseif Rand == 5 then
                EndResult ..= ("%s%s[%d] = (%s == %s and %s or %s);"):format(TabWidth, VariableNames2[Random.new():NextInteger(1, #VariableNames2)], Random.new():NextInteger(1, 8), VariableNames2[Random.new():NextInteger(1, #VariableNames2)], GlobalVariables[Random.new():NextInteger(1, #GlobalVariables)], VariableNames2[Random.new():NextInteger(1, #VariableNames2)], VariableNames2[Random.new():NextInteger(1, #VariableNames2)])
            elseif Rand == 6 then
                local Global1 = GlobalVariables[Random.new():NextInteger(1, #GlobalVariables)]
                EndResult ..= ("%s%s[%d] = (%s == %s and %s(%s) or %s);"):format(TabWidth, VariableNames2[Random.new():NextInteger(1, #VariableNames2)], Random.new():NextInteger(1, 8), VariableNames2[Random.new():NextInteger(1, #VariableNames2)], Global1, Global1, VariableNames2[Random.new():NextInteger(1, #VariableNames2)], VariableNames2[Random.new():NextInteger(1, #VariableNames2)])
            elseif Rand == 7 then
                EndResult ..= ("%s%s[%d] = %s;"):format(TabWidth, VariableNames2[Random.new():NextInteger(1, #VariableNames2)], Random.new():NextInteger(1, 8), GenerateTable(VariableNames2, 5, 10))
            end
        end

        return ("%s%s"):format(EndResult, CustomTabWidth and " end" or "\nend;")
    end
	
	for _ = 1, 4 do
		local Name = GenerateVariable("__%s__")
		table.insert(TableNames, Name)
	end
	
	Result ..= ("\nlocal __%s__, __%s__, __%s__, __%s__ = %s, %s, %s, %s"):format(TableNames[1], TableNames[2], TableNames[3], TableNames[4], GenerateTable(), Random.new():NextInteger(1, 2) == 1 and GenerateFunction("function(%s)", " ") or GenerateTable(), GenerateTable(), Random.new():NextInteger(1, 2) == 1 and GenerateFunction("function(%s)", " ") or GenerateTable())
	
	for _ = 1, 5 do
		for _,v in next, TableNames do
			Result ..= ("\n__%s__ = %s"):format(v, GenerateTable())
		end
	end

	Result ..= ("\nlocal %s = %s"):format(GenerateVariable("__%s__"), GenerateTable2())
end

task.wait()

setclipboard(Result)