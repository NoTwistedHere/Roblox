script.Name = "Signalling.lua"

local Signalling = {} --// Is that right?
local getthreadidentity, setthreadidentity = getthreadidentity or syn.get_thread_identity, setthreadidentity or syn.set_thread_identity

local function CallFunc(Identity, Function, ...)
    local Old = getthreadidentity()
    setthreadidentity(Identity)
    Function(...)
    setthreadidentity(Old)
end

function Signalling:Fire(...)
    self.Fired = true

    for i, v in next, self.Callbacks do
        if type(v) == "function" then
            CallFunc(getthreadidentity(v), task.spawn, v, ...)
        elseif type(v) == "thread" then
            CallFunc(getthreadidentity(v), task.spawn, coroutine.resume, v, ...)
        end
    end

    return Signalling
end

function Signalling:Wait(Arg)
    if self.Active == 0 or (Arg == "f" and self.Fired) then
        return;
    end

    table.insert(self.Callbacks, coroutine.running())

    return coroutine.yield()
end

function Signalling:Connect(Callback)
    if self.Active == 0 then
        return;
    end

    table.insert(self.Callbacks, Callback)
    
    return self
end

function Signalling:Disconnect(Callback)
    table.remove(self.Callbacks, table.find(self.Callbacks, Callback))
end

function Signalling.new()
    return setmetatable({ Callbacks = {} }, { __index = Signalling })
end

return Signalling