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

const PAR_AMOUNT = 500;
const PERCENT100AMT = 10000;
const SECRETAMT = 15000;

class ClassicStats : DoomStatusScreen
{
	int intermissioncounter;
	int bonus, cnt_bonus[MAXPLAYERS], breathestate, breathetime, killcount, secretcount, itemcount;
	TextureID Breathe[2], BJFinal;
	int points, lives;
	int style;
	Font ClassicFont;
	LevelData totals;
	LevelInfo info;

	int fadetarget;
	int fadetime;
	double fadealpha;

	enum styles
	{
		normal,
		secret,
		finale,
	};

	color textcolor;
	double scale;
	Font displayFont, titlefont;
	bool allbots;

	override void initStats ()
	{
		intermissioncounter = gameinfo.intermissioncounter;
		CurState = StatCount;
		acceleratestage = 0;

		cnt_otherkills = 0;
		total_frags = 0;
		total_deaths = 0;

		int playercount, botcount;

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			cnt_kills[i] = cnt_items[i] = cnt_secret[i] = cnt_bonus[i] = 0;
			cnt_frags[i] = cnt_deaths[i] = player_deaths[i] = 0;

			if (!playeringame[i]) { continue; }

			for (int j = 0; j < MAXPLAYERS; j++)
			{
				if (playeringame[j]) { player_deaths[i] += Plrs[j].frags[i]; }
			}

			total_deaths += player_deaths[i];
			total_frags += Plrs[i].fragcount;

			if (!deathmatch) { dofrags += fragSum(i); }

			playercount++;
			if (players[i].bot) { botcount++; }
		}

		if (playercount == botcount + 1) { allbots = true; }

		if (!deathmatch) { dofrags = !!dofrags; }

		cnt_pause = Thinker.TICRATE;

		if (gamestate == GS_FINALE) { GameHandler.ChangeMusic("URAHERO"); }

		displayFont = Font.GetFont("MiniFont");
		titlefont = SmallFont;

		textcolor = FONT.CR_WHITE;
		scale = 0.4;

		switch (style)
		{
			case secret:
				bonus = SECRETAMT;
				sp_state = 10;
				break;
			case finale:
				totals = GetTotals();
				killcount = totals.killcount;
				secretcount = totals.secretcount;
				itemcount = totals.itemcount;
				sp_state = 4;
				break;
			default:
				killcount = Plrs[me].skills;
				secretcount = Plrs[me].ssecret;
				itemcount = Plrs[me].sitems;
				sp_state = 1;
				break;
		}
	}

	LevelData GetTotals() // Pull the total stats from the map stats event handler - it saves stats for *all* maps, not just main chapters
	{
		LevelData totals = New("LevelData");
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

		MapStatsHandler stats = MapStatsHandler(StaticEventHandler.Find("MapStatsHandler"));

		if (stats)
		{
			Array<LevelData> summary;

			for (int i = 0; i < stats.Levels.Size(); i++)
			{
				let m = stats.Levels[i];

				// Filter to only show results from maps named in this episode (e.g., matching "E1L").
				if (m.mapname.Mid(0, 3) ~== wbs.current.Mid(0, 3)) { summary.Push(m); }
				else { continue; }
			}

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
			}
		}

		return totals;
	}

	override void updateStats ()
	{
		// Actual score bonus handled in MapStatsHandler WorldLoaded function
		// This is just here for appearances
		LevelData stats = MapStatsHandler.GetStats(wbs.current);
		if (!stats) { return; }

		int timeleft = style == normal ? stats.timebonusamt : 0;

		if (acceleratestage && sp_state < 10)
		{
			acceleratestage = 0;
			sp_state = 11;
			
			bonus = timeleft * PAR_AMOUNT;

			if (multiplayer)
			{
				for (int i = 0; i < MAXPLAYERS; i++)
				{
					if (!playeringame[i]) { continue; }

					cnt_kills[i] = Plrs[i].skills;
					cnt_items[i] = Plrs[i].sitems;
					cnt_secret[i] = Plrs[i].ssecret;
					cnt_frags[i] = Plrs[i].fragcount;
					cnt_deaths[i] = player_deaths[i];

					if (!deathmatch && dofrags) { cnt_frags[i] = fragSum(i); }

					if (style == normal)
					{
						if (cnt_kills[i] == stats.totalkills) { bonus += PERCENT100AMT; }
						if (cnt_secret[i] == stats.totalsecrets) { bonus += PERCENT100AMT; }
						if (cnt_items[i] == stats.totalitems) { bonus += PERCENT100AMT; }
					}

					if (style != finale)
					{
						cnt_bonus[i] = bonus;

						AddPoints(bonus, i);
					}
				}

				cnt_otherkills = otherkills;
			}
			else
			{
				cnt_kills[0] = stats.totalkills ? stats.killcount : 0;
				cnt_secret[0] = stats.totalsecrets ? stats.secretcount : 0;
				cnt_items[0] = stats.totalitems ? stats.itemcount : 0;

				if (style == normal)
				{
					if (cnt_kills[0] == stats.totalkills) { bonus += PERCENT100AMT; }
					if (cnt_secret[0] == stats.totalsecrets) { bonus += PERCENT100AMT; }
					if (cnt_items[0] == stats.totalitems) { bonus += PERCENT100AMT; }
				}

				if (style != finale)
				{
					cnt_bonus[0] = bonus;

					AddPoints(bonus);
				}
			}
		}

		if (sp_state == 2)
		{
			if (timeleft && !deathmatch)
			{
				bonus = timeleft * PAR_AMOUNT;

				for (int i = 0; i < MAXPLAYERS; i++)
				{
					if (!playeringame[i]) { continue; }

					UpdateCounter(cnt_bonus[i], bonus, 0, PAR_AMOUNT * 2, PAR_AMOUNT / 40, p:i);
				}
			}
			else { sp_state += 2; }
		}
		else if (sp_state == 4)
		{
			for (int i = 0; i < MAXPLAYERS; i++)
			{
				if (!playeringame[i]) { continue; }

				if (deathmatch) { UpdateCounter(cnt_frags[i], Plrs[i].fragcount, 0, p:i); }
				else { UpdateCounter(cnt_kills[i], multiplayer ? Plrs[i].skills : stats.killcount, style == normal ? stats.totalkills : 0, p:i); }
			}
		}
		else if (sp_state == 6)
		{
			for (int i = 0; i < MAXPLAYERS; i++)
			{
				if (!playeringame[i]) { continue; }
				
				if (deathmatch) { UpdateCounter(cnt_deaths[i], player_deaths[i], 0, p:i); }
				else { UpdateCounter(cnt_secret[i], multiplayer ? Plrs[i].ssecret : stats.secretcount, style == normal ? stats.totalsecrets : 0, p:i); }
			}
		}
		else if (sp_state == 8)
		{
			if (deathmatch)
			{
				sp_state = 11;
			}
			else
			{
				for (int i = 0; i < MAXPLAYERS; i++)
				{
					if (!playeringame[i]) { continue; }
				
					UpdateCounter(cnt_items[i], multiplayer ? Plrs[i].sitems : stats.itemcount, style == normal ? stats.totalitems : 0, p:i);
				}
			}
		}
		else if (sp_state == 10)
		{
			if (bonus > 0)
			{
				for (int i = 0; i < MAXPLAYERS; i++)
				{
					if (!playeringame[i]) { continue; }
				
					AddPoints(bonus, i);
				}

				sp_state++;
			}
			else { sp_state += 2; }
		}
		else if (sp_state == 12)
		{
			if (acceleratestage)
			{
				if (Game.IsSod() && info.levelnum % 100 >= 2 && !GameHandler.GameFilePresent("SOD"))
				{
					PlaySound("pickups/life");
					Menu.StartMessage(StringTable.Localize("$DEMOSTRING"), 1);

					sp_state++;

					return;
				}

				if (!multiplayer && (style == finale || level.info.nextmap.left(6) == "enDSeQ" || level.info.nextmap == ""))
				{
					if (Game.IsSoD()) { Menu.SetMenu("SoDFinale", -1); }
					else { Menu.SetMenu("Episode" .. info.levelnum / 100 .. "End", -1); }
				}

				if (gametic > fadetarget)
				{
					if (!multiplayer || allbots)
					{
						fadetarget = gametic + fadetime;
					}
				}

				if (fadetarget == gametic) { initNoState(); }

				if (multiplayer && !allbots) { sp_state++; }
			}
		}
		else if (sp_state == 14) // Press a key to advance in multiplayer
		{
			for (int i = 0; i < MAXPLAYERS; i++)
			{
				if (!playeringame[i]) { continue; }

				cnt_kills[i] = Plrs[i].skills;
				cnt_items[i] = Plrs[i].sitems;
				cnt_secret[i] = Plrs[i].ssecret;
				cnt_frags[i] = Plrs[i].fragcount;
				cnt_deaths[i] = player_deaths[i];
			}

			if (
				(players[consoleplayer].settings_controller && !ScreenJobRunner.IsPlayerReady(consoleplayer)) &&
				(style == finale || level.info.nextmap.left(6) == "enDSeQ" || level.info.nextmap == "")
			)
			{
				EventHandler.SendNetworkEvent("openfinale", level.info.levelnum / 100);
			}

			sp_state++;
		}
		else if (sp_state & 1)
		{
			if (!--cnt_pause)
			{
				sp_state++;
				cnt_pause = Thinker.TICRATE;
			}
		}
	}

	void UpdateCounter(out int current, int count, int max = 0, int step = 2, int freq = 5, int p = -1)
	{
		if (p == -1) { p = me; }
		
		if (intermissioncounter)
		{
			if (count)
			{
				current += step;
				
				if (!(bcnt % freq)) { PlaySound("stats/bonuscount"); }
			}
			else { current = 0; }
		}

		if (!intermissioncounter || current >= count)
		{
			current = count;
			if (max > 0 && count == max)
			{
				bonus += PERCENT100AMT;
				cnt_bonus[p] = bonus;
				PlaySound("stats/bonus100");
			}
			else if (count) { PlaySound("stats/total"); }
			else { PlaySound("stats/nobonus"); }
			sp_state++;
		}
	}

	override void DrawStats (void)
	{
		if (StatusBar is "ClassicStatusBar") { ClassicStatusBar(StatusBar).DrawClassicBar(false, points, lives); }

		switch (style)
		{
			case secret:
				DrawBJ(0, 16);

				Write(14, 4, lnametexts[0]);
				Write(16, 6, "$STATS_COMPLETED");

				Write(22, 16, "$STATS_BONUS2");
				Write(10, 16, String.Format("%i", bonus));
				break;
			case finale:
				DrawImage(8, 8, BJFinal);

				Write(18, 2, "$STATS_YOUWIN");

				Write(14, 6, "$STATS_TOTALTIME");
				WriteTime(14, 8, wbs.totaltime);

				Write(12, 12, "$STATS_AVERAGES");
				Write(22, 14, "$STATS_KILL", right);
				WritePercent(30, 14, cnt_kills[0], totals.totalkills);
				Write(30, 14, "%");

				Write(22, 16, "$STATS_SECRET", right);
				WritePercent(30, 16, cnt_secret[0], totals.totalsecrets);
				Write(30, 16, "%");

				Write(22, 18, "$STATS_TREASURE", right);
				WritePercent(30, 18, cnt_items[0], totals.totalitems);
				Write(30, 18, "%");

				break;
			default:
				DrawBJ(0, 16);

				Write(14, 2, lnametexts[0]);
				Write(14, 4, "$STATS_COMPLETED");

				Write(14, 7, "$STATS_BONUS");
				Write(36, 7, String.Format("%i", cnt_bonus[0]), right);

				Write(24, 10, "$STATS_LEVELTIME", right);
				WriteTime(26, 10, Plrs[me].stime);

				if (info.partime > 0)
				{ 
					Write(24, 12, "$STATS_PAR", right);
					WriteTime(26, 12, info.partime, true);
				}

				Write(29, 14, "$STATS_KILLRATIO", right);
				WritePercent(37, 14, cnt_kills[0], wbs.maxkills);
				Write(37, 14, "%");

				Write(29, 16, "$STATS_SECRETRATIO", right);
				WritePercent(37, 16, cnt_secret[0], wbs.maxsecret);
				Write(37, 16, "%");

				Write(29, 18, "$STATS_TREASURERATIO", right);
				WritePercent(37, 18, cnt_items[0], wbs.maxitems);
				Write(37, 18, "%");
				break;
		}

		if (multiplayer) { DrawScoreboard(21, 17); }
	}

	void DrawBJ(int x, int y)
	{
		if (bcnt > breathetime)
		{
			breathestate ^= 1;
			breathetime = bcnt + 17;
		}

		DrawImage(x, y, Breathe[breathestate]);
	}

	enum align
	{
		left,
		right,
		center,
	};

	enum valign
	{
		top,
		bottom,
		middle,
	};

	void DrawImage(int x, int y, TextureID img, int align = left, int valign = top, int w = 0, int h = 0, color shade = -1, double alpha = 1.0)
	{
		if (!img) { return; }

		Vector2 size = TexMan.GetScaledSize(img);

		Vector2 scalexy = (1.0, 1.0);

		if (w && size.x > w) { scalexy.x = double(w) / size.x; }
		if (h && size.y > h) { scalexy.y = double(h) / size.y; }

		double scale = min(scalexy.x, scalexy.y);

		size *= scale;

		if (align == right) { x = int(x - size.x); }
		else if (align == center) { x = int(x - size.x / 2); }

		if (valign == bottom) { y = int(y - size.y); }
		else if (valign == middle) { y = int(y - size.y / 2); }

		bool alphachannel;

		if (shade > 0) { alphachannel = true; }

		screen.DrawTexture(img, true, x, y, DTA_320x200, true, DTA_DestWidth, int(size.x), DTA_DestHeight, int(size.y), DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_Alpha, alpha, DTA_AlphaChannel, alphachannel, DTA_FillColor, shade);
	}

	void DrawText(int x, int y, String text, Font fnt = null, color clr = Font.CR_UNTRANSLATED, int align = left)
	{
		if (!fnt) { fnt = IntermissionFont; }

		text = StringTable.Localize(text);

		if (align == right) { x -= fnt.StringWidth(text); }
		else if (align == center) { x -= fnt.StringWidth(text) / 2; }

		screen.DrawText(fnt, clr, x, y, text, DTA_320x200, true);
	}

	void Write(int x, int y, String text, int align = left)
	{
		x *= 8;
		y *= 8;

		DrawText(x, y, text, align:align);
	}

	void WriteTime(int x, int y, int t, bool altmethod = false)
	{
		if (t < 0) { return; }

		if (altmethod) { t /= Thinker.TICRATE; }
		else { t = Thinker.Tics2Seconds(t); }

		int minutes = min(t / 60, 99);
		int seconds = t % 60;

		Write(x, y, String.Format("%02d:%02d", minutes, seconds));
	}

	void WritePercent(int x, int y, int n, int d)
	{
		if (n <= 0 || d <= 0)
		{
			Write(x, y, "0", right);
		}
		else
		{
			Write(x, y, String.Format("%i", n * 100 / d), right);
		}
	}

	override void Start (wbstartstruct wbstartstruct)
	{
		wbs = wbstartstruct;
		acceleratestage = 0;
		cnt = bcnt = 0;
		me = wbs.pnum;
		for (int i = 0; i < MAXPLAYERS; i++) Plrs[i] = wbs.plyr[i];

		ClassicFont = Font.GetFont("WOLFNUM");

		Breathe[0] = TexMan.CheckForTexture("BREATHE0", TexMan.Type_Any);
		Breathe[1] = TexMan.CheckForTexture("BREATHE1", TexMan.Type_Any); 
		BJFinal =  TexMan.CheckForTexture("BJFinal", TexMan.Type_Any); 

		points = GetScore();
		lives = LifeHandler.GetLives(players[me].mo);

		ParsedMap curmap = MapHandler.GetCurrentMap();
		if (curmap) { info = curmap.GetInfo(); }
		if (!info) { info = level.info; }

		// Use the local level structure which can be overridden by hubs
		Array<String> levelname;
		info.levelname.Split(levelname, ": "); // Use the portion of the name after the colon, if there is one.

		lnametexts[0] = levelname[levelname.Size() - 1];
		lnametexts[1] = wbstartstruct.nextname;

		int levelnum = info.levelnum % 100;

		if (wbs.next == "") { style = finale; }
		else if 
		(
			(Game.IsSoD() && levelnum > 18) ||
			(info.levelnum > 100 && levelnum == 10)
		) { style = secret; }
		else { style = normal; }

		fadealpha = 1.0;
		fadetime = 12;
		fadetarget = gametic;

		initStats();
	}

	override void End()
	{
		Super.End();

		EventHandler.SendNetworkEvent("bonus", me, bonus);
	}

	int GetScore()
	{
		let score = players[me].mo.FindInventory("Score");
		if (score) { return score.Amount; }

		return 0;
	}

	void AddPoints(int amt, int p = -1)
	{
		if (p == -1) { p = me; }

		points += amt;
		int lifeamt;

		let scoreinv = Score(players[p].mo.FindInventory("Score"));
		let scoredef = Score(GetDefaultByType("Score"));

		if (scoreinv) { lifeamt = scoreinv.lifeamount; }
		else { lifeamt = scoredef.lifeamount; }

		while (points >= lifeamt)
		{
			lifeamt = lifeamt + scoredef.lifeamount;
			lives = clamp(lives + 1, 0, 9);
		}
	}

	override void Ticker(void)
	{
		// counter for general background animation
		bcnt++;  
	
		if (bcnt == 1)
		{
			GameHandler.ChangeMusic("ENDLEVEL");
		}

		switch (CurState)
		{
			case StatCount:
				updateStats();
				break;
		
			case NoState:
				updateNoState();
				break;

			case LeavingIntermission:
				break;
		}

		if (Game.IsSoD() && info.levelnum % 100 == 21) { fadealpha = 0.0; }
		else if (gametic > 35)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}
	}

	override void Drawer (void)
	{
		switch (CurState)
		{
			case StatCount:
				Screen.Dim(0x004040, 1.0, 0, 0, Screen.GetWidth(), Screen.GetHeight());
				DrawStats();
				break;
			case LeavingIntermission:
			default:
				break;
		}

		screen.Dim(0x000000, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	void drawTextScaled (Font fnt, double x, double y, String text, double scale, int translation = Font.CR_UNTRANSLATED)
	{
		screen.DrawText(fnt, translation, x / scale, y / scale, text, DTA_VirtualWidthF, 320 / scale, DTA_VirtualHeightF, 200 / scale);
	}

	void drawNumScaled (Font fnt, int x, int y, double scale, int n, int translation = Font.CR_UNTRANSLATED)
	{
		String s = String.Format("%d", n);
		drawTextScaled(fnt, x - fnt.StringWidth(s) * scale / 2, y, s, scale, translation);
	}

	void DimScaled(Color clr = 0x000000, double alpha = 0.5, int x = 0, int y = 0, int w = 0, int h = 0, int width = 320, int height = 200)
	{
		double dimscale = double(Screen.GetHeight()) / height;

		Vector2 pos, size;
		[pos, size] = Screen.VirtualToRealCoords((x, y), (w, h), (width, height));

		Screen.Dim(clr, alpha, int(pos.x), int(pos.y), int(size.x), int(size.y));
	}

	void DrawTextureScaled(TextureID tex, bool animate, double x, double y, double scale = 1.0, double imagescale = 1.0)
	{
		screen.DrawTexture(tex, animate, x / scale, y / scale, DTA_VirtualWidthF, 320 / scale, DTA_VirtualHeightF, 200 / scale, DTA_TopLeft, true, DTA_ScaleX, imagescale, DTA_ScaleY, imagescale);
	}

	void DrawScoreboard(int x, int y, int w = 79, int h = 86)
	{
		int lineheight = displayfont.GetHeight() * scale;
		int titleheight = titlefont.GetHeight() * scale;

		DimScaled(0x0, 0.5, x, y, w, h);

		int ypadding = 2;
		int xpadding = 1;

		w -= 2 * xpadding;
		h -= 2 * ypadding;

		String text_name = Stringtable.Localize("$SCORE_NAME");
		String text_kills = Stringtable.Localize("$SCORE_KILLS");
		String text_secrets = Stringtable.Localize("$SCORE_SECRETS");
		String text_treasure = Stringtable.Localize("$SCORE_TREASURE");
		String text_deaths = Stringtable.Localize("$SCORE_DEATHS");
		String text_frags = Stringtable.Localize("$SCORE_FRAGS");

		int datacolwidth;
		if (deathmatch) { datacolwidth = max(titlefont.StringWidth(text_deaths), titlefont.StringWidth(text_frags)) * scale; }
		else { datacolwidth = displayfont.StringWidth("0000") * scale; }
		
		int maxnamewidth, maxscorewidth, maxiconheight;
		[maxnamewidth, maxscorewidth, maxiconheight] = GetPlayerWidths();
			
		TextureID readyico = TexMan.CheckForTexture("Graphics/ReadySmall.png", TexMan.Type_Any);
		Vector2 readysize = TexMan.GetScaledSize(readyico) * scale;
		Vector2 readyoffset = TexMan.GetScaledOffset(readyico) * scale;
		
		maxnamewidth = w - datacolwidth * (deathmatch ? 2 : 3) - xpadding * 2 - readysize.x;
		maxscorewidth = max(maxscorewidth, readysize.x);

		int column[5];
		column[0] = x + xpadding; // icon
		column[1] = column[0] + maxscorewidth + xpadding;
		column[2] = column[1] + maxnamewidth + xpadding;
		column[3] = column[2] + datacolwidth + xpadding;
		column[4] = column[3] + datacolwidth + xpadding;

		drawTextScaled(titlefont, column[1], y, text_name, scale, textcolor);

		if (deathmatch)
		{
			drawTextScaled(titlefont, column[2] + (datacolwidth - titlefont.StringWidth(text_frags) * scale) / 2, y, text_frags, scale, textcolor);
			drawTextScaled(titlefont, column[3] + (datacolwidth - titlefont.StringWidth(text_deaths) * scale) / 2, y, text_deaths, scale, textcolor);
		}
		else
		{
			drawTextScaled(titlefont, column[2] + (datacolwidth - titlefont.StringWidth(text_kills) * scale) / 2, y, text_kills, scale, textcolor);
			drawTextScaled(titlefont, column[3] + (datacolwidth - titlefont.StringWidth(text_secrets) * scale) / 2, y, text_secrets, scale, textcolor);
			drawTextScaled(titlefont, column[4] + (datacolwidth - titlefont.StringWidth(text_treasure) * scale) / 2, y, text_treasure, scale, textcolor);
		}

		y += titleheight + ypadding;

		int missed_kills = wbs.maxkills;
		int missed_secrets = wbs.maxsecret;
		int missed_treasure = wbs.maxitems;

		// Sort all players
		Array<int> sortedplayers;
		GetSortedPlayers(sortedplayers, teamplay);

		// Draw lines for each player
		for (int i = 0; i < min(sortedplayers.Size(), (h - titleheight - ypadding) / (lineheight + ypadding) - (deathmatch ? 0 : 2)); i++)
		{
			int pnum = sortedplayers[i];
			PlayerInfo player = players[pnum];

			if (!playeringame[pnum]) { continue; }

			DimScaled(player.GetDisplayColor(), 0.5, column[0] - xpadding, y - ypadding / 2, w + xpadding * 2, lineheight / scale - ypadding / 2);

			if (ScreenJobRunner.IsPlayerReady(pnum))
			{
				// Bots are automatically assumed ready, to prevent confusion
				DrawTextureScaled(readyico, true, column[0], y - ypadding / 2, scale);
			}
			else if (player.mo.ScoreIcon.isValid())
			{
				DrawTextureScaled(player.mo.ScoreIcon, true, column[0], y - ypadding / 2, scale, 0.5);
			}

			drawTextScaled(displayFont, column[1], y, player.GetUserName(), scale, GetRowColor(player, pnum == consoleplayer));

			if (deathmatch)
			{
				drawNumScaled(displayFont, column[2] + datacolwidth / 2, y, scale, cnt_frags[pnum], textcolor);
				drawNumScaled(displayFont, column[3] + datacolwidth / 2, y, scale, cnt_deaths[pnum], textcolor);
			}
			else
			{
				drawNumScaled(displayFont, column[2] + datacolwidth / 2, y, scale, cnt_kills[pnum], textcolor);
				drawNumScaled(displayFont, column[3] + datacolwidth / 2, y, scale, cnt_secret[pnum], textcolor);
				drawNumScaled(displayFont, column[4] + datacolwidth / 2, y, scale, cnt_items[pnum], textcolor);

				missed_kills -= cnt_kills[pnum];
				missed_secrets -= cnt_secret[pnum];
				missed_treasure -= cnt_items[pnum];
			}
			y += lineheight + ypadding;
		}

		if (!deathmatch)
		{
			// Draw "OTHER" line
			drawTextScaled(displayFont, column[1], y, Stringtable.Localize("$SCORE_OTHER"), scale, Font.CR_DARKGRAY);
			drawNumScaled(displayFont, column[2] + datacolwidth / 2, y, scale, cnt_otherkills, textcolor);
			missed_kills -= cnt_otherkills;

			y += lineheight + ypadding;

			// Draw "MISSED" line
			drawTextScaled(displayFont, column[1], y, Stringtable.Localize("$SCORE_MISSED"), scale, Font.CR_DARKGRAY);
			drawNumScaled(displayFont, column[2] + datacolwidth / 2, y, scale, missed_kills, Font.CR_DARKGRAY);
			drawNumScaled(displayFont, column[3] + datacolwidth / 2, y, scale, missed_secrets, Font.CR_DARKGRAY);
			drawNumScaled(displayFont, column[4] + datacolwidth / 2, y, scale, missed_treasure, Font.CR_DARKGRAY);

			y += lineheight + ypadding;

			// Draw "TOTAL" line
			drawTextScaled(displayFont, column[1], y, Stringtable.Localize("$SCORE_TOTAL"), scale, textcolor);
			drawNumScaled(displayFont, column[2] + datacolwidth / 2, y, scale, wbs.maxkills, textcolor);
			drawNumScaled(displayFont, column[3] + datacolwidth / 2, y, scale, wbs.maxsecret, textcolor);
			drawNumScaled(displayFont, column[4] + datacolwidth / 2, y, scale, wbs.maxitems, textcolor);
		}
		else
		{
			// Draw "TOTAL" line
			drawTextScaled(displayFont, column[1], y, Stringtable.Localize("$SCORE_TOTAL"), scale, textcolor);
			drawNumScaled(displayFont, column[2] + datacolwidth / 2, y, scale, total_frags, textcolor);
			drawNumScaled(displayFont, column[3] + datacolwidth / 2, y, scale, total_deaths, textcolor);
		}
	}
}