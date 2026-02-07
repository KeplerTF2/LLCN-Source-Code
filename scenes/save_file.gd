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
@export var Borderless : bool = true
@export var Stretch : bool = true
@export var VSync : bool = true
@export var JumpscareVolume : float = 1.0
@export var LightToggle : bool = true
@export var CRTShader : bool = true
@export var LureToggle : bool = true

@export var NHLBest : int = 0
@export var NHLPPBest : int = 0

@export var Controls : Dictionary = {
	"light": InputMap.action_get_events("light"),
	"flipcam": InputMap.action_get_events("flipcam"),
	"low": InputMap.action_get_events("low"),
	"med": InputMap.action_get_events("med"),
	"high": InputMap.action_get_events("high"),
	"off": InputMap.action_get_events("off"),
	"quit": InputMap.action_get_events("quit"),
	"reset": InputMap.action_get_events("reset")
}

var ActionToKeycode : Dictionary = {
	"light": KEY_SPACE,
	"flipcam": KEY_S,
	"low": KEY_A,
	"med": KEY_W,
	"high": KEY_D,
	"off": KEY_SHIFT,
	"quit": KEY_ESCAPE,
	"reset": KEY_F1 
}

func _init():
	if !has_meta("SmoothTurn"):
		set_meta("SmoothTurn", true)
	if !has_meta("CRTShader"):
		set_meta("CRTShader", true)
	if !has_meta("LightToggle"):
		set_meta("LightToggle", true)
	if !has_meta("LureToggle"):
		set_meta("LureToggle", true)
	if !has_meta("JumpscareVolume"):
		set_meta("JumpscareVolume", 1.0)
	if !has_meta("NHLBest"):
		set_meta("NHLBest", 0)
	if !has_meta("NHLPPBest"):
		set_meta("NHLPPBest", 0)
	for action in Controls:
		var NewEvent : InputEventKey = InputEventKey.new()
		NewEvent.pressed = true
		NewEvent.echo = false
		NewEvent.physical_keycode = ActionToKeycode[action]
		NewEvent.keycode = DisplayServer.keyboard_get_keycode_from_physical(NewEvent.physical_keycode)
		NewEvent.key_label = NewEvent.keycode
		Controls[action] = [NewEvent]
