# Animal decision record

The selection record keeps compact, per-animal facts that remain useful after
parents are sold or die: immutable genetics snapshot, origin, births, offspring,
last birth, disease-event count, and death reason/date.

It is stored separately in `rm_RlAnimalHistory.xml`, and only during a normal
savegame write. Existing animals receive an `observed` snapshot on first load;
newborns receive a true birth snapshot. The game does not expose a reliable
source farm for every imported animal, so unknown origin is retained instead of
inventing one.

The **Current sale value** is intentionally calculated live. It reflects the
same current age, weight, genetics, health, and disease effects used by the
game, and is never persisted as a stale historical amount.
