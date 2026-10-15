# FS25 Realistic Livestock Enhanced

FS25 Realistic Livestock Enhanced is a GPL-3.0 fork of Ritter's maintained version of [Realistic Livestock RM](https://github.com/rittermod/FS25_RealisticLivestockRM), itself based on Arrow-kb's original [Realistic Livestock](https://github.com/Arrow-kb/FS25_RealisticLivestock). It replaces FS25's simple animal clusters with individually tracked animals, each with their own genetics, reproduction, health, growth, and production state.

The project evolves the existing, stable individual-animal simulation into a deeper livestock-management experience. Genetic selection, reproduction, nutrition, health, production, growth, and farm economics will be developed as connected systems, through small and testable releases.

## Documentation

The included [user guide](docs/user-guide/index.md) documents the inherited baseline. Enhanced-specific documentation will be added alongside each approved milestone.

> [!IMPORTANT]
> The roadmap below describes planned work, not features already present in a release. The current source baseline is upstream `1.4.1.0-dev.3`; the first stable release of this fork will be `1.0.0`.

## Project Roadmap

Each milestone is a separately releasable module. Work starts only after its design, compatibility impact, migration path, and tests have been reviewed.

| Planned version | Module | Scope |
| --- | --- | --- |
| `1.0.0` | Enhanced baseline | First stable release of the fork: GPL attribution, distinct project identity, documented compatibility boundaries, and validated packaging, loading, save/load, and rollback procedure. |
| `1.1.0` | Pedigree and safe breeding | Persistent ancestry, kinship detection, configurable warnings and blocks for high-risk pairings, and Herdsman safeguards. |
| `1.2.0` | Reproduction and genetic planning | Pairing plans, reproductive calendars, AI selection tools, and breeding-program indicators. |
| `1.3.0` | Dairy production | Individual lactation state, production history, dry periods, and transparent production indicators. |
| `1.4.0` | Nutrition and growth | Stage-specific requirements, feed-efficiency indicators, growth and finishing analysis, designed around existing feed mods. |
| `1.5.0` | Animal health | Individual health histories, prevention and treatment workflows, and production or fertility consequences. |
| `1.6.0` | Livestock economics | Individual costs and income, margins, and a clear distinction between recorded game costs and optional economic estimates. |
| `1.7.0` | Management interface and automation | Pedigree views, management dashboards, alerts, and Herdsman extensions built on the preceding modules. |

## Release automation

Releases are created only from pull requests into `main`; contributors never commit releases directly to `main`.

- Use a Conventional Commit title. `feat:` creates the next minor version, `fix:` the next patch version, and `!` or a `BREAKING CHANGE:` footer creates the next major version.
- A PR intended for release must use the `release` label and contain non-empty `## Summary` and `## Validation` sections. Its title and description are reused as the GitHub release title and notes.
- While that PR is open, each eligible update creates a tested GitHub pre-release named `vX.Y.Z-rc.N`.
- Once the labelled PR is merged into `main`, the workflow creates the corresponding final `vX.Y.Z` release and its mod ZIP plus `SHA256SUMS.txt` checksum.

The first stable release is `v1.0.0`; inherited upstream tags are deliberately not used to number this fork.

## First feature milestone: `1.1.0` — Pedigree and safe breeding

The first module will preserve ancestry independently from whether an animal is still alive or owned, calculate known kinship, and apply a configurable breeding policy:

- Block high-risk pairings by default: parent-offspring, siblings, and grandparent-offspring.
- Warn and require confirmation for more distant known relationships.
- Do not block a pairing solely because historical data is incomplete.
- Apply the same policy to natural breeding, artificial insemination, and Herdsman automation.
- Preserve compatibility with existing saves through a forward-only migration and isolated savegame tests.

No game data or animal records are changed merely by documenting this milestone.

## Features

- Individual animal tracking with unique identity (farm ID, unique ID, birthday)
- Genetics system with heritable traits that affect production output
- Genetics display in animal names with configurable detail level (average score or full trait breakdown)
- Breeding and reproduction with pregnancy mechanics and genetic inheritance
- AI insemination system with semen dewars
- Disease simulation with nine diseases across cows, pigs, sheep, goats, chickens and horses - a hidden phase before symptoms on harder settings, spread within a pen, immunity, paid treatment and culling, with five difficulty levels and a per-disease on/off list
- Animal monitoring to track individual animals over time
- Weight system tied to genetics and feeding
- Animal marking and castration
- RL Menu: a standalone tabbed menu (default Right Shift + O, also opened from pens, dealers, and trailers) covering all animal management - animal browsing with pedigree/genetics/disease detail, moving, selling, buying, AI straw purchases, messages, and trailer loading/unloading
- Saveable animal filters: build reusable filters in-game (age, gender, pregnancy, genetics, weight, health, and more) and cycle them with F across the menu tabs
- Herdsman automation: named daily tasks (sell, buy, castrate, naming, AI insemination, move, horse care) driven by saved filters, with per-task caps, budgets, and a herdsman wage
- Animal Country of Origin setting: choose the country new animals are registered in (ear tags, identifiers)
- Dealer controls: choose which animals and age groups the dealer offers, and whether it stocks Budget, Standard or Premium quality animals
- Daily summary mode for message log
- In-game help pages covering monitors, pregnancy, production, weight, and genetics
- Highland cattle bull support
- Animal pack system: third-party mods can add new breeds or adjust animal balance
- Map support: Hof Bergmann (ducks, geese, cats, rabbits, alpacas, quail) with automatic version-aware compatibility
- Map support: Witcombe (UK breeds - Jersey, Gloucestershire Old Spot, Texel, Suffolk, Blue Faced Leicester, plus Hereford heritage profile) with automatic version-aware compatibility
- Map support: Le Mechet (French breeds - Charolaise, Montbeliarde, Simmental, Vosgienne) with automatic version-aware compatibility
- Simple support for butchers using Extended Production Point (EPP) mod
- Mod compatibility checks at startup: hard-block dialog for incompatible mods, plus a dismissible warning tier for mods known to degrade gameplay
- In-game warning when two map bridges or animal packs replace the same animal type's husbandry config (last-loaded wins; first one's animals can render as ghosts)
- Mod compatibility bridges for foreign mods that overlap the inherited baseline's hooks - currently coexists with Seasonal Wool Production (Argsy Gaming) without double wool output
- Multiplayer support (server-authoritative)

## Supported Maps & Packs

The Enhanced baseline works on virtually any map out of the box. It does not need to be on a list. The maps below are special only because they add their own custom animal types or breeds, which need built-in support for those extras to receive the full individual-animal treatment (genetics, breeding, reproduction). On any other map, the standard animals just work.

**Maps:**
- [Hof Bergmann](https://www.lsfarming-mods.com/) - ducks, geese, cats, rabbits, alpacas, quail with full breeding support
- [Witcombe](https://oxygendavid.itch.io/witcombe-park-farm) - UK breeds (Jersey, Gloucestershire Old Spot, Texel, Suffolk, Blue Faced Leicester) with full breeding support; Hereford heritage profile
- [Le Mechet](https://farming-simulator.com/mod.php?mod_id=357964) - French breeds (Charolaise, Montbeliarde, Simmental, Vosgienne) with full breeding support (NOT compatible with Cow Breeds Pack unless you use the latest development version - both replace the cow husbandry config)

**Animal Packs:**
- [Cow Breeds Pack for RLRM](https://github.com/ConGan98/FS25_CowBreedsRLRM) by ConGan98 - additional cattle breeds
- [Sheep Breeds Pack for RLRM](https://github.com/ConGan98/FS25_SheepBreedsRLRM) by ConGan98 - additional sheep breeds

## Notes

- The inherited baseline includes migration from Arrow-kb's original version; its behaviour under the Enhanced identity has not yet been validated.
- Font Library mod is no longer required (functionality has been inlined)
- Incompatible with FS25_EnhancedLivestock, FS25_MoreVisualAnimals, and FS25_EnhancedAnimalSystem (use FS25_MoreVisualAnimalsRM instead of FS25_MoreVisualAnimals)

## Installation

Release installation instructions will be published with the first Enhanced release. Until then, treat this repository as development source code; do not install it alongside `FS25_RealisticLivestockRM` in a production savegame.

**Migration:** Migration from Arrow-kb's or Rittermod's releases has not yet been validated for Enhanced. Do not load an existing production savegame until the `1.0.0` compatibility procedure has been published and tested on a copy.

## Changelog
See the [CHANGELOG](CHANGELOG.md) for a detailed list of changes, fixes, and improvements in this version.

## Credits

- Original project: [FS25 Realistic Livestock](https://github.com/Arrow-kb/FS25_RealisticLivestock) by [Arrow-kb](https://github.com/Arrow-kb) (v1.2.0.5), released under GPL-3.0.
- Maintained upstream: [FS25 Realistic Livestock RM](https://github.com/rittermod/FS25_RealisticLivestockRM) by Ritter, released under GPL-3.0.
- This project: FS25 Realistic Livestock Enhanced, a fork of the maintained upstream version. Contributions and their authors are recorded in this repository's Git history.
- The inherited disease-system changes are inspired by Renfordt's [Enhanced Livestock](https://github.com/renfordt/FS25_EnhancedLivestock), also released under GPL-3.0; some parts were converted directly from it.

## License
This mod is released under GPL-3 license. See the [LICENSE](LICENSE) file for details.




# About reuse, modification and building upon FS25 Realistic Livestock Enhanced

> [!NOTE]
> TL;DR: FS25 Realistic Livestock Enhanced is GPL-3.0 software based on GPL-3.0 projects. Anyone can use, modify, and redistribute it as long as they preserve the required notices, license the whole derivative work under GPL-3.0, and provide the corresponding source when distributing it.



This fork is derived from the original Realistic Livestock project by Arrow-kb and the maintained Realistic Livestock RM project by Ritter. Those projects and this fork are released under GPL-3.0. In practical terms, when distributing this fork or a modified version:

- You may use, study, modify, and redistribute the code for any purpose.
- Keep the applicable copyright, attribution, licence, and warranty notices.
- Clearly state that you modified the work and give a relevant date.
- License the complete derivative work under GPL-3.0 and include a copy of that licence.
- Provide the corresponding source code, including the scripts needed to build, install, and modify the distributed version.

This is a practical summary, not legal advice. The authoritative terms are in the [GPL-3.0 licence](LICENSE).
