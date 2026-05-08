class_name LootTable
extends Resource

@export var drops: Array[LootTableDrop]


func roll_drops() -> Array[InventoryEntry]:
	var results: Array[InventoryEntry] = []
	for drop in drops:
		if drop == null or drop.item == null:
			continue
		if RNG.instance.randf() > drop.drop_chance:
			continue
		var qty := RNG.instance.randi_range(drop.min_qty, drop.max_qty)
		if qty <= 0:
			continue
		var entry: InventoryEntry = InventoryEntry.new()
		entry.item = drop.item
		entry.qty = qty
		results.append(entry)
	return results
		
