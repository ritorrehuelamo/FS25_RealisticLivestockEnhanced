-- XML boundary for RLAnimalHistoryRegistry. Kept separate for plain-Lua tests.
local Log = RmLogging.getLogger("RLRM")
RLAnimalHistorySerialization = { XML_BASE_KEY = "rm_RlAnimalHistory" }

local function writeDate(xmlFile, key, date)
    if date == nil then return end
    if date.day ~= nil then xmlFile:setInt(key .. "#day", date.day) end
    if date.month ~= nil then xmlFile:setInt(key .. "#month", date.month) end
    if date.year ~= nil then xmlFile:setInt(key .. "#year", date.year) end
end
function RLAnimalHistorySerialization.saveToXMLFile(xmlFile, baseKey, registry)
    if xmlFile == nil or registry == nil then return 0 end
    local records = registry:recordsSorted()
    for index, record in ipairs(records) do
        local key = string.format("%s.record(%d)", baseKey, index - 1)
        xmlFile:setString(key .. "#id", record.id); xmlFile:setString(key .. "#origin", record.origin or "unknown")
        xmlFile:setString(key .. "#snapshotKind", record.snapshotKind or "observed"); xmlFile:setInt(key .. "#births", record.births or 0); xmlFile:setInt(key .. "#offspring", record.offspring or 0)
        for trait, value in pairs(record.birthGenetics or {}) do xmlFile:setFloat(key .. ".birthGenetics#" .. trait, value) end
        writeDate(xmlFile, key .. ".lastBirth", record.lastBirth)
        if record.death ~= nil then xmlFile:setString(key .. ".death#reason", record.death.reason or "unknown"); writeDate(xmlFile, key .. ".death", record.death) end
        local diseaseIndex = 0; for title, count in pairs(record.diseases or {}) do xmlFile:setString(string.format("%s.disease(%d)#title", key, diseaseIndex), title); xmlFile:setInt(string.format("%s.disease(%d)#count", key, diseaseIndex), count); diseaseIndex = diseaseIndex + 1 end
    end
    Log:debug("RLAnimalHistorySerialization: saved %d record(s)", #records); return #records
end
function RLAnimalHistorySerialization.loadFromXMLFile(xmlFile, baseKey, registry)
    if xmlFile == nil or registry == nil then return 0 end
    local loaded = 0
    xmlFile:iterate(baseKey .. ".record", function(_, key)
        local id = xmlFile:getString(key .. "#id")
        if id == nil or id == "" then return end
        local record = { id = id, origin = xmlFile:getString(key .. "#origin") or "unknown", snapshotKind = xmlFile:getString(key .. "#snapshotKind") or "observed", births = xmlFile:getInt(key .. "#births", 0), offspring = xmlFile:getInt(key .. "#offspring", 0), birthGenetics = {}, diseases = {} }
        for _, trait in ipairs({ "metabolism", "fertility", "health", "quality", "productivity" }) do local value = xmlFile:getFloat(key .. ".birthGenetics#" .. trait); if value ~= nil then record.birthGenetics[trait] = value end end
        local day = xmlFile:getInt(key .. ".lastBirth#day"); if day ~= nil then record.lastBirth = { day = day, month = xmlFile:getInt(key .. ".lastBirth#month"), year = xmlFile:getInt(key .. ".lastBirth#year") } end
        local reason = xmlFile:getString(key .. ".death#reason"); if reason ~= nil then record.death = { reason = reason, day = xmlFile:getInt(key .. ".death#day"), month = xmlFile:getInt(key .. ".death#month"), year = xmlFile:getInt(key .. ".death#year") } end
        xmlFile:iterate(key .. ".disease", function(_, diseaseKey) local title = xmlFile:getString(diseaseKey .. "#title"); if title ~= nil then record.diseases[title] = xmlFile:getInt(diseaseKey .. "#count", 1) end end)
        if registry:observe(record) then local stored = registry.records[id]; stored.births = record.births; stored.offspring = record.offspring; stored.lastBirth = record.lastBirth; stored.death = record.death; stored.diseases = record.diseases; loaded = loaded + 1 end
    end)
    Log:debug("RLAnimalHistorySerialization: loaded %d record(s)", loaded); return loaded
end
g_rlAnimalHistoryRegistry = g_rlAnimalHistoryRegistry or RLAnimalHistoryRegistry.new()
