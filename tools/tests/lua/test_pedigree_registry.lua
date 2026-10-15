assert(loadfile("scripts/animal/RLPedigreeRegistry.lua"))()

local function registry(records)
    local result = RLPedigreeRegistry.new()
    for _, record in ipairs(records) do assert(result:record(record)) end
    return result
end

local family = registry({
    { id = "grandmother", typeIndex = 1 },
    { id = "grandfather", typeIndex = 1 },
    { id = "mother", motherId = "grandmother", fatherId = "grandfather", typeIndex = 1 },
    { id = "aunt", motherId = "grandmother", fatherId = "grandfather", typeIndex = 1 },
    { id = "daughter", motherId = "mother", typeIndex = 1 },
    { id = "niece", motherId = "aunt", typeIndex = 1 },
    { id = "unrelated", typeIndex = 1 },
    { id = "goat", typeIndex = 2 },
})

assert(family:relationship("mother", "daughter") == "direct")
assert(family:relationship("mother", "aunt") == "direct")
assert(family:relationship("grandmother", "daughter") == "close")
assert(family:relationship("mother", "niece") == "close")
assert(family:relationship("daughter", "niece") == "extended")
assert(family:relationship("daughter", "unrelated") == "unknown")
assert(family:relationship("daughter", "goat") == "unrelated")

local safeClose = family:evaluate("mother", "niece", RLPedigreeRegistry.POLICY.SAFE)
assert(safeClose.allowed == false and safeClose.relationship == "close")
local legacyClose = family:evaluate("mother", "niece", RLPedigreeRegistry.POLICY.LEGACY_DIRECT)
assert(legacyClose.allowed == true and legacyClose.warning == false)
local strictCousins = family:evaluate("daughter", "niece", RLPedigreeRegistry.POLICY.STRICT)
assert(strictCousins.allowed == false and strictCousins.relationship == "extended")

local cycle = registry({
    { id = "cycleA", motherId = "cycleB", typeIndex = 1 },
    { id = "cycleB", fatherId = "cycleA", typeIndex = 1 },
})
assert(cycle:relationship("cycleA", "cycleB") == "direct")
assert(cycle:relationship("cycleA", "missing") == "unknown")
