class HelpMenu : ReadThisMenu
{
	TextureID border;
	Vector2 dimcoords, dimsize;
	Array<String> pages;
	int margins[15][2];
	int currentline;
	int fontheight;
	bool sharewareremap;
	bool allowexit;
	bool allowinput;

	override void Init(Menu parent)
	{
		InitCommon(parent);

		sharewareremap = true;
		allowexit = true;
		ParseFile("data/help.txt");

		if (gamestate != GS_FINALE)
		{
			S_ChangeMusic("CORNER");
		}
	}

	void InitCommon(Menu parent)
	{
		GenericMenu.Init(parent);
		mScreen = 1;
		mInfoTic = gametic;
		border = TexMan.CheckForTexture("BORDER", TexMan.Type_Any);

		[dimcoords, dimsize] = screen.VirtualToRealCoords((0, 0), (320, 200), (320, 200));

		fontheight = 10;
		allowinput = true;
	}

	override void Drawer()
	{
		screen.Dim(0, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());
		screen.Dim(0xDCDCDC, 1.0, int(dimcoords.x), int(dimcoords.y), int(dimsize.x), int(dimsize.y));

		if (mScreen < pages.Size()) { DrawText(pages[mScreen]); }

		if (border) { screen.DrawTexture(border, false, 0, 0, DTA_320x200, true); }

		screen.DrawText(SmallFont, Font.FindFontColor("WolfDarkGold"), 213, 183, "pg " .. mScreen .. " of " .. pages.Size() - 1, DTA_320x200, true);
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Back)
		{
			if (allowexit)
			{
				Close();
			}
			else
			{
				if (gamestate == GS_FINALE || gamestate == GS_CUTSCENE) { Menu.SetMenu("HighScores", -1); }
				else { Menu.SetMenu("MainMenu", -1); }
			}

			if (gamestate != GS_FINALE && gamestate != GS_CUTSCENE)
			{
				if (!mParentMenu) { S_ChangeMusic(level.music); }
				else { S_ChangeMusic("WONDERIN"); }
			}

			MenuSound (GetCurrentMenu() != null? "menu/backup" : "menu/clear");
			return true;
		}

		if (!allowinput) { return false; }

		if (mkey == MKEY_Enter || mkey == MKEY_Right)
		{
			mScreen = min(pages.Size() - 1, mScreen + 1);
			mInfoTic = gametic;

			return true;
		}
		else if (mkey == MKEY_Left)
		{
			mScreen = max(1, mScreen - 1);
			mInfoTic = gametic;

			return true;
		}
		else return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (type == MOUSE_Click)
		{
			return MenuEvent(MKEY_Enter, true);
		}

		return Super.MouseEvent(type, x, y);
	}

	ui void ParseFile(String filename)
	{
		String data = ReadLump(filename);
		data.Split(pages, "^P");
	}

	ui String ReadLump(String lumpname)
	{
		int lump = -1;

		lump = Wads.CheckNumForFullName(lumpname);

		if (lump > -1) { return Wads.ReadLump(lump); }

		return "";
	}

	void DrawText(String input)
	{
		Array<String> lines;
		input.Split(lines, "\n");

		currentline = 0;

		for (int i = 0; i < margins.Size(); i++)
		{
			margins[i][0] = 16;
			margins[i][1] = 16;
		}

		// Intentionally skip the first line, which is either blank or a page number
		for (int l = 1; l < lines.Size(); l++)
		{
			currentline += ParseLine(lines[l]);
		}
	}

	int ParseLine(String input)
	{
		String word = "";
		int linecount = 0;
		int lastbreak = 0;
		String clr = "\c[Palette00]";
		int lineindex = currentline;

		if (lineindex > margins.Size() - 1) { return linecount; }

		int currentx = margins[lineindex][0];
		int currenty = 16 + lineindex * fontheight;

		for (int i = 0; i < input.Length(); i++)
		{
			switch(input.ByteAt(i))
			{
				// Handle control characters
				case 0x5E: // ^
					i++;
					switch(input.ByteAt(i))
					{
						// Change the text color
						case 0x43: // C
						case 0x63: // c
							clr = "\c[Palette" .. input.Mid(i + 1, 2) .. "]";
							i += 2;
							break;
						// Insert a graphic...  Looks for graphic number x as "SLIDEGx", then fails back to "WVGA000x"
						case 0x47: // G
						case 0x67: // g
							Array<String> graphicinfo;
							input.Mid(i + 1).Split(graphicinfo, ",");

							for (int g = 0; g < graphicinfo.Size(); g++)
							{
								int x = graphicinfo[1].ToInt();
								int y = graphicinfo[0].ToInt();
								int g = graphicinfo[2].ToInt();

								TextureID tex;
								if (sharewareremap) { tex = TexMan.CheckForTexture(String.Format("SLIDEG%i", g), TexMan.Type_Any); }
								if (!sharewareremap || !tex.IsValid()) { tex = TexMan.CheckForTexture(String.Format("WVGA%04i", g), TexMan.Type_Any); }

								if (tex)
								{
									screen.DrawTexture(tex, false, x, y, DTA_320x200, true);

									Vector2 size = TexMan.GetScaledSize(tex);

									int adjustleft = 0;
									int adjustright = 0;

									if (x + size.x / 2 > 160) { adjustright = (320 - x) + 8; }
									else { adjustleft = x + int(size.x) + 8; }

									int top = clamp((y - 16) / fontheight, 0, margins.Size() - 1);
									int bottom = clamp((y + int(size.y) - 16) / FONTHEIGHT, 0, margins.Size() - 1);

									for (int i = top; i <= bottom; i++)
									{
										if (adjustleft) { margins[i][0] = adjustleft; }
										if (adjustright) { margins[i][1] = adjustright; }
									}
								}
							}
							return 0;
						// Marks end of file.  Not used in this implementation
						case 0x45: // E
						case 0x65: // e
						default:
							break;
					}
					break;
				// Handle tabs and spaces
				case 0x09: // Tab
				case 0x20: // Space
					PrintText(clr .. word, currentx, currenty); // Print the word, then check to see if a line break is needed...
					currentx += SmallFont.StringWidth(word);
					word = "";

					if (input.ByteAt(i) == 0x09) { currentx = (currentx + 8) & 0xf8; }
					else if (input.ByteAt(i) == 0x20) { currentx += 7; }

					int nextspace = input.IndexOf(" ", i + 1); // Find the next space
					if (nextspace < 0) { nextspace = input.Length() - 1; }

					String teststring = input.mid(i + 1, nextspace - (i + 1));

					if (teststring.ByteAt(0) == 0x5E) { teststring = teststring.Mid(4); } // Skip color codes that are in lines when calculating length

					int testlength = SmallFont.StringWidth(teststring);

					if (testlength > 320 - margins[lineindex][1] - currentx)
					{
						lastbreak = i;
						linecount++;
						lineindex = currentline + linecount;
						if (lineindex > margins.Size() - 1) { return linecount; }
						currentx = margins[lineindex][0];
						currenty = 16 + lineindex * fontheight;
					}
					break;
				// Build the current word one character at  time
				default:
					if (input.Mid(i, 1))
					{
						word = word .. input.Mid(i, 1);
					}
					else { lastbreak = i; }
					break;
			}
		}

		PrintText(clr .. word, currentx, currenty); // Print the last word that wasn't caught in the loop...

		return linecount + 1;
	}

	void PrintText(String text, int x, int y)
	{
		screen.DrawText(SmallFont, Font.FindFontColor("TrueBlack"), x, y, text, DTA_320x200, true);
	}
}

class Episode0End : HelpMenu
{
	override void Init(Menu parent)
	{
		InitCommon(parent);

		ParseFile("data/episode0.txt");
	}
}

class Episode1End : HelpMenu
{
	override void Init(Menu parent)
	{
		InitCommon(parent);

		ParseFile("data/episode1.txt");
	}
}

class Episode2End : HelpMenu
{
	override void Init(Menu parent)
	{
		InitCommon(parent);

		ParseFile("data/episode2.txt");
	}
}

class Episode3End : HelpMenu
{
	override void Init(Menu parent)
	{
		InitCommon(parent);

		ParseFile("data/episode3.txt");
	}
}

class Episode4End : HelpMenu
{
	override void Init(Menu parent)
	{
		InitCommon(parent);

		ParseFile("data/episode4.txt");
	}
}

class Episode5End : HelpMenu
{
	override void Init(Menu parent)
	{
		InitCommon(parent);

		ParseFile("data/episode5.txt");
	}
}

class Episode6End : HelpMenu
{
	override void Init(Menu parent)
	{
		InitCommon(parent);

		ParseFile("data/episode6.txt");
	}
}

class SoDEnd : HelpMenu
{
	TextureID page, nextpage;

	int tickcount;
	int inputtic;
	int fadetarget;
	int fadetime;
	double fadealpha;
	int advancetime;
	color fadecolor;
	bool initial;

	static const String SoDPages[] = {"SODEND1", "SODEND2", "SODEND3", "SODEND4", "SODEND5", "SODEND6", "SODEND6", "SODEND7", "SODEND8", "SODEND9", "SODEND10", "SODEND11", "SODEND12", "SODEND13" };

	override void Init(Menu parent)
	{
		InitCommon(parent);

		mScreen = -1;

		allowinput = false;

		fadetime = 12;
		fadetarget = 0;
		advancetime = 0;
		initial = true;

		DontDim = true;
		allowexit = false;

		fadecolor = 0x004040;

		for (int p = 0; p < SoDPages.Size(); p++)
		{
			pages.Push(SodPages[p]);
		}
	}

	override void Drawer()
	{
		if (mScreen > -1 || tickcount > 150)
		{
			screen.Dim(0x004040, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

			if (page.isValid()) { screen.DrawTexture(page, false, 160, 100, DTA_CenterOffset, true, DTA_320x200, true); }

			if (page == nextpage)
			{
				switch (mScreen)
				{
					case 5:
						BrokenLines lines = SmallFont.BreakLines(StringTable.Localize("$SODEND1"), 320);
						for (int l = 0; l < lines.Count(); l++)
						{
							screen.DrawText(SmallFont, Font.FindFontColor("TrueWhite"), 160 - lines.StringWidth(l) / 2, 180 + SmallFont.GetHeight() * l, lines.StringAt(l), DTA_320x200, true);
						}
						break;
					case 6:
						BrokenLines lines2 = SmallFont.BreakLines(StringTable.Localize("$SODEND2"), 320);
						for (int l = 0; l < lines2.Count(); l++)
						{
							screen.DrawText(SmallFont, Font.FindFontColor("TrueWhite"), 160 - lines2.StringWidth(l) / 2, 180 + SmallFont.GetHeight() * l, lines2.StringAt(l), DTA_320x200, true);
						}
						break;
					default:
						break;
				}
			}
		}

		screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		tickcount++;

		if (mScreen == -1 && tickcount <= 150)
		{
			S_ChangeMusic("");
			fadealpha = tickcount / 150.0;
			advancetime = gametic;

			return;
		}

		if (advancetime > 0 && advancetime <= gametic)
		{
			inputtic = gametic;
			mScreen = clamp(mScreen + 1, 0, pages.Size());
			advancetime = 0;
		}

		if (mScreen == 4 && !initial)
		{
			Level.ExitLevel(0, false);
			Close();
			return;
		}

		if (inputtic == gametic)
		{
			nextpage = TexMan.CheckForTexture(pages[mScreen]);

			switch (mScreen)
			{
				case 0:
					initial = false;
					fadetarget = gametic + fadetime;
					S_ChangeMusic("XTHEEND");
					advancetime = gametic + 35 * 2;
					break;
				case 1:
				case 2:
					S_ChangeMusic("XTHEEND");
					page = nextpage;
					advancetime = gametic + 52;
					break;
				case 3:
					S_ChangeMusic("XTHEEND");
					page = nextpage;
					advancetime = gametic + 35 * 3;
					break;
				case 4:
					S_ChangeMusic("URAHERO");
					fadecolor = 0x00000;
					fadetarget = gametic + fadetime;
					allowinput = true;
					break;
				case 5:
					S_ChangeMusic("URAHERO");
					fadetarget = gametic + fadetime;
					advancetime = gametic + 35 * 10;
					break;
				case 6:
					S_ChangeMusic("URAHERO");
					advancetime = gametic + 35 * 10;
					break;
				case 7:
				case 8:
				case 9:
				case 10:
				case 11:
				case 12:
				case 13:
				case 14:
					S_ChangeMusic("URAHERO");
					if (page != nextpage) { fadetarget = gametic + fadetime; }
					advancetime = 0;
				default:
					break;
			}
		}

		fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		if (fadealpha == 1.0) { page = nextpage; }
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Back)
		{
			if (allowexit)
			{
				Close();
			}
			else
			{
				Menu.SetMenu("HighScores", -1);
			}

			MenuSound (GetCurrentMenu() != null? "menu/backup" : "menu/clear");
			return true;
		}

		if (!allowinput) { return false; }

		if (mkey)
		{
			mScreen = min(pages.Size() - 1, mScreen + 1);
			mInfoTic = gametic;
			inputtic = gametic;

			return true;
		}

		return false;
	}
}

class SoDFinale : SodEnd
{
	override void Init(Menu parent)
	{
		Super.Init(parent);
		mScreen = 3;
		advancetime = gametic;
	}
}

class IntroSlideshow : WolfMenu
{
	int curscreen;
	int inputtic;

	int fadetarget;
	int fadetime;
	double fadealpha;
	int sodversion;

	int advancetime;

	TextureID startup, startup2, warning, title, credits, current, prev, next, selected;

	Vector2 dimcoords, dimsize;

	override void Init(Menu parent)
	{
		S_ChangeMusic("");

		GenericMenu.Init(parent);

		curscreen = -1;
		fadetime = 12;
		fadetarget = 0;
		advancetime = 15;

		sodversion = -1;
		SetGraphics();

		[dimcoords, dimsize] = screen.VirtualToRealCoords((0, 0), (320, 200), (320, 200));
	}

	virtual void SetGraphics()
	{
		if (sodversion == Game.IsSoD()) { return; }

		startup = TexMan.CheckForTexture((Game.IsSoD() ? GameHandler.GameFilePresent("SOD", false) ? "SSTARTUP" : "SDSTARTU" : "STARTUP"), TexMan.Type_Any);
		startup2 = TexMan.CheckForTexture((Game.IsSoD() ? GameHandler.GameFilePresent("SOD", false) ? "SSTARTU2" : "SDSTART2" : "STARTUP2"), TexMan.Type_Any);
		warning = TexMan.CheckForTexture("WARNING", TexMan.Type_Any);
		title = TexMan.CheckForTexture((Game.IsSoD() ? GameHandler.GameFilePresent("SOD", false) ? "STITLEPI" : "SDTITLEP" : "TITLEPIC"), TexMan.Type_Any);
		credits = TexMan.CheckForTexture((Game.IsSoD() ? "SCREDIT" : "CREDIT"), TexMan.Type_Any);
		selected = TexMan.CheckForTexture("STARTSEL", TexMan.Type_Any);

		sodversion = !!(g_sod > 0);
	}

	override void Drawer()
	{
		SetGraphics();

		screen.Dim(0x000000, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

		if (current == startup2)
		{
			screen.DrawTexture(current, false, 0, 0, DTA_320x200, true);

			if (!Game.IsSoD())
			{
				screen.Dim(0x880000, 1.0, screen.GetWidth() / 2 - 60 * CleanXfac, Screen.GetHeight() - 11 * CleanYfac, 120 * CleanXfac, 11 * CleanYfac);

				// if (curscreen == 1)
				// {
				// 	String press = "One moment...";
				// 	int w = SmallFont.StringWidth(press);
				// 	screen.DrawText(SmallFont, Font.FindFontColor("TrueBlack"), 160 - w / 2, 190, press, DTA_320x200, true);
				// }
				if (curscreen == 2)
				{
					String press = "Press a key";
					int w = SmallFont.StringWidth(press);
					screen.DrawText(SmallFont, Font.FindFontColor("WolfStartupYellow"), 160 - w / 2, 190, press, DTA_320x200, true);
				}
				else
				{
					String press = "Working...";
					int w = SmallFont.StringWidth(press);
					screen.DrawText(SmallFont, Font.FindFontColor("WolfStartupGreen"), 160 - w / 2, 190, press, DTA_320x200, true);
				}
			}

			if (use_mouse) { screen.DrawTexture(selected, false, 164, 82, DTA_320x200, true); }
			if (use_joystick) { screen.DrawTexture(selected, false, 164, 106, DTA_320x200, true); }
		}
		else if (current == warning)
		{
			screen.Dim(0x20A8FC, 1.0, 0, 0, Screen.GetWidth(), Screen.GetHeight());

			screen.DrawTexture(current, false, 216, 110, DTA_320x200, true);
		}
		else if (current)
		{
			screen.DrawTexture(current, false, 0, 0, DTA_320x200, true);
		}

		screen.Dim(0x000000, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		if (advancetime > 0 && advancetime <= gametic)
		{
			inputtic = gametic;
			curscreen++;
			advancetime = 0;
		}

		if (inputtic == gametic)
		{
			switch (curscreen)
			{
				case 0: // Blank black screen
					advancetime = gametic + 20;
					break;
				case 1: // Initial load screen
					current = startup;
					advancetime = gametic + 20;
					break;
				case 2: // Press a key
					current = startup2;
					advancetime = (Game.IsSoD() ? gametic + 35 * 2 : 0);
					break;
				case 3: // Working...
					advancetime = 5;
					break;
				case 4: // Start demo loop
					S_ChangeMusic(Game.IsSoD() ? "XTOWER2" : "NAZI_NOR");
					next = warning;
					fadetarget = gametic + fadetime;
					advancetime = gametic + 35 * 7;
					break;
				case 5: // Title picture
					next = title;
					fadetarget = gametic + fadetime;
					advancetime = gametic + 35 * 15;
					break;
				case 6: // Credits
					next = credits;
					fadetarget = gametic + fadetime;
					advancetime = gametic + 35 * 10;
					break;
				default: // Swap between title and credits after the initial run-through
					fadetarget = gametic + fadetime;
					if (current == title)
					{
						next = credits;
						advancetime = gametic + 35 * 10;
					}
					else
					{
						next = title;
						advancetime = gametic + 35 * 15;
					}
					break;
			}
		}

		if (gametic > 35)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}

		if (fadetarget == gametic)
		{
			prev = current;
			current = next;
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey && fadetarget < gametic)
		{
			inputtic = gametic;
			curscreen++;

			if (curscreen > 5) { Menu.SetMenu("MainMenu", -1); }

			return true;
		}
	
		return false;
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (type == MOUSE_Click)
		{
			return MenuEvent(MKEY_Enter, true);
		}

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.type == UIEvent.Type_KeyDown)
		{
			if (CheckControl(self, ev, "toggleconsole"))
			{
				
				return true;
			}
			
			return MenuEvent(MKEY_Enter, true);
		}
		else if (ev.type > UIEvent.Type_FirstMouseEvent)
		{
			Super.OnUIEvent(ev);
		}

		return false;
	}
}

class IntroSlideShowLoop : IntroSlideShow
{
	override void Init(Menu parent)
	{
		Super.Init(parent);

		curscreen = 6;
		current = title;
		advancetime = gametic + 35 * 10;

		S_ChangeMusic(Game.IsSoD() ? "XTOWER2" : "NAZI_NOR");
	}
}

class LoadScreen : IntroSlideShow
{
	int nextscreen, actiontick, tickcount;
	double speed;
	double assetalpha;
	TextureID bkg, bkg1, bkg2, gametitle, gzdoom, thirtyyears;

	override void SetGraphics()
	{
		bkg = TexMan.CheckForTexture("MENUBLUE", TexMan.Type_Any);
		bkg1 = TexMan.CheckForTexture("Graphics/Title/bkg1.png", TexMan.Type_Any);
		bkg2 = TexMan.CheckForTexture("Graphics/Title/bkg2.png", TexMan.Type_Any);
		gametitle = TexMan.CheckForTexture("Graphics/Wolf3D.png", TexMan.Type_Any);
		gzdoom = TexMan.CheckForTexture("Graphics/Title/gzdoom.png", TexMan.Type_Any);
		thirtyyears = TexMan.CheckForTexture("Graphics/Title/30years.png", TexMan.Type_Any);
	}

	override void Drawer()
	{
		SetGraphics();

		screen.Dim(0x000000, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

		int step = int(actiontick * speed);

		if (curscreen == 4)
		{
			screen.DrawTexture(thirtyyears, false, 320, 240, DTA_VirtualWidth, 640, DTA_VirtualHeight, 480, DTA_CenterOffset, true);
		}
		else if (curscreen > 0 && curscreen < 4)
		{
			screen.DrawTexture(bkg, false, 0, 0, DTA_FullscreenEx, FSMode_ScaleToFill, DTA_Desaturate, 255);
			screen.Dim(0x000000, 0.6, 0, 0, screen.GetWidth(), screen.GetHeight());
			screen.DrawTexture(bkg1, false, CleanWidth_1 - 320 - step, 0, DTA_KeepRatio, true, DTA_VirtualHeight, 480);
			screen.DrawTexture(bkg2, false, -320 + step, 0, DTA_KeepRatio, true, DTA_VirtualHeight, 480);
			screen.Dim(0x000000, 0.6, 0, 0, screen.GetWidth(), screen.GetHeight());

			if (curscreen == 2)
			{
				screen.DrawTexture(gametitle, false, 0, 32, DTA_VirtualWidth, 480, DTA_VirtualHeight, 360, DTA_Alpha, assetalpha);
			}
			else if (curscreen == 3)
			{
				screen.DrawTexture(gametitle, false, 0, 32, DTA_VirtualWidth, 480, DTA_VirtualHeight, 360);
				screen.DrawTexture(gzdoom, false, 480, 320, DTA_VirtualWidth, 640, DTA_VirtualHeight, 480, DTA_Alpha, assetalpha);
			}
		}

		screen.Dim(0x000000, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		tickcount++;

		if (advancetime > 0 && advancetime <= gametic)
		{
			inputtic = gametic;
			nextscreen++;
			advancetime = 0;
		}

		speed = 1.0 * CleanWidth_1 / 960;

		if (curscreen > 1 && curscreen < 4)
		{
			actiontick++;
		}
	
		if (inputtic == gametic)
		{
			switch (curscreen)
			{
				case 0: // Blank black screen
					advancetime = gametic + 35;
					fadetarget = gametic + fadetime;
					break;
				case 1: // Background only
					S_StartSound("introsplash", CHAN_VOICE, CHANF_UI, 0.85);
					advancetime = gametic + 35 * 4;
					fadetarget = -1;
					break;
				case 2: // Game Title
					advancetime = gametic + 35 * 5;
					fadetarget = -1;
					break;
				case 3: // Powered by GZDoom
					advancetime = gametic + 35 * 6;
					fadetarget = gametic + fadetime;
					break;
				case 4: // 30 Years
					advancetime = gametic + 35;
					fadetarget = gametic + fadetime;
					break;
				case 5:
					Menu.SetMenu("GameMenu", -1);
					break;
				default:
					advancetime = gametic + 20;
					fadetarget = gametic + fadetime;
					break;
			}

			if (fadetarget == gametic || fadetarget == -1)
			{
				assetalpha = 0.0;
			}
		}

		if (gametic > 0)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
			if (assetalpha < 1.0) { assetalpha = min(1.0, assetalpha + 0.1); }
		}

		if (fadetarget == gametic || fadetarget == -1)
		{
			curscreen = nextscreen;
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey && fadetarget < gametic)
		{
			System.StopAllSounds();
			Menu.SetMenu("GameMenu", -1);
			return true;
		}
	
		return false;
	}
}

class ScoreEntry
{
	String n;
	String l;
	String s;
}

class HighScores : WolfMenu
{
	Vector2 dimcoords, dimsize;
	TextureID title, nametitle, scoretitle, leveltitle, bkg, icon;
	int currentline, fontheight;
	Array<ScoreEntry> scores;

	int fadetarget;
	int fadetime;
	double fadealpha;
	int fadecolor;

	int exittimeout;
	bool exitmenu;
	bool finale;

	TextEnterMenu mInput;
	int inputindex;
	String mPlayerName;

	override void Init(Menu parent)
	{
		GenericMenu.Init(parent);

		fadetime = 12;
		fadetarget = gametic;
		fadealpha = 1.0;
		fadecolor = (Game.IsSoD() ? 0x000000 : 0x880000);

		title = TexMan.CheckForTexture((Game.IsSoD() ? "SSCORES" : "SCORES"), TexMan.Type_Any);
		nametitle = TexMan.CheckForTexture("M_NAME", TexMan.Type_Any);
		scoretitle = TexMan.CheckForTexture("M_SCORE", TexMan.Type_Any);
		leveltitle = TexMan.CheckForTexture("M_LEVEL", TexMan.Type_Any);
		bkg = TexMan.CheckForTexture("MENUBLUE", TexMan.Type_Any);
		icon = TexMan.CheckForTexture("SODICON", TexMan.Type_Any);

		[dimcoords, dimsize] = screen.VirtualToRealCoords((0, 0), (320, 200), (320, 200));

		fontheight = 10;

		S_ChangeMusic("ROSTER");

		for (int s = 1; s <= 7; s++)
		{
			CVar scorevalue = CVar.FindCvar("wolf3dtc_highscore" .. s);

			if (scorevalue)
			{
				Array<String> entry;

				decode(scorevalue.GetString(), s).Split(entry, "||");

				ScoreEntry h = New("ScoreEntry");
				if (entry.Size()) { h.n = entry[0]; }
				if (entry.Size() > 1) { h.l = entry[1]; }
				if (entry.Size() > 2) { h.s = entry[2]; }

				scores.Push(h);

				entry.Clear();
				scorevalue = null;
			}
		}

		let p = players[consoleplayer].mo;

		finale = (gamestate == GS_FINALE || gamestate == GS_CUTSCENE || LifeHandler.GetLives(p) < 0);
		inputindex = -1;

		if (finale && (!mParentMenu || !ListMenu(mParentMenu) || (!ListMenu(mParentMenu).mDesc || ListMenu(mParentMenu).mDesc.mMenuName != "MainMenu")))
		{
			ScoreEntry h = New("ScoreEntry");

			h.n = "";
			h.l = LevelString();
			h.s = p.FindInventory("Score") ? String.Format("%i", p.FindInventory("Score").Amount) : "0";

			scores.Push(h);

			inputindex = SortScores();

			WriteScores();
		}

		mInput = null;
	}

	override void Drawer()
	{
		screen.Dim(0, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());
		screen.Dim((Game.IsSoD() ? 0x000088 : 0x880000), 1.0, int(dimcoords.x), int(dimcoords.y), int(dimsize.x), int(dimsize.y));

		double ratio = screen.GetHeight() / 200.;

		screen.Dim(0x000000, 1.0, 0, int(10 * ratio), screen.GetWidth(), int(22 * ratio));
		screen.Dim(0x000000, 0.3, 0, int(32 * ratio), screen.GetWidth(), int(1 * ratio));
		screen.Dim(0x000000, 1.0, 0, int(33 * ratio), screen.GetWidth(), int(1 * ratio));

		if (Game.IsSoD() && bkg) { screen.DrawTexture(bkg, true, 0, 0, DTA_Fullscreen, 1); }

		if (title) { screen.DrawTexture(title, false, (Game.IsSoD() ? 0 : 48), (Game.IsSoD() ? 0 : -0.25), DTA_320x200, true, DTA_LeftOffset, 0, DTA_TopOffset, 0); }

		if (!Game.IsSoD())
		{
			if (nametitle) { screen.DrawTexture(nametitle, false, 32, 68, DTA_320x200, true); }
			if (leveltitle) { screen.DrawTexture(leveltitle, false, 160, 68, DTA_320x200, true); }
			if (scoretitle) { screen.DrawTexture(scoretitle, false, 228, 68, DTA_320x200, true); }
		}

		for (int s = 0; s < 7; s++)
		{
			int y = 76 + 16 * s;

			screen.DrawText(SmallFont, Font.FindFontColor("TrueWhite"), 32, y, scores[s].n, DTA_320x200, true);
			screen.DrawText(SmallFont, Font.FindFontColor("TrueWhite"), 163, y, scores[s].l, DTA_320x200, true);

			if (icon && scores[s].l.Left(5) == "   21")
			{
				screen.DrawTexture(icon, false, 160, y - 1, DTA_320x200, true);
			}

			for (int t = scores[s].s.Length(); t > 0; t--)
			{
				String chr = scores[s].s.Mid(scores[s].s.Length() - t, 1);

				// The Wolf fixed-width numbers center the 1 but left-align all of the other numbers...
				int x = chr == "1" ? 264 - 8 * t + 4 - SmallFont.StringWidth(chr) / 2 : 264 - 8 * t;
				screen.DrawText(SmallFont, Font.FindFontColor("TrueWhite"), x, y, chr, DTA_320x200, true);
			}
		}

		if (inputindex > -1 && mInput)
		{
			let printit = mInput.GetText() .. ((gametic % 30 < 15) ? String.Format("%c", 0x80) : "");
			screen.DrawText (SmallFont, Font.FindFontColor("TrueWhite"), 32, 76 + 16 * inputindex, printit, DTA_320x200, true);
		}
 
		screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		Super.Ticker();

		if (gametic > 35)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}

		if (exitmenu)
		{
			exittimeout++;

			if (exittimeout >= fadetime)
			{
				if (mParentMenu || finale)
				{
					S_ChangeMusic("WONDERIN");
					Menu.SetMenu("MainMenu", -1);
				}
				else { Menu.SetMenu("CloseMenu", -1); }
			}
		}

		if (!fadealpha && inputindex > -1 && !mInput)
		{
			GetInput();
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (inputindex == -1)
		{
			exitmenu = true;

			if (gamestate == GS_FINALE || gamestate == GS_CUTSCENE) { fadecolor = 0x000000; }
			MenuSound (GetCurrentMenu() != null ? "menu/backup" : "menu/clear");
			return true;
		}

		if (mkey == Menu.MKEY_Input)
		{
			scores[inputindex].n = mInput.GetText();
			WriteScores();
			mInput = null;
			inputindex = -1;
			return true;
		}

		return false;
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (type == MOUSE_Click)
		{
			return MenuEvent(MKEY_Enter, true);
		}

		return Super.MouseEvent(type, x, y);
	}

	String LevelString()
	{
		String levelname = level.mapname;

		if (levelname.Length() == 4 && levelname.Mid(0, 1) ~== "E" && levelname.Mid(2, 1) ~== "L")
		{
			levelname = levelname.Mid(0, 2) .. "/" .. levelname.Mid(2, 2);
			levelname = levelname.MakeUpper();
		}
		else if (levelname.length() == 5 && levelname.mid(0, 3) ~== "SOD")
		{
			levelname = "   " .. levelname.Mid(3, 2);
		}
		else if (levelname.length() == 5 && levelname.mid(0, 3) ~== "SD2")
		{
			levelname = "   " .. levelname.Mid(3, 2) .. " RTD";
		}
		else if (levelname.length() == 5 && levelname.mid(0, 3) ~== "SD3")
		{
			levelname = "   " .. levelname.Mid(3, 2) .. " TUC";
		}

		return levelname;
	}

	// Algorithms adapted from https://en.wikibooks.org/wiki/Algorithm_Implementation/Miscellaneous/Base64
	// Pass in v value as an offset to slightly obfuscate the encoded value (added ROT cipher, effectively)
	String Encode(String s, int v = 0)
	{
		String base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
		String r = ""; 
		String p = ""; 
		int c = s.Length() % 3;

		if (c)
		{
			for (; c < 3; c++)
			{ 
				p = p .. '='; 
				s = s .. "\0"; 
			} 
		}

		for (c = 0; c < s.Length(); c += 3)
		{
			int m = (s.ByteAt(c) + v << 16) + (s.ByteAt(c + 1) + v << 8) + s.ByteAt(c + 2) + v;
			int n[] = { (m >>> 18) & 63, (m >>> 12) & 63, (m >>> 6) & 63, m & 63 };
			r = r .. base64chars.Mid(n[0], 1) .. base64chars.Mid(n[1], 1) .. base64chars.Mid(n[2], 1) .. base64chars.Mid(n[3], 1);
		}

		return r.Mid(0, r.Length() - p.Length()) .. p;
	}

	String Decode(String s, int v = 0)
	{
		String base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

		String p = (s.Mid(s.Length() - 1, 1) == '=' ? (s.Mid(s.Length() - 2, 1) == '=' ? "AA" : "A") : ""); 
		String r = ""; 
		s = s.Mid(0, s.Length() - p.Length()) .. p;

		for (int c = 0; c < s.Length(); c += 4)
		{
			int c1 = base64chars.IndexOf(s.Mid(c, 1)) << 18;
			int c2 = base64chars.IndexOf(s.Mid(c + 1, 1)) << 12;
			int c3 = base64chars.IndexOf(s.Mid(c + 2, 1)) << 6;
			int c4 = base64chars.IndexOf(s.Mid(c + 3, 1));

			int n = (c1 + c2 + c3 + c4);
			r = r .. String.Format("%c%c%c", ((n >>> 16) - v) & 127, ((n >>> 8) - v) & 127, (n - v) & 127); // Sorry extened ASCII and Unicode...  No support for you here.
		}

		return r.Mid(0, r.Length() - p.Length());
	}

	int SortScores()
	{
		bool swapped = true;

		int currentindex = scores.Size() - 1;

		while (swapped)
		{
			swapped = false;

			for (int s = 1; s < scores.Size(); s++)
			{
				if (scores[s].s.ToInt() > scores[s - 1].s.ToInt())
				{
					ScoreEntry temp = scores[s - 1];
					scores[s - 1] = scores[s];
					scores[s] = temp;

					if (s == currentindex) { currentindex = s - 1; }

					swapped = true;
				}
			}
		}

		return currentindex > 6 ? -1 : currentindex;
	}

	void WriteScores()
	{
		for (int s = 0; s < 7; s++)
		{
			CVar scorevalue = CVar.FindCvar("wolf3dtc_highscore" .. s + 1);

			if (scorevalue && scores[s])
			{
				String value = scores[s].n .. "||" .. scores[s].l .. "||" .. scores[s].s;
				value = encode(value, s + 1);

				scorevalue.SetString(value);

				scorevalue = null;
			}
		}

	}

	void GetInput()
	{
		mInput = TextEnterMenu.OpenTextEnter(Menu.GetCurrentMenu(), SmallFont, mPlayerName, 128);
		mInput.ActivateMenu();
	}
}