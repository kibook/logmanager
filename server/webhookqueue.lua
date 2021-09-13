local discordCharacterLimit = 2000

WebhookQueue = {}

function WebhookQueue:new(webhook)
	self.__index = self
	local self = setmetatable({}, self)

	self.webhook = webhook

	self.content = ""
	self.contentLen = 0

	Citizen.CreateThread(function()
		while self do
			if self.contentLen > 0 then
				self:send()
			end
			Citizen.Wait(1000)
		end
	end)

	return self
end

function WebhookQueue:add(message)
	message = message .. "\n"

	local messageLen = message:len()

	if self.contentLen + messageLen > discordCharacterLimit - 7 then
		self:send()
	end

	self.content = self.content .. message
	self.contentLen = self.contentLen + messageLen
end

function WebhookQueue:send()
	local content = "```\n" .. self.content .. "```"
	exports.discord_rest:executeWebhookUrl(self.webhook, {content = content}):next(nil, function(err)
		print("Error executing webhook: " .. err)
	end)
	self.content = ""
	self.contentLen = 0
end
