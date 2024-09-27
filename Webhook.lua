local Embed = {}
Embed.__index = Embed

local HTTPService = game:GetService("HttpService")

function Embed.new()
	return setmetatable({
		Debug = false,
		Forced = false,
		MaxTries = 5,
		Tries = 0,
		Webhook = "",
		EmbedContent = {
			
			["content"] = "",
			["embeds"] = {{
				["title"] = "",
				["description"] = "",
				["color"] = tonumber(0x8B008B),
				["image"] = {},  -- To store the image if set
				["footer"] = {}, -- To store footer text and icon if set
				["timestamp"] = "" -- Placeholder for timestamp
			}}
			
		},
		Events = {
			Success = Instance.new("BindableEvent");
			Fail = Instance.new("BindableEvent")
		},
		Connections = {
			
		}
	}, Embed)
end

-- Function to set the author information
function Embed:SetAuthor(Data)
	local Valid = {"name", "icon_url", "url"}
	self.EmbedContent.embeds[1].author = {}
	for i,v in pairs(Data) do
		if table.find(Valid, i:lower()) then
			self.EmbedContent.embeds[1].author[i:lower()] = v
		end
	end
end

-- Function to set the description
function Embed:SetDescription(Data)
	self.EmbedContent.embeds[1].description = Data
end

-- Function to set fields in the embed
function Embed:AddFields(Data)
	if not self.EmbedContent.embeds[1].fields then
		self.EmbedContent.embeds[1].fields = {}
	end
	self.EmbedContent.embeds[1].fields = Data
end

-- Function to set the webhook URL
function Embed:SetWebhook(URL)
	self.Webhook = URL
end

-- Function to set the maximum number of retries
function Embed:SetMaxTries(Num)
	if not Num then Num = 5 end
	self.MaxTries = Num
end

-- Function to force the sending of the embed
function Embed:SetForced(Bool)
	if Bool == nil then Bool = false end
	self.Forced = Bool
end

-- Function to enable or disable debugging mode
function Embed:SetDebug(Bool)
	if type(Bool) ~= "boolean" then Bool = false end
	self.Debug = Bool
end

-- Function to set the image in the embed
function Embed:SetImage(URL)
	self.EmbedContent.embeds[1].image = {["url"] = URL}
end

-- Function to set the footer in the embed
function Embed:SetFooter(Text, IconURL)
	self.EmbedContent.embeds[1].footer = {
		["text"] = Text,
		["icon_url"] = IconURL or "" -- IconURL is optional
	}
end

-- Function to set the timestamp (optional)
function Embed:SetTimestamp(Timestamp)
	if Timestamp == nil then 
		self.EmbedContent.embeds[1].timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
	else
		self.EmbedContent.embeds[1].timestamp = Timestamp
	end
end

-- Send the embed through a webhook
function Embed:Send()
	local S,E = pcall(function()
		request({
			Method = "Post",
			Url = self.Webhook,
			Headers = {
			["Content-Type"] = "Application/Json"
			},
			Body = HTTPService:JSONEncode(self.EmbedContent)
			})
	end)
	if not S then 
		if self.Debug then
			warn(E)
		end
		if (self.Tries >= self.MaxTries) and not self.Forced then self.Events.Fail:Fire(); task.wait() self:Dispose() return false end
		task.wait()
		self.Tries += 1
		self:Send()
		return false
	else
		if self.Debug then
			print(`Successfully sent in {self.Tries} attempts!`) 
		end
		self.Events.Success:Fire()
		task.wait()
		self:Dispose()
		return true
	end
end

-- Bind a function to the success event
function Embed:OnSuccess(Function)
	local TotalNum = #self.Connections+1
	self.Connections[TotalNum] = self.Events.Success.Event:Connect(Function)
end

-- Bind a function to the failure event
function Embed:OnFail(Function)
	local TotalNum = #self.Connections+1
	self.Connections[TotalNum] = self.Events.Fail.Event:Connect(Function)
end

-- Clean up the events and connections
function Embed:Dispose()
	for i,v in pairs(self.Events) do
		if typeof(v) == "Instance" then v:Destroy() end
	end
	for i,v in pairs(self.Connections) do
		if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
	end
end

return Embed
