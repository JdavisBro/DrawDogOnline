extends MeshInstance2D

const ROT_SPEED = 64
const RAD = 36
const MIN_DIST = 26

var startpos = Vector2.ZERO
var selected = null
var size = 100

@onready var brush = get_node("..")

func create_mesh():
	var qual = len(Global.palette)

	mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	mesh.surface_set_color(Color.BLACK)
	for i in range(qual): # black border
		var radius = size*1.05
		var inner_rad = size*0.7
		
		if selected != null and i == selected:
			radius += 25 
			inner_rad += 25
		
		var a = (TAU / qual) * i
		var lx = Vector2(0,-1).rotated(a).x
		var ly = Vector2(0,-1).rotated(a).y
		a = (TAU / qual) * (i+1)
		var lx2 = Vector2(0,-1).rotated(a).x
		var ly2 = Vector2(0,-1).rotated(a).y
		
		mesh.surface_add_vertex_2d(Vector2(lx * radius, ly * radius))
		mesh.surface_add_vertex_2d(Vector2(lx * inner_rad, ly * inner_rad))
		mesh.surface_add_vertex_2d(Vector2(lx2 * inner_rad, ly2 * inner_rad))
		mesh.surface_add_vertex_2d(Vector2(lx * radius, ly * radius))
		mesh.surface_add_vertex_2d(Vector2(lx2 * radius, ly2 * radius))
		mesh.surface_add_vertex_2d(Vector2(lx2 * inner_rad, ly2 * inner_rad))

	for i in range(qual):
		var radius = size
		var inner_rad = size*0.75
		
		if selected != null and i == selected:
			radius += 25 
			inner_rad += 25
		
		if i < len(Global.palette):
			mesh.surface_set_color(Global.palette[i])
		else:
			mesh.surface_set_color(Color.SLATE_GRAY)
		var a = (TAU / qual) * i
		var lx = Vector2(0,-1).rotated(a).x
		var ly = Vector2(0,-1).rotated(a).y
		a = (TAU / qual) * (i+1)
		var lx2 = Vector2(0,-1).rotated(a).x
		var ly2 = Vector2(0,-1).rotated(a).y
		
		
		mesh.surface_add_vertex_2d(Vector2(lx * radius, ly * radius))
		mesh.surface_add_vertex_2d(Vector2(lx * inner_rad, ly * inner_rad))
		mesh.surface_add_vertex_2d(Vector2(lx2 * inner_rad, ly2 * inner_rad))
		mesh.surface_add_vertex_2d(Vector2(lx * radius, ly * radius))
		mesh.surface_add_vertex_2d(Vector2(lx2 * radius, ly2 * radius))
		mesh.surface_add_vertex_2d(Vector2(lx2 * inner_rad, ly2 * inner_rad))
	mesh.surface_end()

func get_selected():
	var diff = (brush.pos - startpos)*(Vector2.ONE/scale)
	if diff.length() < MIN_DIST:
		selected = null
		return
	var ang = Vector2.UP.angle_to(diff)
	if ang < 0:
		ang = TAU+ang
	selected = floori(ang / (TAU/len(Global.palette)))

func _process(_delta):
	if Input.is_action_pressed("quick_color", true) and not Input.is_action_pressed("draw", true):
		if not visible:
			startpos = brush.pos
		get_selected()
		visible = true
	else:
		if visible:
			get_selected()
			if selected != null and selected < len(Global.palette):
				brush.color_index = selected
			selected = null
			visible = false
	
	if visible:
		global_position = startpos
		create_mesh()
