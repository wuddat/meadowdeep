# MeadowDeep — Dev Notes

Running log of reminders, red flags, known issues, things to revisit, and decisions made mid-session.

---

## Decisions

- **`StatusHandler` redesigned from PokéSpire** — Original iterated `StatusUI` child nodes to find statuses (coupled logic to scene tree). MeadowDeep version uses an internal `_statuses: Array[Status]` for all logic lookups. `StatusUI` nodes are spawned only when `status_ui_scene` is set. Decouples combat logic from visual layer entirely.
- **`ArchaeologistStats`** — `CharacterStats` from PokéSpire renamed to `ArchaeologistStats`. This is the player character resource; holds party, deck, mana, cards_per_turn. Replaces `CharacterStats` everywhere.
- **`Archaeologist`** — `Player` node from PokéSpire renamed to `Archaeologist`. Holds `ArchaeologistStats`, StatusHandler, ModifierHandler. The final class name for the player character node is not decided but this is the working name per the design doc.
- **`CreatureBattleUnit`** — `PokemonBattleUnit` ported as `CreatureBattleUnit` in `creatures/`. `is_trainer_pkmn` renamed to `is_wild_creature` (false = party creature, true = enemy creature). `set_pokemon_stats` → `set_creature_stats`, `update_pokemon` → `update_creature`.
- **`evolution_triggered` signal emits `CreatureStats` not the battle unit** — In PokéSpire it emitted `PokemonBattleUnit` (the node). MeadowDeep's `Events.evolution_triggered` takes `CreatureStats` for cleaner data/scene separation.
- **Catching mechanics removed from `Enemy`** — Entire catch system stripped. No `is_catchable`, `is_caught`, `mark_as_caught`, `catch_animator`, catch sounds. MeadowDeep uses the egg system for acquisition.
- **`BattleStats` simplified** — PokéSpire had trainer types, boss battle, Mewtwo phase 2. MeadowDeep version has only `Wild`/`Boss` encounter types and `assign_creature_party()` using `CreatureData.get_species_for_depth()`.
- **`BattleOverPanel` stub created** — `scenes/battle/battle_over_panel.gd` is a stub that just defines the `Type { WIN, LOSE }` enum needed by `Events.battle_over_screen_requested`. Replace with full UI in Phase 1.
- **`battle.gd` evolution stripped** — Evolution cutscene, card-swap reward screen, and evolution queue all removed for Phase 0. `_on_evolution_triggered` and `_on_evolution_completed` are stubs that just print. Wired to the same signals so Phase 3 can hook in without changing the battle scene structure.
- **`effect.gd` (base class) moved to `effects/`** — In PokéSpire it lived in `custom_resources/`. Moved it into the `effects/` folder to keep all effect-related code together.
- **`species_id` kept as field name** — Neutral enough term, not Pokemon IP. Will carry over naturally into `CreatureStats`.
- **`catching.gd` ported as-is** — The catching mechanic is the PokéSpire analogue to MeadowDeep's egg extraction system. Ported for completeness but the design will need revisiting. See Revisit section.
- **Signals removed from `events.gd`** — `catch_attempted`, `catch_completed`, `pokemon_captured` (replaced by the future egg system), `mewtwo_phase_2_requested` (Mewtwo-specific). Any code referencing these will need updating when those systems are built.
- **Status move names kept for now** (`firespin`, `quiverdance`, etc.) — These are Pokemon IP in spirit but renaming them now would require updating `.tres` resource files, `STATUS_LOOKUP`, and move data all at once. Flagged for a content pass later.

---

## To Revisit

- **`catching.gd` / egg extraction mechanic** — The `Catching` status + `Events.catch_attempted` signal is the PokéSpire creature acquisition flow. In MeadowDeep this becomes the egg system (find egg in ruins, carry it home). The status may be repurposed, replaced, or removed entirely when the egg system is designed.
- **Status flavor names** (`firespin`, `quiverdance`, `seeded`, `chill`, `froze`, etc.) — These are Pokemon move names. Needs a content pass to replace with original MeadowDeep status names once the creature/element design is further along.
- **`ElementType` enum in `card.gd`** — Placeholder type names (VERDANT, EMBER, TIDE, etc.) were invented to replace the Pokemon types. These are not final — they need a proper pass once MeadowDeep's element system is designed. The TypeChart will also need to align with whatever lands here. `get_element_color()` and `ELEMENT_COLORS` will need updating at the same time. `CreatureStats.element_type` is a String to stay consistent with `Card.damage_type` — both resolve through TypeChart.
- **`StatBlock` grade multipliers are placeholders** — E=0.5, D=0.75, C=1.0, B=1.25, A=1.5, S=2.0. Tune once combat feel is testable.
- **Alignment axes are placeholder floats** — `wild_bonded_alignment` and `feral_mystic_alignment` on `CreatureStatBlock` are stubs (-1.0 to 1.0). Ranges, meaning, and how they affect gameplay not yet designed.
- **`bonds_with_creatures` not exported** — Dictionary on `CreatureStatBlock` mapping uid→bond score. Not `@export` because Godot can't serialise typed Dictionaries cleanly. Will need a custom save/load step.
- **`intelligence` and `luck` renamed to `mystic` and `focus`** — Changed during creature design session. Any old references to these field names on `CreatureStatBlock` will break.
- **`move_data.gd` `element_to_moves` uses Pokemon type strings** — Phase 0 uses PokéSpire's `move_list.json` so type keys are "grass", "fire", "water" etc., not MeadowDeep element names. `get_draft_cards_from_element()` on `CreatureStats` will return empty arrays until `move_list.json` is replaced with MeadowDeep content.
- **`move_list.json` needs to be copied from PokéSpire** — `move_data.gd` points at `res://data/move_list.json`. This file doesn't exist in MeadowDeep yet — copy it from `pokespireproj/data/move_list.json` to `data/move_list.json`.
- **WISP uses `shade` element type** — WISP felt like a shadow/ghost creature so it was given `element_type: "shade"` rather than a dedicated "wisp" type. Revisit if a distinct WISP element is designed.
- **`Events.catch_attempted`** — Signal referenced in `catching.gd` but removed from `events.gd` (egg system will replace it). Will error if triggered.
- **`EnemyActionPicker` / `EnemyAction` not yet ported** — `enemy.gd` and `enemy_handler.gd` reference these as untyped `Node`. Enemy AI will not function until these systems are ported (Phase 1).
- **`StatsUI` / `IntentUI` / `UnitStatusIndicator` not yet ported** — Referenced as `Node` in creature_battle_unit, enemy, and battle files. Stats/intent display will be invisible until these scenes are ported.
- **`Hand` / `BattleUI` not yet ported** — `PlayerHandler` and `Battle` reference these as `Node`. Card hand display and battle UI won't work until ported.
- **`Shaker` autoload** — Ported to `global/shaker.gd` but all `Shaker.shake(...)` calls are commented out until it's registered as an autoload in `project.godot`.
- **`SFXPlayer` not yet ported** — All `SFXPlayer.pitch_play(...)` / `SFXPlayer.play(...)` calls are commented out.
- **`MusicPlayer` not yet ported** — `MusicPlayer.play(music)` call in `battle.gd` is commented out.
- **`SaveData` not yet ported** — `SaveData.delete_data()` in `battle.gd` is commented out.
- **`queue_remove_on_next_damage` in StatusHandler is a stub** — Currently calls `remove_status` immediately. Proper implementation needs a signal from the unit's `take_damage` pathway. `vulnerable.gd` depends on this.
- **`Utils.get_evolution_options`** — References `creature.icon`, `creature.species_id`, `creature.uid` off `CreatureStats` — all three fields now exist, so this should resolve correctly.
- **Art asset paths** — All `preload("res://art/sounds/...")` paths are copied from PokéSpire. These will be broken until the art folder is populated or paths are updated.
- **`vulnerable.gd`** — Calls `target.status_handler.queue_remove_on_next_damage("vulnerable")`. This method may not exist on StatusHandler — needs verification when StatusHandler is ported.
- **`Player` class reference in `status_effect.gd`** — The `Player` class check (`target is Player`) is not Pokemon-specific but will need to become `Archaeologist` (or whatever the player character class ends up being called) when that system is built.

---

## Known Issues / Red Flags

- **`.tres` resource files not ported** — All status `.tres` files (e.g. `statuses/attack_up.tres`) exist in PokéSpire but have not been created in MeadowDeep. `StatusData` preloads these at startup — the project will error on load until they exist. These are Godot resource files that need to be created in-editor or copied and re-saved.
- **`primary_target` unused in `data/moves/power.gd`** — `apply_effects` captures `primary_target = targets[0]` but never passes it to any executor call. Harmless for now but dead code worth cleaning up.
- **`.tres` card resources not yet created** — `data/moves/attack.tres`, `block.tres`, `power.tres`, `shift.tres`, `status.tres` need to be created in-editor with the matching scripts attached before `Utils.create_card()` can load them.
- **No autoloads registered** — `StatusData`, `Events`, `RNG`, `SFXPlayer`, `Utils`, `MoveData` etc. need to be registered in `project.godot` as autoloads before they'll be accessible globally.

---

## Phase 0 Progress

- [x] `effects/` — Ported
- [x] `statuses/` — Ported (scripts only, `.tres` resources pending)
- [x] `custom_resources/status.gd` — Ported
- [x] `global/status_data.gd` — Ported
- [x] `ModifierHandler` — Ported (`modifier.gd`, `modifier_value.gd`, `modifier_handler.gd`)
- [x] `CardPile` — Ported
- [x] `Events` — Ported (4 signals removed, all pkmn→creature renamed)
- [x] `RNG` — Ported (clean lift)
- [x] `Utils` — Ported
- [x] `Card` base (`custom_resources/card.gd`) + subclasses (`data/moves/attack`, `block`, `power`, `shift`, `status`)
- [x] `CreatureStats` — Built (`stats.gd` base, `stat_block.gd`, `creature_stat_block.gd` identity record, `creature_stats.gd`)
- [x] Data loaders — `creature_data.gd`, `move_data.gd`, `data/creatures.json` (5 placeholder creatures)
- [x] Copy `move_list.json` from PokéSpire into `data/`
- [x] Battle system scripts ported — `StatusHandler`, `StatusUI`, `ArchaeologistStats`, `Archaeologist`, `CreatureBattleUnit`, `EnemyStats`, `BattleStats`, `BattleOverPanel` (stub), `PartyHandler`, `PlayerHandler`, `Enemy`, `EnemyHandler`, `Battle`, `Shaker`
- [ ] Battle scene wired up in Godot editor (create .tscn files, assign @export scene refs, register autoloads)
