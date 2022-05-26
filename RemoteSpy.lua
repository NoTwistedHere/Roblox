--// Report any issues/detections to me

if not PrintTable then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.lua"))("a")
end

getgenv().RemoteSpyEnabled = RemoteSpyEnabled or true
getgenv().Enabled = Enabled or {
    BindableEvent = false;
    BindableFunction = false;
    RemoteEvent = true;
    RemoteFunction = true;
    OnClientInvoke = true;
}
local Methods = {
    BindableEvent = "Fire";
    BindableFunction = "Invoke";
    RemoteEvent = "FireServer";
    RemoteFunction = "InvokeServer";
}
local Directory, FileName, FileType = "RemoteSpyLogs/", ("RemoteSpy Logs [%s_%s]"):format(game.PlaceId, game.PlaceVersion), ".luau"
local GetFullName = game.GetFullName
local isexecutorfunction = isexecutorfunction or is_synapse_function or isexecutorclosure or isourclosure or function(f) return getinfo(f, "s").source:find("@") and true or false end
local hookmetamethod = hookmetamethod or newcclosure(function(Object, Metamethod, Function)
    local Metatable = assert(getrawmetatable(Object), ("bad argument #1 (%s does not have a metatable)"):format(tostring(typeof(Object))))
    local Original = assert(rawget(Metatable, Metamethod), "bad argument #2 (metamethod doesn't exist)")
    assert(type(Function) == "function", "bad argument #3 (function expected)")
    
    return hookfunction(Original, Function)
end)

local getthreadidentity = getthreadidentity or syn.get_thread_identity
local setthreadidentity = setthreadidentity or syn.set_thread_identity

if not isexecutorfunction or not getinfo or not hookmetamethod then
    game:GetService("Players").LocalPlayer:Kick("Unsupported exploit")
    return;
end

if not isfolder(Directory) then
    makefolder(Directory)
end

if isfile(FileName..FileType) then
    local Name, Count = "", 0

    repeat
        Count += 1
        Name = FileName..(" (%d)"):format(Count)
    until not isfile(Directory..Name..FileType)
    
    FileName = Name
    
    if WriteToFile then
        writefile(Directory..FileName..FileType, "")
    end
end

local function ConvertCodepoints(OriginalString) --// cba to rename it
    if OriginalString:match("[^%a%c%d%l%p%s%u%x]") then
        local Utf8String = "utf8.char("

        if not pcall(function() for i, v in utf8.codes(OriginalString) do Utf8String ..= ("%s%s"):format(i > 1 and ", " or "", v) end end) then
            local String = ""

            for i = 1, #OriginalString do
                String ..= "\\" .. string.byte(OriginalString, i, i)
            end

            return "\""..String.."\""
        end

        return Utf8String ..")"
    end

    return "\""..OriginalString.."\""
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
        if not isfile(Directory..FileName..FileType) then
            writefile(Directory..FileName..FileType, Content)
        end

        return appendfile(Directory..FileName..FileType, Content)
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

    if Arguments.FunctionInfo then
        return Save(("What: %s\nMethod: %s\nTo Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s\nFunctionInfo: %s\nTraceback: %s\n"):format(Arguments.What, Arguments.Method, Arguments.Script, Arguments.Timestamp, Arguments.Arguments, Arguments.Response, Arguments.Info, Arguments.FunctionInfo, Arguments.Traceback))
    elseif Arguments.Response then
        return Save(("What: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s\nTraceback: %s\n"):format(Arguments.What, Arguments.Method, Arguments.Script, Arguments.Timestamp, Arguments.Arguments, Arguments.Response, Arguments.Info, Arguments.Traceback))
    end

    Save(("What: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nInfo: %s\nTraceback: %s\n"):format(Arguments.What, Arguments.Method, Arguments.Script, Arguments.Timestamp, Arguments.Arguments, Arguments.Info, Arguments.Traceback))
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
            return FirstInfo or getinfo(i - 1), Traceback
        end

        table.insert(Traceback, ("%s:%d"):format(Info.short_src, Info.currentline))

        if Info.what ~= "C" and not isexecutorfunction(Info.func) and not FirstInfo then
            FirstInfo = Info
        end
    end
end

local function SortArguments(self, ...)
    return self, {...}
end

for Name, Method in next, Methods do
    local Original; Original = hookfunction(Instance.new(Name)[Method], function(...)
        local self, Arguments = SortArguments(...)

        if RemoteSpyEnabled and ArgGuard(...) and Enabled[self.ClassName] and not Ignore(...) then
            local Thread = coroutine.running()
            local Info, Traceback = GetCaller()
            local Method = Method.." (Raw)"

            task.spawn(function(...)
                local Success, Response = SortArguments(pcall(Original, ...))

                if not Success then
                    return coroutine.resume(Thread, unpack(Response))
                end
    
                if self.ClassName:match("Function") then
                    Log({What = GetFullName(self), Method = Method, Script = Info.short_src, Timestamp = Timestamp(), Arguments = Arguments, Info = Info, Response = Response, Traceback = Traceback})
                else
                    Log({What = GetFullName(self), Method = Method, Script = Info.short_src, Timestamp = Timestamp(), Arguments = Arguments, Info = Info, Traceback = Traceback})
                end

                repeat
                    task.wait()
                until coroutine.status(Thread) == "suspended"
    
                coroutine.resume(Thread, unpack(Response))
            end, ...)
    
            return coroutine.yield()
        end

        return Original(...) --unpack(Response)
    end)
end

local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", function(...)
    local self, Arguments = SortArguments(...)
    local Method = getnamecallmethod()
    
    if RemoteSpyEnabled and ArgGuard(...) and Enabled[self.ClassName] and Methods[self.ClassName] == Method and not Ignore(...) then
        local Thread = coroutine.running()
        local Info, Traceback = GetCaller()

        task.spawn(function(...)
            setnamecallmethod(Method)
            local Success, Response = SortArguments(pcall(OldNamecall, ...))

            if not Success then
                return coroutine.resume(Thread, unpack(Response))
            end

            if self.ClassName:match("Function") then
                Log({What = GetFullName(self), Method = Method, Script = Info.short_src, Timestamp = Timestamp(), Arguments = Arguments, Info = Info, Response = Response, Traceback = Traceback})
            else
                Log({What = GetFullName(self), Method = Method, Script = Info.short_src, Timestamp = Timestamp(), Arguments = Arguments, Info = Info, Traceback = Traceback})
            end

            repeat
                task.wait()
            until coroutine.status(Thread) == "suspended"

            coroutine.resume(Thread, unpack(Response))
        end, ...)

        return coroutine.yield()
    end

    return OldNamecall(...) --unpack(Response)
end)

local function SafeCall(Function, ...)
    local Old, SetFEnv, OldEnv, Success, Response = getthreadidentity(), setfenv, getfenv();

    setthreadidentity(2)
    SetFEnv(getfenv(Function))
    Success, Response = SortArguments({pcall(Function, ...)}) --// you're loss ;)
    SetFEnv(OldEnv)
    setthreadidentity(Old)

    return Success, Response
end

local function IsValid(Parsed, Checked)
    local Checked = Checked or {}

    table.insert(Checked, Parsed)

    if type(Parsed) == "function" then
        return true
    elseif typeof(Parsed) == "userdata" and getrawmetatable(Parsed) then
        return IsValid(rawget(getrawmetatable(Parsed), "__call"), Checked)
    end

    return false
end

local function IsValidIndex(Index)
    return Index == "OnClientInvoke" or Index == "onClientInvoke"
end

local OldNewIndex; OldNewIndex = hookmetamethod(game, "__newindex", function(...)
    local self, Arguments = SortArguments(...)

    if ArgGuard(...) and self:IsA("RemoteFunction") and IsValidIndex(TrueString(Arguments[1])) and pcall(IsValid, Arguments[2]) then
        local Name, ClassName = GetFullName(self), self.ClassName
        local Function = Arguments[2]
        local FunctionInfo = getinfo(Function)
        local Info, Traceback = GetCaller()

        return OldNewIndex(self, "OnClientInvoke", function(...)
            local Success, Response = SafeCall(Function, ...)

            --[[if not Success then --// Commented out because I know of an easy way to bypass, but feel free to enable it if you wish
                return coroutine.resume(Thread, unpack(Response))
            end]]

            if RemoteSpyEnabled and Enabled["OnClientInvoke"] then
                Log({What = Name, Method = "InvokeClient", Script = Info.short_src, Timestamp = Timestamp(), Arguments = {...}, FunctionInfo = FunctionInfo, Info = Info, Response = not Success and "Script Error: "..Response or Response, Traceback = Traceback})
            end

            if not Success then
                return;
            end

            return unpack(Response)
        end)
    end

    return OldNewIndex(...)
end)