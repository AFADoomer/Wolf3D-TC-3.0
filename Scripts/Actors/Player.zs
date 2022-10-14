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

		Player.ColorRange 0x60, 0x6F;
		Player.ColorSet 0, "Green",	0x60, 0x6F, 0x62;
		Player.ColorSet 1, "Gray",	0x10, 0x1F, 0x14;
		Player.ColorSet 2, "Brown",	0xD0, 0xDF, 0xD2;
		Player.ColorSet 3, "Red",	0x20, 0x2F, 0x22;
		Player.ColorSet 4, "Yellow",	0x40, 0x4F, 0x44;
		Player.ColorSet 5, "Tan",	0xC0, 0xCF, 0xCA;
		Player.ColorSet 6, "Purple",	0xB0, 0xBF, 0xB2;
		Player.ColorSet 7, "Teal",	0x70, 0x7F, 0x7A;
		Player.DisplayName "BJ";
		Player.Face "WLF";
		Player.ForwardMove 1.3, 1.3;
		Player.MaxHealth 100;
		Player.SideMove 1.3, 1.3;
		Player.StartItem "WolfClip", 8;
		Player.ViewBob 0;
		Player.ViewHeight 32;
		Player.WeaponSlot 1, "WolfKnife", "WolfKnifeLost";
		Player.WeaponSlot 2, "WolfPistol", "WolfPistolLost";
		Player.WeaponSlot 3, "WolfMachinegun", "WolfMachinegunLost";
		Player.WeaponSlot 4, "WolfChaingun", "WolfChaingunSoD", "WolfChaingunLost";
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
			PLAY H 10 A_GiveToTarget("Score", 2500);
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
		Super.Tick();

		CVar momentum = CVar.FindCVar("g_momentum");

		if ((!momentum || !momentum.GetInt()) && pos.z == floorz)
		{
			vel *= 0;
			Speed = Default.Speed * 8;
		}
		else { Speed = Default.Speed; }

		// SoD-specific idle and ouch face mugshots
		if (Game.IsSod() || level.levelnum < 101)
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
}