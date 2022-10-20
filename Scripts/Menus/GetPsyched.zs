class WolfMenu : GenericMenu
{
	static void SetMenu(Actor caller, Name mnu, int param = 0)
	{
		if (players[consoleplayer].mo != caller) { return; }

		Menu.SetMenu(mnu, param);
	}

	// Strip color codes out of a string
	static String StripColorCodes(String input)
	{
		int place = 0;
		int len = input.length();
		String output;

		while (place < len)
		{
			if (!(input.Mid(place, 1) == String.Format("%c", 0x1C)))
			{
				output = output .. input.Mid(place, 1);
				place++;
			}
			else if (input.Mid(place + 1, 1) == "[")
			{
				place += 2;
				while (place < len - 1 && !(input.Mid(place, 1) == "]")) { place++; }
				if (input.Mid(place, 1) == "]") { place++; }
			}
			else
			{
				if (place + 1 < len - 1) { place += 2; }
				else break;
			}
		}

		return output;
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
		keynames = StripColorCodes(keynames);

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

		curstate = 0;
		fadealpha = 1.0;
		fadetime = 12;
		fadetarget = gametic;
		fadecolor = 0x000000;

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
				step = min(step + 8, 210);
				if (ticcount == 35) { ticcount = 0; curstate++; }
				break;
			case 2:
				ticcount++;
				if (ticcount == 35)
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
			default:
				break;
		}

		if (fadetarget || (fadetarget == 0 && starttic == 0))
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
			case 2:
			default:
				screen.Dim(0x004040, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
				break;
		}

		if (StatusBar is "ClassicStatusBar") { ClassicStatusBar(StatusBar).DrawClassicBar(false); }
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
				fadetarget = gametic;
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