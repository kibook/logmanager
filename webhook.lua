webhook = {}

function webhook:init(url, rateLimit)
	self.url = url
	self.rateLimit = rateLimit

	self.queue = {}

	Citizen.CreateThread(function()
		while true do
			self:dequeue()
			Citizen.Wait(self.rateLimit)
		end
	end)
end

function webhook:enqueue(cb)
	table.insert(self.queue, 1, cb)
end

function webhook:dequeue()
	local cb = table.remove(self.queue)

	if cb then
		cb()
	end
end

function webhook:execute(data)
	self:enqueue(function()
		PerformHttpRequest(self.url,
			function(status, text, headers)
				if status < 200 or status > 299 then
					print(("Error executing Discord webhook: %d \"%s\" %s"):format(status, text or "", json.encode(headers)))
				end
			end,
			"POST",
			json.encode(data),
			{["Content-Type"] = "application/json"})
	end)
end
