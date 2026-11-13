"""Genera el prototipo 3D del robot de carga y sus imágenes.

Uso (desde la raíz del repositorio):
    blender -b -P docs/modelo/generar_prototipo.py

Produce docs/img/robot_prototipo_frente.png, robot_prototipo_atras.png,
robot_prototipo_interior.png y docs/modelo/robot_prototipo.blend.
Medidas en metros; el frente del robot apunta a +X.
"""
import math
import os

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.normpath(os.path.join(HERE, "..", "img"))
os.makedirs(IMG, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---- Medidas del diseño -----------------------------------------------------
L, W = 0.28, 0.22          # largo x ancho de las placas
T = 0.005                  # espesor de placa (MDF 5 mm; 3 mm también sirve)
WHEEL_R, WHEEL_W = 0.0325, 0.026
Z1 = 0.048                 # cara inferior de la placa 1 (chasis)
GAP12 = 0.050              # separadores entre placa 1 y placa 2
GAP23 = 0.040              # separadores entre placa 2 y bandeja
Z2 = Z1 + T + GAP12        # cara inferior de la placa 2 (electrónica)
Z3 = Z2 + T + GAP23        # cara inferior de la bandeja
TRAY_L = 0.22
TRAY_X = 0.03              # la bandeja deja libre la parte trasera (paro, switch)
AXLE_X = -0.05             # eje de las ruedas motrices


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
    "mdf": mat("MDF", (0.50, 0.33, 0.17), 0.8),
    "queso": mat("Bandeja", (1.0, 0.72, 0.05), 0.45),
    "tapete": mat("Antideslizante", (0.03, 0.03, 0.035), 0.95),
    "llanta": mat("Llanta", (0.02, 0.02, 0.02), 0.9),
    "rin": mat("Rin", (0.95, 0.80, 0.10), 0.5),
    "metal": mat("Metal", (0.75, 0.76, 0.78), 0.3, 1.0),
    "laton": mat("Laton", (0.80, 0.62, 0.25), 0.35, 1.0),
    "negro": mat("Plastico negro", (0.03, 0.03, 0.03), 0.5),
    "pcb_azul": mat("PCB azul", (0.02, 0.12, 0.45), 0.4),
    "pcb_negro": mat("PCB negro", (0.02, 0.02, 0.03), 0.4),
    "pcb_rojo": mat("PCB rojo", (0.55, 0.03, 0.03), 0.4),
    "blanco": mat("Protoboard", (0.92, 0.92, 0.90), 0.6),
    "celda": mat("Celda 18650", (0.05, 0.45, 0.42), 0.35),
    "rojo": mat("Paro", (0.80, 0.02, 0.02), 0.35),
    "amarillo": mat("Base paro", (0.95, 0.80, 0.05), 0.5),
    "carton": mat("Carga", (0.62, 0.45, 0.28), 0.9),
    "led": mat("LED", (0.1, 1.0, 0.25), 0.3, emit=6.0),
    "piso": mat("Piso", (0.80, 0.81, 0.83), 0.7),
}

ROBOT = bpy.data.collections.new("Robot")
scene.collection.children.link(ROBOT)
TRAY = bpy.data.collections.new("Bandeja y carga")
scene.collection.children.link(TRAY)


def _add(obj, material, coll=None):
    obj.data.materials.append(material)
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    (coll or ROBOT).objects.link(obj)
    return obj


def box(name, size, loc, material, rot_z=0.0, coll=None, bevel=0.0008):
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


def cyl(name, r, depth, loc, material, axis="Z", rot_z=0.0, coll=None, verts=48):
    rot = {"Z": (0, 0, rot_z), "Y": (math.pi / 2, 0, rot_z), "X": (0, math.pi / 2, rot_z)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.object
    o.name = name
    bpy.ops.object.shade_auto_smooth()
    return _add(o, material, coll)


def plate(name, lx, ly, t, z, material, cx=0.0, r=0.02, coll=None):
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


# ---- Chasis (placa 1): tracción y energía -----------------------------------
plate("Placa 1 - chasis", L, W, T, Z1, M["mdf"])
top1 = Z1 + T

for side, tag in ((1, "izq"), (-1, "der")):
    y = side * (W / 2 + 0.006 + WHEEL_W / 2)
    cyl(f"Llanta {tag}", WHEEL_R, WHEEL_W, (AXLE_X, y, WHEEL_R), M["llanta"], "Y")
    cyl(f"Rin {tag}", WHEEL_R * 0.62, WHEEL_W + 0.002, (AXLE_X, y, WHEEL_R), M["rin"], "Y")
    cyl(f"Cople {tag}", 0.007, 0.012, (AXLE_X, side * (W / 2 + 0.001), WHEEL_R), M["laton"], "Y", verts=6)
    # Motorreductor 25 mm con encoder, bajo la placa.
    cyl(f"Reductora {tag}", 0.0125, 0.024, (AXLE_X, side * 0.090, WHEEL_R), M["laton"], "Y")
    cyl(f"Motor {tag}", 0.0120, 0.032, (AXLE_X, side * 0.062, WHEEL_R), M["metal"], "Y")
    cyl(f"Encoder {tag}", 0.0125, 0.008, (AXLE_X, side * 0.042, WHEEL_R), M["pcb_negro"], "Y")
    box(f"Soporte motor {tag}", (0.030, 0.003, Z1 - WHEEL_R + 0.014),
        (AXLE_X, side * 0.103, (Z1 + WHEEL_R - 0.014) / 2 + 0.0), M["metal"])

# Rueda loca delantera.
cyl("Rueda loca - cuerpo", 0.011, Z1 - 0.014, (0.105, 0, 0.014 + (Z1 - 0.014) / 2), M["metal"])
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.0095, location=(0.105, 0, 0.0095))
ball = bpy.context.object
ball.name = "Rueda loca - balin"
bpy.ops.object.shade_smooth()
_add(ball, M["metal"])

# Batería 3S (3 celdas 18650 en portapilas) al centro y abajo: centro de gravedad bajo.
box("Portapilas 3x18650", (0.078, 0.062, 0.012), (0.035, 0, top1 + 0.006), M["negro"])
for i in (-1, 0, 1):
    cyl(f"Celda 18650 {i + 2}", 0.009, 0.065, (0.035, i * 0.0195, top1 + 0.016), M["celda"], "X")
box("BMS 3S", (0.050, 0.016, 0.003), (0.035, 0.045, top1 + 0.0015), M["pcb_azul"])

# Driver de motores y convertidor buck, atrás junto a los motores.
box("Driver TB6612FNG", (0.021, 0.021, 0.0016), (-0.085, 0.030, top1 + 0.006), M["pcb_rojo"])
box("Driver - chip", (0.008, 0.006, 0.002), (-0.085, 0.030, top1 + 0.0078), M["pcb_negro"], bevel=0)
box("Buck LM2596", (0.043, 0.021, 0.0016), (-0.085, -0.035, top1 + 0.006), M["pcb_azul"])
cyl("Buck - bobina", 0.006, 0.006, (-0.075, -0.035, top1 + 0.010), M["negro"])
cyl("Buck - capacitor", 0.004, 0.010, (-0.098, -0.035, top1 + 0.012), M["metal"])

# ---- Separadores ------------------------------------------------------------
for sx in (1, -1):
    for sy in (1, -1):
        cyl("Separador 50mm", 0.003, GAP12, (sx * (L / 2 - 0.015), sy * (W / 2 - 0.015), top1 + GAP12 / 2),
            M["laton"], verts=6)

# ---- Placa 2: electrónica y sensores ----------------------------------------
plate("Placa 2 - electronica", L, W, T, Z2, M["mdf"])
top2 = Z2 + T

box("Protoboard 400", (0.083, 0.055, 0.009), (0.015, 0, top2 + 0.0045), M["blanco"])
box("ESP32 DevKit", (0.052, 0.028, 0.0016), (0.015, 0, top2 + 0.0135), M["pcb_negro"])
box("ESP32 - modulo WROOM", (0.018, 0.016, 0.003), (0.030, 0, top2 + 0.0158), M["metal"])
box("ESP32 - USB", (0.006, 0.008, 0.003), (-0.009, 0, top2 + 0.0158), M["metal"], bevel=0)
box("IMU MPU6050", (0.021, 0.016, 0.0016), (AXLE_X, 0, top2 + 0.004), M["pcb_azul"])


def ultrasonico(name, x, y, ang):
    """HC-SR04 vertical; ang = hacia dónde mira (rad, 0 = frente)."""
    c, s = math.cos(ang), math.sin(ang)
    z = top2 + 0.012
    box(name, (0.0016, 0.045, 0.020), (x, y, z), M["pcb_azul"], rot_z=ang)
    box(name + " - escuadra", (0.012, 0.030, 0.002), (x - c * 0.006, y - s * 0.006, top2 + 0.001), M["metal"], rot_z=ang)
    for k in (-1, 1):
        px = x + c * 0.007 - s * k * 0.013
        py = y + s * 0.007 + c * k * 0.013
        cyl(name + " - transductor", 0.008, 0.012, (px, py, z), M["metal"], "X", rot_z=ang)


ultrasonico("HC-SR04 frontal", L / 2 - 0.008, 0, 0)
ultrasonico("HC-SR04 izquierdo", L / 2 - 0.035, W / 2 - 0.012, math.radians(55))
ultrasonico("HC-SR04 derecho", L / 2 - 0.035, -(W / 2 - 0.012), math.radians(-55))

# Zona trasera libre: paro de emergencia, interruptor, LED de estado y buzzer.
cyl("Paro - base", 0.021, 0.012, (-0.110, 0, top2 + 0.006), M["amarillo"])
cyl("Paro - vastago", 0.008, 0.010, (-0.110, 0, top2 + 0.017), M["negro"])
cyl("Paro - hongo", 0.020, 0.010, (-0.110, 0, top2 + 0.027), M["rojo"])
box("Interruptor general", (0.020, 0.013, 0.012), (-0.112, -0.060, top2 + 0.006), M["negro"])
box("Interruptor - tecla", (0.012, 0.009, 0.003), (-0.112, -0.060, top2 + 0.013), M["rojo"], bevel=0)
cyl("LED bicolor", 0.004, 0.008, (-0.112, 0.055, top2 + 0.004), M["led"])
cyl("Buzzer", 0.006, 0.009, (-0.112, 0.078, top2 + 0.0045), M["negro"])

# ---- Bandeja de carga -------------------------------------------------------
# Los delanteros van detrás de los sensores laterales para no taparlos.
for sx in (TRAY_X - TRAY_L / 2 + 0.015, 0.075):
    for sy in (1, -1):
        cyl("Separador 40mm", 0.003, GAP23, (sx, sy * (W / 2 - 0.015), top2 + GAP23 / 2), M["laton"], verts=6)

plate("Bandeja", TRAY_L, W, T, Z3, M["queso"], cx=TRAY_X, coll=TRAY)
top3 = Z3 + T
RIM = 0.015
for sy in (1, -1):
    box("Bandeja - borde lateral", (TRAY_L - 0.036, 0.004, RIM), (TRAY_X, sy * (W / 2 - 0.002), top3 + RIM / 2),
        M["queso"], coll=TRAY)
for sx in (1, -1):
    box("Bandeja - borde", (0.004, W - 0.036, RIM), (TRAY_X + sx * (TRAY_L / 2 - 0.002), 0, top3 + RIM / 2),
        M["queso"], coll=TRAY)
box("Tapete antideslizante", (TRAY_L - 0.012, W - 0.012, 0.002), (TRAY_X, 0, top3 + 0.001), M["tapete"], coll=TRAY)
box("Carga (ejemplo)", (0.10, 0.08, 0.07), (TRAY_X, 0, top3 + 0.002 + 0.035), M["carton"],
    rot_z=math.radians(12), coll=TRAY, bevel=0.0015)

# ---- Escena: piso, luces, cámara -------------------------------------------
bpy.ops.mesh.primitive_plane_add(size=6, location=(0, 0, 0))
floor = bpy.context.object
floor.name = "Piso"
floor.data.materials.append(M["piso"])

world = bpy.data.worlds.new("Mundo")
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (0.90, 0.93, 0.97, 1)
bg.inputs["Strength"].default_value = 0.45
scene.world = world


def light(name, loc, energy, size):
    d = bpy.data.lights.new(name, "AREA")
    d.energy = energy
    d.size = size
    o = bpy.data.objects.new(name, d)
    o.location = loc
    scene.collection.objects.link(o)
    aim(o, (0, 0, 0.08))


def aim(obj, target):
    from mathutils import Vector
    d = Vector(target) - obj.location
    obj.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


light("Luz principal", (0.6, -0.5, 0.9), 7, 0.8)
light("Luz de relleno", (-0.5, 0.7, 0.6), 2.5, 1.0)
light("Luz trasera", (-0.7, -0.6, 0.5), 2.5, 0.6)

cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
cam.data.lens = 55
scene.collection.objects.link(cam)
scene.camera = cam

scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 64
scene.cycles.use_denoising = True
scene.render.resolution_x = 1600
scene.render.resolution_y = 1200
scene.render.image_settings.file_format = "PNG"
scene.view_settings.view_transform = "Standard"


def shot(filename, loc, target=(0.0, 0, 0.085)):
    cam.location = loc
    aim(cam, target)
    scene.render.filepath = os.path.join(IMG, filename)
    bpy.ops.render.render(write_still=True)
    print("render:", scene.render.filepath)


shot("robot_prototipo_frente.png", (0.62, -0.50, 0.40))
shot("robot_prototipo_atras.png", (-0.60, -0.48, 0.46))

# Vista interior: sin bandeja ni carga, desde arriba.
for o in TRAY.objects:
    o.hide_render = True
shot("robot_prototipo_interior.png", (0.30, -0.42, 0.62), target=(0.0, 0, 0.07))
for o in TRAY.objects:
    o.hide_render = False

cam.location = (0.62, -0.50, 0.40)
aim(cam, (0.0, 0, 0.085))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "robot_prototipo.blend"))
