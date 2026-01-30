#!/usr/bin/env python3
"""
NCC Blender Test Script
Tests basic Blender functionality for 3D rendering capabilities
"""

import bpy
import os

# --- CONFIGURATION ---
OUTPUT_DIR = r"C:/Users/gripa/OneDrive/Desktop/NCC_BlenderRenders"
RENDER_RES = (1920, 1080)

# --- SETUP ---
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

print("NCC Blender Test: Setting up scene...")

# Clear existing scene
bpy.ops.wm.read_factory_settings(use_empty=True)

# Create a simple cube
bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 0))

# Add a camera
bpy.ops.object.camera_add(location=(7, -7, 5))
camera = bpy.context.active_object
camera.rotation_euler = (1.1, 0, 0.785)  # Point camera at cube

# Set camera as active camera
bpy.context.scene.camera = camera

# Add lighting
bpy.ops.object.light_add(type='SUN', location=(5, 5, 5))

# Set render settings
bpy.context.scene.render.resolution_x = RENDER_RES[0]
bpy.context.scene.render.resolution_y = RENDER_RES[1]
bpy.context.scene.render.image_settings.file_format = 'PNG'

print("NCC Blender Test: Rendering 4 angles...")

# Render from 4 different angles
angles = [
    ("front", (0, 0, 0)),
    ("right", (0, 1.57, 0)),
    ("back", (0, 3.14, 0)),
    ("left", (0, -1.57, 0))
]

for angle_name, rotation in angles:
    # Rotate camera
    camera.rotation_euler = (1.1, rotation[1], rotation[2])

    # Set output path
    output_path = os.path.join(OUTPUT_DIR, f"ncc_test_{angle_name}.png")
    bpy.context.scene.render.filepath = output_path

    # Render
    print(f"Rendering {angle_name} view...")
    bpy.ops.render.render(write_still=True)

    print(f"✅ Saved: {output_path}")

print("NCC Blender Test: Complete!")
print(f"Output directory: {OUTPUT_DIR}")
