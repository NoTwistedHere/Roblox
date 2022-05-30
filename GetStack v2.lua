local isexecutorfunction = isexecutorfunction or is_synapse_function or isexecutorclosure or isourclosure or function(f) return getinfo(f, "s").source:find("@") and true or false end
local getthreadidentity = getthreadidentity or syn.get_thread_identity
local setthreadidentity = setthreadidentity or syn.set_thread_identity
local isvalidlevel = debug.isvalidlevel or debug.validlevel
local Stacks, Source = {}, getinfo(1).source

local RemoteEvent = Instance.new("RemoteEvent")

local function IsValidEnv(Env)
    local Metatable = getrawmetatable(Env)

    if not Metatable or not Metatable.__metatable == "This metatable is locked" then
        return false;
    end

    return true
end

local GetCaller; GetCaller = function()
    local Traceback, FirstInfo = {};
    for i = 1, 16380 do
        local Info = isvalidlevel(i) and getinfo(i)

        if not Info then
            local NewInfo = FirstInfo or getinfo(i - 1)
            local OldTraceback = Stacks[NewInfo.func]
            
            if GetCallerV2 and OldTraceback then
                for _, v in next, OldTraceback do
                    table.insert(Traceback, v)
                end

                Stacks[NewInfo.func] = nil
            end
            
            return NewInfo, Traceback
        end
        
        if Info.source ~= Source then
            table.insert(Traceback, ("%s:%d"):format(Info.short_src, Info.currentline))
        end

        if Info.what ~= "C" and not isexecutorfunction(Info.func) and not FirstInfo then
            FirstInfo = Info
        end
    end
end

local function FireServer(self, ...)
    local Info, Traceback = GetCaller()
    
    warn(PrintTable(Traceback))
end

if GetCallerV2 then
    local function HookFunc(Func)
        local Old; Old = hookfunction(Func, function(...)
            local Call, Arguments, Info, Traceback = SortArguments(...), GetCaller()
    
            if type(Call) ~= "function" then
                return Old(...)
            end
    
            Stacks[Call] = Traceback
            
            local Success, Response = SortArguments(pcall, Old, ...)
    
            if not Success then
                Stacks[Call] = nil
            end
    
            return unpack(Response)
        end)
    end

    local function HookFuncThread(Func)
        local Old; Old = hookfunction(Func, function(...)
            local Call, Arguments, Info, Traceback = SortArguments(...), GetCaller()
    
            if type(Call) ~= "function" and type(Call) ~= "thread" then
                return Old(...)
            end
    
            Stacks[Call] = Traceback
            
            local Success, Response = SortArguments(pcall, Old, ...)
    
            if not Success then
                Stacks[Call] = nil
            end
    
            return unpack(Response)
        end)
    end

    local OldS; OldS = hookfunction(spawn, function(...)
        local Call, Arguments, Info, Traceback = SortArguments(...), GetCaller()

        if type(Call) ~= "function" and type(Call) ~= "thread" and (typeof(Call) ~= "userdata" and not getrawmetatable(Call).__call) then
            return OldS(...)
        end

        Stacks[Call] = Traceback
        
        local Success, Response = SortArguments(pcall, OldS, ...)

        if not Success then
            Stacks[Call] = nil
        end

        return unpack(Response)
    end)

    HookFunc(getrenv().coroutine.create)
    HookFunc(getrenv().coroutine.wrap)
    HookFunc(getrenv().delay)
    HookFuncThread(getrenv().task.spawn)
    HookFuncThread(getrenv().task.defer)
    HookFuncThread(getrenv().task.delay)
end

local function b()
    task.spawn(task.spawn, FireServer, RemoteEvent, "asdgyh37asdgyi", true)
end

b(b)