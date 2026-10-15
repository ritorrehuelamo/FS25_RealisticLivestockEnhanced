--[[
    RLPedigreeRegistry.lua
    Durable, game-independent pedigree records and pairing decisions.

    This module deliberately has no GIANTS API dependencies so the relationship
    rules can be tested outside Farming Simulator and shared by every breeding
    entry point.
]]

RLPedigreeRegistry = {}
RLPedigreeRegistry.__index = RLPedigreeRegistry

RLPedigreeRegistry.POLICY = {
    LEGACY_DIRECT = "legacyDirect",
    SAFE = "safe",
    STRICT = "strict",
}

local function isKnownId(value)
    return type(value) == "string" and value ~= "" and value ~= "-1"
end

local function copyRecord(record)
    return {
        id = record.id,
        motherId = record.motherId,
        fatherId = record.fatherId,
        typeIndex = record.typeIndex,
    }
end

function RLPedigreeRegistry.new()
    return setmetatable({ records = {} }, RLPedigreeRegistry)
end

function RLPedigreeRegistry:clear()
    self.records = {}
end

function RLPedigreeRegistry:record(record)
    if type(record) ~= "table" or not isKnownId(record.id) then return false end

    local existing = self.records[record.id]
    if existing ~= nil then
        -- Parent links are immutable. A later observation may fill a missing
        -- type index but cannot rewrite ancestry from an older save or client.
        if existing.typeIndex == nil and record.typeIndex ~= nil then
            existing.typeIndex = record.typeIndex
        end
        return false
    end

    self.records[record.id] = {
        id = record.id,
        motherId = isKnownId(record.motherId) and record.motherId or nil,
        fatherId = isKnownId(record.fatherId) and record.fatherId or nil,
        typeIndex = record.typeIndex,
    }
    return true
end

function RLPedigreeRegistry:get(id)
    local record = self.records[id]
    return record ~= nil and copyRecord(record) or nil
end

function RLPedigreeRegistry:recordsSorted()
    local records = {}
    for _, record in pairs(self.records) do table.insert(records, copyRecord(record)) end
    table.sort(records, function(a, b) return a.id < b.id end)
    return records
end

function RLPedigreeRegistry:_ancestors(id, maxDepth)
    local root = self.records[id]
    if root == nil then return {}, true end

    local ancestors, queue, unknown = {}, { { id = id, depth = 0 } }, false
    local cursor = 1

    while cursor <= #queue do
        local current = queue[cursor]
        cursor = cursor + 1
        if current.depth < maxDepth then
            local record = self.records[current.id]
            if record == nil then
                unknown = true
            else
                local parents = { record.motherId, record.fatherId }
                local foundParent = false
                for _, parentId in ipairs(parents) do
                    if isKnownId(parentId) then
                        foundParent = true
                        local depth = current.depth + 1
                        if ancestors[parentId] == nil or depth < ancestors[parentId] then
                            ancestors[parentId] = depth
                            table.insert(queue, { id = parentId, depth = depth })
                        end
                    end
                end
                if not foundParent then unknown = true end
            end
        end
    end

    return ancestors, unknown
end

function RLPedigreeRegistry:relationship(firstId, secondId, maxDepth)
    maxDepth = maxDepth or 3
    if not isKnownId(firstId) or not isKnownId(secondId) then return "unknown" end
    if firstId == secondId then return "direct" end

    local first, second = self.records[firstId], self.records[secondId]
    if first == nil or second == nil then return "unknown" end
    if first.typeIndex ~= nil and second.typeIndex ~= nil and first.typeIndex ~= second.typeIndex then
        return "unrelated"
    end

    local firstAncestors, firstUnknown = self:_ancestors(firstId, maxDepth)
    local secondAncestors, secondUnknown = self:_ancestors(secondId, maxDepth)
    local closest = nil

    if firstAncestors[secondId] ~= nil then closest = firstAncestors[secondId] end
    if secondAncestors[firstId] ~= nil then
        closest = math.min(closest or math.huge, secondAncestors[firstId])
    end
    if closest ~= nil then
        return closest == 1 and "direct" or "close"
    end

    local sharedDistance = nil
    for ancestorId, firstDepth in pairs(firstAncestors) do
        local secondDepth = secondAncestors[ancestorId]
        if secondDepth ~= nil then
            local distance = firstDepth + secondDepth
            if sharedDistance == nil or distance < sharedDistance then sharedDistance = distance end
        end
    end

    if sharedDistance ~= nil then
        if sharedDistance == 2 then return "direct" end -- full or half siblings
        if sharedDistance <= 3 then return "close" end -- aunt/uncle and niece/nephew
        return "extended"
    end

    return (firstUnknown or secondUnknown) and "unknown" or "unrelated"
end

function RLPedigreeRegistry:evaluate(firstId, secondId, policy, maxDepth)
    local relationship = self:relationship(firstId, secondId, maxDepth)
    policy = policy or RLPedigreeRegistry.POLICY.SAFE

    local blocked = relationship == "direct"
        or (policy ~= RLPedigreeRegistry.POLICY.LEGACY_DIRECT and relationship == "close")
        or (policy == RLPedigreeRegistry.POLICY.STRICT and relationship == "extended")

    return {
        allowed = not blocked,
        warning = relationship == "extended" and not blocked,
        relationship = relationship,
        reason = blocked and ("rl_pedigree_" .. relationship) or nil,
    }
end
