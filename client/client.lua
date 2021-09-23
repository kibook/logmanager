local clientLog = {}

local function log(entry)
	if not entry.time then
		entry.time = GetGameTimer()
	end

	if not entry.resource then
		entry.resource = GetInvokingResource() or GetCurrentResourceName()
	end

	if entry.coords == true then
		entry.coords = GetEntityCoords(PlayerPedId())
	end

	table.insert(clientLog, entry)
end

local function uploadLog()
	TriggerServerEvent("logmanager:upload", clientLog, GetGameTimer())
	clientLog = {}
end

exports("log", log)

if Config.events.spawnmanager.playerSpawned then
	AddEventHandler("playerSpawned", function(spawnInfo)
		log {
			resource = "spawnmanager",
			message = "Spawned",
			coords = vector3(spawnInfo.x, spawnInfo.y, spawnInfo.z)
		}
	end)
end

Citizen.CreateThread(function()
	while true do
		uploadLog()
		Citizen.Wait(Config.uploadInterval)
	end
end)
