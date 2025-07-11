extends Node2D

@export var Won : bool = false
@export var CheatsOn : bool = false
const LosingCharacterPos : int = 328
const WinningCharacterPosStart : int = 2192
const WinningCharacterPosEnd : int = 1632

var PresetToTrophy : Dictionary = {
	"Custom": 0,
	"FNAF1": GjId.FNAF1,
	"Fredbear": GjId.Diner,
	"BB": GjId.BB,
	"Pests": GjId.Pests,
	"TheBit": GjId.Bit,
	"LANParty": GjId.LAN,
	"How+": GjId.HowP,
	"StaticFNAF1": GjId.SFNAF1,
	"StaticFredbear": GjId.SDiner,
	"StaticBB": GjId.SBB,
	"StaticPests": GjId.SPests,
	"TheNibble": GjId.Nibble,
	"TheKillerBite": GjId.TKB,
	"How++": GjId.HowPP
}

# Called when the node enters the scene tree for the first time.
func _ready():
	$Black.color = Color.BLACK
	Engine.time_scale = 1
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "color", Color.WHITE, 2.0)
	if !Global.Mobile:
		DiscordPresence()
	
	if Global.Preset != "Custom":
		if Global.Preset == "The Killer Bite" and (Global.FullFocus and Global.CoveKeeper and Global.GlobeTrotter) and Global.Won:
			$Labels/TitleLabel/SubTitlePreset.text = "How Did We Get Here?++"
		elif (Global.Preset == "The Bit" || Global.Preset == "The LAN Party") and (Global.FullFocus and Global.CoveKeeper and Global.GlobeTrotter) and Global.Won:
			$Labels/TitleLabel/SubTitlePreset.text = "How Did We Get Here?+"
		elif "Bitcrush" in Global.Preset:
			$Labels/TitleLabel/SubTitlePreset.text = "Bitcrush " + str(Global.StarDiff)
		else:
			$Labels/TitleLabel/SubTitlePreset.text = Global.Preset
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Character.play(Global.Character)
	if Global.Won:
		DisplayWinStats()
		$WinSong.play()
		$Labels/TitleLabel/SubTitle.text = "(wow)"
		$Labels/TitleLabel.text = "YOU WIN!"
		$Labels/TitleLabel.position.x = 0
		$Character.position.x = WinningCharacterPosStart
		var CharacterTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
		CharacterTween.tween_property($Character, "position:x", WinningCharacterPosEnd, 2.5)
		$Labels/LoseStats.visible = false
		$Labels/WinStats.visible = true
	else:
		DisplayLoseStats()
		$LoseSong.play()
		var CharacterTween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
		CharacterTween.tween_property($Character, "position:x", LosingCharacterPos, 2.5)
		match Global.FailedChallenge:
			"GlobeTrotter":
				$Labels/TitleLabel/SubTitle.text = "Static Guy didn't go to every cam first"
			"CoveKeeper":
				$Labels/TitleLabel/SubTitle.text = "Foxy went into a hallway"
			"FullFocus":
				$Labels/TitleLabel/SubTitle.text = "You lost focus"
				

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func DisplayLoseStats():
	var HighestLength : int = 0
	
	# Time
	var TimeStr : String = str(Global.TimeSpent / 60) + ":"
	TimeStr = str(Global.TimeSpent / 60) + ":"
	var min : String = str(Global.TimeSpent % 60)
	if Global.TimeSpent % 60 < 10:
		min = "0" + min
	TimeStr += min
	HighestLength = TimeStr.length()
	
	# Power
	var PowerUsed : String = str(int(Global.TotalPowerUsed)) + "%"
	HighestLength = max(HighestLength, PowerUsed.length())
	var PowerGenerated : String = str(int(Global.PowerGenerated)) + "%"
	HighestLength = max(HighestLength, PowerGenerated.length())
	
	$Labels/LoseStats.text = "Time: " + " ".repeat(HighestLength - TimeStr.length()) + TimeStr
	$Labels/LoseStats.text += "\nTotal Power Used: " + " ".repeat(HighestLength - PowerUsed.length()) + PowerUsed
	if !Global.Bitcrush:
		$Labels/LoseStats.text += "\nPower Generated: " + " ".repeat(HighestLength - PowerGenerated.length()) + PowerGenerated
	
	# Save Data
	if Global.PresetID != "Custom":
		if not ("Bitcrush" in Global.PresetID):
			if PlayerData.SaveData.PresetsComplete[Global.PresetID] == 0:
				if PlayerData.SaveData.PresetTimes[Global.PresetID] < Global.TimeSpent:
					PlayerData.SaveData.PresetTimes[Global.PresetID] = Global.TimeSpent
	PlayerData.save_character_data(PlayerData.SaveData)

func DisplayWinStats():
	# Time
	var TimeStr : String = str(Global.TimeSpent / 60) + ":"
	TimeStr = str(Global.TimeSpent / 60) + ":"
	var min : String = str(Global.TimeSpent % 60)
	if Global.TimeSpent % 60 < 10:
		min = "0" + min
	TimeStr += min
	
	# Power
	var PowerUsed : String = str(int(Global.TotalPowerUsed)) + "%"
	var PowerGenerated : String = str(int(Global.PowerGenerated)) + "%"
	
	# Score
	var Score = Global.Score
	var AdditionalScore = 0
	if !(Global.Preset in ["How Did We Get Here?+", "How Did We Get Here?++"]):
		if Global.GlobeTrotter and !Global.TrackingGlobeTrotter:
			AdditionalScore += 1000
		if Global.FullFocus and !Global.TrackingFullFocus:
			AdditionalScore += 500
		if Global.CoveKeeper and !Global.TrackingCoveKeeper:
			AdditionalScore += 25 * Global.AIDiffs["foxy"]
	Score += AdditionalScore
	
	if Global.Bitcrush:
		Score = 2000 + Global.StarDiff * 2000
	
	# High Score
	var HighScore = "0"
	if !CheatsOn:
		if PlayerData.SaveData.HighScore < Score:
			PlayerData.SaveData.HighScore = Score
			HighScore = str(Score) + " (NEW)"
			GameJolt.trophies_add_achieved(GjId.HighScore)
			if Score >= 2500:
				GameJolt.trophies_add_achieved(GjId.HighScore2500)
			if Score >= 5000:
				GameJolt.trophies_add_achieved(GjId.HighScore5000)
			if Score >= 7500:
				GameJolt.trophies_add_achieved(GjId.HighScore7500)
			
			GameJolt.scores_add(str(Score) + " Points", Score, GjId.HighScoreBoard)
		else:
			HighScore = str(PlayerData.SaveData.HighScore)
	
	$Labels/WinStats.text = ""
	if !Global.Bitcrush:
		$Labels/WinStats.text += "Time:             " + TimeStr
	$Labels/WinStats.text += "\nTotal Power Used: " + PowerUsed
	if !Global.Bitcrush:
		$Labels/WinStats.text += "\nPower Generated:  " + PowerGenerated
	$Labels/WinStats.text += "\nTotal Score:      " + str(Score)
	$Labels/WinStats.text += "\nHigh Score:       " + str(HighScore)
	
	if !CheatsOn:
		if Global.FullFocus or Global.CoveKeeper or Global.GlobeTrotter:
			$Labels/WinStats/Achievements.text = ""
			if (!(Global.Preset in ["How Did We Get Here?+", "How Did We Get Here?++"]) or (AdditionalScore != 0)) and !Global.Bitcrush:
				$Labels/WinStats/Achievements.text = "Achievements:     +" + str(AdditionalScore) + " Score"
			elif !Global.Bitcrush:
				$Labels/WinStats/Achievements.text = "Achievements:"
			if Global.GlobeTrotter:
				if !Global.Bitcrush:
					$Labels/WinStats/Achievements.text += "\nGlobe Trotter"
				GameJolt.trophies_add_achieved(GjId.GlobeTrotter)
				if Score >= 4000:
					GameJolt.trophies_add_achieved(GjId.GlobeTrotterP)
				if Score >= 8000:
					GameJolt.trophies_add_achieved(GjId.GlobeTrotterPP)
			if Global.FullFocus:
				if !Global.Bitcrush:
					$Labels/WinStats/Achievements.text += "\nFull Focus"
				GameJolt.trophies_add_achieved(GjId.FullFocus)
				if Score >= 4000:
					GameJolt.trophies_add_achieved(GjId.FullFocusP)
				if Score >= 8000:
					GameJolt.trophies_add_achieved(GjId.FullFocusPP)
			if Global.CoveKeeper:
				if !Global.Bitcrush:
					$Labels/WinStats/Achievements.text += "\nCove-Keeper"
				if Global.AIDiffs["foxy"] > 0:
					GameJolt.trophies_add_achieved(GjId.CoveKeeper)
					if Score >= 4000:
						GameJolt.trophies_add_achieved(GjId.CoveKeeperP)
					if Score >= 8000:
						GameJolt.trophies_add_achieved(GjId.CoveKeeperPP)
			if Global.FullFocus and Global.CoveKeeper and Global.GlobeTrotter:
				if !Global.Bitcrush:
					$Labels/WinStats/Achievements.text += "\nHow Did We Get Here?"
				if Global.AIDiffs["foxy"] > 0:
					GameJolt.trophies_add_achieved(GjId.How)
	
	# Save Data
	var NumOfAchievements : int = int(Global.GlobeTrotter) + int(Global.FullFocus) + int(Global.CoveKeeper)
	if !CheatsOn:
		if Global.PresetID != "Custom":
			if "Bitcrush" in Global.PresetID:
				PlayerData.SaveData.BitcrushBest = max(PlayerData.SaveData.BitcrushBest, Global.StarDiff)
			else:
				HandleSaveData(Global.PresetID)
				if Global.PresetID == "How++":
					HandleSaveData("TheKillerBite")
				if Global.PresetID == "How+":
					HandleSaveData("TheBit")
				if (Global.PresetID == "TheBit" || Global.PresetID == "LANParty") and NumOfAchievements == 3:
					HandleSaveData("How+")
				if Global.PresetID == "TheKillerBite" and NumOfAchievements == 3:
					HandleSaveData("How++")
		PlayerData.save_character_data(PlayerData.SaveData)
	
	# GameJolt
	if !CheatsOn:
		if $Labels/TitleLabel/SubTitlePreset.text == "How Did We Get Here?+":
			GameJolt.trophies_add_achieved(GjId.HowP)
		elif $Labels/TitleLabel/SubTitlePreset.text == "How Did We Get Here?++":
			GameJolt.trophies_add_achieved(GjId.HowPP)
		
		if Global.PresetID != "Custom" and not Global.Bitcrush:
			GameJolt.trophies_add_achieved(PresetToTrophy[Global.PresetID])
		
		if Global.Bitcrush:
			match Global.StarDiff:
				1:
					GameJolt.trophies_add_achieved(GjId.BC1)
				2:
					GameJolt.trophies_add_achieved(GjId.BC2)
				3:
					GameJolt.trophies_add_achieved(GjId.BC3)
				4:
					GameJolt.trophies_add_achieved(GjId.BC4)
				5:
					GameJolt.trophies_add_achieved(GjId.BC5)
		
		if Global.PresetID == "TheBit":
			GameJolt.scores_add(TimeStr, Global.TimeSpent, GjId.BitTime)
			GameJolt.scores_add(PowerUsed, int(Global.TotalPowerUsed), GjId.BitPower)
		if Global.PresetID == "TheKillerBite" || Global.PresetID == "How++":
			GameJolt.scores_add(TimeStr, Global.TimeSpent, GjId.TKBTime)
			GameJolt.scores_add(PowerUsed, int(Global.TotalPowerUsed), GjId.TKBPower)
		if Global.PresetID == "How++":
			GameJolt.scores_add(TimeStr, Global.TimeSpent, GjId.HowTime)
			GameJolt.scores_add(PowerUsed, int(Global.TotalPowerUsed), GjId.HowPower)
		
		if Global.AIDiffs["phone_guy"] == 20 and Global.Challenges["HelloHello"] and Global.Challenges["LightsOut"]:
			GameJolt.trophies_add_achieved(GjId.RAC)
		
		if Global.AIDiffs["phone_guy"] == 20 and Global.AIDiffs["freddy"] == 20 and Global.Challenges["HyperFreddy"]:
			GameJolt.trophies_add_achieved(GjId.SoundSens)
		
	# Platinum trophies
	if CheckForTheBitVariant():
		if Global.Minus3Strat:
			GameJolt.trophies_add_achieved(GjId.Minus3)
		if Global.ColourBlind:
			GameJolt.trophies_add_achieved(GjId.UnRed)
		if Global.LifeOnEdge:
			GameJolt.trophies_add_achieved(GjId.LifeOnEdge)
		
		if int(Global.PowerGenerated) == 0:
			GameJolt.trophies_add_achieved(GjId.TG)
		
		if Global.TimeSpent <= 120:
			GameJolt.trophies_add_achieved(GjId.TS)
		if Global.TimeSpent <= 180 and Global.PresetID == "TheKillerBite":
			GameJolt.trophies_add_achieved(GjId.FS)
		if Global.TimeSpent <= 600 and ($Labels/TitleLabel/SubTitlePreset.text == "How Did We Get Here?+" || $Labels/TitleLabel/SubTitlePreset.text == "How Did We Get Here?++"):
			GameJolt.trophies_add_achieved(GjId.LBS)
		if Global.TimeSpent <= 900 and $Labels/TitleLabel/SubTitlePreset.text == "How Did We Get Here?++":
			GameJolt.trophies_add_achieved(GjId.LBS2)

func HandleSaveData(PresetID):
	if PresetID != "Custom":
		var NumOfAchievements : int = int(Global.GlobeTrotter) + int(Global.FullFocus) + int(Global.CoveKeeper)
		if PlayerData.SaveData.PresetsComplete[PresetID] == 0:
			PlayerData.SaveData.PresetTimes[PresetID] = 99999999
		if PlayerData.SaveData.PresetsComplete[PresetID] < 1 + NumOfAchievements:
			PlayerData.SaveData.PresetsComplete[PresetID] = 1 + NumOfAchievements
		if PlayerData.SaveData.PresetTimes[PresetID] > Global.TimeSpent:
			PlayerData.SaveData.PresetTimes[PresetID] = Global.TimeSpent

func _on_continue_pressed():
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "color", Color.BLACK, 2.0)
	FadeTween.tween_callback(ChangeScene)

func ChangeScene():
	if $Labels/TitleLabel/SubTitlePreset.text == "How Did We Get Here?++" and Global.Won:
		get_tree().change_scene_to_file("res://scenes/how_did_we_get_here.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/cn_menu.tscn")

func CheckForTheBitVariant() -> bool:
	var Total : int = 0
	for i in Global.AIDiffs:
		Total += Global.AIDiffs[i]
	print(Total)
	return Total == 160 || Total == 170

func DiscordPresence():
	if Global.DiscordRPCSetup:
		if Global.Won:
			DiscordRPC.details = "Win Screen"
		else:
			DiscordRPC.details = "Game Over Screen"
		DiscordRPC.state = "Preset: " + Global.Preset
		DiscordRPC.large_image = "game_icon" # Image key from "Art Assets"
		DiscordRPC.large_image_text = "Static Guy!"
		DiscordRPC.small_image = ""
		DiscordRPC.small_image_text = ""
		
		DiscordRPC.start_timestamp = Global.StartTime # "02:46 elapsed"
		# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
		
		DiscordRPC.refresh() # Always refresh after changing the values!
