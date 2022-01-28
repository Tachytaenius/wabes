uniform vec2 windowSize;

uniform sampler2D previousOutflow;
uniform sampler2D space;

vec4 effect(vec4 colour, sampler2D pressure, vec2 imageCoords, vec2 windowCoords) {
	vec2 coordsLeft = (windowCoords + vec2(-1.0, 0.0 )) / windowSize;
	vec2 coordsUp = (windowCoords + vec2(0.0,  -1.0)) / windowSize;
	vec2 coordsRight = (windowCoords + vec2(1.0,  0.0 )) / windowSize;
	vec2 coordsDown = (windowCoords + vec2(0.0,  1.0 )) / windowSize;
	
	return Texel(previousOutflow, imageCoords) + Texel(pressure, imageCoords).r - vec4(
		Texel(pressure, coordsLeft  ).r * Texel(space, coordsLeft  ).r,
		Texel(pressure, coordsUp    ).r * Texel(space, coordsUp    ).r,
		Texel(pressure, coordsRight ).r * Texel(space, coordsRight ).r,
		Texel(pressure, coordsDown  ).r * Texel(space, coordsDown  ).r
	);
}
