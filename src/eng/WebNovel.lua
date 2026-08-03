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
    
    local success, str = pcall(function() return res:string() end)
    if success and str then return str end

    success, str = pcall(function() return res:body() end)
    if success and str then return str end

    return ""
end

-- Public Web Feed Request Worker
local function fetchPublicFeed(page)
    local pNum = page or 1
    local url = "https://m.webnovel.com/go/m/api/book/getCategoryBookList?categoryType=1&pageIndex=" .. pNum .. "&pageSize=20"
    
    local res = GET(url)
    local bodyText = getResponseBody(res)
    local data = safeParseJSON(bodyText)
    
    local novels = {}
    
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
        return fetchPublicFeed(page)
    end,

    listings = {
        Listing("Popular Feed", true, function(page)
            return fetchPublicFeed(page)
        end)
    },

    parseNovel = function(novelUrl)
        local bookId = novelUrl:match("(%d+)")
        if not bookId then return nil end
        
        local res = GET("https://m.webnovel.com/go/m/api/book/getChapterList?bookId=" .. bookId)
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

        local res = GET("https://m.webnovel.com/go/m/api/chapter/getContent?bookId=" .. bookId .. "&chapterId=" .. chapterId)
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
