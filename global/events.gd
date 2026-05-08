#events.gd
extends Node

signal tooltip_hide_requested

#Run Event Requested
signal scene_transition_requested(scene_id: String)

#Meadow Creature-related Events
signal trigger_action(creature, action, duration)
signal creature_stat_view_requested(creature_stats: CreatureStats)
signal creature_stat_view_dismissed(uid: String)
signal creature_stat_updated(uid: String)

# Item-related Events
signal item_aim_started(item)
signal item_aim_ended(item)
signal item_used(item)
signal item_picked_up(item, qty)
signal item_received(item)

# Player-related Events
signal player_hit
signal player_died

# Autobattle Events
signal combat_started
signal combat_ended

# Enemy-related Events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_fainted(enemy: Enemy)

# Battle-related Events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])
signal status_tooltip_hide_requested()
signal return_to_main_menu
signal battle_text_requested(text: String)
signal battle_text_completed()
signal camera_shake_requested(damage: int, intensity: float)

# Creature-related Events
signal party_creature_fainted(creature: CreatureBattleUnit)

# Reward-related Events
signal creature_reward_requested(creature_stats: CreatureStats)
signal creature_reward_completed

# Map-related Events
signal save_game(on_map: bool)
