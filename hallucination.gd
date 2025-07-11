extends Node2D

var Active : bool = false
var ActiveQueued : bool = false

func QueueActivation():
	ActiveQueued = true

func Activate():
	Active = true
	ActiveQueued = false
	$Sprite.visible = true
	$Sound.play()
	Activated.emit()

func Deactivate():
	Active = false
	$Sprite.visible = false
	$Sound.stop()
	$Deactivate.play()

signal Activated
