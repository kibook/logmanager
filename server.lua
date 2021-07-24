local serverLog = json.decode(LoadResourceFile(GetCurrentResourceName(), "log.json")) or {}

RegisterNetEvent("logmanager:upload")

local function log(resource, message)
	local entry = {}

	entry.time = os.time()
	entry.resource = resource or GetCurrentResourceName()
	entry.message = message

	table.insert(serverLog, entry)
end

local function matchesQuery(query, entry)
	if query.playerName and string.lower(query.playerName) ~= string.lower(entry.playerName) then
		return false
	end

	if query.identifier then
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

	return true
end

local function printLogEntry(entry, query)
	local date = os.date("%Y-%m-%dT%H:%M:%S", entry.time)

	print(("[%s][%s] %s: %s"):format(date, entry.resource, entry.playerName or "server", entry.message))
end

local function saveLog()
	table.sort(serverLog, function(a, b)
		return a.time < b.time
	end)

	SaveResourceFile(GetCurrentResourceName(), "log.json", json.encode(serverLog), -1)
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

RegisterCommand("showlogs", function(source, args, raw)
	local query = {}

	for i = 1, #args do
		if args[i] == "-name" then
			query.playerName = args[i + 1]
		elseif args[i] == "-identifier" then
			query.identifier = args[i + 1]
		end
	end

	for _, entry in ipairs(serverLog) do
		if matchesQuery(query, entry) then
			printLogEntry(entry, query)
		end
	end
end, true)

Citizen.CreateThread(function()
	while true do
		saveLog()
		Citizen.Wait(5000)
	end
end)
