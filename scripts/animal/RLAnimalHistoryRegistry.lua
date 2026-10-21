--[[
    RLAnimalHistoryRegistry.lua
    Compact, durable decision facts for individual animals. Dynamic values such
    as sale price are intentionally not stored here: callers calculate them live.
]]

RLAnimalHistoryRegistry = {}
RLAnimalHistoryRegistry.__index = RLAnimalHistoryRegistry

local function known(value) return type(value) == "string" and value ~= "" and value ~= "-1" end
local function copyGenetics(value)
    local copy = {}
    for _, trait in ipairs({ "metabolism", "fertility", "health", "quality", "productivity" }) do
        if type(value) == "table" and type(value[trait]) == "number" then copy[trait] = value[trait] end
    end
    return copy
end
local function copyRecord(record)
    local diseases, genetics = {}, copyGenetics(record.birthGenetics)
    for title, count in pairs(record.diseases or {}) do diseases[title] = count end
    local monthly = {}
    for index, snapshot in ipairs(record.monthly or {}) do monthly[index] = { month = snapshot.month, year = snapshot.year, weight = snapshot.weight, health = snapshot.health, sellValue = snapshot.sellValue, dailyGain = snapshot.dailyGain, foodLiters = snapshot.foodLiters } end
    return {
        id = record.id, origin = record.origin, snapshotKind = record.snapshotKind,
        birthGenetics = genetics, births = record.births or 0, offspring = record.offspring or 0,
        lastBirth = record.lastBirth and { day = record.lastBirth.day, month = record.lastBirth.month, year = record.lastBirth.year } or nil,
        death = record.death and { reason = record.death.reason, day = record.death.day, month = record.death.month, year = record.death.year } or nil,
        diseases = diseases,
        monthly = monthly,
    }
end

function RLAnimalHistoryRegistry.new() return setmetatable({ records = {} }, RLAnimalHistoryRegistry) end
function RLAnimalHistoryRegistry:get(id) local record = self.records[id]; return record and copyRecord(record) or nil end
function RLAnimalHistoryRegistry:recordsSorted()
    local records = {}; for _, record in pairs(self.records) do table.insert(records, copyRecord(record)) end
    table.sort(records, function(a, b) return a.id < b.id end); return records
end
function RLAnimalHistoryRegistry:observe(record)
    if type(record) ~= "table" or not known(record.id) then return false end
    if self.records[record.id] ~= nil then return false end
    self.records[record.id] = {
        id = record.id, origin = record.origin or "unknown", snapshotKind = record.snapshotKind or "observed",
        birthGenetics = copyGenetics(record.birthGenetics), births = 0, offspring = 0, diseases = {}, monthly = {},
    }
    return true
end
function RLAnimalHistoryRegistry:recordMonthly(id, snapshot)
    local record = self.records[id]
    if record == nil or type(snapshot) ~= "table" or snapshot.month == nil or snapshot.year == nil then return false end
    local monthly = record.monthly
    local previous = monthly[#monthly]
    local entry = { month = snapshot.month, year = snapshot.year, weight = snapshot.weight, health = snapshot.health, sellValue = snapshot.sellValue, foodLiters = snapshot.foodLiters }
    if previous ~= nil and type(previous.weight) == "number" and type(entry.weight) == "number" then entry.dailyGain = (entry.weight - previous.weight) / math.max(1, snapshot.days or 1) end
    if previous ~= nil and previous.month == entry.month and previous.year == entry.year then monthly[#monthly] = entry else table.insert(monthly, entry) end
    while #monthly > 24 do table.remove(monthly, 1) end
    return true
end
function RLAnimalHistoryRegistry:recordBirth(id, offspring, date)
    local record = self.records[id]; if record == nil then return false end
    record.births = record.births + 1; record.offspring = record.offspring + math.max(0, tonumber(offspring) or 0)
    if type(date) == "table" then record.lastBirth = { day = date.day, month = date.month, year = date.year } end
    return true
end
function RLAnimalHistoryRegistry:recordDisease(id, title)
    local record = self.records[id]; if record == nil or type(title) ~= "string" or title == "" then return false end
    record.diseases[title] = (record.diseases[title] or 0) + 1; return true
end
function RLAnimalHistoryRegistry:recordDeath(id, reason, date)
    local record = self.records[id]; if record == nil then return false end
    record.death = { reason = reason or "unknown", day = date and date.day, month = date and date.month, year = date and date.year }; return true
end

