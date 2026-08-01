-- Safe JSON Parser helper
local function safeParseJSON(text)
    if not text or text == "" then return nil end
    if json and json.parse then
        return json.parse(text)
    elseif json and json.decode then
        return json.decode(text)
    elseif parseJSON then
        return parseJSON(text)
    end
    return nil
end

-- Safely extract string body from Shosetsu HttpResponse
local function getResponseBody(res)
    if type(res) == "string" then return res end
    if not res then return "" end
    
    -- Shosetsu uses res:string()
    local success, str = pcall(function() return res:string() end)
    if success and str then return str end

    -- Fallback check for alternative versions
    success, str = pcall(function() return res:body() end)
    if success and str then return str end

    return ""
end

-- Helper to construct valid Shosetsu Headers objects
local function getBrowserHeaders()
    local builder = HeadersBuilder()
    builder:set("User-Agent", "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
    builder:set("Accept", "application/json, text/plain, */*")
    return builder:build()
end

-- Define search worker
local function performSearch(query, page, filters)
    local qStr = "shadow"
    if type(query) == "string" and query ~= "" then
        qStr = query
    elseif type(query) == "table" then
        qStr = query.query or query.text or "shadow"
    end

    local pNum = 1
    if type(page) == "number" or type(page) == "string" then
        pNum = page
    elseif type(page) == "table" then
        pNum = page.page or 1
    end

    local url = "https://m.webnovel.com/go/m/api/search/search-result?keywords=" .. qStr .. "&pageIndex=" .. pNum
    local res = GET(url, getBrowserHeaders())
    local bodyText = getResponseBody(res)
    local data = safeParseJSON(bodyText)
    
    local novels = {}
    
    -- Parse JSON response
    if data and data.data then
        local items = data.data.bookItems or data.data.items or data.data.list
        if items then
            for _, item in ipairs(items) do
                local bName = item.bookName or item.name or "Unknown"
                local bId = item.bookId or item.id or ""
                local img = item.coverUrl or ("https://img.webnovel.com/bookcover/" .. bId .. "/600/600.jpg")
                
                if bId ~= "" then
                    table.insert(novels, NovelListing({
                        name = bName,
                        link = "/book/" .. bId,
                        imageURL = img
                    }))
                end
            end
        end
    end

    return novels
end

-- Extension Table Definition
local extension = {
    id = 880101,
    name = "WebNovel",
    baseURL = "https://m.webnovel.com",
    language = "eng",

    expandURL = function(relativeUrl)
        if not relativeUrl then return "" end
        if relativeUrl:find("^https?://") then
            return relativeUrl
        end
        return "https://m.webnovel.com" .. relativeUrl
    end,

    shrinkURL = function(fullUrl)
        if not fullUrl then return "" end
        return fullUrl:gsub("^https://m%.webnovel%.com", "")
    end,

    search = function(query, page, filters)
        return performSearch(query, page, filters)
    end,

    listings = {
        Listing("Popular", true, function(page)
            return performSearch("shadow", page, nil)
        end)
    },

    parseNovel = function(novelUrl)
        local bookId = novelUrl:match("(%d+)")
        if not bookId then return nil end
        
        local res = GET("https://m.webnovel.com/go/m/api/book/getChapterList?bookId=" .. bookId, getBrowserHeaders())
        local bodyText = getResponseBody(res)
        local data = safeParseJSON(bodyText)

        local chapters = {}
        if data and data.data and data.data.volumeItems then
            for _, volume in ipairs(data.data.volumeItems) do
                if volume.chapterItems then
                    for _, chap in ipairs(volume.chapterItems) do
                        table.insert(chapters, Chapter({
                            name = chap.chapterName or "Chapter",
                            link = "/book/" .. bookId .. "/" .. (chap.chapterId or "")
                        }))
                    end
                end
            end
        end

        local bookName = "Unknown"
        local desc = ""
        if data and data.data and data.data.bookInfo then
            bookName = data.data.bookInfo.bookName or "Unknown"
            desc = data.data.bookInfo.description or ""
        end

        return NovelDetails({
            name = bookName,
            description = desc,
            imageURL = "https://img.webnovel.com/bookcover/" .. bookId .. "/600/600.jpg",
            chapters = chapters
        })
    end,

    getPassage = function(chapterUrl)
        local bookId, chapterId = chapterUrl:match("/book/(%d+)/(%d+)")
        if not bookId or not chapterId then return "" end

        local res = GET("https://m.webnovel.com/go/m/api/chapter/getContent?bookId=" .. bookId .. "&chapterId=" .. chapterId, getBrowserHeaders())
        local bodyText = getResponseBody(res)
        local data = safeParseJSON(bodyText)
        
        local text = ""
        if data and data.data and data.data.chapterInfo and data.data.chapterInfo.contents then
            for _, paragraph in ipairs(data.data.chapterInfo.contents) do
                if paragraph.content then
                    text = text .. paragraph.content .. "\n\n"
                end
            end
        end

        return text
    end
}

return extension
