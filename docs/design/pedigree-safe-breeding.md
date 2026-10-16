# Pedigree and safe breeding (`1.1.0`) design

## Goal

Extend the existing individual-animal parent links into a durable pedigree system
that identifies related pairings before conception. The same decision must be
used by manual insemination, pen breeding, and Herdsman automation.

The module prevents accidental inbreeding. It does not introduce genetic
penalties, change pregnancy odds, or alter animal genetics; those remain
separate future design work.

## Existing baseline

The baseline already stores `motherId` and `fatherId` on animals, unborn
animals, save data, and multiplayer streams. It displays parents in the RL
menu and rejects an AI straw when it is the animal's recorded father.

That is not sufficient for safe breeding: it does not retain ancestry after an
animal leaves a herd, cannot identify siblings or grandparents, and is not a
single rule shared by all breeding paths.

## Pedigree record

`RLPedigreeRegistry` will own immutable records keyed by the existing full
animal identifier. A record contains only:

- the animal identifier;
- `motherId` and `fatherId`, when known;
- species/type information needed to reject cross-species comparisons.

The registry is append-only. A sold, dead, or moved animal keeps its record,
so its descendants remain safe to evaluate. The animal object remains the
source of current gameplay state; the registry is genealogy only.

At load time the registry is populated from saved registry data and reconciled
with all currently loaded animals and unborn animals. New births add records
before they can become breeding candidates.

## Relationship policy

The evaluator walks known parents to a bounded depth of three generations and
returns a deterministic result:

| Result | Examples | Default action |
| --- | --- | --- |
| `unknown` | one or both branches have no recorded parents | allow, with no invented risk |
| `unrelated` | no common known ancestor in the search depth | allow |
| `direct` | parent/offspring, full or half siblings | block |
| `close` | grandparent/grandchild, aunt or uncle with niece or nephew | block |
| `extended` | first cousins or another shared ancestor within the configured depth | warn |

The default policy is **Safe**, preventing direct and close pairings while
allowing an extended pairing with a clear warning. The server administrator can
change **Breeding relationship policy** in the RL settings to **Direct
relatives only** (legacy behaviour) or **Strict** (also blocks extended
relationships). The setting is saved with the game and applies identically to
manual AI, natural breeding, and Herdsman actions. It never turns unknown
ancestry into a block: old saves and purchased animals frequently lack history.

## One authoritative gate

A single pure Lua predicate receives two animal identifiers and returns
`allowed`, a relationship class, and an explanation key. It becomes the
authoritative gate for:

- manual AI straws and the existing `getCanBeInseminatedByAnimal` check;
- natural pen breeding before a pregnancy is created;
- Herdsman planning and execution, so an eligible-looking candidate cannot
  bypass the manual rule;
- UI warnings and messages, including a final server-side validation when an
  insemination event arrives.

The server executes the decision. Clients receive the existing result/event
flow and translated reason only; they do not author pedigree data.

## Migration and compatibility

Pedigree history is stored in its own `rm_RlPedigree.xml` file. It is written
only with the savegame, so changing a mod setting never rewrites the full
historical registry. Early `1.1.0` release candidates used a
`rm_RlSettings.pedigree` subtree; the loader reads that location only when the
standalone file does not exist, then the next save writes `rm_RlPedigree.xml`.

This is a forward-only, non-destructive save migration. Existing animals keep
their current parent IDs. Missing parent IDs remain unknown; no guessed lineage
is generated and no existing pregnancy is cancelled. The registry is written
only after a successful save, and an old save without registry data is valid
input.

Multiplayer stream changes, if required for the registry, must be versioned or
sent from the server after the registry is complete. A mixed-version session
is unsupported, as with any gameplay mod update.

## Test plan

Automated Lua domain tests will cover:

1. unknown lineage and unrelated animals are allowed;
2. parent/offspring, full siblings, and half siblings are blocked;
3. grandparent and aunt/uncle relationships are classified as close;
4. first cousins are classified as extended;
5. an ancestry cycle or malformed identifier terminates safely;
6. policy modes produce the documented allow/warn/block decision;
7. Herdsman and manual callers receive the same decision.

Manual FS25 verification in the release PR will cover:

- a new save with manual AI and natural pen breeding;
- save/reload after a birth, sale, and death, then a related pairing;
- Herdsman AI with a related candidate and a valid alternative;
- multiplayer server/client interaction and a fresh `log.txt` without errors.

## Delivery slices

1. Registry, relationship evaluator, and Lua tests.
2. Save/load migration and network integration.
3. Manual and Herdsman gates, settings, messages, and RL-menu warnings.
4. RC manual verification, then the `feat(pedigree):` release PR for `1.1.0`.
