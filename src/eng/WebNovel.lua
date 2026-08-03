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
    return ""
end

-- Helper to construct valid Shosetsu Headers objects
local function getBrowserHeaders()
    local builder = HeadersBuilder()
    builder:set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    builder:set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
    return builder:build()
end

-- 1. Search & Popular Worker Function
local function performSearch(query, page)
    local pNum = 1
    if type(page) == "number" or type(page) == "string" then
        pNum = page
    elseif type(page) == "table" then
        pNum = page.page or 1
    end

    local qStr = "shadow"
    if type(query) == "string" and query ~= "" then
        qStr = query
    elseif type(query) == "table" then
        qStr = query.query or query.text or "shadow"
    end

    -- Query URL handling
    local url = "https://freewebnovel.com/search/?searchkey=" .. qStr
    if pNum > 1 then
        url = "https://freewebnovel.com/search/" .. qStr .. "/" .. pNum .. ".html"
    end

    local res = GET(url, getBrowserHeaders())
    local bodyText = getResponseBody(res)
    
    local novels = {}

    if bodyText ~= "" then
        local document = HTML.parse(bodyText)
        local items = document:select("div.li-row, div.con, div.pic")

        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local titleEl = item:select(".tit a, .title a, h3 a"):first()
            local imgEl = item:select("img"):first()

            if titleEl then
                local name = titleEl:attr("title")
                if not name or name == "" then
                    name = titleEl:text()
                end

                local link = titleEl:attr("href")
                local img = imgEl and (imgEl:attr("src") or imgEl:attr("data-original")) or ""

                if link and link ~= "" then
                    table.insert(novels, NovelListing({
                        name = name,
                        link = link,
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
    baseURL = "https://freewebnovel.com",
    language = "eng",

    expandURL = function(relativeUrl)
        if not relativeUrl then return "" end
        if relativeUrl:find("^https?://") then return relativeUrl end
        return "https://freewebnovel.com" .. relativeUrl
    end,

    shrinkURL = function(fullUrl)
        if not fullUrl then return "" end
        return fullUrl:gsub("^https://freewebnovel%.com", "")
    end,

    search = function(query, page, filters)
        return performSearch(query, page)
    end,

    listings = {
        Listing("Popular", true, function(page)
            return performSearch("shadow", page)
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
            
            -- Extract Novel Info
            local titleEl = document:select("h1.tit, h1.book-name"):first()
            if titleEl then bookName = titleEl:text() end

            local descEl = document:select("div.inner, div.description, div.m-desc"):first()
            if descEl then desc = descEl:text() end

            local imgEl = document:select("div.pic img, div.book-img img"):first()
            if imgEl then imgUrl = imgEl:attr("src") or imgEl:attr("data-original") or "" end

            -- Extract Chapter List
            local chapItems = document:select("div.m-newest2 ul.ul-list5 li a, div.more-list ul li a, ul.chapter-list li a")
            for i = 0, chapItems:size() - 1 do
                local chap = chapItems:get(i)
                local cName = chap:attr("title")
                if not cName or cName == "" then cName = chap:text() end

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
            local paragraphEls = document:select("div.txt p, div.p-text p, div.chapter-entity p")

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
