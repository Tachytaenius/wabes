uniform vec2 windowSize;
uniform float borderSize;
uniform bool greyscale;

uniform sampler2D space;

vec4 effect(vec4 colour, sampler2D pressure, vec2 imageCoords, vec2 windowCoords) {
	imageCoords = (windowCoords - borderSize) / (windowSize - borderSize * 2.0);
	float pressureHere = Texel(pressure, imageCoords).r;
	if (greyscale) {
		return vec4(vec3(pressureHere + 0.5), 1.0);
	} else {
		float spaceHere = 0.0 < imageCoords.x && imageCoords.x < 1.0 && 0.0 < imageCoords.y && imageCoords.y < 1.0 ? Texel(space, imageCoords).r : 1.0;
		return vec4(pressureHere, -pressureHere, 1.0 - spaceHere, 1.0);
	}
}
