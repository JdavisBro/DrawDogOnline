extends Node2D


func _ready():
	var file = FileAccess.open("res://data/dog_animations.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	for anim in data:
		var out = DogAnimation.new()
		var d = data[anim]
		out.origin = Vector2(d["origin"][0], d["origin"][1])
		out.ear = d["ear"]
		out.A = d["A"]
		out.B = d["B"]
		out.loop = str(d["loop"])
		out.bounce = float(d["bounce"])
		var head_frames = []
		for f in d["frames_head"]:
			var frame = DogAnimationFrame.new()
			frame.rotation = -float(f["ang"])
			frame.position = Vector2(f["x"], f["y"])
			head_frames.append(frame)
		out.head = head_frames
		var body_frames = []
		if "frames_body" in d:
			for f in d["frames_body"]:
				var frame = DogAnimationFrame.new()
				frame.rotation = -float(f["ang"])
				frame.position = Vector2(f["x"], f["y"])
				body_frames.append(frame)
		out.body = body_frames
		ResourceSaver.save(out, "user://" + anim + ".tres")
