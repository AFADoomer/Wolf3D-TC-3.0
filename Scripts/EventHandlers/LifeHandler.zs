
class PersistentLifeHandler : EventHandler
{
	int lives[MAXPLAYERS];
	bool died[MAXPLAYERS];
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

	static bool JustDied(Actor p, int playernum)
	{
		if (playernum < 0) { return false; }

		LifeHandler this = LifeHandler(StaticEventHandler.Find("LifeHandler"));
		if (!this || !this.died[playernum]) { return false; }

		this.died[playernum] = false;
		this.SaveLifeData();

		return true;
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
		bool firstlevel = !!(level.levelnum % 100 == 1);

		if (e.IsSaveGame || firstlevel)
		{
			if (!persistent) { persistent = PersistentLifeHandler(EventHandler.Find("PersistentLifeHandler")); }

			if (level.time > 35) // If loading a save that (likely) wasn't an autosave, check for saved stats and copy them over if found
			{
				if (persistent)
				{
					for (int i = 0; i < MAXPLAYERS; i++)
					{
						lives[i] = persistent.lives[i];
						died[i] = persistent.died[i];

						if (playeringame[i] && players[i].mo)
						{
							players[i].mo.ACS_NamedExecuteAlways("InitializePlayer", 0, i);
						}
					}
				}
			}
			else // Otherwise this is an autosave, so treat as if the player died and respawned
			{
				for (int i = 0; i < MAXPLAYERS; i++)
				{
					died[i] = died[i] || e.IsSaveGame;

					if (playeringame[i] && players[i].mo)
					{
						players[i].mo.ClearInventory();
						players[i].mo.GiveDefaultInventory();

						players[i].mo.ACS_NamedExecuteAlways("InitializePlayer", 0, i);
					}
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
				if (playeringame[i])
				{
					persistent.lives[i] = lives[i];
					persistent.died[i] = died[i];
				}
			}
		}
	}

	override void PlayerRespawned(PlayerEvent e)
	{
		players[e.playernumber].mo.ClearInventory();
		players[e.playernumber].mo.GiveDefaultInventory();
	}

	override void PlayerEntered(PlayerEvent e)
	{
		if (!persistent) { persistent = PersistentLifeHandler(EventHandler.Find("PersistentLifeHandler")); }
		if (persistent)
		{
			persistent.lives[e.playernumber] = lives[e.playernumber];
		}

		Level.MakeAutoSave();
	}

	override void PlayerDied(PlayerEvent e)
	{
		lives[e.playernumber] = max(lives[e.playernumber] - 1, -1);
		died[e.playernumber] = true;

		SaveLifeData();
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

				this.SaveLifeData();
			}
		}
	}
}