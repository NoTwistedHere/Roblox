local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Hooks = {}

local function SortArguments(self, ...)
    return self, {...}
end

local Old; Old = hookmetamethod(UserInputService.WindowFocused, "__index", function(...)
    local self, Index = ...
    local Response = Old(self, Index)

    if (tostring(self):find("WindowFocused") or tostring(self):find("WindowFocusReleased")) and not table.find(Hooks, Response) then
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