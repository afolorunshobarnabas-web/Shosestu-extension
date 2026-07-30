-- Extension Information
id = 880101
name = "WebNovel"
baseUrl = "https://m.webnovel.com"
language = "eng"

-- 1. Search / Popular Novels
function getListing(page, type)
    local url = baseUrl .. "/search?keywords="
    local document = GETDocument(url)
    
    local novelElements = document:select("a.book-item") -- Adjust CSS selector to site's HTML
    local novels = {}

    for i = 0, novelElements:size() - 1 do
        local el = novelElements:get(i)
        table.insert(novels, {
            name = el:select(".book-name"):text(),
            link = el:attr("href"),
            imageURL = el:select("img"):attr("src")
        })
    end

    return novels
end

-- 2. Fetch Novel Details & Chapter List
function getNovelDetails(novelUrl)
    local document = GETDocument(baseUrl .. novelUrl)

    local details = {
        name = document:select(".book-detail-name"):text(),
        description = document:select(".book-detail-desc"):text(),
        imageURL = document:select(".book-cover img"):attr("src"),
        chapters = {}
    }

    local chapterElements = document:select("ul.chapter-list a")
    for i = 0, chapterElements:size() - 1 do
        local el = chapterElements:get(i)
        table.insert(details.chapters, {
            name = el:text(),
            link = el:attr("href")
        })
    end

    return details
end

-- 3. Fetch Chapter Text
function getChapterText(chapterUrl)
    local document = GETDocument(baseUrl .. chapterUrl)
    
    -- Extract paragraph elements from reader content
    local paragraphs = document:select(".chapter-content p")
    local text = ""

    for i = 0, paragraphs:size() - 1 do
        text = text .. paragraphs:get(i):text() .. "\n\n"
    end

    return text
end
