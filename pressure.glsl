float sum(vec4 v) {
	return dot(v, vec4(1));
}

uniform float damping;

uniform sampler2D previousPressure;
uniform sampler2D space;

vec4 effect(vec4 colour, sampler2D outflow, vec2 imageCoords, vec2 windowCoords) {
	float newPressure = (Texel(previousPressure, imageCoords).r - 0.5 * (1.0 - damping) * sum(Texel(outflow, imageCoords))) * Texel(space, imageCoords).r;
	return vec4(newPressure, 0.0, 0.0, 1.0);
}
