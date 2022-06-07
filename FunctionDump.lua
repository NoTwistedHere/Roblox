if not PrintTable then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.luau"))()
end

local Global, Local = "Garbage Logs/", game.PlaceId.."/"

local function ConvertCodepoints(OriginalString)
    if OriginalString:match("[^%a%c%d%l%p%s%u%x]") then
        local String = ""

        for i = 1, #OriginalString do
            local Byte = string.byte(OriginalString, i, i)

            if Byte <= 126 and Byte >= 33 then
                String ..= string.char(Byte)
            end
        end

        return String
    end

    return OriginalString
end

local function Stringify(String)
    if type(String) ~= "string" then
        return;
    end
    
    return ConvertCodepoints(String:gsub("\\", ""):gsub("//", ""):gsub("\"", ""):gsub("\\(d+)", ""))
end

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

local function CountTable(Table)
    local Count = 0

    for _ in next, Table do
        Count += 1
    end

    return Count
end

if not isfolder(Global) then
    makefolder(Global)
end

function Write(Function, Checked, NoWrite)
    local Checked, Upvalues, Constants, Protos, Info = Checked or {}, getupvalues(Function), getconstants(Function), getprotos(Function), getinfo(Function)

    table.insert(Checked, Function)

    for i, v in next, Protos do
        if Checked[v] then
            continue;
        end

        task.wait()

        Protos[i] = Write(v, Checked, true)
    end

    return {Upvalues = Upvalues, Constants = Constants, LocalFunctions = Protos, Info = Info}
end

getgenv().DumpScript = function(Source)
    local Functions = {}
    local Final = Global..Local..Stringify(Source)..".lua"

    if not isfolder(Global..Local) then
        makefolder(Global..Local)
    end

    writefile(Final, "")

    for i, v in next, getgc() do
        local Info = type(v) == "function" and getinfo(v)

        if Info and Info.source == Source then
            table.insert(Functions, {v, Info})
        end
    end

    table.sort(Functions, function(a, b) return a[2].currentline < b[2].currentline end)

    for _, Data in next, Functions do
        appendfile(File, PrintTable(Write(Data[1])))
    end

    rconsolewarn("Finished")
end

getgenv().DumpScripts = function()
    local Scripts, GC = {}, getgc()
    local Directory = Global..Local

    if not isfolder(Global..Local) then
        makefolder(Global..Local)
    end

    rconsoleclear()
    rconsolename("FunctionDumper")
    rconsolewarn("Collecting Functions\n")
    ProgressBar(0, #GC)

    for i, v in next, GC do
        local Info = type(v) == "function" and islclosure(v) and not is_synapse_function(v) and getinfo(v)

        if Info then
            if not Scripts[Info.source] then
                Scripts[Info.source] = {}
            end

            table.insert(Scripts[Info.source], {v, Info})
            ProgressBar(i, #GC)
        end
    end

    ProgressBar(1, 1)
    task.wait()
    rconsoleprint("\nDumping Functions\n")
    ProgressBar(0, #Scripts)

    local Count, ScriptsCount = 0, CountTable(Scripts)

    for Source, Dump in next, Scripts do
        local Final = Directory..Stringify(Source)..".lua"

        Count += 1
        table.sort(Dump, function(a, b) return a[2].currentline < b[2].currentline end)
        writefile(Final, "")
        task.wait()

        for _, Data in next, Dump do
            appendfile(Final, PrintTable(Write(Data[1])))
            task.wait()
        end

        ProgressBar(Count, ScriptsCount)
    end

    rconsoleprint("\nFinished")
end