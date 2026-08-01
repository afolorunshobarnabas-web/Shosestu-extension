-- Create local extension table
local extension = {}

-- Extension Information
extension.id = 880101
extension.name = "WebNovel"
extension.baseUrl = "https://m.webnovel.com"
extension.language = "eng"

-- URL Helper Functions required by Shosetsu
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

-- 1. Novel Listings (Catalog & Search)
function extension.listings(page, type)
    local url = "https://m.webnovel.com/go/m/api/search/search-result?keyword=shadow&pageIndex=" .. page
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

-- 2. Novel Details & Chapter List
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

-- 3. Chapter Content (Passage Parser)
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
