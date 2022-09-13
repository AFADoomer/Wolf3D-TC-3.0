class PersistentLifeHandler : EventHandler
{
	int lives[MAXPLAYERS];
}

class LifeHandler : StaticEventHandler
{
	int lives[MAXPLAYERS];
	bool died[MAXPLAYERS];
	PersistentLifeHandler persistent;

	ui static int GetLives(Actor p)
	{
		if (!p) { return 0; }

		int playernum = p.PlayerNumber();
		if (playernum < 0) { return 0; }

		LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
		if (!this) { return 0; }

		return this.lives[playernum];
	}

	static bool JustDied(Actor p)
	{
		if (!p) { return 0; }

		int playernum = p.PlayerNumber();
		if (playernum < 0) { return 0; }

		LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
		if (!this) { return 0; }

		bool died = this.died[playernum];

		this.died[playernum] = false;

		return died;
	}

	static void TakeLife(Actor p, int count = 1)
	{
		if (!p) { return; }

		int playernum = p.PlayerNumber();
		if (playernum < 0) { return; }

		LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
		if (!this) { return; }

		this.lives[playernum] = max(this.lives[playernum] - count, -1);
		this.died[playernum] = true;

		this.SaveLifeData();
	}

	static void SetLives(Actor p, int count = 1)
	{
		if (!p) { return; }

		int playernum = p.PlayerNumber();
		if (playernum < 0) { return; }

		LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
		if (!this) { return; }

		this.lives[playernum] = clamp(count, 0, 9);

		this.SaveLifeData();
	}

	static void GiveLife(Actor p, int count = 1)
	{
		if (!p) { return; }

		int playernum = p.PlayerNumber();
		if (playernum < 0) { return; }

		LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
		if (!this) { return; }

		this.lives[playernum] = min(this.lives[playernum] + count, 9);

		this.SaveLifeData();
	}

	override void WorldLoaded(WorldEvent e)
	{
		if (e.IsSaveGame) // If loading a save, check for saved stats and copy them over if found
		{
			if (!persistent) { persistent = PersistentLifeHandler(EventHandler.Find("PersistentLifeHandler")); }
			if (persistent)
			{
				for (int i = 0; i < MAXPLAYERS; i++)
				{
					lives[i] = persistent.lives[i];
				}
			}
		}

		SaveLifeData();
	}

	void SaveLifeData()
	{
		if (!persistent) { persistent = PersistentLifeHandler(EventHandler.Find("PersistentLifeHandler")); }
		if (persistent)
		{
			for (int i = 0; i < MAXPLAYERS; i++)
			{
				persistent.lives[i] = lives[i];
			}
		}
	}

	override void NewGame()
	{
		if (!persistent) { persistent = PersistentLifeHandler(EventHandler.Find("PersistentLifeHandler")); }

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			lives[i] = 3;
			if (persistent) { persistent.lives[i] = 3; }
		}
	}

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