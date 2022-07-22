script.Name = "Threading.lua"

local Threading = {}
local Signaling = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/Signalling.lua"))()

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