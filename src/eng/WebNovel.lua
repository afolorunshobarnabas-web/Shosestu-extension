-- Create local extension table
local extension = {}

-- Extension Information (Notice capital 'URL')
extension.id = 880101
extension.name = "WebNovel"
extension.baseURL = "https://m.webnovel.com"
extension.language = "eng"

-- Standard Headers
local headers = {
    ["User-Agent"] = "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    ["Accept"] = "application/json, text/plain, */*"
}

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

-- 1. Search Function
function extension.search(query, page, filters)
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

    -- Direct search API endpoint
    local url = "https://m.webnovel.com/go/m/api/search/search-result?keywords=" .. qStr .. "&pageIndex=" .. pNum
    local res = GET(url, headers)
    
    local bodyText = type(res) == "string" and res or (res and res.body and res:body()) or ""
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

-- 2. Define Listings Table
extension.listings = {
    Listing("Popular", true, function(page)
        return extension.search("shadow", page, nil)
    end)
}

-- 3. Novel Details & Chapter List
function extension.parseNovel(novelUrl)
    local bookId = novelUrl:match("(%d+)")
    if not bookId then return nil end
    
    local res = GET("https://m.webnovel.com/go/m/api/book/getChapterList?bookId=" .. bookId, headers)
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
end

-- 4. Chapter Content (Passage Parser)
function extension.getPassage(chapterUrl)
    local bookId, chapterId = chapterUrl:match("/book/(%d+)/(%d+)")
    if not bookId or not chapterId then return "" end

    local res = GET("https://m.webnovel.com/go/m/api/chapter/getContent?bookId=" .. bookId .. "&chapterId=" .. chapterId, headers)
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

-- Return the extension table
return extension
