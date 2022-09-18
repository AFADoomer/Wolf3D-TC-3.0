class ConsoleHandler : StaticEventHandler
{
	override void OnRegister()
	{
		CVar sodvar = CVar.FindCVar("g_sod");
		if (sodvar) { sodvar.SetInt(-2); }
	}

	override void UITick()
	{
		Canvas conbackcanvas = TexMan.GetCanvas("CONBACK");
		if (conbackcanvas)
		{
			conbackcanvas.Clear(0, 0, 800, 500, 0x000000);

			int size = 3;
			int steps = 64;
			for (int g = 0; g < steps; g ++)
			{
				int y = 498 - g * size;
				conbackcanvas.DrawThickLine(0, y, 800, y, size, Game.IsSoD() ? 0x0000DD : 0xDD0000, 64 - (g * 64 / steps));
			}

			TextureID logo = TexMan.CheckForTexture((Game.IsSoD() ? "Graphics/SoD.png" : "Graphics/Wolf3D.png"), TexMan.Type_Any);
			if (logo)
			{
				Vector2 size = TexMan.GetScaledSize(logo);
				conbackcanvas.DrawTexture(logo, true, 800 - size.x, 500 - size.y - 8, DTA_KeepRatio, true);
			}

			conbackcanvas.DrawText(SmallFont, Font.FindFontColor("TrueWhite"), 5 * CleanXfac_1, 500 - SmallFont.GetHeight() - 5 * CleanYfac_1, StringTable.Localize("$VERSION"));

			conbackcanvas.DrawThickLine(0, 498, 800, 498, size, Game.IsSoD() ? 0xDDDD00 : 0xDD0000);
			conbackcanvas.DrawLine(0, 499, 800, 499, 0x000000, 128);
		}
	}
}