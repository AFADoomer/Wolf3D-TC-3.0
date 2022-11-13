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
		if (!p) { return false; }

		int playernum = p.PlayerNumber();
		if (playernum < 0) { return false; }

		LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
		if (!this || !this.died[playernum]) { return false; }

		this.died[playernum] = false;

		return true;
	}

	static void TakeLife(Actor p, int count = 1)
	{
		if (!p) { return; }

		int playernum = p.PlayerNumber();
		if (playernum < 0) { return; }

		LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
		if (!this) { return; }

		this.lives[playernum] = max(this.lives[playernum] - count, -1);

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
		Level.MakeAutoSave();
		if (died[e.playernumber])
		{
			players[e.playernumber].mo.ClearInventory();
			
			ResetWeapons(e.playernumber);
		}
	}

	static void ResetWeapons(int p)
	{
		if (g_sod < 2)
		{
			players[p].mo.GiveInventory("WolfKnife", 1);
			players[p].mo.GiveInventory("WolfPistol", 1);
		}
		else
		{
			players[p].mo.GiveInventory("WolfKnifeLost", 1);
			players[p].mo.GiveInventory("WolfPistolLost", 1);
		}
	}

	override void PlayerDied(PlayerEvent e)
	{
		died[e.playernumber] = true;
		TakeLife(players[e.playernumber].mo, 1);
	}

	override void NewGame()
	{
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (died[i]) { continue; } // Don't reset lives if we just died

			lives[i] = 3;
		}

		SaveLifeData();
	}

	override void WorldThingDied(WorldEvent e)
	{
		if (!e.thing.target || e.thing.target == e.thing) { return;} // Don't give points if you kill yourself

		int amt;

		if (e.thing is "ClassicBase") { amt = ClassicBase(e.thing).scoreamt; }
		else if (e.thing is "PlayerPawn") { amt = 2500; }
		else { amt = e.thing.SpawnHealth() * 10; }

		e.thing.A_GiveToTarget("Score", amt);
	}
	
	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name == "resetdeaths")
		{
			LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
			if (this)
			{
				for (int i = 0; i < MAXPLAYERS; i++)
				{
					this.died[i] = false;
				}
			}
		}
	}
}