# MeadowDeep — Item System Refactor: Wire-In-Now Tasks

You are working on **MeadowDeep**, a Godot 4 creature-raising roguelite. You are a senior systems architect. Your job is to execute a targeted refactor that lays the foundation for an expandable item system. Do not add features beyond what is specified. Do not change battle systems, enemy logic, or anything outside the files listed.

---

## Context: What exists today

### `custom_resources/creature_food.gd`
```gdscript
class_name CreatureFood
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EXOTIC }

@export var name: String
@export var durability: int
@export var creature_attribute: StatBlock.StatType
@export var attribute_increment: int
@export var rarity: Rarity
@export var value: int
@export var art: Texture2D = preload("res://art/game_art/items/berry.png")
```

### `scenes/meadow/creature_food_item.gd`
```gdscript
class_name CreatureFoodItem
extends Area2D

@export var food_data: CreatureFood

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const CARRY_OFFSET := Vector2(0, -10)

@export var stages: int = 5

var is_carried := false
var _carrier: Node2D = null
var being_eaten := false
var _total_stages: int = 0

func _ready() -> void:
    add_to_group("food")
    if food_data and food_data.art:
        sprite.texture = food_data.art
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
    if is_carried and _carrier:
        global_position = _carrier.global_position + CARRY_OFFSET

func decrement_stage() -> void:
    if stages <= 0:
        return
    stages -= 1
    scale = Vector2.ONE * (float(stages) / float(_total_stages))

func pickup(carrier: Node2D) -> void:
    is_carried = true
    _carrier = carrier
    collision_shape.disabled = true

func start_eating() -> void:
    being_eaten = true
    _total_stages = stages

func drop() -> void:
    is_carried = false
    _carrier = null
    collision_shape.call_deferred("set_disabled", false)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        body.nearby_food = self

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player") and body.get("nearby_food") == self:
        body.nearby_food = null
```

### `creatures/creature_stat_handler.gd`
```gdscript
extends Node

signal stat_changed

var stat_block: CreatureStatBlock

func apply_food(food_data: CreatureFood) -> void:
    if not stat_block or not food_data:
        return
    var stat_name: String = CreatureData.STAT_NAMES.get(food_data.creature_attribute, "")
    if not stat_name:
        return
    var stat: StatBlock = stat_block.get(stat_name)
    if stat:
        stat.points += food_data.attribute_increment
        stat_changed.emit()
```

### `creatures/base_creature.gd` (relevant excerpt — food handling)
```gdscript
func _tick_eat_food(data: Dictionary, delta: float) -> void:
    data["timer"] -= delta
    data["stage_timer"] = data.get("stage_timer", 0.0) + delta
    if data["stage_timer"] >= 1.0 and _eating_food:
        data["stage_timer"] -= 1.0
        _eating_food.decrement_stage()
        var food_data: CreatureFood = _eating_food.get("food_data")
        if food_data:
            creature_stat_handler.apply_food(food_data)
    # ... rest of method unchanged

func receive_food(food_item: Node2D, from_player: Node2D) -> void:
    from_player.set("carried_food", null)
    from_player.set("nearby_food", null)
    if food_item.has_method("drop"):
        food_item.drop()
    if food_item.has_method("start_eating"):
        food_item.start_eating()
    food_item.global_position = global_position + Vector2(5, 5)
    _eating_food = food_item
    _food = null
    _action_queue = _action_queue.filter(
        func(e): return e["id"] != &"seek_food" and e["id"] != &"eat_food"
    )
    _push_action_front(&"eat_food", {
        "timer": randf_range(action_duration_min, action_duration_max)
    })
```

### `custom_resources/creature_stat_block.gd` (relevant excerpt)
```gdscript
class_name CreatureStatBlock
extends Resource

# ... existing fields (PWR, AGI, RES, MYS, FOC, personality, bonds, history, etc.)
# You will ADD fields here. Do not remove anything existing.
```

### `global/events.gd` (relevant excerpt)
```gdscript
# Item-related Events
signal item_aim_started(item)
signal item_aim_ended(item)
signal item_used(item)
signal item_added(item)
# You will ADD a signal here.
```

---

## Your Tasks

Execute all five tasks in order. Output the **complete file** for every file you touch — no partial diffs, no pseudocode.

---

### Task 1 — Create `MeadowWorldItem` base resource

**File:** `custom_resources/meadow_world_item.gd`

Create this as a new file. `CreatureFood` will extend it in Task 2.

Requirements:
- `class_name MeadowWorldItem`, `extends Resource`
- `enum Rarity { COMMON, UNCOMMON, RARE, EXOTIC }` (moves here from `CreatureFood`)
- `enum ItemCategory { FOOD, TOY, MEDICINE, RELIC }`
- Exported fields: `id: String`, `display_name: String`, `description: String`, `rarity: Rarity`, `category: ItemCategory`, `value: int`, `art: Texture2D`
- A virtual method stub: `func get_category() -> ItemCategory: return category`
- Export groups: group `"Identity"` for id/display_name/description, group `"Economy"` for rarity/value, group `"Visuals"` for art

---

### Task 2 — Migrate `CreatureFood` to extend `MeadowWorldItem`

**File:** `custom_resources/creature_food.gd`

Rewrite to extend `MeadowWorldItem`. Rules:
- Remove `Rarity` enum (now inherited from `MeadowWorldItem`)
- Remove `name` field — use inherited `display_name`
- Remove `value` field — use inherited `value`
- Remove `art` field — use inherited `art`
- Keep `durability: int`, `creature_attribute: StatBlock.StatType`, `attribute_increment: int`
- In `_init()`, set `category = ItemCategory.FOOD`
- Keep all export groups clean and sensible
- Do NOT change `StatBlock.StatType` — that enum stays where it is

---

### Task 3 — Create `WorldItemBase` scene script

**File:** `scenes/meadow/world_item_base.gd`

This replaces the standalone logic in `CreatureFoodItem` with a reusable base. `CreatureFoodItem` will extend this in Task 4.

Requirements:
- `class_name WorldItemBase`, `extends Area2D`
- `@export var item_data: MeadowWorldItem` — typed to the base resource
- `const CARRY_OFFSET := Vector2(0, -10)`
- All vars: `is_carried: bool`, `_carrier: Node2D`, `being_eaten: bool`
- `@onready var sprite: Sprite2D = $Sprite2D`
- `@onready var collision_shape: CollisionShape2D = $CollisionShape2D`
- `_ready()`: add to group `"items"` (NOT "food" — that moves to subclass), set sprite texture from `item_data.art` if present, connect `body_entered` / `body_exited`
- `_process(delta)`: carry offset logic
- `pickup(carrier: Node2D)`: set is_carried, _carrier, disable collision
- `drop()`: clear is_carried, _carrier, deferred re-enable collision
- `_on_body_entered(body)`: if body is in group "player", set `body.nearby_food = self` — keep this name for now for compatibility
- `_on_body_exited(body)`: clear `body.nearby_food` if it matches self
- `on_delivered(creature: Node) -> void`: calls `creature.creature_stat_handler.apply_item(item_data)` — this is the key dispatch hook. Also emits `Events.item_used.emit(item_data)` if Events autoload exists.
- Add a `## Override in subclasses to add delivery-specific behavior.` docstring above `on_delivered`

---

### Task 4 — Migrate `CreatureFoodItem` to extend `WorldItemBase`

**File:** `scenes/meadow/creature_food_item.gd`

Rewrite to extend `WorldItemBase`. Rules:
- Remove everything that is now in `WorldItemBase`: `CARRY_OFFSET`, `is_carried`, `_carrier`, `being_eaten`, `item_data` (now typed as `food_data: CreatureFood` via a local accessor — see below), `_ready` body re: groups/sprite/signals, `_process`, `pickup`, `drop`, `_on_body_entered`, `_on_body_exited`
- Keep `@export var food_data: CreatureFood` as a typed convenience export — in `_ready()` assign `item_data = food_data` so the base class works correctly
- Keep `stages: int`, `_total_stages: int`, `decrement_stage()`, `start_eating()`
- In `_ready()`: call `super._ready()`, add to group `"food"` (subclass-specific), assign `item_data = food_data`
- Override `on_delivered(creature: Node) -> void`: call `super.on_delivered(creature)` — food delivery is handled by the base routing; the stage-based eating loop remains driven by `_tick_eat_food` in `base_creature.gd` which calls `apply_food` directly, so this override just ensures the signal fires

---

### Task 5 — Update `CreatureStatHandler` and `CreatureStatBlock`

**File:** `creatures/creature_stat_handler.gd`

Add `apply_item()` as the new primary dispatch method. Keep `apply_food()` intact and call it from the dispatch — do not break existing calls in `base_creature.gd`.

Requirements:
- Add signal: `item_received(item: MeadowWorldItem)`
- Add method:
  ```gdscript
  func apply_item(item: MeadowWorldItem) -> void:
      if not item:
          return
      match item.category:
          MeadowWorldItem.ItemCategory.FOOD:
              apply_food(item as CreatureFood)
          MeadowWorldItem.ItemCategory.TOY:
              pass  # stub — ToyItem not yet implemented
          MeadowWorldItem.ItemCategory.MEDICINE:
              pass  # stub — MedicineItem not yet implemented
          MeadowWorldItem.ItemCategory.RELIC:
              pass  # stub — RelicItem not yet implemented
      item_received.emit(item)
  ```
- Keep `apply_food(food_data: CreatureFood)` exactly as-is

**File:** `custom_resources/creature_stat_block.gd`

Add the following fields only. Do not remove or reorder anything existing. Add them in a new export group at the bottom:

```gdscript
@export_group("Item History")
@export var total_items_received: int = 0
@export var total_meals_eaten: int = 0
# item_id (String) → total times received (int)
var item_affinity: Dictionary = {}
```

**File:** `global/events.gd`

Add one signal under the Item-related Events section:
```gdscript
signal item_received(item)
```

---

## Constraints

- **Do not touch** `base_creature.gd`. The existing `apply_food()` call path in `_tick_eat_food` must keep working unchanged.
- **Do not touch** `player.gd`, `creature_stats.gd`, `creature_data.gd`, or any battle system files.
- **Do not create** `ToyItem`, `MedicineItem`, or `RelicItem` resources — stubs in the match statement are sufficient.
- **Do not create** `items.json` or `ItemData` autoload — those are separate tasks.
- All GDScript must be valid Godot 4.x syntax. Use `@export`, not `export`. Use `func` not `def`.
- Preserve all existing comments and export groups in files you modify.
- Output each file as a complete code block labeled with its path.
