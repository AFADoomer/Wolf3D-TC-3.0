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

class ZScriptTools
{
	enum StringPosition
	{
		STR_LEFT = 0,
		STR_RIGHT = 1,
		STR_CENTERED = 2,
		STR_TOP = 4,
		STR_BOTTOM = 8,
		STR_MIDDLE = 16,
		STR_FIXED = 32, // Print directly on screen, not in hud coordinate space
		STR_MENU = 64, // Print in menu coordinate space (only implemented for key buttons)
		STR_NOSCALE = 128, // Don't recalculate coordinates
	};

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

	static bool IsWhitespace(int c)
	{
		switch (c)
		{
			// Reference https://en.wikipedia.org/wiki/Whitespace_character
			case 0x0009:
			case 0x000A:
			case 0x000B:
			case 0x000C:
			case 0x000D:
			case 0x0020:
			case 0x0085: 
			case 0x00A0:
			case 0x1680:
			case 0x2000:
			case 0x2001:
			case 0x2002:
			case 0x2003:
			case 0x2004:
			case 0x2005:
			case 0x2006:
			case 0x2007:
			case 0x2008:
			case 0x2009:
			case 0x200A:
			case 0x2028:
			case 0x2029:
			case 0x202F:
			case 0x205F:
			case 0x3000:
				return true;
			default:
				return false;
		}
	}

	static String StripControlCodes(String input)
	{
		String output = "";
		input = ZScriptTools.StripColorCodes(input); // Special handling to also remove the color index or string name

		int i = 0;
		int c = -1;

		while (c != 0)
		{
			[c, i] = input.GetNextCodePoint(i);
			if (
				(c > 0x001F && c < 0x007F) || // Skip C0 characters (ASCII Control Codes)
				(c > 0x007F && c < 0x0080) || // Skip Delete (ASCII Delete)
				c > 0x009F // Skip C1 characters (UNICODE-specific control codes)
			) { output.AppendCharacter(c); }
		}

		return output;
	}

	static String Trim(String input)
	{
		if (input.Length() < 1) { return ""; }

		String output = input;

		while (ZScriptTools.IsWhiteSpace(output.GetNextCodePoint(0))) { output.Remove(0, 1); }
		while (ZScriptTools.IsWhiteSpace(output.GetNextCodePoint(output.CodePointCount() - 1))) { output.DeleteLastCharacter(); }

		return output;
	}

	static String, bool GetKeyPressString(String bind, bool required = false, String keycolor = "Gold", String textcolor = "Untranslated", String errorcolor = "Dark Red")
	{
		keycolor = "\c[" .. keycolor .. "]";
		textcolor = "\c[" .. textcolor .. "]";
		errorcolor = "\c[" .. errorcolor .. "]";

		Array<int> keycodes;
		bool ret = true;

		// Look up key binds for the passed-in command
		Bindings.GetAllKeysForCommand(keycodes, bind);

		String keynames = "";
		if (keycodes.Size())
		{
			// Get the key names for each bound key, and parse them into a lookup array
			keynames = Bindings.NameAllKeys(keycodes);
			keynames = ZScriptTools.StripColorCodes(keynames);

			int index = keynames.RightIndexOf(", ");
			if (index > -1)
			{
				keynames = keynames.left(index) .. " " .. textcolor .. StringTable.Localize("$WORD_OR") .. " " .. keycolor .. keynames.mid(index + 2);
				keynames.Replace(", ", textcolor .. ", " .. keycolor);
			}

		}

		// If the bind is an inventory use command, append '<activate item>' to the string
		String suffix = "";
		if (bind.Left(3) ~== "use")
		{
			suffix = " " .. StringTable.Localize("$WORD_OR") .. keycolor .. " <" .. StringTable.Localize("$CNTRLMNU_USEITEM") .. ">" .. textcolor;
			suffix.MakeLower();
		}

		if (required && !keynames.length())
		{
			String actionname = ZScriptTools.GetActionName(bind);

			return errorcolor .. "<" .. StringTable.Localize("$BINDKEY") .. " " .. textcolor .. actionname .. errorcolor .. ">" .. textcolor .. suffix, false;
		}
		else
		{
			if (keynames.length()) { keynames = keycolor .. keynames .. textcolor .. suffix; }
		}

		return keynames, true;
	}

	static String GetActionName(String actionname, String prefix = "$CNTRLMNU_")
	{
		String output = "";
		String rawactionname = actionname;

		if (actionname.Left(1) == "+") { actionname = actionname.Mid(1); }
		if (actionname.Left(3) == "am_") { actionname = actionname.Mid(3); }

		// Special handling for native items that don't follow the naming pattern
		if (actionname ~== "left") { output = "$CNTRLMNU_TURNLEFT"; }
		else if (actionname ~== "right") { output = "$CNTRLMNU_TURNRIGHT"; }
		else if (actionname ~== "mlook") { output = "$CNTRLMNU_MOUSELOOK"; }
		else if (actionname ~== "klook") { output = "$CNTRLMNU_KEYBOARDLOOK"; }
		else if (actionname ~== "speed") { output = "$CNTRLMNU_RUN"; }
		else if (actionname ~== "toggle cl_run") { output = "$CNTRLMNU_TOGGLERUN"; }
		else if (actionname ~== "showscores") { output = "$CNTRLMNU_SCOREBOARD"; }
		else if (actionname ~== "messagemode") { output = "$CNTRLMNU_SAY"; }
		else if (actionname ~== "messagemode2") { output = "$CNTRLMNU_TEAMSAY"; }
		else if (actionname ~== "weapnext") { output = "$CNTRLMNU_NEXTWEAPON"; }
		else if (actionname ~== "weapprev") { output = "$CNTRLMNU_PREVIOUSWEAPON"; }
		else if (actionname.Left(5) ~== "slot ") { output = "$CNTRLMNU_SLOT" .. actionname.Mid(5); }
		else if (actionname.Left(4) ~== "user") { output = "$CNTRLMNU_USER" .. actionname.Mid(4); }
		else if (actionname ~== "invuse") { output = "$CNTRLMNU_USEITEM"; }
		else if (actionname ~== "invuseall") { output = "$CNTRLMNU_USEALLITEMS"; }
		else if (actionname ~== "invnext") { output = "$CNTRLMNU_NEXTITEM"; }
		else if (actionname ~== "invprev") { output = "$CNTRLMNU_PREVIOUSITEM"; }
		else if (actionname ~== "invdrop") { output = "$CNTRLMNU_DROPITEM"; }
		else if (actionname ~== "invquery") { output = "$CNTRLMNU_QUERYITEM"; }
		else if (actionname ~== "weapdrop") { output = "$CNTRLMNU_DROPWEAPON"; }
		else if (actionname ~== "togglemap") { output = "$CNTRLMNU_AUTOMAP"; }
		else if (actionname ~== "chase") { output = "$CNTRLMNU_CHASECAM"; }
		else if (actionname ~== "spynext") { output = "$CNTRLMNU_COOPSPY"; }
		else if (actionname ~== "toggleconsole") { output = "$CNTRLMNU_CONSOLE"; }
		else if (actionname ~== "sizeup") { output = "$CNTRLMNU_DISPLAY_INC"; }
		else if (actionname ~== "sizedown") { output = "$CNTRLMNU_DISPLAY_DEC"; }
		else if (actionname ~== "togglemessages") { output = "$CNTRLMNU_TOGGLE_MESSAGES"; }
		else if (actionname ~== "bumpgamma") { output = "$CNTRLMNU_ADJUST_GAMMA"; }
		else if (actionname ~== "menu_help") { output = "$CNTRLMNU_OPEN_HELP"; }
		else if (actionname ~== "menu_save") { output = "$CNTRLMNU_OPEN_SAVE"; }
		else if (actionname ~== "menu_load") { output = "$CNTRLMNU_OPEN_LOAD"; }
		else if (actionname ~== "menu_options") { output = "$CNTRLMNU_OPEN_OPTIONS"; }
		else if (actionname ~== "menu_display") { output = "$CNTRLMNU_OPEN_DISPLAY"; }
		else if (actionname ~== "menu_endgame") { output = "$CNTRLMNU_EXIT_TO_MAIN"; }
		else if (actionname ~== "menu_quit") { output = "$CNTRLMNU_MENU_QUIT"; }
		else if (actionname ~== "showpopup 1") { output = "$CNTRLMNU_MISSION"; }
		else if (actionname ~== "showpopup 2") { output = "$CNTRLMNU_KEYS"; }
		else if (actionname ~== "showpopup 3") { output = "$CNTRLMNU_STATS"; }
		else if (actionname ~== "gobig") { output = "$MAPCNTRLMNU_TOGGLEZOOM"; }
		else if (actionname ~== "toggle am_rotate") { output = "$MAPCNTRLMNU_ROTATE"; }
		else if (actionname ~== "clearmarks") { output = "$MAPCNTRLMNU_CLEARMARK"; }
		else if (rawactionname ~== "crouch") { output = "$CNTRLMNU_TOGGLECROUCH"; }
		else { output = prefix .. actionname; }

		output = StringTable.Localize(output);

		// Fall back to displaying the bind information if no string was found.
		if (output.left(prefix.length() - 1) ~== prefix.Mid(1)) { output = rawactionname; }

		return output;
	}
}