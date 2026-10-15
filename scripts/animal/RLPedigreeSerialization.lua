--[[
    RLPedigreeSerialization.lua
    XML boundary for the durable, append-only pedigree registry.

    Kept separate from RLPedigreeRegistry so relationship decisions remain
    plain Lua and can be exercised without Farming Simulator's XML runtime.
]]

local Log = RmLogging.getLogger("RLRM")

RLPedigreeSerialization = {}
RLPedigreeSerialization.XML_BASE_KEY = "rm_RlSettings.pedigree"

local RECORD_VERSION = 1

local function writeRecord(xmlFile, key, record)
    xmlFile:setString(key .. "#id", record.id)
    xmlFile:setString(key .. "#motherId", record.motherId)
    xmlFile:setString(key .. "#fatherId", record.fatherId)
    if record.typeIndex ~= nil then xmlFile:setInt(key .. "#typeIndex", record.typeIndex) end
    xmlFile:setInt(key .. "#version", RECORD_VERSION)
end

local function readRecord(xmlFile, key)
    local id = xmlFile:getString(key .. "#id")
    if id == nil or id == "" or id == "-1" then
        Log:warning("RLPedigreeSerialization: missing id at %s; skipping record", tostring(key))
        return nil
    end

    return {
        id = id,
        motherId = xmlFile:getString(key .. "#motherId"),
        fatherId = xmlFile:getString(key .. "#fatherId"),
        typeIndex = xmlFile:getInt(key .. "#typeIndex"),
    }
end

function RLPedigreeSerialization.saveToXMLFile(xmlFile, baseKey, registry)
    if xmlFile == nil or registry == nil then return 0 end

    local records = registry:recordsSorted()
    for index, record in ipairs(records) do
        writeRecord(xmlFile, string.format("%s.record(%d)", baseKey, index - 1), record)
    end
    Log:debug("RLPedigreeSerialization: saved %d record(s)", #records)
    return #records
end

function RLPedigreeSerialization.loadFromXMLFile(xmlFile, baseKey, registry)
    if xmlFile == nil or registry == nil then return 0 end

    local loaded = 0
    xmlFile:iterate(baseKey .. ".record", function(_, key)
        local record = readRecord(xmlFile, key)
        if record ~= nil and registry:record(record) then loaded = loaded + 1 end
    end)
    Log:debug("RLPedigreeSerialization: loaded %d record(s)", loaded)
    return loaded
end

g_rlPedigreeRegistry = g_rlPedigreeRegistry or RLPedigreeRegistry.new()
