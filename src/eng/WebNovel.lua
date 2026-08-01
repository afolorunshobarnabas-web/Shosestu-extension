-- Create local extension table
local extension = {}

-- Extension Information
extension.id = 880101
extension.name = "WebNovel"
extension.baseURL = "https://m.webnovel.com"
extension.language = "eng"

-- Helper to construct valid Shosetsu Headers objects
local function getBrowserHeaders()
    local builder = HeadersBuilder()
    builder:set("User-Agent", "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
    builder:set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
    return builder:build()
end

-- URL Helper Functions
function extension.expandURL(relativeUrl)
    if not relativeUrl then return "" end
    if relativeUrl:find("^https?://") then
        return relativeUrl
    end
    return extension.baseURL .. relativeUrl
end

function extension.shrinkURL(fullUrl)
    if not fullUrl then return "" end
    return fullUrl:gsub("^" .. extension.baseURL, "")
end

-- 1. Search Function (HTML Scraper approach)
function extension.search(query, page, filters)
    local qStr = "shadow"
    if type(query) == "string" and query ~= "" then
        qStr = query
    elseif type(query) == "table" then
        qStr = query.query or query.text or "shadow"
    end

    local url = "https://m.webnovel.com/search?keywords=" .. qStr
    local res = GET(url, getBrowserHeaders())
    local bodyText = type(res) == "string" and res or (res and res.body and res:body()) or ""
    
    local novels = {}
    
    -- Parse HTML elements if JSON fails
    if bodyText ~= "" then
        local document = HTML.parse(bodyText)
        local items = document:select("li.search-item, a.book-item, div.book-li")
        
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local titleEl = item:select(".book-name, .name, h3"):first()
            local linkEl = item:select("a"):first()
            local imgEl = item:select("img"):first()
            
            if titleEl and linkEl then
                local name = titleEl:text()
                local link = linkEl:attr("href")
                local img = imgEl and imgEl:attr("src") or ""
                
                table.insert(novels, NovelListing({
                    name = name,
                    link = link,
                    imageURL = img
                }))
            end
        end
    end

    return novels
end

-- 2. Define Listings Table
extension.listings = {
    Listing("Popular", true, function(page)
        return extension.search("shadow", page, nil)
    end)
}

-- Return the extension table
return extension
