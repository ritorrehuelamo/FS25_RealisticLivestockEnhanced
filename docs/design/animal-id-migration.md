# Fallback animal-ID migration

Some existing saves can load livestock before the owning farm is available. The
old fallback pair `farmId=1` and `uniqueId=1` is repaired at mission startup.

Every successful repair now logs the pen, old identifier, new identifier and
animal type, marks the animal dirty for the next normal save, and is persisted
to `rm_RlAnimalIdMigration.xml`. The next startup compares against that saved
migration: it logs a pass only when there are zero further repairs and logs an
error if another repair is required.

The migration does not guess relationship rewrites when multiple animals shared
the same fallback identifier. A guessed parent would create incorrect ancestry;
the existing historical reference remains available for audit and the animal is
instead treated as ancestry not verifiable. The safe-breeding policy therefore
never converts ambiguity into a false clean pedigree.

## Required FS25 verification

1. Load the affected save and note every `Fallback ID migration` line.
2. Save normally, reload the same save, and require the log line `stability
   check passed: 0 repairs`.
3. Compare `rm_RlPedigree.xml` before and after: all pre-existing entries must
   remain present.
4. Create a birth, sell a parent, save and reload; the child must still show
   both stored parent identifiers.
