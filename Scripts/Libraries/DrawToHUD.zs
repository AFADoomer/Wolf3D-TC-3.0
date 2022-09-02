/*

	Helper function to translate HUD-style coordinates to screen-space coordinates so 
	that you can use Screen drawing functions to draw elements that align with the HUD.

	TranslatetoHUDCoordinates takes two parameters:
	- Vector2 of the HUD x/y coordinates that you want to position something at
	- Vector2 of the desired width/height of the image in HUD-scaled pixels

	The function returns two Vector2 values:
	- Vector2 of the x/y screen coordinates equivalent to the HUD coordinates passed in
	- Vector2 of the screen-scaled width/height of the image


	Also includes wrapper functions to draw textures and shape textures using the
	coordinate translation function (both draw the texture centered at the coords).
*/
class DrawToHUD
{
	enum offsets
	{
		left,
		right,
		center,
	};

	enum verticaloffsets
	{
		top,
		middle,
		bottom,
	};

	// Scale coordinates and size to screen space, using rules simliar to the hud sizing/scaling rules
	static ui Vector2, Vector2 TranslatetoHUDCoordinates(Vector2 pos, Vector2 size = (0, 0), int hoffset = left, int voffset = top, bool checkfullscreen = false)
	{
		if (checkfullscreen && !Statusbar.fullscreenoffsets)
		{
			double x, y, w, h;
			[x, y, w, h] = Statusbar.StatusbarToRealCoords(pos.x, pos.y, size.x, size.y);

			return (x, y), (w, h);
		}

		// Get the scale being used by the HUD code
		Vector2 hudscale = Statusbar.GetHudScale();

		// Scale the texture and coordinates to match the HUD elements
		Vector2 screenpos, screensize;

		screenpos.x = pos.x * hudscale.x;
		screenpos.y = pos.y * hudscale.y;

		screensize.x = size.x * hudscale.x;
		screensize.y = size.y * hudscale.y;

		// Allow HUD coordinate-style positioning (not the decimal part, just that negatives mean offset from right/bottom)
		if (pos.x < 0) { screenpos.x += Screen.GetWidth(); }
		else if (hoffset == right) { screenpos.x = Screen.GetWidth() - screenpos.x; }
		else if (hoffset == center) { screenpos.x += Screen.GetWidth() / 2; }

		if (pos.y < 0) { screenpos.y += Screen.GetHeight(); }
		else if (voffset == bottom) { screenpos.y = Screen.GetHeight() - screenpos.y; }
		else if (voffset == middle) { screenpos.y += Screen.GetHeight() / 2; }

		return screenpos, screensize;
	}

	static ui void SetClipRect(double x, double y, double w, double h, int hoffset = left, int voffset = top, bool checkfullscreen = false)
	{
		Vector2 screenpos, screensize;
		[screenpos, screensize] = TranslatetoHUDCoordinates((x, y), (w, h), hoffset, voffset, checkfullscreen);

		Screen.SetClipRect(int(screenpos.x), int(screenpos.y), int(screensize.x), int(screensize.y));
	}

	static ui void DrawText(String text, Vector2 pos, Font fnt = null, double alpha = 1.0, double scale = 1.0, color shade = -1, int textoffset = left, int hoffset = left, int voffset = top, bool checkfullscreen = false)
	{
		if (!fnt) { fnt = SmallFont; }

		Vector2 hudscale = Statusbar.GetHudScale();

		double width = Screen.GetWidth();
		double height = Screen.GetHeight();

		// Scale the coordinates
		Vector2 screenpos, screensize;
		[screenpos, screensize] = TranslatetoHUDCoordinates(pos, (width * hudscale.x, height * hudscale.y), hoffset, voffset, checkfullscreen);

		hudscale *= scale;

		width /= hudscale.x;
		height /= hudscale.y;
		screenpos.x = screenpos.x / hudscale.x;
		screenpos.y = screenpos.y / hudscale.y;

		//Do offset handling...
		switch (textoffset)
		{
			case 1:
				screenpos.x -= fnt.StringWidth(text);
				break;
			case 2:
				screenpos.x -= fnt.StringWidth(text) / 2;
				break;
			default:
				break;
		}

		// Draw the text
		screen.DrawText(fnt, shade, screenpos.x, screenpos.y, text, DTA_KeepRatio, true, DTA_Alpha, alpha, DTA_VirtualWidthF, width, DTA_VirtualHeightF, height);
	}

	static ui void DrawTexture(TextureID tex, Vector2 pos, double alpha = 1.0, double scale = 1.0, color shade = -1, int hoffset = left, int voffset = top, bool checkfullscreen = false)
	{
		// Scale the coordinates
		Vector2 screenpos, screensize;
		[screenpos, screensize] = TranslatetoHUDCoordinates(pos, TexMan.GetScaledSize(tex) * scale, hoffset, voffset, checkfullscreen);

		bool alphachannel;
		color fillcolor;

		if (shade > 0)
		{
			alphachannel = true;
			fillcolor = shade & 0xFFFFFF;
		}

		// Draw the texture
		screen.DrawTexture(tex, false, screenpos.x, screenpos.y, DTA_DestWidth, int(screensize.x), DTA_DestHeight, int(screensize.y), DTA_Alpha, alpha, DTA_CenterOffset, true, DTA_AlphaChannel, alphachannel, DTA_FillColor, shade);
	}

	static ui void DrawShapeTexture(TextureID tex, Vector2 pos, double alpha = 1.0, double ang = 0, double scale = 1.0, color shade = -1, int hoffset = left, int voffset = top, bool checkfullscreen = false)
	{
		// Scale the coordinates
		Vector2 screenpos, screensize;
		[screenpos, screensize] = TranslatetoHUDCoordinates(pos, TexMan.GetScaledSize(tex) * scale, hoffset, voffset, checkfullscreen);

		bool alphachannel;
		color fillcolor;

		if (shade > 0)
		{
			alphachannel = true;
			fillcolor = shade & 0xFFFFFF;
		}

		// Make 2D shape
		let shape = ShapeUtil.MakeSquare();

		// Draw rotated texture
		ShapeUtil.MoveSquare(shape, screensize, screenpos, ang);
		Screen.DrawShape(tex, false, shape, DTA_Alpha, alpha, DTA_AlphaChannel, alphachannel, DTA_FillColor, shade);
	}
}