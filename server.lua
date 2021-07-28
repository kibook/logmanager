RegisterNetEvent("logmanager:upload")
RegisterNetEvent("baseevents:onPlayerDied")
RegisterNetEvent("baseevents:onPlayerKilled")
RegisterNetEvent("baseevents:onPlayerWasted")
RegisterNetEvent("baseevents:enteringVehicle")
RegisterNetEvent("baseevents:enteringAborted")
RegisterNetEvent("baseevents:enteredVehicle")
RegisterNetEvent("baseevents:leftVehicle")

local function addLogEntry(entry)
	if not entry.time then
		entry.time = os.time()
	end

	if not entry.resource then
		entry.resource = GetCurrentResourceName()
	end

	exports.ghmattimysql:execute(
		[[
		INSERT INTO
			logmanager_log (time, resource, endpoint, player_name, message)
		VALUES
			(FROM_UNIXTIME(@time), @resource, @endpoint, @player_name, @message)
		]],
		{
			["time"] = entry.time,
			["resource"] = entry.resource,
			["endpoint"] = entry.endpoint,
			["player_name"] = entry.playerName,
			["message"] = entry.message
		},
		function(results)
			if results and entry.identifiers then
				local statements = {}

				for _, identifier in ipairs(entry.identifiers) do
					table.insert(statements, {
						query = "INSERT INTO logmanager_log_identifier (log_id, identifier) VALUES (@log_id, @identifier)",
						values = {
							["log_id"] = results.insertId,
							["identifier"] = identifier
						}
					})
				end

				exports.ghmattimysql:transaction(statements)
			end
		end)
end

local function addLogEntryForPlayer(source, entry)
	if not entry.identifiers then
		entry.identifiers = GetPlayerIdentifiers(source)
	end

	if not entry.endpoint then
		entry.endpoint = GetPlayerEndpoint(source)
	end

	if not entry.playerName then
		entry.playerName = GetPlayerName(source)
	end

	addLogEntry(entry)
end

local function log(resource, message)
	addLogEntry{resource = resource, message = message}
end

local function matchesQuery(query, entry)
	if query.resource and (not entry.resource or string.lower(query.resource) ~= string.lower(entry.resource)) then
		return false
	end

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

local function formatTime(time)
	return os.date(Config.timeFormat, time)
end

local function formatLogEntry(entry)
	return ("[%s][%s] %s: %s"):format(formatTime(entry.time), entry.resource, entry.playerName or "server", entry.message)
end

local function printLogEntry(entry)
	print(formatLogEntry(entry))
end

exports("log", log)

AddEventHandler("logmanager:upload", function(log, uploadTime)
	local identifiers = GetPlayerIdentifiers(source)
	local endpoint = GetPlayerEndpoint(source)
	local playerName = GetPlayerName(source)
	local currentTime = os.time()

	for _, entry in ipairs(log) do
		entry.identifiers = identifiers
		entry.endpoint = endpoint
		entry.playerName = playerName
		entry.time = math.floor(currentTime - ((uploadTime - entry.time) / 1000))

		addLogEntry(entry)
	end
end)

if Config.events.baseevents then
	AddEventHandler("baseevents:onPlayerDied", function(killerType, deathCoords)
		addLogEntryForPlayer(source, {
			resource = "baseevents",
			message = ("Died at (%.2f, %.2f, %.2f)"):format(deathCoords[1], deathCoords[2], deathCoords[3])
		})
	end)

	AddEventHandler("baseevents:onPlayerKilled", function(killerId, deathData)
		if killerId == -1 then
			addLogEntryForPlayer(source, {
				resource = "baseevents",
				message = ("Was killed at (%.2f, %.2f, %.2f)"):format(deathData.killerpos[1], deathData.killerpos[2], deathData.killerpos[3])
			})
		else
			addLogEntryForPlayer(killerId, {
				resource = "baseevents",
				message = ("Killed %s at (%.2f, %.2f, %.2f)"):format(GetPlayerName(source), deathData.killerpos[1], deathData.killerpos[2], deathData.killerpos[3])
			})
		end
	end)

	AddEventHandler("baseevents:onPlayerWasted", function(deathCoords)
		addLogEntryForPlayer(source, {
			resource = "baseevents",
			message = ("Wasted at (%.2f, %.2f, %.2f)"):format(deathCoords[1], deathCoords[2], deathCoords[3])
		})
	end)

	AddEventHandler("baseevents:enteringVehicle", function(targetVehicle, vehicleSeat, vehicleDisplayName)
		addLogEntryForPlayer(source, {
			resource = "baseevents",
			message = ("Entering seat %d of %s %d"):format(vehicleSeat, vehicleDisplayName, targetVehicle)
		})
	end)

	AddEventHandler("baseevents:enteringAborted", function()
		addLogEntryForPlayer(source, {
			resource = "baseevents",
			message = "Aborted entering vehicle"
		})
	end)

	AddEventHandler("baseevents:enteredVehicle", function(currentVehicle, currentSeat, vehicleDisplayName)
		addLogEntryForPlayer(source, {
			resource = "baseevents",
			message = ("Entered seat %d of %s %d"):format(currentSeat, vehicleDisplayName, currentVehicle)
		})
	end)

	AddEventHandler("baseevents:leftVehicle", function(currentVehicle, currentSeat, vehicleDisplayName)
		addLogEntryForPlayer(source, {
			resource = "baseevents",
			message = ("Exited seat %d of %s %d"):format(currentSeat, vehicleDisplayName, currentVehicle)
		})
	end)
end

if Config.events.chat then
	AddEventHandler("chatMessage", function(source, author, text)
		addLogEntryForPlayer(source, {
			resource = "chat",
			message = text
		})
	end)
end

if Config.events.core then
	AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
		addLogEntryForPlayer(source, {
			resource = "core",
			playerName = playerName,
			message = "connecting"
		})
	end)

	AddEventHandler("playerDropped", function(reason)
		addLogEntryForPlayer(source, {
			resource = "core",
			message = ("dropped (%s)"):format(reason)
		})
	end)
end

local function collateLogs(fn, query, ...)
	local args = ...

	exports.ghmattimysql:execute(
		[[
		SELECT
			logmanager_log.id as id,
			logmanager_log.time as time,
			logmanager_log.resource as resource,
			logmanager_log.endpoint as endpoint,
			logmanager_log.player_name as player_name,
			logmanager_log.message as message,
			logmanager_log_identifier.identifier as identifier
		FROM
			logmanager_log LEFT OUTER JOIN logmanager_log_identifier ON logmanager_log.id = logmanager_log_identifier.log_id
		WHERE
			(@after IS NULL OR logmanager_log.time > @after) AND
			(@before IS NULL OR logmanager_log.time < @before)
		]],
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
						collated[result.id].endpoint = result.endpoint
						collated[result.id].playerName = result.player_name
						collated[result.id].message = result.message

						collated[result.id].identifiers = {}
					end

					table.insert(collated[result.id].identifiers, result.identifier)
				end

				local entries = {}

				for _, entry in pairs(collated) do
					if matchesQuery(query, entry) then
						table.insert(entries, entry)
					end
				end

				table.sort(entries, function(a, b)
					return a.time < b.time
				end)

				fn(entries, args)
			end
		end)
end

local function printLogEntries(entries)
	local numEntries = #entries

	if numEntries > 0 then
		print(("Showing %d log entries from %s to %s"):format(numEntries, formatTime(entries[1].time), formatTime(entries[#entries].time)))

		for _, entry in ipairs(entries) do
			printLogEntry(entry)
		end
	else
		print("No log entries found")
	end
end

local function writeLogEntries(entries, name)
	local text = ""

	for _, entry in ipairs(entries) do
		text = text .. formatLogEntry(entry) .. "\n"
	end

	SaveResourceFile(GetCurrentResourceName(), name, text, -1)
end

local function buildQuery(args)
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
		elseif args[i] == "-endpoint" then
			query.endpoint = args[i + 1]
		elseif args[i] == "-resource" then
			query.resource = args[i + 1]
		elseif args[i] == "-all" then
			query.all = true
		end
	end

	return query
end

local function getCurrentDay()
	local now = os.date("*t", os.time())

	return os.time {
		year = now.year,
		month = now.month,
		day = now.day,
		hour = 0,
		min = 0,
		sec = 0
	}
end

RegisterCommand("showlogs", function(source, args, raw)
	local query = buildQuery(args)

	if not (query.all or query.after or query.before) then
		query.after = formatTime(getCurrentDay())
	end

	collateLogs(printLogEntries, query)
end, true)

RegisterCommand("writelogs", function(source, args, raw)
	collateLogs(writeLogEntries, {}, args[1] or "log.txt")
end, true)

RegisterCommand("clearlogs", function(source, args, raw)
	local query = buildQuery(args)

	exports.ghmattimysql:execute(
		[[
		DELETE FROM
			logmanager_log
		WHERE
			(@after IS NULL OR time > @after) AND
			(@before is NULL or time < @before)
		]],
		{
			["after"] = query.after,
			["before"] = query.before
		},
		function(results)
			print(("%d log entries deleted"):format(results.affectedRows))
		end)
end, true)

exports.ghmattimysql:transaction {
	[[
	CREATE TABLE IF NOT EXISTS logmanager_log (
		id INT NOT NULL AUTO_INCREMENT,
		time DATETIME NOT NULL,
		resource VARCHAR(255),
		endpoint VARCHAR(255),
		player_name VARCHAR(255),
		message VARCHAR(255),
		PRIMARY KEY (id)
	)
	]],
	[[
	CREATE TABLE IF NOT EXISTS logmanager_log_identifier (
		id INT NOT NULL AUTO_INCREMENT,
		log_id INT NOT NULL,
		identifier VARCHAR(255) NOT NULL,
		PRIMARY KEY (id),
		FOREIGN KEY (log_id) REFERENCES logmanager_log (id) ON DELETE CASCADE
	)
	]]
}
