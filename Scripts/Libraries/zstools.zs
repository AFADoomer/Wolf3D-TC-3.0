/*
 * Copyright (c) 2018-2024 AFADoomer
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
		STR_FIXEDWIDTH = 256, // Print all characters at the width of the font's "0" character
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
				output = String.Format("%s%s", output, input.Mid(place, 1));
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

	enum PuncuationType
	{
		PUNC_DEFAULT = 0,
		PUNC_NUMBER = 1,
		PUNC_PATH = 2,
		PUNC_STRICT = 3,
	};

	static bool IsPunctuation(int c, int punctype = ZScriptTools.PUNC_DEFAULT)
	{
		bool ispunc;

		if (punctype == PUNC_NUMBER) { ispunc = (c < 0x30 || c > 0x3A); }
		else { ispunc = (punctype == PUNC_PATH ? false : ZScriptTools.IsWhiteSpace(c)) || (c >= 0x21 && c <= 0x2F || c >= 0x3A && c <= 0x40 || c >= 0x5B && c <= 0x60 || c >= 0x7B && c <= 0x7E); }

		if (!ispunc) { return false; }

		switch (punctype)
		{
			case PUNC_PATH: // allow "*./:<>?[\]^_`{|}~
				if (c == 0x22 || c == 0x2A || c == 0x2E || c == 0x2F || c == 0x3A || c == 0x3C || c == 0x3E || c == 0x3F || c >= 0x5B && c <= 0x60 || c >= 0x7B && c <= 0x7E) { return false; }
				break;
			case PUNC_NUMBER: // allow +-.
				if (c == 0x2B || c == 0x2D || c == 0x2E) { return false; }
				break;
			case PUNC_DEFAULT: // allow [\]^_`{|}~
				if (c >= 0x5B && c <= 0x60 || c >= 0x7B && c <= 0x7E) { return false; }
			default:
				break;
		}

		return true;
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

	static String GetText(String input)
	{
		return ZScriptTools.StripColorCodes(ZScriptTools.Trim(input));
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

	// Returns the scale necessary to cleanly resize an image to fit into a box of a specific size
	static Vector2, Vector2 ScaleTextureTo(TextureID tex, int size = 16)
	{
		Vector2 texsize = TexMan.GetScaledSize(tex);
		Vector2 imagesize = texsize;
		double ratio = 1.0;

		if (texsize.x > size || texsize.y > size)
		{
			if (texsize.y > texsize.x) { ratio = size / texsize.y; }
			else { ratio = size / texsize.x; }

			imagesize *= ratio;
		}

		return (ratio, ratio), imagesize;
	}

	// Returns the best text color match for the passed-in RGB color
	// Modified from gzdoom/src/common/utility/palette.cpp
	// static String BestTextColor(Color clr)
	// {
	// 	DataHandler data = DataHandler(StaticEventHandler.Find("DataHandler"));
	// 	if (!data) { return "L"; }

	// 	int bestcolor = 0;
	// 	int bestdist = 257 * 257 + 257 * 257 + 257 * 257;

	// 	for (int p = 0; p < data.textcolordata.children.Size(); p++)
	// 	{
	// 		Color palentry = ZScriptTools.HexStrToInt(data.textcolordata.children[p].value);
	// 		int x = clr.r - palentry.r;
	// 		int y = clr.g - palentry.g;
	// 		int z = clr.b - palentry.b;
	// 		int dist = x * x + y * y + z * z;
	// 		if (dist < bestdist)
	// 		{
	// 			if (dist == 0) { return String.Format("[%s]", data.textcolordata.children[p].keyname); }

	// 			bestdist = dist;
	// 			bestcolor = p;
	// 		}
	// 	}

	// 	return String.Format("[%s]", data.textcolordata.children[bestcolor].keyname);
	// }

	static int HexStrToInt(String input)
	{
		int output;

		input = input.MakeUpper();

		for (uint i = 0; i < input.Length(); i++)
		{		
			int index = input.Mid(i, 1).ToInt();

			if (!(input.Mid(i, 1) == "0") && !index)
			{
				index = input.ByteAt(i) - 55;
				if (index > 15) { return -1; }
			}

			if (index < 0) { return -1; }

			int multiplier = 1;
			for (uint j = 0; j < input.Length() - i - 1; j++)
			{
				multiplier *= 16;
			}

			output += multiplier * index;
		}

		return output;
	}

	static String, int GetWord(String input, int punctype = ZScriptTools.PUNC_DEFAULT, int end = -1)
	{
		String output = "";
		input = ZScriptTools.Trim(input);

		uint c, t;
		[c, t] = input.GetNextCodePoint(0);

		while (!ZScriptTools.IsPunctuation(c, punctype) && (end < 0 || c != end) && t <= input.length())
		{
			output = String.Format("%s%c", output, c);
			[c, t] = input.GetNextCodePoint(t);
		}

		return ZScriptTools.Trim(output), t;
	}

	static int, int GetNumber(String input)
	{
		while (input.left(1) == " ") { input = input.mid(1); }

		String output;
		int next;
		[output, next] = GetWord(input, ZScriptTools.PUNC_NUMBER);

		return output.ToInt(), next;
	}

	// Function to find the shortest distance between an actor and a line
	//
	// Returns:	Shortest distance between the given actor and line
	//			Position of the closest point on the line to the given actor
	//
	// Adapted from https://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
	play static double, Vector2 DistanceFromLine(Actor mo, Line l)
	{
		if (!l || !mo) { return 0, (0, 0); }

		Vector2 v1, v2, delta, point;

		v1 = l.v1.p;
		v2 = l.v2.p;
		delta = l.delta;
		point = mo.pos.xy;

		double lengthsquared = (v2 - v1).length() ** 2;

		if (!lengthsquared) { return (v1 - point).length(), v1; }

		double t = clamp((point - v1) dot delta / lengthsquared, 0, 1);
		Vector2 projection = v1 + t * delta;

		return (point - projection).length(), projection;
	}

	// Function to find the closest line that an actor is touching
	//
	// Returns:	Line closest to actor centerpoint
	//			Perpendicular distance from the line to the actor
	//			Closest point on the line to the actor
	play static Line, double, Vector2 GetCurrentLine(Actor mo)
	{
		Line linedef = null;
		double dist;
		Vector2 projection;

		BlockLinesIterator it = BlockLinesIterator.Create(mo);

		double radius = mo.radius;
		if (!radius) { radius = 1; }

		While (it.Next())
		{
			Line current = it.curline;

			// Discard lines that are outside of the actor's radius
			if (
				(current.v1.p.x > mo.pos.x + radius && current.v2.p.x > mo.pos.x + radius) ||
				(current.v1.p.x < mo.pos.x - radius && current.v2.p.x < mo.pos.x - radius) ||
				(current.v1.p.y > mo.pos.y + radius && current.v2.p.y > mo.pos.y + radius) ||
				(current.v1.p.y < mo.pos.y - radius && current.v2.p.y < mo.pos.y - radius) 
			) { continue; }

			// Find the line that is closest to the actor's center point
			double curdist;
			Vector2 curprojection;
			[curdist, curprojection] = ZScriptTools.DistanceFromLine(mo, current);
			if (!linedef || curdist <= dist)
			{
				linedef = current;
				dist = curdist;
				projection = curprojection;
			}
		}

		return linedef, dist, projection;		
	}

	play static Line AlignToLine(Actor mo, double offsetamount = 0.1)
	{
		if (!mo) { return null; }

		double dist;
		Line linedef;
		Vector2 projection;
		[linedef, dist, projection] = ZScriptTools.GetCurrentLine(mo);

		if (linedef)
		{
			Vector2 offset = mo.pos.xy - projection;
			Vector3 newpos;

			if (offset.length())
			{
				offset = offset.Unit() * offsetamount;
				newpos = ((projection + offset), mo.pos.z);
			}
			else { newpos = mo.Vec3Angle(offsetamount, mo.angle); }

			mo.SetXYZ(newpos);
		}

		return linedef;
	}

	clearscope static bool IsCoop(void)
	{
		return (multiplayer && !deathmatch);
	}

	static TextureID FullPathTexture(TextureID tex)
	{
		String texname = TexMan.GetName(tex);

		if (texname.IndexOf("/") == -1)
		{
			int lump = Wads.CheckNumForName(texname, Wads.ns_newtextures);
			texname = Wads.GetLumpFullName(lump);
			tex = TexMan.CheckForTexture(texname, TexMan.Type_Any);
		}

		return tex;
	}

	static bool IsSameTexture(TextureID tex, TextureID tex2)
	{
		if (!tex.IsValid() || !tex2.IsValid()) { return false; }
		if (tex == tex2) { return true; }

		tex = ZScriptTools.FullPathTexture(tex);
		tex2 = ZScriptTools.FullPathTexture(tex2);

		return tex == tex2;
	}
}