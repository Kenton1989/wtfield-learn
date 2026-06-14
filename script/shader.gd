extends Node

const SHADER_PARAM_BLINK_ENABLED := &"blink_enabled"

func set_blink_enabled(material: Material, enabled: bool):
	if material == null:
		push_warning("missing material")
		return

	var shader = material as ShaderMaterial
	if shader == null:
		push_warning("material is not sharder material")
		return

	shader.set_shader_parameter(SHADER_PARAM_BLINK_ENABLED, enabled)
