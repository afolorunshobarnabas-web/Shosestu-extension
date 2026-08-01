-- Create local extension table
local extension = {}

-- Extension Information
extension.id = 880101
extension.name = "WebNovel"
extension.baseUrl = "https://m.webnovel.com"
extension.language = "eng"

-- URL Helper Functions
function extension.expandURL(relativeUrl)
    if not relativeUrl then return "" end
    if relativeUrl:find("^https?://") then
        return relativeUrl
    end
    return extension.baseUrl .. relativeUrl
end

function extension.shrinkURL(fullUrl)
    if not fullUrl then return "" end
    return fullUrl:gsub("^" .. extension.baseUrl, "")
end

-- 1. Search Function (Safely handles strings, numbers, or tables)
function extension.search(query, page, filters)
    -- Safely extract search query string
    local qStr = "shadow"
    if type(query) == "string" and query ~= "" then
        qStr = query
    elseif type(query) == "table" then
        qStr = query.query or query.text or "shadow"
    end

    -- Safely extract page number
    local pNum = 1
    if type(page) == "number" or type(page) == "string" then
        pNum = page
    elseif type(page) == "table" then
        pNum = page.page or 1
    end

    local url = "https://m.webnovel.com/go/m/api/search/search-result?keyword=" .. qStr .. "&pageIndex=" .. pNum
    local res = GET(url)
    local data = parseJSON(res:body())
    
    local novels = {}
    
    if data and data.data and data.data.bookItems then
        for _, item in ipairs(data.data.bookItems) do
            table.insert(novels, NovelListing({
                name = item.bookName,
                link = "/book/" .. item.bookId,
                imageURL = "https://img.webnovel.com/bookcover/" .. item.bookId .. "/600/600.jpg"
            }))
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
    
    local res = GET("https://m.webnovel.com/go/m/api/book/getChapterList?bookId=" .. bookId)
    local data = parseJSON(res:body())

    local chapters = {}
    if data and data.data and data.data.volumeItems then
        for _, volume in ipairs(data.data.volumeItems) do
            if volume.chapterItems then
                for _, chap in ipairs(volume.chapterItems) do
                    table.insert(chapters, Chapter({
                        name = chap.chapterName,
                        link = "/book/" .. bookId .. "/" .. chap.chapterId
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

    local res = GET("https://m.webnovel.com/go/m/api/chapter/getContent?bookId=" .. bookId .. "&chapterId=" .. chapterId)
    local data = parseJSON(res:body())
    
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
