// Use an overlay texture to alpha mask an existing texture
//  Used to transform Wolf3D sprite shadows into translucent pixels so that they 
//  map onto any surface/floor texture, not just the original flat gray.  
//  Written by AFADoomer

// Mac shadow color approximation
//const vec4 shadowcolor = vec4(0.23, 0.18, 0.09, 2.0);

// PC shadow color
const vec4 shadowcolor = vec4(0.0, 0.0, 0.0, 1.0);

// Approximation of Wolf3D's lightest 'cast light' pixel color 
const vec4 lightcolor = vec4(0.816, 0.816, 0.816, 0.816);

const float maxshade = 0.43;
const float minlight = 0.57;

vec4 ProcessTexel()
{
	vec4 color = getTexel(vTexCoord.st);

	// Ignore anything in the top percentage of the image, as configured 
	// via CLIPHEIGHT define, or defaulting to 85% if not defined
#ifdef CLIPHEIGHT
	float shadowclip = CLIPHEIGHT;
#else
	float shadowclip = 0.85;
#endif

	if (vTexCoord.t < shadowclip) { return color; }

	vec4 shadowmap = texture(shadow, vTexCoord.st);

	if (textureSize(shadow, 0) == ivec2(1, 1))
	{
		// If blank shadow map is provided, fudge the shadow based on gray elements in
		// the bottom of the sprite image - not perfect, but good for many sprites
		if (vTexCoord.t > shadowclip && color.rgb != vec3(0.0) && color.r < maxshade && color.r == color.g && color.g == color.b)
		{
			shadowmap = color;
		}
		else { return color; }
	}

	if (shadowmap.a == 0.0) { return color; }

	// Calculate an alpha to approximate original shade/appearance on 
	// the default Wolf3D floor color
	float alpha = 2.0 * mix(0.0, 1.0, maxshade - shadowmap.r) * color.a;

	if (alpha > 0.0)
	{
		// Shade the dark spots
		color.rgb = shadowcolor.rgb;
		color.a = clamp(alpha * shadowcolor.a, 0.0, 1.0);
	}
	else
	{
		// Lighten the light spots
		color.r = mix(minlight, lightcolor.r, 2.0 * shadowmap.r * lightcolor.r);
		color.g = mix(minlight, lightcolor.g, 2.0 * shadowmap.g * lightcolor.g);
		color.b = mix(minlight, lightcolor.b, 2.0 * shadowmap.b * lightcolor.b);
		color.a = clamp(-alpha * lightcolor.a, 0.0, 1.0);
	}

	return color;
}