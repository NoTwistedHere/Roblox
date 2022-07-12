if not PrintTable then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.luau"))()
end

local Threading = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/Threading.lua"))()
local Place = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
local Global, Local = "Function Dumps/", ("%s [%d]/"):format(tostring(Place and Place.Name or "Unknown Game"):gsub("[^%w%s]", ""), game.PlaceId)
local Key = game:GetService("HttpService"):GenerateGUID(false)

local function ConvertCodepoints(OriginalString)
    if OriginalString:match("[^%a%c%d%l%p%s%u%x]") or OriginalString:match("[\\/:*?\"<>|]") then
        local String = ""

        for i = 1, #OriginalString do
            local Byte = string.byte(OriginalString, i, i)
            local Char = string.char(Byte)

            if Byte <= 126 and Byte >= 33 and not Char:match("[\\/:*?\"<>|]") then
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
    
    --return ConvertCodepoints(String:gsub("\\", ""):gsub("//", ""):gsub("\"", ""):gsub("\\(d+)", ""))
    local NewString, C = String:gsub("[^%w%s%.%(%)=]", ""), -1

    repeat
        NewString, C = NewString:gsub("%.%.", ".")
    until C == 0

    if #NewString == 0 then
        return "INVALID NAME"
    end

    return NewString
end

local function GiveColour(Current, Max)
    return (Current < Max * 0.25 and "@@RED@@") or (Current < Max * 0.5 and "@@YELLOW@@") or (Current < Max * 0.75 and "@@CYAN@@") or "@@GREEN@@"
end

local function GetLoading()
    local SpinnerCount = 0

    return function()
        local Chars = { "|", "/", "—", "\\" }

        SpinnerCount += 1

        if SpinnerCount > #Chars then
            SpinnerCount = 1
        end

        return " "..Chars[SpinnerCount]
    end
end

local function ProgressBar(Header, Thread, Current, Max)
    local Size, PreviousCur, PreviousMax = 80, Current, Max
    local Loading = GetLoading()
    local LoadingChar = Loading()

    local function Update(Current, Max, Extra_After)
        local Progress, Percentage = math.floor(Size * Current / Max), math.floor(100 * Current / Max)

        PreviousCur = Current
        PreviousMax = Max
        rconsoleprint(GiveColour(Current, Max))
        rconsoleprint(("\13%s%s %s%s"):format(("#"):rep(Progress), ("."):rep(Size - Progress), Percentage.."%", Percentage == 100 and "!\n" or Extra_After or LoadingChar))
        rconsoleprint("@@WHITE@@")
    end

    rconsoleprint(Header.."\n")

    task.spawn(function()
        while PreviousCur < PreviousMax and coroutine.status(Thread) ~= "dead" do
            LoadingChar = Loading()
            Update(PreviousCur, PreviousMax, LoadingChar)
            task.wait(0.5)
        end
    end)

    return function(...)
        task.spawn(Update, ...)
    end
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

function Write(Function, Checked, OriginalFunction)
    local Checked, Upvalues, Constants, Protos, Info = Checked or {}, getupvalues(Function), getconstants(Function), getprotos(Function), getinfo(Function)
    local UserdataCount = 0

    table.insert(Checked, Function)

    for i, v in next, Protos do
        if Checked[v] then
            continue;
        end

        Protos[i] = Write(v, Checked, Function)
    end

    for i, v in next, Constants do
        if typeof(v) == "userdata" and not getrawmetatable(v) then
            local Proxy = newproxy(true)
            UserdataCount += OriginalFunction and 0 or 1
            setrawmetatable(Proxy, {
                [Key] = OriginalFunction or (Protos[UserdataCount] and Protos[UserdataCount]["Info"]["func"]) or "[[LOCAL FUNCTION DEFINITIONS MAY BE INCORRECT]]";
            })
            Constants[i] = Proxy
        end
    end

    if OriginalFunction then
        return {Constants = Constants, Info = Info}
    end

    return {Upvalues = Upvalues, Constants = Constants, LocalFunctions = Protos, Info = Info}
end

function CheckFile(Directory, FileName)
    local Name, New, Count = "", Directory..Stringify(FileName..".lua"), 0

    if isfile(New) then
        repeat
            Count += 1
            Name = FileName..(" (%d)"):format(Count)
            New = Directory..Stringify(Name..".lua")
        until not isfile(Directory..Stringify(Name..".lua"))
    end

    return New
end

local function Get(Table)
    local Final = ""
    
    for i, v in pairs(Table) do
        Final ..= v[2]
    end

    return Final
end

getgenv().DumpScript = function(Source) --// Outdated, cba to update tbh
    if not isfolder(Global..Local) then
        makefolder(Global..Local)
    elseif isfolder(Global..Local) then
        delfolder(Global..Local)
    end

    local Functions, GC, Thread = {}, getgc(), coroutine.running()
    local Final = CheckFile(Global..Local, Source)

    rconsoleclear()
    rconsolename("FunctionDumper")
    local CPB = ProgressBar("Collecting Functions", Thread, 0, 1)
    writefile(Final, "")

    for i, v in next, getgc() do
        local Info = type(v) == "function" and getinfo(v)

        if Info and Info.source == Source then
            table.insert(Functions, {v, Info})
            CPB(i, #GC)
        end
    end

    CPB(1, 1)
    local CPB = ProgressBar(("Dumping Functions [%d]"):format(#Functions), Thread, 0, 1)

    table.sort(Functions, function(a, b) return a[2].currentline < b[2].currentline end)

    for i, Data in next, Functions do
        appendfile(File, PrintTable(Write(Data[1]), {MetatableKey = Key}))

        CPB(i, #Functions)
    end

    rconsoleprint("\nFinished")
end

getgenv().DumpFunctions = function()
    if not isfolder(Global..Local) then
        makefolder(Global..Local)
    elseif isfolder(Global..Local) then
        delfolder(Global..Local)
        makefolder(Global..Local)
    end

    local Scripts, GC, TotalFunctions, Thread = {}, getgc(), 0, coroutine.running()
    local Directory = Global..Local

    rconsoleclear()
    rconsolename("FunctionDumper")
    local CPB = ProgressBar("Collecting Functions", Thread, 0, 1)

    for i, v in next, GC do
        local Info = type(v) == "function" and islclosure(v) and not is_synapse_function(v) and getinfo(v)

        if Info then
            if not Scripts[Info.source] then
                Scripts[Info.source] = {}
            end

            TotalFunctions += 1
            table.insert(Scripts[Info.source], {v, Info})
            CPB(i, #GC)
        end
    end

    CPB(1, 1)
    local CPB = ProgressBar(("Dumping Functions [%d]"):format(TotalFunctions), Thread, 0, 1)
    local Count = 0

    for Source, Dump in next, Scripts do
        local Final, FinalData, Thread = CheckFile(Directory, Source), {}, Threading.new()

        for ThreadNum = 0, math.ceil(#Dump / 200) - 1 do
            Thread:Add(function()
                for TIndex = 1, 201 do
                    local Data = Dump[TIndex + (200 * ThreadNum)]

                    if not Data then
                        break;
                    end

                    FinalData[Data[2].currentline] = {Data[2].currentline, PrintTable(Write(Data[1]), {MetatableKey = Key}).."\n"}
                    Count += 1
                    CPB(Count, TotalFunctions)
                end
            end)
        end

        Thread.Ended:Wait()
        table.sort(FinalData, function(a, b) return a[1] < b[1] end)
        writefile(Final, Get(FinalData))
    end

    rconsoleprint("Finished")
end