#events.gd
extends Node

# Run / Scene
signal scene_transition_requested(scene_id: String)

# Meadow Creature stat view
signal creature_stat_view_requested(creature_stats: CreatureStats)
signal creature_stat_view_dismissed(uid: String)
signal creature_stat_updated(uid: String)

# Items
signal item_picked_up(item, qty)

# Player
signal player_died

# Combat lifecycle
signal combat_started
signal combat_ended

# Enemy
signal enemy_fainted(enemy: Enemy)

# Battle UI
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)

# Party
signal party_creature_fainted(creature: CreatureBattleUnit)
