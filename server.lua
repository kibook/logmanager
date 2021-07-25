local serverLog = json.decode(LoadResourceFile(GetCurrentResourceName(), "log.json")) or {}

RegisterNetEvent("logmanager:upload")

local function addLogEntry(entry)
	if not entry.time then
		entry.time = os.time()
	end

	if not entry.resource then
		entry.resource = GetCurrentResourceName()
	end

	table.insert(serverLog, entry)
end

local function log(resource, message)
	addLogEntry{resource = resource, message = message}
end

local function matchesQuery(query, entry)
	if query.playerName and (not entry.playerName or string.lower(query.playerName) ~= string.lower(entry.playerName)) then
		return false
	end

	if query.identifier then
		if not entry.identifiers then
			return false
		end

		local found = false

		for _, identifier in ipairs(entry.identifiers) do
			if identifier == query.identifier then
				found = true
				break
			end
		end

		if not found then
			return false
		end
	end

	if query.after and entry.time < query.after then
		return false
	end

	if query.before and entry.time > query.before then
		return false
	end

	return true
end

local function formatLogEntry(entry)
	local date = os.date("%Y-%m-%dT%H:%M:%S", entry.time)
	return ("[%s][%s] %s: %s"):format(date, entry.resource, entry.playerName or "server", entry.message)
end

local function printLogEntry(entry, query)
	print(formatLogEntry(entry))
end

local function sortLog()
	table.sort(serverLog, function(a, b)
		return a.time < b.time
	end)
end

local function saveLog()
	sortLog()
	SaveResourceFile(GetCurrentResourceName(), "log.json", json.encode(serverLog), -1)
end

local function stringToTime(str)
	local year, month, day, hour, min, sec = str:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")

	return os.time {
		year = year or 1970,
		month = month or 1,
		day = day or 1,
		hour = hour or 0,
		min = min or 0,
		sec = sec or 0
	}
end

exports("log", log)

AddEventHandler("logmanager:upload", function(log, uploadTime)
	local identifiers = GetPlayerIdentifiers(source)
	local playerName = GetPlayerName(source)
	local currentTime = os.time()

	for _, entry in ipairs(log) do
		entry.identifiers = identifiers
		entry.playerName = playerName

		entry.time = math.floor(currentTime - ((uploadTime - entry.time) / 1000))

		table.insert(serverLog, entry)
	end
end)

AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
	addLogEntry{
		resource = "core",
		identifiers = GetPlayerIdentifiers(source),
		playerName = playerName,
		message = "connecting"
	}
end)

AddEventHandler("playerDropped", function(reason)
	addLogEntry {
		resource = "core",
		playerName = playerName,
		message = ("dropped (%s)"):format(reason)
	}
end)

AddEventHandler("chatMessage", function(source, author, text)
	addLogEntry{resource = "chat", playerName = GetPlayerName(source), message = text}
end)

RegisterCommand("showlogs", function(source, args, raw)
	local query = {}

	for i = 1, #args do
		if args[i] == "-name" then
			query.playerName = args[i + 1]
		elseif args[i] == "-identifier" then
			query.identifier = args[i + 1]
		elseif args[i] == "-after" then
			query.after = stringToTime(args[i + 1])
		elseif args[i] == "-before" then
			query.before = stringToTime(args[i + 1])
		end
	end

	for _, entry in ipairs(serverLog) do
		if matchesQuery(query, entry) then
			printLogEntry(entry, query)
		end
	end
end, true)

RegisterCommand("writelogs", function(source, args, raw)
	sortLog()

	local text = ""

	for _, entry in ipairs(serverLog) do
		text = text .. formatLogEntry(entry) .. "\n"
	end

	SaveResourceFile(GetCurrentResourceName(), args[1] or "log.txt", text, -1)
end, true)

Citizen.CreateThread(function()
	while true do
		saveLog()
		Citizen.Wait(5000)
	end
end)
