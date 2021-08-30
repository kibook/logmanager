webhook = {}

function webhook:init(url)
	self.url = url

	self.queue = {}
	self.rateLimitRemaining = 0
	self.rateLimitReset = 0

	Citizen.CreateThread(function()
		while true do
			if self.rateLimitRemaining > 0 or os.time() > self.rateLimitReset then
				self:dequeue()
			end

			Citizen.Wait(500)
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
				else
					local rateLimitRemaining = tonumber(headers["x-ratelimit-remaining"])
					local rateLimitReset = tonumber(headers["x-ratelimit-reset"])

					if rateLimitRemaining then
						self.rateLimitRemaining = rateLimitRemaining
					end

					if rateLimitReset then
						self.rateLimitReset = rateLimitReset
					end
				end
			end,
			"POST",
			json.encode(data),
			{["Content-Type"] = "application/json"})
	end)
end
