-- Helper to execute HTTP requests using Shosetsu's network client
local function fetchHTML(url, headers)
    local req
    if headers then
        req = GET(url, headers)
    else
        req = GET(url)
    end

    local res = nil
    -- Execute the request through Shosetsu's OkHttp client
    if client then
        local success, response = pcall(function()
            return client:newCall(req):execute()
        end)
        if success and response then
            res = response
        end
    end

    if not res then
        res = req
    end

    if res == nil then return "" end
    if type(res) == "string" then return res end

    -- Extract body string from OkHttp Response object
    local success, bodyStr = pcall(function()
        return res:body():string()
    end)
    if success and type(bodyStr) == "string" and bodyStr ~= "" then
        return bodyStr
    end

    return ""
end

-- Parse Novel Listings from HTML
local function parseNovelList(bodyText)
    local novels = {}
    if bodyText == nil or bodyText == "" or type(bodyText) ~= "string" then 
        return novels 
    end

    local success, document = pcall(function() return HTML.parse(bodyText) end)
    if not success or not document then return novels end

    -- Target Ranobes story blocks
    local items = document:select("div.block_story, article.story, div.short-story, div.story")
    if not items or items:size() == 0 then
        items = document:select("article, div.block")
    end

    if not items then return novels end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local titleEl = item:select(".title_story a, h2.title a, h3.title a, .title a, a[href*='/novels/']"):first()
            local imgEl = item:select("img"):first()

            if titleEl then
                local name = titleEl:text()
                if not name or name == "" then
                    name = titleEl:attr("title")
                end

                local link = titleEl:attr("href")
                local img = ""

                if imgEl then
                    img = imgEl:attr("data-src") or imgEl:attr("src") or imgEl:attr("data-original") or ""
                end

                if link and link ~= "" and name and name ~= "" then
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
        local qStr = ""
        if type(query) == "string" then
            qStr = query
        elseif type(query) == "table" then
            qStr = query.query or query.text or ""
        end

        local url = "https://ranobes.top/index.php?do=search&subaction=search&story=" .. qStr
        local bodyText = fetchHTML(url)
        return parseNovelList(bodyText)
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

            local bodyText = fetchHTML(url)
            return parseNovelList(bodyText)
        end)
    },

    parseNovel = function(novelUrl)
        local fullUrl = extension.expandURL(novelUrl)
        local bodyText = fetchHTML(fullUrl)

        local chapters = {}
        local bookName = "Unknown Title"
        local desc = ""
        local imgUrl = ""

        if bodyText and bodyText ~= "" then
            local success, document = pcall(function() return HTML.parse(bodyText) end)
            if success and document then
                local titleEl = document:select("h1.title, h1"):first()
                if titleEl then bookName = titleEl:text() end

                local descEl = document:select("div.moreless-text, div.description, div.entry-content"):first()
                if descEl then desc = descEl:text() end

                local imgEl = document:select("div.poster img, .story-poster img"):first()
                if imgEl then imgUrl = imgEl:attr("src") or imgEl:attr("data-src") or "" end

                local chapItems = document:select("div.chapters-list a, ul.chapters-scroll li a, a.chapter-item")
                if chapItems then
                    for i = 0, chapItems:size() - 1 do
                        local chap = chapItems:get(i)
                        if chap then
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
        local bodyText = fetchHTML(fullUrl)

        local text = ""

        if bodyText and bodyText ~= "" then
            local success, document = pcall(function() return HTML.parse(bodyText) end)
            if success and document then
                local paragraphEls = document:select("div#arrArticle p, div.text p, div.entry-content p")
                if paragraphEls then
                    for i = 0, paragraphEls:size() - 1 do
                        local p = paragraphEls:get(i)
                        if p then
                            local pText = p:text()
                            if pText and pText ~= "" then
                                text = text .. pText .. "\n\n"
                            end
                        end
                    end
                end
            end
        end

        return text
    end
}

return extension
