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

getgenv().DumpScript = function(Source)
    local Functions = {}
    local Final = Global..Local..Stringify(Source)..".lua"

    if not isfolder(Global..Local) then
        makefolder(Global..Local)
    end

    for i, v in next, getgc() do
        local Info = type(v) == "function" and getinfo(v)
        if Info and Info.short_src == Source then
            table.insert(Functions, {v, Info})
        end
    end

    table.sort(Functions, function(a, b) return a[2].currentline < b[2].currentline end)

    for i, v in next, Functions do
        appendfile(Final, PrintTable({Upvalues = getupvalues(v[1]), Constants = getconstants(v[1]), LocalFunctions = getprotos(v[1]), Info = v[2]}))
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
            local Function, Info = Data[1], Data[2]
            appendfile(Final, PrintTable({Upvalues = getupvalues(Function), Constants = getconstants(Function), LocalFunctions = getprotos(Function), Info = Info}))
        end
    end

    rconsolewarn("Finished")
end