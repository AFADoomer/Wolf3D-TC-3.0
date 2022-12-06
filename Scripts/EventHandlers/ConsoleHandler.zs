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

class ConsoleHandler : StaticEventHandler
{
	String gamestring;

	override void OnRegister()
	{
		String hash = "";

		// Show the last commit's hash if this is a beta release
		if (StringTable.Localize("$VERSION").IndexOf("beta") > -1)
		{
			hash = ReadFrom("Data/GitHash.txt");
			hash = " \c[Dark Gray]" .. hash.Left(7);
		}

		gamestring = String.Format("\c[True White]%s %s", StringTable.Localize("$VERSION"), hash);

		console.printf(gamestring);
	}

	ui void UpdateCanvas()
	{
		Canvas conbackcanvas = TexMan.GetCanvas("CONBACK");
		if (conbackcanvas)
		{
			int h = 768;
			int w = 1024;
			double fontscale = 2.0;

			Font fnt = SmallFont;

			int fontheight = fnt.GetHeight();
			int fontwidth = fnt.StringWidth("0");

			double wscale = w / double(Screen.GetWidth());

			conbackcanvas.Clear(0, 0, w, h, 0x000000);

			int size = 3;
			int steps = 64;
			for (int g = 0; g < steps; g ++)
			{
				int y = h - 2 - g * size;
				conbackcanvas.DrawThickLine(0, y, w, y, size, Game.IsSoD() ? 0x0000DD : 0xDD0000, 64 - (g * 64 / steps));
			}

			TextureID logo = TexMan.CheckForTexture((Game.IsSoD() ? "Graphics/SoD.png" : "Graphics/Wolf3D.png"), TexMan.Type_Any);
			if (logo)
			{
				Vector2 size = TexMan.GetScaledSize(logo);
				conbackcanvas.DrawTexture(logo, true, w - size.x * wscale, h - size.y - 8, DTA_ScaleX, wscale);
			}

			conbackcanvas.DrawText(fnt, Font.FindFontColor("TrueWhite"), 3, h - fontheight * fontscale - 3, gamestring, DTA_ScaleX, wscale * fontscale, DTA_ScaleY, fontscale);

			conbackcanvas.DrawThickLine(0, h - 2, w, h - 2, size, Game.IsSoD() ? 0xDDDD00 : 0xDD0000);
			conbackcanvas.DrawLine(0, h - 1, w, h - 1, 0x000000, 128);
		}
	}

	override void UITick()
	{
		if (consolestate != c_up) { UpdateCanvas(); }
	}

	String ReadFrom(String path)
	{
		int lump = -1;

		lump = Wads.CheckNumForFullName(path);

		if (lump > -1) { return Wads.ReadLump(lump); }

		return "";
	}
}