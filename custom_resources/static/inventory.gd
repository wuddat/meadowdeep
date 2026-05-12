class_name Inventory
extends Resource

signal inventory_changed

@export var entries: Array[InventoryEntry] = []

func add_item(item: ItemDef, qty: int) -> void:
	if item == null or qty <= 0:
		return
	var existing := _find_entry(item)
	if existing:
		existing.qty += qty
	else:
		var entry := InventoryEntry.new()
		entry.item = item
		entry.qty = qty
		entries.append(entry)
	inventory_changed.emit()


func remove_item(item: ItemDef, qty: int) -> bool:
	if item == null or qty <= 0:
		return false
	var existing := _find_entry(item)
	if not existing or existing.qty < qty:
		return false
	existing.qty -= qty
	if existing.qty <= 0:
		entries.erase(existing)
	inventory_changed.emit()
	return true


func _find_entry(item: ItemDef) -> InventoryEntry:
	for entry in entries:
		if entry.item and item and entry.item.id == item.id:
			return entry
	return null
