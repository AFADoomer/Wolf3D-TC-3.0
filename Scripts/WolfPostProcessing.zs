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

// Handle swapping out items if a custom SoD or Lost Episodes map is loaded with Wolf3D, or vice versa.
// Can be toggled by setting 'g_sod' CVar and restarting map - but won't work for default maps

class WolfPostProcessor : LevelPostProcessor
{
	protected void Apply(Name checksum, String mapname)
	{
		uint count = GetThingCount();
	
		for (uint i = 0; i < count; i++)
		{
			uint e = GetThingEdNum(i);

			if (e < 20000 || e > 22089 || (e >= 21075 && e <= 21089)) { continue; }

			e = e % 1000;

			if (e > 22 && e < 75 || e == 124) // Objects
			{
				if (e == 51) { SetThingEdNum(i, 21000 + clamp(g_sod, 0, 2) * 100 + e); }
				else { SetThingEdNum(i, 21000 + (g_sod > 1 ? 200 : 0) + e); }
			}
			else if (e > 0 && e < 160 || e > 200 && e < 206) // Standard Enemies
			{
				if (e == 106) { SetThingEdNum(i, 20000 + clamp(g_sod, 1, 3) * 1000 + e); }
				else { SetThingEdNum(i, 20000 + (g_sod > 1 ? 2000 : 1000) + e); }
			}
			else if (e >= 107 && e <= 161) // SoD Bosses
			{
				SetThingEdNum(i, 20000 + (g_sod > 1 ? 2000 : 1000) + e);
			}
		}
	}
}