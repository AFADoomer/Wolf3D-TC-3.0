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

class ClassicMessageBox : MessageBoxMenu
{
	String prefix;
	Color fillcolor;
	TextureID top, bottom, left, right;
	TextureID topleft, topright, bottomleft, bottomright;

	String message;

	String cursor;
	int blinktime;
	int width, height;

	Font fnt;
	int alignment;

	override void Init(Menu parent, String msg, int messagemode, bool playsound, Name cmd, voidptr native_handler)
	{
		// Initialize everything through the real message box code
		Super.Init(parent, msg, messagemode, playsound, cmd, native_handler);

		message = msg;

		// Remove the hard-coded additional prompt message components
		message.Replace("\n\n" .. Stringtable.Localize("$DOSY"), "");
		message.Replace("\n\n" .. Stringtable.Localize("$PRESSKEY"), "");
		message.Replace("\n\n" .. Stringtable.Localize("$PRESSYN"), "");
		message.Replace(Stringtable.Localize("$PRESSYN"), ""); // For the save deletion prompt

		// Adjust quit messages to select SoD variants as appropriate
		// Randomly use either set on the game selection screen
		if (Game.IsSoD() && !(g_sod < 0 && Random(0, 1)))
		{
			for (int m = 1; m <= 9; m++)
			{
				if (message ~== StringTable.Localize("QUITMSG" .. m, false))
				{
					message = StringTable.Localize("QUITMSG" .. m + 9, false);
					break;
				}
			}
		}

		if (!prefix.Length()) { prefix = "BG_"; fillcolor = 0x8c8c8c; }
		if (!fnt) { fnt = BigFont; }

		top = TexMan.CheckForTexture(prefix .. "T", TexMan.Type_Any);
		bottom = TexMan.CheckForTexture(prefix .. "B", TexMan.Type_Any);
		left = TexMan.CheckForTexture(prefix .. "L", TexMan.Type_Any);
		right = TexMan.CheckForTexture(prefix .. "R", TexMan.Type_Any);
		topleft = TexMan.CheckForTexture(prefix .. "TL", TexMan.Type_Any);
		topright = TexMan.CheckForTexture(prefix .. "TR", TexMan.Type_Any);
		bottomleft = TexMan.CheckForTexture(prefix .. "BL", TexMan.Type_Any);
		bottomright = TexMan.CheckForTexture(prefix .. "BR", TexMan.Type_Any);

		DontDim = true;

		if (messagemode > 0) { blinktime = -1; }

		if (ExtendedListMenu(mParentMenu)) { ExtendedListMenu(mParentMenu).nodim = true; }
		if (ExtendedOptionMenu(mParentMenu)) { ExtendedOptionMenu(mParentMenu).nodim = true; }
	}

	static ClassicMessageBox PrintMessage(String text, String prefix = "B_", Color fillcolor = 0xFFFFFF, int style = 0, int width = -1, int height = -1, bool nocursor = true, int align = 0)
	{
		StartMessage(text, nocursor);

		ClassicMessageBox msg = ClassicMessageBox(GetCurrentMenu());
		msg.prefix = prefix;
		msg.fillcolor = fillcolor;

		if (width > 0) { msg.width = width * 8 + 16; }
		if (height > 0) { msg.height = height * 8 + 16; }

		switch (style)
		{
			case 1:
				msg.fnt = BigFont;
				break;
			case 2:
				msg.fnt = ConFont;
				break;
			default:
				msg.fnt = SmallFont;
				break;
		}

		msg.alignment = align;

		msg.Init(msg.mParentMenu, text, msg.mMessagemode);

		return msg;
	}

	override void Drawer()
	{
		if (mParentMenu) { mParentMenu.Drawer(); }
		DrawMessage(message);
	}

	void DrawMessage(String text, int size = 8, color clr = 0x8c8c8c)
	{
		if (!top || !bottom || !left || !right || !topleft || !topright || !bottomleft || !bottomright) { return; }

		int w = 0, h = 0;
		text = StringTable.Localize(text);

		if (fillcolor) { clr = fillcolor; }

		BrokenLines message = fnt.BreakLines(text, width > 0 ? width : 300);

		int c = message.Count();

		int fontheight = fnt.GetHeight();

		for (int i = 0; i < c; i++)
		{
			w = max(w, message.StringWidth(i) + (i == (c - 1) ? blinktime > -1 ? fnt.StringWidth("_") : 0 : 0));
			h += fontheight;
		}

		int textheight = h;

		w += 10;
		h += 10;

		w = max(w, width);// - 2 * size;
		h = max(h, height);// - 2 * size;

		int ws = w * CleanXfac;
		int hs = h * CleanYfac;

		int x = Screen.GetWidth() / 2 - ws / 2;
		int y = Screen.GetHeight() / 2 - hs / 2;

		x += int(size * CleanXfac);
		y += int(size / 2 * CleanYfac);
		ws -= int(2 * size * CleanXfac);
		hs -= int(2 * size * CleanYfac);

		screen.Dim(clr, 1.0, x, y, ws, hs);

		screen.DrawTexture(top, true, x, y - int(size * CleanYfac), DTA_CleanNoMove, true, DTA_DestWidth, ws, DTA_DestHeight, int(size * CleanYfac));
		screen.DrawTexture(bottom, true, x, y + hs, DTA_CleanNoMove, true, DTA_DestWidth, ws, DTA_DestHeight, int(size * CleanYfac));
		screen.DrawTexture(left, true, x - int(size * CleanXfac), y, DTA_CleanNoMove, true, DTA_DestWidth, int(size * CleanXfac), DTA_DestHeight, hs);
		screen.DrawTexture(right, true, x + ws, y, DTA_CleanNoMove, true, DTA_DestWidth, int(size * CleanXfac), DTA_DestHeight, hs);

		screen.DrawTexture(topleft, true, x - int(size * CleanXfac), y - int(size * CleanYfac), DTA_CleanNoMove, true, DTA_DestWidth, int(size * CleanXfac), DTA_DestHeight, int(size * CleanYfac));
		screen.DrawTexture(topright, true, x + ws, y - int(size * CleanYfac), DTA_CleanNoMove, true, DTA_DestWidth, int(size * CleanXfac), DTA_DestHeight, int(size * CleanYfac));
		screen.DrawTexture(bottomleft, true, x - int(size * CleanXfac), y + hs, DTA_CleanNoMove, true, DTA_DestWidth, int(size * CleanXfac), DTA_DestHeight, int(size * CleanYfac));
		screen.DrawTexture(bottomright, true, x + ws, y + hs, DTA_CleanNoMove, true, DTA_DestWidth, int(size * CleanXfac), DTA_DestHeight, int(size * CleanYfac));

		if (blinktime > -1 && gametic > blinktime)
		{
			if (cursor == "_") { cursor = ""; }
			else { cursor = "_"; }	

			blinktime = gametic + 5;
		}

		x = 160;
		y = 100 - textheight / 2 - fontheight / 2;
		for (int i = 0; i < c; i++)
		{
			int size = fnt.StringWidth(message.StringAt(i) .. (i == (c - 1) ? cursor : ""));
			x += alignment == 2 ? -size / 2 : alignment == 1 ? w / 2 - size - 4 : -w / 2 + 4;

			screen.DrawText(fnt, 0, x, y, "\c[TrueBlack]" .. message.StringAt(i) .. (i == (c - 1) ? cursor : ""), DTA_Clean, true);

			x = 160;
			y += fontheight;
		}
	}
}