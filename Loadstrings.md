# <b>Loadstrings</b>

# AntiAFK
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/AntiAFK.lua"))()
```

# FunctionDump(er)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/FunctionDump.lua"))() --// Place the loadstring in your autoexec if you wish
```
## <b>Example Usage:</b>
```lua
DumpScript("=ReplicatedFirst.LocalScript")
DumpFunctions()
```
Writes to `Garbage Logs/ {Name} [{PlaceId}]/`

# PrintTable
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.luau"))() --// Place the loadstring in your autoexec if you wish
```
## <b>Example Usage:</b>
```lua
PrintTable({a, "b", 1, game:GetService("Players"), pcall})
```

# RemoteSpy
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/RemoteSpy.lua"))() --// Place the loadstring in your autoexec if you wish to spy :InvokeClient()
```
## <b>Example Usage:</b>
```lua
WriteToFile = true
RobloxConsole = false
GetCallerV2 = false
RemoteSpyEnabled = true
Enabled = {
    BindableEvent = false;
    BindableFunction = false;
    RemoteEvent = true;
    RemoteFunction = true;
    OnClientInvoke = true;
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/RemoteSpy.lua"))() --// Place the loadstring in your autoexec if you wish to spy :InvokeClient()
```
Writes to `RemoteSpyLogs/Remote Spy Logs [{PlaceId-PlaceVersion}]` *(if enabled)*

# ScriptDumper
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/ScriptDumper.lua"))()
```
## <b>Example Usage:</b>
```lua
Threads = 10
IgnoreEmpty = true --// Ignore scripts with no bytecode
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/ScriptDumper.lua"))() --// Place the loadstring in your autoexec if you wish to decompile scripts before they have the chance to hide themselves
```
Writes to `Game Dumps/{PlaceId}/Scripts for {Name} [{GameId-PlaceVersion}]`