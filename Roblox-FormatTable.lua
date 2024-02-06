--[[
    Report any bugs, issues and detections to me if you don't mind (NoTwistedHere#6703)
]]

local Threading, Signalling = {}, {}
local HttpService = game:GetService("HttpService")
local ObjectTypes = {
	["nil"] = 1;
	["boolean"] = 1;
	["number"] = 1;
	["string"] = 2;
	["Instance"] = 3;
	["userdata"] = 4;
	["table"] = 4;
	["function"] = 5;
	["EnumItem"] = 6;
	["Enum"] = 7;
	["NumberSequenceKeypoint"] = 8;
	["NumberSequence"] = 9;
}

function Signalling:Fire(...)
	self.Fired = true

	for i, v in next, self.Callbacks do
		if type(v) == "function" then
			task.spawn(v, ...)
		elseif type(v) == "thread" then
			task.spawn(coroutine.resume, v, ...)
			table.remove(self.Callbacks, table.find(self.Callbacks, v))
		end
	end

	return Signalling
end

function Signalling:Wait(Arg, C)
	if Arg == "f" and self.Fired then
		return;
	end

	table.insert(self.Callbacks, coroutine.running())

	return coroutine.yield()
end

function Signalling:Connect(Callback)
	table.insert(self.Callbacks, Callback)

	return self
end

function Signalling:Disconnect(Callback)
	table.remove(self.Callbacks, table.find(self.Callbacks, Callback))
end

function Signalling.new()
	return setmetatable({ Callbacks = {} }, { __index = Signalling })
end

function Threading.new(Option, Manual)
	return setmetatable({
		Threads = 0;
		Active = 0;
		Option = Option;
		AutoFire = not Manual;
		Ended = Signalling.new();
		Available = Option == "Group" and Signalling.new();
	}, { __index = Threading })
end

function Threading:Add(Function)
	self.Threads += 1
	self.Active += 1

	coroutine.wrap(function() --// task.spawn takes the piss; it takes a lot longer to call task.* than spawn/delay/coroutine.*
		Function()
		self.Active -= 1

		if self.Available then
			self.Available:Fire()
			task.wait()

			if self.AutoFire and self.Active == 0 then
				self.Ended:Fire()
			end
		end

		if self.AutoFire and not self.Available and self.Active == 0 then
			self.Ended:Fire()
		end
	end)()

	return self
end

local function CountTable(Table)
	local Count = 0

	for _ in next, Table do
		Count += 1
	end

	return Count
end

local function Unrep(String)
	local Counts = {}

	for i, v in next, String:split("") do
		if not Counts[v] then
			Counts[v] = 0
		end

		Counts[v] += 1
	end

	for i, v in next, Counts do
		if v > 100 then
			local Subbed = false
			String = String:gsub(i, function(C) if not Subbed then Subbed = true return C end return "" end)
			continue
		end

		Counts[i] = nil
	end

	return String, CountTable(Counts) > 0
end

local function AntiRep(Options, String, ...) --// I'm too lazy
	local Unicode = String:gsub("[^%a%c%d%l%p%s%u%x]", "")

	if Options.NoAntiRep and #Unicode > 2e3 then
		return Unicode, ...
	end

	return String, ...
end

local function ConvertCodepoints(OriginalString, Modified, Extra)
	if OriginalString:match("[^%a%c%d%l%p%s%u%x]") then
		--local Utf8String = "utf8.char("

		--if not pcall(function() for i, v in utf8.codes(OriginalString) do Utf8String ..= ("%s%s"):format(i > 1 and ", " or "", v) end end) then
		local String = ""

		for i = 1, #OriginalString do
			local Byte = string.byte(OriginalString, i, i)
			if Byte <= 126 and Byte >= 33 then
				String ..= string.char(Byte)
				continue;
			end

			String ..= "\\" .. Byte
		end

		return "\"" .. String .. "\"", Extra and true or false
        --[[end
        
        if Extra then
            return Utf8String .. ")", true
        end

        return Utf8String ..")"]]
	end

	return "\""..OriginalString.."\"", Extra and Modified > 0 or nil
end

local function IsService(Object)
	local Success, Response = pcall(function()
		return game:GetService(Object.ClassName)
	end)

	return Success and Response
end

local function Tostring(Object, One)
	local Metatable = getmetatable(Object)

	if Metatable ~= nil and type(Metatable) == "table" and rawget(Metatable, "__tostring") then
		return tostring(Object), " [Metatable]"
	end


	return tostring(Object)
end

local function Stringify(String, Options, Extra, Checked, Root)
	local function Add(Message)
		if Checked and Root then
			Checked[String] = Message or Root
		end
	end

	if type(String) ~= "string" then
		return Tostring(String)
	elseif Checked and Checked[String] then
		return Checked[String]
	end

	if not Options.LargeStrings and #String > 5e3 then
		local Message = ("\"String is larger than 5e3 (Very Large) #%s\""):format(HttpService:GenerateGUID())
		Add(Message)

		return Message
	elseif #String > 2e2 then
		Add()
	end

	if Options.RawStrings then
		return "\"" .. String:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("%c", function(Char) return "\\"..string.byte(Char) end) .. "\""
	end

	return ConvertCodepoints(AntiRep(Options, String:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("%c", function(Char) return "\\"..string.byte(Char) end), Extra))
end

local function Convert(OriginalString)
	local String = ""
	local OriginalString = OriginalString:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("%c", function(Char) return "\\"..string.byte(Char) end)

	for i = 1, #OriginalString do
		local Byte = string.byte(OriginalString, i, i)
		if Byte <= 126 and Byte >= 33 then
			String ..= string.char(Byte)
			continue;
		end

		String ..= "\\" .. Byte
	end

	return String
end

local function GetName(Name)
	if tonumber(Name:sub(1, 1)) or Name:match("([0-9a-zA-Z]*)") ~= Name then
		if Name:match("\0") then
			return (":FindFirstChild(\"%s\")"):format(Convert(Name))
		end

		return ("[\"%s\"]"):format(Convert(Name))
	end

	return (".%s"):format(Name)
end

local function GetPath(Object, Sub)
	local Path = GetName(Object.Name):reverse()
	local Parent = Object.Parent

	if Object == game then
		Path = ("game"):reverse()
	elseif not Sub and IsService(Object) then
		Path = (":GetService(\"%s\")"):format(Object.ClassName):reverse()
		Path ..= GetPath(Parent, true)
	elseif Parent == game then
		Path = ("game"):reverse()
	elseif Parent and IsService(Parent) then
		Path ..= (":GetService(\"%s\")"):format(Parent.ClassName):reverse()
		Path ..= GetPath(Parent, true)
	elseif Parent then
		Path ..= GetPath(Parent, true)
	elseif Object ~= game then
		Path ..= ("nil"):reverse()
	end

	if Sub then
		return Path
	end

	return Path:reverse()
end

local ParseObject; ParseObject = function(Object, DetailedInfo, TypeOf, Checked, Root, Options, Indents)
	local Type = typeof(Object)
	local ObjectType = ObjectTypes[Type]

	local function _Parse()
		if ObjectType == 2 then
			local String, Modified = Stringify(Object, Options, true, Checked, Root)
			return String, Modified
		elseif ObjectType == 3 then
			--return Stringify(GetPath(Object), false, Checked, Root), " ClassName: "..Object.ClassName
			return GetPath(Object), " ClassName: "..Object.ClassName
		elseif ObjectType == 5 then
			local Type, Line, Name, NumParams, IsVariadic = debug.info(Object, "slna")
			return ("%s"):format(tostring(Object)), (" what: %s, name: %s (currentline: %s, numparams: %s, is_vararg: %s)"):format(Type, Name, Line, NumParams, IsVariadic and "true" or "false")
		elseif ObjectType == 6 then
			return tostring(Object.Name)
		elseif ObjectType == 7 then
			return ("Enum."):format(tostring(Object))
		elseif ObjectType == 8 then
			return ("NumberSequenceKeypoint.new(%d, %d)"):format(Object.Time, Object.Value)
		elseif ObjectType == 9 then
			local Keypoints = "{\n"

			for i, v in next, Object.Keypoints do
				Keypoints ..= ("    "):rep(Indents + 1) .. ParseObject(v, DetailedInfo, false, Checked, Root, Options) .. ("%s\n"):format(i == #Object.Keypoints and "" or ",")
			end

			return ("NumberSequence.new(%s)"):format(Keypoints .. ("    "):rep(Indents) .. "}")
		else
			return Tostring(Object)
		end
	end

	local Parsed = {_Parse()}

	return Parsed[1], (TypeOf and ("[%s]"):format(Type) or "") .. (DetailedInfo and unpack(Parsed, 2) or "")
end

local function CheckForClone(Checked, Table)
	local TC = CountTable(Table)

	if TC <= 3 then
		return false
	end

	for Value, Count in next, Checked do
		if type(Value) == "table" and Count <= 3 or Count ~= TC then
			continue;
		end

		local MatchedCount = 0

		for Index, Value2 in next, Table do
			if rawequal(rawget(Value, Index), Value2) then
				MatchedCount += 1
			end
		end

		if MatchedCount == Count then
			return i
		end
	end

	return false
end

local function IncrementalRepeat(ToRepeat, Repeat, Increment)
	local Final = ""

	for i = 1, Repeat do
		Final ..= ToRepeat .. (Increment and i or "") .. (i == Repeat and "" or ", ")
	end

	return Final
end

local function CreateComment(Comment, Options, Existing)
	if Options.NoComments or Options.NoIndentation then
		return ""
	end

	return (Existing and " // %s" or (Options.NoIndentation and " --[[ %s ]]" or " --// %s")):format(Comment)
end

local _FormatTable; _FormatTable = function(Table, Options, Indents, Checked, Root)
	local Success, Response = xpcall(function()
		if typeof(Table) ~= "table" and typeof(Table) ~= "userdata" then
			return;
		end

		Root = typeof(Root) == "string" and Root or "Table"
		Checked = type(Checked) == "table" and Checked or {}
		Indents = Options.NoIndentation and 1 or Indents or 1
		Checked[Table] = TableCount

		if Checked and Checked[Table] then
			return ParseObject(Table, false, false, Checked, Root or "Table", Options, Indents)
		end

		local Metatable, IsProxy = getmetatable(Table), typeof(Table) == "userdata"
		local TableCount, TabWidth, Count = IsProxy and 0 or CountTable(Table), Options.NoIndentation and " " or "    ", 1

		if TableCount >= 3e3 and not Options.LargeTables then
			return ("{ [Table is too large] }; --// Max: 5e3, Got: %d"):format(TableCount)
		elseif IsProxy then
			return ("{\n [Proxy]%s \n}"):format(Metatable ~= nil and " --// [Metatable]" or "")
		end

		local NewTable, Results, Thread = {}, {}, Threading.new()

		for i, v in next, Table do
			if Options.NumLength and i == "#" then
				continue;
			end

			table.insert(NewTable, {i, v})
		end

		if Options.NumLength and type(rawget(Table, "#")) == "number" and #Table ~= rawget(Table, "#") then
			for i = #Table + 1, rawget(Table, "#") do
				table.insert(NewTable, {i, nil})
			end
		end

		for ThreadNum = 0, math.ceil(TableCount / 200) - 1 do
			Thread:Add(function()
				for TIndex = 1, 200 do
					xpcall(function()
						local Data = NewTable[TIndex + (200 * ThreadNum)]

						if not Data then
							return;
						end

						local Index, Value = Data[1], Data[2]

						if Options.NumLength and Index == "#" then
							return;
						end

						local NewRoot = Root..("[%s]"):format(Stringify(Index, Options))
						local AlreadyLogged = type(Value) == "table" and (Checked[Value] or CheckForClone(Checked, Value))

						local function Format(...)
							local Arguments = {...}

							if type(Index) == "number" and Options.IgnoreNumberIndex then
								table.remove(Arguments, 2)

								return ("%s%s%s%s"):format(unpack(Arguments))
							end

							return ("%s[%s] = %s%s%s"):format(...)
						end

						if AlreadyLogged then
							Results[TIndex] = Format(string.rep(TabWidth, Indents), ParseObject(Index, false, false, Checked, NewRoot, Options, Indents), Tostring(Value), Count < TableCount and "," or "", Checked[Value] and "" or CreateComment("Duplicate of "..Tostring(AlreadyLogged), Options))
							Count += 1
							return;
						end

						local IsValid = (type(Value) == "table" or typeof(Value) == "userdata") and not Checked[Value]
						local ParsedValue, IsComment, ReParse = IsValid and _FormatTable(Value, Options, Indents + 1, Checked, NewRoot);
						local Parsed = {ParseObject((IsComment == "DBC" or not ReParse) and Value or ReParse, true, true, Checked, NewRoot, Options, Indents)}
						local Comment = ((IsComment == "DBC" or IsValid) and Parsed[1]..(Parsed[2] and " " or "") or "") .. (Parsed[2] and Parsed[2] or "")

						Results[TIndex] = Format(string.rep(TabWidth, Indents), ParseObject(Index, false, false, Checked, NewRoot, Options, Indents), ParsedValue or Parsed[1], Count < TableCount and "," or "", #Comment > 0 and CreateComment(Comment or "", Options, IsComment))
						Count += 1
					end, function(e)
						Results[TIndex] = ("FormatTable Error: [[\n%s\n%s]]"):format(e, debug.traceback())
					end)
				end
			end)
		end

		if TableCount > 0 then
			Thread.Ended:Wait("f")
		end

		if Options.GenerateScript then
			if Root == "Table" then
				local EndResult = ""

				for i, v in next, Results do
					EndResult ..= v:gsub("function: 0x([0-9a-f]+)", function(h) return ("FindFunction(\"%s\")"):format(h) end) .. (Options.OneLine and "" or "\n")
				end

				return {"local function FindFunction(k) for _, v in next, getgc() do if tostring(v) == \"function: 0x\" .. k then return v end end end\n", EndResult .. " "}
			else
				for i, v in next, Results do
					Results[i] = v:gsub("function: 0x([0-9a-f]+)", function(h) return ("FindFunction(\"%s\")"):format(h) end)
				end
			end
		end

		return (Metatable and "setmetatable(%s, %s)" or "%s"):format(TableCount == 0 and "{}" or ("{%s%s%s%s}"):format(Options.OneLine and "" or "\n", table.concat(Results, Options.OneLine and "" or "\n"), Options.OneLine and " " or "\n", string.rep(TabWidth, Indents - 1)), Metatable ~= nil and (type(Metatable) == "table" and _FormatTable(Metatable, Options, Indents, Checked, Root) or "{ [Unknown Metatable] }"))
	end, function(e)
		return ("FormatTable Error: [[\n%s\n%s]]"):format(e, debug.traceback())
	end)

	return Response
end


FormatTable = function(Table, Options)
	local Type = typeof(Table)
	assert((Type == "table" or Type == "userdata"), "FormatTable Error: Invalid Argument #1 (table or userdata expected)")
	assert((type(Options) == "table" or not Options), "FormatTable Error: Invalid Argument #2 (table expected)")

	Options = Options or {}

	local Success, Response = xpcall(_FormatTable, function(e)
		return ("FormatTable Error: [[\n%s\n%s]]"):format(e, debug.traceback())
	end, Table, Options, Options.Indents)

	return Response
end

FormatArguments = function(...)
	local Success, Response = xpcall(_FormatTable, function(e)
		return ("FormatTable Error: [[\n%s\n%s]]"):format(e, debug.traceback())
	end, {...}, {})

	return Response
end

_G.FormatTable = FormatTable
shared.FormatTable = FormatTable
_G.FormatArguments = FormatArguments
shared.FormatArguments = FormatArguments

return {
	FormatTable = FormatTable,
	FormatArguments = FormatArguments
}
