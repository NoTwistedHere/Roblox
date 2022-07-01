local Threading = {}
local Signaling = {} --// Is that right?

function Signaling:Fire(...)
    self.Fired = true

    for i, v in next, self.Callbacks do
        if type(v) == "function" then
            task.spawn(v, ...)
        elseif type(v) == "thread" then
            task.spawn(coroutine.resume, v, ...)
        end
    end

    return Signaling
end

function Signaling:Wait(Arg)
    if self.Active == 0 or (Arg == "f" and self.Fired) then
        return;
    end

    table.insert(self.Callbacks, coroutine.running())

    return coroutine.yield()
end

function Signaling:Connect(Callback)
    if self.Active == 0 then
        return;
    end

    table.insert(self.Callbacks, Callback)
    
    return self
end

function Signaling.new()
    return setmetatable({ Callbacks = {} }, { __index = Signaling })
end

function Threading.new()
    return setmetatable({
        Threads = 0;
        Active = 0;
        Ended = Signaling.new()
    }, { __index = Threading })
end

function Threading:Add(Function)
    self.Threads += 1
    self.Active += 1

    coroutine.wrap(function() --// task.spawn takes the piss; it takes a lot longer to call task.* than spawn/delay/coroutine.*
        Function()
        self.Active -= 1

        if self.Active == 0 then
            self.Ended:Fire()
        end
    end)()

    return self
end

return Threading