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

local function ConvertCodepoints(OriginalString, Modified) --// cba to rename it
    if OriginalString:match("[^%a%c%d%l%p%s%u%x]") then
        local String = "utf8.char("
        
        for i, v in utf8.codes(OriginalString) do
            String ..= ("%s%s"):format(i > 1 and "," or "", v)
        end
        
        return String .. ")", Modified, " --// "..OriginalString
    end

    return OriginalString, Modified
end

local function Stringify(String)
    if type(String) ~= "string" then
        return;
    end
    
    return ConvertCodepoints(String:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\\(d+)", function(Char) return "\\"..Char end):gsub("[%c%s]", function(Char) if Char ~= " " then return "\\"..(utf8.codepoint(Char) or 0) end end))
end

local function Tostring(Object)
    local Metatable = getrawmetatable(Object)
    local Response;

    if Metatable and not isreadonly(Metatable) and rawget(Metatable, "__tostring") then
        local Old = rawget(Metatable, "__tostring")
        rawset(Metatable, "__tostring", nil)
        Response = tostring(Object)
        rawset(Metatable, "__tostring", Old)
    end

    return Response or tostring(Object)
end

local function ParseObject(Object, DetailedInfo, TypeOf)
    local Type = typeof(Object)
    local ObjectType = ObjectTypes[Type]
    
    local function _Parse()
        if ObjectType == 1 then
            return Tostring(Object)
        elseif ObjectType == 2 then
            local String, Modified, Extra = Stringify(Object)
            return String, Modified and " [Modified]", Extra
        elseif ObjectType == 3 then
            return Stringify(Object:GetFullName())
        elseif ObjectType == 4 then
            return Tostring(Object), getrawmetatable(Object) and " [Metatable]"
        elseif ObjectType == 5 then
            local Info = getinfo(Object)
            return ("%s"):format(tostring(Object)), ("source: %s, what: %s, name: \"%s\" (currentline: %s, numparams: %s, nups: %s, is_vararg: %s)"):format(Stringify(Info.source), Info.what, Stringify(Info.name), Info.currentline, Info.numparams, Info.nups, Info.is_vararg)
        else
            return Tostring(Object)
        end
    end

    local Parsed = {_Parse()}
    local Main = Parsed[1]
    table.remove(Parsed, 1)

    return Main .. (TypeOf and (" [%s]"):format(Type) or ""), (DetailedInfo and unpack(Parsed) or "")
end

_PrintTable = function(Table, Indents, Checked)
    local TableCount, TabWidth, Result, Count = CountTable(Table), "    ", "", 1
    local Metatable = getrawmetatable(Table)

    Checked = Checked or {}
    Indents = Indents or 1
    Checked[Table] = true

    for i,v in next, Table do
        local IsValid = type(v) == "table" and not Checked[v]
        local Parsed = {ParseObject(v, true, true)}
        local Value = IsValid and _PrintTable(v, Indents + 1, Checked) or Parsed[1]
        local Comment = (IsValid and (" %s"):format(Parsed[1]) or "") .. (Parsed[2] or "")

        Result ..= ("%s[%s] = %s%s%s\n"):format(string.rep(TabWidth, Indents), ParseObject(i), Value, Count < TableCount and "," or "", #Comment > 0 and " --//" .. Comment or "")
        Count += 1
    end

    return (Metatable and "setmetatable(%s, %s)" or "%s"):format(TableCount == 0 and "{}" or ("{\n%s%s}"):format(Result, string.rep(TabWidth, Indents - 1)), Metatable and _PrintTable(Metatable, Indents, Checked))
end

getgenv().PrintTable = newcclosure(function(Table)
    local Type = typeof(Table)
    assert((Type == "table" or Type == "userdata"), "PrintTable: Invalid Argument #1 (table or userdata expected)")

    local Success, Response = pcall(_PrintTable, Table)

    return (Success and Response) or ("PrintTable: \"%s\""):format(Response)
end)