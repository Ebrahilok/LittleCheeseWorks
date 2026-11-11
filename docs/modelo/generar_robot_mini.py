"""Genera el prototipo 3D del ROBOT MINI (cuarto de 2 x 2 m) y sus imágenes.

Uso (desde la raíz del repositorio):
    blender -b -P docs/modelo/generar_robot_mini.py

Produce docs/img/mini_frente.png, mini_atras.png, mini_interior.png,
mini_abajo.png y docs/modelo/robot_mini.blend.
Medidas en metros; el frente del robot apunta a +X. Es una ilustración: las
dimensiones salen de las fichas de UNIT Electronics, pero el kit real puede
variar en detalles (forma del chasis, soportes de motor).
"""
import math
import os

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.normpath(os.path.join(HERE, "..", "img"))
os.makedirs(IMG, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---- Medidas ----------------------------------------------------------------
L, W, T = 0.17, 0.09, 0.002        # chasis de aluminio (ficha: 170 x 90 mm)
WHEEL_R, WHEEL_W = 0.0325, 0.027   # llanta de 65 mm
AXLE_X = -0.010
Z_PLATE = 0.044                    # cara inferior del chasis
TOP = Z_PLATE + T                  # cara superior del chasis
STANDOFF = 0.045                   # separadores de la bandeja de cartón


def mat(name, color, rough=0.5, metal=0.0, emit=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = (*color, 1)
        b.inputs["Emission Strength"].default_value = emit
    return m


M = {
    "chasis": mat("Aluminio rojo", (0.62, 0.04, 0.04), 0.35, 0.7),
    "motor": mat("Motor amarillo", (0.95, 0.72, 0.05), 0.5),
    "llanta": mat("Llanta", (0.02, 0.02, 0.02), 0.9),
    "rin": mat("Rin", (0.90, 0.90, 0.88), 0.5),
    "metal": mat("Metal", (0.75, 0.76, 0.78), 0.3, 1.0),
    "laton": mat("Laton", (0.80, 0.62, 0.25), 0.35, 1.0),
    "negro": mat("Plastico negro", (0.03, 0.03, 0.03), 0.5),
    "pcb_azul": mat("PCB azul", (0.02, 0.12, 0.45), 0.4),
    "pcb_negro": mat("PCB negro", (0.02, 0.02, 0.03), 0.4),
    "pcb_rojo": mat("PCB rojo", (0.55, 0.03, 0.03), 0.4),
    "blanco": mat("Protoboard", (0.92, 0.92, 0.90), 0.6),
    "carton": mat("Carton", (0.62, 0.45, 0.28), 0.9),
    "carga": mat("Carga", (0.80, 0.60, 0.36), 0.9),
    "cable_rojo": mat("Cable rojo", (0.8, 0.02, 0.02), 0.5),
    "cable_negro": mat("Cable negro", (0.01, 0.01, 0.01), 0.5),
    "led": mat("LED", (0.1, 1.0, 0.25), 0.3, emit=6.0),
    "base": mat("Base", (0.10, 0.55, 0.20), 0.6),
    "piso": mat("Piso", (0.80, 0.81, 0.83), 0.7),
}

ROBOT = bpy.data.collections.new("Robot")
scene.collection.children.link(ROBOT)
TRAY = bpy.data.collections.new("Bandeja y carga")
scene.collection.children.link(TRAY)
UNDER = bpy.data.collections.new("Piso y base")
scene.collection.children.link(UNDER)


def _add(obj, material, coll=None):
    obj.data.materials.append(material)
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    (coll or ROBOT).objects.link(obj)
    return obj


def box(name, size, loc, material, rot_z=0.0, coll=None, bevel=0.0006):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=(0, 0, rot_z))
    o = bpy.context.object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        b = o.modifiers.new("Bisel", "BEVEL")
        b.width = min(bevel, min(size) / 3)
        b.segments = 2
    return _add(o, material, coll)


def cyl(name, r, depth, loc, material, axis="Z", rot_z=0.0, coll=None, verts=40):
    rot = {"Z": (0, 0, rot_z), "Y": (math.pi / 2, 0, rot_z), "X": (0, math.pi / 2, rot_z)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.object
    o.name = name
    bpy.ops.object.shade_auto_smooth()
    return _add(o, material, coll)


def plate(name, lx, ly, t, z, material, cx=0.0, r=0.01, coll=None):
    """Placa con esquinas redondeadas; z es la cara inferior."""
    pts = []
    for sx, sy, a0 in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        ox, oy = sx * (lx / 2 - r), sy * (ly / 2 - r)
        for i in range(9):
            a = math.radians(a0 + i * 90 / 8)
            pts.append((cx + ox + r * math.cos(a), oy + r * math.sin(a)))
    n = len(pts)
    verts = [(x, y, z) for x, y in pts] + [(x, y, z + t) for x, y in pts]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    faces += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    return _add(o, material, coll)


# ---- Chasis de aluminio -----------------------------------------------------
plate("Chasis de aluminio", L, W, T, Z_PLATE, M["chasis"], r=0.008)

# Tracción: motorreductor amarillo + llanta de 65 mm a cada lado.
for side, tag in ((1, "izq"), (-1, "der")):
    box(f"Motorreductor {tag}", (0.070, 0.022, 0.019), (AXLE_X, side * 0.034, WHEEL_R), M["motor"], bevel=0.0015)
    box(f"Soporte motor {tag}", (0.012, 0.022, 0.0025), (AXLE_X, side * 0.034, Z_PLATE - 0.0012), M["metal"], bevel=0)
    # Eje de salida hacia la llanta.
    cyl(f"Eje {tag}", 0.0017, 0.020, (AXLE_X, side * 0.055, WHEEL_R), M["metal"], "Y", verts=16)
    cyl(f"Llanta {tag}", WHEEL_R, WHEEL_W, (AXLE_X, side * (W / 2 + 0.0135 + 0.003), WHEEL_R), M["llanta"], "Y")
    cyl(f"Rin {tag}", WHEEL_R * 0.66, WHEEL_W + 0.0015, (AXLE_X, side * (W / 2 + 0.0135 + 0.003), WHEEL_R), M["rin"], "Y")
    # Disco encoder en el otro extremo del eje, con su sensor de ranura (F249).
    cyl(f"Disco encoder {tag}", 0.0105, 0.0015, (AXLE_X, side * 0.0225, WHEEL_R), M["negro"], "Y")
    for k in (-1, 1):
        box(f"F249 horquilla {tag}", (0.004, 0.0022, 0.013),
            (AXLE_X + 0.0095, side * 0.0225 + k * 0.0035, WHEEL_R), M["pcb_azul"], bevel=0)
    box(f"F249 placa {tag}", (0.0016, 0.013, 0.015), (AXLE_X + 0.0125, side * 0.0225, WHEEL_R + 0.001), M["pcb_azul"], bevel=0)

# Rueda loca delantera.
cyl("Rueda loca - poste", 0.004, Z_PLATE - 0.012, (0.070, 0, 0.012 + (Z_PLATE - 0.012) / 2), M["metal"])
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.008, location=(0.070, 0, 0.008))
ball = bpy.context.object
ball.name = "Rueda loca - balin"
bpy.ops.object.shade_smooth()
_add(ball, M["metal"])

# ---- Electrónica sobre el chasis -------------------------------------------
# Portapilas 4 x AA con interruptor, atrás.
box("Portapilas 4xAA", (0.063, 0.057, 0.017), (-0.052, 0, TOP + 0.0085), M["negro"], bevel=0.0012)
box("Portapilas - interruptor", (0.011, 0.007, 0.007), (-0.074, 0.0, TOP + 0.0205), M["negro"], bevel=0.0008)
box("Portapilas - palanca", (0.004, 0.003, 0.005), (-0.074, 0.0, TOP + 0.0255), M["rin"], bevel=0)
box("Cable rojo", (0.020, 0.0012, 0.0012), (-0.0105, -0.010, TOP + 0.010), M["cable_rojo"], bevel=0)
box("Cable negro", (0.020, 0.0012, 0.0012), (-0.0105, -0.0135, TOP + 0.007), M["cable_negro"], bevel=0)

# Protoboard con el ESP32 y el driver TB6612FNG.
box("Protoboard 400", (0.083, 0.055, 0.0085), (0.022, 0, TOP + 0.00425), M["blanco"])
pb = TOP + 0.0085
box("ESP32 DevKit", (0.052, 0.028, 0.0016), (0.012, 0, pb + 0.0045), M["pcb_negro"])
box("ESP32 - modulo", (0.018, 0.016, 0.003), (0.027, 0, pb + 0.0068), M["metal"])
box("ESP32 - USB", (0.006, 0.008, 0.003), (-0.011, 0, pb + 0.0068), M["metal"], bevel=0)
box("Driver TB6612FNG", (0.021, 0.021, 0.0016), (0.0505, 0, pb + 0.0045), M["pcb_rojo"])
box("Driver - chip", (0.008, 0.006, 0.002), (0.0505, 0, pb + 0.0062), M["pcb_negro"], bevel=0)
cyl("LED bicolor", 0.0025, 0.007, (0.062, -0.0205, pb + 0.0035), M["led"])

# Ultrasónico HC-SR04P al frente, con su soporte.
ux, uz = L / 2 - 0.006, TOP + 0.014
box("HC-SR04P", (0.0016, 0.045, 0.020), (ux, 0, uz), M["pcb_azul"], bevel=0)
box("HC-SR04P - soporte", (0.012, 0.030, 0.002), (ux - 0.006, 0, TOP + 0.001), M["metal"], bevel=0)
for k in (-1, 1):
    cyl("HC-SR04P - transductor", 0.008, 0.012, (ux + 0.007, k * 0.013, uz), M["metal"], "X")

# ---- Bandeja de cartón con la carga ----------------------------------------
TRAY_CX = -0.015
for sx in (-0.060, 0.030):
    for sy in (1, -1):
        cyl("Separador", 0.003, STANDOFF, (sx, sy * 0.036, TOP + STANDOFF / 2), M["laton"], verts=6, coll=TRAY)
plate("Bandeja de carton", 0.110, 0.085, 0.003, TOP + STANDOFF, M["carton"], cx=TRAY_CX, r=0.006, coll=TRAY)
box("Carga (ejemplo)", (0.050, 0.045, 0.040), (TRAY_CX, 0, TOP + STANDOFF + 0.003 + 0.020), M["carga"],
    rot_z=math.radians(10), coll=TRAY, bevel=0.001)

# ---- Escena -----------------------------------------------------------------
bpy.ops.mesh.primitive_plane_add(size=6, location=(0, 0, 0))
floor = bpy.context.object
floor.name = "Piso"
floor.data.materials.append(M["piso"])
for c in list(floor.users_collection):
    c.objects.unlink(floor)
UNDER.objects.link(floor)
box("Base (cinta verde)", (0.20, 0.20, 0.001), (0, 0, 0.0005), M["base"], coll=UNDER, bevel=0)

world = bpy.data.worlds.new("Mundo")
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (0.90, 0.93, 0.97, 1)
bg.inputs["Strength"].default_value = 0.45
scene.world = world


def aim(obj, target):
    d = Vector(target) - obj.location
    obj.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


def light(name, loc, energy, size):
    d = bpy.data.lights.new(name, "AREA")
    d.energy = energy
    d.size = size
    o = bpy.data.objects.new(name, d)
    o.location = loc
    scene.collection.objects.link(o)
    aim(o, (0, 0, 0.05))


light("Luz principal", (0.45, -0.38, 0.65), 6, 0.6)
light("Luz de relleno", (-0.40, 0.50, 0.45), 2.2, 0.8)
light("Luz trasera", (-0.50, -0.45, 0.35), 2.2, 0.5)
light("Luz inferior", (0.20, -0.10, -0.40), 3, 0.6)

cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
cam.data.lens = 55
cam.data.clip_start = 0.01
scene.collection.objects.link(cam)
scene.camera = cam

scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x = 1280
scene.render.resolution_y = 960
scene.render.image_settings.file_format = "PNG"
scene.view_settings.view_transform = "Standard"


def shot(filename, loc, target):
    cam.location = loc
    aim(cam, target)
    scene.render.filepath = os.path.join(IMG, filename)
    bpy.ops.render.render(write_still=True)
    print("render:", scene.render.filepath)


shot("mini_frente.png", (0.36, -0.30, 0.20), (0.0, 0, 0.06))
shot("mini_atras.png", (-0.34, -0.30, 0.22), (0.0, 0, 0.06))

# Sin bandeja ni carga: se ve la electrónica.
for o in TRAY.objects:
    o.hide_render = True
shot("mini_interior.png", (0.17, -0.21, 0.34), (0.0, 0, 0.045))

# Desde abajo, sin piso: motores, discos encoder y sensores de rueda.
for o in UNDER.objects:
    o.hide_render = True
shot("mini_abajo.png", (0.20, -0.26, -0.06), (0.0, 0, 0.035))

for o in TRAY.objects:
    o.hide_render = False
for o in UNDER.objects:
    o.hide_render = False
cam.location = (0.36, -0.30, 0.20)
aim(cam, (0.0, 0, 0.06))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "robot_mini.blend"))
