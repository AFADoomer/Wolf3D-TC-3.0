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