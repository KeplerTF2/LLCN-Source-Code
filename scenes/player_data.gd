extends Node

var save_path = "user://savedata.res"
var SaveData : SaveFile = null

func _ready():
	SaveData = load_character_data()
	if SaveData == null:
		SaveData = SaveFile.new()
		save_character_data(SaveData)
	else:
		if SaveData.SaveFileVersion < 3:
			SaveData.SaveFileVersion = 3
		save_character_data(SaveData)

func load_character_data():
	if ResourceLoader.exists(save_path):
		return load(save_path)
	return null

func save_character_data(data):
	var result = ResourceSaver.save(data, save_path)
