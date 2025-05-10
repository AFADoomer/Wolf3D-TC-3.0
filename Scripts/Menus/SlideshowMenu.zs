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

class OldHelpMenu : ReadThisMenu
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
		ParseFile(GameHandler.GameFilePresent("WL3", true) ? "data/helpregistered.txt" : "data/help.txt");

		if (gamestate != GS_FINALE)
		{
			GameHandler.ChangeMusic("CORNER");
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

		Menu.Drawer();
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
				if (!mParentMenu) { GameHandler.ChangeMusic("*"); }
				else { GameHandler.ChangeMusic("WONDERIN"); }
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

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.type == UIEvent.Type_RButtonUp)
		{
			if (mScreen == 1) { return MenuEvent(MKEY_Back, false); }
			return MenuEvent(MKEY_Left, false);
		}

		return Super.OnUIEvent(ev);
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

class FinaleMenu : TextScreenMenu
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		InitCommon(parent, desc);

		if (mDesc.mTitle.length()) { ParseFile(mDesc.mTitle); }
	}
}

class SoDEnd : OldHelpMenu
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
			GameHandler.ChangeMusic("");
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
					GameHandler.ChangeMusic("XTHEEND");
					advancetime = gametic + 35 * 2;
					break;
				case 1:
				case 2:
					GameHandler.ChangeMusic("XTHEEND");
					page = nextpage;
					advancetime = gametic + 52;
					break;
				case 3:
					GameHandler.ChangeMusic("XTHEEND");
					page = nextpage;
					advancetime = gametic + 35 * 3;
					break;
				case 4:
					GameHandler.ChangeMusic("URAHERO");
					fadecolor = 0x00000;
					fadetarget = gametic + fadetime;
					allowinput = true;
					break;
				case 5:
					GameHandler.ChangeMusic("URAHERO");
					fadetarget = gametic + fadetime;
					advancetime = gametic + 35 * 10;
					break;
				case 6:
					GameHandler.ChangeMusic("URAHERO");
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
					GameHandler.ChangeMusic("URAHERO");
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
		GameHandler.ChangeMusic("");

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

		startup = TexMan.CheckForTexture((Game.IsSoD() ? GameHandler.GameFilePresent("SOD") ? "SSTARTUP" : "SDSTARTU" : "STARTUP"), TexMan.Type_Any);
		startup2 = TexMan.CheckForTexture((Game.IsSoD() ? GameHandler.GameFilePresent("SOD") ? "SSTARTU2" : "SDSTART2" : "STARTUP2"), TexMan.Type_Any);
		warning = TexMan.CheckForTexture("WARNING", TexMan.Type_Any);
		title = TexMan.CheckForTexture((Game.IsSoD() ? GameHandler.GameFilePresent("SOD") ? "STITLEPI" : "SDTITLEP" : "TITLEPIC"), TexMan.Type_Any);
		credits = TexMan.CheckForTexture((Game.IsSoD() ? "SCREDIT" : "CREDIT"), TexMan.Type_Any);
		selected = TexMan.CheckForTexture("STARTSEL", TexMan.Type_Any);

		sodversion = Game.IsSoD();
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
					GameHandler.ChangeMusic(Game.IsSoD() ? "XTOWER2" : "NAZI_NOR");
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
		if (ev.type == UIEvent.Type_KeyUp)
		{
			if (CheckControl(self, ev, "toggleconsole"))
			{
				GameHandler.OpenConsole();
				Close();

				return false;
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

		GameHandler.ChangeMusic(Game.IsSoD() ? "XTOWER2" : "NAZI_NOR");
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
		int w = int(480 * Screen.GetAspectRatio());

		if (curscreen == 4)
		{
			screen.DrawTexture(thirtyyears, false, w / 2, 240, DTA_VirtualWidth, w, DTA_VirtualHeight, 480, DTA_CenterOffset, true, DTA_KeepRatio, true);
		}
		else if (curscreen > 0 && curscreen < 4)
		{
			screen.DrawTexture(bkg, false, 0, 0, DTA_FullscreenEx, FSMode_ScaleToFill, DTA_Desaturate, 255);
			screen.Dim(0x000000, 0.6, 0, 0, screen.GetWidth(), screen.GetHeight());
			screen.DrawTexture(bkg1, false, w - min(640, 320 + step), 0, DTA_KeepRatio, true, DTA_VirtualWidth, w, DTA_VirtualHeight, 480);
			screen.DrawTexture(bkg2, false, min(0, -320 + step), 0, DTA_KeepRatio, true, DTA_VirtualWidth, w, DTA_VirtualHeight, 480);
			screen.Dim(0x000000, 0.6, 0, 0, screen.GetWidth(), screen.GetHeight());

			if (curscreen == 2)
			{
				screen.DrawTexture(gametitle, false, 0, 32, DTA_VirtualWidth, 480, DTA_VirtualHeight, 360, DTA_Alpha, assetalpha);
			}
			else if (curscreen == 3)
			{
				screen.DrawTexture(gametitle, false, 0, 32, DTA_VirtualWidth, 480, DTA_VirtualHeight, 360);
				screen.DrawTexture(gzdoom, false, int(w * 3 / 4), 320, DTA_KeepRatio, true, DTA_VirtualWidth, w, DTA_VirtualHeight, 640, DTA_VirtualHeight, 480, DTA_Alpha, assetalpha);
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
					GameHandler.ChangeMusic("INTRO", 0, false);
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
					if (GameHandler.NoGamemaps())
					{
						Menu.SetMenu("GamemapsMessage", -1);
					}
					else
					{
						Menu.SetMenu("GameMenu", -1);
					}
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

			if (GameHandler.NoGamemaps())
			{
				Menu.SetMenu("GamemapsMessage", -1);
			}
			else
			{
				Menu.SetMenu("GameMenu", -1);
			}
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
	int fadestart;

	int exittimeout;
	bool exitmenu;
	bool finale;

	TextEnterMenu mInput;
	int inputindex;
	String mPlayerName;

	override void Init(Menu parent)
	{
		GenericMenu.Init(parent);

		fadestart = gametic + !parent * 12;
		fadetime = 12;
		fadetarget = fadestart;
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

		GameHandler.ChangeMusic("ROSTER");

		for (int s = 1; s <= 7; s++)
		{
			CVar scorevalue = CVar.FindCvar("wolf3dtc_highscore" .. (g_sod > 0 ? "s" : "") .. s);

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

		finale = (gamestate == GS_FINALE || !Game.InGame());
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

		if (gametic > fadestart)
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
					GameHandler.ChangeMusic("WONDERIN");
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
			CVar scorevalue = CVar.FindCvar("wolf3dtc_highscore" .. (g_sod > 0 ? "s" : "") .. s + 1);

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

class TextScreenMenu : OptionMenu
{
	TextureID border;
	Vector2 dimcoords, dimsize;
	int lineheight;
	bool allowexit;
	bool allowinput;
	int selected;
	Vector2 padding;

	int mScreen;
	int mInfoTic;

	Array<HelpInfo> PagesInfo;

	bool showoverlay;

	void InitCommon(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		selected = 0;
		mInfoTic = gametic;
		border = TexMan.CheckForTexture("BORDER", TexMan.Type_Any);

		[dimcoords, dimsize] = screen.VirtualToRealCoords((0, 0), (320, 200), (320, 200));

		lineheight = 10;
		allowinput = true;

		padding = (16, 16);
	}

	override void Drawer()
	{
		screen.Dim(0, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());
		screen.Dim(0xDCDCDC, 1.0, int(dimcoords.x), int(dimcoords.y), int(dimsize.x), int(dimsize.y));

		if (selected < PagesInfo.Size()) { DrawText(PagesInfo[selected]); }

		if (border) { screen.DrawTexture(border, false, 0, 0, DTA_320x200, true); }

		screen.DrawText(SmallFont, Font.FindFontColor("WolfDarkGold"), 213, 183, String.Format("pg %i of %i", selected + 1, PagesInfo.Size()), DTA_320x200, true);
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
			selected = min(PagesInfo.Size() - 1, selected + 1);
			mInfoTic = gametic;

			return true;
		}
		else if (mkey == MKEY_Left)
		{
			selected = max(0, selected - 1);
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
		ParseData(ReadLump(filename));
	}

	ui void ParseData(String data, String defaultcolor = "\c[Palette00]")
	{
		int s = data.IndexOf("^P");
		while (s > -1)
		{
			int e = data.IndexOf("^P", s + 2);
			if (e < 0) { e == 0x7FFFFFFF; }

			let h = HelpInfo.Create(data.Mid(s, e - s), lineheight, defaultcolor, 15);
			PagesInfo.Push(h);

			s = e < 0x7FFFFFFF ? e : -1;
		}
	}

	ui String ReadLump(String lumpname)
	{
		int lump = -1;

		lump = Wads.CheckNumForFullName(lumpname);

		if (lump > -1) { return Wads.ReadLump(lump); }

		return "";
	}

	void DrawText(in out HelpInfo info, int textx = 0, int texty = 0, font fnt = null)
	{
		if (fnt == null) { fnt = SmallFont; }

		info.Draw(textx, texty, fnt, padding);
	}

	virtual void DrawDebugOverlay(int textx = 0, int texty = 0)
	{
		double scale = 0.4;

		for (int c = textx; c < 320; c += 5)
		{
			String num = String.Format("%i", c - textx);
			String gnum = String.Format("(%i)", c - textx + padding.x);
			if ((c - textx) % 25 == 0)
			{
				screen.DrawText(NewSmallFont, Font.FindFontColor("Cyan"), padding.x + c - (NewSmallFont.StringWidth(num) * scale / 2), texty - 6, num, DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale);
				screen.DrawText(NewSmallFont, Font.FindFontColor("Purple"), padding.x + c - (NewSmallFont.StringWidth(gnum) * scale / 2), texty + 1, gnum, DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale);
				
			}
			screen.DrawText(NewSmallFont, Font.FindFontColor("White"), padding.x + c - (NewSmallFont.StringWidth("╵") * scale / 2), texty + 7, "╵", DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale);
		}

		for (int l = 1; texty + padding.y + l * lineheight < 200; l++)
		{
			String lnum = String.Format("\c[Cyan]%i \c[Purple](%i)", l - 1, (l + 1) * lineheight);
			screen.DrawText(NewSmallFont, Font.FindFontColor("TrueBlack"), textx - 12 - NewSmallFont.StringWidth(lnum) * scale, texty + padding.y + l * lineheight, lnum, DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale);

			for (int c = textx; c < 320; c += 5)
			{
				screen.DrawText(SmallFont, Font.FindFontColor("TrueBlack"), padding.x + c - (SmallFont.StringWidth("|") * scale / 2) + 0.5, texty + padding.y + l * lineheight, "|", DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, 0.9, DTA_Alpha, 0.125);
			}
		}
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.type == UIEvent.Type_KeyDown)
		{
			if (g_DebugTextScreens && ev.keystring == "G") { showoverlay = true; }
		}
		else if (ev.type == UIEvent.Type_KeyUp)
		{
			if (ev.keystring == "G") { showoverlay = false; }
		}

		return Super.OnUIEvent(ev);
	}
}

class MapMenu : TextScreenMenu
{
	double alpha;
	int h, w;

	Font titlefont, textfont, captionfont;
	
	int contentheight;
	int drawbottom;
	int scrollpos, maxscroll, scrollamt;
	int topoffset, bottomoffset;

	Vector2 cellsize, realcellsize;
	Vector2 scale;
	Vector2 screensize;

	ScrollBar scroll;

	Array<int> VisiblePages;
	MapHandler handler;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		OptionMenu.Init(parent, desc);

		border = TexMan.CheckForTexture("Graphics/Menu/MapSelectBackground.png", TexMan.Type_Any);

		mMouseCapture = true;
		allowexit = true;
		allowinput = true;

		alpha = 1.0;

		// Set the base resolution
		h = 200;
		w = 320;

		// Set frame padding and draw offsets
		padding = (4, 4);
		topoffset = 16;
		bottomoffset = 0;
		
		// Set cell size for index entries
		cellsize = (299, 12);

		// Set the fonts
		titlefont = BigFont;
		textfont = SmallFont;
		captionfont = SmallFont;

		// Font height used by entry content (captionfont)
		lineheight = max(captionfont.GetHeight(), 7);

		// Parse the data file and store it into an array
		handler = MapHandler.Get();
		GetMapData();

		MapDataInfo parent, last;
		int lasttier;
		selected = -1;

		for (int p = 0; p < PagesInfo.Size(); p++)
		{
			let h = PagesInfo[p];

			if (!parent || h.tier == 0)
			{
				parent = MapDataInfo(h);
				h.path = ZScriptTools.Trim(h.title);
				h.childrenhidden = true;
			}
			else
			{
			 	if (h.tier < lasttier)
				{
					int d = lasttier - h.tier;
					while (d > 0 && parent)
					{
						parent = MapDataInfo(parent.parent);
						d--;
					}
				}
				else if (h.tier > lasttier)
				{
					parent = last;
				}

				h.parent = parent;
				if (h.parent.childrenhidden)
				{
					h.childrenhidden = true; 
					h.hidden = true;
				}
				
				h.path = String.Format("%s%s \c[Palette7E]> %s%s", h.defaultcolor, parent.path, h.defaultcolor, ZScriptTools.Trim(h.title));

				if (parent) { parent.children.Push(h); }
			}

			last = MapDataInfo(h);
			lasttier = h.tier;

			h.ParseLines(300, captionfont, padding);
		}

		scrollpos = 0;
		scrollamt = 10;

		CalculatePositions();

		if (gamestate != GS_FINALE)
		{
			GameHandler.ChangeMusic("*");
		}

		[dimcoords, dimsize] = screen.VirtualToRealCoords((0, 0), (320, 200), (320, 200));
	}

	void CalculatePositions()
	{
		scale = (CleanXFac, CleanYFac);
		
		// Calculate the usable content area bounds
		contentheight = int(h - 2 * padding.y - topoffset - bottomoffset - 60);

		Vector2 realpos, realsize;
		[realpos, realsize] = Screen.VirtualToRealCoords((padding.x, padding.y + topoffset), (w - 2 * padding.x, contentheight), (w, h));

		drawbottom = int(realpos.y + realsize.y);

		Vector2 temp;
		[temp, realcellsize] = Screen.VirtualToRealCoords((0, 0), cellsize, (w, h));

		maxscroll = int(cellsize.y * (PagesInfo.Size() - 2) - contentheight);

		// Initialize the scrollbar
		if (scroll) { scroll.Destroy(); }
		scroll = Scroll.Init(int(realpos.x + realcellsize.x + 2 * scale.x), int(realpos.y), int(12 * scale.x), int(realsize.y), maxscroll);
	}

	override void Ticker()
	{
		Super.Ticker();

		if (screensize.x != Screen.GetWidth() || screensize.y != Screen.GetHeight())
		{
			screensize = (Screen.GetWidth(), Screen.GetHeight());
			CalculatePositions();
		}

		VisiblePages.Clear();

		// Create the entry list
		for (int p = 0; p < PagesInfo.Size() - 1; p++)
		{
			let page = PagesInfo[p];

			if (page.hidden) { continue; }

			page.index = VisiblePages.Size();
			page.pos = (padding.x, padding.y + topoffset - scrollpos + VisiblePages.Size() * cellsize.y);
			page.boxpos = (padding.x, padding.y + topoffset);
			[page.realpos, page.realboxpos] = Screen.VirtualToRealCoords(page.pos, page.boxpos, (w, h));
			page.size = realcellsize;

			page.size.y = min(page.size.y, page.realpos.y + page.size.y - page.realboxpos.y);
			page.size.y = min(page.size.y, drawbottom - page.realpos.y);
			page.realpos.y = clamp(page.realpos.y, page.realboxpos.y, drawbottom);

			VisiblePages.Push(p);

			if (selected == -1 && page.spans.Size()) { selected = page.index; }
		}

		maxscroll = max(0, int(cellsize.y * VisiblePages.Size() - contentheight));
		if (!maxscroll) { scrollpos = 0; }

		// Update the scrollbar
		if (scroll)
		{
			scroll.alpha = alpha;
			scroll.scrollpos = scrollpos;
			scroll.maxscroll = maxscroll;
		}
	}

	override void Drawer()
	{
		// Fill in the background
		screen.Dim(0x282828, 1.0, 0, 0, Screen.GetWidth(), Screen.GetHeight());
		if (border) { screen.DrawTexture(border, false, 160, 100, DTA_320x200, true, DTA_CenterOffset, true); }

		OptionMenu.Drawer();

		// Draw the title
		String pagetitle = StringTable.Localize("$M_MAPSELECT");
		screen.DrawText(titlefont, Font.FindFontColor("Palette6C"), 160 - titlefont.StringWidth(pagetitle) / 2, padding.y, pagetitle, DTA_320x200, true);

		// If there aren't any pages, stop here
		if (!VisiblePages.Size()) { return; }

		// Draw the entry list
		for (int p = 0; p < VisiblePages.Size(); p++)
		{
			let page = PagesInfo[VisiblePages[p]];

			if (page.realpos.y >= drawbottom || page.realpos.y + page.size.y <= page.realboxpos.y) { continue; }

			// Draw shading behind the selected entry
			if (p == selected)
			{
				screen.Dim(0xF, 0.25, int(page.realpos.x), int(page.realpos.y), int(page.size.x + (maxscroll ? 0 : 13 * scale.x)), int(page.size.y));
			}

			// Draw each entry
			String title = page.title;
			String indicator = " ";
			if (page.children.Size()) { indicator = (page.childrenhidden ? "🢓" : "🢒"); }
			title = String.Format("%s%s%s", title.left(page.tier), indicator, title.mid(page.tier));

			screen.DrawText(textfont, Font.FindFontColor("WolfMenuLightGrey"), page.pos.x, page.pos.y, title, DTA_320x200, true, DTA_ClipTop, int(page.realboxpos.y), DTA_ClipBottom, int(drawbottom), DTA_ClipRight, int(page.realpos.x + realcellsize.x));
		}

		// Draw page content
		if (VisiblePages.Size() && selected > -1)
		{
			int textx = 4;
			int texty = int(topoffset - lineheight + contentheight + 4);

			if (showoverlay) { DrawDebugOverlay(textx, texty); }

			if (!PagesInfo[VisiblePages[selected]].spans.Size()) { DrawText(PagesInfo[PagesInfo.Size() - 1], textx, texty, captionfont); }
			else { DrawText(PagesInfo[VisiblePages[selected]], textx, texty, captionfont); }
		}

		// Draw page number
		// screen.DrawText(captionfont, Font.FindFontColor("Palette07"), 270, 189, String.Format("pg %i of %i", selected + 1, VisiblePages.Size() - 1), DTA_320x200, true);

		// Draw the scrollbar
		if (scroll && maxscroll) { scroll.Draw(); }
	}

	MapDataInfo GetEntryAt(int x, int y)
	{
		for (int p = 0; p < VisiblePages.Size(); p++)
		{
			let page = MapDataInfo(PagesInfo[VisiblePages[p]]);
			if (!page) { continue; }

			if (
				x >= page.realpos.x &&
				x <= page.realpos.x + page.size.x &&
				y >= page.realpos.y &&
				y <= page.realpos.y + page.size.y
			) { return page; }
		}

		return null;
	}

	override bool MouseEvent(int type, int mx, int my)
	{
		if (type == MOUSE_CLICK)
		{
			MapDataInfo entry = GetEntryAt(mx, my);

			if (entry)
			{
				if (selected == entry.index) { entry.Clicked(); }
				else { selected = entry.index; }

				if (entry.size.y < realcellsize.y)
				{
					if (entry.realpos.y < Screen.GetHeight() / 2) { scrollpos -= int(realcellsize.y - entry.size.y); }
					else { scrollpos += int(realcellsize.y - entry.size.y); }
				}

				if (entry.childrenhidden)
				{
					maxscroll = max(0, int(cellsize.y * (VisiblePages.Size() - entry.children.Size()) - contentheight));
				}
				else
				{
					maxscroll = max(0, int(cellsize.y * (VisiblePages.Size() + entry.children.Size()) - contentheight));
				}

				return true;
			}

			if (scroll)
			{
				int scrollclick = scroll.CheckClick(mx, my);

				switch (scrollclick)
				{
					case ScrollBar.SCROLL_SLIDER:
						scroll.capture = true;
						break;
					case ScrollBar.SCROLL_UP:
						scrollpos = max(0, int(scrollpos - cellsize.y));
						break;
					case ScrollBar.SCROLL_DOWN:
						scrollpos = min(maxscroll, int(scrollpos + cellsize.y));
						break;
					case ScrollBar.SCROLL_PGUP:
						scrollpos = max(0, int(scrollpos - cellsize.y * 5));
						break;
					case ScrollBar.SCROLL_PGDOWN:
						scrollpos = min(maxscroll, int(scrollpos + cellsize.y * 5));
						break;
					default:
						break;
				}
			}
		}
		else if (type == MOUSE_MOVE && scroll && scroll.capture)
		{
			int ypos = clamp(my - (scroll.y + scroll.elementsize), 0, scroll.h - (scroll.elementsize * 2));
			scrollpos = maxscroll * ypos / (scroll.h - (scroll.elementsize * 2));
		}
		else
		{
			if (scroll && scroll.capture) { scroll.capture = false; }
		}

		return true;
	}
	
	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.type == UIEvent.Type_WheelUp)
		{
			if (!maxscroll) { scrollpos = 0; return true; }
			scrollpos = max(0, scrollpos - scrollamt);
			return true;
		}
		else if (ev.type == UIEvent.Type_WheelDown)
		{
			if (!maxscroll) { scrollpos = 0; return true; }
			scrollpos = min(maxscroll, scrollpos + scrollamt);
			return true;
		}
		return Super.OnUIEvent(ev);
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
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

		int startedAt = selected;
		int pageamt = int(contentheight / cellsize.y);

		switch (mkey)
		{
			case MKEY_Left:
				if (PagesInfo[VisiblePages[selected]].children.Size() && !PagesInfo[VisiblePages[selected]].childrenhidden)
				{
					PagesInfo[VisiblePages[selected]].Clicked(0);
					maxscroll = max(0, int(cellsize.y * (VisiblePages.Size() - PagesInfo[VisiblePages[selected]].children.Size()) - contentheight));
				}
				else if (PagesInfo[VisiblePages[selected]].parent)
				{
					PagesInfo[VisiblePages[selected]].parent.Clicked(0);
					selected = PagesInfo[VisiblePages[selected]].parent.index;
				}
				break;
			case MKEY_Up:
				selected--;
				break;
			case MKEY_Right:
				if (PagesInfo[VisiblePages[selected]].children.Size())
				{
					if (PagesInfo[VisiblePages[selected]].childrenhidden)
					{
						PagesInfo[VisiblePages[selected]].Clicked(1);
						maxscroll = max(0, int(cellsize.y * (VisiblePages.Size() + PagesInfo[VisiblePages[selected]].children.Size()) - contentheight));
					}
					else
					{
						selected = PagesInfo[VisiblePages[selected]].children[0].index;
					}
				}
				break;
			case MKEY_Down:
				selected++;
				break;
			case MKEY_PageUp:
				selected -= pageamt;
				break;
			case MKEY_PageDown:
				selected += pageamt;
				break;
			case MKEY_Enter:
				if (PagesInfo[VisiblePages[selected]].children.Size())
				{
					PagesInfo[VisiblePages[selected]].Clicked();
				}
				else
				{
					MapDataInfo m = MapDataInfo(PagesInfo[VisiblePages[selected]]);

					String queuecmd = String.Format("initialize:%s:%s", ZScriptTools.GetText(m.title), ZScriptTools.GetText(m.d.path));
					EventHandler.SendNetworkEvent(queuecmd);
					Close();
				}
				break;
			default:
				return Super.MenuEvent(mkey, fromcontroller);
		}

		SetScrollPosition();

		if (selected != startedAt)
		{
			MenuSound ("menu/cursor");
		}

		return true;
	}

	void SetScrollPosition()
	{
		int lastentry = VisiblePages.Size() - 1;

		if (selected < 0)
		{
			selected = 0;
		}
		else if (selected > lastentry)
		{
			selected = lastentry;
		}

		if (selected == 0)
		{
			scrollpos = 0;
		}
		else if (selected == lastentry)
		{
			scrollpos = maxscroll;
		}
		else if (selected * cellsize.y < scrollpos)
		{
			scrollpos = int(selected * cellsize.y);
		}
		else if ((selected + 1) * cellsize.y > scrollpos + contentheight)
		{
			scrollpos = int((selected + 1) * cellsize.y - contentheight);
		}

		scrollpos = clamp(scrollpos, 0, maxscroll);
	}

	void GetMapData()
	{
		if (!handler || !handler.datafiles.Size()) { return; }

		for (int d = 0; d < handler.datafiles.Size(); d++)
		{
			let gamefile = handler.datafiles[d];

			String gamefiledata = String.Format("^P\n^I0%s\n$PATH\n\n", ZScriptTools.GetText(gamefile.gametitle));
			let h = MapDataInfo.Create(gamefiledata, lineheight, gamefile);
			PagesInfo.Push(h);

			for (int m = 0; m < gamefile.maps.Size(); m++)
			{
				let parsedmap = gamefile.maps[m];

				if (
					(m > 0 && parsedmap.hash == gamefile.maps[m - 1].hash) ||
					(m < gamefile.maps.Size() - 1 && parsedmap.hash == gamefile.maps[m + 1].hash)
				 ) { continue; }

				String mapdata = String.Format("^P\n^I1!%s\n$PATH\n\n", parsedmap.mapname);
				let n = MapDataInfo.Create(mapdata, lineheight, gamefile);
				n.map = parsedmap;
		
				PagesInfo.Push(n);
			}
		}
	}
}

// Scrollbar UI widget class
class ScrollBar ui
{
	int x, y, w, h;
	int scrollpos, maxscroll;
	int elementsize;
	int blocktop, blockbottom;
	bool capture;

	double alpha;

	TextureID up, down, scroll_t, scroll_m, scroll_b, scroll_s;

	ScrollBar Init(int x, int y, int w, int h, int maxscroll)
	{
		ScrollBar s = New("ScrollBar");

		if (s)
		{
			s.up = TexMan.CheckForTexture("graphics/menu/arrow_up.png", TexMan.Type_Any);
			s.down = TexMan.CheckForTexture("graphics/menu/arrow_dn.png", TexMan.Type_Any);
			s.scroll_t = TexMan.CheckForTexture("graphics/menu/scroll_t.png", TexMan.Type_Any);
			s.scroll_m = TexMan.CheckForTexture("graphics/menu/scroll_m.png", TexMan.Type_Any);
			s.scroll_b = TexMan.CheckForTexture("graphics/menu/scroll_b.png", TexMan.Type_Any);
			s.scroll_s = TexMan.CheckForTexture("graphics/menu/scroll_s.png", TexMan.Type_Any);
	
			s.x = x;
			s.y = y;
			s.w = w;
			s.h = h;
			s.maxscroll = maxscroll;
			s.elementsize = s.w;
		}

		return s;
	}

	void Draw()
	{
		double scrollblocksize = double(h - elementsize * 3) / max(1, maxscroll);
		int scrollbarsize = int(clamp(scrollblocksize, 0, h / elementsize - 2));

		Screen.Dim(0x0, 0.5, x, y, w, h);

		if (scrollbarsize <= 1)
		{
				blocktop = y + elementsize + int(scrollblocksize * scrollpos);
				blockbottom = blocktop + elementsize;
				screen.DrawTexture(scroll_s, true, x, blocktop, DTA_Alpha, alpha, DTA_DestHeight, elementsize, DTA_DestWidth, elementsize);
		}
		else
		{
			blocktop = y + elementsize + min(int(scrollblocksize * scrollpos), h - elementsize * (2 + scrollbarsize));
			blockbottom = blocktop + elementsize * scrollbarsize;
			for (int b = 0; b < scrollbarsize; b++)
			{
				if (b == 0)
				{
					screen.DrawTexture(scroll_t, true, x, blocktop, DTA_Alpha, alpha, DTA_DestHeight, elementsize, DTA_DestWidth, elementsize);
				}
				else if (b == scrollbarsize - 1)
				{
					screen.DrawTexture(scroll_b, true, x, blocktop + b * elementsize, DTA_DestHeight, elementsize, DTA_DestWidth, elementsize);
				}
				else if (scrollbarsize > 2)
				{
					screen.DrawTexture(scroll_m, true, x, blocktop + b * elementsize, DTA_DestHeight, elementsize, DTA_DestWidth, elementsize);
				}
			}
		}

		Color clr = 0xFFFF00;
		Color disabled = 0xAAAAAA;

		screen.DrawTexture(up, true, x, y, DTA_Alpha, alpha, DTA_AlphaChannel, true, DTA_FillColor, scrollpos == 0 ? disabled : clr, DTA_DestHeight, elementsize, DTA_DestWidth, elementsize);
		screen.DrawTexture(down, true, x, y + h - elementsize, DTA_Alpha, alpha, DTA_AlphaChannel, true, DTA_FillColor, scrollpos == maxscroll ? disabled : clr, DTA_DestHeight, elementsize, DTA_DestWidth, elementsize);
	}

	enum Clicks
	{
		NONE,
		SCROLL_UP,
		SCROLL_DOWN,
		SCROLL_SLIDER,
		SCROLL_PGUP,
		SCROLL_PGDOWN,
	};

	int CheckClick(int mousex, int mousey)
	{
		if (mousex < x || mousex > x + elementsize) { return NONE; }
		if (mousey < y && mousey > y + h) { return NONE; }

		if (mousey <= y + elementsize) { return SCROLL_UP; }
		if (mousey >= y + h - elementsize) { return SCROLL_DOWN; }
		if (mousey >= blocktop && mousey <= blockbottom) { return SCROLL_SLIDER; }
		if (mousey < blocktop) { return SCROLL_PGUP; }
		if (mousey > blockbottom) { return SCROLL_PGDOWN; }

		return NONE;
	}

	int GetRight()
	{
		return x + w;
	}
}

class HelpInfo
{
	HelpInfo parent;
	Array<HelpInfo> children;
	String pagedata, title, path;
	int index, linecount, tier, column;
	Vector2 pos, realpos, boxpos, realboxpos, size;
	bool hidden, childrenhidden;
	Array<SpanInfo> spans;
	Array<GraphicInfo> graphics;
	Array<BlockInfo> blocks;
	int margins[26][2];
	int lineheight;
	String defaultcolor;

	virtual void Clicked(int activate = -1)
	{
		if (activate == 1) { HideChildren(false); }
		else if (activate == 0) { HideChildren(true); }
		else { HideChildren(!childrenhidden); }
	}

	virtual void Hide(bool hide = true)
	{
		hidden = hide;

		if (!hide) { return; }
		HideChildren(hide);
	}

	virtual void HideChildren(bool hide = true)
	{
		childrenhidden = hide;

		for (int i = 0; i < children.Size(); i++)
		{
			children[i].Hide(hide);
		}
	}

	static HelpInfo Create(String page, int lineheight, String defaultcolor, int maxlines = -1)
	{
		let h = New("HelpInfo");
		h.pagedata = page;
		h.lineheight = lineheight;
		h.defaultcolor = defaultcolor;

		h.ParseLines(maxrows:maxlines);

		return h;
	}

	virtual void ParseLines(int maxwidth = 320, Font fnt = null, Vector2 padding = (16, 16), int maxrows = -1)
	{
		spans.Clear();
		graphics.Clear();
		blocks.Clear();

		if (maxrows == -1) { maxrows = margins.Size(); }
		else { maxrows = min(margins.Size(), maxrows); }

		for (int m = 0; m < maxrows; m++)
		{
			margins[m][0] = int(padding.x);
			margins[m][1] = int(maxwidth - padding.x);
		}
		linecount = 0;
		column = 0;

		boxpos = (padding.x, padding.y);

		int t = 0;
		while (t > -1 && linecount < maxrows)
		{
			int f = pagedata.IndexOf("\n", t + 1);
			if (f < 0) { f == 0x7FFFFFFF; }

			ParseLine(pagedata.Mid(t == 0 ? 0 : t + 1, f - t), maxwidth, fnt, true);

			t = f < 0x7FFFFFFF ? f : -1;
		}

		if (!spans.Size() && !graphics.Size()) { hidden = true; }
	}

	virtual String ParseLine(String input = "", int maxwidth = 320, Font fnt = null, bool savedata = true)
	{
		if (!input.length()) { return ""; }

		if (fnt == null) { fnt = SmallFont; }

		String word = "";
		String content = "";
		String newclr = defaultcolor, clr = defaultcolor;
		linecount = min(linecount, margins.Size() - 1);

		int charoffset, j, c;

		int s = input.IndexOf("$");
		while (s > -1)
		{
			String lookup = ZScriptTools.GetWord(input.mid(s + 1), ZScriptTools.PUNC_DEFAULT, 0x5E);

			String entry;
			if (lookup ~== "PATH") { entry = path; }
			else { entry = StringTable.Localize(lookup, false); }

			input = String.Format("%s%s%s", input.Left(s), entry, input.Mid(s + lookup.length() + 1));

			s = input.IndexOf("$", s);
		}

		SpanInfo span = New("SpanInfo");
		span.fnt = fnt;
		span.x = max(column, margins[linecount][0]);
		span.y = linecount;

		for (uint i = 0; i < input.Length(); i++)
		{
			int nextchar = input.GetNextCodePoint(i);
			switch(nextchar)
			{
				// Handle control characters
				case 0x5E: // ^
					i++;
					switch(input.GetNextCodePoint(i))
					{
						// Change text alignment for this line (and all following text on this line)
						case 0x41: // A
						case 0x61: // a
							int textalign = ZScriptTools.STR_LEFT;

							i++;
							String align = input.Mid(i, 1);
							if (align ~== "C") { textalign = ZScriptTools.STR_CENTERED; }
							else if (align ~== "R") { textalign = ZScriptTools.STR_RIGHT; }

							i++;
							content = ZScriptTools.Trim(ParseLine(input.Mid(i), 0x7FFFFFFF, fnt, false));

							span.content = content;

							switch (textalign)
							{
								case ZScriptTools.STR_RIGHT:
									span.x -= fnt.StringWidth(content);
									break;
								case ZScriptTools.STR_CENTERED:
									span.x -= int(fnt.StringWidth(content) / 2.0);
									break;
								case ZScriptTools.STR_LEFT:
								default:
									break;
							}

							if (savedata && ZScriptTools.GetText(span.content).length()) { spans.Push(span); }

							return content;
						case 0x42: // B
						case 0x62: // b
							let b = New("BlockInfo");
							charoffset = 1;

							i += charoffset;
							[b.y, charoffset] = ZScriptTools.GetNumber(input.Mid(i));

							i += charoffset;
							[b.x, charoffset] = ZScriptTools.GetNumber(input.Mid(i));

							i += charoffset;
							[b.size.x, charoffset] = ZScriptTools.GetNumber(input.Mid(i));

							i += charoffset;
							[b.size.y, charoffset] = ZScriptTools.GetNumber(input.Mid(i));

							i += charoffset;

							b.clr = Screen.PaletteColor(ZScriptTools.HexStrToInt(ZScriptTools.Trim(input.Mid(i))));
							if (b.clr == 0x0) { b.clr = 0xDCDCDC; }

							if (savedata) { blocks.Push(b); }
							return "";
						// Change the text color
						case 0x43: // C
						case 0x63: // c
							string colorname = "";

							[c, j] = input.GetNextCodePoint(i + 1);
							if (c == 0x5B) // [
							{
								colorname = ZScriptTools.GetWord(input.mid(j), ZScriptTools.PUNC_DEFAULT, 0x5D);
							}

							if (colorname.length()) { i = j - 1; }
							else
							{
								colorname = String.Format("Palette%s", input.Mid(i + 1, 2));
								i += 2;
							}

							if (colorname.Left(1) == "#")
							{
								Color hexclr = ZScriptTools.HexStrToInt(colorname.Mid(1));
								newclr = String.Format("\c%s", ZScriptTools.BestTextColor(hexclr));
							}
							else
							{
								newclr = String.Format("\c[%s]", colorname);
							}
							break;
						// Marks end of file.  Not used in this implementation
						case 0x45: // E
						case 0x65: // e
						default:
							break;
						// Change the current font
						case 0x46: // F
						case 0x66: // f
							i++;
							String fontname = "";

							[c, j] = input.GetNextCodePoint(i);
							if (c == 0x5B) { fontname = ZScriptTools.GetWord(input.mid(j), ZScriptTools.PUNC_DEFAULT, 0x5D); }

							Font newfnt = Font.FindFont(fontname);
							if (newfnt)
							{
								if (savedata && ZScriptTools.GetText(span.content).length()) { spans.Push(span); }
								SpanInfo prevspan = span;

								span = New("SpanInfo");
								span.x = prevspan.x + prevspan.Width();
								span.y = linecount;
								span.fnt = newfnt;

								i = j + fontname.length();
							}
							break;
						// Insert a graphic...  
						// First looks for the lump by graphic number x as "SLIDEGx", then
						// falls back to looking for graphic by name/path
						case 0x47: // G
						case 0x67: // g
							int y, x, n;
							charoffset = 1;

							i += charoffset;
							[y, charoffset] = ZScriptTools.GetNumber(input.Mid(i));

							i += charoffset;
							[x, charoffset] = ZScriptTools.GetNumber(input.Mid(i));

							i += charoffset;
							n = ZScriptTools.GetNumber(input.Mid(i));

							String path;
							TextureID tex;
							if (n)
							{
								path = String.Format("SLIDEG%i", n);
								tex = TexMan.CheckForTexture(path, TexMan.Type_Any);

								if (!tex.IsValid()) { tex = TexMan.CheckForTexture(String.Format("WVGA%04i", n), TexMan.Type_Any); }
							}
							else
							{
								path = ZScriptTools.GetWord(input.Mid(i), ZScriptTools.PUNC_PATH);
								tex = TexMan.CheckForTexture(path, TexMan.Type_Any);
							}

							if (tex.IsValid())
							{
								let g = New("GraphicInfo");
								g.tex = tex;
								g.x = x & ~7;
								g.y = y + 7;
								g.size = TexMan.GetScaledSize(tex);
								if (savedata) { graphics.Push(g); }

								int adjustleft = 0;
								int adjustright = 0;

								Vector2 offsets = TexMan.GetScaledOffset(tex);

								if (x + size.x / 2 > maxwidth / 2) { adjustright = int(x - offsets.x - 8); }
								else { adjustleft = int(x - offsets.x + g.size.x + 8); }

								double top = max(0, (y - offsets.y - boxpos.y) / lineheight);
								double bottom = min(25, (g.y - offsets.y + g.size.y - boxpos.y) / lineheight);

								for (int m = int(floor(top)); m < floor(bottom) && m <  margins.Size(); m++)
								{
									if (adjustleft) { margins[m][0] = max(margins[m][0], adjustleft); }
									if (adjustright) { margins[m][1] = min(margins[m][1], adjustright); }
								}
							}
							else
							{
								console.printf("\c[Red]Error in screen format command \c[Gray]%s\n\c[Red]Specified texture '%s' is invalid.\n", ZScriptTools.Trim(input), path);
							}

							return "";
						// Custom addition to identify title and indentation
						// The numbers after the ^I are the number of spaces to indent by
						// e.g.:  ^I2 for two spaces of indentation
						case 0x49: // I
						case 0x69: // i
							title = "";
							charoffset = 1;
							int spacingamt;

							[spacingamt, charoffset] = ZScriptTools.GetNumber(input.Mid(i + charoffset));

							i += charoffset;

							hidden = (input.Mid(i, 1) == "!");
							if (hidden) { i++; }

							if (spacingamt > 0)
							{
								for (int s = 0; s < spacingamt; s++) { title = String.Format("%s%s", " ", title); }
								tier = spacingamt;
							}

							title = String.Format("%s%s", title, ParseLine(input.Mid(i), maxwidth, fnt, false));
							return title;
						// Position the cursor
						case 0x4C: // L
						case 0x6C: // l
							charoffset = 1;

							i += charoffset;
							[span.y, charoffset] = ZScriptTools.GetNumber(input.Mid(i));
							span.y = int(floor(span.y / lineheight)) + 1;
							linecount = min(span.y, margins.Size() - 1);

							i += charoffset;
							[span.x, charoffset] = ZScriptTools.GetNumber(input.Mid(i));
							column = span.x;
							return "";
						// New page.  Ignore here.
						case 0x50: // P
						case 0x70: // p
							return "";
					}
					break;
				// Handle tabs and spaces
				case 0x09: // Tab
				case 0x20: // Space
					content = String.Format("%s%s ", content, word);
					span.content = content;
					word = "";

					if (input.ByteAt(i) == 0x09)
					{
						if (savedata && ZScriptTools.GetText(span.content).length()) { spans.Push(span); }
						SpanInfo prevspan = span;

						content = "";
						span = New("SpanInfo");
						span.x = prevspan.x + prevspan.Width() - fnt.StringWidth(" ");
						span.y = prevspan.y;
						span.fnt = prevspan.fnt;

						span.x = int((span.x + 8) & 0xf8);
					}

					int nextspace = input.IndexOf(" ", i + 1); // Find the next space
					if (nextspace < 0) { nextspace = input.Length() - 1; }

					String teststring = ZScriptTools.Trim(input.mid(i + 1, nextspace - (i + 1)));

					// Skip color codes that are in lines when calculating length
					int c = 0;
					while (c < teststring.length())
					{
						if (teststring.ByteAt(c) == 0x5E) { teststring = String.Format("%s%s", teststring.Left(c), teststring.Mid(c + 4)); }
						c++;
					}

					int testlength = fnt.StringWidth(teststring);

					if (savedata && span.x + span.Width() + testlength > margins[linecount][1])
					{
						linecount++;

						if (savedata && ZScriptTools.Trim(span.content).length()) { spans.Push(span); }
						SpanInfo prevspan = span;

						content = "";
						span = New("SpanInfo");
						span.x = column ? max(column, margins[linecount][0]) : margins[linecount][0];
						span.y = linecount;
						span.fnt = prevspan.fnt;
					}
					break;
				// Ignore comments and stop parsing the line
				// Modified to only work if the semi-colon is at the start of a line
				case 0x3B: // ;
					if (i == 0) { return ""; }
				// Build the current word one character at  time
				default:
					if (ZScriptTools.IsPunctuation(nextchar) || ZScriptTools.IsWhiteSpace(nextchar) || !word.length())
					{
						if (clr != newclr)
						{
							word = String.Format("%s%s%s", clr, word, newclr);
							clr = newclr;
						}
						else { word = String.Format("%s%s", clr, word); }
					}

					word = String.Format("%s%c", word, nextchar);
					break;
			}
		}

		content = String.Format("%s%s ", content, word);
		span.content = content;
		if (savedata && ZScriptTools.GetText(span.content).length()) { spans.Push(span); }

		linecount++;

		return content;
	}

	virtual void Draw(int x, int y, Font fnt, Vector2 padding = (0, 0))
	{
		double scale = 0.4;

		for (int b = 0; b < blocks.Size(); b++)
		{
			let block = blocks[b];

			Vector2 pos, size;
			[pos, size] = Screen.VirtualToRealCoords((x + block.x, y + block.y - lineheight / 2), block.size, (320, 200));
			screen.Dim(block.clr, 1.0, int(pos.x), int(pos.y), int(size.x), int(size.y));

			// Draw block x/y coordinates
			if (g_DebugTextScreens)
			{
				screen.DrawText(NewSmallFont, Font.FindFontColor("Yellow"), x + block.x + 1, y + block.y - lineheight / 2, String.Format("%i, %i  %ix%i", block.x, block.y, block.size.x, block.size.y), DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale);
			}
		}

		for (int g = 0; g < graphics.Size(); g++)
		{
			let graphic = graphics[g];

			// Highlight draw area
			if (g_DebugTextScreens)
			{
				Vector2 pos, size, offsets;
				offsets = TexMan.GetScaledOffset(graphic.tex);
				[pos, size] = Screen.VirtualToRealCoords((x + graphic.x - offsets.x, y + graphic.y - lineheight / 2 - offsets.y), graphic.size, (320, 200));
				screen.Dim(0xDC00DC, 0.25, int(pos.x), int(pos.y), int(size.x), int(size.y));
			}

			screen.DrawTexture(graphic.tex, true, x + graphic.x, y + graphic.y - lineheight / 2, DTA_320x200, true); //, DTA_TopOffset, 0, DTA_LeftOffset, 0);

			// Draw graphic x/y coordinates
			if (g_DebugTextScreens)
			{
				screen.DrawText(NewSmallFont, Font.FindFontColor("Purple"), x + graphic.x - NewSmallFont.StringWidth("◸") * scale / 2 + 1, y + graphic.y - lineheight * 0.5, "◸", DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale);
				screen.DrawText(NewSmallFont, Font.FindFontColor("Purple"), x + graphic.x + 3, min(y + graphic.y - lineheight / 2, 200 - 12 * scale), String.Format("%i, %i", graphic.x, graphic.y), DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale);
			}
		}

		for (int s = 0; s < spans.Size(); s++)
		{
			let span = spans[s];
			Font spanfnt = span.fnt ? span.fnt : fnt;
			screen.DrawText(span.fnt, Font.FindFontColor("TrueBlack"), x + span.x, padding.y + y + span.y * lineheight, span.content, DTA_320x200, true);
			
			// Draw line x/y coordinates if they aren't at default for that line
			if (g_DebugTextScreens && (span.x - padding.x))
			{
				String coords = String.Format("%i, %i", int(span.x), int(span.y - 1));
				screen.DrawText(NewSmallFont, Font.FindFontColor("Cyan"), x + span.x, padding.y + y + span.y * lineheight, coords, DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale);
			}
		}

		if (g_DebugTextScreens)
		{
			String marker, m = "│";
			int left = 0;
			int right = 0;

			for (int l = 0; l < margins.Size(); l++)
			{
				if (left != margins[l][0])
				{
					left = int(margins[l][0]);
					marker = String.Format("\c[Gray]%i\c[TrueBlack] >%s", left, m);
				}
				else { marker = m; }
				if (left > padding.x) { screen.DrawText(NewSmallFont, Font.FindFontColor("TrueBlack"), x + margins[l][0] - NewSmallFont.StringWidth(marker) *  scale, padding.y + y + l * lineheight, marker, DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale); }

				if (right != margins[l][1])
				{
					right = int(margins[l][1]);
					marker = String.Format("\c[TrueBlack]%s< \c[Gray]%i", m, right);
				}
				else { marker = m; }
				if (x + right + padding.x * 2 < 320) { screen.DrawText(NewSmallFont, Font.FindFontColor("TrueBlack"), x + margins[l][1], padding.y + y + l * lineheight, marker, DTA_320x200, true, DTA_ScaleX, scale, DTA_ScaleY, scale); }
			}
		}
	}
}

class SpanInfo
{
	String content;
	Font fnt;
	int x, y;

	int Width()
	{
		return fnt.StringWidth(content);
	}
}

class GraphicInfo
{
	TextureID tex;
	int x, y;
	Vector2 size;

	static int Find(Array<GraphicInfo> graphics, TextureID tex)
	{
		for (int g = 0; g < graphics.Size(); g++)
		{
			if (graphics[g].tex == tex) { return g; }
		}

		return graphics.Size();
	}
}

class BlockInfo
{
	Color clr;
	int x, y;
	Vector2 size;
}

class MapDataInfo : HelpInfo
{
	DataFile d;
	ParsedMap map;

	static MapDataInfo Create(String page, int lineheight, DataFile d)
	{
		let h = New("MapDataInfo");
		h.pagedata = page;
		h.lineheight = lineheight;
		h.d = d;
		h.defaultcolor = "\c[White]";

		h.ParseLines();

		return h;
	}

	override void Draw(int x, int y, Font fnt, Vector2 padding)
	{
		String title = ZScriptTools.GetText(title);

		if (!map || !map.info)
		{
			screen.DrawText(fnt, Font.FindFontColor("White"), x + 4, padding.y + y + lineheight, title, DTA_320x200, true);
		}
		else
		{
			screen.DrawText(fnt, Font.FindFontColor("White"), x + 4, padding.y + y + lineheight, StringTable.Localize(map.info.levelname, false) .. "\n \c[Gray]" .. title, DTA_320x200, true);
		}

		if (map)
		{
			TextureID tex = TexMan.CheckForTexture("Floor", TexMan.Type_Any);
			double scale = 64.0 / map.height;
			for (int w = 0; w < map.width; w++)
			{
				for (int h = 0; h < map.height; h++)
				{
					int val = map.TileAt((w, h));
					if (val < 0x6A)
					{
						int l = map.TileAt((w - 1, h));
						int r = map.TileAt((w + 1, h));
						int a = map.TileAt((w, h - 1));
						int b = map.TileAt((w, h + 1));

						if (
							l > 0x6A && l < 0x90 || 
							r > 0x6A && r < 0x90 || 
							a > 0x6A && a < 0x90 || 
							b > 0x6A && b < 0x90
						)
						{
							screen.DrawTexture(map.GetTexture((w, h)), false, x + 310 - map.width * scale + w * scale, y + 1.5 * lineheight + h * scale * 0.83333, DTA_320x200, true, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_DestWidthF, scale, DTA_DestHeightF, scale * 0.83333);
						}
					}
					else if (val > 0x6A && val < 0x90)
					{
						tex = TexMan.CheckForTexture("Floor", TexMan.Type_Any);
						screen.DrawTexture(tex, false, x + 310 - map.width * scale + w * scale, y + 1.5 * lineheight + h * scale * 0.83333, DTA_320x200, true, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_DestWidthF, scale, DTA_DestHeightF, scale * 0.83333);
					}
					else if (val > 0x95)
					{
						screen.DrawTexture(map.GetTexture((w, h)), false, x + 310 - map.width * scale + w * scale, y + 1.5 * lineheight + h * scale * 0.83333, DTA_320x200, true, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_DestWidthF, scale, DTA_DestHeightF, scale * 0.83333);
					}
				}
			}
		}

	}
}

class HelpMenu : TextScreenMenu
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		InitCommon(parent, desc);

		ParseFile(GameHandler.GameFilePresent("WL3", true) ? "data/helpregistered.txt" : "data/help.txt");
	}
}

class OptionMenuItemVariableText : OptionMenuItem 
{
	int mColor;

	OptionMenuItemVariableText Init(String label, Name command, int cr = -1)
	{
		Super.Init(label, command, true);

		mColor = OptionMenuSettings.mFontColor;
		if ((cr & 0xffff0000) == 0x12340000) mColor = cr & 0xffff;
		else if (cr > 0) mColor = OptionMenuSettings.mFontColorHeader;
		return self;
	}

	OptionMenuItemVariableText InitDirect(String label, Name command, int cr)
	{
		Super.Init(label, command, true);
		mColor = cr;
		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		String txt = StringTable.Localize(String.Format("$%s%i", mLabel, g_warpskill));
		int w = Menu.OptionWidth(txt) * CleanXfac_1;
		int x = (screen.GetWidth() - w) / 2;
		drawText(x, y, mColor, txt);
		return -1;
	}

	override bool Selectable()
	{
		return false;
	}
}

class OptionMenuItemImageSlider : OptionMenuSliderBase
{
	transient CVar mCVar;
	String prefix;

	OptionMenuItemImageSlider Init(String label, String texprefix, Name command, double min, double max, double step, CVar graycheck = NULL, int graycheckVal = 0)
	{
		Super.Init(label, min, max, step, -1, command, graycheck, graycheckVal);
		prefix = texprefix;
		mCVar = CVar.FindCVar(command);
		return self;
	}

	override double GetSliderValue()
	{
		if (mCVar != null)
		{
			return mCVar.GetFloat();
		}
		else
		{
			return 0;
		}
	}

	override void SetSliderValue(double val)
	{
		if (mCVar != null)
		{
			mCVar.SetFloat(val);
		}
	}
}