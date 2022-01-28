uniform vec2 windowSize;

uniform float toAdd;
uniform sampler2D current;
uniform float falloff;

vec4 effect(vec4 colour, sampler2D image, vec2 imageCoords, vec2 windowCoords) {
	float falloff = falloff < 0.0 ? 1.0 / (-falloff + 1.0) : falloff + 1.0;
	vec4 currentToReturn = Texel(current, windowCoords / windowSize);
	currentToReturn.r += toAdd * pow(1.0 - min(length(imageCoords * 2.0 - 1.0), 1.0), falloff);
	return currentToReturn;
}
