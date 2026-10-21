-- XML boundary for the fallback-ID migration audit.
local Log = RmLogging.getLogger("RLRM")
RLAnimalIdMigrationSerialization = { XML_BASE_KEY = "rm_RlAnimalIdMigration" }

function RLAnimalIdMigrationSerialization.saveToXMLFile(xmlFile, baseKey, audit)
    if xmlFile == nil or audit == nil then return 0 end
    xmlFile:setInt(baseKey .. "#runs", audit.runs or 0)
    xmlFile:setInt(baseKey .. "#lastRepairCount", audit.lastRepairCount or 0)
    local entries = audit:entriesSorted()
    for index, entry in ipairs(entries) do
        local key = string.format("%s.entry(%d)", baseKey, index - 1)
        xmlFile:setString(key .. "#pen", entry.pen); xmlFile:setString(key .. "#oldId", entry.oldId)
        xmlFile:setString(key .. "#newId", entry.newId); xmlFile:setString(key .. "#type", entry.type)
    end
    Log:debug("RLAnimalIdMigrationSerialization: saved %d ID repair entry(s)", #entries)
    return #entries
end

function RLAnimalIdMigrationSerialization.loadFromXMLFile(xmlFile, baseKey, audit)
    if xmlFile == nil or audit == nil then return 0 end
    local entries = {}
    xmlFile:iterate(baseKey .. ".entry", function(_, key)
        local oldId, newId = xmlFile:getString(key .. "#oldId"), xmlFile:getString(key .. "#newId")
        if oldId ~= nil and newId ~= nil then table.insert(entries, { pen = xmlFile:getString(key .. "#pen") or "unknown", oldId = oldId, newId = newId, type = xmlFile:getString(key .. "#type") or "unknown" }) end
    end)
    audit:restore(xmlFile:getInt(baseKey .. "#runs", 0), xmlFile:getInt(baseKey .. "#lastRepairCount", 0), entries)
    Log:debug("RLAnimalIdMigrationSerialization: loaded %d ID repair entry(s)", #entries)
    return #entries
end
