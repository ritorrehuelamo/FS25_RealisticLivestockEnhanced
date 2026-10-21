assert(loadfile("scripts/animal/RLAnimalIdMigrationAudit.lua"))()

local audit = RLAnimalIdMigrationAudit.new()
audit:beginRun()
assert(audit:record("Cattle barn", "ES 1 1", "ES 700 123", "COW"))
assert(not audit:record("Cattle barn", "ES 1 1", "ES 1 1", "COW"))
assert(audit.lastRepairCount == 1)

local entries = audit:entriesSorted()
assert(entries[1].pen == "Cattle barn")
assert(entries[1].oldId == "ES 1 1")
assert(entries[1].newId == "ES 700 123")

audit:beginRun()
assert(audit.previousRepairCount == 1)
assert(audit.lastRepairCount == 0)
assert(#audit:entriesSorted() == 1)

print("test_animal_id_migration_audit: OK")
