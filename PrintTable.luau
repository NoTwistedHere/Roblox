local HttpService = game:GetService("HttpService")
local ObjectTypes = {
    ["nil"] = 1;
    ["boolean"] = 1;
    ["number"] = 1;
    ["string"] = 2;
    ["Instance"] = 3;
    ["userdata"] = 4;
    ["table"] = 4;
    ["function"] = 5;
}

local function CountTable(Table)
    local Count = 0

    for _ in next, Table do
        Count += 1
    end

    return Count
end

local function Unrep(String)
    local Counts = {}
    
    for i, v in next, String:split("") do
        if not Counts[v] then
            Counts[v] = 0
        end
        
        Counts[v] += 1
    end
    
    for i, v in next, Counts do
        if v > 100 then
            local Subbed = false
            String = String:gsub(i, function(C) if not Subbed then Subbed = true return C end return "" end)
            continue
        end
        
        Counts[i] = nil
    end
    
    return String, CountTable(Counts) > 0
end

local function AntiRep(String, ...) --// I'm too lazy
    local Unicode = String:gsub("[^%a%c%d%l%p%s%u%x]", "")

    if #Unicode > 2e3 then
        return Unicode, ...
    end

    return String, ...
end

local function ConvertCodepoints(OriginalString, Modified, Extra)
    if OriginalString:match("[^%a%c%d%l%p%s%u%x]") then
        local Utf8String = "utf8.char("

        if not pcall(function() for i, v in utf8.codes(OriginalString) do Utf8String ..= ("%s%s"):format(i > 1 and ", " or "", v) end end) then
            local String = ""

            for i = 1, #OriginalString do
                local Byte = string.byte(OriginalString, i, i)
                if Byte <= 126 and Byte >= 33 then
                    String ..= string.char(Byte)
                    continue;
                end

                String ..= "\\" .. Byte
            end

            return "\"" .. String .. "\"", Extra and true or false
        end
        
        if Extra then
            return Utf8String .. ")", true
        end

        return Utf8String ..")"
    end

    return "\""..OriginalString.."\"", Extra and Modified > 0 or nil
end

local function Tostring(Object)
    local Metatable = getrawmetatable(Object)

    if Metatable and rawget(Metatable, "__tostring") then
        local Old, IsReadOnly, Response = rawget(Metatable, "__tostring"), isreadonly(Metatable);

        setreadonly(Metatable, false)
        rawset(Metatable, "__tostring", nil)
        Response = tostring(Object)
        rawset(Metatable, "__tostring", Old)
        setreadonly(Metatable, IsReadOnly)

        return Response, " [Metatable]"
    end


    return tostring(Object)
end

local function Stringify(String, Extra, Checked, Root)
    local function Add(Message)
        if Checked and Root then
            Checked[String] = Message or Root
        end
    end

    if type(String) ~= "string" then
        return Tostring(String)
    elseif Checked and Checked[String] then
        return Checked[String]
    end

    if #String > 5e3 then
        local Message = ("\"String is larger than 5e3 (Very Large) #%s\""):format(HttpService:GenerateGUID())
        Add(Message)

        return Message
    elseif #String > 2e2 then
        Add()
    end
    
    return ConvertCodepoints(AntiRep(String:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("%c", function(Char) return "\\"..string.byte(Char) end), Extra))
end

local function ParseObject(Object, DetailedInfo, TypeOf, Checked, Root)
    local Type = typeof(Object)
    local ObjectType = ObjectTypes[Type]
    
    local function _Parse()
        if ObjectType == 2 then
            local String, Modified = Stringify(Object, true, Checked, Root)
            return String, Modified
        elseif ObjectType == 3 then
            return Stringify(Object:GetFullName(), false, Checked, Root), " ClassName: "..Object.ClassName
        elseif ObjectType == 5 then
            local Info = getinfo(Object)
            return ("%s"):format(tostring(Object)), (" source: %s, what: %s, name: %s (currentline: %s, numparams: %s, nups: %s, is_vararg: %s)"):format(Stringify(Info.source), Info.what, Stringify(Info.name), Info.currentline, Info.numparams, Info.nups, Info.is_vararg)
        else
            return Tostring(Object)
        end
    end

    local Parsed = {_Parse()}

    return Parsed[1], (TypeOf and ("[%s]"):format(Type) or "") .. (DetailedInfo and unpack(Parsed, 2) or "")
end

local function CheckForClone(Checked, Table)
    local TC = CountTable(Table)

    if TC <= 3 then
        return false
    end

    for Value, Count in next, Checked do
        if type(Value) == "table" and Count <= 3 or Count ~= TC then
            continue;
        end
        
        local MatchedCount = 0

        for Index, Value2 in next, Table do
            if rawequal(rawget(Value, Index), Value2) then
                MatchedCount += 1
            end
        end

        if MatchedCount == Count then
            return i
        end
    end

    return false
end

local function IncrementalRepeat(ToRepeat, Repeat, Increment)
    local Final = ""

    for i = 1, Repeat do
        Final ..= ToRepeat .. (Increment and i or "") .. (i == Repeat and "" or ", ")
    end

    return Final
end

local function YieldableFunc(OriginalFunction)
    local NoUV = #getupvalues(OriginalFunction) + 1
    local Variables, Values = IncrementalRepeat("_", NoUV, true), IncrementalRepeat("game", NoUV)
    local New = newcclosure(loadstring(([[
        local %s = %s

        return function()
            return %s
        end]]):format(Variables, Values, Variables)))()

    hookfunction(New, OriginalFunction)
    return New
end

local _PrintTable; _PrintTable = YieldableFunc(function(Table, Indents, Checked, Root)
    local Metatable, IsProxy = getrawmetatable(Table), typeof(Table) == "userdata"
    local TableCount, TabWidth, Count = IsProxy and 0 or CountTable(Table), "    ", 1

    Root = Root or "Table"
    Checked = Checked or {}
    Indents = Indents or 1
    Checked[Table] = TableCount

    if TableCount >= 3e3 then
        return "{ \"Table is too large\" }; --// Max: 5e3"
    elseif IsProxy then
        return (Metatable and "setmetatable(%s, %s)" or "%s"):format(Tostring(Table), Metatable and _PrintTable(Metatable, Indents, Checked))
    elseif TableCount == 0 then
        return (Metatable and "setmetatable(%s, %s)" or "%s"):format("{}", Metatable and _PrintTable(Metatable, Indents, Checked))
    end

    local NewTable, Results, Threads, Yield = {}, {}, 0, coroutine.running()

    for i, v in next, Table do
        table.insert(NewTable, {i, v})
    end

    for ThreadNum = 0, math.ceil(TableCount / 200) - 1 do
        Threads += 1

        task.spawn(function()
            for TIndex = 1, 200 do
                local Data = NewTable[TIndex + (200 * ThreadNum)]

                if not Data then
                    break;
                end

                local Index, Value = Data[1], Data[2]

                local NewRoot = Root..("[%s]"):format(Stringify(Index))
                local AlreadyLogged = type(Value) == "table" and (Checked[Value] or CheckForClone(Checked, Value))

                if AlreadyLogged then
                    Results[TIndex] = ("%s[%s] = %s%s%s"):format(string.rep(TabWidth, Indents), ParseObject(Index, false, false, Checked, NewRoot), Tostring(Value), Count < TableCount and "," or "", Checked[Value] and "" or " --// Duplicate of "..Tostring(AlreadyLogged))
                    Count += 1
                    continue;
                end

                local IsValid = (type(Value) == "table" or typeof(Value) == "userdata") and not Checked[Value]
                local Parsed = {ParseObject(Value, true, true, Checked, NewRoot)}
                local ParsedValue = IsValid and _PrintTable(Value, Indents + 1, Checked, NewRoot) or Parsed[1]
                local Comment = (IsValid and Parsed[1]..(Parsed[2] and " " or "") or "") .. (Parsed[2] and Parsed[2] or "")

                Results[TIndex] = ("%s[%s] = %s%s%s"):format(string.rep(TabWidth, Indents), ParseObject(Index, false, false, Checked, NewRoot), ParsedValue, Count < TableCount and "," or "", #Comment > 0 and " --// " .. Comment or "")
                Count += 1
            end

            Threads -= 1

            if Threads == 0 then
                if coroutine.status(Yield) ~= "suspended" then
                    repeat
                        task.wait()
                    until coroutine.status(Yield) == "suspended"
                end

                coroutine.resume(Yield, (Metatable and "setmetatable(%s, %s)" or "%s"):format(TableCount == 0 and "{}" or ("{\n%s\n%s}"):format(table.concat(Results, "\n"), string.rep(TabWidth, Indents - 1)), Metatable and _PrintTable(Metatable, Indents, Checked)))
            end
        end)
    end

    return coroutine.yield()
end)

getgenv().PrintTable = YieldableFunc(function(Table)
    local Type = typeof(Table)
    assert((Type == "table" or Type == "userdata"), "PrintTable: Invalid Argument #1 (table or userdata expected)")

    local Success, Response = pcall(_PrintTable, Table)

    return (Success and Response) or ("PrintTable: \"%s\""):format(Response)
end)