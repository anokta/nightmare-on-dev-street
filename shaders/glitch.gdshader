shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform bool is_active = true;
uniform float glitch_speed : hint_range(0.0, 30.0) = 10.0;
uniform float glitch_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float block_count : hint_range(1.0, 50.0) = 15.0;
uniform float color_split : hint_range(0.0, 0.05) = 0.01;

// Simple pseudo-random hash function based on a 2D vector.
float random_hash(vec2 uv) {
    return fract(sin(dot(uv, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    if (is_active) {		
        vec2 distorted_uv = SCREEN_UV;
		
		// horizontal displacement
        float time_step = floor(TIME * glitch_speed);
        float block_y = floor(SCREEN_UV.y * block_count);
        float line_noise = random_hash(vec2(block_y, time_step));
        if (line_noise > 0.7) {
            distorted_uv.x += (random_hash(vec2(time_step, block_y)) - 0.5) * glitch_intensity;
        }

		// chromatic abbreviation.
        float r = texture(screen_texture, distorted_uv + vec2(color_split * line_noise, 0.0)).r;
        float g = texture(screen_texture, distorted_uv).g;
        float b = texture(screen_texture, distorted_uv - vec2(color_split * line_noise, 0.0)).b;

        COLOR = vec4(r, g, b, 1.0);
    } else {
        COLOR = texture(screen_texture, SCREEN_UV);
	}
}
