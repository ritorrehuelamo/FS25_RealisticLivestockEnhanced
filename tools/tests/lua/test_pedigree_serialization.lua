RmLogging = {
    getLogger = function()
        return { debug = function() end, warning = function() end }
    end,
}

assert(loadfile("scripts/animal/RLPedigreeRegistry.lua"))()
assert(loadfile("scripts/animal/RLPedigreeSerialization.lua"))()

local xml = { values = {}, keys = {} }
function xml:setString(key, value) self.values[key] = value end
function xml:setInt(key, value) self.values[key] = value end
function xml:getString(key) return self.values[key] end
function xml:getInt(key) return self.values[key] end
function xml:iterate(_, callback)
    for _, key in ipairs(self.keys) do callback(nil, key) end
end

local original = RLPedigreeRegistry.new()
assert(original:record({ id = "dam", typeIndex = 1 }))
assert(original:record({ id = "sire", typeIndex = 1 }))
assert(original:record({ id = "calf", motherId = "dam", fatherId = "sire", typeIndex = 1 }))

local baseKey = RLPedigreeSerialization.XML_BASE_KEY
assert(RLPedigreeSerialization.saveToXMLFile(xml, baseKey, original) == 3)
xml.keys = {
    baseKey .. ".record(0)", baseKey .. ".record(1)", baseKey .. ".record(2)",
}

local restored = RLPedigreeRegistry.new()
assert(RLPedigreeSerialization.loadFromXMLFile(xml, baseKey, restored) == 3)
assert(restored:relationship("dam", "calf") == "direct")
assert(restored:get("calf").fatherId == "sire")

local legacyXml = { values = {}, keys = {} }
function legacyXml:setString(key, value) self.values[key] = value end
function legacyXml:setInt(key, value) self.values[key] = value end
function legacyXml:getString(key) return self.values[key] end
function legacyXml:getInt(key) return self.values[key] end
function legacyXml:iterate(_, callback)
    for _, key in ipairs(self.keys) do callback(nil, key) end
end

local legacyBaseKey = RLPedigreeSerialization.LEGACY_XML_BASE_KEY
assert(RLPedigreeSerialization.saveToXMLFile(legacyXml, legacyBaseKey, original) == 3)
legacyXml.keys = {
    legacyBaseKey .. ".record(0)", legacyBaseKey .. ".record(1)", legacyBaseKey .. ".record(2)",
}
local migrated = RLPedigreeRegistry.new()
assert(RLPedigreeSerialization.loadFromXMLFile(legacyXml, legacyBaseKey, migrated) == 3)
assert(migrated:relationship("dam", "calf") == "direct")
