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
			}}
			
		},
		Events = {
			Success = Instance.new("BindableEvent");
			Fail = Instance.new("BindableEvent")
		},
		Connections = {}
	}, Embed)
end

-- Set the author field of the embed
function Embed:SetAuthor(Data)
	local Valid = {"name", "icon_url", "url"}
	self.EmbedContent.embeds[1].author = {}
	for i,v in pairs(Data) do
		if table.find(Valid, i:lower()) then
			self.EmbedContent.embeds[1].author[i:lower()] = v
		end
	end
end

-- Set the title of the embed
function Embed:SetTitle(Title)
	self.EmbedContent.embeds[1].title = Title
end

-- Set the description of the embed
function Embed:SetDescription(Data)
	self.EmbedContent.embeds[1].description = Data
end

-- Add multiple fields to the embed
function Embed:AddFields(Data)
	if not self.EmbedContent.embeds[1].fields then
		self.EmbedContent.embeds[1].fields = {}
	end
	for _, field in pairs(Data) do
		table.insert(self.EmbedContent.embeds[1].fields, field)
	end
end

-- Set a footer with optional icon
function Embed:SetFooter(Text, IconURL)
	self.EmbedContent.embeds[1].footer = {
		["text"] = Text or "",
		["icon_url"] = IconURL or ""
	}
end

-- Set an image for the embed
function Embed:SetImage(URL)
	self.EmbedContent.embeds[1].image = {["url"] = URL}
end

-- Set a thumbnail for the embed
function Embed:SetThumbnail(URL)
	self.EmbedContent.embeds[1].thumbnail = {["url"] = URL}
end

-- Set the embed's timestamp
function Embed:SetTimestamp(Timestamp)
	if Timestamp == nil then
		Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") -- RFC3339 format
	end
	self.EmbedContent.embeds[1].timestamp = Timestamp
end

-- Set the webhook URL to send the embed to
function Embed:SetWebhook(URL)
	self.Webhook = URL
end

-- Set the maximum number of tries for sending
function Embed:SetMaxTries(Num)
	self.MaxTries = Num or 5
end

-- Force send if max tries exceeded
function Embed:SetForced(Bool)
	self.Forced = Bool == nil and false or Bool
end

-- Set debug mode
function Embed:SetDebug(Bool)
	self.Debug = Bool == true
end

-- Send the embed to the webhook
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
		if (self.Tries >= self.MaxTries) and not self.Forced then
			self.Events.Fail:Fire()
			task.wait()
			self:Dispose()
			return false
		end
		self.Tries += 1
		task.wait()
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

-- Bind a function to run on successful send
function Embed:OnSuccess(Function)
	local TotalNum = #self.Connections + 1
	self.Connections[TotalNum] = self.Events.Success.Event:Connect(Function)
end

-- Bind a function to run on failure
function Embed:OnFail(Function)
	local TotalNum = #self.Connections + 1
	self.Connections[TotalNum] = self.Events.Fail.Event:Connect(Function)
end

-- Clean up resources and connections
function Embed:Dispose()
	for _, v in pairs(self.Events) do
		if typeof(v) == "Instance" then
			v:Destroy()
		end
	end
	for _, v in pairs(self.Connections) do
		if typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
		end
	end
end

return Embed
