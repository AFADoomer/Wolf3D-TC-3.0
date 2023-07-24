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

// Wolf3D Player Class
class WolfPlayer : DoomPlayer
{
	bool goobers, mutated, respawn, justdied;
	int deathtick, respawntick, idletick;
	double attackerangle;
	Vector3 lastpos;

	Default
	{
		+DONTGIB
		DeathHeight 0;
		Health 100;
		Height 56;
		Mass 10000;

		Player.DisplayName "BJ";
		Player.Face "WLF";
		Player.ForwardMove 1.3, 1.3;
		Player.ViewBob 0.125;
		Player.MaxHealth 100;
		Player.SideMove 1.3, 1.3;
		Player.StartItem "WolfPistol";
		Player.StartItem "WolfKnife";
		Player.StartItem "WolfClip", 8;
		Player.ViewHeight 32;
		Player.WeaponSlot 1, "WolfKnife", "WolfKnifeLost";
		Player.WeaponSlot 2, "WolfPistol", "WolfPistolLost";
		Player.WeaponSlot 3, "WolfMachinegun", "WolfMachinegunLost";
		Player.WeaponSlot 4, "WolfChaingun", "WolfChaingunLost";
		Player.WeaponSlot 5, "";
		Player.WeaponSlot 6, "";
		Player.WeaponSlot 7, "";
	}

	States
	{
		Spawn:
			PLAY A 1;
			Loop;
		See:
			PLAY ABCD 4 A_JumpIf(!vel.x && !vel.y, "Spawn");
			Loop;
		Missile:
			PLAY E 12;
			Goto Spawn;
		Melee:
			PLAY F 6 Bright;
			Goto Missile;
		Pain:
			PLAY G 4;
			PLAY G 4 A_Pain;
			Goto Spawn;
		Death.WolfNaziSyringe:
			PLAY H 0 { mutated = true; }
		Death:
			PLAY H 10;
			PLAY I 10 A_PlayerScream;
			PLAY JKLM 10;
			PLAY N 1 A_CheckPlayerDone;
			Wait;
	}

	override void PostBeginPlay()
	{
		if (player) { player.cheats |= CF_INSTANTWEAPSWITCH; }
		if (!Default.bNoBlood) { bNoBlood = g_noblood; }

		Super.PostBeginPlay();
	}

	override void Tick()
	{
		if (!player) { return; }

		lastpos = pos;

		Super.Tick();

		// SoD-specific idle and ouch face mugshots
		if (Game.IsSoD() || level.levelnum < 101)
		{
			if (player && player.damagecount > 30 && ClassicStatusBar(StatusBar)) { ClassicStatusBar(StatusBar).DoScream(self); } 

			if (pos == lastpos)
			{
				if (idletick++ > 30 * 35 && ClassicStatusBar(StatusBar))
				{
					ClassicStatusBar(StatusBar).DoIdleFace(self);
					idletick = 0;
				}
			}
			else { idletick = 0; }
		}
	}

	override void MovePlayer(void)
	{
		CVar momentum = CVar.FindCVar("g_momentum");
		CVar bobscale = CVar.GetCVar("g_viewbobscale", player);

		if ((!momentum || !momentum.GetInt()) && pos.z == floorz)
		{
			// Stop screen bobbing if the player is stopped or if no weapon bob is enabled
			if (!vel.length() || (!bobscale || !bobscale.GetFloat())) { player.vel = (0, 0); }
		}

		if ((!momentum || !momentum.GetInt()) && pos.z == floorz && vel.xy.length())
		{
			if (!vel.xy.length()) { player.mo.PlayIdle(); }
			vel *= 0;

			Speed = Default.Speed * 8;
		}
		else { Speed = Default.Speed; }

		Super.MovePlayer();
	}

	override void PlayerThink()
	{
		Super.PlayerThink();

		if (!(player.cheats & CF_PREDICTING))
		{
			ViewBob = Default.ViewBob * CVar.GetCVar("g_viewbobscale", player).GetFloat();
		}

		if (player.playerstate != PST_DEAD && !(player.cheats & CF_PREDICTING))
		{
			if (player.damagecount) { player.damagecount--; }
		}
	}

	override void DeathThink()
	{
		player.Uncrouch();
		TickPSprites();

		if (sv_norespawn) { return; }
		
		if (
			respawntick++ >= (LifeHandler.CheckLives(self) > -1 ? 70 : 105) ||
			(player.cmd.buttons & BT_USE && player.Bot != null)
		)
		{ respawn = true; }

		if (player.attacker && player.attacker != self)
		{
			if (!attackerangle) { attackerangle = deltaangle(angle, AngleTo(player.attacker)); }
			A_Face(player.attacker, abs(attackerangle) / 20, 6, 0, 0, FAF_BOTTOM);
		}

		if (respawn)
		{
			deathtick++;

			if (deathtick >= 12)
			{
				player.cls = NULL; // Force a new class if the player is using a random class
				player.playerstate = PST_REBORN;
				if (special1 > 2) { special1 = 0; }
			}
		}
	}

	// Give health with 'give all' cheat, don't give backpack unless
	// the 'give everything' cheat is used, and never give armor
	override void CheatGive (String name, int amount)
	{
		int i;
		Class<Inventory> type;
		let player = self.player;

		if (player.mo == NULL || player.health <= 0)
		{
			return;
		}

		int giveall = ALL_NO;
		if (name ~== "all")
		{
			giveall = ALL_YES;
		}
		else if (name ~== "everything")
		{
			giveall = ALL_YESYES;
		}

		if (giveall || name ~== "health")
		{
			if (amount > 0)
			{
				health += amount;
				player.health = health;
			}
			else
			{
				player.health = health = GetMaxHealth(true);
			}
		}

		if (giveall == ALL_YESYES || name ~== "backpack")
		{
			// Select the correct type of backpack based on the game
			type = (class<Inventory>)(gameinfo.backpacktype);
			if (type != NULL)
			{
				GiveInventory(type, 1, true);
			}

			if (!giveall)
				return;
		}

		if (giveall || name ~== "lives")
		{
			LifeHandler.SetLives(self, 9);

			if (!giveall)
				return;
		}

		if (giveall || name ~== "ammo")
		{
			// Find every unique type of ammo. Give it to the player if
			// he doesn't have it already, and set each to its maximum.
			for (i = 0; i < AllActorClasses.Size(); ++i)
			{
				let ammotype = (class<Ammo>)(AllActorClasses[i]);

				if (ammotype && GetDefaultByType(ammotype).GetParentAmmo() == ammotype)
				{
					let ammoitem = FindInventory(ammotype);
					if (ammoitem == NULL)
					{
						ammoitem = Inventory(Spawn (ammotype));
						ammoitem.AttachToOwner (self);
						ammoitem.Amount = ammoitem.MaxAmount;
					}
					else if (ammoitem.Amount < ammoitem.MaxAmount)
					{
						ammoitem.Amount = ammoitem.MaxAmount;
					}
				}
			}

			if (!giveall)
				return;
		}

		if (giveall || name ~== "keys")
		{
			for (int i = 0; i < AllActorClasses.Size(); ++i)
			{
				if (AllActorClasses[i] is "Key")
				{
					if (AllActorClasses[i] is "YellowKeyLost" || AllActorClasses[i] is "BlueKeyLost") { continue; }
					let keyitem = GetDefaultByType (AllActorClasses[i]);
					if (keyitem.special1 != 0)
					{
						let item = Inventory(Spawn(AllActorClasses[i]));
						if (!item.CallTryPickup (self))
						{
							item.Destroy ();
						}
					}
				}
			}
			if (!giveall)
				return;
		}

		if (giveall || name ~== "weapons")
		{
			let savedpending = player.PendingWeapon;
			for (i = 0; i < AllActorClasses.Size(); ++i)
			{
				let type = (class<Weapon>)(AllActorClasses[i]);
				if (type != null && type != "Weapon" && !type.isAbstract())
				{
					// Don't give replaced weapons unless the replacement was done by Dehacked.
					let rep = GetReplacement(type);
					if (rep == type || rep is "DehackedPickup")
					{
						// Give the weapon only if it is set in a weapon slot.
						if (player.weapons.LocateWeapon(type))
						{
							readonly<Weapon> def = GetDefaultByType (type);
							if (giveall == ALL_YESYES || !def.bCheatNotWeapon)
							{
								GiveInventory(type, 1, true);
							}
						}
					}
				}
			}
			player.PendingWeapon = savedpending;

			if (!giveall)
				return;
		}

		if (giveall || name ~== "artifacts")
		{
			for (i = 0; i < AllActorClasses.Size(); ++i)
			{
				type = (class<Inventory>)(AllActorClasses[i]);
				if (type!= null)
				{
					let def = GetDefaultByType (type);
					if (def.Icon.isValid() && (def.MaxAmount > 1 || def.bAutoActivate == false) && CheckArtifact(type))
					{
						// Do not give replaced items unless using "give everything"
						if (giveall == ALL_YESYES || GetReplacement(type) == type)
						{
							GiveInventory(type, amount <= 0 ? def.MaxAmount : amount, true);
						}
					}
				}
			}
			if (!giveall)
				return;
		}

		if (giveall || name ~== "puzzlepieces")
		{
			for (i = 0; i < AllActorClasses.Size(); ++i)
			{
				let type = (class<PuzzleItem>)(AllActorClasses[i]);
				if (type != null)
				{
					let def = GetDefaultByType (type);
					if (def.Icon.isValid())
					{
						// Do not give replaced items unless using "give everything"
						if (giveall == ALL_YESYES || GetReplacement(type) == type)
						{
							GiveInventory(type, amount <= 0 ? def.MaxAmount : amount, true);
						}
					}
				}
			}
			if (!giveall)
				return;
		}

		if (giveall)
			return;

		type = name;
		if (type == NULL)
		{
			if (PlayerNumber() == consoleplayer)
				A_Log(String.Format("Unknown item \"%s\"\n", name));
		}
		else
		{
			GiveInventory(type, amount, true);
		}
		return;
	}

	private bool CheckArtifact(class<Actor> type)
	{
		return !(type is "PuzzleItem") && !(type is "Powerup") && !(type is "Ammo") &&	!(type is "Armor") && !(type is "Key") && !(type is "Weapon");
	}

	override void GiveDefaultInventory ()
	{
		let player = self.player;
		if (player == NULL) return;

		// HexenArmor must always be the first item in the inventory because
		// it provides player class based protection that should not affect
		// any other protection item.
		let myclass = GetClass();
		GiveInventoryType('HexenArmor');
		let harmor = HexenArmor(FindInventory('HexenArmor'));

		harmor.Slots[4] = self.HexenArmor[0];
		for (int i = 0; i < 4; ++i)
		{
			harmor.SlotsIncrement[i] = self.HexenArmor[i + 1];
		}

		// BasicArmor must come right after that. It should not affect any
		// other protection item as well but needs to process the damage
		// before the HexenArmor does.
		GiveInventoryType('BasicArmor');

		// Now add the items from the DECORATE definition
		let di = GetDropItems();

		int h, gamemode;
		[h, gamemode] = Game.IsSoD();

		while (di)
		{
			String classname = di.Name;

			if (
				gamemode > 1 &&
				(
					classname ~== "WolfKnife" || 
					classname ~== "WolfPistol" || 
					classname ~== "WolfMachineGun" || 
					classname ~== "WolfChaingun"
				)
			)
			{
				classname.AppendFormat("%s", "Lost");
			}

			Class<Actor> ti = classname;
			if (ti)
			{
				let tinv = (class<Inventory>)(ti);
				if (!tinv)
				{
					Console.Printf(TEXTCOLOR_ORANGE .. "%s is not an inventory item and cannot be given to a player as start item.\n", di.Name);
				}
				else
				{
					let item = FindInventory(tinv);
					if (item != NULL)
					{
						item.Amount = clamp(
							item.Amount + (di.Amount ? di.Amount : item.default.Amount), 0, item.MaxAmount);
					}
					else
					{
						item = Inventory(Spawn(ti));
						item.bIgnoreSkill = true;	// no skill multipliers here
						item.Amount = di.Amount;
						let weap = Weapon(item);
						if (weap)
						{
							// To allow better control any weapon is emptied of
							// ammo before being given to the player.
							weap.AmmoGive1 = weap.AmmoGive2 = 0;
						}
						bool res;
						Actor check;
						[res, check] = item.CallTryPickup(self);
						if (!res)
						{
							item.Destroy();
							item = NULL;
						}
						else if (check != self)
						{
							// Player was morphed. This is illegal at game start.
							// This problem is only detectable when it's too late to do something about it...
							ThrowAbortException("Cannot give morph item '%s' when starting a game!", di.Name);
						}
					}
					let weap = Weapon(item);
					if (weap != NULL && weap.CheckAmmo(Weapon.EitherFire, false))
					{
						player.ReadyWeapon = player.PendingWeapon = weap;
					}
				}
			}
			di = di.Next;
		}
	}
}