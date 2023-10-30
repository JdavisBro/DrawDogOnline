extends MeshInstance2D

var polygon = PackedVector2Array()
var color = Color(255,0,0)
var time_rot = 0

const ROT_SPEED = 64
const QUAL = 12
const RAD = 36

@onready var brush = get_node("..")

func create_mesh():
	color = Global.palette[brush.color_index]
	
	if color == Color.BLACK:
		color = Color(64/255.0, 64/255.0, 64/255.0).lerp(Color.BLACK, 0.33)
	elif color == Color.WHITE:
		color = Color(192/255.0, 192/255.0, 192/255.0).lerp(Color.WHITE, 0.33)

	var size = lerp(0, RAD, pow(brush.size / 24.0, 0.25))

	mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	mesh.surface_set_color(color)

	var inner_rad
	for radius in [[size, size/2], [size*0.75, size*0.75-size/4]]:
		inner_rad = radius[1]
		radius = radius[0]
		for i in range(QUAL+1):
			var a = (time_rot + ((360.0 / QUAL) * i))
			var lx = Vector2(1,0).rotated(deg_to_rad(a)).x
			var ly = Vector2(0.5,0).rotated(deg_to_rad(a)).y # this is 1 instead of 0.5 on walls but i dont think i'll have walls
			
			mesh.surface_add_vertex_2d(Vector2(lx * radius, ly * radius))
			mesh.surface_add_vertex_2d(Vector2(lx * inner_rad, ly * inner_rad))
		mesh.surface_set_color(Color(0,0,0))
	mesh.surface_end()

func _process(delta):
	time_rot += ROT_SPEED*delta
	time_rot = fmod(time_rot, 360)
	
	if visible:
		create_mesh()

