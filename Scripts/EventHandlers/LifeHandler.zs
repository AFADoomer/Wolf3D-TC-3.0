/*
 * Copyright (c) 2022 AFADoomer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

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

	static int CheckLives(Actor p)
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

	static void CleanInventory(Actor p, bool forcereset = false)
	{
		let mo = PlayerPawn(p);

		if (!mo) { return; }

		if (sv_cooploseinventory)
		{
			mo.ClearInventory();
			mo.GiveDefaultInventory();

			return;
		}

		Inventory next;
		for (Inventory item = mo.Inv; item != null; item = next)
		{
			next = item.Inv;

			if ((!sv_cooplosekeys || sv_coopsharekeys) && item is "Key") { continue; }

			if (!forcereset)
			{
				if (!sv_cooploseweapons && item is "Weapon") { continue; }
				else if (!sv_cooplosearmor && item is "Armor") { continue; }
				else if (!sv_cooplosepowerups && item is "Powerup") { continue; }
				else if ((!sv_cooploseammo && !sv_coophalveammo) && item is "Ammo") { continue; }
			}

			if (item is "Ammo")
			{
				if (sv_cooploseammo || forcereset) { item.Amount = 0; }
				else { item.Amount = max(1, item.Amount / 2); }

				continue;
			}

			item.Destroy();
		}

		mo.GiveDefaultInventory();
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
		int i = 0;

		if (e.IsSaveGame)
		{
			if (!persistent) { persistent = PersistentLifeHandler(EventHandler.Find("PersistentLifeHandler")); }

			if (level.time > 35) // If loading a save that (likely) wasn't an autosave, check for saved stats and copy them over if found
			{
				if (persistent)
				{
					for (i = 0; i < MAXPLAYERS; i++)
					{
						lives[i] = persistent.lives[i];
						died[i] = persistent.died[i];
					}
				}
			}
			else if (!multiplayer)// Otherwise this is an autosave or a new game, so treat as if the player just (re)spawned
			{
				for (i = 0; i < MAXPLAYERS; i++)
				{
					died[i] = died[i] || e.IsSaveGame;

					if (playeringame[i] && players[i].mo)
					{
						DoInventoryReset(i);
					}
				}
			}
		}

		for (i = 0; i < MAXPLAYERS; i++)
		{
			if (playeringame[i] && players[i].mo)
			{
				players[i].mo.ACS_NamedExecuteAlways("InitializePlayer", 0, i);
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
		if (!multiplayer) { DoInventoryReset(e.playernumber); }
	}

	void DoInventoryReset(uint playernum)
	{
		players[playernum].mo.ClearInventory();
		players[playernum].mo.GiveDefaultInventory();
	}

	override void PlayerEntered(PlayerEvent e)
	{
		if (multiplayer && level.levelnum % 100 == 1 && !e.IsReturn)
		{
			lives[e.playernumber] = 3;
			DoInventoryReset(e.playernumber);
			
			let score = players[e.playernumber].mo.FindInventory("Score");
			if (score)
			{
				score.amount = 0;
				Score(score).lifeamount = 40000;
			}
		}

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
		if (!e.thing.target || !e.thing.target.player || e.thing.target == e.thing) { return;} // Don't give points if you kill yourself or if the killer wasn't a player.

		int amt;

		if (e.thing is "ClassicBase") { amt = ClassicBase(e.thing).scoreamt; }
		else if (e.thing.player)
		{
			if (deathmatch) { amt = 2500; }
			else { amt = -2500; }
		}
		else { amt = e.thing.SpawnHealth() * 10; }

		if (amt > 0) { e.thing.A_GiveToTarget("Score", amt); }
		else { e.thing.A_TakeFromTarget("Score", amt); }
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