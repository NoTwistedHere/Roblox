# <b>Loadstrings</b>

# AntiAFK
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/AntiAFK.lua"))()
```

# FunctionDump(er) (can be placed in autoexec)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/FunctionDump.lua"))()
```
## <b>Example Usage:</b>
```lua
DumpScript("=ReplicatedFirst.LocalScript")
DumpFunctions()
```
Writes to `Garbage Logs/ {Name} [{PlaceId}]/`

# PrintTable (can be placed in autoexec)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.luau"))()
```
## <b>Example Usage:</b>
```lua
PrintTable({a, "b", 1, game:GetService("Players"), pcall})

PrintTable({ workspace, 20, { pcall, 0X20 } }, {
    OneLine = true;
    IgnoreNumberIndex = true;
    NoIndentation = false;
    MetatableKey = nil;
    GenerateScript = false;
    NoAntiRep = false;
})

PrintArguments(a, "b", 1, game:GetService("Players"), pcall)

local Result = PrintTable({ 1, "b", game:GetService("Players").LocalPlayer}, {
    OneLine = false;
    IgnoreNumberIndex = false;
    NoIndentation = false;
    MetatableKey = Key;
    GenerateScript = true;
    NoAntiRep = false;
}) --// Will return a table with two arguments, [1] will contain FindFunction(), [2] will contain the generated code

local Proxy, Key = newproxy(true), game:GetService("HttpService"):GenerateGUID(false)
setrawmetatable(Proxy, {
    [Key] = "Hello there"
})
PrintTable({ workspace, 20, Proxy }, {
    OneLine = false;
    IgnoreNumberIndex = false;
    NoIndentation = false;
    MetatableKey = Key;
    GenerateScript = false;
    NoAntiRep = false;
})
```

# RemoteSpy (can be placed in autoexec)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/RemoteSpy.lua"))() --// spying on :InvokeClient can only be done if executed before the game loads
```
## <b>Example Usage:</b>
```lua
WriteToFile = true
RobloxConsole = false
GetCallerV2 = false --// Cannot be enabled mid-game
RemoteSpyEnabled = true
GenerateCode = true
Enabled = {
    BindableEvent = false;
    BindableFunction = false;
    RemoteEvent = true;
    RemoteFunction = true;
    OnClientInvoke = true;
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/RemoteSpy.lua"))()
```
Writes to `RemoteSpyLogs/Remote Spy Logs [{PlaceId-PlaceVersion}]` *(if enabled)*

# ScriptDumper (can be placed in autoexec)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/ScriptDumper.lua"))()
```
## <b>Example Usage:</b>
```lua
Threads = 10
IgnoreEmpty = true --// Ignore scripts with no bytecode
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/ScriptDumper.lua"))() --// Place the loadstring in your autoexec if you wish to decompile scripts before they have the chance to hide themselves
```
Writes to `Game Dumps/{PlaceId-Name}/Scripts for {Name} [{GameId-PlaceVersion}]`