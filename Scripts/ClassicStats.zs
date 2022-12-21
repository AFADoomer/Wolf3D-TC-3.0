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

	int fadetarget;
	int fadetime;
	double fadealpha;

	enum styles
	{
		normal,
		secret,
		finale,
	};

	override void initStats ()
	{
		intermissioncounter = gameinfo.intermissioncounter;
		CurState = StatCount;
		acceleratestage = 0;
		cnt_kills[0] = cnt_items[0] = cnt_secret[0] = -1;
		cnt_pause = Thinker.TICRATE;
		cnt_bonus[0] = 0;

		if (gamestate == GS_FINALE) { GameHandler.ChangeMusic("URAHERO"); }

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

			cnt_kills[0] = stats.totalkills ? stats.killcount : -1;
			cnt_secret[0] = stats.totalsecrets ? stats.secretcount : -1;
			cnt_items[0] = stats.totalitems ? stats.itemcount : -1;

			bonus = timeleft * PAR_AMOUNT;

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

		if (sp_state == 2)
		{
			if (timeleft)
			{
				bonus = timeleft * PAR_AMOUNT;

				UpdateCounter(cnt_bonus[0], bonus, 0, PAR_AMOUNT * 2, PAR_AMOUNT / 40);
			}
			else { sp_state += 2; }
		}
		else if (sp_state == 4)
		{
			UpdateCounter(cnt_kills[0], stats.killcount, style == normal ? stats.totalkills : 0);
		}
		else if (sp_state == 6)
		{
			UpdateCounter(cnt_secret[0], stats.secretcount, style == normal ? stats.totalsecrets : 0);
		}
		else if (sp_state == 8)
		{
			UpdateCounter(cnt_items[0], stats.itemcount, style == normal ? stats.totalitems : 0);
		}
		else if (sp_state == 10)
		{
			if (bonus > 0)
			{
				AddPoints(bonus);
				sp_state++;
			}
			else { sp_state += 2; }
		}
		else if (sp_state == 12)
		{
			if (acceleratestage)
			{
				if (Game.IsSod() && level.levelnum % 100 >= 2 && !GameHandler.GameFilePresent("SOD"))
				{
					PlaySound("pickups/life");
					Menu.StartMessage(StringTable.Localize("$DEMOSTRING"), 1);

					sp_state++;

					return;
				}

				if (style == finale)
				{
					if (Game.IsSoD()) { Menu.SetMenu("SoDFinale", -1); }
					else { Menu.SetMenu("Episode" .. level.levelnum / 100 .. "End", -1); }
				}

				if (gametic > fadetarget) { fadetarget = gametic + fadetime; }

				if (fadetarget == gametic) { initNoState(); }
			}
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

	void UpdateCounter(out int current, int count, int max = 0, int step = 2, int freq = 5)
	{
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
				cnt_bonus[0] = bonus;
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

				if (wbs.partime > 0)
				{ 
					Write(24, 12, "$STATS_PAR", right);
					WriteTime(26, 12, wbs.partime, true);
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

		// Use the local level structure which can be overridden by hubs
		Array<String> levelname;
		Level.levelname.Split(levelname, ": "); // Use the portion of the name after the colon, if there is one.

		lnametexts[0] = levelname[levelname.Size() - 1];
		lnametexts[1] = wbstartstruct.nextname;

		int levelnum = level.levelnum % 100;

		if (wbs.next == "") { style = finale; }
		else if 
		(
			(Game.IsSoD() && levelnum > 18) ||
			(level.levelnum > 100 && levelnum == 10)
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

	void AddPoints(int amt)
	{
		points += amt;
		int lifeamt;

		let scoreinv = Score(players[me].mo.FindInventory("Score"));
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

		if (Game.IsSoD() && level.levelnum % 100 == 21) { fadealpha = 0.0; }
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
}