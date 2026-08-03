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
            local log = {}

            -- 1. Check known candidate global functions/objects
            local candidates = {"GET", "POST", "HTTP", "http", "fetch", "request", "Request", "client", "network", "Network", "perform", "HTML"}
            for _, name in ipairs(candidates) do
                if _G[name] ~= nil then
                    table.insert(log, name .. ":" .. type(_G[name]))
                end
            end

            -- 2. Inspect sandbox metatable if present
            local mt = getmetatable(_G)
            if mt and type(mt.__index) == "table" then
                for k, v in pairs(mt.__index) do
                    table.insert(log, "mt." .. tostring(k) .. ":" .. type(v))
                end
            end

            -- 3. Inspect the GET() object return type and available methods
            if GET then
                local req = GET("https://ranobes.top/novels/")
                table.insert(log, "GET_type:" .. type(req))
                
                if type(req) == "userdata" or type(req) == "table" then
                    local testMethods = {"execute", "await", "text", "body", "string", "send", "run", "toResponse", "request"}
                    for _, m in ipairs(testMethods) do
                        local ok, val = pcall(function() return req[m] end)
                        if ok and val ~= nil then
                            table.insert(log, "req." .. m .. ":" .. type(val))
                        end
                    end
                end
            end

            error("DIAG: " .. table.concat(log, " | "))
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
