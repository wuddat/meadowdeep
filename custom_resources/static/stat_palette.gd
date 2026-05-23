class_name StatPalette
extends Resource

const STAT_COLORS := {
	"PWR": Color(0.90, 0.15, 0.15),  # red
	"AGI": Color(0.95, 0.85, 0.10),  # yellow
	"RES": Color(0.20, 0.75, 0.30),  # green
	"MYS": Color(0.55, 0.25, 0.80),  # purple
	"FOC": Color(0.95, 0.55, 0.10),  # orange
}

const BASE_VALUE := 0.85
const SHADOW_LERP := 0.55
const HIGHLIGHT_LERP := 0.45
const SATURATION_FULL_AT := 400.0  # total points at which color fully blooms


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
		return Color.from_hsv(0.0, 0.0, BASE_VALUE)

	var blended_hue: float = wrapf(vec.angle(), 0.0, TAU) / TAU
	var direction_purity: float = clampf(vec.length() / total, 0.0, 1.0)
	var depth: float = clampf(total / SATURATION_FULL_AT, 0.0, 1.0)
	var saturation: float = direction_purity * depth
	return Color.from_hsv(blended_hue, saturation, BASE_VALUE)


static func build_gradient(identity: CreatureIdentity) -> GradientTexture1D:
	var base := compute(identity)
	var grad := Gradient.new()
	grad.set_color(0, base.lerp(Color.BLACK, SHADOW_LERP))
	grad.set_color(1, base.lerp(Color.WHITE, HIGHLIGHT_LERP))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	return tex
