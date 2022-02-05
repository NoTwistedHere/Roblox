--// Report any issues/detections to me

if not PrintTable then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.luau"))()
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

for i, v in next, Methods do
    local _Instance = Instance.new(i)
    local Original; Original = hookfunction(_Instance[v], newcclosure(function(self, ...)
        local Response = {Original(self, ...)}
        local ClassName = self.ClassName
        local Info = getinfo(3)
        local Arguments = {...}
        
        if RemoteSpyEnabled and Enabled[ClassName] and not Ignore(self, ...) then
            if ClassName:match("Function") then
                rconsolewarn(("\nWhat: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s"):format(GetFullName(self), v, Info.short_src or "NULL", Timestamp(), #Arguments > 0 and PrintTable(Arguments) or "None", Response and #Response > 0 and PrintTable(Response) or "None", PrintTable(Info)))
            else
                rconsolewarn(("\nWhat: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nInfo: %s"):format(GetFullName(self), v, Info.short_src or "NULL", Timestamp(), #Arguments > 0 and PrintTable(Arguments) or "None", PrintTable(Info)))
            end
        end
    
        return unpack(Response)
    end))
end

local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local Response = {OldNamecall(self, ...)}
    local ClassName = self.ClassName
    local Method = getnamecallmethod() or ""

    if Methods[ClassName] and Enabled[ClassName] and Methods[ClassName]:lower() == Method:lower() and RemoteSpyEnabled and not Ignore(self, ...) then
        local Arguments = {...}
        local Info = getinfo(3)

        if ClassName:match("Function") then
            rconsolewarn(("\nWhat: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nReturn: %s\nInfo: %s"):format(GetFullName(self), Method, Info.short_src or "NULL", Timestamp(), #Arguments > 0 and PrintTable(Arguments) or "None", Response and #Response > 0 and PrintTable(Response) or "None", PrintTable(Info)))
        else
            rconsolewarn(("\nWhat: %s\nMethod: %s\nFrom Script: %s\nTimestamp: %s\nArguments: %s\nInfo: %s"):format(GetFullName(self), Method, Info.short_src or "NULL", Timestamp(), #Arguments > 0 and PrintTable(Arguments) or "None", PrintTable(Info)))
        end
    end

    return unpack(Response)
end)

local OldNewIndex; OldNewIndex = hookmetamethod(game, "__newindex", function(self, ...)
    local Arguments = {...}
    if self:IsA("RemoteFunction") and Arguments[1] == "OnClientInvoke" and type(Arguments[2]) == "function" then
        local ClassName = self.ClassName
        local Method = Arguments[1]:gsub("On", "")
        local Function = Arguments[2]
        local Info = getinfo(Function)
        
        local function Honeypot(...)
            local InvokedArguments = {...}

            if RemoteSpyEnabled and Enabled[ClassName] then
                rconsolewarn(("\nWhat: %s\nMethod: %s\nTo Script: %s\nTimestamp: %s\nArguments: %s\nInfo: %s"):format(GetFullName(self), Method, Info.short_src or "NULL", Timestamp(), #InvokedArguments > 0 and PrintTable(InvokedArguments) or "None", PrintTable(Info)))
            end

            setthreadcontext(getthreadcontext(Function))

            task.spawn(Function, ...)
        end

        return OldNewIndex(self, Arguments[1], Honeypot)
    end
    
    return OldNewIndex(self, ...)
end)
