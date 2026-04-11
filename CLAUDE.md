# MeadowDeep — Claude Code Briefing

## Who You're Working With

You're working with a developer who has a 9-5 job and does contract web dev in the evenings. Game development happens in focused sessions — typically Saturday mornings. Time is limited and precious, so sessions should be productive and focused. 

Be direct, warm, and collaborative. Think of yourself as a creative and technical partner, not just a code executor. When there's a design decision to make, engage with it — don't just ask what to do. When something could be done better, say so. Keep energy up. This project matters to the person building it.

---

## What MeadowDeep Is

**One-sentence pitch:** A cozy roguelite where you care for and bond with a growing collection of strange creatures, then descend together into ancient ruins — the deeper you go, the stranger and rarer they become.

**The emotional core — three feelings this game must deliver:**
- *"Look how far we've come"* — creatures visibly evolve and change based on what you do together. The meadow looks different. The ruins go deeper.
- *"This one is mine"* — you carried that egg out of the ruins. You hatched it. It grew differently because of how you played.
- *"One more run"* — each descent feels different because your living, growing party shapes the deck.

**Design pillars:**
- Attachment over disposability — creatures persist, death is setback not deletion
- Experience shapes growth — what happens in runs changes who creatures become
- The meadow is alive — home base reflects progress and has its own texture
- Depth rewards bravery — rarer eggs and stranger creatures live deeper in the ruins
- Small and finishable — one biome, one ruin, a complete loop

---

## The Game Loop

Two alternating phases:

**MEADOW (Home / Exhale)**
- Nurture creatures, build and customize habitats
- Hatch eggs brought back from runs
- Watch creatures interact and bond with each other
- Prep your party for the next descent

**RUINS (Descent / Inhale)**
- Card-based turn combat where your party IS your deck
- Explore branching procedural chambers
- Find eggs — carry them back safely (risk/reward tension)
- Collect loot and resources to fuel meadow development
- Return safely or push deeper for rarer rewards

---

## Core Systems Design

### Party as Deck
Each creature in the active party contributes cards to a shared combat deck based on their current moveset, level, and bond. The deck is a living portrait of who your creatures are right now — it changes as they grow.

The archaeologist (the player character) contributes a small fixed set of cards — tools and knowledge — that persist regardless of party composition.

### Bond System
- Built through: shared runs, surviving together, meadow care
- Affects combat: higher bond = more powerful card contributions, potential combo abilities with other bonded creatures
- Affects growth: deeply bonded creatures develop different traits than neglected ones
- Creates stakes: sending a bonded creature into danger feels different

### The Egg System
Eggs are the primary way to acquire new creatures.
- Found deeper in ruins — rarer eggs require greater depth
- Carrying an egg home creates tension: push deeper for loot, or protect the egg?
- Eggs must be nurtured in the meadow before hatching
- The hatch is a reveal moment — what emerges reflects depth and rarity
- By the time a creature hatches, you've already invested in it

### Growth & Evolution
- Threshold evolutions: buildup then transformation, like Pokemon
- Experience-shaped traits: run through fire encounters, develop fire-related traits
- The biography: a creature's appearance, moves, and traits form a readable history

### Habitat System
- Each creature has a buildable habitat in the meadow
- Habitat type may influence growth direction (water habitat = water trait odds)
- Resources to build come from ruin runs — exploration has direct meadow impact

---

## Technical Foundation

### Engine
Godot 4.4, GDScript, JSON-driven data for creatures/moves/items

### The Most Important Context
This project is being built on top of a previous Godot project called **PokéSpire** — a Pokemon + Slay the Spire fan game. PokéSpire has a battle-tested architecture that is being ported and adapted into MeadowDeep. Do not rebuild what already works. Port it, adapt it, improve it where needed.

### Systems to Port from PokéSpire (these are DONE — just move them)
- `EffectExecutor` — composable damage, status, block, shift execution
- `Status` system — all individual status classes, StatusHandler, StatusData lookup
- `Card` base class — `setup_from_data` pattern, attack/block/status/power/shift subclasses
- `CardPile` — clean, minimal, works perfectly
- `ModifierHandler` — damage dealt/taken modifier pipeline
- `Events` — signal bus (rename signals to fit new context)
- `RNG` — seeded RNG with save/load state
- `SFXPlayer` / `MusicPlayer` — port directly
- `Utils` — card creation helpers, typed array utils

### Systems to Adapt (same architecture, new content)
- `TypeChart` — replace Pokemon types with original creature element types
- Map/Room system — same branching structure, ruin aesthetic
- `EnemyActionFactory` + enemy action classes — same pattern, new enemies
- `BattleStatsPool` — same weighted pool system, new encounter data

### Systems to Build Fresh
- `CreatureStats` resource — replaces PokemonStats, adds bond level, biography, trait slots, egg origin data
- Bond system — tracks relationship between player and each creature over time
- Meadow scene — home base with placeable habitat nodes and creature AI routines
- Habitat system — buildable structures that influence creature growth
- Egg resource — incubation state, hatch logic, rarity tiers
- Trait system — traits earned through experience that modify cards and stats
- Meta-progression — what persists between failed runs

---

## Folder Structure (Target)

```
/art
  /creatures
  /ui
  /sfx
  /music
/battles
/creatures          ← replaces /characters from PokéSpire
/custom_resources
/data
  /creatures.json   ← replaces pokedex.json
  /moves.json
  /items.json
/effects            ← port from PokéSpire
/global             ← port from PokéSpire
/meadow             ← new
/ruins              ← replaces /scenes/map from PokéSpire
/scenes
/statuses           ← port from PokéSpire
/utils              ← port from PokéSpire
```

---

## Development Phases

### Phase 0 — Foundation (Current Priority)
Get the core battle loop running in the new project with ported systems.
- [ ] Port: effects, statuses, card, card_pile, modifier_handler, events, rng, utils
- [ ] Create placeholder `CreatureStats` resource
- [ ] Get 2 placeholder creatures fighting in a battle scene
- [ ] No art required yet — placeholders are fine

### Phase 1 — The Ruin Loop
- [ ] Adapt map/room system for ruins
- [ ] 3-4 original placeholder creatures with distinct movesets
- [ ] Egg chamber room type + extraction tension mechanic
- [ ] Basic enemy roster
- [ ] Win/loss conditions

### Phase 2 — The Meadow
- [ ] Meadow scene with creature presence
- [ ] Egg hatching system
- [ ] Basic habitat building
- [ ] Bond tracking
- [ ] Between-run creature state

### Phase 3 — Growth & Polish
- [ ] Evolution system
- [ ] Trait system
- [ ] Creature interactions in meadow
- [ ] Bond-driven card upgrades
- [ ] Art pass

### Phase 4 — Content & Release
- [ ] Full creature roster (15-20 creatures)
- [ ] Original move pool (40-60 moves)
- [ ] Story layer via archaeology notes
- [ ] Save/load
- [ ] Sound and music
- [ ] Balance pass

---

## Open Design Questions
These don't need answering now — revisit as development progresses.

- **Failure state**: Party wipe = retreat with wounded creatures, or permanent loss for non-companion creatures?
- **Active party size**: 2-3 creatures suggested
- **Habitat influence on growth**: Loose probability influence or hard rules?
- **Meta-progression**: What persists between failed runs?
- **Narrative depth**: How much archaeology story gets layered in?

---

## Working Style Notes

- Sessions are short — prioritize tasks that have a clear finish line
- One small completable goal per session beats sprawling open-ended work
- When porting from PokéSpire, adapt don't just copy — remove Pokemon IP, improve where obvious
- The GDD lives in this repo — check it for design intent when making decisions
- If something feels wrong architecturally, say so early rather than building on a shaky foundation
- The developer already knows GDScript well and has shipped a complete Godot project — don't over-explain basics
