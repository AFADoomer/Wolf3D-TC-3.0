class ConsoleHandler : StaticEventHandler
{
	override void UITick()
	{
		Canvas conbackcanvas = TexMan.GetCanvas("CONBACK");
		if (conbackcanvas)
		{
			conbackcanvas.Clear(0, 0, 800, 500, 0x000000);

			TextureID logo = TexMan.CheckForTexture((g_sod ? "Graphics/SoD.png" : "Graphics/Wolf3D.png"), TexMan.Type_Any);
			if (logo)
			{
				Vector2 size = TexMan.GetScaledSize(logo);
				conbackcanvas.DrawTexture(logo, true, 800 - size.x, 500 - size.y - 8, DTA_KeepRatio, true);
			}
		}

		conbackcanvas.DrawText(SmallFont, Font.FindFontColor("TrueWhite"), 5 * CleanXfac_1, 500 - SmallFont.GetHeight() - 5 * CleanYfac_1, StringTable.Localize("$VERSION"));

		conbackcanvas.DrawThickLine(0, 498, 800, 498, 3, g_sod ? 0x0000DD : 0xDD0000);
		conbackcanvas.DrawLine(0, 499, 800, 499, 0x000000, 128);
	}
}