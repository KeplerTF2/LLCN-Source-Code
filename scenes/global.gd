extends Node

var DiscordRPCSetup: bool = false

var LowColour : Color = Color.GREEN
var MedColour : Color = Color.YELLOW
var HighColour : Color = Color.RED

var Challenges : Dictionary = {
	"LightsOut": false,
	"TheParty": false,
	"HyperFreddy": false,
	"Permatrap": false,
	"FoxerFoxy": false,
	"HelloHello": false,
	"KillerTheory": false,
	"StaticShock": false
}

var Preset : String = "Custom"
var PresetID : String = "Custom"

var TrackingGlobeTrotter : bool = false
var TrackingCoveKeeper : bool = false
var TrackingFullFocus : bool = false
var GlobeTrotter : bool = false
var CoveKeeper : bool = true
var FullFocus : bool = true

var Score : int = 0

var LoggedInGamejolt : bool = false

var AIDiffs : Dictionary = {
	"freddy": 0,
	"bonnie": 0,
	"chica": 0,
	"foxy": 0,
	"fredbear": 0,
	"springtrap": 0,
	"phone_guy": 0,
	"static_guy": 0
}

var TotalPowerUsed : float = 0.0
var PowerGenerated : float = 0.0
var TimeSpent : int = 0
var Won : bool = false
var Character : String = "static_guy"
var FailedChallenge : String = ""
var Tutorial : bool = false

@onready var StartTime : int = int(Time.get_unix_time_from_system())
@export var Mobile : bool = false

var TimeScale = 1

var Bitcrush : bool = false
var StarDiff : int = 1

# Trophies
var Minus3Strat : bool = true
var ColourBlind : bool = true
var LifeOnEdge : bool = true

func ResetCNVars():
	Challenges = {
		"LightsOut": false,
		"TheParty": false,
		"HyperFreddy": false,
		"Permatrap": false,
		"FoxerFoxy": false,
		"HelloHello": false,
		"KillerTheory": false,
		"StaticShock": false
	}
	TrackingFullFocus = false
	TrackingCoveKeeper = false
	TrackingGlobeTrotter = false
	AIDiffs = {
		"freddy": 0,
		"bonnie": 0,
		"chica": 0,
		"foxy": 0,
		"fredbear": 0,
		"springtrap": 0,
		"phone_guy": 0,
		"static_guy": 0
	}
	Preset = "Custom"
	PresetID = "Custom"
	Score = 0

func ResetInGameVars():
	Tutorial = false
	GlobeTrotter = false
	CoveKeeper = true
	FullFocus = true
	Minus3Strat = true
	ColourBlind = true
	LifeOnEdge = true
	TotalPowerUsed = 0.0
	PowerGenerated = 0.0
	TimeSpent = 0
	Won = false
	Character = "static_guy"
	FailedChallenge = ""

signal TimeScaleChanged
