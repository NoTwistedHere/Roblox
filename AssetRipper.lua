local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local function Request(Url, Yes)
    warn("Requesting:", Url)
    return syn.request({
        Method = "GET",
        Url = Url,
        Headers = {
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.67 Safari/537.36";
        }
    })
end

local function GetInfo(ID)
    if not ID or type(ID) ~= "number" then
        return;
    end

    local Success, Response = pcall(function()
        return MarketplaceService:GetProductInfo(ID)
    end)

    if not Success then
        return;
    end

    return Response
end

local function CreateName(Directory, FileName, FileType)
    if isfile(Directory .. FileName .. FileType) then
        local Name, Count = "", 0
    
        repeat
            Count += 1
            Name = FileName .. (" (%d)"):format(Count)
        until not isfile(Directory .. Name .. FileType)
        
        FileName = Name
    end

    return Directory .. FileName .. FileType
end

local DownloadTextures; DownloadTextures = function(Directory, Folder)
    if not isfolder(Folder) then
        makefolder(Folder)
    end
    
    local Downloaded = {}

    for i, v in next, Directory:GetDescendants() do
        if v:IsA("MeshPart") and v.TextureID then
            xpcall(function()
                local ID = tonumber(v.TextureID:reverse():match("%d+"):reverse())
                local Info = GetInfo(ID)
                
                if not Info or Downloaded[ID] then
                    return;
                end
                
                Downloaded[ID] = true

                local Image = Request(("https://assetdelivery.roblox.com/v1/asset/?id=%s"):format(ID)).Body
                    
                if Image:match("PNG") then
                    writefile(CreateName(Folder, Info.Name, ".png"), Image)
                    return;
                end

                warn(("%s-%d Failed"):format(Info.Name, ID))
            end, warn)
        end
    end
    
    warn("done")
end

local DownloadMeshes; DownloadMeshes = function(Directory, Folder)
    if not isfolder(Folder) then
        makefolder(Folder)
    end

    local Downloaded = {}

    for i, v in next, Directory:GetDescendants() do
        if v:IsA("MeshPart") and v.MeshId then
            xpcall(function()
                local ID = tonumber(v.MeshId:reverse():match("%d+"):reverse())
                local Info = GetInfo(ID)

                if not Info or Downloaded[ID] then
                    return;
                end

                Downloaded[ID] = true

                local Image = HttpService:JSONDecode(Request(("https://assetgame.roblox.com/asset-thumbnail-3d/json?assetId=%d&_=1653251104515"):format(ID), true).Body)
                local ImageData = HttpService:JSONDecode(Request(Image.Url).Body)
                local Final;
                    
                for i = 0, 7 do
                    Final = Request(("https://t%d.rbxcdn.com/%s"):format(i, ImageData.obj)).Body:gsub("%d+/(%d+)/%d+", function(Str) return Str end)
                        
                    if Final:match("vt") then
                        writefile(CreateName(Folder, Info.Name, ".obj"), Final)
                        return;
                    end
                end

                warn(("%s-%d Failed"):format(Info.Name, ID))
            end, warn)
        end
    end

    warn("done")
end

getgenv().DownloadTextures = DownloadTextures
getgenv().DownloadMeshes = DownloadMeshes

return {
    DownloadMeshes = DownloadMeshes;
    DownloadTextures = DownloadTextures;
}