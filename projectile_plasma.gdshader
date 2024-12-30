shader_type spatial;

void fragment() {
    vec3 glow_color = vec3(0.0, 0.8, 1.0); // Blue-green plasma color
    ALBEDO = glow_color;
    EMISSION = glow_color * 2.0; // Glow intensity
}
