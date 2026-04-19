#events.gd
extends Node

# Card-related Events
signal card_drag_started(card_ui)
signal card_drag_ended(card_ui)
signal card_aim_started(card_ui)
signal card_aim_ended(card_ui)
signal card_played(card: Card)
signal card_tooltip_requested(card: Card)
signal tooltip_hide_requested

#Meadow Creature-related Events
signal trigger_action(creature, action, duration)

# Item-related Events
signal item_aim_started(item)
signal item_aim_ended(item)
signal item_used(item)
signal item_added(item)

# Player-related Events
#signal player_hand_drawn       # dead — autobattle
#signal player_hand_discarded   # dead — autobattle
#signal player_turn_ended       # dead — autobattle
signal player_hit
signal player_died
#signal card_play_initiated     # dead — autobattle
#signal card_play_completed     # dead — autobattle
#signal card_draw_requested(amount: int)  # dead — autobattle

# Autobattle Events
signal creature_action_started(unit: CreatureBattleUnit, card: Card)
signal creature_action_completed(unit: CreatureBattleUnit)
signal combat_started
signal combat_ended

# Enemy-related Events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_fainted(enemy: Enemy)
signal enemy_seeded(seeded: Status)

# Battle-related Events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])
signal status_tooltip_hide_requested()
signal party_shifted
signal add_leveled_creature_to_rewards(creature_stats: CreatureStats)
signal return_to_main_menu
signal battle_text_requested(text: String)
signal battle_text_completed()
signal camera_shake_requested(damage: int, intensity: float)
signal card_added_to_hand(card: Card)

# Creature-related Events
signal party_creature_fainted(creature: CreatureBattleUnit)
signal player_creature_start_status_applied(creature: CreatureBattleUnit)
signal player_creature_end_status_applied(creature: CreatureBattleUnit)
signal added_creature_to_party(creature: CreatureBattleUnit)
signal player_creature_switch_requested(uid_out: String, uid_in: String)
signal player_creature_switch_completed(creature_stats: CreatureStats)
signal evolution_triggered(creature_stats: CreatureStats)
signal evolution_completed

# Reward-related Events
signal creature_reward_requested(creature_stats: CreatureStats)
signal creature_reward_completed

# Map-related Events
signal map_exited(room)
signal save_game(on_map: bool)

# Shop-related Events
signal shop_exited
signal shop_card_bought(card: Card, gold_cost: int)
signal shop_creature_bought(creature_stats: CreatureStats, gold_cost: int)
signal shop_creature_clicked(creature_stats: CreatureStats)

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
