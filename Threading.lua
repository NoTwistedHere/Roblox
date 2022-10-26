local Threading = {}
local Signalling = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/" .. Branch or "main" .. "/Signalling.lua"))()

function Threading.new(Option, Manual)
    return setmetatable({
        Threads = 0;
        Active = 0;
        Option = Option;
        AutoFire = not Manual;
        Ended = Signalling.new();
        Available = Option == "Group" and Signalling.new();
    }, { __index = Threading })
end

function Threading:Add(Function)
    self.Threads += 1
    self.Active += 1

    coroutine.wrap(function() --// task.spawn takes the piss; it takes a lot longer to call task.* than spawn/delay/coroutine.*
        Function()
        self.Active -= 1
        
        if self.Available then
            self.Available:Fire()
            task.wait()
            
            if self.AutoFire and self.Active == 0 then
                self.Ended:Fire()
            end
        end

        if self.AutoFire and not self.Available and self.Active == 0 then
            self.Ended:Fire()
        end
    end)()

    return self
end

return Threading
