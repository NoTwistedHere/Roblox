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
local GetFullName = game.GetFullName
local getthreadcontext = getthreadcontext or getthreadidentity or (syn and syn.get_thread_identity)
local setthreadcontext = setthreadcontext or setthreadcontext or (syn and syn.set_thread_identity)
local rconsolewarn = rconsolewarn or newcclosure(function(String)
    rconsoleprint(("\n[*] %s"):format(String))
end)
local hookmetamethod = hookmetamethod or newcclosure(function(Object, Metamethod, Function)
    local Metatable = assert(getrawmetatable(Object), ("bad argument #1 (%s does not have a metatable)"):format(tostring(typeof(Object))))
    local Original = assert(rawget(Metatable, Metamethod), "bad argument #2 (metamethod doesn't exist)")
    assert(type(Function) == "function", "bad argument #3 (function expected)")

    return hookfunction(Original, Function)
end)

if not getthreadcontext or not setthreadcontext then
    if not game:GetService("Players").LocalPlayer then
        game:Shutdown()
        return;
    end

    game:GetService("Players").LocalPlayer:Kick("Unsupported exploit")
    return;
end

if rconsolename then
    rconsolename("RemoteSpy")
end

local function Stringify(String)
    if type(String) ~= "string" then
        return;
    end

    local Stringified = String:gsub("\"", "\\\""):gsub("\\(d+)", function(Char) return "\\"..Char end):gsub("[%c%s]", function(Char) return "\\"..(utf8.codepoint(Char) or 0) end)
    return Stringified
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
    return ("%s/%s/%s %s:%s:%s:%s"):format(Time:FormatUniversalTime("D", "en-us"), Time:FormatUniversalTime("M", "en-us"), Time:FormatUniversalTime("YYYY", "en-us"), Time:FormatUniversalTime("H", "en-us"), Time:FormatUniversalTime("m", "en-us"), Time:FormatUniversalTime("s", "en-us"), Time:FormatUniversalTime("SSS", "en-us"))--// why is there no en-uk
end

local function CheckDep(String1, Comparison)
    if not (type(String1) == "string" and type(Comparison) == "string") then
        return false
    end

    local Dep = Comparison:sub(1, 1):lower()..Comparison:sub(2, 9e5)

    if String1 == Comparison or String1 == Dep then
        return true
    end

    return false
end

local function Log(...)
    local Arguments = {...}

    for i, v in next, Arguments do
        if type(v) == "string" then
            Arguments[i] = Stringify(v)
        elseif type(v) == "table" then
            Arguments[i] = PrintTable(v)
        end
    end

    if Arguments[7] then
        return rconsolewarn(("\nWhat: %s\nMethod: %s\nTo Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s"):format(Arguments[1], Arguments[2], Arguments[3], Arguments[4], Arguments[5], Arguments[7], Arguments[6]))
    end

    rconsolewarn(("\nWhat: %s\nMethod: %s\nTo Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s"):format(Arguments[1], Arguments[2], Arguments[3], Arguments[4], Arguments[5], Arguments[6]))
end

local pcall, unpack, assert = pcall, unpack, assert

for Name, Method in next, Methods do
    local Original; Original = hookfunction(Instance.new(Name)[Method], function(...)
        local Arguments = {...}
        local self = ...
        local Response = Original(...)
        local ClassName = self.ClassName
        local Info = getinfo(3)

        if RemoteSpyEnabled and Enabled[ClassName] and not Ignore(...) then
            if ClassName:match("Function") then
                Log(GetFullName(self), Method, Info.short_src, Timestamp(), Arguments, Info, Response)
            else
                Log(GetFullName(self), Method, Info.short_src, Timestamp(), Arguments, Info)
            end
        end
    
        return unpack(Response)
    end)
end

local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", function(...)
    local self = ...
    local Response = {OldNamecall(...)}
    local ClassName = self.ClassName
    local Method = getnamecallmethod() or ""
    local Arguments = {...}

    if Methods[ClassName] and Enabled[ClassName] and RemoteSpyEnabled and CheckDep(Method, Methods[ClassName]) and not Ignore(...) then
        local Info = getinfo(3)

        if ClassName:match("Function") then
            Log(GetFullName(self), Method, Info.short_src, Timestamp(), Arguments, Info, Response)
        else
            Log(GetFullName(self), Method, Info.short_src, Timestamp(), Arguments, Info, Response)
        end
    end

    return unpack(Response)
end)

local OldNewIndex; OldNewIndex = hookmetamethod(game, "__newindex", function(self, ...)
    local Arguments = {...}

    if self:IsA("RemoteFunction") and TrueString(Arguments[1]) == "OnClientInvoke" and type(Arguments[2]) == "function" then
        local ClassName = self.ClassName
        local Name = Stringify(GetFullName(self))
        local Function = Arguments[2]
        local Info = getinfo(Function)

        if not (islclosure(Function) and #getupvalues(Function) == 0 and #getconstants(Function) == 1 and typeof(getconstant(Function, 1)) == "userdata") then
            local Old;
            
            local function DoOtherFunction(...)
                local InvokedArguments = {...}
                local Response = {Old(...)}

                if RemoteSpyEnabled and Enabled[ClassName] then
                    Log(Name, "ClientInvoke", Stringify(Info.short_src), Timestamp(), InvokedArguments, Info, Response)
                end

                return unpack(Response)
            end
            
            Old = hookfunction(Function, function(...)
                return DoOtherFunction(...)
            end)
        end
    end
    
    return OldNewIndex(self, ...)
end)
