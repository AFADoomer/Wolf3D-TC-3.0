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
// Can be toggled by setting 'g_sod' CVar and restarting map

const MAXDOORS = 14;

class WolfPostProcessor : LevelPostProcessor
{
	protected void Apply(Name checksum, String mapname)
	{
		CVar dynlights = CVar.FindCvar("g_dynamiclights");

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
		else if (dynlights && dynlights.GetInt())
		{
			for (int sec = 0; sec < level.sectors.Size(); sec++)
			{
				if (level.sectors[sec].lightlevel > 229) { level.sectors[sec].SetLightLevel(229); }
			}
		}

		// Use color-coded door textures
		if (g_usedoorkeycolors)
		{
			for (int g = 0; g < 4; g++)
			{
				for (int l = 1; l < 3; l++)
				{
					for (int s = 0x41; s < 0x45; s++)
					{
						level.ReplaceTextures(String.Format("WLF%iLK%i%c", g, l, s), String.Format("WLF%iLK%i%c", g, l, s + 4), 0);
					}
				}
			}
		}

		Array<ActorTranslation> translations;
		ParseActorTranslations(translations);
		uint count = GetThingCount();
		int g, temp;
		[temp, g] = Game.IsSod(); 
	
		for (uint i = 0; i < count; i++)
		{
			uint e = GetThingEdNum(i);

			int j;
			for (j = 0; j < translations.Size(); j++)
			{
				if (
					translations[j] &&
					(
						translations[j].games[0] == e ||
						translations[j].games[1] == e ||
						translations[j].games[2] == e ||
						translations[j].games[3] == e
					)
				) { break; }
			}

			if (j < translations.Size() && g >= 0)
			{
				SetThingEdNum(i, translations[j].games[g]);
			}
		}

		// Move doors into place
		MapHandler handler = MapHandler.Get();
		if (handler && level.mapname ~== "Level")
		{
			if (!handler.queuedmap) { handler.queuedmap = handler.parsedmaps.GetMapData("Wolf3D TC Test"); }
			
			if (handler.queuedmap)
			{
				// Make sure that lines that will be exposed to the player face the 
				// inside of the map (so that all animated walls/switches work properly) 
				for (int l = 0; l < level.lines.Size(); l++)
				{
					Line ln = level.lines[l];

					int x1, x2, y1, y2;
					x1 = x2 = int((ln.v1.p.x + ln.v2.p.x) / 2);
					y1 = y2 = int((ln.v1.p.y + ln.v2.p.y) / 2);

					if (ln.v1.p.y == ln.v2.p.y)
					{
						if (ln.v2.p.x > ln.v2.p.x) { y1 += 32; y2 -= 32; }
						else if (ln.v2.p.x < ln.v2.p.x) { y1 -= 32; y2 += 32; }	
					}
					else if (ln.v1.p.x == ln.v2.p.x)
					{
						if (ln.v1.p.y > ln.v2.p.y) { x1 += 32; x2 -= 32; }
						else if (ln.v1.p.y < ln.v2.p.y) { x1 -= 32; x2 +- 32; }
					}

					int t1 = handler.TileAt((x1, y1));
					int t2 = handler.TileAt((x2, y2));

					if (t1 < 0x6A && t1 < 0x6A) { continue; } // Void space; ignore
					else if (t1 < 0x6A) // t2 is floor, t1 is a wall
					{
						if (y1 > y2 || x1 > x2) { continue; }
						FlipLineCompletely(ln.Index());
					}
					else if (t2 < 0x6A) // t1 is floor, t2 is a wall
					{
						if (y1 < y2 || x1 < x2) { continue; }
						FlipLineCompletely(ln.Index());
					}
				}

				// Index and place polyobject doors

				int startspots[3][256];
				int doorcount[3];

				// Find all of the start spots and store them in an array by type
				for (uint i = 0; i < count; i++)
				{
					uint e = GetThingEdNum(i);

					// Polyobject Start Spot
					if (e == 9301)
					{
						int id = GetThingAngle(i);
						int index = (id > 128 ? 2 : id > 64 ? 1 : 0);

						startspots[index][id - index * 64] = i; // Insert in numerical order so number will match order of use
					}
				}

				// Position door polyobjects in the map
				for (int y = 0; y < 64; y++)
				{
					for (int x = 0; x < 64; x++)
					{
						int a = handler.queuedmap.ActorAt((x, y));
						int t = handler.queuedmap.TileAt((x, y));

						if ((t < 0x5A || t > 0x65) && a != 0x62) { continue; }

						Vector2 pos = ParsedMap.GridToCoords((x, y));
						int doortype = -1; // Invalid door type

						if (t >= 0x5A && t <= 0x65 && !handler.queuedmap.CheckForDoorTiles((x, y), 0x6A))
						{
							doortype = !!(t % 2); // E/W or N/S
						}

						if (t > 0 && t < 0x6A && a == 0x62) // Pushwall
						{
							// Special handling for secret door placed on top of normal door
							if (doortype > -1)
							{
								int spotindex = startspots[2][++doorcount[2]];
								SetThingXY(spotindex, pos.x, pos.y);
								AddThing(22101, (pos, 0), GetThingAngle(spotindex));
							}
							else
							{
								doortype = 2;
							}
						}

						if (doortype < 0) { continue; }

						int spotindex = startspots[doortype][++doorcount[doortype]];
						SetThingXY(spotindex, pos.x, pos.y);

						// Spawn door sound player for doors that were placed in the map
						AddThing(22101, (pos, 0), GetThingAngle(spotindex));
					}
				}
			}
		}
		else
		{
			// Spawn door sound player
			for (uint i = 0; i < count; i++)
			{
				uint e = GetThingEdNum(i);

				// Polyobject Start Spot
				if (e == 9301)
				{
					Vector3 sPos = GetThingPos(i);
					AddThing(22101, sPos, GetThingAngle(i));
				}
			}
		}
	}

	void ParseActorTranslations(out Array<ActorTranslation> translations)
	{
		int lump = -1;
		lump = Wads.CheckNumForFullName("Data/ActorTranslations.txt");

		if (lump != -1)
		{
			Array<String> lines;
			String data = Wads.ReadLump(lump);
			data.Split(lines, "\n");

			for (int i = 0; i < lines.Size(); i++)
			{
				ActorTranslation t = ActorTranslation.Add(lines[i]);
				if (t) { translations.Push(t); }
			}
		}
	}
}

class ActorTranslation
{
	int games[4];

	static ActorTranslation Add(String entry)
	{
		Array<String> values;

		entry.split(values, ",");
		if (values.Size() < 4) { return null; }

		ActorTranslation t = New("ActorTranslation");
		t.games[0] = values[0].ToInt();
		t.games[1] = values[1].ToInt();
		t.games[2] = values[2].ToInt();
		t.games[3] = values[3].ToInt();

		return t;
	}
}