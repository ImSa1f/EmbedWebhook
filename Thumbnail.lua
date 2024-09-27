

local RobloxThumbnailFetcher = {}
local HttpService = game:GetService("HttpService") 


function RobloxThumbnailFetcher.fetchThumbnail(assetId)
    local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. tostring(assetId) .. "&returnPolicy=PlaceHolder&size=420x420&format=webp"
    print("Fetching image for assetId:", assetId) -- Debug: print assetId
    
    local success, response = pcall(function() 
        return HttpService:GetAsync(url) 
    end)
    
    if not success then
        warn("Failed to fetch thumbnail data: ", response)
        return nil
    end

    local data = HttpService:JSONDecode(response) 
    
    if data and data.data and data.data[1] and data.data[1].imageUrl then
        print("Fetched image URL:", data.data[1].imageUrl)
        return data.data[1].imageUrl 
    else
        warn("No valid image URL found for assetId: ", assetId)
        return nil 
    end
end

return RobloxThumbnailFetcher
