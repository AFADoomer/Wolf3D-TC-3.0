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

class GameHandler : StaticEventHandler
{
	Array<String> gamefiles;
	int randomcount;
	Dictionary music;

	override void OnRegister()
	{
		CheckGameFiles(self);
		ParseMusicMapping();
	}

	static void CheckGameFiles(GameHandler this)
	{
		console.printf(StringTable.Localize("$TXT_CHECKFILE"));

		if (this)
		{
			// Check to see if a Wolf3D data file is present
			GameHandler.CheckGameFile("GAMEMAPS.WL3", this.gamefiles, g_showhashes);
			GameHandler.CheckGameFile("GAMEMAPS.WL6", this.gamefiles, g_showhashes);
			GameHandler.CheckGameFile("GAMEMAPS.SOD", this.gamefiles, g_showhashes);
			GameHandler.CheckGameFile("GAMEMAPS.SD2", this.gamefiles, g_showhashes);
			GameHandler.CheckGameFile("GAMEMAPS.SD3", this.gamefiles, g_showhashes);
		}
	}

	ui static bool GameFilePresent(String extension, bool allowdemos = true)
	{
		GameHandler this = GameHandler(StaticEventHandler.Find("GameHandler"));
		if (this)
		{
			if (this.gamefiles.Find(extension) < this.gamefiles.Size()) { return true; }
			if (extension ~== "WL3" && this.gamefiles.Find("WL6") < this.gamefiles.Size()) { return true; }
			if (allowdemos && extension ~== "SOD") { return true; }
		}

		return false;
	}

	private static void CheckGameFile(String filename, out Array<String> gamefiles, bool verbose = false)
	{
		if (!g_placeholders) { gamefiles.Push(filename.Mid(filename.length() - 3)); return; }

		// Check to see if a Wolf3D GAMEMAPS data file is present
		int g =	Wads.CheckNumForFullName(filename);
		String message = StringTable.Localize("$TXT_FOUNDFILE");
		String hash;

		if (g > -1)
		{
			hash = MD5.hash(Wads.ReadLump(g));
			if (
				hash == "???" // I can't find the md5 of GAMEMAPS.WL3 anywhere, and don't own it, so...  unsupported.
			)
			{
				if (gamefiles.Find("WL3") == gamefiles.Size()) { gamefiles.Push("WL3"); }
				message.Replace("%s", "Wolfenstein 3D (Episodes 1-3)");
			}
			else if (
				hash == "05ee51e9bc7d60f01a05334b1cfab1a5" || // v1.1
				hash == "a15b04941937b7e136419a1e74e57e2f" || // v1.2
				hash == "a4e73706e100dc0cadfb02d23de46481" // v1.4 / GoG / Steam
			)
			{
				if (gamefiles.Find("WL6") == gamefiles.Size()) {gamefiles.Push("WL6"); }
				message.Replace("%s", "Wolfenstein 3D");
			}
			else if (hash == "4eb2f538aab6e4061dadbc3b73837762")
			{
				if (gamefiles.Find("SDM") == gamefiles.Size()) { gamefiles.Push("SDM"); }
				message.Replace("%s", "Spear of Destiny Demo");
			}
			else if (hash == "04f16534235b4b57fc379d5709f88f4a")
			{
				if (gamefiles.Find("SOD") == gamefiles.Size()) {gamefiles.Push("SOD"); }
				message.Replace("%s", "Spear of Destiny");
			}
			else if (hash == "fa5752c5b1e25ee5c4a9ec0e9d4013a9")
			{
				if (gamefiles.Find("SD2") == gamefiles.Size()) { gamefiles.Push("SD2"); }
				message.Replace("%s", "Return to Danger");
			}
			else if (
				hash == "4219d83568d770b1c6ac9c2d4d1dfb9e" ||
				hash == "29860b87c31348e163e10f8aa6f19295"
			)
			{
				if (gamefiles.Find("SD3") == gamefiles.Size()) { gamefiles.Push("SD3"); }
				message.Replace("%s", "The Ultimate Challenge");
			}

			if (!(message == StringTable.Localize("$TXT_FOUNDFILE")))
			{
				if (verbose) { console.printf(String.Format("%s (%s)", message, hash)); }
			}
			else
			{
				message = StringTable.Localize("$TXT_BADHASH");
				message.replace("%s", filename);

				console.printf(message .. hash);
			}
		}
	}

	// This is unreliable and causes crashes if it gets called before 
	// video initializes properly (e.g., with +map command line)
/*
	override void PlayerSpawned(PlayerEvent e)
	{
			if (g_nointro) { return; }
			if (g_sod && level.levelnum % 100 == 21) { return; }

			if (e.playernumber == consoleplayer) { Menu.SetMenu("GetPsyched", -1); }
	}

	override void PlayerRespawned(PlayerEvent e)
	{
			if (g_nointro) { return; }

			if (e.playernumber == consoleplayer) { Menu.SetMenu("GetPsyched", -1); }
	}
*/
	ui static bool CheckEpisode(String episode = "", bool allowunfiltered = true)
	{
		String extension = "";

		if (level.levelnum > 100 && episode == "") { episode = Level.GetEpisodeName(); }

		// Map lump name parsing because episode name checks are unreliable
		if (!episode.length())
		{
			String ext = level.mapname.Left(3);
			ext = ext.MakeUpper();

			if (ext ~== "SOD" || ext ~== "SD2" || ext ~== "SD3") { extension = ext; }
			else if (ext.left(1) ~== "E" && ext.mid(2) ~== "L")
			{
				int ep = ext.mid(1, 1).ToInt();

				if (ep == 1) { return true; }
				else if (ep <= 3) { extension = "WL3"; }
				else if (ep <= 6) { extension = "WL6"; }
			}

			episode = extension;
		}

		if (!episode.length()) { return true; }

		String temp;
		if (!extension.length())
		{
			temp = episode;
			int s, e;
			s = temp.IndexOf("[Optional");
			if (s > -1)
			{
				e = temp.IndexOf("]", s);
				extension = temp.Mid(e - 3, 3);
				extension = extension.MakeUpper();

				temp = temp.Mid(e + 1);
			}
		}

		// Treat episodes with no filter as if they were the shareware version
		if (!allowunfiltered && !extension.length()) { extension = "WL6"; }

		// If the replacement string wasn't there, then this one is good
		if (allowunfiltered && (temp == episode || !extension.length())) { return true; }

		GameHandler this = GameHandler(StaticEventHandler.Find("GameHandler"));
		if (this)
		{
			if (this.gamefiles.Find(extension) < this.gamefiles.Size()) { return true; }
			if (extension ~== "WL3" && this.gamefiles.Find("WL6") < this.gamefiles.Size()) { return true; }
			if (extension ~== "SOD" && level.levelnum % 100 < 3) { return true; }
		}

		return false;
	}

	static int WolfRandom()
	{
		static const int rnd_table[] = {
		  0,   8, 109, 220, 222, 241, 149, 107,  75, 248, 254, 140,  16,  66,
		 74,  21, 211,  47,  80, 242, 154,  27, 205, 128, 161,  89,  77,  36,
		 95, 110,  85,  48, 212, 140, 211, 249,  22,  79, 200,  50,  28, 188,
		 52, 140, 202, 120,  68, 145,  62,  70, 184, 190,  91, 197, 152, 224,
		149, 104,  25, 178, 252, 182, 202, 182, 141, 197,   4,  81, 181, 242,
		145,  42,  39, 227, 156, 198, 225, 193, 219,  93, 122, 175, 249,   0,
		175, 143,  70, 239,  46, 246, 163,  53, 163, 109, 168, 135,   2, 235,
		 25,  92,  20, 145, 138,  77,  69, 166,  78, 176, 173, 212, 166, 113,
		 94, 161,  41,  50, 239,  49, 111, 164,  70,  60,   2,  37, 171,  75,
		136, 156,  11,  56,  42, 146, 138, 229,  73, 146,  77,  61,  98, 196,
		135, 106,  63, 197, 195,  86,  96, 203, 113, 101, 170, 247, 181, 113,
		 80, 250, 108,   7, 255, 237, 129, 226,  79, 107, 112, 166, 103, 241,
		 24, 223, 239, 120, 198,  58,  60,  82, 128,   3, 184,  66, 143, 224,
		145, 224,  81, 206, 163,  45,  63,  90, 168, 114,  59,  33, 159,  95,
		 28, 139, 123,  98, 125, 196,  15,  70, 194, 253,  54,  14, 109, 226,
		 71,  17, 161,  93, 186,  87, 244, 138,  20,  52, 123, 251,  26,  36,
		 17,  46,  52, 231, 232,  76,  31, 221,  84,  37, 216, 165, 212, 106,
		197, 242,  98,  43,  39, 175, 254, 145, 190,  84, 118, 222, 187, 136,
		120, 163, 236, 249 };

		if (gamestate == GS_DEMOSCREEN)
		{
			GameHandler this = GameHandler(StaticEventHandler.Find("GameHandler"));
			if (this) { return rnd_table[this.randomcount++ % 256]; }
		}

		return Random(0, 255);
	}

	void ParseMusicMapping()
	{
		music = Dictionary.Create();
		Array<String> translations;

		int lump = -1;
		lump = Wads.CheckNumForFullName("Data/IMFtoMIDI.txt");

		if (lump != -1)
		{
			String data = Wads.ReadLump(lump);
			data.Split(translations, "\n");

			for (int i = 0; i < translations.Size(); i++)
			{
				Array<String> entry;
				translations[i].Split(entry, ",");
				if (entry.size() > 1) { music.Insert(entry[0], entry[1]); }
			}
		}
	}

	ui static String GetMusic(String IMFname)
	{
		CVar stylevar = CVar.FindCVar("g_musicstyle");
		if (stylevar && !stylevar.GetInt()) { return IMFname; }

		GameHandler this = GameHandler(StaticEventHandler.Find("GameHandler"));
		if (this)
		{
			String ret = this.music.At(IMFname);
			if (ret.length()) { return ret; }
		}

		return IMFname;
	}

	ui static void ChangeMusic(String musicname, int order = 0, bool looping = true, bool force = false)
	{
		if (musicname == "*") { musicname = level.music; }
		S_ChangeMusic(GameHandler.GetMusic(musicname), order, looping, force);
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name == "printhashes")
		{
			CheckGameFiles(self);
		}
	}
}

class Game
{
	static int, int IsSoD()
	{
		if (level.levelnum < 100 || level.levelnum >= 999) { return g_sod, g_sod; }

		int ret = max(0, g_sod);

		if (level && level.levelnum > 700)
		{
			String ext = level.mapname.Left(3);
			if (ext ~== "SOD") { ret = 1; }
			else if (ext ~== "SD2") { ret = 2; }
			else if (ext ~== "SD3") { ret = 3; }
		}
		else
		{
			ret = 0;
		}

		if (g_sod != ret && gamestate == GS_LEVEL && level.time == 2) // Set the value if we are in a game and it hasn't been set already by the startup menu
		{
			CVar sodvar = CVar.FindCVar("g_sod");
			if (sodvar) { sodvar.SetInt(ret); }
		}

		return g_sod, ret;
	}

	ui static bool InGame()
	{
		if (
			gamestate == GS_CUTSCENE ||
			gamestate == GS_INTERMISSION ||
			gamestate == GS_FINALE ||
			gamestate == GS_LEVEL
		)
		{
			let p = players[consoleplayer].mo;
			if (p && LifeHandler.GetLives(p) > -1) { return true; }
		}

		return false;
	}

	play static void AttachLight(Actor mo, int radius = 32, color clr = 0xFFFFFF, Vector3 offset = (0, 0, 0), int flags = 0, int inner = 10, int outer = 35, int angle = 0)
	{
		if (!g_dynamiclights) { return; }
		
		if (mo.CurSector.lightlevel < 230)
		{
			mo.A_AttachLight("Light", DynamicLight.PointLight, clr, radius, radius, DYNAMICLIGHT.LF_ATTENUATE | (flags & ~DYNAMICLIGHT.LF_SPOT), offset);
			if (flags & DYNAMICLIGHT.LF_SPOT)
			{
				mo.A_AttachLight("DownLight", DynamicLight.PointLight, clr, int(radius * 1.5), int(radius * 1.5), DYNAMICLIGHT.LF_ATTENUATE | flags, offset, 0, inner, outer, angle);
			}
		}
		else
		{
			mo.A_RemoveLight("Light");
			mo.A_RemoveLight("DownLight");
		}
	}
}