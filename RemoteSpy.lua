--// Report any issues/detections to me

if not PrintTable then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.lua"))()
end

getgenv().RemoteSpyEnabled = true
getgenv().Enabled = {
    BindableEvent = false,
    BindableFunction = false,
    RemoteEvent = true,
    RemoteFunction = true,
}
local Methods = {
    BindableEvent = "Fire",
    BindableFunction = "Invoke",
    RemoteEvent = "FireServer",
    RemoteFunction = "InvokeServer"
}
local FileName, FileType = ("RemoteSpy Logs [%s_%s]"):format(game.PlaceId, game.PlaceVersion), ".luau"
local GetFullName = game.GetFullName
local isexecutorfunction = isexecutorfunction or is_synapse_function or isexecutorclosure or isourclosure or function(f) return getinfo(f, "s").source:find("@") and true or false end
local hookmetamethod = hookmetamethod or newcclosure(function(Object, Metamethod, Function)
    local Metatable = assert(getrawmetatable(Object), ("bad argument #1 (%s does not have a metatable)"):format(tostring(typeof(Object))))
    local Original = assert(rawget(Metatable, Metamethod), "bad argument #2 (metamethod doesn't exist)")
    assert(type(Function) == "function", "bad argument #3 (function expected)")
    
    return hookfunction(Original, Function)
end)

if not isexecutorfunction or not getinfo or not hookmetamethod then
    game:GetService("Players").LocalPlayer:Kick("Unsupported exploit")
    return;
end

if isfile(FileName..FileType) then
    local Name, Count = "", 0

    repeat
        Count += 1
        Name = FileName..(" (%d)"):format(Count)
    until not isfile(Name..FileType)
    
    FileName = Name
    
    if WriteToFile then
        writefile(FileName..FileType, "")
    end
end

local function ConvertCodepoints(OriginalString) --// cba to rename it
    if OriginalString:match("[^%a%c%d%l%p%s%u%x]") then
        local String = "utf8.char("
        
        for i, v in utf8.codes(OriginalString) do
            String ..= ("%s%s"):format(i > 1 and "," or "", v)
        end
        
        return String .. ") --// "..OriginalString
    end

    return OriginalString
end

local function Stringify(String)
    if type(String) ~= "string" then
        return;
    end
    
    return ConvertCodepoints(String:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\\(d+)", function(Char) return "\\"..Char end):gsub("[%c%s]", function(Char) if Char ~= " " then return "\\"..(utf8.codepoint(Char) or 0) end end))
end

local function TrueString(String)
    if type(String) ~= "string" then
        return false
    end

    return (string.split(String, "\0"))[1]
end

local function Ignore(self, ...)
    if getgenv().Ignore then
        return getgenv().Ignore(self, ...)
    end

    return false
end

local function Timestamp()
    local Time = DateTime.now()
    return ("%s/%s/%s %s:%s:%s:%s"):format(Time:FormatUniversalTime("D", "en-us"), Time:FormatUniversalTime("M", "en-us"), Time:FormatUniversalTime("YYYY", "en-us"), Time:FormatUniversalTime("H", "en-us"), Time:FormatUniversalTime("m", "en-us"), Time:FormatUniversalTime("s", "en-us"), Time:FormatUniversalTime("SSS", "en-us"))--// broken?
end

local function Save(Content)
    if WriteToFile then
        if not isfile(FileName..FileType) then
            writefile(FileName..FileType, Content)
        end

        return appendfile(FileName..FileType, Content)
    end

    rconsoleprint(Content)
end

local function Log(Arguments)
    for i, v in next, Arguments do
        if type(v) == "string" then
            Arguments[i] = Stringify(v)
        elseif type(v) == "table" then
            Arguments[i] = PrintTable(v)
        end
    end

    if Arguments.Response then
        return Save(("\nWhat: %s\nMethod: %s\n%s Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s\nFunctionInfo: %s\n Traceback: %s"):format(Arguments.What, Arguments.Method, Arguments.Method == "OnClientInvoke" and "To" or "From", Arguments.Script, Arguments.Timestamp, Arguments.Arguments, Arguments.Response, Arguments.Info, Arguments.FunctionInfo, Arguments.Traceback))
    end

    Save(("\nWhat: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nInfo: %s\nTraceback: %s"):format(Arguments.What, Arguments.Method, Arguments.Script, Arguments.Timestamp, Arguments.Arguments, Arguments.Info, Arguments.Traceback))
end

local function ArgGuard(self, ...)
    if typeof(self) ~= "Instance" then
        return false
    end

    for i, v in next, {...} do
        if type(v) == "table" and rawget(v, v) then
            return false
        end
    end

    return true
end

local function GetCaller()
    local Traceback, FirstInfo = {};
    for i = 1, 16380 do
        local Info = getinfo(i)

        if not Info then
            return FirstInfo, Traceback
        elseif Info.what == "C" or isexecutorfunction(Info.func) then
            continue;
        end

        table.insert(Traceback, ("%s:%d"):format(Stringify(Info.short_src), Info.currentline))
        FirstInfo = FirstInfo or Info
    end
end

local function SortArguments(self, ...)
    return self, {...}
end

for Name, Method in next, Methods do
    local Original; Original = hookfunction(Instance.new(Name)[Method], function(...)
        local self, Arguments = SortArguments(...)
        local Response = "Disabled" --{pcall(Original, ...)}

        if RemoteSpyEnabled and ArgGuard(...) and Enabled[self.ClassName] and not Ignore(...) then
            local Info, Traceback = GetCaller()
            local Method = Method.." (Raw)"

            if self.ClassName:match("Function") then
                Log({What = GetFullName(self), Method = Method, Script = Info.short_src, Timestamp = Timestamp(), Arguments = Arguments, Info = Info, Response = Response, Traceback = Traceback})
            else
                Log({What = GetFullName(self), Method = Method, Script = Info.short_src, Timestamp = Timestamp(), Arguments = Arguments, Info = Info, Traceback = Traceback})
            end
        end

        return Original(...) --unpack(Response)
    end)
end

local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", function(...)
    local self, Arguments = SortArguments(...)
    local Method = getnamecallmethod()
    local Response = "Disabled" --{pcall(OldNamecall, ...)}
    
    if RemoteSpyEnabled and ArgGuard(...) and Enabled[self.ClassName] == Method and not Ignore(...) then
        local Info, Traceback = GetCaller()
        if self.ClassName:match("Function") then
            Log({What = GetFullName(self), Method = Method, Script = Info.short_src, Timestamp = Timestamp(), Arguments = Arguments, Info = Info, Response = Response, Traceback = Traceback})
        else
            Log({What = GetFullName(self), Method = Method, Script = Info.short_src, Timestamp = Timestamp(), Arguments = Arguments, Info = Info, Traceback = Traceback})
        end
    end

    return OldNamecall(...) --unpack(Response)
end)

local OldNewIndex; OldNewIndex = hookmetamethod(game, "__newindex", function(...)
    local self, Arguments = SortArguments(...)

    if self:IsA("RemoteFunction") and TrueString(Arguments[1]) == "OnClientInvoke" and type(Arguments[2]) == "function" and islclosure(Arguments[2]) and not (islclosure(Function) and #getupvalues(Function) == 0 and #getconstants(Function) == 1 and typeof(getconstant(Function, 1)) == "userdata") then
        local Name, ClassName = self.ClassName, Stringify(GetFullName(self))
        local Function = Arguments[2]
        local FunctionInfo = getinfo(Function)
        local Info, Traceback = GetCaller()
        local Old;

        local function DoOtherFunction(...)
            local InvokedArguments = {...}
            local Response = {Old(...)}

            if not getinfo(3) and RemoteSpyEnabled and Enabled[ClassName] and not Ignore(...) then
                Log({What = Name, Method = "ClientInvoke", Script = Stringify(Info.short_src), Timestamp = Timestamp(), Arguments = InvokedArguments, FunctionInfo = FunctionInfo, Info = Info, Response = Response, Traceback = Traceback})
            end

            return unpack(Response)
        end

        Old = hookfunction(Function, function(...)
            return DoOtherFunction(self, ...)
        end)
    end

    return OldNewIndex(...)
end)