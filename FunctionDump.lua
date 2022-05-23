if not PrintTable then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/NoTwistedHere/Roblox/main/PrintTable.lua"))()
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
    
    return ConvertCodepoints(String:gsub("\\", ""):gsub("\"", ""):gsub("\\(d+)", ""))
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
    local Scripts = {}
    local Directory = Global..Local

    if not isfolder(Global..Local) then
        makefolder(Global..Local)
    end

    for i, v in next, getgc() do
        local Info = type(v) == "function" and islclosure(v) and not is_synapse_function(v) and getinfo(v)

        if Info then
            Info.short_src = Stringify(Info.short_src)

            if not Scripts[Info.short_src] then
                Scripts[Info.short_src] = {}
            end

            table.insert(Scripts[Info.short_src], {v, Info})
        end
    end

    for Source, Dump in next, Scripts do
        local Final = Directory..Source..".lua"
        table.sort(Dump, function(a, b) return a[2].currentline < b[2].currentline end)

        writefile(Final, "")

        for _, Data in next, Dump do
            appendfile(Final, PrintTable(Write(Data[1])))
        end
    end

    rconsolewarn("Finished")
end