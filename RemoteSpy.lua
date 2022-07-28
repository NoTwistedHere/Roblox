--[[
    Report any bugs, issues and detections to me if you don't mind
]]

script.Name = "RemoteSpy.lua"

if not PrintTable then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.luau"))()
end
local NUB = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/NoUpvalueHook.lua"))()

getgenv().WriteToFile = WriteToFile or false
getgenv().RobloxConsole = RobloxConsole or false
getgenv().GetCallerV2 = GetCallerV2 or false --// BETA - You are more vulnerable to detections!
getgenv().RemoteSpyEnabled = RemoteSpyEnabled or true
getgenv().GenerateCode = GenerateCode or false
getgenv().Enabled = Enabled or {
    BindableEvent = false;
    BindableFunction = false;
    RemoteEvent = true;
    RemoteFunction = true;
    OnClientInvoke = true;
    OnClientEvent = true;
    OnInvoke = false;
    Event = false;
}
local Events = {
    BindableEvent = "Event";
    BindableFunction = "OnInvoke";
    RemoteEvent = "OnClientEvent";
}
local Methods = {
    BindableEvent = "Fire";
    BindableFunction = "Invoke";
    RemoteEvent = "FireServer";
    RemoteFunction = "InvokeServer";
}
local Hooks = {}
local Stacks, Source = {}, getinfo(1).source
local Directory, FileName, FileType = "RemoteSpyLogs/", ("RemoteSpy Logs [%s_%s]"):format(game.PlaceId, game.PlaceVersion), ".luau"
local HttpService = game:GetService("HttpService")
local isexecutorfunction = isexecutorfunction or is_synapse_function or isexecutorclosure or isourclosure or function(f) return getinfo(f, "s").source:find("@") and true or false end
local getthreadidentity = getthreadidentity or syn.get_thread_identity
local setthreadidentity = setthreadidentity or syn.set_thread_identity
local isvalidlevel = debug.isvalidlevel or debug.validlevel or function(s) local k = pcall(function() return getinfo(s + 3) end) return k end
local hookmetamethod = hookmetamethod or newcclosure(function(Object, Metamethod, Function)
    local Metatable = assert(getrawmetatable(Object), ("bad argument #1 (%s does not have a metatable)"):format(tostring(typeof(Object))))
    local Original = assert(rawget(Metatable, Metamethod), "bad argument #2 (metamethod doesn't exist)")
    assert(type(Function) == "function", "bad argument #3 (function expected)")
    
    return hookfunction(Original, Function)
end)

if not isexecutorfunction or not getinfo or not hookmetamethod or not setthreadidentity then
    game:GetService("Players").LocalPlayer:Kick("Unsupported exploit")
    return;
end

if not isfolder(Directory) then
    makefolder(Directory)
end

if isfile(Directory..FileName..FileType) then
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

    (RobloxConsole and print or rconsoleprint)(Content)
end

local function IsService(Object)
    local Success, Response = pcall(function()
        return game:GetService(Object.ClassName)
    end)
    
    return Success and Response
end

local function GetName(Name)
    if tonumber(Name:sub(1, 1)) or Name:match("([0-9a-zA-Z]*)") ~= Name then
        return ("[\"%s\"]"):format(Name)
    end
    
    return (".%s"):format(Name)
end

local function GetPath(Object, Sub)
    local Path = GetName(Object.Name):reverse()
    local Parent = Object.Parent
    
    if Parent == game then
        Path = ("game"):reverse()
    elseif Parent and IsService(Parent) then
        Path ..= (":GetService(\"%s\")"):format(Parent.ClassName):reverse()
        Path ..= GetPath(Parent, true)
    elseif Parent then
        Path ..= GetPath(Parent, true)
    elseif Object ~= game then
        Path ..= ("nil"):reverse()
    end
    
    if Sub then
        return Path
    end
    
    return Path:reverse()
end

local function GenerateC(self, Method, Arguments)
    local R = PrintTable(Arguments, {NoIndentation = true, OneLine = true, NoComments = true, IgnoreNumberIndex = true, GenerateScript = true})
    local Result = R[1]

    Result ..= ("%s:%s(%s)"):format(GetPath(self), Method, R[2])
    
    return Result
end

local function Log(Arguments, NewThread)
    local function Main()
        local GeneratedCode = GenerateCode and GenerateC(Arguments.self, Arguments.RawMethod or Arguments.Method, Arguments.Arguments) or "Disabled"

        for i, v in next, Arguments do
            if type(v) == "string" then
                Arguments[i] = Stringify(v)
            elseif type(v) == "table" then
                if i == "Traceback" then
                    Arguments[i] = PrintTable(v, {NoComments = true, IgnoreNumberIndex = true})
                    continue;
                end

                Arguments[i] = PrintTable(v)
            end
        end

        if Arguments.FunctionInfo then
            return Save(("What: %s\nMethod: %s\nTo Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s\nFunctionInfo: %s\nTraceback: %s\nGenerated Code:\n%s\n"):format(Arguments.What, Arguments.Method, Arguments.Script, Timestamp(), Arguments.Arguments, Arguments.Response, Arguments.Info, Arguments.FunctionInfo, Arguments.Traceback, GeneratedCode))
        elseif Arguments.Response then
            return Save(("What: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s\nTraceback: %s\nGenerated Code:\n%s\n"):format(Arguments.What, Arguments.Method, Arguments.Script, Timestamp(), Arguments.Arguments, Arguments.Response, Arguments.Info, Arguments.Traceback, GeneratedCode))
        elseif not Arguments.Info then
            return Save(("What: %s\nMethod: %s\nTimestamp: %s\nArguments: %s\nGenerated Code:\n%s\n"):format(Arguments.What, Arguments.Method, Timestamp(), Arguments.Arguments, GeneratedCode))
        end

        Save(("What: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nInfo: %s\nTraceback: %s\nGenerated Code:\n%s\n"):format(Arguments.What, Arguments.Method, Arguments.Script, Timestamp(), Arguments.Arguments, Arguments.Info, Arguments.Traceback, GeneratedCode))
    end

    if NewThread then --// There's a reason as to why I try and avoid task.spawn, but I'm not trying to release semi-bypasses
        return task.spawn(Main)
    end

    return Main()
end

local function ArgGuard(self, ...)
    if typeof(self) ~= "Instance" then
        return false
    end

    local Arguments = {...}

    if self.ClassName:match("Function") and #Arguments > 7995 then
        return false
    end

    for i, v in next, {...} do
        if type(v) == "table" and rawget(v, v) then
            return false
        end
    end

    return true
end

local function FixTable(Table)
    local Yeah = {}

    for i, v in next, Table do
        table.insert(Yeah, v)
    end

    return Yeah
end

local function V2CheckArguments(Arguments)
    if type(Arguments) ~= "table" then
        return false
    end

    local Traceback, Info = {};

    for i, v in next, Arguments do
        if type(v) == "string" and Stacks[v] then
            local Stack = Stacks[v]

            for _, v2 in next, Stack[2] do
                table.insert(Traceback, v2)
            end

            Info = Stack[1]
            Arguments[i] = nil
        end
    end

    return {Info, Traceback, FixTable(Arguments)}
end

local function GetCaller(Arguments)
    local Traceback, FirstInfo = {};

    for i = 1, 16380 do
        local Info = isvalidlevel(i) and getinfo(i)

        if not Info then
            local NewInfo = FirstInfo or getinfo(i - 1)

            if GetCallerV2 then
                local ValidArgs = V2CheckArguments(Arguments)

                if ValidArgs then
                    for _i, v in next, ValidArgs[2] do
                        table.insert(Traceback, v)
                    end

                    NewInfo = ValidArgs[1] or NewInfo

                    return NewInfo, Traceback, ValidArgs[3]
                end
            end
            
            return NewInfo, Traceback, Arguments
        end
        
        if Info.source ~= Source then
            table.insert(Traceback, ("%s:%d%s"):format(Info.short_src, Info.currentline, Info.name ~= "" and " function " .. Info.name or ""))
        end

        if Info.what ~= "C" and not isexecutorfunction(Info.func) and not FirstInfo then
            FirstInfo = Info
        end
    end
end

local function SortArguments(self, ...)
    return self, {...}
end

local function IsValidMethod(ClassName, Method)
    return Methods[ClassName] == Method:sub(1, 1):upper()..Method:sub(2, #Method)
end

if GetCallerV2 then
    local IsNotTraceable = {
        getrenv().coroutine.create,
        getrenv().coroutine.wrap,
        getrenv().delay,
        getrenv().task.spawn,
        getrenv().task.defer,
        getrenv().task.delay,
        getrenv().spawn
    }

    local function GenerateGUID(Info, Traceback)
        local GUID = HttpService:GenerateGUID(false)

        Stacks[GUID] = {Info, Traceback}

        return GUID
    end

    local function HookFunc(Func)
        local Old; Old = hookfunction(Func, function(...)
            local _Args = {...}

            if #_Args == 0 then
                return Old(...)
            end

            local Arguments = GetCallerV2 and V2CheckArguments(_Args)[3] or _Args
            local Call = table.remove(Arguments, 1)
    
            if type(Call) ~= "function" then
                return Old(...)
            end

            local Info, Traceback, Arguments = GetCaller({...})
            local Edited = false

            if Hooks[Call] then
                Edited = true
                table.insert(Arguments, 2, GenerateGUID(Info, Traceback))
            end

            for i, v in next, Arguments do
                if not IsNotTraceable[v] and not Hooks[v] and not Stacks[v] then
                    break;
                elseif Hooks[v] then
                    Edited = true
                    table.insert(Arguments, i + 1, GenerateGUID(Info, Traceback))
                    --Call = Arguments[i - 1] or Call
                    continue;
                end
            end

            if Edited then
                return Old(Call, unpack(Arguments))
            end
    
            return Old(Call, ...)
        end)
    end

    local function HookFuncThread(Func)
        local Old; Old = hookfunction(Func, function(...)
            local _Args = {...}

            if #_Args == 0 then
                return Old(...)
            end

            local Arguments = GetCallerV2 and V2CheckArguments(_Args)[3] or _Args
            local Call = table.remove(Arguments, 1)
    
            if type(Call) ~= "function" and type(Call) ~= "thread" then
                return Old(...)
            end
    
            local Info, Traceback, Arguments = GetCaller({...})
            local Edited = false

            if Hooks[Call] then
                Edited = true
                table.insert(Arguments, 2, GenerateGUID(Info, Traceback))
            end

            for i, v in next, Arguments do
                if not IsNotTraceable[v] and not Hooks[v] and not Stacks[v] then
                    break;
                elseif Hooks[v] then
                    Edited = true
                    table.insert(Arguments, i + 1, GenerateGUID(Info, Traceback))
                    --Call = Arguments[i - 1] or Call
                    continue;
                end
            end

            if Edited then
                return Old(Call, unpack(Arguments))
            end
    
            return Old(Call, ...)
        end)
    end

    local OldS; OldS = hookfunction(spawn, function(...) --// I'm sorry Melancholy, this is a quick patch before I go to work
        local _Args = {...}

        if #_Args == 0 then
            return OldS(...)
        end

        local Arguments = GetCallerV2 and V2CheckArguments(_Args)[3] or _Args
        local Call = table.remove(Arguments, 1)

        if type(Call) ~= "function" and type(Call) ~= "thread" and typeof(Call) ~= "userdata" and (not getrawmetatable(Call) or not getrawmetatable(Call).__call) then
            return OldS(Call, unpack(Arguments))
        end

        local Info, Traceback, Arguments = GetCaller({...})
        local Edited = false

        if Hooks[Call] then
            Edited = true
            table.insert(Arguments, 2, GenerateGUID(Info, Traceback))
        end

        for i, v in next, Arguments do
            if not IsNotTraceable[v] and not Hooks[v] and not Stacks[v] then
                break;
            elseif Hooks[v] then
                Edited = true
                table.insert(Arguments, i + 1, GenerateGUID(Info, Traceback))
                --Call = Arguments[i - 1] or Call
                continue;
            end
        end

        if Edited then
            return OldS(Call, unpack(Arguments))
        end

        return OldS(Call, ...)
    end)

    HookFunc(getrenv().coroutine.create)
    HookFunc(getrenv().coroutine.wrap)
    HookFunc(getrenv().delay)
    HookFuncThread(getrenv().task.spawn)
    HookFuncThread(getrenv().task.defer)
    HookFuncThread(getrenv().task.delay)
end

local function ReturnArguments(Arguments, ...)
    if GetCallerV2 and #Arguments <= 7995 then
        return unpack(Arguments)
    end

    return ...
end

for Name, Method in next, Methods do
    local Func = Instance.new(Name)[Method]
    local Original; Original = hookfunction(Func, function(...)
        local _Args = {...}
        local Arguments = GetCallerV2 and V2CheckArguments(_Args)[3] or _Args
        local self = table.remove(Arguments, 1)

        if RemoteSpyEnabled and #Arguments <= 7995 and ArgGuard(self, ReturnArguments(Arguments, ...)) and Enabled[self.ClassName] and not Ignore(self, ReturnArguments(Arguments, ...)) then
            local Info, Traceback, Arguments = GetCaller({...}) --// Because the stack trace gets removed from _Args
            Thread = coroutine.running()

            table.remove(Arguments, 1)

            if self.ClassName:match("Function") then --// Events return nil so what's the point in yielding? just leads to retarded detections
                task.spawn(function(...)
                    local Success, Response = SortArguments(pcall(Original, self, ReturnArguments(Arguments, ...)))

                    --[[if not Success then
                        return coroutine.resume(Thread, unpack(Response))
                    end]]
            
                    Log({self = self, What = GetPath(self), RawMethod = Method, Method = Method .. " (Raw)", Script = Info.short_src, Arguments = Arguments, Info = Info, Response = Response, Traceback = Traceback})

                    repeat
                        task.wait()
                    until coroutine.status(Thread) == "suspended"
            
                    coroutine.resume(Thread, unpack(Response))
                end, ...)
            
                return coroutine.yield()
            end

            Log({self = self, What = GetPath(self), RawMethod = Method, Method = Method .. " (Raw)", Script = Info.short_src, Arguments = Arguments, Info = Info, Traceback = Traceback}, true)
        end

        return Original(self, ReturnArguments(Arguments, ...)) --unpack(Response)
    end)

    Hooks[Func] = Original
end

local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", function(...)
    local self, Arguments = SortArguments(...)
    local Method = getnamecallmethod()
    
    if RemoteSpyEnabled and ArgGuard(...) and Enabled[self.ClassName] and IsValidMethod(self.ClassName, Method) and not Ignore(...) then
        local Thread = coroutine.running()
        local Info, Traceback, Arguments = GetCaller(Arguments)

        if #Arguments > 7995 then
            return OldNamecall(ReturnArguments(Arguments, ...)) --// Thank you Lua
        end

        if self.ClassName:match("Function") then --// Events return nil so what's the point in yielding? just leads to retarded detections
            task.spawn(function(...)
                setnamecallmethod(Method)
                local Success, Response = SortArguments(pcall(OldNamecall, self, ReturnArguments(Arguments, ...)))

                --[[if not Success then
                    return coroutine.resume(Thread, unpack(Response))
                end]]

                Log({self = self, What = GetPath(self), Method = Method, Script = Info.short_src, Arguments = Arguments, Info = Info, Response = Response, Traceback = Traceback})

                repeat
                    task.wait()
                until coroutine.status(Thread) == "suspended"

                coroutine.resume(Thread, unpack(Response))
            end, ...)

            return coroutine.yield()
        end

        Log({self = self, What = GetPath(self), Method = Method, Script = Info.short_src, Arguments = Arguments, Info = Info, Traceback = Traceback}, true)
        setnamecallmethod(Method)
    end

    if typeof(self) == "Instance" and IsValidMethod(self.ClassName, Method) then
        return OldNamecall(ReturnArguments(Arguments, ...))
    end

    return OldNamecall(...) --unpack(Response)
end)

local function SafeCall(Function, ...)
    local Old, SetFEnv, OldEnv = getthreadidentity(), setfenv, getfenv()

    setthreadidentity(2)
    SetFEnv(0, getfenv(Function))
    local Success, Response = SortArguments(pcall(Function, ...)) --// you're loss ;)
    SetFEnv(0, OldEnv)
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
    return rawequal(Index, "OnClientInvoke") or rawequal(Index, "onClientInvoke")
end

local function Listen(Instance, Event)
    if Instance:IsA("RemoteFunction") or Instance:IsA("BindableFunction") then
        return;
    end

    Instance[Event]:Connect(function(...)
        if Enabled[Event] then
            Log({self = Instance, What = GetPath(Instance), Method = Event, Arguments = {...}})
        end
    end)
end

game.DescendantAdded:Connect(function(Obj)
    if Methods[Obj.ClassName] and Events[Obj.ClassName] then
        Listen(Obj, Events[Obj.ClassName])
    end
end)

for i, v in next, game:GetDescendants() do
    if Methods[v.ClassName] and Events[v.ClassName] then
        Listen(v, Events[v.ClassName])
    end
end

for i, v in next, getnilinstances() do
    if Methods[v.ClassName] and Events[v.ClassName] then
        Listen(v, Events[v.ClassName])
    end
end

local OldNewIndex; OldNewIndex = hookmetamethod(game, "__newindex", function(...)
    local self, Arguments = SortArguments(...)

    if ArgGuard(...) and self:IsA("RemoteFunction") and IsValidIndex(TrueString(Arguments[1])) and pcall(IsValid, Arguments[2]) then
        local Name, ClassName = GetPath(self), self.ClassName
        local Function = Arguments[2]
        local FunctionInfo = getinfo(Function)
        local Info, Traceback = GetCaller(...)

        --[==[return OldNewIndex(self, "OnClientInvoke", function(...)
            local Success, Response = SafeCall(Function, ...)

            --[[if not Success then --// Commented out because I know of an easy way to bypass, but feel free to enable it if you wish
                return coroutine.resume(Thread, unpack(Response))
            end]]

            if RemoteSpyEnabled and Enabled["OnClientInvoke"] then
                Log({self = self, What = Name, Method = "InvokeClient", Script = Info.short_src, Arguments = {...}, FunctionInfo = FunctionInfo, Info = Info, Response = not Success and "Script Error: "..Response or Response, Traceback = Traceback})
            end

            if not Success then
                return;
            end

            return unpack(Response)
        end)]==]

        NUB([=[local Success, Response = <<SafeCall>>(<<Function>>, ...)

        if <<getgenv>>().RemoteSpyEnabled and <<getgenv>>().Enabled["OnClientInvoke"] then
            Log({self = <<self>>, What = <<Name>>, Method = "InvokeClient", Script = <<Info>>.short_src, Arguments = {...}, FunctionInfo = <<FunctionInfo>>, Info = <<Info>>, Response = not Success and "Script Error: "..Response or Response, Traceback = <<Traceback>>})
        end

        if not Success then
            return;
        end

        return unpack(Response)]=], {SafeCall = SafeCall, Function = Function, getgenv = getgenv, Name = Name, self = self, Info = Info, FunctionInfo = FunctionInfo, Traceback = Traceback})
    end

    return OldNewIndex(...)
end)

--[[
local function CountTable(Table)
    local Count = 0

    for _ in next, Table do
        Count += 1
    end

    return Count
end

local function FixTable(Table)
    local Yeah = {}

    for i, v in next, Table do
        table.insert(Yeah, v)
    end

    return Yeah
end

local function Unpack(Table, ...)
    if CountTable(Table) > 7999 then
        local New = {}
        local Count = 0

        for i, v in next, Table do
            if Count < 7999 and v then
                Count += 1
                table.insert(New, v)
                Table[i] = nil
            end
        end

        return Unpack(FixTable(Table), unpack(New))
    end

    return ..., unpack(Table)
end

print(Unpack({unpack(table.create(7999, "woah")), unpack(table.create(7999, "woah"))}))
]]