# Project Logic Roadmap

Project Logic grows as a shared puzzle platform. A new game is only added after
the common systems needed by the existing games are stable.

## v0.9 – Platform foundation

- shared game, mode, and difficulty identities
- game-aware result and statistics data
- split oversized UI and Hashi foundation files by responsibility
- preserve all existing local save data
- common presentation components for repeated game controls

## Existing games

### Binairo

- expand the curated catalog across sizes and difficulties
- stress-test generated puzzles over large deterministic seed sets
- grade difficulty by required solving techniques, not clue count alone
- retain catalog, endless, and daily modes

### Hashi

- expand the curated catalog before relying on generation
- separate domain logic, persistence, catalog data, and presentation
- add a solver with uniqueness checks
- add generation and technique-based difficulty grading
- connect daily, missions, XP, streaks, and shared statistics

## Planned order

1. Slitherlink
2. Hitori
3. Futoshiki
4. Kakuro
5. Nurikabe

Every game should eventually provide a tested catalog, an endless generator,
daily puzzles, save/resume, hints, statistics, and accessible phone controls.

## First Play Store release

The initial production release does not require every planned game. Two
polished games with substantial catalogs and reliable endless modes are the
preferred scope. Store preparation includes Android App Bundle signing,
current target API compliance, privacy and data declarations, store assets,
closed testing, crash checks, and testing on multiple phone sizes.
