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
            -- ENVIRONMENT INSPECTOR: List all global variables in Shosetsu
            local globals = {}
            for k, v in pairs(_G) do
                table.insert(globals, tostring(k) .. "(" .. type(v) .. ")")
            end

            error("GLOBALS: " .. table.concat(globals, ", "))
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
