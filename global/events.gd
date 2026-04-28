#events.gd
extends Node

signal tooltip_hide_requested

#Meadow Creature-related Events
signal trigger_action(creature, action, duration)
signal creature_stat_view_requested(creature_stats: CreatureStats)
signal creature_stat_view_dismissed(uid: String)
signal creature_stat_updated(uid: String)

# Item-related Events
signal item_aim_started(item)
signal item_aim_ended(item)
signal item_used(item)
signal item_added(item)
signal item_received(item)

# Player-related Events
signal player_hit
signal player_died

# Autobattle Events
signal battle_action_step(actor: Node)
signal battle_action_complete(actor_uid: String)
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
signal add_leveled_creature_to_rewards(creature_stats: CreatureStats)
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
signal map_exited(room)
signal save_game(on_map: bool)

# Shop-related Events
signal shop_exited

# Rest-related Events
signal rest_site_exited

# Battle Reward-related Events
signal battle_reward_exited

# Treasure-related Events
signal treasure_room_exited

# RandomEvent-related Events
signal event_room_exited

# Egg Chamber-related Events
signal egg_chamber_exited
