shader_type canvas_item;

// the left/right look amount. Ideally clamp this externally to prevent viewing edges
uniform float scroll = 0.0;

uniform float opacity = 0.5;

// keep positive to maintain pseudo3D effect.
uniform float displacement_scale = 2.0;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

// easiest to just make this a curve texture, but making PNG gives a ton of control across the Y axis. Curve texture is just super smooth and doesn't have any issues with tearing.
uniform sampler2D displacement_map : hint_default_black;

void fragment(){
	vec2 uv = UV + vec2(random(vec2(round(TIME*10.0), round(TIME*10.1))) * 1.01, random(vec2(round(TIME*10.0), round(TIME*10.1))) * 1.02); // scroll the UV
	float displacement = texture(displacement_map, UV).r; // pull amount from map
	displacement *= displacement_scale; // scale
	displacement *= (0.5 - uv.y); // transform based on distance from center horizontal
	COLOR = texture(TEXTURE, uv + vec2(0.0, displacement));// pull source image, displaced by scroll and vertical stretch.
	COLOR.a = opacity;
}

uniform float scale = 1;
uniform vec2 offset = vec2(0.0,0.0);

void vertex(){
	UV = (VERTEX + offset) * TEXTURE_PIXEL_SIZE * (1.0/scale);
}