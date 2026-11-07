"""Weathered materials and curved armor surfaces for the adult revision."""

import math
import bpy
from character_geometry import material, mesh


def weathered(name, color, metal=0, roughness=0.6, grain=75, strength=0.13):
    surface = material(name, color, metal, roughness)
    nodes, links = surface.node_tree.nodes, surface.node_tree.links
    shader = nodes.get('Principled BSDF')
    noise = nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = grain
    noise.inputs['Detail'].default_value = 3
    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position = 0.15
    ramp.color_ramp.elements[0].color = (*(value * 0.55 for value in color), 1)
    ramp.color_ramp.elements[1].position = 0.85
    ramp.color_ramp.elements[1].color = (*(min(1, value * 1.15) for value in color), 1)
    links.new(noise.outputs['Fac'], ramp.inputs[0])
    links.new(ramp.outputs[0], shader.inputs['Base Color'])
    bump = nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = strength
    bump.inputs['Distance'].default_value = 0.009 if metal else 0.004
    links.new(noise.outputs['Fac'], bump.inputs['Height'])
    links.new(bump.outputs[0], shader.inputs['Normal'])
    return surface


def palette():
    p = {
        'skin': weathered('v002 tanned skin pores', (0.34, 0.175, 0.105), roughness=0.61, grain=180, strength=0.20),
        'scar': material('v002 healed scars', (0.27, 0.12, 0.075), roughness=0.73),
        'iron': weathered('v002 hammered charcoal iron', (0.042, 0.055, 0.061), 0.8, 0.49, 95, 0.18),
        'edge': weathered('v002 exposed worn steel', (0.22, 0.25, 0.25), 0.82, 0.39, 120, 0.08),
        'red': weathered('v002 dark crimson lacquer', (0.19, 0.019, 0.015), 0.45, 0.48, 55, 0.13),
        'brass': weathered('v002 aged bronze fittings', (0.28, 0.18, 0.073), 0.78, 0.50),
        'ivory': weathered('v002 worn bone ceramic', (0.60, 0.55, 0.43), 0.05, 0.5, 95, 0.10),
        'cloth': weathered('v002 faded teal weave', (0.015, 0.060, 0.057), 0, 0.96, 210, 0.3),
        'leather': weathered('v002 worn black leather', (0.025, 0.020, 0.017), 0, 0.84, 160, 0.25),
        'hair': weathered('v002 charcoal hair', (0.008, 0.012, 0.015), 0, 0.66, 150, 0.15),
        'steel': weathered('v002 forged blade', (0.20, 0.27, 0.30), 0.91, 0.28, 180, 0.035),
        'eye': material('v002 recessed ember slit', (0.55, 0.065, 0.008), 0.1, 0.42, 0.7),
    }
    p['skin'].node_tree.nodes.get('Principled BSDF').inputs['Subsurface Weight'].default_value = 0.055
    nodes = p['skin'].node_tree.nodes
    nodes.get('Noise Texture').inputs['Scale'].default_value = 450
    nodes.get('Bump').inputs['Distance'].default_value = 0.0007
    ramp = nodes.get('Color Ramp').color_ramp
    ramp.elements[0].color = (0.30, 0.15, 0.088, 1)
    ramp.elements[1].color = (0.355, 0.185, 0.115, 1)
    hair_nodes = p['hair'].node_tree.nodes
    hair_nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value = 0.15
    hair_nodes.get('Principled BSDF').inputs['Roughness'].default_value = 0.85
    hair_nodes.get('Bump').inputs['Distance'].default_value = 0.0004
    return p


def curved_panel(name, angle, radius, width, top, bottom, flare, surface):
    """A thin curved lamella with a shaped bottom, not a rounded solid block."""
    vertices = []
    columns = 10
    for row in range(2):
        for column in range(columns):
            u = column / (columns - 1) - 0.5
            a = angle + u * width
            r = radius + flare * row
            z = top if row == 0 else bottom + 0.025 * abs(u) * 2
            vertices.append((math.sin(a) * r, -math.cos(a) * r, z))
    faces = [(i, i + 1, i + 1 + columns, i + columns) for i in range(columns - 1)]
    obj = mesh(name, vertices, faces, surface)
    solidify = obj.modifiers.new('Real plate thickness', 'SOLIDIFY')
    solidify.thickness = 0.018
    bevel = obj.modifiers.new('Small worn plate edge', 'BEVEL')
    bevel.width, bevel.segments = 0.004, 2
    obj.modifiers.new('Armor normals', 'WEIGHTED_NORMAL')
    return obj
