class_name BodySprites
extends RefCounted

# Rig built from /Users/.../妖刀姬 PSD. All joint positions live in PSD canvas
# coords (PSD pixels, 679×685, origin top-left) — that's the artist's reference
# frame and the only place these constants need to be edited if the PSD changes.
# Everything is converted to fighter-local coords via psd_to_fighter() on demand.

# ─── PSD-space joint constants (the single source of truth) ────────────────
# Naming convention: "front" = visually closer to camera (in front of torso);
# "back" = farther from camera (behind torso). Character is 3/4 view facing right
# → left side of body is closer to camera (front), right side is behind. The
# sword is held in the character's RIGHT hand → sword arm is the BACK arm.
const PSD_X_CENTER := 400.0            # necklace x — character's spine
const PSD_Y_FEET := 626.0              # foot bbox bottom
const PSD_NECK := Vector2(400, 429)    # head ↔ torso junction (necklace centre)
const PSD_SHOULDER_BACK := Vector2(466, 419)   # 右手 shoulder — sword arm
const PSD_SHOULDER_FRONT := Vector2(318, 412)  # 左手 shoulder — off-hand
const PSD_HIP_BACK := Vector2(426, 510)        # 右腿 hip
const PSD_HIP_FRONT := Vector2(350, 511)       # 左腿 hip
const PSD_FOOT_BACK := Vector2(426, 626)
const PSD_FOOT_FRONT := Vector2(350, 626)
const PSD_HAND_BACK := Vector2(485, 510)       # 右手 hand — sword grip
const PSD_HAND_FRONT := Vector2(315, 525)      # 左手 hand — off-hand
const PSD_WEAPON_TIP := Vector2(320, 485)

const FIGHTER_FOOT_Y := 32.0           # matches the existing stick-figure feet line

# Z-order — lower draws first (further back). Matches the artist's PSD layer
# stack: sword arm + sword behind torso, off-hand in front, bangs above everything.
const Z_PONYTAIL := 0
const Z_ARM_BACK := 10          # sword arm — behind torso
const Z_SWORD := 11             # sword — behind torso, just in front of sword arm
const Z_SHEATH := 12            # scabbard — strapped behind body
const Z_LEG_BACK := 20          # 右腿 — behind left leg
const Z_LEG_FRONT := 25         # 左腿 — in front of right leg, still under torso
const Z_TORSO := 30
const Z_SHORTS := 31
const Z_CHEST := 32
const Z_NECKLACE := 33
const Z_ARM_FRONT := 45         # off-hand — in front of torso
const Z_EAR := 50
const Z_HEAD := 55
const Z_EYE_SOCKET := 60
const Z_PUPIL := 61
const Z_BROW := 62
const Z_FOREHEAD_MARK := 63
const Z_MOUTH := 64
const Z_EARRING := 65
const Z_HAIRBAND := 70
const Z_BANGS := 80             # 左1/2/3 + 右1/2/3 刘海 — covers face (top)

class Part:
	var name: String
	var texture: Texture2D
	var psd_origin: Vector2     # top-left in PSD canvas
	var psd_size: Vector2
	# pivot_psd: world-space joint this part anchors to (PSD coords).
	# For limbs this is the shoulder/hip; for head/torso it's the neck;
	# for accessories that follow the head it's the part's own centre.
	var pivot_psd: Vector2
	# natural_angle: only used by limbs/sword. Direction the texture's "free end"
	# points in local texture coords (radians, +X = 0, +Y down = π/2).
	var natural_angle: float = 0.0
	var z: int = 0
	# attaches_to_head: parts whose pivot follows head's transform (face details + hair extras).
	# For these the renderer computes world position relative to the head's current pose.
	var attaches_to_head: bool = false
	# kind: 'limb', 'static', 'head_child' — drives the render path.
	var kind: String = "static"
	# Hair-specific: this part also gets an extra per-frame sway rotation applied
	# around its pivot (see pose_library._render_head_child). hair_amplitude
	# scales the sway and hair_phase staggers strands so they don't move in unison.
	var is_hair: bool = false
	var hair_amplitude: float = 1.0
	var hair_phase: float = 0.0
	# Chest jiggle: a torso-attached static part that gets a smaller, smoother
	# secondary sway rotation around its top-centre pivot. See pose_library._chest_sway.
	var is_chest_jiggle: bool = false

var parts: Array = []           # ordered by z-order
var by_name: Dictionary = {}
var scale: float = 0.15         # ≈ stick-figure height (74 fighter units)

# ─── Public API ────────────────────────────────────────────────────────────
func is_complete() -> bool:
	# Need at least the seven core body parts to render anything meaningful.
	for needed in ["head", "torso", "arm_back", "arm_front", "leg_back", "leg_front", "sword"]:
		if not by_name.has(needed):
			return false
	return true

func psd_to_fighter(p: Vector2) -> Vector2:
	return Vector2((p.x - PSD_X_CENTER) * scale, (p.y - PSD_Y_FEET) * scale + FIGHTER_FOOT_Y)

# Offset in fighter coords from PSD joint A to PSD joint B (sign convention preserved).
func psd_offset_to_fighter(a: Vector2, b: Vector2) -> Vector2:
	return (b - a) * scale

# ─── Loader ────────────────────────────────────────────────────────────────
static func load_default(rig_dir: String) -> BodySprites:
	var b := BodySprites.new()
	var manifest_path: String = rig_dir + "/manifest.json"
	var f: FileAccess = FileAccess.open(manifest_path, FileAccess.READ)
	if f == null:
		push_warning("rig manifest not found at %s" % manifest_path)
		return b
	var raw: String = f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY or not data.has("layers"):
		push_warning("rig manifest malformed: %s" % manifest_path)
		return b
	var layers: Dictionary = data["layers"]
	for name in layers.keys():
		var info: Dictionary = layers[name]
		var part_path: String = rig_dir + "/" + name + ".png"
		var tex: Texture2D = _load_tex(part_path)
		if tex == null:
			continue
		var part := Part.new()
		part.name = name
		part.texture = tex
		part.psd_origin = Vector2(float(info["l"]), float(info["t"]))
		part.psd_size = Vector2(float(info["w"]), float(info["h"]))
		_configure_part(part)
		b.parts.append(part)
		b.by_name[name] = part
	b.parts.sort_custom(func(a, c): return a.z < c.z)
	return b

static func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var r: Resource = load(path)
		if r is Texture2D:
			return r
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

# Per-part rig metadata. Pivots are joint positions in PSD canvas coords.
# Natural angles measured from pivot toward the part's "free end" in texture space.
static func _configure_part(p: Part) -> void:
	match p.name:
		# Limbs: pivot at the joint, free end hangs DOWN in the texture (+Y, π/2).
		"arm_back":
			p.pivot_psd = PSD_SHOULDER_BACK; p.natural_angle = PI * 0.5
			p.kind = "limb"; p.z = Z_ARM_BACK
		"arm_front":
			p.pivot_psd = PSD_SHOULDER_FRONT; p.natural_angle = PI * 0.5
			p.kind = "limb"; p.z = Z_ARM_FRONT
		"leg_back":
			p.pivot_psd = PSD_HIP_BACK; p.natural_angle = PI * 0.5
			p.kind = "limb"; p.z = Z_LEG_BACK
		"leg_front":
			p.pivot_psd = PSD_HIP_FRONT; p.natural_angle = PI * 0.5
			p.kind = "limb"; p.z = Z_LEG_FRONT
		"sword":
			# Pivot at the grip (back hand — the character holds the sword in
			# their right hand, which is the back arm in this layer stack).
			# Blade extends to upper-left in the texture → natural angle ≈
			# atan2(-25, -165) ≈ -2.99 rad (≈ -171°, ≈ π).
			p.pivot_psd = PSD_HAND_BACK; p.natural_angle = -2.99
			p.kind = "limb"; p.z = Z_SWORD
		# Statics — drawn at a fixed joint with body_rotation only.
		"head":
			p.pivot_psd = PSD_NECK; p.kind = "static"; p.z = Z_HEAD
		"torso":
			p.pivot_psd = PSD_NECK; p.kind = "static"; p.z = Z_TORSO
		"sheath":
			p.pivot_psd = p.psd_origin + p.psd_size * 0.5; p.kind = "static"; p.z = Z_SHEATH
		"shorts":
			p.pivot_psd = p.psd_origin + p.psd_size * 0.5; p.kind = "static"; p.z = Z_SHORTS
		"chest":
			# Pivot at the top-centre (clavicle area) so the chest layer pendulums
			# from its upper attachment when the body moves.
			p.pivot_psd = Vector2(p.psd_origin.x + p.psd_size.x * 0.5, p.psd_origin.y + 2)
			p.kind = "static"
			p.z = Z_CHEST
			p.is_chest_jiggle = true
		"necklace":
			p.pivot_psd = p.psd_origin + p.psd_size * 0.5; p.kind = "static"; p.z = Z_NECKLACE
		# Head children — follow head's pivot + any body rotation.
		"eye_socket_back":
			_set_head_child(p, Z_EYE_SOCKET)
		"eye_socket_front":
			_set_head_child(p, Z_EYE_SOCKET)
		"pupil_back":
			_set_head_child(p, Z_PUPIL)
		"pupil_front":
			_set_head_child(p, Z_PUPIL)
		"brow_back":
			_set_head_child(p, Z_BROW)
		"brow_front":
			_set_head_child(p, Z_BROW)
		"forehead_mark":
			_set_head_child(p, Z_FOREHEAD_MARK)
		"mouth":
			_set_head_child(p, Z_MOUTH)
		"ear":
			_set_head_child(p, Z_EAR)
		"earring":
			_set_head_child(p, Z_EARRING)
		"hairband":
			_set_head_child(p, Z_HAIRBAND)
		"ponytail":
			# Ponytail attaches at the hair-tie (≈ where 发带 sits) and swings the
			# most because it's the longest strand. Pivot is set explicitly rather
			# than from the bbox top — the bbox top is the highest stray strand,
			# not the actual attachment.
			p.pivot_psd = Vector2(315, 135)
			p.kind = "head_child"
			p.attaches_to_head = true
			p.z = Z_PONYTAIL
			p.is_hair = true
			p.hair_amplitude = 1.0
			p.hair_phase = 0.0
		# 左1/2/3 + 右1/2/3 are all front bangs (刘海) — pivot at the hairline so
		# each strand swings from where it joins the scalp.
		"hair_back_1":
			_set_bang(p, 0.55, 0.2)
		"hair_back_2":
			_set_bang(p, 0.60, 0.55)
		"hair_back_3":
			_set_bang(p, 0.70, 0.95)
		"hair_front_1":
			_set_bang(p, 0.50, 1.3)
		"hair_front_2":
			_set_bang(p, 0.60, 1.7)
		"hair_front_3":
			_set_bang(p, 0.70, 2.1)
		_:
			# Unknown layer — drop it.
			p.kind = "skip"
			p.z = 999

static func _set_head_child(p: Part, z: int) -> void:
	# Anchor at the part's own centre in PSD coords — when rendered, this point
	# lands at the head_pivot + offset_from_head_pivot.
	p.pivot_psd = p.psd_origin + p.psd_size * 0.5
	p.kind = "head_child"
	p.attaches_to_head = true
	p.z = z

# Bang (刘海) configuration: pivot at the top-centre of the strand (the hairline
# attachment), apply per-strand amplitude/phase so the bangs sway with motion.
static func _set_bang(p: Part, amplitude: float, phase: float) -> void:
	p.pivot_psd = Vector2(p.psd_origin.x + p.psd_size.x * 0.5, p.psd_origin.y + 4)
	p.kind = "head_child"
	p.attaches_to_head = true
	p.z = Z_BANGS
	p.is_hair = true
	p.hair_amplitude = amplitude
	p.hair_phase = phase
