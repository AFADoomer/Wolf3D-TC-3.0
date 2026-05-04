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
class WolfPlayer : PlayerPawn
{
	bool goobers, mutated, respawn, justdied;
	int deathtick, respawntick, idletick, paintick;
	double attackerangle;
	Vector3 lastpos;
	state IdleState, RunningState, AttackState;
	Weapon curweap;

	Default
	{
		+DONTGIB
		DeathHeight 0;
		Health 100;
		Height 56;
		Mass 10000;
		PainChance 255;
		Radius 16;
		Speed 1;
		Scale 0.93;

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
		Player.WeaponSlot 1, "WolfKnife";

		Player.ColorRange 96, 112;
		Player.ColorSet 0, "$TXT_COLOR_ORIGINAL", 0x10, 0x1F, 0x15;
		Player.ColorSet 1, "$TXT_COLOR_RED", 0x20, 0x2F, 0x22;
		Player.ColorSet 2, "$TXT_COLOR_ORANGE", 0x38, 0x3F, 0x3B;
		Player.ColorSet 3, "$TXT_COLOR_YELLOW", 0x40, 0x4F, 0x42;
		Player.ColorSet 4, "$TXT_COLOR_GREEN", 0x60, 0x6F, 0x62;
		Player.ColorSet 5, "$TXT_COLOR_CYAN", 0x70, 0x7F, 0x76;
		Player.ColorSet 6, "$TXT_COLOR_BLUE", 0x80, 0x87, 0x82;
		Player.ColorSet 7, "$TXT_COLOR_DARKBLUE", 0x90, 0x9F, 0x98;
		Player.ColorSet 8, "$TXT_COLOR_PURPLE", 0xA6, 0xAF, 0xA8;
		Player.ColorSet 9, "$TXT_COLOR_PINK", 0xB0, 0xBF, 0xB6;
		Player.ColorSet 10, "$TXT_COLOR_BROWN", 0xC0, 0xDF, 0xD0;
	}

	States
	{
		Spawn:
			"####" "#" 6;
		Spawn.WolfMachinegun:
			BJ3S A 6;
			Loop;
		Spawn.WolfKnife:
			BJ1S A 6;
			Loop;
		Spawn.WolfPistol:
			BJ2S A 6;
			Loop;
		Spawn.WolfChaingun:
			BJ4S A 6;
			Loop;
		Spawn.WolfFlamethrower:
			BJ5S A 6;
			Loop;
		Spawn.WolfRocketLauncher:
			BJ6S A 6;
			Loop;
		See:
		See.WolfMachinegun:
			BJ3W ABCD 4;
			Loop;
		See.WolfKnife:
			BJ1W ABCD 4;
			Loop;
		See.WolfPistol:
			BJ2W ABCD 4;
			Loop;
		See.WolfChaingun:
			BJ4W ABCD 4;
			Loop;
		See.WolfFlamethrower:
			BJ5W ABCD 4;
			Loop;
		See.WolfRocketLauncher:
			BJ6W ABCD 4;
			Loop;
		Melee:
		Attack.WolfKnife:
			BJ1A ABCD 3;
			Goto Spawn;
		Attack.WolfPistol:
			BJ2A A 3;
			BJ2A B 3 Bright;
			BJ2A CD 3;
			Goto Spawn;
		Missile:
		Attack.WolfMachineGun:
			BJ3A A 3;
			BJ3A B 3 Bright;
			BJ3A CD 3;
			Goto Spawn;
		Attack.WolfChaingun:
			BJ4A A 3;
			BJ4A BC 3 Bright;
			BJ4A D 3;
			Goto Spawn;
		Attack.WolfFlamethrower:
			BJ5A ABCD 3 Bright;
			Goto Spawn;
		Attack.WolfRocketLauncher:
			BJ6A BCD 3 Bright;
			BJ6W AA 3;
			Goto Spawn;
		Pain:
		Pain.WolfMachineGun:
			BJ3P A 4 { frame += RandomPick[pain](0, 1); }
			BJ3P "#" 4 A_Pain;
			Goto Spawn;
		Pain.WolfKnife:
			BJ1P A 4 { frame += RandomPick[pain](0, 1); }
			BJ1P "#" 4 A_Pain;
			Goto Spawn;
		Pain.WolfPistol:
			BJ2P A 4 { frame += RandomPick[pain](0, 1); }
			BJ2P "#" 4 A_Pain;
			Goto Spawn;
		Pain.WolfChaingun:
			BJ4P A 4 { frame += RandomPick[pain](0, 1); }
			BJ4P "#" 4 A_Pain;
			Goto Spawn;
		Pain.WolfFlamethrower:
			BJ5P A 4 { frame += RandomPick[pain](0, 1); }
			BJ5P "#" 4 A_Pain;
			Goto Spawn;
		Pain.WolfRocketLauncher:
			BJ6P A 4 { frame += RandomPick[pain](0, 1); }
			BJ6P "#" 4 A_Pain;
			Goto Spawn;
		Death.WolfNaziSyringe:
			BJ0D A 0 { mutated = true; }
		Death:
			BJ0D A 8;
			BJ0D A 0 A_PlayerScream();
		Death.Resume:
			BJ0D B 7;
			BJ0D C 8;
			BJ0D D 1 A_CheckPlayerDone();
			Wait;
		Death.Fire:
		Death.WolfNaziFire:
			BJ0D A 0 {
				if (g_noblood)
				{
					SetStateLabel("Death");
					return;
				}

				vel.xy *= 0;
				A_PlayerScream();
				SpawnFlames();
			}
			BJ0D A 6 A_SetTranslation("Ash25");
			BJ0D A 6 A_SetTranslation("Ash50");
			BJ0D A 6 A_SetTranslation("Ash75");
			BJ0D A 6 A_SetTranslation("Ash100");
			Goto Death.Resume;
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
				if (idletick++ > 30 * GameTicRate && ClassicStatusBar(StatusBar))
				{
					ClassicStatusBar(StatusBar).DoIdleFace(self);
					idletick = 0;
				}
			}
			else { idletick = 0; }
		}
	}

	void RefreshSpriteStates()
	{
		IdleState = GetSpriteState("Spawn", true);
		RunningState = GetSpriteState("See", true);
		AttackState = GetSpriteState("Attack", true);

		if (!IdleState) { IdleState = SpawnState; }
		if (!RunningState) { RunningState = SeeState; }
		if (!AttackState) { AttackState = (player && player.ReadyWeapon && player.ReadyWeapon.bMeleeWeapon) ? MeleeState : MissileState; }
	}

	// Reverse MeleeState and MissileState here so that they make sense
	override void PlayAttacking()
	{
		if (MeleeState && !InStateSequence(CurState, MeleeState)) { SetState(MeleeState); }
	}

	override void PlayAttacking2()
	{
		if (MissileState && !InStateSequence(CurState, MissileState)) { SetState(MissileState); }
	}

	override void PlayIdle()
	{
		if (health <= 0) { return; }
		if (!InStateSequence(CurState, IdleState)) { SetState(IdleState); }
	}

	override void PlayRunning()
	{
		if (!InStateSequence(CurState, RunningState)) { SetState(RunningState); }
	}

	State GetSpriteState(String prefix, bool strict = false)
	{
		if (!player || !player.ReadyWeapon) { return FindStateByString(prefix); }

		String classname = player.ReadyWeapon.GetClassName();
		if (classname.Mid(classname.length() - 4) ~== "Lost") { classname.Replace("Lost", ""); }

		state found = FindStateByString(prefix .. "." .. classname, strict);

		return found;
	}

	override void CheckWeaponChange()
	{
		Super.CheckWeaponChange();
		
		RefreshSpriteStates();
	}

	override bool ReactToDamage(Actor inflictor, Actor source, int damage, Name mod, int flags, int originaldamage)
	{
		bool ret = Super.ReactToDamage(inflictor, source, damage, mod, flags, originaldamage);

		if (!ret || health <= 0) { return ret; }

		state PainState;

		paintick = 8;

		// // Start by looking for damagetype-specific and weapon-specific frames (that likely will never exist)
		// PainState = FindStateByString("Pain." .. player.ReadyWeapon.GetClassName() .. "." .. mod, true);
		// if (PainState)
		// {
		// 	if (!InStateSequence(CurState, PainState)) { SetState(PainState); }
		// 	return ret;
		// }

		// Otherwise, if there is a damagetype-specific pain state, it was set by the Super call, so don't change it
		PainState = FindStateByString("Pain." .. mod, true);
		if (PainState) { return ret; }
		
		// Otherwise look up weapon-specific pain frames
		PainState = GetSpriteState("Pain", true);
		if (PainState)
		{
			if (!InStateSequence(CurState, PainState)) { SetState(PainState); }
		}

		return ret;
	}

	override void FireWeapon(State stat)
	{
		let player = self.player;

		let wpn = player.ReadyWeapon;
		if (!wpn || !wpn.CheckAmmo(Weapon.PrimaryFire, true)) { return; }

		player.WeaponState &= ~WF_WEAPONBOBBING;
		
		bool attacking = true;
		
		let cwpn = ClassicWeapon(wpn);
		if (!cwpn)
		{
			if (!wpn.bMeleeWeapon) { PlayAttacking2(); }
			else { PlayAttacking(); }
		}

		wpn.bAltFire = false;

		if (!stat) { stat = wpn.GetAtkState(!!player.refire); }
		player.SetPsprite(PSP_WEAPON, stat);
		
		if (!wpn.bNoAlert) { SoundAlert (self, false); }
	}

	override void MovePlayer(void)
	{
		CVar bobscale = CVar.GetCVar("g_viewbobscale", player);

		Speed = Default.Speed;

		if (!g_momentum && pos.z == floorz)
		{
			// Stop screen bobbing if the player is stopped or if no weapon bob is enabled
			if (!vel.length() || (!bobscale || !bobscale.GetFloat())) { player.vel = (0, 0); }
		
			if (vel.xy.length())
			{
				vel *= 0;
				Speed = Default.Speed * 8;
			}
		}

		Super.MovePlayer();
	}

	override void PlayerThink()
	{
		Super.PlayerThink();

		if (!(player.cheats & CF_PREDICTING))
		{
			ViewBob = Default.ViewBob * CVar.GetCVar("g_viewbobscale", player).GetFloat();
		}

		if (player.damagecount > 0) { player.damagecount--; }
		if (paintick > 0) { paintick--; }

		if (!player.ReadyWeapon || player.playerstate == PST_DEAD || health <= 0) { return; }

		if (player.ReadyWeapon != curweap)
		{
			curweap = player.ReadyWeapon;
			RefreshSpriteStates();
		}

		if (vel.xy.length()) { PlayRunning(); }
		else if (!paintick) { PlayIdle(); }

		let cwpn = ClassicWeapon(player.ReadyWeapon);
		if (cwpn && cwpn.status == ClassicWeapon.Firing)
		{
			let psp = player.GetPsprite(PSP_WEAPON);

			state FireState = psp.caller.FindState("Fire");
			int frameoffset = FireState.DistanceTo(psp.CurState);

			if (frameoffset > -1) { SetState(AttackState + frameoffset); }
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

		if (respawntick == GameTicRate)
		{
			EventHandler.SendInterfaceEvent(consoleplayer, "fizzle", 0xFF0000, 0, 1920);
		}

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
			GameHandler handler;
			handler = GameHandler(StaticEventHandler.Find("GameHandler"));

			if (handler)
			{
				for (int k = 0; k < handler.keys.Size(); k++)
				{
					let keyitem = GetDefaultByType(handler.keys[k]);
					if (keyitem.special1 != 0)
					{
						let item = Inventory(Spawn(handler.keys[k]));
						if (!item.CallTryPickup (self))
						{
							item.Destroy ();
						}
					}
				}
			}
			else // Fall back to naive code if the handler wasn't available for some reason
			{
				for (int i = 0; i < AllActorClasses.Size(); ++i)
				{
					if (AllActorClasses[i] is "Key")
					{
						if (AllActorClasses[i] is "YellowKeyLost" || AllActorClasses[i] is "BlueKeyLost") { continue; }
						if (giveall != ALL_YESYES && (AllActorClasses[i] is "RedKey" || AllActorClasses[i] is "GreenKey" )) { continue; }

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
						item.Amount = clamp(item.Amount + (di.Amount ? di.Amount : item.default.Amount), 0, item.MaxAmount);
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

	override void GiveDeathmatchInventory()
	{
		GameHandler handler;
		handler = GameHandler(StaticEventHandler.Find("GameHandler"));

		if (handler)
		{
			for (int k = 0; k < handler.keys.Size(); k++)
			{
				let cls = (class<Key>)(handler.keys[k]);
				if (cls)
				{
					if (handler.keys[k] is "YellowKeyLost" || handler.keys[k] is "BlueKeyLost") { continue; }
					let keyobj = GetDefaultByType(handler.keys[k]);

					if (keyobj.special1 != 0)
					{
						GiveInventoryType(cls);
					}
				}
			}
		}
		else
		{
			for ( int i = 0; i < AllActorClasses.Size(); ++i)
			{
				let cls = (class<Key>)(AllActorClasses[i]);
				if (cls)
				{
					if (AllActorClasses[i] is "YellowKeyLost" || AllActorClasses[i] is "BlueKeyLost") { continue; }
					let keyobj = GetDefaultByType(cls);

					if (keyobj.special1 != 0)
					{
						GiveInventoryType(cls);
					}
				}
			}
		}
	}

	override void CheckPitch()
	{
		if (!freelook) { pitch = 0.0; }
		else
		{
			Super.CheckPitch();
		}
	}

	virtual void SpawnFlames(int count = 8, double maxheight = 32, double rad = -1)
	{
		for (int f = 0; f < count; f++)
		{
			if (rad == -1) { rad = radius / 2; }

			Vector3 spawnpos = pos + (FRandom[SpawnFlames](-rad, rad), FRandom[SpawnFlames](-rad, rad), FRandom[SpawnFlames](0, maxheight));
			Spawn("Fire", spawnpos);
			Spawn("SmallFire", spawnpos + (FRandom[SpawnFlames](-16, 16), FRandom[SpawnFlames](-16, 16), FRandom[SpawnFlames](-8, 8)));
			SmokeSpawner ss = SmokeSpawner(Spawn("SmokeSpawner", spawnpos + (FRandom[SpawnFlames](-16, 16), FRandom[SpawnFlames](-16, 16), FRandom[SpawnFlames](-16, 16))));
			if (ss) { ss.duration = Random[SpawnFlames](45, 105); }
		}
	}
}