/*
 * Copyright (c) 2022 AFADoomer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

// Use an overlay texture to alpha mask an existing texture
//  Used to transform Wolf3D sprite shadows into translucent pixels so that they 
//  map onto any surface/floor texture, not just the original flat gray.  

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
		if (uLightFactor >= 1.0)
		{
			color.a = 0.0;
		}
		else
		{
			// Lighten the light spots
			color.r = mix(minlight, lightcolor.r, 2.0 * shadowmap.r * lightcolor.r);
			color.g = mix(minlight, lightcolor.g, 2.0 * shadowmap.g * lightcolor.g);
			color.b = mix(minlight, lightcolor.b, 2.0 * shadowmap.b * lightcolor.b);
			color.a = clamp(-alpha * lightcolor.a, 0.0, 1.0);
		}
	}

	return color;
}