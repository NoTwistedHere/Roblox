script.Name = "ScriptDumper.lua"

local CoreGui, CorePackages, Players, RunService, RunService = game:GetService("CoreGui"), game:GetService("CorePackages"), game:GetService("Players"), game:GetService("RunService"), game:GetService("RunService")
local Result = "<roblox xmlns:xmime=\"http://www.w3.org/2005/05/xmlmime\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"http://www.roblox.com/roblox.xsd\" version=\"4\">"
local Decompiled, Scripts = 0, {}
local DecompiledScripts = {}
local IgnoreEmpty = IgnoreEmpty or true
local Threads = Threads or 10
local Instances = {
    "LocalScript";
    "ModuleScript";
    "RemoteEvent";
    "RemoteFunction";
}
local Services = {
    "StarterPlayerScripts";
    "StarterCharacterScripts";
}
local SpecialCharacters = {
    ["<"] = "&lt;";
    [">"] = "&gt;";
    ["&"] = "&amp;";
    ["\""] = "&quot;";
    ["'"] = "&apos;";
}

local Timeout = Timeout or 60 --// Decompiler timeout (in seconds)

if not RunService:IsRunning() then --// So you can dump scripts in games that do a bit of funny business (I'm mainly trying to patch the things I come up with)
    local function IsNetworkOwner(Object)
        if Object:IsA("BasePart") and isnetworkowner(Object) then
            return true
        elseif not Object.Parent then
            return false
        end

        return IsNetworkOwner(Object.Parent)
    end

    game.DescendantAdded:Connect(function(Obj)
        if Obj:IsA("LocalScript") then
            --if not Obj:IsDescendantOf(workspace) then --// when will I be able to spoof network replication :(
                Obj.Disabled = true --// Not my fault if a game dev is actually smart (or maybe it is)
            --end
        end
    end)

    repeat
        task.wait(0.5) --// There's no rush
    until RunService:IsRunning()
end

local LocalPlayer = Players.LocalPlayer
local InstancesCreated, InstancesTotal = 0, #game:GetDescendants()
local Place = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
local GameName = tostring(Place and Place.Name or "Unknown Game"):gsub("[^%w%s]", "")
local MainDirectory, SubDirectory, FileName, FileType, Final = "Game Dumps/", ("%d-%s/"):format(game.PlaceId, GameName), ("Scripts for %s [%s-%s]"):format(GameName, game.GameId, game.PlaceVersion), ".rbxlx", ""

if not isfolder(MainDirectory) then
    makefolder(MainDirectory)
end

if not isfolder(MainDirectory..SubDirectory) then
    makefolder(MainDirectory..SubDirectory)
end

if isfile(MainDirectory..SubDirectory..FileName..FileType) then
    local Name, Count = "", 0

    repeat
        Count += 1
        Name = FileName..(" (%d)"):format(Count)
    until not isfile(MainDirectory..SubDirectory..Name..FileType)
    
    FileName = Name
end

Final = MainDirectory..SubDirectory..FileName..FileType
writefile(Final, "")

local function GiveColour(Current, Max)
    return (Current < Max * 0.25 and "@@RED@@") or (Current < Max * 0.5 and "@@YELLOW@@") or (Current < Max * 0.75 and "@@CYAN@@") or "@@GREEN@@"
end

local function ProgressBar(Current, Max)
    local Size = 100
    local Progress, Percentage = math.floor(Size * Current / Max), math.floor(100 * Current / Max)
    rconsoleprint(GiveColour(Current, Max))
    rconsoleprint(("\13%s%s %s"):format(("#"):rep(Progress), ("."):rep(Size - Progress), Percentage.."%"))
    rconsoleprint("@@WHITE@@")
end

local function CheckObject(Object)
    for _, v in next, Instances do
        if Object:FindFirstChildWhichIsA(v, true) or Object:IsA(v) then
            return true
        end
    end

    return false
end

local function FindService(Service)
    local Success, Response = pcall(game.FindService, game, Service)

    return Success and Response
end

local function FindScripts(Table)
    for i, v in next, Table do
        if typeof(v) == "Instance" and (v:IsA("LocalScript") or v:IsA("ModuleScript")) or (not IgnoreEmpty or IgnoreEmpty and not getscripthash(v)) then
            return true
        end
    end

    return false
end

local function GetClassName(Object)
    local ClassName = Object.ClassName

    if (Object:IsA("LocalScript") or Object:IsA("ModuleScript")) and getscripthash(Object) == nil and IgnoreEmpty then
        if not FindScripts(Object:GetDescendants()) then
            return;
        end
    end

    if table.find(Instances, ClassName) or table.find(Services, ClassName) or FindService(ClassName) then
        return ClassName
    end

    return "Folder"
end

local function SteralizeString(String)
    return String:gsub("['\"<>&]", SpecialCharacters)
end

local function MakeInstance(Object)
    local ClassName = GetClassName(Object)

    if not ClassName then
        return ""
    end

    local IntResult = ("<Item class=\"%s\" referent=\"RBX%s\"><Properties><string name=\"Name\">%s</string>"):format(ClassName, Object:GetDebugId(0), SteralizeString(Object.Name))
    ProgressBar(InstancesCreated, InstancesTotal)
    
    if (ClassName == "LocalScript" or ClassName == "ModuleScript") then
        local Hash = getscripthash(Object)
        local Source = Hash and (DecompiledScripts[Hash] or "--// Failed to decompile") or "--// Script has no bytecode"

        if ClassName == "LocalScript" then
            IntResult ..= ("<bool name=\"Disabled\">%s</bool>"):format(tostring(Object.Disabled or not Hash))
        end
        
        IntResult ..= ([==[<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>]==]):format(("--// Hash: %s\n%s"):format(Hash or "nil", Source))
    end

    IntResult ..= "</Properties>"
    for _, v in next, Object:GetChildren() do
        if v ~= nil and v ~= game and CheckObject(v) then --// Give me stength
            IntResult ..= MakeInstance(v)
        end
    end

    IntResult ..= "</Item>"
    InstancesCreated += 1

    return IntResult
end

local function Save()
    Result ..= "</roblox>"
    
    rconsoleprint("\n\nWriting to file\n")
    ProgressBar(0, 1)
    writefile(Final, Result)
    ProgressBar(1, 1)
end

local function GetScripts(Table)
    for i, v in next, Table do
        if (not v:IsA("LocalScript") and not v:IsA("ModuleScript")) or (v:IsDescendantOf(CoreGui) or v:IsDescendantOf(CorePackages)) or table.find(Scripts, v) then
            continue;
        end

        ProgressBar(i, #Table)
        
        table.insert(Scripts, v)
    end

    ProgressBar(1, 1)

    rconsoleprint("\n")
end

local function Decompile(...)
    --if Timeout == 0 then
        return decompile(...)
    --end

    --[[local Thread = coroutine.running()
    local DecompThread = task.spawn(function(...)
        local Source = decompile(...)

        if coroutine.status(Thread) ~= "suspended" then
            repeat
                task.wait(0.2) --// There's no rush
            until coroutine.status(Thread) == "suspended"
        end
        
        return coroutine.resume(Thread, Source)
    end, ...)

    task.delay(Timeout, function()
        if coroutine.status(Thread) ~= "suspended" then
            return;
        end

        coroutine.close(DecompThread)

        return coroutine.resume(Thread)
    end)

    return coroutine.yield()]]
end

local function FindNextScript()
    for i, v in next, Scripts do
        Scripts[i] = nil

        return v
    end
end

local function DecompileScripts()
    local Thread = coroutine.running()
    local RunningThreads = 0

    rconsoleprint(("\nDecompiling Scripts [%s]\n"):format(#Scripts))
    ProgressBar(0, #Scripts)

    for i = 1, Threads do
        task.spawn(function()
            RunningThreads += 1

            while true do
                local Script = FindNextScript()

                if not Script then
                    break;
                end

                local Hash = getscripthash(Script)

                if Hash and not DecompiledScripts[Hash] then    
                    DecompiledScripts[Hash] = "--// Decompiling..."
                    DecompiledScripts[Hash] = Decompile(Script) or "--// Failed to decompile"
                end

                Decompiled += 1
                ProgressBar(Decompiled, #Scripts)
                task.wait()
            end

            RunningThreads -= 1

            if RunningThreads == 0 then
                ProgressBar(1, 1)
                coroutine.resume(Thread, true)
            end
        end)
    end

    return coroutine.yield()
end

RunService:Set3dRenderingEnabled(false)
rconsoleclear()
rconsolename("Script Dumper")
rconsoleprint("Collecting Scripts\n")
GetScripts(getscripts())
GetScripts(getnilinstances())
GetScripts(game:GetDescendants())
DecompileScripts()
rconsoleprint("\n\nCreating XML\n")
ProgressBar(0, 1)

for i, v in next, game:GetChildren() do
    if v == CoreGui or v == CorePackages then
        continue;
    end

    Result ..= MakeInstance(v)
end

Result..= MakeInstance({
    ClassName = "Folder";
    Name = "Nil Instances";
    Parent = game;
    GetChildren = function()
        return getnilinstances()
    end;
    GetDebugId = function()
        return Instance.new("Folder"):GetDebugId(0)
    end;
    FindFirstChildWhichIsA = function()
        return true
    end;
    IsA = function(_, IsA)
        return IsA == "Folder"
    end
})

ProgressBar(1, 1)
Save()
rconsoleprint("\n\nFinished")
RunService:Set3dRenderingEnabled(true)