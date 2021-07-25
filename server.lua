RegisterNetEvent("logmanager:upload")

local function addLogEntry(entry)
	if not entry.time then
		entry.time = os.time()
	end

	if not entry.resource then
		entry.resource = GetCurrentResourceName()
	end

	exports.ghmattimysql:execute(
		"INSERT INTO logmanager_log (time, resource, player_name, message) VALUES (FROM_UNIXTIME(@time), @resource, @player_name, @message)",
		{
			["time"] = entry.time,
			["resource"] = entry.resource,
			["player_name"] = entry.playerName,
			["message"] = entry.message
		},
		function(results)
			if results and entry.identifiers then
				for _, identifier in ipairs(entry.identifiers) do
					exports.ghmattimysql:execute(
						"INSERT INTO logmanager_log_identifier (log_id, identifier) VALUES (@log_id, @identifier)",
						{
							["log_id"] = results.insertId,
							["identifier"] = identifier
						})
				end
			end
		end)
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

	return true
end

local function formatLogEntry(entry)
	local date = os.date("%Y-%m-%dT%H:%M:%S", entry.time)
	return ("[%s][%s] %s: %s"):format(date, entry.resource, entry.player_name or "server", entry.message)
end

local function printLogEntry(entry, query)
	print(formatLogEntry(entry))
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

		addLogEntry(entry)
	end
end)

AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
	addLogEntry {
		resource = "core",
		identifiers = GetPlayerIdentifiers(source),
		playerName = playerName,
		message = "connecting"
	}
end)

AddEventHandler("playerDropped", function(reason)
	addLogEntry {
		resource = "core",
		playerName = GetPlayerName(source),
		message = ("dropped (%s)"):format(reason)
	}
end)

AddEventHandler("chatMessage", function(source, author, text)
	addLogEntry {
		resource = "chat",
		playerName = GetPlayerName(source),
		message = text
	}
end)

local function collateLogs(fn, query, ...)
	local args = ...

	exports.ghmattimysql:execute(
		[[SELECT
			logmanager_log.id as id,
			logmanager_log.time as time,
			logmanager_log.resource as resource,
			logmanager_log.player_name as player_name,
			logmanager_log.message as message,
			logmanager_log_identifier.identifier as identifie
		FROM
			logmanager_log,
			logmanager_log_identifier
		WHERE
			logmanager_log.id = logmanager_log_identifier.log_id AND
			(@after IS NULL OR logmanager_log.time > @after) AND
			(@before IS NULL OR logmanager_log.time < @before)
		ORDER BY
			time]],
		{
			["after"] = query.after,
			["before"] = query.before
		},
		function(results)
			if results then
				local collated = {}

				for _, result in ipairs(results) do
					if not collated[result.id] then
						collated[result.id] = {}

						collated[result.id].time = result.time / 1000
						collated[result.id].resource = result.resource
						collated[result.id].playerName = result.player_name
						collated[result.id].message = result.message

						collated[result.id].identifiers = {}
					end

					table.insert(collated[result.id].identifiers, result.identifier)
				end

				local entries = {}

				for _, entry in pairs(collated) do
					table.insert(entries, entry)
				end

				fn(entries, query, args)
			end
		end)
end

local function forEachLogEntry(entries, query, fn)
	for _, entry in ipairs(entries) do
		if matchesQuery(query, entry) then
			fn(entry)
		end
	end
end

local function printLogEntries(entries, query)
	forEachLogEntry(entries, query, printLogEntry)
end

local function writeLogEntries(entries, query, name)
	local text = ""

	for _, entry in ipairs(entries) do
		text = text .. formatLogEntry(entry) .. "\n"
	end

	SaveResourceFile(GetCurrentResourceName(), name, text, -1)
end

RegisterCommand("showlogs", function(source, args, raw)
	local query = {}

	for i = 1, #args do
		if args[i] == "-name" then
			query.playerName = args[i + 1]
		elseif args[i] == "-identifier" then
			query.identifier = args[i + 1]
		elseif args[i] == "-after" then
			query.after = args[i + 1]
		elseif args[i] == "-before" then
			query.before = args[i + 1]
		end
	end

	collateLogs(printLogEntries, query)
end, true)

RegisterCommand("writelogs", function(source, args, raw)
	collateLogs(writeLogEntries, {}, args[1] or "log.txt")
end, true)
