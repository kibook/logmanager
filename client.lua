local clientLog = {}

local function log(resource, message)
	local entry = {}

	entry.time = GetGameTimer()
	entry.resource = resource or GetCurrentResourceName()
	entry.message = message

	table.insert(clientLog, entry)
end

local function uploadLog()
	TriggerServerEvent("logmanager:upload", clientLog, GetGameTimer())
	clientLog = {}
end

exports("log", log)

Citizen.CreateThread(function()
	while true do
		uploadLog()
		Citizen.Wait(Config.uploadInterval)
	end
end)
