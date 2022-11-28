class ReplacementHandler : StaticEventHandler
{
	int useflatsval[MAXPLAYERS];
	transient CVar useflats;

	override void CheckReplacement(ReplaceEvent e)
	{
		if (g_replacenativeactors == 0) { return; }

		switch (e.replacee.GetClassName())
		{
			// Weapons
			case 'Chainsaw': e.replacement = "Life"; break;
			case 'Pistol': e.replacement = "WolfPistol"; break;
			case 'SuperShotgun': 
			case 'Shotgun': e.replacement = "WolfMachineGun"; break;
			case 'Chaingun': e.replacement = "WolfChainGun"; break;
			case 'RocketLauncher': e.replacement = "WolfRocketLauncher"; break;
			case 'PlasmaRifle': e.replacement = "WolfFlameThrower"; break;
			case 'BFG9000': e.replacement = "WolfFlameThrower"; break;

			// Ammo
			case 'Clip':
			case 'Shell': e.replacement = "WolfClip"; break;
			case 'ClipBox': 
			case 'ShellBox': e.replacement = "WolfClipBox"; break;
			case 'RocketAmmo': e.replacement = "WolfRocketPickup"; break;
			case 'RocketBox': e.replacement = "WolfRocketCrate"; break;
			case 'Cell':
			case 'CellPack': e.replacement = "WolfGas"; break;

			// Armor
			case 'ArmorBonus': e.replacement = Random(0, 1) ? "Chalice" : "JeweledCross"; break;
			case 'GreenArmor': e.replacement = "Chest"; break;
			case 'BlueArmor': e.replacement = "Crown"; break;

			// Health
			case 'HealthBonus': e.replacement = Random(0, 1) ? "DogFood" : "MoldyCheese"; break;
			case 'StimPack': e.replacement = "PlateOfFood"; break;
			case 'MediKit': e.replacement = "FirstAidKit"; break;
			case 'SoulSphere':
			case 'MegaSphere': e.replacement = "Life"; break;
			case 'Berserk': e.replacement = "WolfBerserk"; break;
			
			// Other
			case 'ExplosiveBarrel': e.replacement = "ExplosiveOilDrum"; break;
			case 'Backpack': e.replacement = "WolfBackpack"; break;
		}

		if (e.replacement) { e.IsFinal = true; }

		if (g_replacenativeactors == 2) { return; }

		switch (e.replacee.GetClassName())
		{
			// Enemies
			case 'Demon':
			case 'Spectre':
			case 'LostSoul': e.replacement = "Dog"; break;
			case 'Zombieman': e.replacement = "Guard"; break;
			case 'ShotgunGuy': e.replacement = "SS"; break;
			case 'DoomImp': e.replacement = "Mutant"; break;
			case 'BaronofHell': e.replacement = "GretelGrosse"; break;
			case 'Cacodemon':
			case 'PainElemental': e.replacement = "HitlerGhost"; break;
			case 'ChaingunGuy': e.replacement = "Officer"; break;
			case 'HellKnight': e.replacement = "HansGrosse"; break;
			case 'Arachnotron': e.replacement = "TransGrosse"; break;
			case 'Fatso': e.replacement = "Giftmacher"; break;
			case 'Revenant': e.replacement = "DrSchabbs"; break;
			case 'SpiderMastermind': e.replacement = "Hitler"; break;
			case 'CyberDemon': e.replacement = "HitlerMech"; break;
			case 'Archvile': e.replacement = "FettGesicht"; break;
			case 'WolfensteinSS': e.replacement = "Guard"; break;
		}
	}

	override void CheckReplacee(ReplacedEvent e)
	{
		if (g_replacenativeactors != 1) { return; }

		switch (e.replacement.GetClassName())
		{
			// Enemies
			case 'Dog': e.replacee = "Demon"; break;
			case 'Guard': e.replacee = "Zombieman"; break;
			case 'SS': e.replacee = "ShotgunGuy"; break;
			case 'Mutant': e.replacee = "DoomImp"; break;
			case 'GretelGrosse': e.replacee = "BaronofHell"; break;
			case 'HitlerGhost': e.replacee = "Cacodemon"; break;
			case 'Officer': e.replacee = "ChaingunGuy"; break;
			case 'HansGrosse': e.replacee = "HellKnight"; break;
			case 'TransGrosse': e.replacee = "Arachnotron"; break;
			case 'GiftMacher': e.replacee = "Fatso"; break;
			case 'DrSchabbs': e.replacee = "Revenant"; break;
			case 'Hitler': e.replacee = "SpiderMastermind"; break;
			case 'HitlerMech': e.replacee = "CyberDemon"; break;
			case 'FettGesicht': e.replacee = "Archvile"; break;
			case 'Guard': e.replacee = "WolfensteinSS"; break;
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		if (level.levelnum > 100)
		{
			useflats = CVar.FindCVar("g_useflats");
			useflatsval[consoleplayer] = useflats.GetInt();

			if (useflatsval[consoleplayer]) { CheckFlats(); }
		}
	}

	override void WorldTick()
	{
		if (level.levelnum > 100 && (!useflats || useflatsval[consoleplayer] != useflats.GetInt()))
		{
			if (!useflats) { useflats = CVar.FindCVar("g_useflats"); }
			useflatsval[consoleplayer] = useflats.GetInt();

			CheckFlats();
		}
	}

	void CheckFlats()
	{
		static const String WolfCeilings[] = {"1d", "1d", "1d", "1d", "1d", "1d", "1d", "1d", "1d", "bf", "4e", "4e", "4e", "1d", "8d", "4e", "1d", "2d", "1d", "8d", "1d", "1d", "1d", "1d", "1d", "2d", "dd", "1d", "1d", "98", "1d", "9d", "2d", "dd", "dd", "9d", "2d", "4d", "1d", "dd", "7d", "1d", "2d", "2d", "dd", "d7", "1d", "1d", "1d", "2d", "1d", "1d", "1d", "1d", "dd", "dd", "7d", "dd", "dd", "dd"};
		static const String SoDCeilings[] = {"6f", "4f", "1d", "de", "df", "2e", "7f", "9e", "ae", "7f", "1d", "de", "df", "de", "df", "de", "e1", "dc", "2e", "1d", "dc"};

		String ceilname = "1d";
		String floorname = "FLOOR";
		if (g_sod > 0) { ceilname = SoDCeilings[clamp(level.levelnum % 100 - 1, 0, 20)]; }
		else { ceilname = WolfCeilings[clamp((level.levelnum / 100 - 1) * 10 + level.levelnum % 100 - 1, 0, 59)]; }

		TextureID floortex, ceiltex;

		if (useflats && useflats.GetInt())
		{
			if (useflats.GetInt() == 3)
			{
				floorname = "FLOOR" .. (level.levelnum / 5) % 8;
				ceilname = "CEIL" .. level.levelnum % 7;
			}
			else
			{
				if (useflats.GetInt() == 2)
				{
					floorname = "FLOOR" .. (level.levelnum / 5) % 8;
				}
				else
				{
					floorname = "FLOORDEF";
				}
				ceilname = "CEIL" .. ceilname;
			}
		}

		ChangeFlat(0, ceilname);
		ChangeFlat(800, ceilname);
		ChangeFlat(0, floorname, sector.floor);
		ChangeFlat(800, floorname, sector.floor);
	}

	static void ChangeFlat(int tag, String texname, int which = sector.ceiling)
	{
		int s = -1;
		let it = level.CreateSectorTagIterator(tag);

		let tex = TexMan.CheckForTexture(texname, TexMan.Type_Any);

		if (tex.IsValid())
		{
			while ((s = it.Next()) >= 0)
			{
				Level.sectors[s].SetTexture(which, tex);
			}
		}
	}
}