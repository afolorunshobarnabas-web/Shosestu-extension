local function getResponseBody(res)
    if type(res) == "string" then return res end
    if not res then return "NIL_RESPONSE" end
    local success, str = pcall(function() return res:string() end)
    if success and str then return str end
    return "FAILED_TO_EXTRACT_STRING"
end

local function getBrowserHeaders()
    local builder = HeadersBuilder()
    builder:set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    builder:set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    return builder:build()
end

local extension = {
    id = 880101,
    name = "Ranobes",
    baseURL = "https://ranobes.top",
    language = "eng",

    expandURL = function(relativeUrl) return relativeUrl end,
    shrinkURL = function(fullUrl) return fullUrl end,

    search = function(query, page) return {} end,

    listings = {
        Listing("Popular", true, function(page)
            local res = GET("https://ranobes.top/", getBrowserHeaders())
            local body = getResponseBody(res)
            
            -- Extract page title if available to see what loaded
            local title = body:match("<title>(.-)</title>") or "No title found"
            local snippet = string.sub(body, 1, 100):gsub("\n", " ")
            
            error("Ranobes Debug -> Title: [" .. title .. "] | Snippet: [" .. snippet .. "]")
        end)
    },

    parseNovel = function(novelUrl) return nil end,
    getPassage = function(chapterUrl) return "" end
}

return extension
