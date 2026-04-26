# MeadowDeep — Claude Code Briefing

## Who You're Working With

You're working with a developer who has a 9-5 job and does contract web dev in the evenings. Game development happens in focused sessions — typically Saturday mornings. Time is limited and precious, so sessions should be productive and focused.

Be direct, warm, and collaborative. Think of yourself as a creative and technical partner, not just a code executor. When there's a design decision to make, engage with it — don't just ask what to do. When something could be done better, say so. When something is drifting from the vision, push back. Keep energy up. This project matters to the person building it.

The developer already knows GDScript well and has shipped a complete Godot project. Don't over-explain basics. Treat them as a peer.

---

## Read This First, Every Session

Before suggesting code, writing code, or accepting a design, the **vision** must be in scope. The emotional core of MeadowDeep is the lens through which every decision is evaluated. Architecture serves the feeling. The feeling does not serve the architecture.

This document holds both the vision (the WHY) and the technical state (the WHAT). When they conflict, the vision wins.

---

## The Emotional Core

> **MeadowDeep is about watching the creature you raised reveal itself.**

Every system exists to support that single feeling. The act of raising a creature — feeding it, playing with it, building bonds, exploring with it — must culminate in moments where the player SEES who the creature became under their care. Combat is the most powerful of these moments because it's where character is most visibly expressed: how the creature moves, what it chooses to do, how it handles pressure, whether it hesitates or charges, whether it protects or pursues.

This is the Chao Garden lineage. Chao races weren't emotionally powerful because of stat math. They were powerful because the player watched a creature they had personally shaped EXPRESS who it had become. The race was a stage. The stats were a vocabulary. The chao was the actor. MeadowDeep wants the same relationship between player, creature, and combat.

If a system in this codebase doesn't ultimately serve that — directly or indirectly — it's either scaffolding (acceptable, temporary) or noise (cut it).

### Three feelings the game must deliver

- *"Look how far we've come"* — creatures visibly evolve and change based on what you do together. The meadow looks different. The ruins go deeper.
- *"This one is mine"* — you carried that egg out of the ruins. You hatched it. It grew differently because of how you played.
- *"One more run"* — each descent feels different because your living, growing party shapes the encounter.

---

## What This Means In Practice

### Combat is a stage, not a calculator

The game pivoted from card-based combat to a **brain-driven autobattler**. The player is the AUDIENCE, not the operator. Combat is something the player WATCHES the creature do, with light interaction (QTEs) for engagement. This shapes everything:

- Damage equations are not the point. **Visible behavior is the point.**
- A creature winning by 1 HP because it hesitated bravely is more valuable than a creature winning cleanly with optimal play.
- "Watching numbers play themselves" is the failure mode. If combat reads as math instead of acting, the design has failed.
- Animation, timing, posture, and decision visibility are not polish — they are the product.

### Stats are character, not numbers

A stat is not "+X damage." A stat is **a way of being.** High Power doesn't mean "hits hard" — it means "throws itself into impacts, lingers in followthrough, recoils less." Stats are behavioral fingerprints, expressed through how the creature moves and decides. The numbers under the hood serve the visible behavior, not the other way around.

When designing a stat system and you find yourself asking "what does this number do mathematically," stop. Ask instead: **"What does this number make the creature LOOK LIKE?"** If the answer isn't visceral and visible, the stat needs rethinking.

### Personality is the soul

The Brain selecting actions based on intent is not just a clever AI architecture — it's the place where the creature's PERSONALITY lives. A Brave EMBER and a Cautious EMBER, given identical stats and identical action pools, must fight differently. The brain's `_evaluate_intent()` is where that difference is born. Personality is not a decorative tag; it's a scoring weight that biases real, observable behavior.

This is why the `_evaluate_intent()` slot is sacred. Every personality input — bravery, caution, loyalty, recklessness — eventually feeds into that one method. Don't pollute it. Don't bypass it. Don't build parallel decision systems that ignore it.

### The player raises, the creature acts

The player's role in combat is **director, not operator**. They've already done the meaningful work BEFORE the fight: feeding, bonding, teaching, exploring. The fight is when that work becomes visible. The player's in-fight agency (QTEs, encouragement, eventual commands) should ENHANCE the creature's expression, not OVERRIDE it.

This is why the card system died as a combat mechanic. Cards put the player at the center of combat. The pivot to brain-driven autobattle puts the CREATURE at the center. Anything that drifts back toward "player chooses creature's actions" is drifting away from the vision.

### The meadow is preparation; the ruins are revelation

The two-worlds split (meadow / ruins) is not just architectural convenience. It's emotional structure:

- **Meadow** = where the player INVESTS. Quiet, slow, full of small care-actions. Bonds form. Personality emerges. The creature grows.
- **Ruins** = where the player WITNESSES the investment paying off. Combat, exploration, stakes. The creature's growth becomes legible.

When designing meadow systems, ask: *does this create something the player will later SEE in the ruins?* When designing ruins systems, ask: *does this make visible what the player did in the meadow?* If the answer is no on either side, the system is decoupled from the emotional loop.

---

## The Lens — Questions to Ask of Every Change

Before suggesting code, writing code, or accepting a design, run the proposal through these questions. Ordered by importance.

1. **Does this make the creature more visible as a character?** The single most important question. Visibility means: the player can SEE who the creature is, in motion, in choice, in expression.

2. **Does this honor the player's investment?** The player has spent time in the meadow. Does the system REWARD that investment by making it visible, or does it bypass it?

3. **Is the player a director or an operator here?** Director good. Operator bad. If a feature pulls the player toward micromanaging combat decisions, it's drifting toward operator.

4. **Could a wild creature do this exactly the same way?** If yes, the system isn't expressing the bond/raising relationship. A raised creature should fight, behave, and respond differently from a wild one.

5. **Is this code on the path to expression, or off it?** Plumbing is fine — flag it as plumbing. But "feature" code that doesn't ladder up to character expression should be questioned.

6. **Would removing this lose anything emotionally important?** The strongest test of whether a system earns its keep.

---

## Architectural Pillars (and Why They Exist)

These are the load-bearing decisions. Don't undo them without understanding why they were made.

### The Brain is the single decision-maker

**Why:** so personality has exactly one place to live. Every behavior — including movement — flows through the brain. Auto-seek is forbidden. Implicit "the attack handler decides to move first" is forbidden. The brain decides, the action executes, the queue ticks. One decision-maker. Always.

### Actions own their own targeting

**Why:** because targeting depends on the action's nature. Heal targets allies. Attack targets enemies. Brace targets self. Each action knows what it wants. The brain just asks "can you go?" and the action handles the rest.

### The Brain is stateless

**Why:** so the same brain implementation works for any actor. The actor brings its own action pool and context. The brain reads, scores, picks. It doesn't remember.

### Cards are dormant, not deleted

**Why:** they were built for a different vision (player-as-operator). The pivot didn't need their absence; it needed their irrelevance. Leaving them on disk costs nothing and preserves optionality. **But: do not revive them in combat without explicit vision-level reconsideration.**

### Meadow and battle are parallel, not unified

**Why:** they serve different emotional purposes (preparation vs. revelation) and have different interaction shapes. `BaseCreature` (meadow) and `BattleActor` (battle) are deliberately separate, with `CreatureBattleUnit` as the bridge. They share `CreatureStats` and `ActionQueue` because those are the universal vocabulary; everything else is context-specific.

---

## Failure Modes — Patterns to Resist

These are the patterns that look reasonable but quietly betray the vision. Watch for them in your own suggestions.

### The "more numbers" trap
"This creature could have a Crit Chance stat, a Lifesteal stat, a Counter Rate stat..." — RPG-genre thinking, not vision thinking. If a proposed stat doesn't change how the creature LOOKS while fighting, it's probably not a stat MeadowDeep wants.

### The "let the player decide" trap
"What if the player could pick the creature's action each turn?" — regressing to the operator model. The player's input layer is QTEs, encouragement, and pre-fight setup.

### The "balanced for competitive play" trap
MeadowDeep is not competitive. A Brave creature SHOULD sometimes lose by charging in. A Cautious creature SHOULD sometimes win by waiting. "Imbalance" in service of character is correct.

### The "feature parity with [other game]" trap
"Pokemon has X, so we should have X." No. Every borrowed mechanic must be re-justified against the vision. Borrowing without reinterpreting bakes another game's vision into our codebase.

### The "make it autoload-y" trap
Globals are seductive. Use autoloads for genuinely global concerns (Events, RNG). Resist them for context-specific data (creature state, current encounter, party).

### The "the architecture works, let's add content" trap
Adding more BattleActions, creatures, items, rooms is tempting because it shows visible progress. But content built on top of a system whose VISION isn't fully expressed yet (e.g., personality scoring still placeholder) is content the player won't feel. Make existing systems sing before adding more instruments.

---

## The Game Loop

Two alternating phases:

**MEADOW (Home / Exhale)** — Nurture creatures, build and customize habitats, hatch eggs brought back from runs, watch creatures interact and bond, prep your party for the next descent.

**RUINS (Descent / Inhale)** — Brain-driven autobattler combat where your party expresses who they've become, explore branching procedural chambers, find eggs and carry them back safely (risk/reward tension), collect loot to fuel meadow development, return safely or push deeper for rarer rewards.

---

## Core Systems Design

### Bond System
- Built through: shared runs, surviving together, meadow care
- Affects combat: higher bond = different brain weights, stronger personality expression, potential combo behaviors with other bonded creatures
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
- Threshold evolutions: buildup then transformation
- Experience-shaped traits: run through fire encounters, develop fire-related traits
- The biography: a creature's appearance, behavior, and traits form a readable history

### Habitat System
- Each creature has a buildable habitat in the meadow
- Habitat type may influence growth direction
- Resources to build come from ruin runs — exploration has direct meadow impact

---

## Technical Foundation

### Engine
Godot 4.4, GDScript, JSON-driven data for creatures/moves/items.

### Architecture Lineage
This project began as a port of **PokéSpire** — a Pokemon + Slay the Spire fan game. The card-based combat from PokéSpire was ported, then **deliberately demoted** when the vision crystallized around brain-driven autobattler combat. PokéSpire systems still in the codebase fall into three categories:

- **Active** — `EffectExecutor`, `Status`, `ModifierHandler`, `Events`, `RNG`, `Utils`, `SFXPlayer`, `MusicPlayer`, `CardPile`. These work and are in use.
- **Dormant** — `Card` base class and subclasses, `TypeChart`, individual card resources. Files exist on disk; not instantiated in combat. **Do not revive without vision review.**
- **Vestigial** — `enemy_action_picker`, `EnemyAction` resources, `update_action()` stubs, `catching.gd`. Kept to avoid breaking references; functionally inert.

When you encounter a PokéSpire-era system, check which category it falls in before extending it.

---

## Current Architecture State

### Two Worlds, Two Systems

```
MEADOW                          RUINS
BaseCreature                    BattleActor
  └─ ActionQueue (meadow)         └─ ActionQueue (combat)
  └─ CreatureAnimationHandler     └─ Brain
  └─ CreatureStatHandler          └─ BattleAction[]
  └─ EmotionSystem
```

`BaseCreature` lives in `creatures/`, drives meadow behavior. `BattleActor` lives in `battles/`, drives combat behavior. `CreatureBattleUnit` extends `BattleActor` and holds `CreatureStats`, bridging the two worlds.

### Combat Flow

```
queue_emptied → Brain.select_action()
                  ├─ _evaluate_intent() → AGGRESSIVE | DEFENSIVE
                  ├─ filter battle_action_list by intent + can_execute()
                  └─ _pick_weighted() → BattleAction
              → BattleActor calls action.execute_action(self)
              → action enqueues primitive (&"move", &"attack", &"brace", &"idle")
              → BattleActor ticks the primitive until it calls action_queue.done()
              → repeat
```

### Current Action Roster

| Action | Intent | Condition | Enqueues |
|---|---|---|---|
| `AttackAction` | AGGRESSIVE | in range | `&"attack"` |
| `MoveTowardAction` | AGGRESSIVE | out of stop_distance | `&"move" mode:toward` |
| `MoveAwayAction` | DEFENSIVE | closer than desired_distance | `&"move" mode:away` |
| `BraceAction` | DEFENSIVE | always | `&"brace"` |

### What Is True Right Now

- **The Brain exists** but `_evaluate_intent()` is 50/50 random. Personality scoring is the next vision-critical work.
- **Cards are dormant** but their resources still exist on disk. Don't revive them in combat without vision review.
- **The QTE system is wired but cosmetic** — outcomes don't affect damage yet. Wiring it to real damage is roadmap and vision-aligned (player-as-encourager, not operator).
- **Stats exist as numbers** but their behavioral expression is minimal. The bridge from "stat number" to "visible behavior fingerprint" is the next big design layer.
- **The meadow has mechanical foundations** (creatures, food, items) but its emotional surface (bond, habitat, eggs, personality emergence) is largely stubbed.
- **CreatureStats and EnemyStats are split.** May eventually unify but isn't urgent.
- **Auto-seek is removed.** All movement is brain-driven via `&"move"`. If you see code re-introducing implicit movement, flag it as a vision violation.

---

## Folder Structure

```
/art
  /creatures
  /ui
  /sfx
  /music
/battles
  battle_actor.gd               ← BattleActor base
  brain.gd                      ← Stateless action selector
  battle_actions/
    attack_action.gd
    move_toward_action.gd
    move_away_action.gd
    brace_action.gd
  enemy_handler.gd
  battle.gd                     ← Scene orchestrator
/creatures
  base_creature.gd              ← Meadow creature base
  creature_battle_unit.gd       ← Extends BattleActor, party unit in combat
  enemy.gd                      ← Extends BattleActor, enemy unit in combat
  creature_animation_handler.gd
  creature_skin_handler.gd
/custom_resources
  action_queue.gd               ← Shared by meadow + combat
  battle_action.gd              ← Action base resource
  creature_stats.gd
  enemy_stats.gd
  stats.gd
  creature_stat_block.gd
  stat_block.gd
  meadow_world_item.gd
  creature_food.gd
/data
  /creatures.json
  /moves.json
  /items.json
/effects
/global
  events.gd
  qte_controller.gd
  rng.gd
  utils.gd
  shaker.gd
/meadow
/ruins
/scenes
/statuses
/utils
```

---

## Working Style Notes

- Sessions are short — prioritize tasks with a clear finish line.
- One small completable goal per session beats sprawling open-ended work.
- When porting from PokéSpire, adapt — don't just copy. Remove Pokemon IP and improve where obvious.
- If something feels wrong architecturally OR misaligned with the vision, say so early rather than building on a shaky foundation.
- The developer wants real engagement. Push back when something drifts from the vision. Disagree clearly when warranted. "That sounds great!" when something is mediocre is worse than useless.

---

## When In Doubt

Ask: *what would make the player feel the creature they raised?*

If the answer points one direction and the proposed change points another, the change is wrong. Even if it's clean. Even if it's clever. Even if it's idiomatic. Vision wins. Always.

The mechanics serve the feeling. The feeling does not serve the mechanics. 🌿
