--[[
    RLAnimalIdMigrationAudit.lua
    Server-side audit trail for fallback ID repairs. It deliberately records the
    legacy and resulting identifier without rewriting ambiguous relationship
    links: an unknown parent is safer than a confidently wrong one.
]]

RLAnimalIdMigrationAudit = {}
RLAnimalIdMigrationAudit.__index = RLAnimalIdMigrationAudit

local function copyEntry(entry)
    return { pen = entry.pen, oldId = entry.oldId, newId = entry.newId, type = entry.type }
end

function RLAnimalIdMigrationAudit.new()
    return setmetatable({ runs = 0, previousRepairCount = 0, lastRepairCount = 0, entries = {} }, RLAnimalIdMigrationAudit)
end

function RLAnimalIdMigrationAudit:beginRun()
    self.previousRepairCount = self.lastRepairCount or 0
    self.lastRepairCount = 0
    self.runs = (self.runs or 0) + 1
end

function RLAnimalIdMigrationAudit:record(pen, oldId, newId, animalType)
    if type(oldId) ~= "string" or type(newId) ~= "string" or oldId == newId then return false end
    table.insert(self.entries, { pen = pen or "unknown", oldId = oldId, newId = newId, type = animalType or "unknown" })
    self.lastRepairCount = self.lastRepairCount + 1
    return true
end

function RLAnimalIdMigrationAudit:entriesSorted()
    local entries = {}
    for _, entry in ipairs(self.entries) do table.insert(entries, copyEntry(entry)) end
    table.sort(entries, function(a, b)
        if a.pen == b.pen then return a.oldId < b.oldId end
        return a.pen < b.pen
    end)
    return entries
end

function RLAnimalIdMigrationAudit:restore(runs, lastRepairCount, entries)
    self.runs = tonumber(runs) or 0
    self.lastRepairCount = tonumber(lastRepairCount) or 0
    self.entries = entries or {}
end

g_rlAnimalIdMigrationAudit = g_rlAnimalIdMigrationAudit or RLAnimalIdMigrationAudit.new()
