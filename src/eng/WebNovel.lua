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

-- Extract response body safely
local function getResponseBody(res)
    if type(res) == "string" then return res end
    if not res then return "" end
    local success, str = pcall(function() return res:string() end)
    if success and str then return str end
    return ""
end

-- Helper for standard browser headers
local function getBrowserHeaders()
    local builder = HeadersBuilder()
    builder:set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    builder:set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    return builder:build()
end

-- Parse novel listings from HTML
local function parseNovelList(bodyText)
    local novels = {}
    if bodyText == "" then return novels end

    local document = HTML.parse(bodyText)
    local items = document:select("article.story, div.block.story")

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local titleEl = item:select("h2.title a, h3.title a, .title a"):first()
        local imgEl = item:select("div.image img, img"):first()

        if titleEl then
            local name = titleEl:text()
            local link = titleEl:attr("href")
            local img = imgEl and (imgEl:attr("src") or imgEl:attr("data-src")) or ""

            if link and link ~= "" then
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

-- Extension Table Definition
local extension = {
    id = 880101,
    name = "Ranobes",
    baseURL = "https://ranobes.top",
    language = "eng",

    expandURL = function(relativeUrl)
        if not relativeUrl then return "" end
        if relativeUrl:find("^https?://") then return relativeUrl end
        return "https://ranobes.top" .. relativeUrl
    end,

    shrinkURL = function(fullUrl)
        if not fullUrl then return "" end
        return fullUrl:gsub("^https://ranobes%.top", "")
    end,

    search = function(query, page)
        local pNum = 1
        if type(page) == "number" or type(page) == "string" then
            pNum = page
        elseif type(page) == "table" then
            pNum = page.page or 1
        end

        local qStr = ""
        if type(query) == "string" then
            qStr = query
        elseif type(query) == "table" then
            qStr = query.query or query.text or ""
        end

        local url = "https://ranobes.top/index.php?do=search&subaction=search&story=" .. qStr
        if pNum > 1 then
            url = url .. "&search_start=" .. pNum
        end

        local res = GET(url, getBrowserHeaders())
        return parseNovelList(getResponseBody(res))
    end,

    listings = {
        Listing("Popular", true, function(page)
            local pNum = 1
            if type(page) == "number" or type(page) == "string" then
                pNum = page
            elseif type(page) == "table" then
                pNum = page.page or 1
            end

            local url = "https://ranobes.top/novels/"
            if pNum > 1 then
                url = "https://ranobes.top/novels/page/" .. pNum .. "/"
            end

            local res = GET(url, getBrowserHeaders())
            return parseNovelList(getResponseBody(res))
        end)
    },

    parseNovel = function(novelUrl)
        local fullUrl = extension.expandURL(novelUrl)
        local res = GET(fullUrl, getBrowserHeaders())
        local bodyText = getResponseBody(res)

        local chapters = {}
        local bookName = "Unknown Title"
        local desc = ""
        local imgUrl = ""

        if bodyText ~= "" then
            local document = HTML.parse(bodyText)
            
            local titleEl = document:select("h1.title, h1.bold"):first()
            if titleEl then bookName = titleEl:text() end

            local descEl = document:select("div.moreless-text, div.description"):first()
            if descEl then desc = descEl:text() end

            local imgEl = document:select("div.poster img"):first()
            if imgEl then imgUrl = imgEl:attr("src") or imgEl:attr("data-src") or "" end

            -- Parse chapter entries
            local chapItems = document:select("div.chapters-list a, ul.chapters-scroll li a, a.chapter-item")
            for i = 0, chapItems:size() - 1 do
                local chap = chapItems:get(i)
                local cName = chap:text()
                local cLink = chap:attr("href")

                if cLink and cLink ~= "" then
                    table.insert(chapters, Chapter({
                        name = cName,
                        link = cLink
                    }))
                end
            end
        end

        return NovelDetails({
            name = bookName,
            description = desc,
            imageURL = imgUrl,
            chapters = chapters
        })
    end,

    getPassage = function(chapterUrl)
        local fullUrl = extension.expandURL(chapterUrl)
        local res = GET(fullUrl, getBrowserHeaders())
        local bodyText = getResponseBody(res)

        local text = ""

        if bodyText ~= "" then
            local document = HTML.parse(bodyText)
            local paragraphEls = document:select("div#arrArticle p, div.text p, div.entry-content p")

            for i = 0, paragraphEls:size() - 1 do
                local p = paragraphEls:get(i)
                local pText = p:text()
                if pText and pText ~= "" then
                    text = text .. pText .. "\n\n"
                end
            end
        end

        return text
    end
}

return extension
