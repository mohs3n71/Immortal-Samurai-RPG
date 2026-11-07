shader_type spatial;
render_mode cull_disabled;

// World-space ground: grass with large tonal patches, dirt paths (mask R)
// and a stream/pond with a sandy shore (mask G). Shared by the lowland plane,
// plateau tops and ramps so surfaces line up seamlessly.

uniform sampler2D grass_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D mask_texture : repeat_disable, filter_linear;
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 mask_origin = vec2(-150.0, -150.0);
uniform float mask_size = 300.0;
uniform float grass_tile = 26.0;
uniform float dirt_tile = 12.0;
uniform vec3 grass_light : source_color = vec3(0.93, 0.96, 0.8);
uniform vec3 grass_dark : source_color = vec3(0.74, 0.84, 0.64);
uniform float grass_desaturation = 0.3;
uniform vec3 path_rim : source_color = vec3(0.42, 0.5, 0.26);
uniform vec3 shore_color : source_color = vec3(0.85, 0.77, 0.55);
uniform vec3 water_shallow : source_color = vec3(0.33, 0.72, 0.78);
uniform vec3 water_deep : source_color = vec3(0.16, 0.45, 0.62);

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	vec4 mask = texture(mask_texture, (p - mask_origin) / mask_size);
	float broad = texture(noise_texture, p * 0.012).r;
	float fine = texture(noise_texture, p * 0.09).r;

	vec3 grass = texture(grass_texture, p / grass_tile).rgb;
	grass = mix(grass, vec3(dot(grass, vec3(0.299, 0.587, 0.114))), grass_desaturation);
	grass *= mix(grass_dark, grass_light, smoothstep(0.32, 0.68, broad));

	float path_value = mask.r + (fine - 0.5) * 0.22;
	float rim = smoothstep(0.36, 0.46, path_value);
	float path = smoothstep(0.46, 0.54, path_value);
	vec3 dirt = texture(dirt_texture, p / dirt_tile).rgb * mix(0.92, 1.08, fine);
	vec3 color = mix(grass, grass * path_rim * 1.6, rim * (1.0 - path));
	color = mix(color, dirt, path);

	float water_value = mask.g + (fine - 0.5) * 0.12;
	float shore = smoothstep(0.34, 0.42, water_value);
	float wet = smoothstep(0.44, 0.5, water_value);
	float water = smoothstep(0.5, 0.54, water_value);
	color = mix(color, shore_color, shore);
	color = mix(color, shore_color * 0.72, wet);
	vec3 liquid = mix(water_shallow, water_deep, smoothstep(0.56, 0.9, water_value));
	float ripple = sin(p.x * 0.9 + TIME * 1.6 + fine * 7.0) * sin(p.y * 0.75 - TIME * 1.1 + broad * 5.0);
	liquid += vec3(0.12) * smoothstep(0.82, 1.0, ripple);
	liquid += vec3(0.18) * (1.0 - smoothstep(0.54, 0.6, water_value));
	color = mix(color, liquid, water);

	ALBEDO = color;
	ROUGHNESS = mix(1.0, 0.3, water);
	SPECULAR = mix(0.15, 0.5, water);
}
