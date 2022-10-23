class ReplacementHandler : StaticEventHandler
{
	override void CheckReplacement(ReplaceEvent e)
	{
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
			case 'HealthBonus': e.replacement = "DogFood"; break;
			case 'StimPack': e.replacement = "PlateOfFood"; break;
			case 'MediKit': e.replacement = "FirstAidKit"; break;
			case 'SoulSphere':
			case 'MegaSphere': e.replacement = "Life"; break;
			case 'Berserk': e.replacement = "WolfBerserk"; break;

			// Enemies
			case 'Demon':
			case 'Spectre':
			case 'LostSoul': e.replacement = "Dog"; break;
			case 'Zombieman': e.replacement = "Guard"; break;
			case 'ShotgunGuy': e.replacement = "SS"; break;
			case 'DoomImp': e.replacement = "Mutant"; break;
			case 'BaronofHell': e.replacement = Random(0, 2) ? Random(0, 1) ? "HansGrosse" : "GretelGrosse" : "TransGrosse"; break;
			case 'Cacodemon':
			case 'PainElemental': e.replacement = "HitlerGhost"; break;
			case 'ChaingunGuy': e.replacement = "Officer"; break;
			case 'HellKnight': e.replacement = "DrSchabbs"; break;
			case 'Arachnotron': e.replacement = "Giftmacher"; break;
			case 'Fatso': e.replacement = "UberMutant"; break;
			case 'Revenant': e.replacement = "FettGesicht"; break;
			case 'CyberDemon': e.replacement = Random(0, 1) ? "AngelofDeath" : "DeathKnight"; break;
			case 'SpiderMastermind': e.replacement = "HitlerMech"; break;

			// Other
			case 'ExplosiveBarrel': e.replacement = "ExplosiveOilDrum"; break;
		}
	}

	override void CheckReplacee(ReplacedEvent e)
	{
		switch (e.replacement.GetClassName())
		{
			// Enemies
			case 'Dog': e.replacee = "Demon"; break;
			case 'Guard': e.replacee = "Zombieman"; break;
			case 'SS': e.replacee = "ShotgunGuy"; break;
			case 'Mutant': e.replacee = "DoomImp"; break;
			case 'HansGrosse':
			case 'GretelGrosse': 
			case 'TransGrosse': e.replacee = "BaronofHell"; break;
			case 'HitlerGhost': e.replacee = "Cacodemon"; break;
			case 'Officer': e.replacee = "ChaingunGuy"; break;
			case 'DrSchabbs': e.replacee = "HellKnight"; break;
			case 'GiftMacher': e.replacee = "Arachnotron"; break;
			case 'UberMutant': e.replacee = "Fatso"; break;
			case 'FettGesicht': e.replacee = "Revenant"; break;
			case 'AngelofDeath':
			case 'DeathKnight': e.replacee = "CyberDemon"; break;
			case 'HitlerMech': 
			case 'Hitler': e.replacee = "SpiderMastermind"; break;
		}
	}
}