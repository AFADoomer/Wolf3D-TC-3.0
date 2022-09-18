class LevelData
{
	int totalkills, killcount;
	int totalitems, itemcount;
	int totalsecrets, secretcount;
	int leveltime;
	int levelnum;
	int timebonusamt;
	String mapname, levelname;
	Vector3 pos[MAXPLAYERS];
}

class PersistentMapStatsHandler : EventHandler
{
	Array<LevelData> Levels;
}

class MapStatsHandler : StaticEventHandler
{
	Array<LevelData> Levels;
	bool draw;
	bool active[MAXPLAYERS];
	const width = 640;
	const height = 480;
	Font TitleFont, HeadingFont, StatFont;
	double titlescale, headingscale, fontscale;
	int lineheight;
	Array<String> SpecialItemPickups;
	int chapter;
	PersistentMapStatsHandler persistent;

	clearscope int FindLevel(String n) // Helper function to find a thing in a child class (Used in place of Levels.Find(mo) since the name is nested in a LevelData object
	{
		for (int i = 0; i < Levels.Size(); i++)
		{
			if (Levels[i] && Levels[i].mapname == n) { return i; }
		}
		return Levels.Size();
	}

	clearscope int FindLevelNumber(int n) // Helper function to find a thing in a child class (Used in place of Levels.Find(mo) since the level number is nested in a LevelData object
	{
		for (int i = 0; i < Levels.Size(); i++)
		{
			if (Levels[i] && Levels[i].levelnum == n) { return i; }
		}
		return Levels.Size();
	}

	static clearscope LevelData GetStats(String n)
	{
		MapStatsHandler this = MapStatsHandler(StaticEventHandler.Find("MapStatsHandler"));
		if (!this) { return null; }

		int index = this.FindLevel(n);
		if (index == this.Levels.Size()) { return null; }

		return this.levels[index];
	}

	static void SaveLevelData()
	{
		MapStatsHandler this = MapStatsHandler(StaticEventHandler.Find("MapStatsHandler"));
		if (!this) { return; }

		int i = this.FindLevel(level.mapname);

		LevelData l;

		if (i < this.Levels.Size()) // If it's already there, just update the completion data
		{
			l = this.Levels[i];
		}
		else
		{
			l = New("LevelData");

			if (!l) { if (developer) { console.printf("Failed to save level statistics data!"); } return; }

			l.mapname = level.mapname;
			l.levelname = level.levelname;
			l.levelnum = level.levelnum;

			this.Levels.Push(l);
		}

		l.totalkills = level.total_monsters;
		l.killcount = level.killed_monsters;
		l.totalitems = level.total_items;
		l.itemcount = level.found_items;
		l.totalsecrets = level.total_secrets;
		l.secretcount = level.found_secrets;
		l.leveltime = level.maptime;

		if (players[consoleplayer].mo)
		{
			l.pos[consoleplayer] = players[consoleplayer].mo.pos;
		}
		
		if (l.levelnum % 100 == 10) { l.timebonusamt = 30; }
		else { l.timebonusamt = level.partime > 0 ? max(level.partime - Thinker.Tics2Seconds(level.maptime), 0) : 0;}

		// Save the copy of the data that will persist across saves...
		if (!this.persistent) { this.persistent = PersistentMapStatsHandler(EventHandler.Find("PersistentMapStatsHandler")); }
		if (this.persistent) { this.persistent.Levels.Copy(this.Levels); }
	}

	override void OnRegister()
	{
		TitleFont = BigFont;
		HeadingFont = SmallFont;
		StatFont = SmallFont;

		if (!TitleFont) { TitleFont = SmallFont; }
		if (!HeadingFont) { HeadingFont = SmallFont; }
		if (!StatFont) { StatFont = SmallFont; }

		titlescale = GetScale(TitleFont) * 1.2;
		headingscale = GetScale(HeadingFont);
		fontscale = GetScale(StatFont);

		lineheight = int(StatFont.GetHeight() * fontscale) + 1;
	}

	override void WorldTick()
	{
		if (active[consoleplayer])
		{
			// Keep the current level data updated (just in case we decide to use it like this in the future...)
			SaveLevelData();

			PlayerInfo cp = players[consoleplayer];

			// Turn the stats off if you move...
			if (
				cp && 
				(
					cp.cmd.forwardmove || 
					cp.cmd.sidemove || 
					(
						cp.cmd.buttons & BT_CROUCH ||
						cp.cmd.buttons & BT_JUMP 
					)
				)
			)
			{
				active[consoleplayer] = false;
			}
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		if (e.IsSaveGame) // If loading a save, check for saved stats and copy them over if found
		{
			if (!persistent) { persistent = PersistentMapStatsHandler(EventHandler.Find("PersistentMapStatsHandler")); }
			if (persistent) { Levels.Copy(persistent.Levels); }
		}
		else
		{
			int index = Levels.Size() - 1;

			if (index > -1 && !(levels[index].mapname ~== "TITLEMAP") && level.totaltime > 0)
			{
				let l = levels[index];

				int bonus = l.timebonusamt * PAR_AMOUNT;

				if (l.totalkills > 0 && l.killcount == l.totalkills) { bonus += PERCENT100AMT; }
				if (l.totalsecrets > 0 && l.secretcount == l.totalsecrets) { bonus += PERCENT100AMT; }
				if (l.totalitems > 0 && l.itemcount == l.totalitems) { bonus += PERCENT100AMT; }

				players[consoleplayer].mo.GiveInventory("Score", bonus);
			}
		}

		active[consoleplayer] = false;

		chapter = level.mapname.Mid(1, 1).ToInt();

		if (Game.IsSoD() && level.levelnum % 100 == 21)
		{
			int l = FindLevelNumber(level.levelnum - 3);
			if (l < Levels.Size())
			{
				LevelData previous = Levels[l];
				if (previous && level.IsPointInLevel(previous.pos[consoleplayer]))
				{
					players[consoleplayer].mo.SetOrigin(previous.pos[consoleplayer], false);
				}
			}
		}
	
		SaveLevelData();
	}

	override void WorldUnloaded(WorldEvent e)
	{
		SaveLevelData();
	}

	override void RenderOverlay(RenderEvent e)
	{
		if (active[consoleplayer])
		{
			Array<LevelData> summary;

			int screenwidth = Screen.GetWidth();
			int screenheight = Screen.GetHeight();

			screen.Dim(0x000000, 0.45, 0, 0, screenwidth, screenheight);

			DrawChapter(chapter, 320, 64, center);

			for (int i = 0; i < persistent.Levels.Size(); i++)
			{
				let m = persistent.Levels[i];

				// Filter to only show results from maps named in the ExLy format.
				String mapname = m.mapname;
				mapname = mapname.MakeUpper();

				if (mapname.Mid(0, 1) != "E" || mapname.Mid(2, 1) != "L") { continue; }

				int mapnum = mapname.ByteAt(3) - 48;

				int i = summary.Size();
				for (int j = 0; j < i; j++)
				{
					if (summary[j] && summary[j].levelnum == mapnum) { i = j; }
				}

				LevelData c;

				if (i < summary.Size())
				{
					c = summary[i];
				}
				else
				{
					c = New("LevelData");
					summary.Push(c);
				}

				// Add the values for the pieces of multi-part maps together
				c.mapname = mapname.Mid(0, 4); // Only use first 4 letters of map name
				c.levelname = m.levelname;
				c.levelnum = mapnum;
				c.totalkills += m.totalkills;
				c.killcount += m.killcount;
				c.totalitems += m.totalitems;
				c.itemcount += m.itemcount;
				c.totalsecrets += m.totalsecrets;
				c.secretcount += m.secretcount;
				c.leveltime += m.leveltime;
			}

			LevelData totals = New("LevelData"); // This has to be initialized, or bad things happen!
			totals.mapname = "Stat Totals";
			totals.levelname = "Stat Totals";
			totals.levelnum = 0;
			totals.totalkills = 0;
			totals.killcount  = 0;
			totals.totalitems  = 0;
			totals.itemcount = 0;
			totals.totalsecrets = 0;
			totals.secretcount = 0;
			totals.leveltime = 0;

			for (int i = 0; i < summary.Size(); i++)
			{
				let l = summary[i];

				totals.totalkills += l.totalkills;
				totals.killcount += l.killcount;
				totals.totalitems += l.totalitems;
				totals.itemcount += l.itemcount;
				totals.totalsecrets += l.totalsecrets;
				totals.secretcount += l.secretcount;
				totals.leveltime += l.leveltime;

				DrawSummary(l, 112, 116);
			}

			DrawTotals(totals, -112, -108);
		}
	}

	double GetScale(font fnt)
	{
		if (fnt == SmallFont) { return 1.0; }

		double scale = double(SmallFont.GetHeight()) / fnt.GetHeight();

		// Use the total time clock width as a "standard" width for scaling
		double w = fnt.StringWidth("00:00:00");
		if (w > 52.0) { scale = 52.0 / w; }

		return scale;
	}

	enum align
	{
		left,
		right,
		center
	}

	ui void DrawChapter(int chapter, int xoffset, int yoffset, int alignment = left)
	{
		if (xoffset < 0) { xoffset = width + xoffset; }
		if (yoffset < 0) { yoffset = height + yoffset; }

		String chaptertitle = Stringtable.Localize("$STATS_CHAPTER") .. chapter;

		// Print chapter number
		DrawTextScaled(TitleFont, Font.FindFontColor("WolfMenuYellowBright"), xoffset, yoffset, chaptertitle, fontscale * 1.5, alignment);
	}

	ui void DrawTotals(LevelData totals, int xoffset, int yoffset)
	{
		if (xoffset < 0) { xoffset = width + xoffset; }
		if (yoffset < 0) { yoffset = height + yoffset; }

		yoffset = DrawData(totals, xoffset - 72, yoffset, true);

		String timetitle = Stringtable.Localize("$STATS_TIME");

		String s;

		// Print total time
		DrawTextScaled(HeadingFont, Font.CR_DARKGRAY, xoffset - 72, yoffset, timetitle, headingscale, right);
		let seconds = Thinker.Tics2Seconds(totals.leveltime);
		s = String.Format("%02i:%02i:%02i", seconds / 3600, (seconds % 3600) / 60, seconds % 60);
		DrawTextScaled(StatFont, Font.CR_GRAY, xoffset + 50, yoffset, s, fontscale, right);
	}

	ui int DrawDataLine(String title, int n, int d, int x, int y, bool isTotals)
	{
		if (d > 0)
		{
			String amt, total, percentage;

			DrawTextScaled(HeadingFont, Font.CR_DARKGRAY, x, y, title, headingscale, isTotals ? right : left);

			if (isTotals) { x -= 52; }

			amt = PadString(String.Format("%i", n), 3);
			total = String.Format("%i", d);
			percentage = String.Format("%i%%", n * 100 / d);

			DrawTextScaled(StatFont, Font.CR_GRAY, x + 90, y, amt, fontscale, right);
			DrawTextScaled(StatFont, Font.CR_GRAY, x + 97, y, "/", fontscale, center);
			DrawTextScaled(StatFont, Font.CR_GRAY, x + 104, y, total);
			DrawTextScaled(StatFont, Font.CR_GRAY, x + (isTotals ? 175 : 160), y, percentage, fontscale, right);

			return y += lineheight;
		}

		return y += lineheight / 2;
	}

	ui int DrawData(LevelData l, int x, int y, bool isTotals = false)
	{
		String prefix = (isTotals ? "STATS" : "AM");

		String treasuretitle = Stringtable.Localize("$" .. prefix .. "_ITEMS");
		String killstitle = Stringtable.Localize("$" .. prefix .. "_MONSTERS");
		String secretstitle = Stringtable.Localize("$" .. prefix .. "_SECRETS");

		y = DrawDataLine(treasuretitle, l.itemcount, l.totalitems, x, y, isTotals);
		y = DrawDataLine(killstitle, l.killcount, l.totalkills, x, y, isTotals);
		y = DrawDataLine(secretstitle, l.secretcount, l.totalsecrets, x, y, isTotals);

		return y;
	}

	ui void DrawSummary(LevelData l, int xoffset, int yoffset)
	{
		int index = l.levelnum ? l.levelnum : 10;

		int x, y;

		xoffset = min(xoffset, width / 2 - 176 - 16 - 88);
		if (yoffset < 0) { yoffset = height + yoffset; }

		if (index <= 3)
		{
			x = xoffset;
			y = yoffset + 64 * (index - 1);
		}
		else if (index <= 6)
		{
			x = xoffset + 176 + 16;
			y = yoffset + 64 * (index - 4);
		}
		else if (index <= 9)
		{
			x = xoffset + 176 + 16 + 176 + 16;
			y = yoffset + 64 * (index - 7);
		}
		else // Secret map
		{
			x = width / 2 - 88;
			y = yoffset + 192;
		}

		// Dim a frame around the level's info draw area
		DimScaled(0x000000, 0.25, x - 2, y - 2, 182, 62);
		DimScaled(0x000000, 0.25, x - 1, y - 1, 181, lineheight);

		// Print level title
		DrawTextScaled(TitleFont, Font.FindFontColor("WolfMenuYellowBright"), x, y, l.levelname, titlescale);

		// Print level time in hh:mm:ss format
		let seconds = Thinker.Tics2Seconds(l.leveltime);
		String t = String.Format("%02i:%02i:%02i", seconds / 3600, (seconds % 3600) / 60, seconds % 60);
		DrawTextScaled(StatFont, Font.CR_GRAY, x + 176 - StatFont.StringWidth(t) * fontscale, y, t);

		y += 2 + lineheight;

		y = DrawData(l, x + 8, y + 6);
	}

	ui void DimScaled(Color clr = 0x000000, double alpha = 0.5, int x = 0, int y = 0, int w = width, int h = height)
	{
		double dimscale = double(Screen.GetHeight()) / height;

		Vector2 pos, size;
		[pos, size] = Screen.VirtualToRealCoords((x, y), (w, h), (width, height));

		Screen.Dim(clr, alpha, int(pos.x), int(pos.y), int(size.x), int(size.y));
	}

	ui String PadString(String input, int digits)
	{
		While (input.Length() < digits)
		{	
			input = " " .. input;
		}

		return input;
	}

	ui void DrawTextScaled(Font fnt, int normalcolor, double x, double y, String text, double scale = 0, int alignment = left)
	{
		if (!scale) { scale = fontscale; }

		if (alignment == center) { x -= fnt.StringWidth(text) * scale / 2; }
		else if (alignment == right) { x -= fnt.StringWidth(text) * scale; }

		Screen.DrawText(fnt, normalcolor, int(x / scale), int(y / scale), text, DTA_VirtualWidth, int(width / scale), DTA_VirtualHeight, int(height / scale));
	}

	static void Toggle(Actor activator, int status = -1)
	{
		MapStatsHandler this = MapStatsHandler(StaticEventHandler.Find("MapStatsHandler"));
		let p = activator.player;

		if (!this || !p) { return; }

		if (status > -1) { this.active[activator.PlayerNumber()] = status; }
		else { this.active[activator.PlayerNumber()] = !this.active[activator.PlayerNumber()]; }
	}

	static void Clear()
	{
		MapStatsHandler this = MapStatsHandler(StaticEventHandler.Find("MapStatsHandler"));
		if (!this) { return; }

		this.SpecialItemPickups.Clear();
		this.Levels.Clear();
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (!sv_cheats && (netgame || deathmatch)) { return; }
		if (e.Name == "stats") { Toggle(players[e.Player].mo); }
	}
}