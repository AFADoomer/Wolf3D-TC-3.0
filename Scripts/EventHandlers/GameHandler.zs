class GameHandler : StaticEventHandler
{
	Array<String> gamefiles;

	override void OnRegister()
	{
		// Check to see if a Wolf3D data file is present
		GameHandler.CheckGameFile("GAMEMAPS.WL6", gamefiles);
		GameHandler.CheckGameFile("GAMEMAPS.SDM", gamefiles);
		GameHandler.CheckGameFile("GAMEMAPS.SOD", gamefiles);
		GameHandler.CheckGameFile("GAMEMAPS.SD2", gamefiles);
		GameHandler.CheckGameFile("GAMEMAPS.SD3", gamefiles);
	}

	ui static bool GameFilePresent(String extension, bool allowdemos = true)
	{
		GameHandler this = GameHandler(StaticEventHandler.Find("GameHandler"));
		if (this)
		{
			if (this.gamefiles.Find(extension) < this.gamefiles.Size()) { return true; }
			if (allowdemos && extension ~== "SOD") { return GameFilePresent("SDM"); }
		}

		return false;
	}

	static void CheckGameFile(String filename, out Array<String> gamefiles, bool verbose = false)
	{
		if (!g_placeholders) { gamefiles.Push(filename.Mid(filename.length() - 3)); return; }

		// Check to see if a Wolf3D GAMEMAPS data file is present
		int g =	Wads.CheckNumForFullName(filename);
		String message = StringTable.Localize("$TXT_FOUNDFILE");

		if (g > -1)
		{
			String hash = MD5.hash(Wads.ReadLump(g));

			if (
				hash == "a4e73706e100dc0cadfb02d23de46481" || // v1.4 / GoG / Steam
				hash == "a15b04941937b7e136419a1e74e57e2f" // v1.1
			)
			{
				gamefiles.Push("WL6");
				message.Replace("%s", "Wolfenstein 3D");
			}
			else if (hash == "4eb2f538aab6e4061dadbc3b73837762")
			{
				gamefiles.Push("SDM");
				message.Replace("%s", "Spear of Destiny Demo");
			}
			else if (hash == "04f16534235b4b57fc379d5709f88f4a")
			{
				gamefiles.Push("SOD");
				message.Replace("%s", "Spear of Destiny");
			}
			else if (hash == "fa5752c5b1e25ee5c4a9ec0e9d4013a9")
			{
				gamefiles.Push("SD2");
				message.Replace("%s", "Return to Danger");
			}
			else if (
				hash == "4219d83568d770b1c6ac9c2d4d1dfb9e" ||
				hash == "29860b87c31348e163e10f8aa6f19295"
			)
			{
				gamefiles.Push("SD3");
				message.Replace("%s", "The Ultimate Challenge");
			}
		}

		if (verbose && !(message == StringTable.Localize("$TXT_FOUNDFILE")))
		{
			console.printf(message);
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
}

class Game
{
	static bool IsSoD()
	{
		bool ret = false;

		if (g_sod > 0) { ret = true; }
		if (level && level.levelnum > 700) { ret = true; }

		if (g_sod < 0 && gamestate == GS_LEVEL) // Set the value if we are in a game and it hasn't been set already by the startup menu
		{
			CVar sodvar = CVar.FindCVar("g_sod");
			if (sodvar) { sodvar.SetInt(ret ? 1 : 0); }
		}

		return ret;
	}
}