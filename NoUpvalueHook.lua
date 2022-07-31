--[[
    Report any bugs, issues and detections to me if you don't mind (NoTwistedHere#6703)
    I'm tired of 'too many upvalues' so I decided to create a little module instead of doing it manually
]]

return function(src, Upvalues) --// See the example below
    local RUpvalues = {}
    src = src:gsub("<<(%w*)>>", function(Local)
        RUpvalues[Local] = Upvalues[Local] or function() return; end

        return Local
    end)

    local f, e = loadstring(src)

    if e then
        return error(e)
    end

    for i, v in next, RUpvalues do
        getfenv(f)[i] = v
    end

    return f
end

--[=[
    --// Example

    local NUB = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/NoUpvalueBypass.lua"))()
    local a, b, Old = true, false;

    local NewFunc = NUB([[
        if <<a>> or <<b>> then
            <<c>>(...)
        end

        return <<d>>(...)
    ]], {a = a, b = b, c = print, d = Old})

    Old = hookfunction(NoUpvalues, NewFunc)

    --// Or

    local NUB = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/NoUpvalueBypass.lua"))()
    local Skid = true
    local IsSmart = false
    local Print = print
    local Old = nil

    local NewFunc = NUB([[
        if <<Skid>> or <<IsSmart>> then
            <<Print>>(...)
        end

        return <<Old>>(...)
    ]], {
        Skid = Skid,
        IsSmart = IsSmart,
        Print = Print,
        Old = Old
    })

    Old = hookfunction(NoUpvalues, NewFunc)
]=]