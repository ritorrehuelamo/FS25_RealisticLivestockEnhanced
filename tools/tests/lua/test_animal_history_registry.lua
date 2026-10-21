local Registry = dofile("scripts/animal/RLAnimalHistoryRegistry.lua") or RLAnimalHistoryRegistry

local registry = Registry.new()
assert(registry:observe({ id = "ES 1 1", origin = "born", snapshotKind = "birth", birthGenetics = { health = 1.1, fertility = 0.9 } }))
assert(not registry:observe({ id = "ES 1 1", origin = "unknown" }))
assert(registry:recordBirth("ES 1 1", 2, { day = 4, month = 6, year = 3 }))
assert(registry:recordDisease("ES 1 1", "Mastitis"))
assert(registry:recordDeath("ES 1 1", "rl_death_health", { day = 5, month = 6, year = 3 }))

local record = registry:get("ES 1 1")
assert(record.origin == "born")
assert(record.births == 1 and record.offspring == 2)
assert(record.lastBirth.day == 4 and record.diseases.Mastitis == 1)
assert(record.death.reason == "rl_death_health")
record.diseases.Mastitis = 99
assert(registry:get("ES 1 1").diseases.Mastitis == 1)

print("test_animal_history_registry: OK")
