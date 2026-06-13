#events.gd
extends Node

# Run / Scene
@warning_ignore("unused_signal")
signal scene_transition_requested(scene_id: String)
@warning_ignore("unused_signal")
signal ruins_run_started(creature: CreatureInstance)
@warning_ignore("unused_signal")
signal shake_camera_requested()
@warning_ignore("unused_signal")
signal camera_target_requested(node: Node2D)

# Meadow Creature stat view
@warning_ignore("unused_signal")
signal creature_stat_view_requested(instance: CreatureInstance)
@warning_ignore("unused_signal")
signal creature_stat_view_dismissed(uid: String)
@warning_ignore("unused_signal")
signal creature_stat_updated(uid: String)

# Items
@warning_ignore("unused_signal")
signal item_picked_up(item, qty)

# Player
@warning_ignore("unused_signal")
signal player_died

# Combat lifecycle
@warning_ignore("unused_signal")
signal combat_started
@warning_ignore("unused_signal")
signal combat_ended
@warning_ignore("unused_signal")
signal creature_ensnared(creature: CreatureBattleUnit)
@warning_ignore("unused_signal")
signal creature_freed(creature: CreatureBattleUnit)

# Enemy
@warning_ignore("unused_signal")
signal enemy_fainted(enemy: Enemy)

# Battle UI
@warning_ignore("unused_signal")
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
@warning_ignore("unused_signal")
signal reward_selected(reward: RewardDef)
@warning_ignore("unused_signal")
signal reward_ui_requested
@warning_ignore("unused_signal")
signal reward_ui_dismissed

# Party
@warning_ignore("unused_signal")
signal party_creature_fainted(creature: CreatureBattleUnit)
