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

class WolfMenu : GenericMenu
{
	static void SetMenu(Actor caller, Name mnu, int param = 0)
	{
		if (players[consoleplayer].mo != caller) { return; }

		Menu.SetMenu(mnu, param);
	}

	static bool CheckControl(Menu thismenu, UIEvent ev, String control, int type = 0)
	{
		if (ev.type < UIEvent.Type_FirstMouseEvent && !ev.keychar) { return false; }

		Array<int> keycodes;
		bool ret = true;

		// Look up key binds for the passed-in command
		Bindings.GetAllKeysForCommand(keycodes, control);

		if (!keycodes.Size()) { return false; }

		// Get the key names for each bound key, and parse them into a lookup array
		String keynames = Bindings.NameAllKeys(keycodes);
		keynames = ZScriptTools.StripColorCodes(keynames);

		Array<String> keys;
		keynames.Split(keys, ", ");

		String keychar = String.Format("%c", ev.keychar);
		keychar = keychar.MakeUpper();

		bool pressed = false;

		for (int i = 0; i < keys.Size(); i++)
		{
			if (keys[i].Length() > 1)
			{
				if (
					(ev.type == UIEvent.Type_LButtonDown && keys[i] == "Mouse1") ||
					(ev.type == UIEvent.Type_RButtonDown && keys[i] == "Mouse2") ||
					(ev.type == UIEvent.Type_MButtonDown && keys[i] == "Mouse3") ||
					(ev.type == UIEvent.Type_WheelUp && keys[i] == "MWheelUp") || 
					(ev.type == UIEvent.Type_WheelDown && keys[i] == "MWheelDown") || 
					(ev.type == UIEvent.Type_WheelLeft && keys[i] == "MWheelLeft") || 
					(ev.type == UIEvent.Type_WheelRight && keys[i] == "MWheelRight") ||
					(ev.keychar == UIEvent.Key_PgDn && keys[i] == "PgDn") ||
					(ev.keychar == UIEvent.Key_PgUp && keys[i] == "PgUp") ||
					(ev.keychar == UIEvent.Key_Home && keys[i] == "Home") ||
					(ev.keychar == UIEvent.Key_End && keys[i] == "End") ||
					(ev.keychar == UIEvent.Key_Left && keys[i] == "LeftArrow") ||
					(ev.keychar == UIEvent.Key_Right && keys[i] == "RightArrow") ||
					(ev.keychar == UIEvent.Key_Backspace && keys[i] == "Backspace") ||
					(ev.keychar == UIEvent.Key_Tab && keys[i] == "Tab") ||
					(ev.keychar == UIEvent.Key_Down && keys[i] == "DownArrow") ||
					(ev.keychar == UIEvent.Key_Up && keys[i] == "UpArrow") ||
					(ev.keychar == UIEvent.Key_Return && keys[i] == "Enter") ||
					(ev.keychar == UIEvent.Key_F1 && keys[i] == "F1") ||
					(ev.keychar == UIEvent.Key_F2 && keys[i] == "F2") ||
					(ev.keychar == UIEvent.Key_F3 && keys[i] == "F3") ||
					(ev.keychar == UIEvent.Key_F4 && keys[i] == "F4") ||
					(ev.keychar == UIEvent.Key_F5 && keys[i] == "F5") ||
					(ev.keychar == UIEvent.Key_F6 && keys[i] == "F6") ||
					(ev.keychar == UIEvent.Key_F7 && keys[i] == "F7") ||
					(ev.keychar == UIEvent.Key_F8 && keys[i] == "F8") ||
					(ev.keychar == UIEvent.Key_F9 && keys[i] == "F9") ||
					(ev.keychar == UIEvent.Key_F10 && keys[i] == "F10") ||
					(ev.keychar == UIEvent.Key_F11 && keys[i] == "F11") ||
					(ev.keychar == UIEvent.Key_F12 && keys[i] == "F12") ||
					(ev.keychar == UIEvent.Key_Del && keys[i] == "Del") ||
					(ev.keychar == UIEvent.Key_Escape && keys[i] == "Escape")
				)
				{ pressed = true; }
			}
			else if (keys[i].ByteAt(0) == keychar.ByteAt(0)) { pressed = true; }

			if (pressed)
			{
				if (type) { thismenu.MenuEvent(type, false); }
				return true;
			}
		}

		return false;
	}
}

class GetPsyched : WolfMenu
{
	TextureID back, statbar;
	int starttic, ticcount, step;

	int fadetarget;
	int fadetime;
	double fadealpha;
	int fadecolor;

	int curstate;

	override void Init(Menu parent)
	{
		Super.Init(parent);

		back = TexMan.CheckForTexture("PSYCH", TexMan.Type_Any);
		statbar = TexMan.CheckForTexture("PSYCHBAR", TexMan.Type_Any);

		if (Game.IsSoD() && level.levelnum % 100 == 21)
		{
			curstate = 6;
			fadealpha = 0.0;
			fadetarget = 0.0;
		}
		else
		{
			curstate = 0;
			fadealpha = 1.0;
			fadetime = 12;
			fadetarget = gametic;
			fadecolor = 0x000000;
		}

		starttic = gametic;

		DontDim = true;
	}

	override void Drawer()
	{
		if (curstate < 4)
		{
			screen.Dim(0x004040, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

			if (back)
			{
				Vector2 size = TexMan.GetScaledSize(back);

				int x = 160 - int(size.x / 2);
				int y = 100 - int(size.y);

				screen.DrawTexture(back, false, x, y, DTA_Clean, true);

				if (statbar && curstate > 0)
				{
					x += 6;
					y += int(size.y) - 4;

					for (int i = 0; i < step; i += 4)
					{
						screen.DrawTexture(statbar, false, x + i, y, DTA_Clean, true);
					}
				}
			}

			if (StatusBar is "ClassicStatusBar") { ClassicStatusBar(StatusBar).DrawClassicBar(false); }
		}

		screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
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

	override void Ticker()
	{
		switch (curstate)
		{
			case 0:
				ticcount++;
				if (ticcount == fadetime) { ticcount = 0; curstate++; fadecolor = 0x004040; }
				break;
			case 1:
				ticcount++;
				step = min(step + 12, 210);
				if (ticcount == 35) { ticcount = 0; curstate++; }
				break;
			case 2:
				ticcount++;
				if (ticcount == 5)
				{
					fadetarget = gametic + fadetime;
					curstate++;
				}
				break;
			case 3:
				if (gametic == fadetarget) { curstate++; }
				break;
			case 4:
				if (gametic == fadetarget + fadetime) { Close(); }
				break;
			case 5:
				if (ClassicStatusBar(StatusBar)) { ClassicStatusBar(StatusBar).ReverseFizzle(players[consoleplayer].mo); }
				Close();
				break;
			default:
				Close();
				break;
		}

		if (fadetime > 0 && (fadetarget || (fadetarget == 0 && starttic == 0)))
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}

		Super.Ticker();
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		return false;
	}
}

class DeathCamMessage : GetPsyched
{
	String text;
	Font IntermissionFont;

	int exittimeout;
	bool exitmenu;

	int timeout;

	override void Init(Menu parent)
	{
		Super.Init(parent);

		fadetarget = gametic + fadetime;
		timeout = 140;
		fadealpha = 0;

		text = StringTable.Localize("$DEATHCAM");
		IntermissionFont = Font.GetFont("IntermissionFont");

		DontDim = true;

		menuactive = Menu.OnNoPause;
	}

	override void Drawer()
	{
		switch (curstate)
		{
			case 0:
				screen.Dim(0x004040, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
				break;
			case 1:
				screen.Dim(0x004040, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());
				screen.DrawText(IntermissionFont, Font.CR_Untranslated, 160 - IntermissionFont.StringWidth(text) / 2, 56, text, DTA_320x200, true);
				break;
			default:
				break;
		}

		if (screenblocks < 11 && StatusBar is "ClassicStatusBar") { ClassicStatusBar(StatusBar).DrawClassicBar(false); }
	}

	override void Ticker()
	{
		WolfMenu.Ticker();

		ticcount++;

		switch (curstate)
		{
			case 0:
				if (ticcount == fadetime)
				{
					ticcount = 0; curstate++;
				}
				break;
			case 1:
				if (ticcount == timeout)
				{
					ticcount = 0;
					curstate++;
					fadetarget = gametic;
				}
				break;
			case 2:
				exitmenu = true;
				curstate++;
				break;
			default:
				break;
		}

		if (gametic > 1)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}

		if (exitmenu)
		{
			exittimeout++;

			if (exittimeout >= fadetime * 2)
			{
				Close();
			}
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		curstate = 2;

		return true;
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (type == MOUSE_Click)
		{
			return MenuEvent(MKEY_Enter, true);
		}

		return Super.MouseEvent(type, x, y);
	}
}

class Fader : GetPsyched
{
	override void Init(Menu parent)
	{
		Super.Init(parent);

		fadetarget = gametic + fadetime;
		fadealpha = 0;

		DontDim = true;

		menuactive = Menu.OnNoPause;
	}

	override void Drawer()
	{
		screen.Dim(0x000000, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		WolfMenu.Ticker();

		ticcount++;

		switch (curstate)
		{
			case 0:
				fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));

				if (ticcount == fadetime)
				{
					ticcount = 0; curstate++;

					if (!g_nointro) { Close(); }
				}
				break;
			case 1:
				fadealpha = 1.0;

				if (ticcount == 24)
				{
					ticcount = 0;
					curstate++;
					fadetarget = gametic;
				}
				break;
			case 2:
				ticcount = 0;
				fadetarget = gametic;
				curstate++;
				break;
			default:
				fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));

				if (ticcount == fadetime) { Close(); }
				break;
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		return false;
	}

	override bool MouseEvent(int type, int x, int y)
	{
		return false;
	}
}

class PauseMenu : WolfMenu
{
	TextureID pausepic;
	Vector2 size;

	override void Init(Menu parent)
	{
		Super.Init(parent);

		pausepic = TexMan.CheckForTexture("W_PAUSE", TexMan.Type_Any);
		if (pausepic) { size = TexMan.GetScaledSize(pausepic); }

		DontDim = true;
	}

	override void Drawer()
	{
		if (pausepic) { screen.DrawTexture(pausepic, false, 160 - size.x / 2, 100 - size.y / 2, DTA_320x200, true); }
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		Close();
		return true;
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (type == MOUSE_Click)
		{
			return MenuEvent(MKEY_Enter, true);
		}

		return Super.MouseEvent(type, x, y);
	}
}