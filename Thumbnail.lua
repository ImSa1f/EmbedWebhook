local HttpService = game:GetService("HttpService")

local function fetchRobloxThumbnail(assetId)
    local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=420x420&format=Png&isCircular=false", assetId)
    
    local success, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data.data and #data.data > 0 then
            return data.data[1].imageUrl
        end
    end
    return nil
end

return fetchRobloxThumbnail
