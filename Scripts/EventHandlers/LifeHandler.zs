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

	override void PlayerEntered(PlayerEvent e)
	{
		// This *must* be done so that if a player has autosave disabled, the 
		// NewGame call doesn't get called every time the player respawns
		Level.MakeAutoSave();
	}

	override void NewGame()
	{
		if (!persistent) { persistent = PersistentLifeHandler(EventHandler.Find("PersistentLifeHandler")); }

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (died[i]) { continue; }

			lives[i] = 3;
			if (persistent) { persistent.lives[i] = 3; }
		}
	}

	override void WorldThingDied(WorldEvent e)
	{
		int amt;

		if (e.thing is "ClassicBase") { amt = ClassicBase(e.thing).scoreamt; }
		else if (e.thing is "PlayerPawn") { amt = 2500; }
		else { amt = e.thing.SpawnHealth() * 10; }

		e.thing.A_GiveToTarget("Score", amt);
	}
}