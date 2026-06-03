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
			case 'PainElemental': e.replacement = "FakeHitler"; break;
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
			case 'FakeHitler': e.replacee = "Cacodemon"; break;
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
		if (e.IsSaveGame || e.IsReopen) { return; }

		useflats = CVar.FindCVar("g_useflats");
		CheckFlats(useflats.GetInt());
	}

	void CheckFlats(int val = -1)
	{
		if (val == -1) { val = useflats.GetInt(); }

		int levelnum;
		ParsedMap thismap;
		MapHandler handler = MapHandler.Get();
		if (handler)
		{
			if (level.time > 0 && handler.curmap) { thismap = handler.curmap; }
			else if (handler.queuedmap) { thismap = handler.queuedmap; }
			if (thismap) { levelnum = thismap.mapnum; }
		}

		if (!levelnum) { levelnum = level.levelnum; }

		if (val < 4 && levelnum <= 100) { return; }

		static const int WolfCeilings[] = {0x1D, 0x1D, 0x1D, 0x1D, 0x1D, 0x1D, 0x1D, 0x1D, 0x1D, 0xBF, 0x4E, 0x4E, 0x4E, 0x1D, 0x8D, 0x4E, 0x1D, 0x2D, 0x1D, 0x8D, 0x1D, 0x1D, 0x1D, 0x1D, 0x1D, 0x2D, 0xDD, 0x1D, 0x1D, 0x98, 0x1D, 0x9D, 0x2D, 0xDD, 0xDD, 0x9D, 0x2D, 0x4D, 0x1D, 0xDD, 0x7D, 0x1D, 0x2D, 0x2D, 0xDD, 0xD7, 0x1D, 0x1D, 0x1D, 0x2D, 0x1D, 0x1D, 0x1D, 0x1D, 0xDD, 0xDD, 0x7D, 0xDD, 0xDD, 0xDD};
		static const int SoDCeilings[] = {0x6F, 0x4F, 0x1D, 0xDE, 0xDF, 0x2E, 0x7F, 0x9E, 0xAE, 0x7F, 0x1D, 0xDE, 0xDF, 0xDE, 0xDF, 0xDE, 0xE1, 0xDC, 0x2E, 0x1D, 0xDC};

		int h, gamemode = -1;
		if (thismap) { gamemode = thismap.gametype; }
		if (gamemode < 0) { [h, gamemode] = Game.IsSoD(); }

		int ceilingnum = 0x1D;
		if (gamemode > 0) { ceilingnum = SoDCeilings[clamp(levelnum % 100 - 1, 0, 20)]; }
		else { ceilingnum = WolfCeilings[clamp((levelnum / 100 - 1) * 10 + levelnum % 100 - 1, 0, 59)]; }

		String ceilname, floorname;
		TextureID floortex, ceiltex;

		switch (val)
		{
			case 3:
				floorname = String.Format("Textures/Flats/FLAT%02x.png", ceilingnum - 1);
				floortex = TexMan.CheckForTexture(floorname, TexMan.Type_Any);

				ceilname = String.Format("Textures/Flats/FLAT%02x.png", ceilingnum);
				ceiltex = TexMan.CheckForTexture(ceilname, TexMan.Type_Any);
			case 2:
				if (!floortex.IsValid())
				{
					floorname = String.Format("Textures/Flats/FLAT%02x.png", ceilingnum - 1);
					floortex = TexMan.CheckForTexture(floorname, TexMan.Type_Any);
				}

				if (!ceiltex.IsValid())
				{
					ceilname = String.Format("CEIL%02x", ceilingnum);
					ceiltex = TexMan.CheckForTexture(ceilname, TexMan.Type_Any);
				}
			case 1:
				if (!floortex.IsValid())
				{
					floorname = "Textures/Flats/FLAT01.png";
					floortex = TexMan.CheckForTexture(floorname, TexMan.Type_Any);
				}

				if (!ceiltex.IsValid())
				{
					ceilname = String.Format("CEIL%02x", ceilingnum);
					ceiltex = TexMan.CheckForTexture(ceilname, TexMan.Type_Any);
				}
			default:
				if (!floortex.IsValid())
				{
					floorname = "FLOOR";
					floortex = TexMan.CheckForTexture(floorname, TexMan.Type_Any);
				}

				if (!ceiltex.IsValid())
				{
					ceilname = String.Format("%02x", ceilingnum);
					ceiltex = TexMan.CheckForTexture(ceilname, TexMan.Type_Any);
				}
		}

		for (int s = 0; s < level.sectors.Size(); s++)
		{
			let sec = level.sectors[s];
			if (!sec || sec.CenterFloor() == sec.CenterCeiling()) { continue; }

			if (ceiltex.IsValid()) { sec.SetTexture(sector.ceiling, ceiltex); }
			if (floortex.IsValid()) { sec.SetTexture(sector.floor, floortex); }

			if (handler && thismap)
			{
				TileInfo flat;
				int f;
				[f, flat] = thismap.TileAt(ParsedMap.CoordsToGrid(sec.CenterSpot), -1, 2);

				if (f > 0)
				{
					int floornum = f & 0xFF;
					if (floornum > 0)
					{
						String texname = val > 0 ? val > 1 ? String.Format("Textures/Flats/FLAT%02x.png", floornum) : String.Format("CEIL%02x", floornum) : String.Format("%02x", floornum);
						TextureID floor = TexMan.CheckForTexture(texname, TexMan.Type_Any);
						if (floor.IsValid()) { sec.SetTexture(sector.floor, floor); }
					}

					int ceilingnum = (f & 0xFF00) >> 8;
					if (ceilingnum > 0)
					{
						String texname = val > 0 ? val > 2 ? String.Format("Textures/Flats/FLAT%02x.png", ceilingnum) : String.Format("CEIL%02x", ceilingnum) : String.Format("%02x", ceilingnum);
						TextureID ceiling = TexMan.CheckForTexture(texname, TexMan.Type_Any);
						if (ceiling.IsValid()) { sec.SetTexture(sector.ceiling, ceiling); }
					}
				}
			}
		}
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

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.IsManual)  {return; }

		if (e.Name == "updateflatstyle")
		{
			CheckFlats(e.args[0]);
		}
	}
}