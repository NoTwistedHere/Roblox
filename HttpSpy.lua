--[[
    Report any bugs, issues and detections to me if you don't mind (NoTwistedHere#6703)
]]

local File = "HttpSpy/TestLog2.lua"

if not isfolder("HttpSpy/") then
    makefolder("HttpSpy/")
end
writefile(File, "START OF CAPTURE\n")

local function CloneFunction(Function)
    if islclosure(Function) then
        return Function --hookfunction(Function, Function)
    end

    return clonefunction(Function)
end

local function DeepClone(Tab)
    local NewTab = {}

    for i, v in next, Tab do
        if type(v) == "function" then
            NewTab[i] = CloneFunction(v)
        elseif type(v) == "table" then
            NewTab[i] = DeepClone(v)
        else
            NewTab[i] = v
        end
    end

    return NewTab
end

local GEnv = getgenv()

local Game = game

setfenv(0, setmetatable({}, { __index = DeepClone(getrawmetatable(getfenv()).__index) }))
local HttpService = Game:GetService("HttpService")

local function UrlEncode(Url)
    return HttpService:UrlEncode(Url)
end

local function Timestamp()
    local Time = DateTime.now()
    return ("%s/%s/%s %s:%s:%s:%s"):format(Time:FormatUniversalTime("D", "en-us"), Time:FormatUniversalTime("M", "en-us"), Time:FormatUniversalTime("YYYY", "en-us"), Time:FormatUniversalTime("H", "en-us"), Time:FormatUniversalTime("m", "en-us"), Time:FormatUniversalTime("s", "en-us"), Time:FormatUniversalTime("SSS", "en-us"))--// broken?
end

local function Log(Function, Method, ...)
    local Thread = coroutine.running()

    coroutine.wrap(function(...)
        local Success, Response = pcall(Function, ...)

        if not Success then
            return error(Response, 0)
        end

        appendfile(File, FormatTable({ Method = Method, Timestamp = Timestamp() Request = {...}, Response = Response }, { LargeStrings = true, RawStrings = true }) .. "\n")

        if coroutine.status(Thread) ~= "suspended" then
            repeat
                task.wait()
            until coroutine.status(Thread) == "suspended"
        end

        coroutine.resume(Thread, Response)
    end)(...)

    return coroutine.yield()
end

local OldRequest; OldRequest = hookfunction(GEnv.syn.request, function(...)
    local Request = ...

    if type(Request) ~= "table" or type(rawget(Request, "Url")) ~= "string" or not UrlEncode(rawget(Request, "Url")):match("http[s]*%3A%2F%2F(.*)") then
        return OldRequest(...)
    end

    return Log(OldRequest, Request)
end)

local OldGet;

local function GET(...)
    local Url = ...
    
    if type(Url) ~= "string" or not UrlEncode(Url):match("http[s]*%3A%2F%2F(.*)") then
        return OldGet(...)
    end

    return Log(OldGet, "HttpGet(Async)", ...)
end

OldGet = hookfunction(game.HttpGet, GET)
OldGet = hookfunction(game.HttpGetAsync, GET)

local OldPost;

local function POST(...)
    local Url = ...
        
    if type(Url) ~= "string" or not UrlEncode(Url):match("http[s]*%3A%2F%2F(.*)") then
        return OldPost(...)
    end
    
    return Log(OldPost, "HttpPost(Async)", ...)
end

OldPost = hookfunction(game.HttpPost, POST)
hookfunction(game.HttpPostAsync, POST)

local OldNC;

local function LogNC(Method, self, ...)
    local Thread = coroutine.running()

    coroutine.wrap(function(...)
        setnamecallmethod(Method)
        local Success, Response = pcall(OldNC, self, ...)

        if not Success then
            return error(Response, 0)
        end

        appendfile(File, FormatTable({ Method = Method, Timestamp = Timestamp(), Request = {...}, Response = Response }, { LargeStrings = true, RawStrings = true }) .. "\n")

        if coroutine.status(Thread) ~= "suspended" then
            repeat
                task.wait()
            until coroutine.status(Thread) == "suspended"
        end

        coroutine.resume(Thread, Response)
    end)(...)

    return coroutine.yield()
end

OldNC = hookmetamethod(game, "__namecall", function(...)
    local self = ...
    local Method = getnamecallmethod()
    local NoMethod = Method:sub(1, 7)

    if checkcaller() self and typeof(self) == "Instance" and self == Game and (Method == "HttpGet" or Method == "HttpGetAsync" or Method == "HttpPost" or Method == "HttpPostAsync") then
        LogNC(Method, ...)
    end

    return OldNC(...)
end)