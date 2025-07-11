extends Node2D

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

var GlobeTrotter : bool = false
var CoveKeeper : bool = false
var FullFocus : bool = false

var PossibleChallenges : Array = [
	"LightsOut", "TheParty", "HyperFreddy", "Permatrap", "FoxerFoxy", "HelloHello", "KillerTheory", "StaticShock"
]
var PossibleRequirements : Array = [
	"GlobeTrotter", "CoveKeeper", "FullFocus"
]
var ChallengePointMultipliers : Dictionary = {
	"freddy": "HyperFreddy",
	"bonnie": "TheParty",
	"chica": "TheParty",
	"foxy": "FoxerFoxy",
	"fredbear": "KillerTheory",
	"springtrap": "Permatrap",
	"phone_guy": "HelloHello",
	"static_guy": "StaticShock"
}

var PresetID : int = 0
var Preset : String = "Custom"
var PresetStrID : String = "Custom"
var Points : int = 0
var VolumePercent : float = 100
var VolumeDB : float = 0
var SaveDataLoaded : bool = false
var SelectingNewKey : bool = false
var ActionToChange : String = "light"

var TimeScale : float = 1.0

var ActionToName : Dictionary = {
	"light": "Light",
	"flipcam": "Flip Cams",
	"off": "Remove Lure",
	"low": "LOW Lure",
	"med": "MED Lure",
	"high": "HIGH Lure",
	"quit": "Quit"
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

var UsernameHovered : bool = false
var GametokenHovered : bool = false

var ScreenMoving : bool = false

var BitcrushStar : int = 1
var BestStar : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Black.color = Color.BLACK
	Engine.time_scale = Global.TimeScale
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.ResetInGameVars()
	SetupChallengeSignals()
	SetupControlSignals()
	var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	CamTween.tween_property($Camera2D, "zoom", Vector2(1,1), 1.0)
	var RotTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	RotTween.tween_property($Camera2D, "rotation",0, 1.0)
	var FadeTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	FadeTween.tween_property($Black, "color", Color.WHITE, 1.0)
	DisplayLastNightPreset()
	GameJolt.users_auth_completed.connect(_on_GameJolt_users_auth_completed)
	if Global.Mobile:
		$SettingsMenu/Controls.visible = false
		$SettingsMenu/ControlsTitle.visible = false
		$SettingsMenu/GamejoltTitle.position = Vector2(2560, 128)
		$SettingsMenu/GeneralTitle/Fullscreen.visible = false
		$SettingsMenu/GeneralTitle/Stretch.position = Vector2(16,32)
		$SettingsMenu/GeneralTitle/VSync.position = Vector2(16, 72)
		$SettingsMenu/GeneralTitle/SmoothTurn.position = Vector2(16, 112)
		$SettingsMenu/GeneralTitle/VolumeSlider.position = Vector2(16, 172)

func DisplayLastNightPreset():
	# Manage bitcrush
	if "Bitcrush" in Global.Preset:
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
		GlobeTrotter = false
		CoveKeeper = false
		FullFocus = false
		PresetID = 0
		SelectPreset()
	else:
		# AI
		if Global.Challenges["TheParty"]:
			if Global.AIDiffs["bonnie"] > 0:
				Global.AIDiffs["bonnie"] -= 5
			if Global.AIDiffs["chica"] > 0:
				Global.AIDiffs["chica"] -= 5
		AIDiffs = Global.AIDiffs
		for anim in AIDiffs:
			var AnimNode : CNCharacter = get_node("Characters/" + anim)
			AnimNode.Difficulty = AIDiffs[anim]
			AnimNode.Update()
		
		# Challenges
		Challenges = Global.Challenges
		for challenge in Challenges:
			var ButtonNode : Button = get_node("Challenges/btns/" + challenge)
			ButtonNode.button_pressed = Challenges[challenge]
		
		# Requirements
		GlobeTrotter = Global.TrackingGlobeTrotter
		FullFocus = Global.TrackingFullFocus
		CoveKeeper = Global.TrackingCoveKeeper
		$Requirements/btns/GlobeTrotter.button_pressed = GlobeTrotter
		$Requirements/btns/FullFocus.button_pressed = FullFocus
		$Requirements/btns/CoveKeeper.button_pressed = CoveKeeper
	
	# Preset
	CheckForPreset()
	
	# Score
	Points = Global.Score
	$SideMenu/Panel/Score.text = "Score: " + str(Points)

func on_TimeScaleChanged():
	$TimeScale.visible = true
	$TimeScale.text = "Time Scale: " + str(int(Global.TimeScale * 100)) + "%"

func CalculatePoints():
	Points = 0
	for i in AIDiffs:
		Points += AIDiffs[i] * (25 + (15 * int(Challenges[ChallengePointMultipliers[i]])) + (10 * int(Challenges["LightsOut"])))
	Points += 25 * AIDiffs["foxy"] * int(CoveKeeper)
	Points += 500 * int(FullFocus)
	Points += 1000 * int(GlobeTrotter)
	$SideMenu/Panel/Score.text = "Score: " + str(Points)

func _input(event):
	if SelectingNewKey:
		if event is InputEventKey:
			event.pressed = true
			event.echo = false
			PlayerData.SaveData.Controls[ActionToChange] = [event]
			PlayerData.save_character_data(PlayerData.SaveData)
			for action in PlayerData.SaveData.Controls:
				InputMap.action_erase_events(action)
				for input in PlayerData.SaveData.Controls[action]:
					InputMap.action_add_event(action, input)
			SelectingNewKey = false
			$MainMenu.disabled = false
			$SettingsMenu/Controls/PressKey.visible = false
			$SettingsMenu/Controls/EditKey.visible = true
			DisplayNewControls()
	else:
		if Input.is_action_just_pressed("quit"):
			$HonkQuit.play()
		if Input.is_action_just_pressed("remove_trophies"):
			get_tree().change_scene_to_file("res://scenes/remove_all_trophies.tscn")
		if event is InputEventKey:
			if event.key_label == KEY_ENTER:
				$SettingsMenu/GamejoltTitle/Username.release_focus()
				$SettingsMenu/GamejoltTitle/GameToken.release_focus()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if !UsernameHovered:
				$SettingsMenu/GamejoltTitle/Username.release_focus()
			if !GametokenHovered:
				$SettingsMenu/GamejoltTitle/GameToken.release_focus()

func _on_difficulty_changed(AnimName, node):
	AIDiffs[AnimName] = node.Difficulty
	CalculatePoints()
	CheckForPreset()

func _on_start_button_up():
	Global.Challenges = Challenges
	Global.TrackingCoveKeeper = CoveKeeper
	Global.TrackingFullFocus = FullFocus
	Global.TrackingGlobeTrotter = GlobeTrotter
	Global.AIDiffs = AIDiffs
	Global.Preset = Preset
	Global.PresetID = PresetStrID
	Global.Score = Points
	Global.Tutorial = false
	Global.Bitcrush = false
	Global.StarDiff = 1
	$Cover.visible = true
	var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	CamTween.tween_property($Camera2D, "zoom", Vector2(3,3), 3.0)
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "color", Color.BLACK, 2.0)
	FadeTween.tween_callback(ChangeScene)

func ChangeScene():
	get_tree().change_scene_to_file("res://scenes/office.tscn")
	
func ChangeSceneCutscene():
	get_tree().change_scene_to_file("res://scenes/how_did_we_get_here.tscn")

func _on_challenge_toggled(toggled_on, Challenge, FromButtonDirect):
	Challenges[Challenge] = toggled_on
	CalculatePoints()
	CheckForPreset()
	
func SetupChallengeSignals():
	for btn : Button in $Challenges/btns.get_children():
		btn.toggled.connect(_on_challenge_toggled.bind(btn.name, true))

func SetupControlSignals():
	for btn : Button in $SettingsMenu/Controls/Control.get_children():
		btn.pressed.connect(_on_control_pressed.bind(btn.name))

func _on_quit_button_down():
	$HonkQuit.play()

func _on_select_all_toggled(toggled_on):
	for btn : Button in $Challenges/btns.get_children():
		btn.button_pressed = toggled_on
		_on_challenge_toggled(toggled_on, btn.name, false)

func _on_challenges_pressed():
	$Challenges.visible = true
	$SideMenu.visible = false
	$Tutorial.visible = false
	$BitcrushBtn.visible = false
	$press.play()

func _on_requirements_pressed():
	$Requirements.visible = true
	$SideMenu.visible = false
	$Tutorial.visible = false
	$BitcrushBtn.visible = false
	$press.play()

func _on_back_pressed():
	$Requirements.visible = false
	$Challenges.visible = false
	$SideMenu.visible = true
	$Tutorial.visible = true
	$BitcrushBtn.visible = true
	$press.play()

func _on_select_all_req_toggled(toggled_on):
	for btn : Button in $Requirements/btns.get_children():
		btn.button_pressed = toggled_on
		btn.toggled.emit(toggled_on)

func _on_cove_keeper_toggled(toggled_on):
	CoveKeeper = toggled_on
	CalculatePoints()
	CheckForPreset()

func _on_energy_efficient_toggled(toggled_on):
	FullFocus = toggled_on
	CalculatePoints()
	CheckForPreset()

func _on_globe_trotter_toggled(toggled_on):
	GlobeTrotter = toggled_on
	CalculatePoints()
	CheckForPreset()

func _on_forward_button_down():
	PresetID += 1
	if PresetID >= $NightPresets.get_child_count():
		PresetID = 0
	SelectPreset()
	$press.play()

func _on_back_button_down():
	PresetID -= 1
	if PresetID < 0:
		PresetID = $NightPresets.get_child_count() - 1
	SelectPreset()
	$press.play()

func SelectPreset():
	var PresetNode : NightPreset = $NightPresets.get_child(PresetID)
	ChangeToPreset(PresetNode.Name)
	ChangePresetID(PresetNode.name)
	for i in PresetNode.AIDiffs:
		AIDiffs[i] = PresetNode.AIDiffs[i]
		var CharacterNode = get_node("Characters/" + i)
		CharacterNode.Difficulty = PresetNode.AIDiffs[i]
		CharacterNode.Update()
	for i in Challenges:
		var ChallengeNode = get_node("Challenges/btns/" + i)
		Challenges[i] = i in PresetNode.Challenges
		ChallengeNode.button_pressed = Challenges[i]
		ChallengeNode.toggled.emit(Challenges[i])
	for i in PossibleRequirements:
		var RequirementNode = get_node("Requirements/btns/" + i)
		if i in PresetNode.Requirements:
			set(i, true)
		else:
			set(i, false)
		RequirementNode.button_pressed = get(i)
		RequirementNode.toggled.emit(get(i))

func CheckForPreset():
	var Valid : bool = true
	var FoundPreset : bool = false
	for preset : NightPreset in $NightPresets.get_children():
		Valid = true
		if preset.AIDiffs == AIDiffs:
			for i in preset.Challenges:
				if !Challenges[i]:
					Valid = false
			for i in preset.Requirements:
				if !get(i) and i:
					Valid = false
		else:
			Valid = false
	
		if Valid:
			FoundPreset = true
			ChangeToPreset(preset.Name)
			ChangePresetID(preset.name)
	
	if !FoundPreset:
		ChangeToPreset("Custom")
		ChangePresetID("Custom")

func ChangePresetID(Name : String):
	PresetStrID = Name
	if Name == "Custom":
		$SideMenu/Panel2/BestTime.text = "Best Time: N/A"
		$PresetPanel/Star1.play("0")
		$PresetPanel/Star2.play("0")
	else:
		var TimeSpent = PlayerData.SaveData.PresetTimes[Name]
		var TimeStr : String = str(TimeSpent / 60) + ":"
		TimeStr = str(TimeSpent / 60) + ":"
		var min : String = str(TimeSpent % 60)
		if TimeSpent % 60 < 10:
			min = "0" + min
		TimeStr += min
		$SideMenu/Panel2/BestTime.text = "Best Time: " + TimeStr
		var StarNum = str(PlayerData.SaveData.PresetsComplete[Name])
		$PresetPanel/Star1.play(StarNum)
		$PresetPanel/Star2.play(StarNum)

func ChangeToPreset(Name : String):
	Preset = Name
	$PresetPanel/Label.text = Name

func _on_settings_button_down():
	if !ScreenMoving:
		ScreenMoving = true
		var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
		CamTween.tween_property($Camera2D, "offset:x", 2880, 2.0)
		CamTween.tween_callback(SetScreenMoving)

func _on_main_menu_button_down():
	if !ScreenMoving:
		ScreenMoving = true
		var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
		CamTween.tween_property($Camera2D, "offset:x", 960, 2.0)
		CamTween.tween_callback(SetScreenMoving)


func _on_fullscreen_toggled(toggled_on):
	if toggled_on:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
	PlayerData.SaveData.Fullscreen = toggled_on
	PlayerData.save_character_data(PlayerData.SaveData)

func _on_stretch_toggled(toggled_on):
	if toggled_on:
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	else:
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	PlayerData.SaveData.Stretch = toggled_on
	PlayerData.save_character_data(PlayerData.SaveData)

func _on_volume_slider_value_changed(value):
	VolumePercent = value
	$SettingsMenu/GeneralTitle/VolumeSlider/VolumeLabel.text = "Volume: " + str(int(value)) + "%"
	if VolumePercent > 0:
		VolumeDB = (10.0 / log(2)) * log((VolumePercent / 100.0))
		AudioServer.set_bus_mute(0, false)
	else:
		VolumeDB = -72
		AudioServer.set_bus_mute(0, true)
	AudioServer.set_bus_volume_db(0, VolumeDB)

func _on_volume_slider_drag_ended(value_changed):
	PlayerData.SaveData.Volume = VolumePercent / 100.0
	PlayerData.save_character_data(PlayerData.SaveData)

func CheckSaveLoaded() -> bool:
	SaveDataLoaded = PlayerData.SaveData != null
	return SaveDataLoaded

func LoadSettings():
	# Stretch
	if PlayerData.SaveData.Stretch:
		if get_window().content_scale_aspect != Window.CONTENT_SCALE_ASPECT_IGNORE:
			get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	else:
		if get_window().content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
			get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	$SettingsMenu/GeneralTitle/Stretch.button_pressed = PlayerData.SaveData.Stretch
	
	# Fullscreen
	if PlayerData.SaveData.Fullscreen:
		if get_window().mode != Window.MODE_EXCLUSIVE_FULLSCREEN:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		if get_window().mode != Window.MODE_WINDOWED:
			get_window().mode = Window.MODE_WINDOWED
	$SettingsMenu/GeneralTitle/Fullscreen.button_pressed = PlayerData.SaveData.Fullscreen
	
	# VSync
	if PlayerData.SaveData.VSync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	$SettingsMenu/GeneralTitle/VSync.button_pressed = PlayerData.SaveData.VSync
	
	# Smooth Turn
	if PlayerData.SaveData.get_meta("SmoothTurn") != null:
		$SettingsMenu/GeneralTitle/SmoothTurn.button_pressed = PlayerData.SaveData.get_meta("SmoothTurn")
	
	# Volume
	_on_volume_slider_value_changed(PlayerData.SaveData.Volume * 100)
	$SettingsMenu/GeneralTitle/VolumeSlider.value = PlayerData.SaveData.Volume * 100
	
	# Audio Lure Colours
	$SettingsMenu/HighLureColour.color = PlayerData.SaveData.HighColour
	$SettingsMenu/MedLureColour.color = PlayerData.SaveData.MedColour
	$SettingsMenu/LowLureColour.color = PlayerData.SaveData.LowColour
	Global.HighColour = PlayerData.SaveData.HighColour
	Global.MedColour = PlayerData.SaveData.MedColour
	Global.LowColour = PlayerData.SaveData.LowColour
	
	# Keybinds
	for action in PlayerData.SaveData.Controls:
		InputMap.action_erase_events(action)
		for input in PlayerData.SaveData.Controls[action]:
			InputMap.action_add_event(action, input)
	DisplayNewControls()
	
	# High Score
	$SideMenu/Panel3/HighScore.text = "High Score: " + str(PlayerData.SaveData.HighScore)
	
	# Cutscene
	if PlayerData.SaveData.HighScore == 10000:
		$SettingsMenu/Cutscene.visible = true
	
	# Game Jolt
	LoginGamejolt("", "")
	
	# Discord
	if !Global.Mobile:
		DiscordPresence()
		
	# Bitcrush
	BestStar = PlayerData.SaveData.BitcrushBest
	$Bitcrush/CompletedStars.frame = BestStar
	UpdateBitcrushStars()
	
	$Start.disabled = false
	$Tutorial.disabled = false
	$BitcrushBtn.disabled = false

func UpdateBitcrushStars():
	$Bitcrush/SelectedStars.frame = BitcrushStar
	$Bitcrush/SelectedStars.visible = BitcrushStar != BestStar
	$Bitcrush/Panel/Label.text = "Bitcrush " + str(BitcrushStar)

func _on_load_timer_timeout():
	if !CheckSaveLoaded():
		$LoadTimer.start()
	else:
		LoadSettings()
	
	if !$Music.playing:
		$Music.play()

func _on_high_lure_colour_color_changed(color):
	Global.HighColour = color
	PlayerData.SaveData.HighColour = color
	PlayerData.save_character_data(PlayerData.SaveData)

func _on_med_lure_colour_color_changed(color):
	Global.MedColour = color
	PlayerData.SaveData.MedColour = color
	PlayerData.save_character_data(PlayerData.SaveData)

func _on_low_lure_colour_color_changed(color):
	Global.LowColour = color
	PlayerData.SaveData.LowColour = color
	PlayerData.save_character_data(PlayerData.SaveData)

func _on_control_pressed(action_name):
	SelectingNewKey = true
	ActionToChange = action_name
	$MainMenu.disabled = true
	$SettingsMenu/Controls/PressKey.visible = true
	$SettingsMenu/Controls/EditKey.visible = false

func DisplayNewControls():
	$SettingsMenu/Controls.text = ""
	for i in ActionToName:
		$SettingsMenu/Controls.text += ActionToName[i] + ": "
		$SettingsMenu/Controls.text += OS.get_keycode_string(PlayerData.SaveData.Controls[i][0].key_label).to_upper() + "\n"


func _on_reset_controls_pressed():
	for action in ActionToKeycode:
		var NewEvent : InputEventKey = InputEventKey.new()
		NewEvent.pressed = true
		NewEvent.echo = false
		NewEvent.physical_keycode = ActionToKeycode[action]
		NewEvent.keycode = DisplayServer.keyboard_get_keycode_from_physical(NewEvent.physical_keycode)
		NewEvent.key_label = NewEvent.keycode
		PlayerData.SaveData.Controls[action] = [NewEvent]
		PlayerData.save_character_data(PlayerData.SaveData)
		for control in PlayerData.SaveData.Controls:
			InputMap.action_erase_events(control)
			for input in PlayerData.SaveData.Controls[control]:
				InputMap.action_add_event(control, input)
		DisplayNewControls()


func _on_reset_colours_pressed():
	Global.LowColour = Color.GREEN
	Global.MedColour = Color.YELLOW
	Global.HighColour = Color.RED
	$SettingsMenu/LowLureColour.color = Color.GREEN
	$SettingsMenu/MedLureColour.color = Color.YELLOW
	$SettingsMenu/HighLureColour.color = Color.RED
	PlayerData.SaveData.LowColour = Color.GREEN
	PlayerData.SaveData.MedColour = Color.YELLOW
	PlayerData.SaveData.HighColour = Color.RED
	PlayerData.save_character_data(PlayerData.SaveData)


func _on_username_mouse_entered():
	UsernameHovered = true

func _on_username_mouse_exited():
	UsernameHovered = false

func _on_game_token_mouse_entered():
	GametokenHovered = true

func _on_game_token_mouse_exited():
	GametokenHovered = false

func LoginGamejolt(Username : String, Gametoken : String):
	if Global.LoggedInGamejolt and Gametoken == "" and Username == "":
		$SettingsMenu/GamejoltLoggedIn.text = "Logged in as " + PlayerData.SaveData.GamejoltUsername
	else:
		# Handles Save Data
		if Username == "":
			Username = PlayerData.SaveData.GamejoltUsername
		else:
			PlayerData.SaveData.GamejoltUsername = Username
			PlayerData.save_character_data(PlayerData.SaveData)
		if Gametoken == "":
			Gametoken = PlayerData.SaveData.GamejoltToken
		else:
			PlayerData.SaveData.GamejoltToken = Gametoken
			PlayerData.save_character_data(PlayerData.SaveData)
		
		if Username != "" and Gametoken != "":
			GameJolt.set_user_name(Username)
			GameJolt.set_user_token(Gametoken)
			GameJolt.users_auth()

func _on_GameJolt_users_auth_completed(result: Dictionary) -> void:
	if !result.has("message"):
		$SettingsMenu/GamejoltLoggedIn.text = "Logged in as " + PlayerData.SaveData.GamejoltUsername
		Global.LoggedInGamejolt = true
		GameJolt.trophies_add_achieved(GjId.LogIn)
	else:
		$SettingsMenu/GamejoltLoggedIn.text = result["message"]

func _on_confirm_pressed():
	LoginGamejolt($SettingsMenu/GamejoltTitle/Username.text, $SettingsMenu/GamejoltTitle/GameToken.text)


func DiscordPresence():
	if Global.DiscordRPCSetup:
		DiscordRPC.details = "Main Menu"
		DiscordRPC.state = "High Score: " + str(PlayerData.SaveData.HighScore)
		DiscordRPC.large_image = "game_icon" # Image key from "Art Assets"
		DiscordRPC.large_image_text = "Static Guy!"
		DiscordRPC.small_image = ""
		DiscordRPC.small_image_text = ""
		
		DiscordRPC.start_timestamp = Global.StartTime # "02:46 elapsed"
		# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
		
		DiscordRPC.refresh() # Always refresh after changing the values!

func _on_cutscene_pressed():
	var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	CamTween.tween_property($Camera2D, "zoom", Vector2(3,3), 3.0)
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "color", Color.BLACK, 2.0)
	FadeTween.tween_callback(ChangeSceneCutscene)


func _on_tutorial_pressed():
	Global.Challenges = {
		"LightsOut": false,
		"TheParty": false,
		"HyperFreddy": false,
		"Permatrap": false,
		"FoxerFoxy": false,
		"HelloHello": false,
		"KillerTheory": false,
		"StaticShock": false
	}
	Global.TrackingCoveKeeper = false
	Global.TrackingFullFocus = false
	Global.TrackingGlobeTrotter = false
	Global.AIDiffs = {
		"freddy": 0,
		"bonnie": 0,
		"chica": 0,
		"foxy": 0,
		"fredbear": 0,
		"springtrap": 0,
		"phone_guy": 0,
		"static_guy": 0
	}
	Global.Preset = "Tutorial"
	Global.PresetID = "Custom"
	Global.Score = 0
	Global.Tutorial = true
	Global.Bitcrush = false
	Global.StarDiff = 1
	$Cover.visible = true
	var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	CamTween.tween_property($Camera2D, "zoom", Vector2(3,3), 3.0)
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "color", Color.BLACK, 2.0)
	FadeTween.tween_callback(ChangeScene)


func _on_v_sync_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	PlayerData.SaveData.VSync = toggled_on
	PlayerData.save_character_data(PlayerData.SaveData)


func _on_smooth_turn_toggled(toggled_on):
	PlayerData.SaveData.set_meta("SmoothTurn", toggled_on)
	PlayerData.save_character_data(PlayerData.SaveData)


func _on_honk_quit_finished():
	get_tree().quit()


func _on_bc_main_menu_button_down() -> void:
	if !ScreenMoving:
		ScreenMoving = true
		var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
		CamTween.tween_property($Camera2D, "offset:y", 540, 2.0)
		CamTween.tween_callback(SetScreenMoving)

func _on_bitcrush_btn_button_down() -> void:
	if !ScreenMoving:
		ScreenMoving = true
		var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
		CamTween.tween_property($Camera2D, "offset:y", 1620, 2.0)
		CamTween.tween_callback(SetScreenMoving)

func SetScreenMoving() -> void:
	ScreenMoving = false

func _on_bitcrush_start_pressed() -> void:
	Global.Challenges = {
		"LightsOut": false,
		"TheParty": false,
		"HyperFreddy": true,
		"Permatrap": true,
		"FoxerFoxy": true,
		"HelloHello": true,
		"KillerTheory": true,
		"StaticShock": false
	}
	Global.TrackingCoveKeeper = false
	Global.TrackingFullFocus = true
	Global.TrackingGlobeTrotter = false
	Global.AIDiffs = {
		"freddy": 20,
		"bonnie": 20,
		"chica": 20,
		"foxy": 20,
		"fredbear": 20,
		"springtrap": 20,
		"phone_guy": 20,
		"static_guy": 0
	}
	Global.Preset = "Bitcrush " + str(BitcrushStar)
	Global.PresetID = "Bitcrush" + str(BitcrushStar)
	Global.Score = 0
	Global.Tutorial = false
	Global.Bitcrush = true
	Global.StarDiff = BitcrushStar
	$Cover.visible = true
	var CamTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	CamTween.tween_property($Camera2D, "zoom", Vector2(3,3), 3.0)
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "color", Color.BLACK, 2.0)
	FadeTween.tween_callback(ChangeScene)


func _on_bc_back_button_down() -> void:
	BitcrushStar -= 1
	if BitcrushStar < 1:
		BitcrushStar = 5
	UpdateBitcrushStars()
	$press.play()

func _on_bc_forward_button_down() -> void:
	BitcrushStar += 1
	if BitcrushStar > 5:
		BitcrushStar = 1
	UpdateBitcrushStars()
	$press.play()
