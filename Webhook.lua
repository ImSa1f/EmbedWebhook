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
				["title"] = "Kings  here!",
				["description"] = "I'm ON TOP!",
				["color"] = tonumber(0xff1f44),
			}}
			
		},
		Events = {
			Success = Instance.new("BindableEvent");
			Fail = Instance.new("BindableEvent")
		},
		Connections = {}
	}, Embed)
end


function Embed:SetAuthor(Data)
	local Valid = {"name", "icon_url", "url"}
	self.EmbedContent.embeds[1].author = {}
	for i,v in pairs(Data) do
		if table.find(Valid, i:lower()) then
			self.EmbedContent.embeds[1].author[i:lower()] = v
		end
	end
end


function Embed:SetTitle(Title)
	self.EmbedContent.embeds[1].title = Title
end

function Embed:SetDescription(Data)
	self.EmbedContent.embeds[1].description = Data
end

function Embed:AddFields(Data)
	if not self.EmbedContent.embeds[1].fields then
		self.EmbedContent.embeds[1].fields = {}
	end
	for _, field in pairs(Data) do
		table.insert(self.EmbedContent.embeds[1].fields, field)
	end
end


function Embed:SetFooter(Text, IconURL)
	self.EmbedContent.embeds[1].footer = {
		["text"] = Text or "",
		["icon_url"] = IconURL or ""
	}
end


function Embed:SetImage(URL)
	self.EmbedContent.embeds[1].image = {["url"] = URL}
end


function Embed:SetThumbnail(URL)
	self.EmbedContent.embeds[1].thumbnail = {["url"] = URL}
end


function Embed:SetTimestamp(Timestamp)
	if Timestamp == nil then
		Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
	end
	self.EmbedContent.embeds[1].timestamp = Timestamp
end

function Embed:SetWebhook(URL)
	self.Webhook = URL
end


function Embed:SetMaxTries(Num)
	self.MaxTries = Num or 5
end


function Embed:SetForced(Bool)
	self.Forced = Bool == nil and false or Bool
end


function Embed:SetDebug(Bool)
	self.Debug = Bool == true
end

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

function Embed:OnSuccess(Function)
	local TotalNum = #self.Connections + 1
	self.Connections[TotalNum] = self.Events.Success.Event:Connect(Function)
end

function Embed:OnFail(Function)
	local TotalNum = #self.Connections + 1
	self.Connections[TotalNum] = self.Events.Fail.Event:Connect(Function)
end

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
