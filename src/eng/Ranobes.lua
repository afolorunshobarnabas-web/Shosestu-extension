-- Safe Body Text Extractor
local function getResponseBody(res)
    if res == nil then return "" end
    if type(res) == "string" then return res end
    
    if type(res) == "userdata" or type(res) == "table" then
        local success, str = pcall(function() return res:string() end)
        if success and str and str ~= "" then return str end
        
        success, str = pcall(function() return res:body() end)
        if success and str and str ~= "" then return str end
    end
    
    return tostring(res)
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
        return {}
    end,

    listings = {
        Listing("Popular", true, function(page)
            local url = "https://ranobes.top/novels/"
            local res = GET(url)
            local bodyText = getResponseBody(res)

            -- DIAGNOSTIC BREAKPOINT: Print HTML payload info
            local snippet = bodyText:sub(1, 200):gsub("\n", " "):gsub("\r", "")
            error("HTML LEN: " .. tostring(#bodyText) .. " | DATA: [" .. snippet .. "]")

            return {}
        end)
    },

    parseNovel = function(novelUrl)
        return NovelDetails({ name = "", description = "", imageURL = "", chapters = {} })
    end,

    getPassage = function(chapterUrl)
        return ""
    end
}

return extension
