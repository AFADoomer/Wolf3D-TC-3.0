// Wolf3D Player Class
class WolfPlayer : DoomPlayer
{
	bool goobers;
	bool mutated;
	int deathtick, idletick;
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
		Player.MaxHealth 100;
		Player.SideMove 1.3, 1.3;
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
		CVar momentum = CVar.FindCVar("g_momentum");
		CVar bobscale = CVar.GetCVar("g_viewbobscale", player);

		if ((!momentum || !momentum.GetInt()) && pos.z == floorz)
		{
			// Stop screen bobbing if the player is stopped or if no weapon bob is enabled
			if (!vel.length() || (!bobscale || !bobscale.GetFloat())) { player.vel = (0, 0); }
		}

		Super.Tick();

		if ((!momentum || !momentum.GetInt()) && pos.z == floorz && vel.xy.length())
		{
			vel *= 0;
			player.mo.PlayIdle();

			Speed = Default.Speed * 8;
		}
		else { Speed = Default.Speed; }

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

			lastpos = pos;
		}
	}

	override color GetPainFlash()
	{
		if (health <= 0) { return 0; }

		return Super.GetPainFlash();
	}

	override void DeathThink()
	{
		if (!deathtick && (player.cmd.buttons & BT_USE ||
			((multiplayer || alwaysapplydmflags) && sv_forcerespawn)) && !sv_norespawn)
		{
			if (Level.maptime >= player.respawn_time || ((player.cmd.buttons & BT_USE) && player.Bot == NULL))
			{
				if (players[consoleplayer] == player) { Menu.SetMenu("Fader"); }
				deathtick++;
			}
		}

		if (deathtick)
		{
			if (deathtick < 12) { deathtick++; }
			else
			{
				player.cls = NULL; // Force a new class if the player is using a random class
				player.playerstate = (multiplayer || level.AllowRespawn || sv_singleplayerrespawn || G_SkillPropertyInt(SKILLP_PlayerRespawn)) ? PST_REBORN : PST_ENTER;
				if (special1 > 2) { special1 = 0; }
			}

			return;
		}

		Super.DeathThink();
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
}