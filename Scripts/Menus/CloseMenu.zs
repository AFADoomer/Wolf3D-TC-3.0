class CloseMenu : GenericMenu
{
	int fadetarget;
	int fadetime;
	double fadealpha;

	bool exitmenu;
	int exittimeout;

	override void Init(Menu parent)
	{
		Super.Init(parent);

		exitmenu = true;

		fadetime = 12;
		fadetarget = gametic + fadetime;
		fadealpha = 0.0;

		DontDim = true;
	}

	override void Ticker()
	{
		Super.Ticker();

		if (gametic > 1)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}

		if (exitmenu)
		{
			exittimeout++;

			if (exittimeout >= fadetime * 2)
			{
				if (mParentMenu) { mParentMenu.Close(); }
				Close();
			}
			else if (exittimeout >= fadetime)
			{
				if (gamestate != GS_LEVEL && gamestate != GS_INTERMISSION) { Menu.SetMenu("IntroSlideshowLoop"); }
				else if (players[consoleplayer].mo && LifeHandler.GetLives(players[consoleplayer].mo) == -1) { Menu.SetMenu("HighScores"); }
				else if (gamestate != GS_FINALE) { S_ChangeMusic(level.music); }
			}
		}
	}

	override void Drawer()
	{
		if (mParentMenu && exittimeout < fadetime) { mParentMenu.Drawer(); }
		screen.Dim(0x000000, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override bool MenuEvent(int mkey, bool fromcontroller) { return false; }
	override bool MouseEvent(int type, int x, int y) { return false; }
}