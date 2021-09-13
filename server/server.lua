local webhookQueue = Config.webhook and WebhookQueue:new(Config.webhook)

RegisterNetEvent("logmanager:upload")
RegisterNetEvent("baseevents:onPlayerDied")
RegisterNetEvent("baseevents:onPlayerKilled")
RegisterNetEvent("baseevents:onPlayerWasted")
RegisterNetEvent("baseevents:enteringVehicle")
RegisterNetEvent("baseevents:enteringAborted")
RegisterNetEvent("baseevents:enteredVehicle")
RegisterNetEvent("baseevents:leftVehicle")

local function formatTime(time)
	return os.date(Config.timeFormat, time)
end

local function formatLogEntryMessage(entry)
	if entry.coords then
		return ("[%s] %s: %s at (%.2f, %.2f, %.2f)"):format(entry.resource, entry.playerName or "server", entry.message, entry.coords.x, entry.coords.y, entry.coords.z)
	else
		return ("[%s] %s: %s"):format(entry.resource, entry.playerName or "server", entry.message)
	end
end

local function formatLogEntry(entry)
	return ("[%s]"):format(formatTime(entry.time)) .. formatLogEntryMessage(entry)
end

local function printLogEntry(entry)
	print(formatLogEntry(entry))
end

local function log(entry)
	if not entry.time then
		entry.time = os.time()
	end

	if not entry.resource then
		entry.resource = GetInvokingResource() or GetCurrentResourceName()
	end

	if entry.player then
		if not entry.identifiers then
			entry.identifiers = GetPlayerIdentifiers(entry.player)
		end

		if not entry.endpoint then
			entry.endpoint = GetPlayerEndpoint(entry.player)
		end

		if not entry.playerName then
			entry.playerName = GetPlayerName(entry.player)
		end
	end

	exports.ghmattimysql:execute(
		[[
		INSERT INTO
			logmanager_log (time, resource, endpoint, player_name, message, coords_x, coords_y, coords_z)
		VALUES
			(FROM_UNIXTIME(@time), @resource, @endpoint, @player_name, @message, @coords_x, @coords_y, @coords_z)
		]],
		{
			["time"] = entry.time,
			["resource"] = entry.resource,
			["endpoint"] = entry.endpoint,
			["player_name"] = entry.playerName,
			["message"] = entry.message,
			["coords_x"] = entry.coords and entry.coords.x,
			["coords_y"] = entry.coords and entry.coords.y,
			["coords_z"] = entry.coords and entry.coords.z
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

	if Config.webhook then
		webhookQueue:add(formatLogEntryMessage(entry))
	end
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

exports("log", log)

AddEventHandler("logmanager:upload", function(clientLog, uploadTime)
	local identifiers = GetPlayerIdentifiers(source)
	local endpoint = GetPlayerEndpoint(source)
	local playerName = GetPlayerName(source)
	local currentTime = os.time()

	local entries = {}

	for _, entry in ipairs(clientLog) do
		entry.identifiers = identifiers
		entry.endpoint = endpoint
		entry.playerName = playerName
		entry.time = math.floor(currentTime - ((uploadTime - entry.time) / 1000))

		table.insert(entries, entry)
	end

	table.sort(entries, function(a, b) return a.time < b.time end)

	for _, entry in ipairs(entries) do
		log(entry)
	end
end)

if Config.events.baseevents.onPlayerDied then
	AddEventHandler("baseevents:onPlayerDied", function(killerType, deathCoords)
		log {
			resource = "baseevents",
			player = source,
			message = "Died",
			coords = vector3(deathCoords[1], deathCoords[2], deathCoords[3])
		}
	end)
end

if Config.events.baseevents.onPlayerKilled then
	AddEventHandler("baseevents:onPlayerKilled", function(killerId, deathData)
		if killerId == -1 then
			log {
				resource = "baseevents",
				player = source,
				message = "Was killed",
				coords = vector3(deathData.killerpos[1], deathData.killerpos[2], deathData.killerpos[3])
			}
		else
			log {
				resource = "baseevents",
				player = killerId,
				message = ("Killed %s"):format(GetPlayerName(source)),
				coords = vector3(deathData.killerpos[1], deathData.killerpos[2], deathData.killerpos[3])
			}
		end
	end)
end

if Config.events.baseevents.onPlayerWasted then
	AddEventHandler("baseevents:onPlayerWasted", function(deathCoords)
		log {
			resource = "baseevents",
			player = source,
			message = "Wasted",
			coords = vector3(deathCoords[1], deathCoords[2], deathCoords[3])
		}
	end)
end

if Config.events.baseevents.enteringVehicle then
	AddEventHandler("baseevents:enteringVehicle", function(targetVehicle, vehicleSeat, vehicleDisplayName)
		log {
			resource = "baseevents",
			player = source,
			message = ("Entering seat %d of %s %d"):format(vehicleSeat, vehicleDisplayName, targetVehicle)
		}
	end)
end

if Config.events.baseevents.enteringAborted then
	AddEventHandler("baseevents:enteringAborted", function()
		log {
			resource = "baseevents",
			player = source,
			message = "Aborted entering vehicle"
		}
	end)
end

if Config.events.baseevents.enteredVehicle then
	AddEventHandler("baseevents:enteredVehicle", function(currentVehicle, currentSeat, vehicleDisplayName)
		log {
			resource = "baseevents",
			player = source,
			message = ("Entered seat %d of %s %d"):format(currentSeat, vehicleDisplayName, currentVehicle)
		}
	end)
end

if Config.events.baseevents.leftVehicle then
	AddEventHandler("baseevents:leftVehicle", function(currentVehicle, currentSeat, vehicleDisplayName)
		log {
			resource = "baseevents",
			player = source,
			message = ("Exited seat %d of %s %d"):format(currentSeat, vehicleDisplayName, currentVehicle)
		}
	end)
end

if Config.events.chat.chatMessage then
	AddEventHandler("chatMessage", function(source, author, text)
		log {
			resource = "chat",
			player = source,
			message = text
		}
	end)
end

if Config.events.core.playerConnecting then
	AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
		log {
			resource = "core",
			player = source,
			playerName = playerName,
			message = "connecting"
		}
	end)
end

if Config.events.core.playerDropped then
	AddEventHandler("playerDropped", function(reason)
		log {
			resource = "core",
			player = source,
			message = ("dropped (%s)"):format(reason)
		}
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
			logmanager_log.coords_x as coords_x,
			logmanager_log.coords_y as coords_y,
			logmanager_log.coords_z as coords_z,
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

						if result.coords_x and result.coords_y and result.coords_z then
							collated[result.id].coords = vector3(result.coords_x, result.coords_x, result.coords_z)
						end

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
		coords_x FLOAT,
		coords_y FLOAT,
		coords_z FLOAT,
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

local routes = {}

routes["/logs.json"] = function(req, res, helpers)
	req.readJson(function(data)
		exports.ghmattimysql:execute(
			[[
			SELECT
				time,
				resource,
				endpoint,
				player_name,
				message,
				coords_x,
				coords_y,
				coords_z
			FROM
				logmanager_log
			WHERE
				(@time IS NULL OR time >= @time)
			ORDER BY
				time
			]],
			{
				["time"] = data.date
			},
			function(results)
				if results then
					res.sendJson(results)
				else
					res.sendError(500)
				end
			end)
	end)
end

SetHttpHandler(exports.httpmanager:createHttpHandler{
	authorization = Config.authorization,
	routes = routes
})
