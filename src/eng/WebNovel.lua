-- Extension Information
id = 880101
name = "WebNovel"
baseUrl = "https://m.webnovel.com"
language = "eng"

-- 1. Search / Popular Novels via JSON API
function getListing(page, type)
    -- Fetch JSON directly from WebNovel's API
    local res = GET("https://m.webnovel.com/go/m/api/search/search-result?keyword=shadow&pageIndex=" .. page)
    local data = parseJSON(res:body())
    
    local novels = {}
    
    -- Check if data exists in the API response
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
function getNovelDetails(novelUrl)
    -- Extract the book ID from the URL link
    local bookId = novelUrl:match("(%d+)")
    
    -- Fetch chapter catalog from internal API
    local res = GET("https://m.webnovel.com/go/m/api/book/getChapterList?bookId=" .. bookId)
    local data = parseJSON(res:body())

    local chapters = {}
    if data and data.data and data.data.volumeItems then
        for _, volume in ipairs(data.data.volumeItems) do
            for _, chap in ipairs(volume.chapterItems) do
                table.insert(chapters, Chapter({
                    name = chap.chapterName,
                    link = "/book/" .. bookId .. "/" .. chap.chapterId
                }))
            end
        end
    end

    return NovelDetails({
        name = data.data.bookInfo.bookName or "Unknown",
        description = data.data.bookInfo.description or "",
        imageURL = "https://img.webnovel.com/bookcover/" .. bookId .. "/600/600.jpg",
        chapters = chapters
    })
end

-- 3. Chapter Content
function getChapterText(chapterUrl)
    local bookId, chapterId = chapterUrl:match("/book/(%d+)/(%d+)")
    local res = GET("https://m.webnovel.com/go/m/api/chapter/getContent?bookId=" .. bookId .. "&chapterId=" .. chapterId)
    local data = parseJSON(res:body())
    
    local text = ""
    if data and data.data and data.data.chapterInfo and data.data.chapterInfo.contents then
        for _, paragraph in ipairs(data.data.chapterInfo.contents) do
            text = text .. paragraph.content .. "\n\n"
        end
    end

    return text
end
