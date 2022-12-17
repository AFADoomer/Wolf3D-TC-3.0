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
**/

class WidgetStatusBar : BaseStatusBar
{
	Array<widget> widgets;
	int widthoffset;
	int barstate;

	HUDFont mHUDFont;

	override void Init()
	{
		Super.Init();
		CalcOffsets();
	}

	override void Tick()
	{
		Super.Tick();
		Widget.TickWidgets();
	}

	override void Draw (int state, double TicFrac)
	{
		CalcOffsets();
		Super.Draw(state, TicFrac);

		barstate = state;

		Widget.DrawWidgets();
	}

	virtual void CalcOffsets()
	{
		CVar hudratiovar = CVar.FindCVar("g_hudratio");

		int hudratio = hudratiovar.GetInt();
		double ratio;
		
		switch (hudratio)
		{
			// These match the built-in ratios currently defined in the ForceRatios option value
			case 1:
				ratio = 16.0 / 9;
				break;
			case 2:
				ratio = 16.0 / 10;
				break;
			case 3:
				ratio = 4.0 / 3;
				break;
			case 4:
				ratio = 5.0 / 4;
				break;
			case 5:
				ratio = 17.0 / 10;
				break;
			case 6:
				ratio = 21.0 / 9;
				break;
			default:
				widthoffset = 0;
				return;
		}

		// If the ratio selected is wider than the current screen, don't do any offsetting
		if (ratio >= Screen.GetAspectRatio())
		{
			widthoffset = 0;
			return;
		}

		// Account for hud scaling, both automatic and manual
		Vector2 scale = Statusbar.GetHUDScale();
		double h = Screen.GetHeight() / scale.y;
		double w = h * ratio;

		widthoffset = int((Screen.GetWidth() / scale.x - w) / 2);
	}

	virtual Ammo, Ammo, int, int GetWeaponAmmo()
	{
		Ammo ammo1, ammo2;

		if (CPlayer.ReadyWeapon)
		{
			ammo1 = CPlayer.ReadyWeapon.Ammo1;
			ammo2 = CPlayer.ReadyWeapon.Ammo2;

			if (!ammo1)
			{
				ammo1 = ammo2;
				ammo2 = null;
			}
		}
		else
		{
			ammo1 = ammo2 = null;
		}

		let ammocount1 = !!ammo1 ? ammo1.Amount : 0;
		let ammocount2 = !!ammo2 ? ammo2.Amount : 0;

		return ammo1, ammo2, ammocount1, ammocount2;
	}

	virtual void DrawIcon(Inventory item, int x, int y, int size, int flags = DI_ITEM_CENTER, double alpha = 1.0, bool amounts = true, int style = STYLE_Translucent, color clr = 0xFFFFFFFF)
	{
		Vector2 texsize, iconsize;
		[texsize, iconsize] = ZScriptTools.ScaleTextureTo(item.icon, size);
		Vector2 textpos = (x, y + 3);

		if (flags & DI_ITEM_LEFT)
		{
			x += int((size - iconsize.x) / 2); // Center the icon in the size-defined cell
			textpos.x += size - 2;
		}
		else if (flags & DI_ITEM_RIGHT) {}
		else
		{
			textpos.x += size / 2 - 2;
		}

		if (flags & DI_ITEM_VCENTER)
		{
			textpos.y += size / 2 - 2;
		}
		else if (flags & DI_ITEM_TOP)
		{
			y += int((size - iconsize.y) / 2); // Center the icon in the size-defined cell
			textpos.y += size - 2;
		}

		DrawInventoryIcon(item, (x, y), flags, item.alpha * alpha, scale:texsize, style:style, clr:clr);

		if (!amounts) { return; }

		if (item is "BasicArmor")
		{
			let armor = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
			if (!armor) { return; }

			String value = FormatNumber(int(armor.SavePercent * 100)) .. "%";
			DrawString(mHUDFont, value, (textpos.x, textpos.y - mHUDFont.mFont.GetHeight() / 2), DI_TEXT_ALIGN_CENTER, Font.CR_GRAY);
		}
		else if (item.Amount > 1)
		{
			DrawString(mHUDFont, FormatNumber(item.Amount), (int(textpos.x), int(textpos.y - mHUDFont.mFont.GetHeight())), DI_TEXT_ALIGN_CENTER, Font.CR_GRAY, alpha);
		}
	}

	// Modified version of the internal function
	void DrawInventoryIcon(Inventory item, Vector2 pos, int flags = 0, double alpha = 1.0, Vector2 boxsize = (-1, -1), Vector2 scale = (1.,1.), int style = STYLE_Translucent, Color clr = 0xFFFFFFFF)
	{
		TextureID texture;
		Vector2 applyscale;
		[texture, applyscale] = GetIcon(item, flags, false);
		
		if (texture.IsValid())
		{
			if ((flags & DI_DIMDEPLETED) && item.Amount <= 0) flags |= DI_DIM;
			applyscale.X *= scale.X;
			applyscale.Y *= scale.Y;

			if (clr.a == 0) { clr += 0xFF000000; } // Make sure the color's alpha value is set

			DrawTexture(texture, pos, flags, alpha, boxsize, applyscale, style, clr);
		}
	}

	int CountPuzzleItems(int maxrows = 0, int col = 1)
	{
		int count = 0;
		Inventory nextinv = CPlayer.mo.Inv;

		while (nextinv)
		{
			if (!nextinv.bInvBar && nextinv is "PuzzleItem" && nextinv.icon)
			{
				count++;
			}

			if (maxrows > 0 && count == maxrows)
			{
				if (--col == 0) { break; }
				else { count = 0; }
			}

			nextinv = nextinv.Inv;
		}

		return count;
	}

	virtual int, int DrawPuzzleItems(int x, int y, int size = 32, int maxrows = 6, int maxcols = 0, bool vcenter = false, int flags = 0, double alpha = 1.0)
	{
		if (!CPlayer.mo.Inv) { return 0, 0; }

		int starty = y;
		int rows = 1;
		int rowcount = 1;
		int cols = 1;

		Inventory nextinv = CPlayer.mo.Inv;

		if (vcenter) { y -= int((size + 2) * CountPuzzleItems(maxrows) / 2.0); }

		nextinv = CPlayer.mo.Inv;

		while (nextinv)
		{
			// Draw puzzle items that are not already in the inventory bar
			if (!nextinv.bInvBar && nextinv is "PuzzleItem" && nextinv.icon)
			{
				DrawIcon(nextinv, x, y, size, flags, alpha);

				// Move down a block
				if (maxrows <= 0 || rows < maxrows)
				{
					y += size + 2;
					rows++;
					rowcount = max(rowcount, rows);
				}
				else if (maxcols <= 0 || cols <= maxcols) // Wrap to the next column if we're too long
				{
					y = vcenter ? starty - int((size + 2) * CountPuzzleItems(maxrows, cols + 1) / 2.0) : starty;
					rows = 1;

					x -= size + 2;
					cols++;
				}
				else
				{
					break;
				}
			}

			nextinv = nextinv.Inv;
		}

		return cols, rowcount;
	}

	// From v_draw.cpp
	static int GetUIScale(int altval = 0)
	{
		int scaleval;

		if (altval > 0) { scaleval = altval; }
		else if (uiscale == 0)
		{
			// Default should try to scale to 640x400
			int vscale = screen.GetHeight() / 400;
			int hscale = screen.GetWidth() / 640;
			scaleval = clamp(vscale, 1, hscale);
		}
		else { scaleval = uiscale; }

		// block scales that result in something larger than the current screen.
		int vmax = screen.GetHeight() / 200;
		int hmax = screen.GetWidth() / 320;
		int max = MAX(vmax, hmax);
		return MAX(1,MIN(scaleval, max));
	}
}

class ClassicStatusBar : WidgetStatusBar
{
	HUDFont ClassicFont, BigFont;
	TextureID mugshot;

	int mugshottimer, idleframe;
	Vector3 playerpos[MAXPLAYERS];

	TextureID pixel;
	int fizzleindex;
	Vector2 fizzlepoints[64000];

	bool fizzleeffect;
	Color fizzlecolor;
	int fizzlelayer; // 0 = under hud, 1 = on top
	int fizzlespeed;

	play int staticmugshot;
	play int staticmugshottimer;

	int savetimer;
	int savetimertime;

	override void Init()
	{
		Super.Init();
		SetSize(42, 320, 200);
		CompleteBorder = False;

		ClassicFont = HUDFont.Create("WOLFNUM", 0);
		BigFont = HUDFont.Create("BIGFONT", 0);
		mHUDFont = HUDFont.Create("SmallFont", 0);

		pixel = TexMan.CheckForTexture("Floor", TexMan.Type_Any);

		fizzleindex = 0;
		SetFizzleFadeSteps();

		fizzleeffect = false;

		savetimertime = 70;

		Vector2 hudscale = Statusbar.GetHudScale();

		AutomapWidget.Init("Automap", Widget.WDG_TOP | Widget.WDG_LEFT, 0);
		LogWidget.Init("Notifications", Widget.WDG_TOP | Widget.WDG_LEFT, 0, zindex:100);
		SingleLogWidget.Init("MidPrint", Widget.WDG_MIDDLE | Widget.WDG_CENTER, -1, (0, -0.125 * Screen.GetHeight() / hudscale.y), 99);

		KeyWidget.Init("Keys", Widget.WDG_RIGHT, 0);
		PuzzleItemWidget.Init("Puzzle Items", Widget.WDG_RIGHT, 1, (0, 0));

		LifeWidget.Init("Lives", Widget.WDG_BOTTOM, 0);
		InventoryWidget.Init("Selected Inventory", Widget.WDG_BOTTOM, 0);
		LogWidget.Init("Chat", Widget.WDG_BOTTOM, 0, zindex:99);
		ActiveEffectWidget.Init("Active Effects", Widget.WDG_BOTTOM, 1);

		AmmoHealthWidget.Init("Ammo and Health", Widget.WDG_BOTTOM | Widget.WDG_RIGHT, 0);
		ScoreWidget.Init("Score", Widget.WDG_BOTTOM | Widget.WDG_RIGHT, 1);
		AmmoWidget.Init("Ammo Summary", Widget.WDG_BOTTOM | Widget.WDG_RIGHT, 2);

		PositionWidget.Init("Position", Widget.WDG_RIGHT, 0);
	}

	override void Draw(int state, double TicFrac)
	{
		BaseStatusBar.Draw(state, TicFrac);

		BeginStatusBar(st_scale, 320, 200, 42);

		if (fizzlelayer == 0) { DrawFizzle(); }

		if (state == HUD_StatusBar)
		{
			DrawClassicBar();
		}

		CalcOffsets();
		barstate = state;
		Widget.DrawWidgets();

		DrawSaveIcon();

		if (fizzlelayer == 1)
		{
			DrawFizzle();
			if (state == HUD_StatusBar)
			{
				BeginStatusBar(st_scale);
				DrawClassicBar(false);
			}
		}

		BeginStatusBar(st_scale);
	}

	void DrawFizzle()
	{
		if (!pixel || !fizzleeffect)
		{
			EventHandler.SendNetworkEvent("fizzle_off");
			return;
		}

		EventHandler.SendNetworkEvent("fizzle_on");

		CVar fadestyle = CVar.GetCVar("g_fadestyle", CPlayer);
		if (fadestyle && fadestyle.GetInt()) // Just use a normal fade
		{
			Screen.Dim(fizzlecolor, double(fizzleindex) / (fizzlepoints.Size() - 1), 0, 0, Screen.GetWidth(), Screen.GetHeight());
		}
		else // Run the resource hog
		{
			if (fizzlespeed > 0)
			{
				for (int f = 0; f <= fizzleindex; f++)
				{
					Vector2 fizzle = fizzlepoints[f];

					screen.DrawTexture(pixel, false, fizzle.x, fizzle.y, DTA_320x200, true, DTA_DestWidth, 1, DTA_DestHeight, 1, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_FillColor, fizzlecolor);
					screen.DrawTexture(pixel, false, fizzle.x > 160 ? fizzle.x - 320 : fizzle.x + 320, fizzle.y, DTA_320x200, true, DTA_DestWidth, 1, DTA_DestHeight, 1, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_FillColor, fizzlecolor);
				}
			}
			else
			{
				for (int f = fizzleindex; f >= 0; f--)
				{
					Vector2 fizzle = fizzlepoints[f];

					screen.DrawTexture(pixel, false, fizzle.x, fizzle.y, DTA_320x200, true, DTA_DestWidth, 1, DTA_DestHeight, 1, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_FillColor, fizzlecolor);
					screen.DrawTexture(pixel, false, fizzle.x > 160 ? fizzle.x - 320 : fizzle.x + 320, fizzle.y, DTA_320x200, true, DTA_DestWidth, 1, DTA_DestHeight, 1, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_FillColor, fizzlecolor);
				}
			}
		}

		fizzleindex += fizzlespeed; // Draw a chunk of pixels at a time...

		if (fizzleindex >= fizzlepoints.Size()) { fizzleindex = fizzlepoints.Size() - 1; }
		if (fizzleindex <= 0)
		{
			fizzleindex = 0;
			fizzleeffect = false;
		}
	}

	static bool CheckFizzle()
	{
		if (!StatusBar || !ClassicStatusBar(StatusBar) || !StatusBar.CPlayer || !StatusBar.CPlayer.mo) { return false; }

		return ClassicStatusBar(StatusBar).fizzleeffect;
	}

	static void DoFizzle(Actor caller, color clr = 0xFF0000, bool Off = false, int layer = 0, int speed = 1920, bool all = false)
	{
		if (!StatusBar || !ClassicStatusBar(StatusBar) || !StatusBar.CPlayer || !StatusBar.CPlayer.mo) { return; }

		if (!all && StatusBar.CPlayer.mo != caller) { return; }

		ClassicStatusBar(StatusBar).fizzleeffect = !Off;
		ClassicStatusBar(StatusBar).fizzlecolor = clr;
		ClassicStatusBar(StatusBar).fizzlelayer = layer;

		CVar speedmod = CVar.FindCVar("g_fizzlespeed");
		if (speedmod) { speed = int(speed * max(0.5, speedmod.GetFloat())); }

		ClassicStatusBar(StatusBar).fizzlespeed = speed;
	}

	static void ReverseFizzle(Actor caller, color clr = 0xFF0000, bool Off = false, int layer = 0, int speed = 1920, bool all = false)
	{
		ClassicStatusBar(StatusBar).fizzleindex = ClassicStatusBar(StatusBar).fizzlepoints.Size() - 1;
		DoFizzle(caller, clr, Off, layer, -speed, all);
	}

	static void ClearFizzle(Actor caller)
	{
		DoFizzle(caller, 0, true);
	}

	play static void DoGrin(Actor caller)
	{
		if (players[consoleplayer].mo != caller) { return; }

		ClassicStatusBar(StatusBar).staticmugshot = 1;
		ClassicStatusBar(StatusBar).staticmugshottimer = gametic + 80; // 80 tics is roughly the duration of the chaingun pickup sound
	}

	play void DoIdleFace(Actor caller)
	{
		if (players[consoleplayer].mo != caller) { return; }

		ClassicStatusBar(StatusBar).staticmugshot = 2;
		ClassicStatusBar(StatusBar).staticmugshottimer = gametic + 35;
	}

	play static void DoScream(Actor caller)
	{
		if (players[consoleplayer].mo != caller) { return; }

		ClassicStatusBar(StatusBar).staticmugshot = 3;
		ClassicStatusBar(StatusBar).staticmugshottimer = gametic + 30;
	}

	void DrawClassicBar(bool drawborder = true, int points = -1, int lives = -1)
	{
		if (drawborder)
		{
			Vector2 window, windowsize, screensize, viewportsize, viewport;

			screensize = (Screen.GetWidth(), Screen.GetHeight());

			int blocks = automapactive ? 10 : clamp(screenblocks, 3, 10);

			double yoffset = (200 - RelTop);

			CVar borderstylevar = CVar.GetCVar("g_borderstyle", CPlayer);
			int borderstyle = borderstylevar ? borderstylevar.GetInt() : 0;

			if (borderstyle > 0)
			{
				double width = 200 * Screen.GetAspectRatio() + RelTop + 16;
				viewportsize.x = (blocks * width) / 10;
			}
			else
			{
				viewportsize.x = (blocks * (320 - 16)) / 10;
			}

			viewportsize.y = (blocks * yoffset) / 10 - 4;

			viewport.x = (320 - viewportsize.x) / 2;
			viewport.y = (yoffset - viewportsize.y) / 2 + 2;

			[window.x, window.y, windowsize.x, windowsize.y] = Statusbar.StatusbarToRealCoords(viewport.x, viewport.y, viewportsize.x, viewportsize.y);

			if (screenblocks < 11 && st_scale && !automapactive && (borderstyle != 2 || screenblocks < 10))
			{
				// Fill outside of boundaries with green
				Screen.Dim(0x004040, 1.0, 0, 0, int(window.x - 1), int(screensize.y));
				Screen.Dim(0x004040, 1.0, int(window.x + windowsize.x + 1), 0, int(screensize.x - window.x - windowsize.x + 1), int(screensize.y));
				Screen.Dim(0x004040, 1.0, int(window.x - 1), 0, int(windowsize.x + 4), int(window.y));
				Screen.Dim(0x004040, 1.0, int(window.x - 1), int(window.y + windowsize.y), int(windowsize.x + 4), int(screensize.y - window.y - windowsize.y + 1));

				// Draw border
				DrawImage("WBRD_T", (viewport.x, viewport.y - 3), DI_ITEM_LEFT_TOP, scale:(viewportsize.x / 3, 1.0));
				DrawImage("WBRD_B", (viewport.x, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP, scale:(viewportsize.x / 3, 1.0));
				DrawImage("WBRD_L", (viewport.x - 3, viewport.y), DI_ITEM_LEFT_TOP, scale:(1.0, viewportsize.y / 3));
				DrawImage("WBRD_R", (viewport.x + viewportsize.x, viewport.y), DI_ITEM_LEFT_TOP, scale:(1.0, viewportsize.y / 3));

				DrawImage("WBRD_TL", (viewport.x - 3, viewport.y - 3), DI_ITEM_LEFT_TOP);
				DrawImage("WBRD_TR", (viewport.x + viewportsize.x, viewport.y - 3), DI_ITEM_LEFT_TOP);
				DrawImage("WBRD_BL", (viewport.x - 3, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP);
				DrawImage("WBRD_BR", (viewport.x + viewportsize.x, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP);
			}
			else if (!st_scale || automapactive || (screenblocks == 10 && borderstyle == 2))
			{
				Vector2 coords, size;
				[coords.x, coords.y, size.x, size.y] = Statusbar.StatusbarToRealCoords(0, 200 - RelTop, 320, RelTop);

				Screen.Dim(0x004040, 1.0, 0, int(coords.y), int(screensize.x), int(size.y));
				if ((!st_scale && screenblocks == 10) || automapactive)
				{
					DrawImage("WBRD_B", (160, 200 - RelTop), DI_ITEM_TOP | DI_ITEM_HCENTER, scale:(windowsize.x, 1.0));
				}
			}
		}

		DrawImage("BAR", (160, 198), DI_SCREEN_CENTER_BOTTOM);

		//Lives
		if (lives < 0) { lives = LifeHandler.GetLives(CPlayer.mo); }
		DrawString(ClassicFont, FormatNumber(max(lives, 0)), (116, 176), DI_TEXT_ALIGN_CENTER | DI_SCREEN_CENTER_BOTTOM);

		//Level
		String levelnum = String.Format("%i", level.levelnum);
		if (level.levelnum > 100)
		{
			levelnum = String.Format("%i", level.levelnum % 100);
			if (levelnum == "0") { levelnum = "10"; }
		}

		if (levelnum == "0") { levelnum = "?"; }

		DrawString(ClassicFont, (Game.IsSoD() && levelnum == "21" ? "18" : levelnum), (32, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);

		//Score
		if (points < 0) { points = GetAmount("Score"); }
		DrawString(ClassicFont, FormatNumber(points % 1000000), (95, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);

		//Health
		DrawString(ClassicFont, FormatNumber(CPlayer.health), (191, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);

		DrawMugShot(136, 164);

		//Keys
		if (GetAmount("YellowKey") || GetAmount("YellowKeyLost")) { DrawImage("YKEY", (244, 172), DI_ITEM_CENTER | DI_SCREEN_CENTER_BOTTOM); }
		if (GetAmount("BlueKey") || GetAmount("BlueKeyLost")) { DrawImage("BKEY", (244, 188), DI_ITEM_CENTER | DI_SCREEN_CENTER_BOTTOM); }

		//Weapon
		TextureID icontex;
		String icon = "";
		double scale = 1.0;
		let weapon = CPlayer.ReadyWeapon;

		if (weapon)
		{
			String classname = weapon.GetClassName();

			icontex = GetInventoryIcon(weapon, 0);

			if (!icontex && weapon.SpawnState) { icontex = weapon.SpawnState.GetSpriteTexture(0); }
		}
		else
		{
			icontex = TexMan.CheckForTexture("LUGER", TexMan.Type_Any);
		}

		if (icontex)
		{
			Vector2 size = TexMan.GetScaledSize(icontex);
			Vector2 scalexy = (1.0, 1.0);

			if (size.x > 48) { scalexy.x = 48. / size.x; }
			if (size.y > 24) { scalexy.y = 24. / size.y; }

			scale = min(scalexy.x, scalexy.y);

			DrawTexture(icontex, (280, 179), DI_ITEM_CENTER, 1.0, (48, 24), (scale, scale), (!weapon || weapon is "ClassicWeapon") ? STYLE_Translucent : STYLE_Stencil, (!weapon || weapon is "ClassicWeapon") ? 0xFFFFFFFFF : 0xFF0000000);
		}


		//Ammo
		Ammo ammo1, ammo2;
		int ammocount = 0, ammocount1, ammocount2;
		[ammo1, ammo2, ammocount1, ammocount2] = GetWeaponAmmo();
		if (ammo2) { ammocount += ammocount2; }
		if (ammo1) { ammocount += ammocount1; } 
		DrawString(ClassicFont, FormatNumber(ammocount), (231, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);
	}

	void DrawMugShot(int x, int y, int size = 32)
	{
		if (staticmugshot && staticmugshottimer >= gametic)
		{
			mugshot = GetMugShot(5, type:staticmugshot);
			mugshottimer = 0;
		}
		else if (!mugshot || mugshottimer > min(35, Random[mugshot](0, 255)))
		{
			mugshot = GetMugShot(5);
			mugshottimer = 0;
			idleframe = Random(1, 2);
		}

		Vector2 texsize = TexMan.GetScaledSize(mugshot);
		if (texsize.x > size || texsize.y > size)
		{
			if (texsize.y > texsize.x)
			{
				texsize.y = size * 1.0 / texsize.y;
				texsize.x = texsize.y;
			}
			else
			{
				texsize.x = size * 1.0 / texsize.x;
				texsize.y = texsize.x;
			}
		}
		else { texsize = (1.0, 1.0); }

		DrawTexture(mugshot, (x, y), DI_ITEM_OFFSETS, scale:texsize);
	}

	TextureID GetMugShot(int accuracy = 5, String face = "", int type = 0)
	{
		String mugshot;

		if (face == "") { face = CPlayer.mo.face; }

		if (CPlayer.health > 0)
		{
			int hlevel = 0;

			int maxhealth = CPlayer.mo.mugshotmaxhealth > 0 ? CPlayer.mo.mugshotmaxhealth : CPlayer.mo.maxhealth;
			if (maxhealth <= 0) { maxhealth = 100; }

			while (CPlayer.health < (accuracy - 1 - hlevel) * (maxhealth / accuracy)) { hlevel++; }

			int index = (gamestate == GS_CUTSCENE || level.time < 5) ? 0 : Random[mugshot](0, 255) >> 6;
			if (index == 3) { index = 1; }

			// SoD-specific god face
			if (Game.IsSoD() || level.levelnum < 101)
			{
				if (players[consoleplayer].cheats & (CF_GODMODE | CF_GODMODE2))
				{
					mugshot = face .. "GOD" .. index;
				}
			}
	
			if (!mugshot.length())
			{
				switch (type)
				{
					default:
						mugshot = face .. "ST" .. hlevel .. index;
						break;
					case 1: // Grin
						mugshot = face .. "EVL";
						break;
					case 2: // Idle
						mugshot = face .. "STT" .. idleframe;
						break;
					case 3: // Scream
						mugshot = face .. "SCRM";
						break;

				}
			}
		}
		else
		{
			if (CPlayer.mo is "WolfPlayer" && WolfPlayer(CPlayer.mo).mutated)
			{
				mugshot = face .. "MUT";
			}
			else
			{
				mugshot = face .. "DEAD0";
			}
		}

		return TexMan.CheckForTexture(mugshot, TexMan.Type_Any); 
	}

	override Ammo, Ammo, int, int GetWeaponAmmo()
	{
		Ammo ammo1, ammo2;

		if (CPlayer.ReadyWeapon)
		{
			ammo1 = CPlayer.ReadyWeapon.Ammo1;
			ammo2 = CPlayer.ReadyWeapon.Ammo2;
			if (!ammo1)
			{
				ammo1 = ammo2;
				ammo2 = null;
			}
		}
		else
		{
			ammo1 = ammo2 = null;
		}

		if (!ammo1 && !ammo2)
		{
			ammo1 = Ammo(CPlayer.mo.FindInventory("WolfClip"));
		}

		let ammocount1 = ammo1 ? ammo1.Amount : 0;
		let ammocount2 = ammo2 ? ammo2.Amount : 0;

		return ammo1, ammo2, ammocount1, ammocount2;
	}

	override int GetProtrusion(double scaleratio) const
	{
		return int(24 * scaleratio);
	}

	override void Tick()
	{
		mugshottimer++;

		Super.Tick();

		savetimer = max(0, savetimer - 1);
	}

	// Adapted from here: http://fabiensanglard.net/fizzlefade/index.php
	void SetFizzleFadeSteps()
	{
		int x, y;

		int fizzleval = 1;

		do
		{
			y = fizzleval & 0x000FF;		// Y = low 8 bits
			x = (fizzleval & 0x1FF00) >> 8;		// X = High 9 bits

			uint lsb = fizzleval & 1;		// Get the output bit.
			fizzleval >>= 1;			// Shift register

			if (lsb)				// If the output is 0, the xor can be skipped.
			{
				fizzleval ^= 0x00012000;
			}

			if (x < 320 && y < 200)
			{
				fizzlepoints[fizzleindex] = (x, y);
				fizzleindex++;
			}
		} while (fizzleval != 1)

		fizzleindex = 0;
	}

	virtual void DrawSaveIcon()
	{
		if (savetimer)
		{
			TextureID save = TexMan.CheckForTexture("I_DISK0", TexMan.Type_Any);

			if (save)
			{
				double savealpha = 1.0;

				if (savetimer > (savetimertime - 5)) { savealpha = (savetimertime - savetimer) / 5.0; }
				else if (savetimer <= 5) { savealpha = savetimer / 5.0; }

				int width = int(400 * Screen.GetAspectRatio());
				screen.DrawTexture(save, true, width - 20, 20, DTA_CenterOffset, true, DTA_KeepRatio, true, DTA_VirtualWidth, width, DTA_VirtualHeight, 400, DTA_Alpha, savealpha);
			}
		}
	}

	// Original code from shared_sbar.cpp
	override void DrawAutomapHUD(double ticFrac)
	{
		int crdefault = Font.CR_GRAY;
		int highlight = Font.FindFontColor("WolfMenuYellowBright");

		let scale = GetUIScale(hud_scale);
		let titlefont = Font.FindFont("BigFont");
		let font = generic_ui ? NewSmallFont : SmallFont;
		let font2 = font;
		let vwidth = screen.GetWidth() / scale;
		let vheight = screen.GetHeight() / scale;
		let fheight = font.GetHeight();
		String textbuffer;
		int sec;
		int textdist = 4;
		int zerowidth = font.GetCharWidth("0");

		int y = textdist;

		// Don't prepend the map name...  Just use the level's title.
		textbuffer = level.LevelName;
		if (idmypos) { textbuffer = textbuffer .. " (" .. level.mapname.MakeUpper() .. ")"; }

		if (!generic_ui)
		{
			if (!font.CanPrint(textbuffer)) font = OriginalSmallFont;
		}

		let lines = font.BreakLines(textbuffer, vwidth - 32);
		let numlines = lines.Count();
		let finalwidth = lines.StringWidth(numlines - 1);

		// Draw the text
		for (int i = 0; i < numlines; i++)
		{
			screen.DrawText(titlefont, highlight, textdist, y, lines.StringAt(i), DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);
			y += titlefont.GetHeight();
		}

		y+= int(fheight / 2);

		String time;

		if (am_showtime) { time = level.TimeFormatted(); }

		if (am_showtotaltime)
		{
			if (am_showtime) { time = time .. " / " .. level.TimeFormatted(true); }
			else { time = level.TimeFormatted(true); }
		}

		if (am_showtime || am_showtotaltime)
		{
			screen.DrawText(font, crdefault, textdist, y, time, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight, DTA_Monospace, 2, DTA_Spacing, zerowidth, DTA_KeepRatio, true);
			y += int(fheight * 3 / 2);
		}

		String monsters = StringTable.Localize("AM_MONSTERS", false);
		String secrets = StringTable.Localize("AM_SECRETS", false);
		String items = StringTable.Localize("AM_ITEMS", false);

		double labelwidth = 0;

		for (int i = 0; i < 3; i++)
		{
			String label;
			int size;

			Switch (i)
			{
				case 0:
					label = monsters;
					break;
				case 1:
					label = secrets;
					break;
				case 2:
					label = items;
					break;
			}

			size = font2.StringWidth(label .. "   ");

			if (size > labelwidth) { labelwidth = size; }
		}

		if (!generic_ui)
		{
			// If the original font does not have accents this will strip them - but a fallback to the VGA font is not desirable here for such cases.
			if (!font.CanPrint(monsters) || !font.CanPrint(secrets) || !font.CanPrint(items)) { font2 = OriginalSmallFont; }
		}

		if (!deathmatch)
		{
			if (am_showmonsters && level.total_monsters > 0)
			{
				screen.DrawText(font2, crdefault, textdist, y, monsters, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				textbuffer = textbuffer.Format("%d/%d", level.killed_monsters, level.total_monsters);
				screen.DrawText(font2, Font.CR_RED, textdist + labelwidth, y, textbuffer, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				y += fheight;
			}

			if (am_showsecrets && level.total_secrets > 0)
			{
				screen.DrawText(font2, crdefault, textdist, y, secrets, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				textbuffer = textbuffer.Format("%d/%d", level.found_secrets, level.total_secrets);
				screen.DrawText(font2, Font.CR_SAPPHIRE, textdist + labelwidth, y, textbuffer, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				y += fheight;
			}

			// Draw item count
			if (am_showitems && level.total_items > 0)
			{
				screen.DrawText(font2, crdefault, textdist, y, items, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				textbuffer = textbuffer.Format("%d/%d", level.found_items, level.total_items);
				screen.DrawText(font2, Font.CR_GOLD, textdist + labelwidth, y, textbuffer, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				y += fheight;
			}
		}
	}

	override bool DrawPaused(int player)
	{
		TextureID pause = TexMan.CheckForTexture("W_PAUSE"); // gameinfo.PauseSign is not exposed to ZScript
		Vector2 size = TexMan.GetScaledSize(pause);

		double x = Screen.GetWidth() / 2;
		double y = Screen.GetHeight() / 2;

		Screen.DrawTexture(pause, true, x, y, DTA_CleanNoMove, true, DTA_CenterOffset, true);

		if (paused && multiplayer)
		{
			String pstring = StringTable.Localize("$TXT_PAUSEDBY");
			pstring.Substitute("%s", players[paused - 1].GetUserName());
			Screen.DrawText(SmallFont, Font.CR_WHITE, x - SmallFont.StringWidth(pstring) * CleanXfac_1 / 2, y + size.y * CleanYfac_1, pstring, DTA_CleanNoMove_1, true);
		}

		return true;
	}

	override bool ProcessNotify(EPrintLevel printlevel, String outline)
	{
		bool processed = false;

		if (gameaction == ga_savegame || gameaction == ga_autosave)
		{
			// Don't print save messages
			savetimer = savetimertime;
			processed = true;
		}

		CVar logstyle = CVar.FindCVar("g_defaultlog");
		if (logstyle && logstyle.GetInt()) { return false; }

		Font fnt = SmallFont;

		if (!processed && printlevel & PRINT_TYPES <= PRINT_TEAMCHAT)
		{
			if (printlevel <= PRINT_HIGH) { Log.Add(CPlayer, outline, "Notifications", printlevel, fnt); }
			else { Log.Add(CPlayer, outline, "Chat", printlevel, fnt, "WolfMenuYellowBright"); }

			processed = true; 
		}

		return processed;
	}

	override bool ProcessMidPrint(Font fnt, String msg, bool bold)
	{
		Log.Add(CPlayer, msg .. "\r", "MidPrint", PRINT_BOLD, fnt, "White");

		return true;
	}

	override void FlushNotify()
	{
		Log.Clear("Notifications");
	}

	override bool DrawChat(String txt)
	{
		Font fnt = SmallFont;

		return Log.DrawPrompt(txt .. " ", "Chat", fnt);
	}
}

class JaguarHUD : AltHUD
{
	override void Init()
	{
		Super.Init();

		HudFont = Font.FindFont("JAGFONT");
		if (HudFont == NULL) { HudFont = SmallFont; }
	}

	override void DrawHealth(PlayerInfo CPlayer, int x, int y)
	{
		int health = CPlayer.health;

		DrawImageToBox(StatusBar.GetMugShot(7, MugShot.ANIMATEDGODMODE | MugShot.DISABLERAMPAGE | MugShot.DISABLEOUCH | MugShot.CUSTOM, "WLJ"), x, y - 9, 32, 32, 1.0);
		DrawHudNumber(HudFont, -1, health, x + 84 - HudFont.StringWidth(String.Format("%i", health)), y + 17);
	}

	override int DrawAmmo(PlayerInfo CPlayer, int x, int y)
	{
		//Ammo
		Ammo ammo1, ammo2;
		int ammocount = 0, ammocount1, ammocount2;
		[ammo1, ammo2, ammocount1, ammocount2] = ClassicStatusBar(StatusBar).GetWeaponAmmo();

		TextureID ammoicon;
		if (ammo2) { ammocount += ammocount2; ammoicon = ammo2.AltHudIcon; }
		if (ammo1) { ammocount += ammocount1; ammoicon = ammo1.AltHudIcon; }

		DrawHUDNumber(HudFont, -1, ammocount, x - HudFont.StringWidth(String.Format("%i", ammocount)), y + HudFont.GetHeight(), 1.0);
		if (ammoicon) { DrawImageToBox(ammoicon, x, y - 9, 32, 32, 1.0); }

		return 0;
	}

	override void DrawInGame(PlayerInfo CPlayer)
	{
		if (gamestate == GS_TITLELEVEL || !CPlayer) return;

		DrawHealth(CPlayer, 6, hudheight - 32);
		DrawAmmo(CPlayer, hudwidth - 42, hudheight - 32);

		int c = 0;

		Inventory bkey = CPlayer.mo.FindInventory("BlueKey");
		if (!bkey) { bkey = CPlayer.mo.FindInventory("BlueKeyLost"); }
		if (bkey)
		{
			DrawImageToBox(bkey.AltHudIcon, 86, hudheight - 39, 24, 24, 1.0);
		}

		Inventory ykey = CPlayer.mo.FindInventory("YellowKey");
		if (!ykey) { ykey = CPlayer.mo.FindInventory("YellowKeyLost"); }
		if (ykey)
		{
			DrawImageToBox(ykey.AltHudIcon, hudwidth - 108, hudheight - 39, 24, 24, 1.0);
		}
	}

	override void DrawAutomap(PlayerInfo CPlayer)
	{
		return;
	}
}