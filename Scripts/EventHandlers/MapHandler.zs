/*
 * Copyright (c) 2024 AFADoomer
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

Class TileInfo
{
	enum TileFlags
	{
		TILE_DIRECTIONAL = 1,
		TILE_AMBUSH = 2,
		TILE_SECRETEXIT = 4,
		TILE_FLOOR = 8,
		TILE_WALL = 16,
		TILE_FONT = 32,
		TILE_SOLID = TILE_WALL | TILE_FONT,
		TILE_DOOR = 64,
		TILE_DOORFRAME = 128,
		TILE_INVALID = 256,
	};

	uint id;
	String tex[2], alttex[2];
	uint special;
	uint args[5];
	uint key;
	uint flags;

	void ParsePattern(ParsedValue tiledata)
	{
		String match = tiledata.GetString("Pattern");
		if (!match.length()) { return; }

		if (flags & TileInfo.TILE_FONT)
		{
			tex[0] = FileReader.StripQuotes(match);
			return;
		}

		Array<String> patterns;
		match.Split(patterns, ",");

		if (patterns.Size() > 1)
		{
			tex[0] = String.Format(patterns[0], id);
			tex[1] = String.Format(patterns[1], id);
		}
		else
		{
			tex[0] = String.Format(patterns[0], (id - 1) * 2);
			tex[1] = String.Format(patterns[0], (id - 1) * 2 + 1);
		}

		tex[0] = FileReader.StripQuotes(tex[0]);
		tex[1] = FileReader.StripQuotes(tex[1]);
	}

	void ParseAltPattern(ParsedValue tiledata)
	{
		String match = tiledata.GetString("AltPattern", true);
		if (!match.length()) { return; }

		match.Substitute("\"", "");

		Array<String> patterns;
		match.Split(patterns, ",");

		if (patterns.Size() < 2) { return; }
		
		if (!key)
		{
			alttex[0] = patterns[0];
			alttex[1] = patterns[1];

			alttex[0] = FileReader.StripQuotes(alttex[0]);
			alttex[1] = FileReader.StripQuotes(alttex[1]);
			return;
		}

		alttex[0] = String.Format(patterns[0], key);
		alttex[1] = String.Format(patterns[1], key);

		alttex[0] = FileReader.StripQuotes(alttex[0]);
		alttex[1] = FileReader.StripQuotes(alttex[1]);
	}

	void ParseFlags(ParsedValue tiledata)
	{
		String match = tiledata.GetString("Flags");
		if (!match.length()) { return; }

		Array<String> flagvalues;
		match.Split(flagvalues, "|");

		for (int f = 0; f < flagvalues.Size(); f++)
		{
			String flag = flagvalues[f];
		
			if (flag ~== "Directional") { flags |= TileInfo.TILE_DIRECTIONAL; }
			else if (flag ~== "Ambush") { flags |= TileInfo.TILE_AMBUSH; }
			else if (flag ~== "SecretExit") { flags |= TileInfo.TILE_SECRETEXIT; }
			else if (flag ~== "Floor") { flags |= TileInfo.TILE_FLOOR; }
			else if (flag ~== "Wall") { flags |= TileInfo.TILE_WALL; }
			else if (flag ~== "Font") { flags |= TileInfo.TILE_FONT; }
			else if (flag ~== "Door") { flags |= TileInfo.TILE_DOOR; }
			else if (flag ~== "DoorFrame") { flags |= TileInfo.TILE_DOORFRAME; }
			else if (flag ~== "Invalid") { flags |= TileInfo.TILE_INVALID; }
		}
	}

	void ParseKey(ParsedValue tiledata)
	{
		key = tiledata.GetInt("Key");
		if (!key) { return; }

		alttex[0] = String.Format(alttex[0], key);
		alttex[1] = String.Format(alttex[1], key);
	}
	
	void ParseSpecial(ParsedValue tiledata)
	{
		String match = tiledata.GetString("Special");
		if (!match.length()) { return; }

		Array<String> specialstring;
		match.Split(specialstring, ",");

		if (specialstring.Size() == 0) { return; }
		special = specialstring[0].ToInt();

		for (int i = 1; i < specialstring.Size() && i < 5; i++)
		{
			args[i - 1] = specialstring[i].ToInt();
		}
	}
}

Class GameTileInfo
{
	String gamename;
	Array<TileInfo> Tiles;

	void ParseTileInfo(ParsedValue tiledata)
	{
		if (!tiledata.children.Size()) { return; }

		ParsedValue tiledefault = tiledata.Find("Default");
		if (tiledefault)
		{
			Array<int> tilerange;
			tiledefault.GetNumberList("Tiles", tilerange);

			if (tilerange.Size())
			{
				for (int i = 0; i < tilerange.Size(); i++)
				{
					TileInfo tile = GetTile(tilerange[i]);

					tile.ParseKey(tiledefault);
					tile.ParseFlags(tiledefault);
					tile.ParsePattern(tiledefault);
					tile.ParseAltPattern(tiledefault);
					tile.ParseSpecial(tiledefault);
				}
			}
		}

		for (int d = 0; d < tiledata.children.Size(); d++)
		{
			let tiles = tiledata.children[d];
			if (!tiles || tiles == tiledefault) { continue; }

			int tileindex = (tiles.keyname).ToInt();

			if (tileindex > 0)
			{
				TileInfo tile = GetTile(tileindex);

				tile.ParseKey(tiles);
				tile.ParseFlags(tiles);
				tile.ParsePattern(tiles);
				tile.ParseAltPattern(tiles);
				tile.ParseSpecial(tiles);
			}

			ParseTileInfo(tiles);
		}
	}

	TileInfo GetTile(int index)
	{
		if (Tiles.Size() <= index) { Tiles.Resize(index + 1); }
		if (!Tiles[index])
		{
			Tiles[index] = New("TileInfo");
			Tiles[index].id = index;
		}

		return Tiles[index];
	}

	TileInfo GetSpecialTile(int type)
	{
		for (int t = 0; t < Tiles.Size(); t++)
		{
			TileInfo tile = Tiles[t];
			if (tile && tile.flags & type) { return tile; }
		}

		return null;
	}

	void Add(ParsedValue tiledata)
	{
		gamename = tiledata.keyname;

		ParseTileInfo(tiledata);
	}

	static GameTileInfo Find(in out Array<GameTileInfo> tilemaps, String gamename, bool create = false)
	{
		GameTileInfo tilemap;

		for (int g = 0; g < tilemaps.Size(); g++)
		{
			tilemap = tilemaps[g];
			if (tilemap && tilemap.gamename ~== gamename) { return tilemap; }
		}

		if (!create) { return null; }

		tilemap = New("GameTileInfo");
		tilemap.gamename = gamename;
		tilemaps.Push(tilemap);

		return tilemap;
	}

	static TileInfo GetTileInfo(Array<GameTileInfo> tilemaps, String gamename, int tileid)
	{
		if (tileid < 0) { return null; }

		GameTileInfo tilemap = Find(tilemaps, gamename);
		if (!tilemap || tileid >= tilemap.Tiles.Size() || !tilemap.Tiles[tileid]) { tilemap = Find(tilemaps, "Default"); }
		if (!tilemap || tileid >= tilemap.Tiles.Size() || !tilemap.Tiles[tileid]) { return null; }

		return tilemap.Tiles[tileid];
	}

	static TileInfo GetSpecialTileInfo(Array<GameTileInfo> tilemaps, String gamename, int type)
	{
		if (type <= 0) { return null; }

		TileInfo tile;
		GameTileInfo tilemap;
		
		tilemap = Find(tilemaps, gamename);
		if (tilemap)
		{
			tile = tilemap.GetSpecialTile(type);
			if (tile) { return tile; }
		}

		tilemap = Find(tilemaps, "Default");
		if (tilemap) { return tilemap.GetSpecialTile(type); }
		
		return null;
	}
}

Class ActorMap : ParsedValue
{
	static ParsedValue GetActor(ParsedValue actormaps, int gametype, int index, int skill)
	{
		String istr = String.Format("%i", index);
		ParsedValue gm, am;

		switch (gametype)
		{
			case 4:
				gm = actormaps.Find("BS");
				am = gm.Find(istr);
				if (am && am.GetInt("Skill") <= skill) { return am; }
				break;
			case 3:
				gm = actormaps.Find("SD3");
				am = gm.Find(istr);
				if (am && am.GetInt("Skill") <= skill) { return am; }
			case 2:
				gm = actormaps.Find("SD2");
				am = gm.Find(istr);
				if (am && am.GetInt("Skill") <= skill) { return am; }
			case 1:
				gm = actormaps.Find("SD1");
				am = gm.Find(istr);
				if (am && am.GetInt("Skill") <= skill) { return am; }
			case 0:
			default:
				gm = actormaps.Find("Default");
				am = gm.Find(istr);
				if (am && am.GetInt("Skill") <= skill) { return am; }
				break;
		}

		return null;
	}
}

class MapHandler : StaticEventHandler
{
	WolfMapParser parsedmaps;
	Array<DataFile> datafiles;
	ParsedMap curmap, queuedmap, secretmapnext;
	Array<int> activatedfloors;
	Array<int> activatedpushwalls;
	ParsedValue actormaps;
	Array<GameTileInfo> tilemaps;

	override void OnRegister()
	{
		ParseGameMaps();
		ParseActorMaps();
		ParseTileMaps();
	}

	void ParseGameMaps()
	{
		if (developer) { console.printf("Parsing map data..."); }

		// Parse the demo map first
		let d = DataFile.Find(datafiles, "Standalone Maps", "Data/EditorThings.map");
		WolfMapParser.Parse(parsedmaps, d);

		for (int l = 0; l < Wads.GetNumLumps(); l++)
		{
			String lumpname = Wads.GetLumpFullName(l);
			String shortlumpname = Wads.GetLumpName(l);
			if (shortlumpname ~== "gamemaps" || shortlumpname ~== "maptemp")
			{
				String headname = lumpname;
				headname.Substitute("gamemaps", "maphead");
				headname.Substitute("maptemp", "maphead");

				if (Wads.CheckNumForFullName(headname) > -1)
				{
					let e = DataFile.Find(datafiles, lumpname, lumpname, headname);
					WolfMapParser.Parse(parsedmaps, e);
				}
			}
			else if (lumpname.Mid(lumpname.Length() - 4) ~== ".map" || lumpname.Mid(lumpname.Length() - 4) ~== ".lvl")
			{
				d.path = lumpname;
				d.lump = l;
				WolfMapParser.Parse(parsedmaps, d);
			}
			else if (shortlumpname ~== "PLANES")
			{
				d.path = lumpname;
				d.lump = l;
				WolfMapParser.Parse(parsedmaps, d);
			}
			else if (lumpname.left(5) ~== "maps/" && lumpname.Mid(lumpname.Length() - 4) ~== ".wad")
			{
				ParseWadMap(l, shortlumpname);
			}
		}
	}

	void ParseWadMap(int lump, String mapname)
	{
		String data = Wads.ReadLump(lump);

		String header = data.left(4);
		int files = WolfMapParser.GetLittleEndian(data, 4, 4);
		int offset = WolfMapParser.GetLittleEndian(data, 8, 4);

		Array<WadEntry> entries;

		String directory = data.Mid(offset);
		while (directory.length())
		{
			let e = New("WadEntry");

			e.datalump = lump;
			e.offset = WolfMapParser.GetLittleEndian(directory, 0, 4);
			e.size = WolfMapParser.GetLittleEndian(directory, 4, 4);
			e.name = directory.Mid(8, 8);
			e.data = data.Mid(e.offset, e.size);

			entries.Push(e);

			directory = directory.Mid(16);
		}

		for (int d = 0; d < entries.Size(); d++)
		{
			let entry = entries[d];
			if (entry.name ~== "Planes")
			{
				int container = Wads.GetLumpContainer(lump);
				String containername = Wads.GetContainerName(container);
				containername.Replace(".wad", "");
				containername.Replace(".pk3", "");
				containername.Replace(".pk7", "");

				let d = DataFile.Find(datafiles, containername, mapname);
				d.path = mapname;
				d.lump = lump;

				Array<int> temp;
				parsedmaps.gametype = -1; // Play as Wolf, but allow setting via CVar
				parsedmaps.ReadGameMaps(entry.data, 0, temp, d, lump);
			}
		}
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (!parsedmaps) { return; }

		if (e.Name.Left(10) == "initialize")
		{
			String mapname = "Wolf3D TC Test";
			String datafile = "";
			if (e.Name.Length() > 11)
			{
				String data = e.Name.Mid(11);

				Array<String> splitdata;
				data.Split(splitdata, ":");

				mapname = splitdata[0];
				if (e.IsManual) { mapname.Substitute("_", " "); }

				if (splitdata.Size() > 1) { datafile = splitdata[1]; }
			}

			queuedmap = parsedmaps.GetMapData(mapname, datafile);

			if (gamestate == GS_LEVEL)
			{
				level.ChangeLevel("Level", 0, 0, g_warpskill);

				if (mapname == "Wolf3D TC Test")
				{
					console.printf("Use '\c[Yellow]netevent listmaps\c-' to see available maps.\nUse '\c[Yellow]netevent initialize:<mapname_with_underscores>\c-' to load a specific map.", e.Name);
				}
			}
		}
		else if (e.Name == "listmaps")
		{
			for (int m = 0; m < parsedmaps.maps.Size(); m++)
			{
				String mapname = parsedmaps.maps[m].mapname;
				console.printf("'%s' (%s)", mapname, parsedmaps.maps[m].datafile.path);
			}
		}
		else if (e.Name == "updatestyle" && !e.IsManual)
		{
			if (e.args[0] >= 0) { InitializeParsedMap(e.args[0], false); }
		}
	}

	override void WorldTick()
	{
		// Check for noclipping players; allow them to see through void space
		// by clearing sidedef flags that normally block rendering
		//
		// We are assuming that if they are noclipping, they don't care about
		// seeing parts of the map that they shouldn't actually be able to see
		if (!(level.mapname ~== "Level") || !curmap || curmap.noclip || level.time % 35) { return; } // only check every 35 tics for performance

		for (int p = 0; p < MAXPLAYERS; p++)
		{
			if (playeringame[p] && players[p].cheats & CF_NOCLIP)
			{
				curmap.noclip = true;
				break;
			}

			return;
		}
		
		for (int s = 0; s < level.sides.Size(); s++)
		{
			let side = level.sides[s];
			if (side) { side.flags &= ~Side.WALLF_BLOCKRENDERING; }
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		if (e.IsSaveGame) { return; }

		if (g_sod < 0)
		{
			CVar sodvar = CVar.FindCVar("g_sod");
			if (sodvar) { sodvar.SetInt(max(0, g_sod)); }
		}

		if (level.mapname ~== "Level" && queuedmap)
		{
			curmap = queuedmap;
			InitializeParsedMap(g_sod);
		}
		else
		{
			queuedmap = null;
			curmap = null;
		}
	}

	void InitializeParsedMap(int style = -1, bool initial = true)
	{
		if (!curmap) { return; }

		if (style < 0) { style = max(0, g_sod); }

		curmap.Initialize(style, initial);

		if (initial)
		{
			activatedfloors.Clear();
			activatedpushwalls.Clear();
		}

		if (!initial) { return; }

		if (curmap.info)
		{
			console.PrintfEx(PRINT_HIGH | PRINT_NONOTIFY, "\c[%s]%s\n", style <= 0 ? "DarkRed" : "Gold", StringTable.Localize(curmap.info.levelname, false));
			
			if (secretmapnext)
			{
				queuedmap = secretmapnext;
				secretmapnext = null;
				level.nextmap = "Level";
			}
			else
			{
				String nextmap = curmap.info.nextmap;
				if (nextmap.length() && nextmap.left(6) != "enDSeQ")
				{
					LevelInfo nextinfo = LevelInfo.FindLevelInfo(nextmap);
					if (nextinfo) { queuedmap = parsedmaps.GetMapDataByNumber(nextinfo.levelnum, curmap.datafile.path); }
					level.nextmap = "Level";
				}
			}

			String IMFname = curmap.info.music;

			CVar stylevar = CVar.GetCVar("g_musicstyle", players[consoleplayer]);
			if (stylevar && !stylevar.GetInt()) { S_ChangeMusic(IMFname); }
			else
			{
				GameHandler this = GameHandler(StaticEventHandler.Find("GameHandler"));
				if (!this) { S_ChangeMusic(IMFname); }
				else
				{
					String song = this.music.GetIfExists(IMFname);
					if (song.length()) { S_ChangeMusic(song); }
					else { S_ChangeMusic(IMFname); }
				}
			}
		}
		else
		{
			console.PrintfEx(PRINT_HIGH | PRINT_NONOTIFY, "\c[%s]%s\n", style <= 0 ? "DarkRed" : "Gold", curmap.mapname);
			level.nextmap = level.nextsecretmap = level.mapname;
		}
	}
	
	override void WorldLinePreActivated(WorldEvent e)
	{
		if (level.mapname ~== "Level")
		{
			Line ln = e.ActivatedLine;
			if (ln.special != 80 || ln.args[0] != 10) { return; }

			int side = 0;
			for (int s = 0; s < 2; s++)
			{
				let sidedef = ln.sidedef[s];
				if (sidedef.sector.CenterFloor() == e.Thing.cursector.CenterFloor()) { side = s; }
			}

			if (ln.args[2] == 10) // Secret map trigger
			{
				LevelInfo nextinfo;
				
				if (curmap.info.nextsecretmap.length())
				{
					nextinfo = LevelInfo.FindLevelInfo(curmap.info.nextsecretmap);
				}
				else
				{
					console.printf("\c[Red]Secret exit does not match orginal game!\n\c-Attempting proper level progression...");

					int levelnum = int(curmap.mapnum / 100) * 100;
					if (Game.IsSoD())
					{
						int check = curmap.mapnum % 100;

						// This is essentially a guess - who knows how mods have changed level progression...
						if (check < 12) { levelnum += 19; }
						else { levelnum += 20; }
					}
					else
					{
						// Secret map is always 10 unless someone made some executable changes
						levelnum += 10;
					}

					nextinfo = LevelInfo.FindLevelByNum(levelnum);
					secretmapnext = queuedmap; // Remember the normal next map so that the secret level's exit can return to it
				}
				
				if (nextinfo) { queuedmap = parsedmaps.GetMapDataByNumber(nextinfo.levelnum, curmap.datafile.path); }
			}
		}
	}

	override void PlayerSpawned (PlayerEvent e)
	{
		PlacePlayer(e.PlayerNumber);
	}

	override void PlayerRespawned (PlayerEvent e)
	{
		PlacePlayer(e.PlayerNumber);
	}

	void PlacePlayer(int p)
	{
		if (!(level.mapname ~== "Level")) { return; }
		if (!curmap) { return; }
		if (!playeringame[p] || !players[p].mo) { return; }

		Vector2 pos = curmap.startspot;

		int a = ActorAt(pos);
		double angle = 90 - (a - 0x13) * 90;

		players[p].mo.SetOrigin((curmap.GetNextSpot(pos, angle, p - 1, deathmatch), 0), false);
		players[p].mo.angle = angle;
	}

	void ParseActorMaps()
	{
		if (developer) { console.printf("Parsing actor data..."); }

		actormaps = FileReader.Parse("Data/ActorCodes.txt");
			
		for (int d = 0; d < actormaps.children.Size(); d++)
		{
			let gamedata = actormaps.children[d];
			
			for (int e = 0; e < gamedata.children.Size(); e++)
			{
				let entry = gamedata.children[e];

				String value = entry.value;

				Array<String> values;
				value.split(values, ",");
				if (!values.Size()) { values.Push(value); }
		
				ParsedValue m;
				m = entry.AddKey(true);
				m.keyname = "Class";
				m.value = ZScriptTools.Trim(values[0]);

				m = entry.AddKey(true);
				m.keyname = "Skill";
				if (values.Size() > 1) { m.value = ZScriptTools.Trim(values[1]); }
				else { m.value = "-1"; }
				
				m = entry.AddKey(true);
				m.keyname = "Angle";
				if (values.Size() > 2) { m.value = ZScriptTools.Trim(values[2]); }
				else { m.value = "270"; }

				m = entry.AddKey(true);
				m.keyname = "Patrolling";
				if (values.Size() > 3) { m.value = ZScriptTools.Trim(values[3]); }
				else { m.value = "0"; }

				entry.value = "";
			}
		}
	}

	void ParseTileMaps()
	{
		if (developer) { console.printf("Parsing tile data..."); }

		for (int l = 0; l < Wads.GetNumLumps(); l++)
		{
			String lumpname = Wads.GetLumpFullName(l);
			lumpname = lumpname.MakeLower();
			if (lumpname.IndexOf("data/tilecodes/") > -1)
			{
				ParsedValue tilemapdata = FileReader.Parse(lumpname);
				if (developer) { console.printf("Parsing %s tile data from '%s'...", tilemapdata.children[0].keyname, lumpname); }

				for (int d = 0; d < tilemapdata.children.Size(); d++)
				{
					let gamedata = tilemapdata.children[d];

					GameTileInfo gametiles = GameTileInfo.Find(tilemaps, gamedata.keyname, true);
					gametiles.Add(gamedata);
				}
			}
		}
	}

	static clearscope MapHandler Get()
	{
		return MapHandler(StaticEventHandler.Find("MapHandler"));
	}

	static ui ParsedMap GetCurrentMap()
	{
		MapHandler this = MapHandler.Get();
		if (!this) { return null; }

		return this.curmap;
	}

	static bool IsParsedMap()
	{
		return (level.mapname ~== "Level");
	}

	static int GetGameType()
	{
		MapHandler this = MapHandler.Get();
		if (!this || !this.curmap) { return -1; }

		return this.curmap.gametype;
	}

	static ui String GetMusic()
	{
		MapHandler this = MapHandler.Get();
		if (!this || !this.curmap || !this.curmap.info) { return level.music; }

		return this.curmap.info.music;
	}

	static int, TileInfo TileAt(Vector2 pos, ParsedMap curmap = null)
	{
		MapHandler this = MapHandler.Get();
		if (!this || !this.curmap) { return -1, null; }

		if (!curmap) { curmap = this.curmap; }
		if (!curmap) { return -1, null; }

		pos = ParsedMap.CoordsToGrid(pos);

		TileInfo tile;
		int t;
		[t, tile] = curmap.TileAt(pos);

		return t, tile;
	}

	static int ActorAt(Vector2 pos)
	{
		MapHandler this = MapHandler.Get();
		if (!this || !this.curmap) { return -1; }

		pos = ParsedMap.CoordsToGrid(pos);

		return this.curmap.ActorAt(pos);
	}

	static bool CheckPushwallAt(Vector2 pos)
	{
		MapHandler this = MapHandler.Get();
		if (!this || !this.curmap) { return -1; }

		pos = ParsedMap.CoordsToGrid(pos);

		int index = int(pos.y * this.curmap.width + pos.x);
		if (index >= this.activatedpushwalls.Size()) { return this.curmap.ActorAt(pos) == 0x62; }

		return (this.curmap.ActorAt(pos) == 0x62 && !this.activatedpushwalls[index]);
	}

	static bool MarkPushwallAt(Vector2 pos)
	{
		MapHandler this = MapHandler.Get();
		if (!this || !this.curmap) { return false; }

		if (!g_singlestartpushwalls) { return true; }

		pos = ParsedMap.CoordsToGrid(pos);

		int index = int(pos.y * this.curmap.width + pos.x);
		this.activatedpushwalls.Insert(index, true);

		return true;
	}

	static void ActivateFloorCode(Vector2 pos, Actor activator)
	{
		MapHandler this = MapHandler.Get();
		if (!this) { return; }

		TileInfo tile;
		int floor;
		[floor, tile] = MapHandler.TileAt(pos);

		if ((tile.flags & TileInfo.TILE_FLOOR) && this.activatedfloors.Find(floor) == this.activatedfloors.Size())
		{
			this.activatedfloors.Push(floor);

			let it = level.CreateActorIterator(floor, "Actor");
			Actor mo;

			while (mo = Actor(it.Next()))
			{
				if (!mo.bIsMonster || mo.bDormant || !mo.bShootable || mo.health <= 0 || mo.bAmbush) { continue; }

				let c = ClassicBase(mo);
				if (c)
				{
					if (c.bActive) { continue; }
					else { c.bActive = true; }
				}

				mo.target = activator;
				mo.SetState(mo.SeeState);
				mo.vel *= 0;

				if (mo.bBoss || mo.bFullVolSee)
				{
					mo.A_StartSound(mo.SeeSound, CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE);
				}
				else
				{
					mo.A_StartSound(mo.SeeSound, CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NORM);
				}
			}
		}
	}

	ui static int CountParsedMaps(bool all = false)
	{
		MapHandler this = MapHandler.Get();
		if (!this || !this.parsedmaps || !this.parsedmaps.maps.Size()) { return 0; }

		if (all) { return this.parsedmaps.maps.Size(); }

		int count = 0; 
		for (int m = 0; m < this.parsedmaps.maps.Size(); m++)
		{
			if (this.parsedmaps.maps[m].mapname ~== "Wolf3D TC Test") { continue; } // Don't count the demo map
			if (this.parsedmaps.maps[m].gametype == -1) { count++; }
		}

		return count;
	}
}

class ParsedMap
{
	String mapname;
	DataFile datafile;
	LevelInfo info;
	int mapnum;
	int gametype;
	String signature;
	int width;
	int height;
	Array<int> planes[3];
	Array<Sector> voidspace;
	bool noclip;
	Vector2 startspot;
	String hash;
	int lump;

	int, TileInfo TileAt(Vector2 pos, int style = -1)
	{
		if (pos.x < 0 || pos.x >= width || pos.y < 0 || pos.y >= height) { return -1, null; }

		int index = int(pos.y * width + pos.x);
		if (index < 0 || index >= planes[0].Size()) { return -1, null; } // Map edges return an invalid tile, but not "nothing"

		let this = MapHandler.Get();

		if (style < 0) { style = max(0, g_sod); }

		return planes[0][index], this ? GameTileInfo.GetTileInfo(this.tilemaps, GetGameName(style), planes[0][index]) : null;
	}

	TileInfo TileAtIndex(int index, int style = -1)
	{
		let this = MapHandler.Get();
		if (index < 0 || !this) { return null; }

		if (style < 0) { style = max(0, g_sod); }

		return GameTileInfo.GetTileInfo(this.tilemaps, GetGameName(style), index);
	}

	static String GetGameName(int gametype)
	{
		switch (gametype)
		{
			case 3:
				return "SD3";
			case 2:
				return "SD2";
			case 1:
				return "SD1";
			case 0:
			default:
				return "Default";
		}

		return "Default";
	}

	int ActorAt(Vector2 pos)
	{
		if (pos.x < 0 || pos.x > width || pos.y < 0 || pos.y > height) { return 0; }

		int index = int(pos.y * width + pos.x);
		if (index < 0 || index >= planes[1].Size()) { return 0; }

		return planes[1][index];
	}

	static Vector2 CoordsToGrid(Vector2 coords)
	{
		int width, height;
		width = height = 64;

		MapHandler this = MapHandler.Get();
		if (this)
		{
			if (this.curmap)
			{
				width = this.curmap.width;
				height = this.curmap.height;
			}
			else if (this.queuedmap)
			{
				width = this.queuedmap.width;
				height = this.queuedmap.height;
			}
		}

		return (int(floor(coords.x / 64)) + (width / 2), int(floor(-coords.y / 64)) + (height / 2));
	}

	static Vector2 GridToCoords(Vector2 coords)
	{
		int width, height;
		width = height = 64;

		MapHandler this = MapHandler.Get();
		if (this)
		{
			if (this.curmap)
			{
				width = this.curmap.width;
				height = this.curmap.height;
			}
			else if (this.queuedmap)
			{
				width = this.queuedmap.width;
				height = this.queuedmap.height;
			}
		}

		return ((coords.x - 32) * 64 + (width / 2), -(coords.y - 32) * 64 - (height / 2));
	}

	void ExpandData(int plane, String planedata, int encoding = 0xABCD, bool carmack = true)
	{
		if (!planedata.length()) { return; }

		Array<int> expanded;

		if (carmack && planedata.length() != 8192)
		{
			CarmackExpand(planedata, expanded);
		}

		RLEWExpand(planedata, encoding, expanded);

		for (int y = 0; y < height; y++)
		{
			for (int x = 0; x < width; x++)
			{
				int index = y * 2 * width + x * 2;

				if (index < expanded.size()) { planes[plane].Insert(y * width + x, expanded[index + 1] * 0x100 + expanded[index]); }
			}
		}
	}

	int CarmackExpand(String input, in out Array<int> outputbytes)
	{
		Array<int> inputbytes;
		int offset = 0;

		for (uint i = 0; i < input.length(); i++) { inputbytes.Push(input.ByteAt(i)); }

		int length = inputbytes[offset + 1] * 0x100 + inputbytes[offset];
		offset += 2;

		while (offset < inputbytes.Size() - 1)
		{
			if (inputbytes[offset + 1] == 0xA7)
			{
				int count = inputbytes[offset];
				int dist = inputbytes[offset + 2];

				if (count == 0)
				{
					outputbytes.Push(dist);
					outputbytes.Push(0xA7);
				}
				else
				{
					int start = outputbytes.Size() - dist * 2;
					for (int o = start; o < start + count * 2; o++) { outputbytes.Push(outputbytes[o]); }
				}

				offset += 3;
			}
			else if (inputbytes[offset + 1] == 0xA8)
			{
				int count = inputbytes[offset];

				if (count == 0)
				{
					outputbytes.Push(inputbytes[offset + 2]);
					outputbytes.Push(0xA8);

					offset += 3;
				}
				else
				{
					int dist = inputbytes[offset + 3] * 0x100 + inputbytes[offset + 2];
					int start = dist * 2;

					for (int o = start; o < start + count * 2; o++) { outputbytes.Push(outputbytes[o]); }

					offset += 4;
				}
			}
			else
			{
				outputbytes.Push(inputbytes[offset]);
				outputbytes.Push(inputbytes[offset + 1]);

				offset += 2;
			}
		}

		return length;
	}

	int RLEWExpand(String input, int encoding, in out Array<int> outputbytes)
	{
		Array<int> inputbytes;
		int offset = 0;

		if (!outputbytes.Size())
		{
			for (uint i = 0; i < input.length(); i++) { inputbytes.Push(input.ByteAt(i)); }
		}
		else
		{
			for (int i = 0; i < outputbytes.Size(); i++) { inputbytes.Push(outputbytes[i]); }
			outputbytes.Clear();
		}

		int length = inputbytes[offset + 1] * 0x100 + inputbytes[offset];
		offset += 2;

		while (offset < inputbytes.Size() - 1)
		{
			int value = inputbytes[offset + 1] * 0x100 + inputbytes[offset];

			if (value == encoding)
			{
				int count = inputbytes[offset + 3] * 0x100 + inputbytes[offset + 2];

				while (count--)
				{
					outputbytes.Push(inputbytes[offset + 4]);
					outputbytes.Push(inputbytes[offset + 5]);
				}

				offset += 6;
			}
			else
			{
				outputbytes.Push(inputbytes[offset]);
				outputbytes.Push(inputbytes[offset + 1]);

				offset += 2;
			}
		}

		return length;
	}

	play void Initialize(int style = -1, bool initial = true)
	{
		if (style < 0) { style = max(0, g_sod); }

		MapHandler handler = MapHandler.Get();
		if (handler.IsParsedMap())
		{
			voidspace.Clear();
			noclip = false;

			TextureID nulltex = TexMan.CheckForTexture("-", TexMan.Type_Any);
			
			for (int s = 0; s < level.sectors.Size(); s++)
			{
				Sector sec = level.sectors[s];

				// If this sector is out of range, continue
				if (abs(sec.centerspot.x) > 4096 || abs(sec.centerspot.y) > 4096) { continue; }

				// Clear any previously spawned actors
				Actor thing = sec.thinglist;
				while (thing != null)
				{
					if (!(thing is "PlayerPawn")) { thing.Destroy(); }
					thing = (thing == sec.thinglist) ? null : thing.snext;
				}

				Vector2 pos = CoordsToGrid(sec.centerspot);

				TileInfo tile;
				int t;
				[t, tile] = TileAt(pos);
				int a = ActorAt(pos);

				if (a >= 0x13 && a <= 0x16)
				{
					startspot = sec.centerspot;
					double angle = 90 - (a - 0x13) * 90;

					if (initial)
					{
						for (int i = 0; i < MAXPLAYERS; i++)
						{
							if (playeringame[i])
							{
								if (!deathmatch && i == 0)
								{
									players[0].mo.SetOrigin((startspot, 0), false);
									players[0].mo.angle = angle;
								}
								else
								{
									players[i].mo.SetOrigin((GetNextSpot(startspot, angle, 0, deathmatch), 0), false);
									players[i].mo.angle = deathmatch ? int(ceil(GameHandler.WolfRandom() / 64)) * 90 : angle;
								}
							}
						}
					}

				}

				// Build the wall structure
				if ((!tile || tile.flags & TileInfo.TILE_SOLID) && (a == 0 || (a > 0x59 && a < 0x62)))
				{
					// Collapse the sector height
					if (tile && !(tile.flags & TileInfo.TILE_FONT) && !GraphicsHandler.CheckTouched(tile.tex[0]))
					{
						sec.MoveFloor(256, sec.floorplane.PointToDist(sec.centerspot, sec.CenterCeiling() - 64), 0, -1, false, true);

						TextureID nulltex = TexMan.CheckForTexture("-", TexMan.Type_Any);
						for (int l = 0; l < sec.lines.Size(); l++)
						{
							let ln = sec.lines[l];

							ln.flags |= Line.ML_TWOSIDED;
							ln.flags &= ~(Line.ML_BLOCKING | Line.ML_BLOCKSIGHT | Line.ML_SOUNDBLOCK);


							for (int s = 0; s < 2; s++)
							{
								if (ln.sidedef[s])
								{
									if (ln.sidedef[s].sector != sec) { ln.sidedef[s].SetTexture(side.mid, nulltex); }
									ln.sidedef[s].flags &= ~Side.WALLF_BLOCKRENDERING;
								}
							}
						}
					}
					else
					{
						sec.MoveFloor(256, sec.floorplane.PointToDist(sec.centerspot, sec.CenterCeiling()), 0, 1, false, true);

						// Make lines blocking and set textures
						for (int l = 0; l < sec.lines.Size(); l++)
						{
							let ln = sec.lines[l];

							ln.flags &= ~Line.ML_TWOSIDED;
							ln.flags |= Line.ML_BLOCKING | Line.ML_BLOCKSIGHT | Line.ML_SOUNDBLOCK;

							TextureID tex = GetTexture(pos, ln, style);

							for (int s = 0; s < 2; s++)
							{
								if (ln.sidedef[s] && ln.sidedef[s].sector != sec)
								{
									ln.sidedef[s].SetTexture(side.mid, tex);
								}
							}
						}

						// Set the floor texture to the wall texture so they show up on the automap
						sec.SetTexture(Sector.floor, GetTexture(pos, null, style));
					}
				}

				// Spawn actors
				if (a > 0)
				{
					Actor mo;
					ParsedValue am = ActorMap.GetActor(handler.actormaps, style, a, G_SkillPropertyInt(SKILLP_ACSReturn) + 1);

					if (am)
					{
						// Spawn the actor
						Class<Actor> spawnclass = am.GetString("Class", true);
						let it = GetDefaultByType(spawnclass);

						if (spawnclass && it.ShouldSpawn())
						{
							mo = Actor.Spawn(spawnclass, (sec.centerspot, 0));
							if (mo)
							{
								// Align the actor
								mo.angle = am.GetInt("Angle");

								// Assign a TID matching the floor code for alerting reasons
								// (Recreate's Wolf's ability to alert actors elsewhere 
								// in the map if they share the same floor code)
								if (tile && tile.flags & TileInfo.TILE_AMBUSH)  // Deaf Guard Floor Code
								{
									mo.bAmbush = true;

									if (ClassicBoss(mo)) { ClassicBoss(mo).bDeafandBlind = true; } // Recreate blind-and-deaf bosses bug

									// Look at nearby tiles to find the closest floor code
									TileInfo tile;
									[t, tile] = TileAt(pos + (1, 0));
									if (tile && !(tile.flags & TileInfo.TILE_FLOOR)) { [t, tile] = TileAt(pos - (1, 0)); }
									if (tile && !(tile.flags & TileInfo.TILE_FLOOR)) { [t, tile] = TileAt(pos + (0, 1)); }
									if (tile && !(tile.flags & TileInfo.TILE_FLOOR)) { [t, tile] = TileAt(pos - (0, 1)); }
									if (tile && !(tile.flags & TileInfo.TILE_FLOOR)) { t = 0; } // Fall back to not assigning a TID
								}
								
								mo.ChangeTID(t);
								mo.bDropped = false;

								if (ClassicNazi(mo)) { ClassicNazi(mo).bPatrolling = am.GetBool("Patrolling"); }
							}
						}
					}
				}
			}

			// Clean up display of collapsed sectors on the automap
			for (int s = 0; s < level.sectors.Size(); s++)
			{
				let sec = level.sectors[s];

				Vector2 pos = CoordsToGrid(sec.centerspot);
				
				TileInfo tile;
				int t;
				[t, tile] = TileAt(pos);
				int a = ActorAt(pos);

				// If this sector is out of range, continue
				if (abs(sec.centerspot.x) > 4096 || abs(sec.centerspot.y) > 4096) { continue; }

				// Don't draw lines between sectors that are collapsed
				int edges = 0;
				for (int l = 0; l < sec.lines.Size(); l++)
				{
					let ln = sec.lines[l];
					int solid = 0;

					for (int s = 0; s < 2; s++)
					{
						if (!ln.sidedef[s] || ln.sidedef[s].sector.CenterCeiling() - ln.sidedef[s].sector.CenterFloor() == 0)
						{
							solid++;
							if (ln.sidedef[s] && !a) { ln.sidedef[s].flags |= Side.WALLF_BLOCKRENDERING; }
						}
					}

					if (solid > 1)
					{
						ln.flags |= Line.ML_DONTDRAW;
						edges++;
					}
				}

				bool accessible = (ActorAt(pos + (1, 0)) || ActorAt(pos - (1, 0)) || ActorAt(pos + (0, 1)) || ActorAt(pos - (0, 1)));

				// Set the floor and ceiling for collapsed sectors to "-"
				if (edges == sec.lines.Size() && !accessible && tile && !(tile.flags & TileInfo.TILE_FONT))
				{
					sec.SetTexture(Sector.floor, nulltex);
					sec.SetTexture(Sector.ceiling, nulltex);

					for (int l = 0; l < sec.lines.Size(); l++)
					{
						let ln = sec.lines[l];
						for (int s = 0; s < 2; s++)
						{
							if (ln.sidedef[s])
							{
								ln.sidedef[s].SetTexture(side.top, nulltex);
								ln.sidedef[s].SetTexture(side.mid, nulltex);
								ln.sidedef[s].SetTexture(side.bottom, nulltex);
							}
						}
					}

					voidspace.Push(sec);
				}

				PolyobjectHandle door = PolyobjectHandle.FindPolyobjAt(sec.CenterSpot);
				
				// Handle texturing of doors and door frames
				if ((tile && tile.flags & TileInfo.TILE_DOOR) || a == 0x62 || door)
				{
					if (door)
					{
						door.Lines.Push(door.StartLine);

						if (door.StartLine.special != Polyobj_ExplicitLine)
						{
							// Find all lines that belong to this polyobject
							Vertex start = door.StartLine.v1;
							Vertex current = door.StartLine.v2;
							int count = 0;

							door.Lines.Push(door.StartLine);

							while (current.Index() != start.Index() && count < level.lines.Size())
							{
								for (int l = 0; l < level.lines.Size(); l++)
								{
									count++;
									let ln = level.lines[l];
									if (ln.v1 == current)
									{
										if (door.Lines.Find(ln) == door.Lines.Size())
										{
											if (
												tile &&
												((tile.flags & TileInfo.TILE_DOOR) && a != 0x62) ||
												(a == 0x62 && !(tile.flags & TileInfo.TILE_DOOR))
											)
											{
												for (int s = 0; s < 2; s++)
												{
													if (ln.sidedef[s]) { ln.sidedef[s].flags |= Side.WALLF_BLOCKRENDERING; }
												}
											}
											door.Lines.Push(ln);
										}
										current = ln.v2;
										count = 0;
										break;
									}
									if (count > level.lines.Size()) { break; }
								}
							}
						}

						if (initial && (tile && tile.flags & TileInfo.TILE_WALL) && a == 0x62)
						{
							for (int n = 0; n < door.Lines.Size(); n++)
							{
								let dln = door.Lines[n];

								for (int s = 0; s < 2; s++)
								{
									if (dln.sidedef[s])
									{
										dln.sidedef[s].flags |= Side.WALLF_BLOCKRENDERING;
										dln.sidedef[s].SetAdditiveColor(side.mid, g_highlightpushwalls != 0x110000 ? g_highlightpushwalls : 0x3F3700);
										if (g_highlightpushwalls) { dln.sidedef[s].EnableAdditiveColor(side.mid, true); }
									}
								}
							}
						}
					}

					for (int l = 0; l < sec.lines.Size(); l++)
					{
						let ln = sec.lines[l];

						// Block sounds by default
						if (ln.flags & Line.ML_TWOSIDED) { ln.flags |= Line.ML_SOUNDBLOCK; }

						// If this is a standard door entry, set up activation and flags
						if (ln.flags & Line.ML_TWOSIDED && ln.frontsector.CenterFloor() == ln.backsector.CenterFloor())
						{
							if (a != 0x62) // Don't set activation lines for secret doors
							{
								ln.flags |= Line.ML_BLOCK_PLAYERS | Line.ML_DONTDRAW; // Block players by default, and don't draw on the automap

								if (door)
								{
									// Set two-sided lines to open/close the door so that it
									// can be closed even without directly using the polyobject
									ln.special = Polyobj_DoorSlide;
									ln.args[0] = door.PolyobjectNum;
									ln.args[2] = (t % 2 == 0) ? 192 : 0;
									ln.activation = SPAC_Use | SPAC_UseBack | SPAC_UseThrough;
									ln.flags |= Line.ML_REPEAT_SPECIAL;

									if (tile && tile.key)
									{
										ln.locknumber = 59 + tile.key;
										ln.flags &= ~Line.ML_DONTDRAW;
									}
								}
							}
						}

						// If this line borders a secret door, continue
						if (tile && !(tile.flags & TileInfo.TILE_DOOR) && a == 0x62) { continue; }

						// If this line is an entryway, continue
						if (ln.flags & Line.ML_TWOSIDED)
						{
							if (t % 2 == 1 && ln.delta.x) { continue; }
							if (t % 2 == 0 && ln.delta.y) { continue; }
						}

						// Don't add door frames if Deaf Guard tiles meet the threshhold
						if (g_deafguarddoors > 0)
						{
							TileInfo checktile;
							TextureID c;
							[c, checktile] = GetSpecialTileTexture(TileInfo.TILE_AMBUSH);

							if (checktile && CheckDoorTiles(pos, checktile.id) >= g_deafguarddoors) { continue; }
						}

						// Set door frame textures on the sides
						for (int s = 0; s < 2; s++)
						{
							if (ln.sidedef[s] && ln.sidedef[s].sector == sec)
							{
								ln.sidedef[s].SetTexture(side.mid, GetSpecialTileTexture(TileInfo.TILE_DOORFRAME, pos, ln));
							}
						}
					}

					if (door)
					{
						for (int l = 0; l < door.Lines.Size(); l++)
						{
							let ln = door.lines[l];

							if (ln.special == 8 || a == 0x62)
							{
								TextureID tex;
								if (tile && tile.key)
								{
									ln.locknumber = 59 + tile.key;

									String texpath;
								
									// Set the doors to colored variants if the CVar is set
									if (ln.delta.x) { texpath = g_usedoorkeycolors ? tile.alttex[0] : tile.tex[0]; }
									else { texpath = g_usedoorkeycolors ? tile.alttex[1] : tile.tex[1]; }
									
									tex = TexMan.CheckForTexture(texpath, TexMan.Type_Any);
								}

								// If it's a secret door
								if (a == 0x62 && (tile && tile.flags & TileInfo.TILE_WALL))
								{
									// Check the neighboring tile for this line
									TileInfo ntile;
									int n = 0;
									if (ln.delta.x == 0)
									{
										if (ln.v1.p.x > door.StartSpotPos.x) { [n, ntile] = TileAt(pos + (1, 0)); }
										else { [n, ntile] = TileAt(pos - (1, 0)); }
									}
									else if (ln.delta.y == 0)
									{
										if (ln.v1.p.y > door.StartSpotPos.y) { [n, ntile] = TileAt(pos - (0, 1)); }
										else { [n, ntile] = TileAt(pos + (0, 1)); }
									}

									// If it's a door frame, texture this line to match
									if (ntile && ntile.flags & TileInfo.TILE_DOOR)
									{
										Vector2 gridpos = ParsedMap.CoordsToGrid(door.StartSpotPos);
										tex = GetSpecialTileTexture(TileInfo.TILE_DOORFRAME, (0, 0), ln);
									}
								}

								// Set door textures
								for (int s = 0; s < 2; s++)
								{
									if (ln.sidedef[s])
									{
										if (!tex.IsValid()) { tex = GetTexture(ParsedMap.CoordsToGrid(door.Origin), ln, style); }
										if (tex.IsValid())
										{
											ln.sidedef[s].SetTexture(side.mid, tex);
										}
									}
								}
							}

							ln.flags &= ~Line.ML_DONTDRAW;

						}

						// If this was a secret door, flag it as a secret and set the floor texture for the automap
						if (a == 0x62)
						{
							if (initial)
							{
								sec.flags |= Sector.SECF_SECRET | Sector.SECF_WASSECRET;
								Level.total_secrets++;
							}
	
							if (tile && !(tile.flags & TileInfo.TILE_DOOR)) { sec.SetTexture(Sector.floor, GetTexture(ParsedMap.CoordsToGrid(door.Origin), null, style)); }
						}
						else if (ActorAt(CoordsToGrid(door.Origin)) == 0x62)
						{
							sec.SetTexture(Sector.floor, GetTexture(ParsedMap.CoordsToGrid(door.Origin), null, style));
						}
					}

				}
				else if ((tile && tile.special)) // Elevator switch
				{
					bool secret;

					TileInfo specialtile = tile;
					int s;
					[s, specialtile] = TileAt(pos + (1, 0));
					if (specialtile && specialtile.flags & TileInfo.TILE_SECRETEXIT) { secret = true; }
					else
					{
						[s, specialtile] = TileAt(pos - (1, 0));
						if (specialtile && specialtile.flags & TileInfo.TILE_SECRETEXIT) { secret = true; }
					}

					for (int l = 0; l < sec.lines.Size(); l++)
					{
						let ln = sec.lines[l];
						if (ln.delta.x || (ln.frontsector && ln.backsector && ln.frontsector.CenterFloor() == ln.backsector.CenterFloor())) { continue; }

						ln.special = tile.special;
						for (int r = 0; r < 5; r++)
						{
							ln.args[r] = tile.args[r];
						}

						if (ln.special == 80 && ln.args[0] == 10 && secret) { ln.args[2] = 10; }

						ln.activation = SPAC_Use | SPAC_UseBack;
					}
				}
				else if (a == 0x63) // Walkover exit trigger
				{
					for (int l = 0; l < sec.lines.Size(); l++)
					{
						let ln = sec.lines[l];

						// If this line is a wall, continue;
						if (ln.flags & Line.ML_TWOSIDED)
						{
							ln.special = 80;
							ln.args[0] = 4;
							ln.args[2] = 1;

							ln.activation = SPAC_Cross;
						}
					}
				}

				// Set wall textures for walls with things spawned inside of them
				if (tile && (tile.flags & TileInfo.TILE_WALL) && (a > 0 && a != 0x62))
				{
					// Make lines blocking and set textures
					for (int l = 0; l < sec.lines.Size(); l++)
					{
						let ln = sec.lines[l];

						ln.flags |= Line.ML_BLOCKSIGHT | Line.ML_SOUNDBLOCK;

						if (ln.frontsector.CenterFloor() == ln.backsector.CenterFloor())
						{
							TextureID tex = GetTexture(pos, ln, style);
							for (int s = 0; s < 2; s++)
							{
								if (ln.sidedef[s])
								{
									if (ln.sidedef[s].sector != sec)
									{
										ln.sidedef[s].SetTexture(side.mid, tex);
									}
								}
							}	
						}
						else
						{
							Sector texsec = (ln.frontsector == sec) ? ln.backsector : ln.frontsector;
							Vector2 texpos = (texsec ? texsec.CenterSpot : (-4096, 4096));
							texpos = ParsedMap.CoordsToGrid(texpos);
							TextureID tex = GetTexture(texpos, ln, style);

							for (int s = 0; s < 2; s++)
							{
								if (ln.sidedef[s])
								{
									if (ln.sidedef[s].sector == sec)
									{
										ln.sidedef[s].SetTexture(side.mid, tex);
									}
								}
							}
						}
					}
				}
			}
		}
	}

	LevelInfo GetInfo()
	{
		int num = mapnum;

		if (num >= 1000)
		{

		}
		else if (num > 700)
		{
			num += (gametype - 1) * 100; // Adjust map numbers for lost episodes
		}

		for (int i = 0; i < LevelInfo.GetLevelInfoCount(); i++)
		{
			LevelInfo info = LevelInfo.GetLevelInfo(i);
			if (info.levelnum == mapnum || info.mapname ~== mapname) { return info; }
		}

		return null;
	}

	TextureID GetTexture(Vector2 pos, Line ln = null, int style = -1)
	{
		if (style < 0) { style = max(0, g_sod); }

		TileInfo tile;
		int t;
		[t, tile] = TileAt(pos, style);

		TextureID tex = GetTileTexture(tile, pos, ln);

		return tex;
	}

	TextureID, TileInfo GetSpecialTileTexture(int type, Vector2 pos = (0, 0), Line ln = null, int style = -1)
	{
		let this = MapHandler.Get();
		if (!this) { return null, null; }

		if (style < 0) { style = max(0, g_sod); }

		TileInfo tile = GameTileInfo.GetSpecialTileInfo(this.tilemaps, GetGameName(style), type);
		if (!tile) { return null, null; }

		return GetTileTexture(tile, pos, ln), tile;
	}

	TextureID GetTileTexture(TileInfo tile, Vector2 pos, Line ln = null)
	{
		if (!tile) { return null; }

		String texname;

		if (!ln)
		{
			texname = tile.tex[0];
			
			if (tile && tile.flags & TileInfo.TILE_DIRECTIONAL) // Landscape and Elevator walls show alternate walls on map as appropriate
			{
				TileInfo left, right;
				int l, r;
				[l, left] = TileAt(pos - (1, 0));
				[r, right] = TileAt(pos + (1, 0));
				
				if (left && left.flags & TileInfo.TILE_FLOOR || right && right.flags & TileInfo.TILE_FLOOR) { texname = tile.tex[1]; }
			}
		}
		else
		{
			texname = (ln.delta.x) ? tile.tex[0] : tile.tex[1];
		}

		TextureID tex = TexMan.CheckForTexture(texname, TexMan.Type_Any);

		if (!tex.IsValid() || !GraphicsHandler.CheckTouched(texname))
		{
			switch (gametype)
			{
				// case 4:
				// 	if (t > 0xD0) { t -= 0x13C; }
				// 	else if (t < 0x58) { return TexMan.CheckForTexture("Patches/Walls/Wall4000.png", TexMan.Type_Any); }
				// 	else { return tex; }
				// 	break;
				default:
					TileInfo defaulttile = TileAtIndex(0);
					if (tile && !(tile.flags & TileInfo.TILE_FONT)) { return TexMan.CheckForTexture(defaulttile.tex[0], TexMan.Type_Any); }
					break;
			}

			int c = 0;
			switch (tile.id)
			{
				case 0xCA: // Space
					break;
				case 0xE3: // !
					c = 0x21;
					break;
				case 0xCB: // Highlight (*)
					c = 0x2A;
					break;
				case 0xDB: // -
					c = 0x2D;
					break;
				case 0xE1: // ?
					c = 0x3F;
					break;
				case 0xE2: // .
					c = 0x2E;
					break;
				case 0xDE: // /
					c = 0x2F;
					break;
				case 0xDF: // <
					c = 0x3C;
					break;
				case 0xDA: // =
					c = 0x3D;
					break;
				case 0xE0: // >
					c = 0x3E;
					break;
				case 0xDD: // \
					c = 0x5C;
					break;
				case 0xDC: // |
					c = 0x7C;
					break;
				default:
					if (tile.id < 0xB0) { c = 0x41 + (tile.id - 0x96); } // Uppercase letters
					else if (tile.id < 0xCA) { c = 0x61 + (tile.id - 0xB0); } // Lowercase letters
					else if (tile.id < 0xDA) { c = 0x30 + (tile.id - 0xD0); } // Numbers
					break;
			}
	
			if (c > 0)
			{
				tex = TexMan.CheckForTexture(String.Format(tile.tex[0], c), TexMan.Type_Any);
			}
		}

		return tex;
	}

	Vector2 GetNextSpot(Vector2 pos, double angle, int iter = 0, bool random = false)
	{
		// Randomize spawn locations across the map
		if (random)
		{
			bool blocked = true;
			while (blocked)
			{
				int column = Random[dmstart](1, 63); // Random column
				int row = Random[dmstart](1, 63); // Random row
				
				for (int y = row; y < 64; y++) // Look for an empty tile
				{
					Vector2 gridpos = (column, Random[dmstart](0, 1) ? y : 63 - y); // Start from the botton randomly
					TileInfo tile;
					int t;
					[t, tile] = TileAt(gridpos);

					bool blocked = (tile && tile.flags & TileInfo.TILE_SOLID | TileInfo.TILE_DOOR); // Walls keep you from spawning
					if (!blocked) { blocked = !!FindBlockingActor(GridToCoords(gridpos)); } // And so do blocking actors

					if (!blocked) { return GridToCoords(gridpos); } // But if you're not blocked, spawn here
					// Keep looking in this column
				}
				// Otherwise try again with a new random spot
			}
		}

		// Otherwise, spawn in a 3x3 grid pattern in alignment with the player start
		Vector2 offset = (iter / 3,  (iter % 3) - 1);
		offset = Actor.RotateVector(offset, angle);

		Vector2 gridpos = CoordsToGrid(pos) - offset;

		if (gridpos.x > 64 || gridpos.y > 64 || gridpos.x < 0 || gridpos.y < 0) { return pos; }

		TileInfo tile;
		int t;
		[t, tile] = TileAt(gridpos);

		bool blocked = (tile && tile.flags & TileInfo.TILE_SOLID | TileInfo.TILE_DOOR);
		if (!blocked) { blocked = !!FindBlockingActor(pos + offset * 64); }
		if (blocked) { return GetNextSpot(pos, angle, ++iter); }
		
		return pos + offset * 64;
	}

	Actor FindBlockingActor(Vector2 spot, int dist = 32)
	{
		BlockThingsIterator it = BlockThingsIterator.CreateFromPos(spot.x, spot.y, 0, 0, dist, false);
		while (it.Next())
		{
			if (it.thing.bSolid && Level.Vec2Diff(spot, it.thing.pos.xy).length() < dist) { return it.thing; }
		}

		return null;
	}

	// Check for tiles on either side of doors
	int CheckDoorTiles(Vector2 spot, int tilecheck1, int tilecheck2 = -1)
	{ 
		TileInfo tile;
		int t;
		[t, tile] = TileAt(spot);
		int a = ActorAt(spot);
		if (tile && !(tile.flags & TileInfo.TILE_DOOR)) { return 0; }

		int t1, t2;
		int tilecount = 0;

		if (t % 2 == 0)
		{
			t1 = TileAt(spot - (1, 0));
			t2 = TileAt(spot + (1, 0));
		}
		else
		{
			t1 = TileAt(spot - (0, 1));
			t2 = TileAt(spot + (0, 1));
		}

		tilecount += (t1 == tilecheck1 && (tilecheck2 < 0 ? 1 : t2 == tilecheck2)) + (t2 == tilecheck1 && (tilecheck2 < 0 ? 1 : t1 == tilecheck2));

		return tilecount;
	}

	int CountDoors(Vector2 pos)
	{
		int count = 0;

		for (int y = 0; y <= pos.y; y++)
		{
			for (int x = 0; x < 64; x++)
			{
				TileInfo tile;
				int t;
				[t, tile] = TileAt((x, y));
				count += (tile && tile.flags & TileInfo.TILE_DOOR);

				if (y == pos.y && x + 1 == pos.x) { break; }
			}
		}

		return count;
	}
}

class WolfMapParser
{
	Array<ParsedMap> maps;
	int gametype;
	int custommapcount;

	static void Parse(in out WolfMapParser parsedmaps, in out DataFile d)
	{
		int headlump = -1;
		int mapslump = -1;

		if (!parsedmaps) { parsedmaps = New("WolfMapParser"); }
		if (!d) { return; }

		if (d.headpath.length()) { headlump = Wads.CheckNumForFullName(d.headpath); }

		if (d.lump) { mapslump = d.lump; }
		else { mapslump = Wads.CheckNumForFullName(d.path); }

		if (mapslump == -1) { return; }

		String game = d.path.Mid(d.path.length() - 3);
		if (game ~== "WL1" || game ~== "WL3" || game ~== "WL6") { parsedmaps.gametype = 0; }
		else if (game ~== "SOD" || game ~== "SD1") { parsedmaps.gametype = 1; }
		else if (game ~== "SD2") { parsedmaps.gametype = 2; }
		else if (game ~== "SD3") { parsedmaps.gametype = 3; }
		else if (game ~== "BS1" || game ~== "BS6") { parsedmaps.gametype = 4; }
		else { parsedmaps.gametype = -1; } // Play as Wolf, but allow setting via CVar

		int encoding;
		Array<int> addresses;
		if (headlump > -1) { parsedmaps.ReadMapHead(Wads.ReadLump(headlump), encoding, addresses); }
		parsedmaps.ReadGameMaps(Wads.ReadLump(mapslump), encoding, addresses, d, mapslump);
	}

	void ReadMapHead(String content, out int encoding, in out Array<int> addresses)
	{
		uint offset = 0;
		[encoding, offset] = WolfMapParser.GetLittleEndian(content, 0, 2);

		int address = 8;
		while (offset < content.Length() && address > 0)
		{
			[address, offset] = GetLittleEndian(content, offset, 4);
			addresses.Push(address);
		}
	}

	enum maptypes
	{
		GameMaps,
		Raw,
		RawWithHeader,
		FloEdit,
	};

	void ReadGameMaps(String content, int encoding, Array<int> addresses, Datafile d, int lump = -1)
	{
		maptypes type = GameMaps;
		if (!addresses.Size())
		{
			int size = content.length();

			if (size == 16384)
			{ // Raw
				addresses.Push(8);
				type = Raw;
			}
			else if (size == 16393)
			{ // Raw inverted x/y (FloEdit)
				addresses.Push(8);
				type = FloEdit;
			}
			else if (size % 8192 == 34)
			{ // Raw with Header
				addresses.Push(8);
				type = RawWithHeader;
			}
			else
			{ // Invalid Format
				return;
			}
		}

		for (int a = 0; a < addresses.Size(); a++)
		{
			int offset = addresses[a];
			if (offset == 0) { continue; }

			ParsedMap newmap = New("ParsedMap");
			newmap.datafile = d;
			newmap.lump = lump;
			
			int planeoffsets[4];
			int planesizes[4];

			if (type > GameMaps)
			{
				// Set defaults for fallback
				newmap.width = 64;
				newmap.height = 64;
				newmap.mapname = "Custom Map";

				if (type == RawWithHeader)
				{
					newmap.signature = content.Left(8);
					planeoffsets[0] = 34;

					if (newmap.signature.left(3) ~== "WDC")
					{
						newmap.width = WolfMapParser.GetLittleEndian(content, 0x1E, 2);
						newmap.height = WolfMapParser.GetLittleEndian(content, 0x20, 2);
						newmap.mapname = content.Mid(0x0E, WolfMapParser.GetLittleEndian(content, 0x0C, 2));
					}
					else if(newmap.signature.left(2) ~== "CE") // ChaosEdit
					{
						newmap.width = content.ByteAt(0x0C) * 0x100 + content.ByteAt(0x0D);
						newmap.height = content.ByteAt(0x0E) * 0x100 + content.ByteAt(0x0F);
						newmap.mapname = content.Mid(0x12, content.ByteAt(0x10) * 0x100 + content.ByteAt(0x11));
					}
				}
				else if (type == FloEdit)
				{
					newmap.signature = content.Left(8);
					planeoffsets[0] = 9;
				}

				planesizes[0] = planesizes[1] = newmap.width * newmap.height * 2;
				planeoffsets[1] = planeoffsets[0] + planesizes[0];

				newmap.mapnum = 1000 + custommapcount++;

				for (int p = 0; p < 2; p++)
				{
					String plane = content.Mid(planeoffsets[p]);

					for (int y = 0; y < newmap.height; y++)
					{
						for (int x = 0; x < newmap.width; x++)
						{
							if (type == FloEdit)
							{
								int index = x * 2 * newmap.height + y * 2;
								newmap.planes[p].Insert(y * newmap.height + x, WolfMapParser.GetLittleEndian(plane, index, 2));
							}
							else
							{
								int index = y * 2 * newmap.width + x * 2;
								newmap.planes[p].Insert(y * newmap.width + x, WolfMapParser.GetLittleEndian(plane, index, 2));
							}
						}
					}
				}
			}
			else
			{
				[planeoffsets[0], offset] = WolfMapParser.GetLittleEndian(content, offset, 4);
				[planeoffsets[1], offset] = WolfMapParser.GetLittleEndian(content, offset, 4);
				[planeoffsets[2], offset] = WolfMapParser.GetLittleEndian(content, offset, 4);

				[planesizes[0], offset] = WolfMapParser.GetLittleEndian(content, offset, 2);
				[planesizes[1], offset] = WolfMapParser.GetLittleEndian(content, offset, 2);
				[planesizes[2], offset] = WolfMapParser.GetLittleEndian(content, offset, 2);

				[newmap.width, offset] = WolfMapParser.GetLittleEndian(content, offset, 2);
				[newmap.height, offset] = WolfMapParser.GetLittleEndian(content, offset, 2);

				newmap.mapname = content.Mid(offset, 16);
				offset += 16;
				newmap.signature = content.Mid(offset, 4);
				newmap.mapnum = gametype <= 0 ? (a / 10 + 1) * 100 + a % 10 + 1 : 600 + gametype * 100 + a + 1;

				for (int p = 0; p < 3; p++)
				{
					if (planesizes[p] <= 0) { continue; }
					newmap.ExpandData(p, content.mid(planeoffsets[p], planesizes[p]), encoding, d.carmack);
				}
			}

			newmap.hash = MD5.hash(content.Mid(planeoffsets[0], planesizes[0] + planesizes[1]));
			
			newmap.gametype = gametype;
			newmap.info = newmap.GetInfo();

			d.maps.Push(newmap);
			maps.Push(newmap);
		}
	}

	ParsedMap GetMapData(String mapname, String datafile = "")
	{
		for (int m = maps.Size() - 1; m >= 0; m--)
		{
			if (maps[m].mapname ~== mapname && (!datafile.length() || maps[m].datafile.path ~== datafile)) { return maps[m]; }
		}

		for (int m = maps.Size() - 1; m >= 0; m--)
		{
			if (maps[m].mapname ~== mapname && maps[m].datafile.gametitle == "Standalone Maps") { return maps[m]; }
		}

		return null;
	}

	ParsedMap GetMapDataByNumber(int mapnum, String datafile = "")
	{
		for (int m = 0; m < maps.Size(); m++)
		{
			if (maps[m].mapnum == mapnum && (!datafile.length() || maps[m].datafile.path ~== datafile)) { return maps[m]; }
		}

		return null;
	}

	static int, int GetLittleEndian(String input, int offset = 0, int count = 2)
	{
		int ret = 0;

		for (int b = count - 1; b >= 0; b--)
		{
			ret += int((0x100 ** b) * input.ByteAt(offset + b));
		}

		return ret, offset + count;
	}
}

class DataFile
{
	String gametitle;
	String path;
	String headpath;
	Array<ParsedMap> maps;
	int lump;
	bool carmack;

	static DataFile Find(in out Array<DataFile> datafiles, String title, String path, String headpath = "")
	{
		for (int i = 0; i < datafiles.Size(); i++)
		{
			if (
				(!headpath.length() && datafiles[i].gametitle == title) ||
				(datafiles[i].path ~== path && datafiles[i].headpath ~== headpath)
			)
			{
				return datafiles[i];
			}
		}

		let d = New("DataFile");

		if (!headpath.length())
		{
			d.gametitle = title;
		}
		else
		{
			d.path = path;
			d.headpath = headpath;
			d.lump = Wads.CheckNumForFullName(path);
			d.carmack = true;

			path = path.MakeUpper();
			if (path.IndexOf("MAPTEMP") > -1) { d.carmack = false; } // Assume MAPTEMP files are not Carmackized (Blake Stone and TED5 output)

			String hash = MD5.hash(Wads.ReadLump(d.lump));

			if (hash == "30fecd7cce6bc70402651ec922d2da3d")
			{ d.gametitle = "Wolfenstein 3D Shareware"; }
			if (hash == "cec494930f3ac0545563cbd23cd611d6") // v1.2
			{ d.gametitle = "Wolfenstein 3D (Episodes 1-3)"; }
			else if (hash == "05ee51e9bc7d60f01a05334b1cfab1a5") // v1.1
			{ d.gametitle = "Wolfenstein 3D v1.1"; }
			else if (hash == "a15b04941937b7e136419a1e74e57e2f") // v1.2
			{ d.gametitle = "Wolfenstein 3D v1.2"; }
			else if (hash == "a4e73706e100dc0cadfb02d23de46481") // v1.4 / GoG / Steam
			{ d.gametitle = "Wolfenstein 3D v1.4"; }
			else if (hash == "4eb2f538aab6e4061dadbc3b73837762")
			{ d.gametitle = "Spear of Destiny Demo"; }
			else if (hash == "04f16534235b4b57fc379d5709f88f4a")
			{ d.gametitle = "Spear of Destiny"; }
			else if (hash == "fa5752c5b1e25ee5c4a9ec0e9d4013a9")
			{ d.gametitle = "Return to Danger"; }
			else if (hash == "4219d83568d770b1c6ac9c2d4d1dfb9e")
			{ d.gametitle = "The Ultimate Challenge"; }
			else if (hash == "29860b87c31348e163e10f8aa6f19295")
			{ d.gametitle = "The Ultimate Challenge (UAC Version)"; }
			else if (hash == "6532d4062fed1817b440684c41a21fb5")
			{
				d.gametitle = "Blake Stone: Aliens of Gold Demo";
				d.carmack = false;
			}
			else if (hash == "9b259747340ffedd37eb5eae898e95c1")
			{
				d.gametitle = "Blake Stone: Aliens of Gold";
				d.carmack = false;
			}
			// else if (hash == "")
			// {
			// 	d.gametitle = "Blake Stone: Planet Strike";
			// 	d.carmack = false;
			// }
			else
			{
				String ext = path.Mid(path.length() - 3, 3);
				ext = ext.MakeLower();

				if (ext == "wl6") { d.gametitle = "Wolfenstein 3D (Modified)"; }
				else if (ext == "wl3") { d.gametitle = "Wolfenstein 3D (Episodes 1-3) (Modified)"; }
				else if (ext == "wl1") { d.gametitle = "Wolfenstein 3D Shareware (Modified)"; }
				else if (ext == "sdm") { d.gametitle = "Spear of Destiny Demo (Modified)"; }
				else if (ext == "sod" || ext == "sd1") { d.gametitle = "Spear of Destiny (Modified)"; }
				else if (ext == "sd2") { d.gametitle = "Return to Danger (Modified)"; }
				else if (ext == "sd3") { d.gametitle = "The Ultimate Challenge (Modified)"; }
				else if (ext == "bs1")
				{
					d.gametitle = "Blake Stone: Aliens of Gold Demo (Modified)";
					d.carmack = false;
				}
				else if (ext == "bs6")
				{
					d.gametitle = "Blake Stone: Aliens of Gold (Modified)";
					d.carmack = false;
				}
				else if (ext == "vsi")
				{
					d.gametitle = "Blake Stone: Planet Strike (Modified)";
					d.carmack = false;
				}
			}
		}

		if (!d.gametitle.length()) { d.gametitle = path; }

		datafiles.Push(d);

		return d;
	}
}

class WadEntry
{
	int datalump;
	int offset;
	int size;
	String name;
	String data;
}