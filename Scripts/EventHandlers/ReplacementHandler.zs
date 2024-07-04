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
			case 'ArmorBonus': e.replacement = Random[WolfReplace](0, 1) ? "JeweledScepter" : "JeweledCross"; break;
			case 'GreenArmor': e.replacement = Random[WolfReplace](0, 1) ? "Chest" : "Chalice"; break;
			case 'BlueArmor': e.replacement = "Crown"; break;

			// Health
			case 'HealthBonus': e.replacement = Random[WolfReplace](0, 1) ? "DogFood" : "MoldyCheese"; break;
			case 'StimPack': e.replacement = "PlateOfFood"; break;
			case 'MediKit': e.replacement = "FirstAidKit"; break;
			case 'SoulSphere':
			case 'MegaSphere': e.replacement = "Life"; break;
			case 'Berserk': e.replacement = "WolfBerserk"; break;
			
			// Other
			case 'ExplosiveBarrel': e.replacement = "ExplosiveOilDrum"; break;
			case 'Backpack': e.replacement = "WolfBackpack"; break;
			case 'AllMap': e.replacement = "WolfMap"; break;

			// BulletZBorn compatibility
			case 'WolfPuff':
				e.replacement = GameHandler.CheckForClass("BulletZPuff");
				break;
			case 'WallSmoke': e.replacement = "WolfPuff"; break;

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
		useflats = CVar.FindCVar("g_useflats");
		useflatsval[consoleplayer] = useflats.GetInt();

		if (useflatsval[consoleplayer]) { CheckFlats(); }
	}

	override void WorldTick()
	{
		if (!useflats || useflatsval[consoleplayer] != useflats.GetInt())
		{
			if (!useflats) { useflats = CVar.FindCVar("g_useflats"); }
			useflatsval[consoleplayer] = useflats.GetInt();

			CheckFlats();
		}
	}

	void CheckFlats()
	{
		int levelnum;
		ParsedMap queuedmap;
		MapHandler handler = MapHandler(StaticEventHandler.Find("MapHandler"));
		if (handler && handler.queuedmap)
		{
			queuedmap = handler.queuedmap;
			levelnum = handler.queuedmap.mapnum;
		}
		else { levelnum = level.levelnum; }

		if (useflatsval[consoleplayer] < 4 && levelnum <= 100) { return; }

		static const String WolfCeilings[] = {"1D", "1D", "1D", "1D", "1D", "1D", "1D", "1D", "1D", "BF", "4E", "4E", "4E", "1D", "8D", "4E", "1D", "2D", "1D", "8D", "1D", "1D", "1D", "1D", "1D", "2D", "DD", "1D", "1D", "98", "1D", "9D", "2D", "DD", "DD", "9D", "2D", "4D", "1D", "DD", "7D", "1D", "2D", "2D", "DD", "D7", "1D", "1D", "1D", "2D", "1D", "1D", "1D", "1D", "DD", "DD", "7D", "DD", "DD", "DD"};
		static const String SoDCeilings[] = {"6F", "4F", "1D", "DE", "DF", "2E", "7F", "9E", "AE", "7F", "1D", "DE", "DF", "DE", "DF", "DE", "E1", "DC", "2E", "1D", "DC"};

		String ceilname = "1D";
		String floorname = "FLOOR";

		int h, gamemode = -1;
		if (queuedmap) { gamemode = queuedmap.gametype; }
		if (gamemode < 0) { [h, gamemode] = Game.IsSoD(); }

		if (gamemode > 0) { ceilname = SoDCeilings[clamp(levelnum % 100 - 1, 0, 20)]; }
		else { ceilname = WolfCeilings[clamp((levelnum / 100 - 1) * 10 + levelnum % 100 - 1, 0, 59)]; }
 
		TextureID floortex, ceiltex;

		if (useflats && useflats.GetInt())
		{
			int val = useflats.GetInt() % 4;
			if (val == 3)
			{
				floorname = "FLOOR" .. (levelnum / 5) % 8;
				ceilname = "CEIL" .. levelnum % 7;
			}
			else
			{
				if (val == 2)
				{
					floorname = "FLOOR" .. (levelnum / 5) % 8;
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