class_name StatPalette
extends Resource

# ── Stat → hue source of truth ────────────────────────────────────────────────
const STAT_COLORS := {
	"PWR": Color(0.90, 0.15, 0.15),  # red
	"RES": Color(0.95, 0.85, 0.10),  # yellow
	"AGI": Color(0.20, 0.75, 0.30),  # green
	"MYS": Color(0.55, 0.25, 0.80),  # purple
	"FOC": Color(0.95, 0.55, 0.10),  # orange
}

const BASE_VALUE := 0.65            # midtone brightness of the blended color
const SATURATION_FULL_AT := 100.0   # total points at which color fully blooms

# ── Painterly shading (warm highlights, cool shadows) ─────────────────────────
const WARM_ANCHOR := 0.08           # hue highlights rotate toward (orange-yellow)
const COOL_ANCHOR := 0.62           # hue shadows rotate toward (blue-violet)
const SHADOW_HUE_PULL := 0.30
const HIGHLIGHT_HUE_PULL := 0.25
const SHADOW_SAT_BOOST := 0.5      # shadows get richer
const HIGHLIGHT_SAT_DROP := 0.9    # highlights wash out slightly
const SHADOW_VALUE := 0.45          # brightness of the darkest band
const HIGHLIGHT_VALUE := 1.0        # brightness of the brightest band

# Greenie's painted shading steps as luminance offsets (dark→light).
# Near-identical brightnesses already merged — they collapse harmlessly.
# Lift these per-creature if a species has a different tonal structure.
const RAMP_LUMA := [0.0, 0.285, 0.337, 0.369, 0.399, 0.431, 0.462,
	0.471, 0.504, 0.542, 0.567, 0.585, 0.594, 0.650, 0.678, 0.698,
	0.708, 0.718, 0.738, 0.761, 0.792, 0.848, 0.873, 0.879]


# ═══════════════════════════════════════════════════════════════════════════════
# Public
# ═══════════════════════════════════════════════════════════════════════════════

# Blended stat color: hue = vector sum of stat hues (leans toward dominant stat,
# opposing stats cancel toward gray), saturation = specialization × investment.
static func compute(identity: CreatureIdentity) -> Color:
	if not identity:
		return Color.from_hsv(0.0, 0.0, BASE_VALUE)

	var weights := {
		"PWR": float(identity.PWR.points) if identity.PWR else 0.0,
		"AGI": float(identity.AGI.points) if identity.AGI else 0.0,
		"RES": float(identity.RES.points) if identity.RES else 0.0,
		"MYS": float(identity.MYS.points) if identity.MYS else 0.0,
		"FOC": float(identity.FOC.points) if identity.FOC else 0.0,
	}

	var vec := Vector2.ZERO
	var total := 0.0
	for stat in STAT_COLORS:
		var w: float = weights.get(stat, 0.0)
		if w <= 0.0:
			continue
		total += w
		var hue: float = STAT_COLORS[stat].h * TAU
		vec += Vector2(cos(hue), sin(hue)) * w

	if vec.length() < 0.001 or total <= 0.0:
		return Color.from_hsv(0.2, 0.2, BASE_VALUE)

	var blended_hue: float = wrapf(vec.angle(), 0.0, TAU) / TAU
	var direction_purity: float = clampf(vec.length() / total, 0.0, 1.0)
	var depth: float = clampf(total / SATURATION_FULL_AT, 0.0, 1.0)
	var saturation: float = direction_purity * depth
	return Color.from_hsv(blended_hue, saturation, BASE_VALUE)


# Banded, hue-shifted ramp keyed by source luminance. Hard pixel-art steps
# (constant interpolation) land at the sprite's painted shading positions;
# each band is filled with the stat-derived color, shaded cool→warm.
static func build_gradient(identity: CreatureIdentity) -> GradientTexture1D:
	var base := compute(identity)
	var shadow := _shift(base, COOL_ANCHOR, SHADOW_HUE_PULL, SHADOW_SAT_BOOST, SHADOW_VALUE)
	var highlight := _shift(base, WARM_ANCHOR, HIGHLIGHT_HUE_PULL, -HIGHLIGHT_SAT_DROP, HIGHLIGHT_VALUE)

	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for off in RAMP_LUMA:
		offsets.append(off)
		if off < 0.5:
			colors.append(shadow.lerp(base, off / 0.5))            # shadow → base
		else:
			colors.append(base.lerp(highlight, (off - 0.5) / 0.5))  # base → highlight

	var grad := Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	grad.offsets = offsets
	grad.colors = colors

	var tex := GradientTexture1D.new()
	tex.gradient = grad
	return tex


# ═══════════════════════════════════════════════════════════════════════════════
# Internal
# ═══════════════════════════════════════════════════════════════════════════════

# Rotate `base`'s hue toward `anchor` the short way around the wheel,
# adjust saturation and set an explicit value. Returns the shaded color.
static func _shift(base: Color, anchor: float, pull: float, sat_delta: float, value: float) -> Color:
	return Color.from_hsv(
		_lerp_hue(base.h, anchor, pull),
		clampf(base.s + sat_delta, 0.0, 1.0),
		value
	)


# Shortest-path circular interpolation between two hues (0–1).
static func _lerp_hue(from: float, to: float, t: float) -> float:
	var diff := to - from
	if diff > 0.5:
		diff -= 1.0
	elif diff < -0.5:
		diff += 1.0
	return wrapf(from + diff * t, 0.0, 1.0)
