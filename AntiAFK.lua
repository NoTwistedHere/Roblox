local VirtualInputManager = Instance.new("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Hooks = {}

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

local OldFindService = hookfunction(game.FindService, function(...)
    local self, Index = ...
    local Response = OldFindService(...)

    if type(Index) == "string" and TrueString(Index) == "VirtualInputManager" then
        return;
    end

    return Response
end)

hookGetSerivce(game.GetService)
hookGetSerivce(game.getService)
hookGetSerivce(game.service)

local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", function(...)
    local self, Arguments = SortArguments(...)
    local Method = getnamecallmethod()

    if typeof(self) == "Instance" and self == game and Method:lower():match("service") and TrueString(Arguments[1]) == "VirtualInputManager" then
        if Method == "FindService" then
            return;
        end

        local Success, Error = pcall(function()
            setnamecallmethod(Method)
            game[Method](game, "VirtualFuckOff")
        end)

        if not Error:match("is not a valid member") then
            error(Error:replace("VirtualFuckOff", "VirtualInputManager"))
            return;
        end
    end

    return OldNamecall(...)
end)

local OldWindow; OldWindow = hookmetamethod(UserInputService.WindowFocused, "__index", function(...)
    local self, Index = ...
    local Response = OldWindow(...)

    if type(Response) ~= "function" and (tostring(self):find("WindowFocused") or tostring(self):find("WindowFocusReleased")) and not table.find(Hooks, Response) then
        table.insert(Hooks, Response)

        if Index:lower() == "wait" then
            local Old2; Old2 = hookfunction(Response, function(...)
                local self1 = ...

                if self1 == self then
                    self1 = Instance.new("BindableEvent").Event
                end

                return Old2(self1)
            end)
        elseif Index:lower() == "connect" then
            local Old2; Old2 = hookfunction(Response, function(...)
                local self1, Function = ...

                if self1 == self then
                    Function = function() return; end
                end

                return Old2(self1, Function)
            end)
        end
    end

    return Response
end)

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
end
