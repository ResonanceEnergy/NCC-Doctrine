
import bpy
import os

# Ensure STL import add-on is enabled for background mode
bpy.ops.preferences.addon_enable(module="io_mesh_stl")

# --- USER CONFIG ---
MODEL_PATH = r"C:/Users/gripa/OneDrive/Desktop/your_model_file.stl"  # Change to your model file
OUTPUT_DIR = r"C:/Users/gripa/Desktop/BlenderRenders"
RENDER_RES = (1920, 1080)

# --- SETUP ---
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

bpy.ops.wm.read_factory_settings(use_empty=True)

# Import model (auto-detect by extension)
ext = os.path.splitext(MODEL_PATH)[1].lower()
if ext == ".stl":
    bpy.ops.import_mesh.stl(filepath=MODEL_PATH)
elif ext == ".obj":
    bpy.ops.import_scene.obj(filepath=MODEL_PATH)
elif ext == ".fbx":
    bpy.ops.import_scene.fbx(filepath=MODEL_PATH)
else:
    raise Exception("Unsupported file type: " + ext)

# Center model
for obj in bpy.context.selected_objects:
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    obj.location = (0, 0, 0)

# Camera setup
scene = bpy.context.scene
scene.render.resolution_x, scene.render.resolution_y = RENDER_RES
scene.render.image_settings.file_format = 'JPEG'

cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
scene.collection.objects.link(cam)
scene.camera = cam

# Lighting
light_data = bpy.data.lights.new(name="Light", type='SUN')
light = bpy.data.objects.new(name="Light", object_data=light_data)
scene.collection.objects.link(light)
light.location = (10, -10, 10)

# 4 angles: front, right, back, left
angles = [
    (0, -5, 0),    # Front
    (5, 0, 0),     # Right
    (0, 5, 0),     # Back
    (-5, 0, 0),    # Left
]
rotations = [
    (0, 0, 0),
    (0, 0, 1.5708),
    (0, 0, 3.1416),
    (0, 0, -1.5708),
]

for i, (loc, rot) in enumerate(zip(angles, rotations)):
    cam.location = (loc[0], loc[1], 3)
    cam.rotation_euler = rot
    scene.render.filepath = os.path.join(OUTPUT_DIR, f"render_{i+1}.jpg")
    bpy.ops.render.render(write_still=True)

print("Rendering complete. Images saved to:", OUTPUT_DIR)
