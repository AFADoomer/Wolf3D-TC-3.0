class ClassicStatusBar : BaseStatusBar
{
	HUDFont ClassicFont, BigFont;
	TextureID mugshot;

	int mugshottimer;

	TextureID pixel;
	int fizzleindex;
	Vector2 fizzlepoints[64000];

	bool fizzleeffect;
	Color fizzlecolor;

	play int staticmugshot;
	play int staticmugshottimer;

	override void Init()
	{
		Super.Init();
		SetSize(42, 320, 200);
		CompleteBorder = False;

		ClassicFont = HUDFont.Create("WOLFNUM", 0);
		BigFont = HUDFont.Create("BIGFONT", 0);

		pixel = TexMan.CheckForTexture("Floor", TexMan.Type_Any);

		fizzleindex = 0;
		SetFizzleFadeSteps();

		fizzleeffect = false;
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);

		if (pixel && fizzleeffect)
		{
			for (int f = 0; f <= fizzleindex; f++)
			{
				Vector2 fizzle = fizzlepoints[f];

				screen.DrawTexture(pixel, false, fizzle.x, fizzle.y, DTA_320x200, true, DTA_DestWidth, 1, DTA_DestHeight, 1, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_FillColor, fizzlecolor);
				screen.DrawTexture(pixel, false, fizzle.x > 160 ? fizzle.x - 320 : fizzle.x + 320, fizzle.y, DTA_320x200, true, DTA_DestWidth, 1, DTA_DestHeight, 1, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_FillColor, fizzlecolor);
			}

			fizzleindex += 1920; // Draw a chunk of pixels at a time...

			if (fizzleindex >= fizzlepoints.Size()) { fizzleindex = fizzlepoints.Size() - 1; }
		}

		if (state == HUD_StatusBar)
		{
			BeginStatusBar(screenblocks < 11);
			DrawClassicBar();
		}
		else if (state == HUD_Fullscreen)
		{
			DrawHUD();
		}
	}

	static void DoFizzle(Actor caller, color clr = 0xFF0000, bool Off = false)
	{
		if (ClassicStatusBar(StatusBar).CPlayer.mo != caller) { return; }

		ClassicStatusBar(StatusBar).fizzleeffect = !Off;
		ClassicStatusBar(StatusBar).fizzlecolor = clr;
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

	protected void DrawClassicBar()
	{
		Vector2 window, windowsize, screensize, viewportsize, viewport;

		screensize = (Screen.GetWidth(), Screen.GetHeight());

		int blocks = automapactive ? 10 : clamp(screenblocks, 3, 10);

		double yoffset = (200 - RelTop);

		CVar borderstylevar = CVar.GetCVar("g_borderstyle", CPlayer);
		int borderstyle = borderstylevar ? borderstylevar.GetInt() : 0;

		if (borderstyle > 0)
		{
			double width = 200 * screensize.x / screensize.y;
			viewportsize.x = (blocks * (width - 16)) / 8.35;
		}
		else
		{
			viewportsize.x = (blocks * (320 - 16)) / 10;
		}

		viewportsize.y = (blocks * yoffset) / 10 - 2;

		viewport.x = (320 - viewportsize.x) / 2;
		viewport.y = (yoffset - viewportsize.y) / 2;

		[window, windowsize] = DrawToHud.TranslatetoHUDCoordinates(viewport, viewportsize, checkfullscreen:true);

		if (screenblocks < 11 && !automapactive && (borderstyle != 2 || screenblocks < 10))
		{
			// Fill outside of boundaries with green
			Screen.Dim(0x004040, 1.0, 0, 0, int(window.x - 1), int(screensize.y));
			Screen.Dim(0x004040, 1.0, int(window.x + windowsize.x), 0, int(screensize.x - window.x - windowsize.x), int(screensize.y));
			Screen.Dim(0x004040, 1.0, int(window.x - 1), 0, int(windowsize.x + 2), int(window.y));
			Screen.Dim(0x004040, 1.0, int(window.x - 1), int(window.y + windowsize.y), int(windowsize.x + 2), int(screensize.y - window.y - windowsize.y));

			// Draw border
			DrawImage("WBRD_T", (viewport.x, viewport.y - 1), DI_ITEM_LEFT_TOP, scale:(viewportsize.x / 8, 1.0));
			DrawImage("WBRD_B", (viewport.x, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP, scale:(viewportsize.x / 8, 1.0));
			DrawImage("WBRD_L", (viewport.x - 3, viewport.y), DI_ITEM_LEFT_TOP, scale:(1.0, viewportsize.y / 8));
			DrawImage("WBRD_R", (viewport.x + viewportsize.x, viewport.y), DI_ITEM_LEFT_TOP, scale:(1.0, viewportsize.y / 8));

			DrawImage("WBRD_TL", (viewport.x - 3, viewport.y - 1), DI_ITEM_LEFT_TOP);
			DrawImage("WBRD_TR", (viewport.x + viewportsize.x, viewport.y - 1), DI_ITEM_LEFT_TOP);
			DrawImage("WBRD_BL", (viewport.x - 3, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP);
			DrawImage("WBRD_BR", (viewport.x + viewportsize.x, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP);
		}
		else if (automapactive || (screenblocks == 10 && borderstyle == 2))
		{
			Vector2 coords, size;
			[coords, size] = DrawToHud.TranslatetoHUDCoordinates((0, 200 - RelTop), (320, RelTop), checkfullscreen:true);

			Screen.Dim(0x004040, 1.0, 0, int(coords.y), int(screensize.x), int(size.y));
			DrawImage("WBRD_B", (160, 200 - RelTop), DI_ITEM_TOP | DI_ITEM_HCENTER, scale:(windowsize.x / 4, 1.0));
		}

		DrawImage("BAR", (160, 198), DI_SCREEN_CENTER_BOTTOM);

		//Lives
		DrawString(ClassicFont, FormatNumber(max(LifeHandler.GetLives(CPlayer.mo), 0)), (116, 176), DI_TEXT_ALIGN_CENTER | DI_SCREEN_CENTER_BOTTOM);

		//Level
		String levelnum = String.Format("%i", level.levelnum % 100);

		if (levelnum == "0") { levelnum = "10"; }
		DrawString(ClassicFont, (Game.IsSoD() && levelnum == "21" ? "18" : levelnum), (32, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);

		//Score
		DrawString(ClassicFont, FormatNumber(GetAmount("Score") % 1000000), (95, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);

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
	
			if (icontex)
			{
				Vector2 size = TexMan.GetScaledSize(icontex);
				Vector2 scalexy = (1.0, 1.0);

				if (size.x > 48) { scalexy.x = 48. / size.x; }
				if (size.y > 24) { scalexy.y = 24. / size.y; }

				scale = min(scalexy.x, scalexy.y);

				DrawToHUD.DrawTexture(icontex, (280, 179), 1.0, scale, weapon is "ClassicWeapon" ? -1 : 0x000000, DrawToHUD.center, DrawToHUD.bottom, true);
			}
		}

		//Ammo
		Ammo ammo1, ammo2;
		int ammocount = 0, ammocount1, ammocount2;
		[ammo1, ammo2, ammocount1, ammocount2] = GetClassicDisplayAmmo();
		if (ammo2) { ammocount += ammocount2; }
		if (ammo1) { ammocount += ammocount1; } 
		DrawString(ClassicFont, FormatNumber(ammocount), (231, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);
	}

	void DrawMugShot(int x, int y, int size = 32)
	{
		if (staticmugshot && staticmugshottimer >= gametic)
		{
			mugshot = GetMugShot(5, type:staticmugshot);
		}
		else if (!mugshot || mugshottimer > Random[mugshot](0, 255))
		{
			mugshot = GetMugShot(5);
			mugshottimer = 0;
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
			int level = 0;

			int maxhealth = CPlayer.mo.mugshotmaxhealth > 0 ? CPlayer.mo.mugshotmaxhealth : CPlayer.mo.maxhealth;
			if (maxhealth <= 0) { maxhealth = 100; }

			while (CPlayer.health < (accuracy - 1 - level) * (maxhealth / accuracy)) { level++; }

			int index = Random[mugshot](0, 255) >> 6;
			if (index == 3) { index = 1; }

			switch (type)
			{
				default:
					mugshot = face .. "ST" .. level .. index;
					break;
				case 1: // Grin
					mugshot = face .. "EVL";
					break;
				case 2: // Idle
					mugshot = face .. "STT" .. Random(1, 2);
					break;
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

	protected void DrawHUD()
	{
		fullscreenOffsets = true;

		int baseline = -14;

		//Score
		DrawString(BigFont, FormatNumber(GetAmount("Score")), (-2, baseline - 16), DI_TEXT_ALIGN_RIGHT, Font.FindFontColor("TrueWhite"));

		//Lives
		TextureID life = TexMan.CheckForTexture("LIFEA0", TexMan.Type_Any);
		if (life) { DrawTexture(life, (19, -26), DI_ITEM_CENTER); }
		DrawString(BigFont, FormatNumber(max(LifeHandler.GetLives(CPlayer.mo), 0)), (35, baseline), 0, Font.FindFontColor("TrueWhite"));

		//Keys
		if (GetAmount("YellowKey") || GetAmount("YellowKeyLost")) { DrawImage("I_YKEY", (-8, 0), DI_ITEM_LEFT_TOP); }
		if (GetAmount("BlueKey") || GetAmount("BlueKeyLost")) { DrawImage("I_BKEY", (-8, 14), DI_ITEM_LEFT_TOP); }

		//Ammo
		Ammo ammo1, ammo2;
		int ammocount = 0, ammocount1, ammocount2;
		[ammo1, ammo2, ammocount1, ammocount2] = GetClassicDisplayAmmo();

		TextureID ammoicon;
		if (ammo2) { ammocount += ammocount2; ammoicon = ammo2.Icon; }
		if (ammo1) { ammocount += ammocount1; ammoicon = ammo1.Icon; }

		if (ammoicon) { DrawTexture(ammoicon, (-110, -1), DI_ITEM_CENTER_BOTTOM ); }
		DrawString(BigFont, FormatNumber(ammocount), (-95, baseline), 0, Font.FindFontColor("TrueWhite"));

		//Health
		TextureID health = TexMan.CheckForTexture("HLTHE0", TexMan.Type_Any);
		if (health) { DrawTexture(health, (-50, -1), DI_ITEM_CENTER_BOTTOM); }
		DrawString(BigFont, FormatNumber(CPlayer.health), (-2, baseline), DI_TEXT_ALIGN_RIGHT, Font.FindFontColor("TrueWhite"));
	}

	Ammo, Ammo, int, int GetClassicDisplayAmmo()
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
			ammo2 = Ammo(CPlayer.mo.FindInventory("WolfClip"));
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
}