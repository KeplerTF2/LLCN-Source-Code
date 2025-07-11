extends Node

@export var Root : Node
@export var Static : Node2D
@export var Black : Node2D
@export var Sound : AudioStreamPlayer

func FailAchievement():
	PassInGlobalVars()
	Sound.play()
	Static.visible = true
	Global.Won = false
	Root.FailingRequirement = true
	get_tree().paused = true
	var FadeTween = self.create_tween()
	FadeTween.tween_property(Black, "modulate:a", 1, 2.0)
	FadeTween.tween_callback(ChangeScene)

func PassInGlobalVars():
	Global.TotalPowerUsed = Root.TotalPowerUsed
	Global.PowerGenerated = Root.PowerGenerated
	Global.TimeSpent = Root.CurrentTime

func ChangeScene():
	get_tree().change_scene_to_file("res://scenes/endscreen.tscn")
