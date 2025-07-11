extends Resource
class_name SaveFile

@export var SaveFileVersion : int = 3

@export var BitcrushBest : int = 0

@export var HighScore : int = 0
@export var LowColour : Color = Color.GREEN
@export var MedColour : Color = Color.YELLOW
@export var HighColour : Color = Color.RED

@export var PresetsComplete : Dictionary = {
	"FNAF1": 0,
	"Fredbear": 0,
	"BB": 0,
	"Pests": 0,
	"TheBit": 0,
	"LANParty": 0,
	"How+": 0,
	"StaticFNAF1": 0,
	"StaticFredbear": 0,
	"StaticBB": 0,
	"StaticPests": 0,
	"TheNibble": 0,
	"TheKillerBite": 0,
	"How++": 0
}

@export var PresetTimes : Dictionary = {
	"FNAF1": 0,
	"Fredbear": 0,
	"BB": 0,
	"Pests": 0,
	"TheBit": 0,
	"LANParty": 0,
	"How+": 0,
	"StaticFNAF1": 0,
	"StaticFredbear": 0,
	"StaticBB": 0,
	"StaticPests": 0,
	"TheNibble": 0,
	"TheKillerBite": 0,
	"How++": 0
}

@export var GamejoltUsername : String = ""
@export var GamejoltToken : String = ""

@export var Volume : float = 1.0
@export var Fullscreen : bool = true
@export var Stretch : bool = true
@export var VSync : bool = true

@export var Controls : Dictionary = {
	"light": InputMap.action_get_events("light"),
	"flipcam": InputMap.action_get_events("flipcam"),
	"low": InputMap.action_get_events("low"),
	"med": InputMap.action_get_events("med"),
	"high": InputMap.action_get_events("high"),
	"off": InputMap.action_get_events("off"),
	"quit": InputMap.action_get_events("quit")
}

var ActionToKeycode : Dictionary = {
	"light": 32,
	"flipcam": 83,
	"low": 65,
	"med": 87,
	"high": 68,
	"off": 4194325,
	"quit": 4194305
}

func _init():
	if !has_meta("SmoothTurn"):
		set_meta("SmoothTurn", true)
	for action in Controls:
		var NewEvent : InputEventKey = InputEventKey.new()
		NewEvent.pressed = true
		NewEvent.echo = false
		NewEvent.physical_keycode = ActionToKeycode[action]
		NewEvent.keycode = DisplayServer.keyboard_get_keycode_from_physical(NewEvent.physical_keycode)
		NewEvent.key_label = NewEvent.keycode
		Controls[action] = [NewEvent]
