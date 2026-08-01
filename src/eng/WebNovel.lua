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

-- Helper to construct valid Shosetsu Headers objects
local function getBrowserHeaders()
    local builder = HeadersBuilder()
    builder:set("User-Agent", "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
    builder:set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
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

    local url = "https://m.webnovel.com/search?keywords=" .. qStr
    local res = GET(url, getBrowserHeaders())
    local bodyText = type(res) == "string" and res or (res and res.body and res:body()) or ""
    
    local novels = {}
    
    if bodyText ~= "" then
        local document = HTML.parse(bodyText)
        local items = document:select("li.search-item, a.book-item, div.book-li, .g_book_item")
        
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local titleEl = item:select(".book-name, .name, h3, .g_book_name"):first()
            local linkEl = item:select("a"):first()
            local imgEl = item:select("img"):first()
            
            if titleEl and linkEl then
                local name = titleEl:text()
                local link = linkEl:attr("href")
                local img = imgEl and (imgEl:attr("src") or imgEl:attr("data-original")) or ""
                
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

-- Extension Table Definition (Explicit key declaration)
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
        local bodyText = type(res) == "string" and res or (res and res.body and res:body()) or ""
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
        local bodyText = type(res) == "string" and res or (res and res.body and res:body()) or ""
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
