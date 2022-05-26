local function RConsoleColour(Colour)
    rconsoleprint(("@@%s@@"):format(Colour))
end

local function RConsoleError(Error, Message)
    RConsoleColour("WHITE")
    rconsoleprint("[")
    RConsoleColour("RED")
    rconsoleprint("*")
    RConsoleColour("WHITE")
    rconsoleprint("]: ")
    RConsoleColour("RED")
    rconsoleprint(Error)
    RConsoleColour("WHITE")
    
    if Message then
        rconsoleprint(" "..Message)
    end
    rconsoleprint("\n")
end

RConsoleError("You are using an outdated script.", "Please use the loadstrings to continue using the latest versions, found here: https://github.com/NoTwistedHere/Roblox/blob/main/Loadstrings.md")

task.wait()
while true do end