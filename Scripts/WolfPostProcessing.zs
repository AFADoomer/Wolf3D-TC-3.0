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
		// Bare-bones compatibility with Relighting mod...  Darken the maps so that 
		// the dynamic lights show up and the mod has some chance of working properly
		int relighting = Wads.CheckNumForFullName("zscript/hd_relighting.zs");
		if (relighting > -1)
		{
			for (int sec = 0; sec < level.sectors.Size(); sec++)
			{
				if (level.sectors[sec].lightlevel == 255) { level.sectors[sec].SetLightLevel(192); }
			}
		}

		uint count = GetThingCount();
	
		for (uint i = 0; i < count; i++)
		{
			uint e = GetThingEdNum(i);

			if (e < 20000 || e > 22089 || (e >= 21075 && e <= 21089)) { continue; }

			uint f = e % 1000;

			if (e > 21022 && e < 21075 || e > 21122 && e < 21175 || e > 21222 && e < 21275) // Objects
			{
				if (f == 124) { SetThingEdNum(i, 21000 + (g_sod > 1 ? 200 : 0) + f); }
				else
				{
					f = e % 100;
					if (
						f == 33 ||
						f == 38 ||
						f == 45 ||
						f == 51 ||
						f == 63 ||
						f >= 67 && f <= 69 ||
						f >= 71 && f <= 74
					) { SetThingEdNum(i, 21000 + clamp(g_sod, 0, 2) * 100 + f); }
					else { SetThingEdNum(i, 21000 + (g_sod > 1 ? 200 : 0) + f); }
				}
			}
			else if (e > 20000 && e < 20006 || e > 21000 && e < 21006 || e > 20200 && e < 20206 || f == 106) // Standard Enemies
			{
				if (f == 106) { SetThingEdNum(i, 20000 + clamp(g_sod, 1, 3) * 1000 + f); }
				else { SetThingEdNum(i, 20000 + (g_sod > 1 ? 2000 : 0) + f); }
			}
			else if (f >= 107 && f <= 161) // SoD Bosses
			{
				SetThingEdNum(i, 20000 + (g_sod > 1 ? 2000 : 1000) + f);
			}
		}
	}
}