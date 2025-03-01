class_name Files


static func get_dictionary(path: String) -> Dictionary:
	var file_access = FileAccess.open(path, FileAccess.READ)
	var text = file_access.get_as_text()
	var file = JSON.parse_string(text) if text else null
	file_access.close()
	return file.data if file and file.has('data') else {}


static func save(data: Dictionary, path: String, image: Image) -> void:
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	save_file.store_line(JSON.stringify(data))
	save_file.close()
	if image:
		print(image.get_size())
		var image_path = path.substr(0, path.rfind('.'))
		print(image_path)
		image.save_jpg(image_path + '.jpg')
	# Files.load()
	return


static func load(path := "user://savegame.save") -> Dictionary:
	var save_file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var text = save_file.get_line()
	var result = json.parse(text)
	if not result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", text, " at line ", json.get_error_line())
	save_file.close()
	return json.data


## returns list of files at given path recursively
## [br]taken from - https://gist.github.com/hiulit/772b8784436898fd7f942750ad99e33e
static func get_all_files(path: String, file_ext := "", files : Array[String] = []) -> Array[String]:
	var dir : = DirAccess.open(path)
	if file_ext.begins_with("."): # get rid of starting dot if we used, for example ".tscn" instead of "tscn"
		file_ext = file_ext.substr(1,file_ext.length()-1)
	
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				# recursion
				files = get_all_files(dir.get_current_dir() +"/"+ file_name, file_ext, files)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				
				files.append(dir.get_current_dir() +"/"+ file_name)

			file_name = dir.get_next()
	else:
		print("[get_all_files()] An error occurred when trying to access %s." % path)
	return files
