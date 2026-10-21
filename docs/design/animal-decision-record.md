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

At the first day of each in-game month, the record also keeps a rolling 24-month
series of weight, health, live sale value, food litres and calculated daily
weight gain. Food cost is deliberately not inferred: a pen can consume a custom
mix, pasture or player-owned feed, none of which has one truthful per-animal
price in the game API. A future economic record must use an actual settled cost
source rather than presenting an estimate as a cost.
