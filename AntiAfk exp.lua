--[[
    // I got sick of that yellow fucking text in my explorer & tab bar

    TODO:
        Hook FindFirstChild, WaitForChild and aliases
        Hook ChildAdded, ServiceAdded, DescendantAdded and aliases
        Hook RBXScriptConnection
        Rewrite RBXScriptSignal hooking
            Use signalling & don't hook parsed func
]]

local BlacklistedMethods = {}
local isexecutorfunction = isexecutorfunction or is_synapse_function or isexecutorclosure or isourclosure or function(f) return getinfo(f, "s").source:find("@") and true or false end
local getthreadidentity, setthreadidentity = getthreadidentity or syn.get_thread_identity, setthreadidentity or syn.set_thread_identity
local NUB = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/NoUpvalueHook.lua"))()

local function TrueString(String)
    if type(String) ~= "string" then
        return false
    end

    return (string.split(String, "\0"))[1]
end

local function SortArguments(self, ...)
    return self, {...}
end

local function hookGetSerivce(...)
    local OldGetService; OldGetService = function(...)
        local self, Index = ...
        local Response = OldGetService(...)
    
        if type(Index) == "string" and TrueString(Index) == "VirtualInputManager" then
            error(("'%s' is not a valid Service name"):format(TrueString(Index)))
            return;
        end
    
        return Response
    end
end

local function HookFind(Function, Type)
    table.insert(BlacklistedMethods, getinfo(Function).name)

    local Old; Old = hookfunction(Function, function(...)
        local Returned = Old(...)

        if not checkcaller() and Returned.ClassName == "VirtualInputManager" then
            if Type == "Find" then
                return nil
            elseif Type == "Wait" then
                coroutine.yield()
            end
        end

        return Returned
    end)
end

--[[local Loaded = game.Loaded
local LoadedConnection = Loaded:Connect(function() end)
local OConnect = Loaded.Connect]]

local Connections = { "ChildAdded", "childAdded", "ServiceAdded", "DescendantAdded" }
local YieldCons = { "ChildAdded", "childAdded", "ServiceAdded", "DescendantAdded" }
local YieldConnections = { }
local UserInputServiceEvent = Instance.new("BindableEvent")

local function HookConnection(Connection)
    local function HookCallback(Callback)
        local Old; Old = hookfunction(Callback, NUB([[(function(Obj, ...)
            if typeof(Obj) == "Instance" and Obj.ClassName == "VirtualInputManager" then
                return;
            end

            return <<Old>>(Obj, ...)
        end)(...)]], { Old = Old }))
    end
    
    local OldConnect; OldConnect = hookfunction(Connection.Connect, function(...)
        local self, Callback = ...
    
        if checkcaller() or typeof(self) ~= "RBXScriptSignal" or (type(Callback) ~= "function" and typeof(Callback) ~= "userdata" and (not getrawmetatable(Callback) or not getrawmetatable(Callback).__call)) then
            return OldConnect(...)
        end
        
        if tostring(self):find("WindowFocused") or tostring(self):find("WindowFocusReleased") then
            return OldConnect(self, function() end)
        elseif Connections[tostring(self)] then
            HookCallback(Callback)
        end
    
        return OldConnect(...)
    end)

    for i, v in next, getconnections(Connection) do
        if v.Function and not isexecutorfunction(v.Function) then
            HookCallback(v.Function)
        end
    end

    return Connection.Connect
end

local function CreateYield(Signal)
    local BindableEvent = Instance.new("BindableEvent")
    local Old = getthreadidentity()
    setthreadidentity(2)

    Signal:Connect(function(Obj)
        if Obj.ClassName ~= "VirtualInputManager" then
            BindableEvent:Fire(Obj)
            return;
        end

        warn("no?", Obj)
    end)

    setthreadidentity(Old)

    local OldWait; OldWait = hookfunction(Signal.Wait, function(...)
        local self = ...

        warn(self, typeof(self))
    
        if typeof(self) ~= "RBXScriptSignal" then
            return OldWait(...)
        end

        if tostring(self):find("WindowFocused") or tostring(self):find("WindowFocusReleased") then
            return OldWait(UserInputServiceEvent.Event)
        elseif YieldCons[tostring(self)] then
            print(1)
            return OldWait(YieldCons[tostring(self)].Event)
        end

        return OldWait(...)
    end)

    return BindableEvent, OldWait
end

for i, v in next, Connections do
    if type(v) ~= "string" then
        continue;
    end

    YieldCons[tostring(game[v])], YieldConnections[tostring(game[v])] = CreateYield(game[v])
    Connections[tostring(game[v])] = HookConnection(game[v])
    YieldCons[i] = nil
    Connections[i] = nil
end

local OldIndex; OldIndex = hookfunction(getrawmetatable(game.ChildAdded).__index, function(...)
    local self, Index = ...

    if checkcaller() or typeof(self) ~= "RBXScriptSignal" or (Index ~= "Connect" and Index ~= "connect" and Index ~= "Wait" and Index ~= "wait") then
        return OldIndex(...)
    end

    if Index == "Wait" or Index == "wait" then
        return YieldConnections[tostring(self)] or OldIndex(...)
    end

    return Connections[tostring(self)] or OldIndex(...)
end)

local OldFindService = hookfunction(game.FindService, function(...)
    local self, Index = ...
    local Response = OldFindService(...)

    if type(Index) == "string" and TrueString(Index) == "VirtualInputManager" then
        return;
    end

    return Response
end)

local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", function(...)
    local self, Arguments = SortArguments(...)
    local Method = getnamecallmethod()

    if not checkcaller() and self == game and (Method:lower():match("service") or Method:lower():match("find") or Method == "WaitForChild") and TrueString(Arguments[1]) == "VirtualInputManager" then
        if table.find(BlacklistedMethods, Method) then
            if Method == "WaitForChild" then
                return OldNamecall(Instance.new("Folder"), "FuckOff")
            end

            return;
        end

        local Success, Error = pcall(function()
            setnamecallmethod(Method)
            game[Method](game, "VirtualFuckOff")
        end)

        if Error and Error:match("is not a valid member") then
            error(Error:replace("VirtualFuckOff", "VirtualInputManager"))
            return;
        end
    end

    return OldNamecall(...)
end)

local OldIndex; OldIndex = hookmetamethod(game, "__index", function(...)
    local self, Index = ...

    if not checkcaller() and self == game and TrueString(Index) == "VirtualInputManager" then
        return nil;
    end

    return OldIndex(...)
end)

hookGetSerivce(game.GetService)
hookGetSerivce(game.getService)
hookGetSerivce(game.service)
HookFind(game.FindService, "Find")
HookFind(game.FindFirstDescendant, "Find")
HookFind(game.FindFirstChild, "Find")
HookFind(game.findFirstChild, "Find")
HookFind(game.FindFirstChildWhichIsA, "Find")
HookFind(game.FindFirstChildOfClass, "Find")
HookFind(game.FindFirstAncestor, "Find")
HookFind(game.FindFirstAncestorOfClass, "Find")
HookFind(game.FindFirstAncestorWhichIsA, "Find")
HookFind(game.WaitForChild, "Wait")

--[[local VirtualInputManager, UserInputService = game:GetService("VirtualInputManager"), game:GetService("UserInputService")

for i, v in next, getconnections(UserInputService.WindowFocusReleased) do
    v:Disable()
end

for i, v in next, getconnections(UserInputService.WindowFocused) do
    v:Disable()
end

if not iswindowactive() and not getgenv().WindowFocused then
    firesignal(UserInputService.WindowFocused)
    getgenv().WindowFocused = true
end

while true do
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Unknown, false, game)

    task.wait(Random.new():NextNumber(15, 120))
end]]