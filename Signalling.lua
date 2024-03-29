local Signalling = {} --// Is that right?

function Signalling:Fire(...)
    self.Fired = true

    for i, v in next, self.Callbacks do
        if type(v) == "function" then
            task.spawn(v, ...)
        elseif type(v) == "thread" then
            task.spawn(coroutine.resume, v, ...)
            table.remove(self.Callbacks, table.find(self.Callbacks, v))
        end
    end

    return Signalling
end

function Signalling:Wait(Arg, C)
    if Arg == "f" and self.Fired then
        return;
    end

    table.insert(self.Callbacks, coroutine.running())

    return coroutine.yield()
end

function Signalling:Connect(Callback)
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