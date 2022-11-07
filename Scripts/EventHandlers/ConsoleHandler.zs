class ConsoleHandler : StaticEventHandler
{
	String hash;

	ui void UpdateCanvas()
	{
		Canvas conbackcanvas = TexMan.GetCanvas("CONBACK");
		if (conbackcanvas)
		{
			int h = 768;
			int w = 1024;
			double scale = 0.5;

			Font fnt = SmallFont;

			int fontheight = fnt.GetHeight();
			int fontwidth = fnt.StringWidth("0");
			String gametitle = StringTable.Localize("$VERSION") .. hash;

			double ratio = Screen.GetAspectRatio();
			int vh, vw;

			if (h >= w)
			{
				vh = int(w / ratio);
				vw = w;
			}
			else
			{
				vw = int(h * ratio);
				vh = h;
			}

			vw = int(vw * scale);
			vh = int(vh * scale);

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
				conbackcanvas.DrawTexture(logo, true, vw - size.x, vh - size.y - 8, DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);
			}

			conbackcanvas.DrawText(fnt, Font.FindFontColor("TrueWhite"), 3, vh - fontheight - 3, gametitle, DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);

			conbackcanvas.DrawThickLine(0, h - 2, w, h - 2, size, Game.IsSoD() ? 0xDDDD00 : 0xDD0000);
			conbackcanvas.DrawLine(0, h - 1, w, h - 1, 0x000000, 128);
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		// Show the last commit's hash if this is a beta release
		if (StringTable.Localize("$VERSION").IndexOf("beta") > -1)
		{
			hash = ReadFrom("Data/GitHash.txt");
			hash = " \c[Dark Gray]" .. hash.Left(7);
		}

		Super.WorldLoaded(e);
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