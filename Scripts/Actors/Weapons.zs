// Wolf3D Weapons
class ClassicWeapon : Weapon
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Weapons
		//$Color 3

		Mass 10000;
		Obituary "";
		Inventory.PickupMessage "";
		Weapon.YAdjust 19;
	}

	States
	{
		Spawn:
			UNKN A -1;
			Stop;
		Deselect:
			"####" "#" 1 A_Lower();
			Loop;
		Select:
			"####" "#" 1 A_Raise();
			Loop;
		Ready:
			"####" "#" 1;
			"####" "#" 0 A_WeaponReady();
			Loop;
		Fire:
			"####" "#" 1;
			Goto Ready;
		Refire:
			"####" "#" 0  A_Refire;
			"####" "#" 0 A_Jump (256, "Ready");
		Hold:
			"####" "#" 1;
			"####" "#" 0 A_JumpIfInventory ("PowerStrength", 1, "Hold.Automatic");
			"####" "#" 0 A_Jump (256, "Refire");
		Hold.Automatic:
			"####" "#" 0 A_Jump (256, "Fire");
	}

	action int WolfRandom()
	{
		static const int rnd_table[] = {
		  0,   8, 109, 220, 222, 241, 149, 107,  75, 248, 254, 140,  16,  66,
		 74,  21, 211,  47,  80, 242, 154,  27, 205, 128, 161,  89,  77,  36,
		 95, 110,  85,  48, 212, 140, 211, 249,  22,  79, 200,  50,  28, 188,
		 52, 140, 202, 120,  68, 145,  62,  70, 184, 190,  91, 197, 152, 224,
		149, 104,  25, 178, 252, 182, 202, 182, 141, 197,   4,  81, 181, 242,
		145,  42,  39, 227, 156, 198, 225, 193, 219,  93, 122, 175, 249,   0,
		175, 143,  70, 239,  46, 246, 163,  53, 163, 109, 168, 135,   2, 235,
		 25,  92,  20, 145, 138,  77,  69, 166,  78, 176, 173, 212, 166, 113,
		 94, 161,  41,  50, 239,  49, 111, 164,  70,  60,   2,  37, 171,  75,
		136, 156,  11,  56,  42, 146, 138, 229,  73, 146,  77,  61,  98, 196,
		135, 106,  63, 197, 195,  86,  96, 203, 113, 101, 170, 247, 181, 113,
		 80, 250, 108,   7, 255, 237, 129, 226,  79, 107, 112, 166, 103, 241,
		 24, 223, 239, 120, 198,  58,  60,  82, 128,   3, 184,  66, 143, 224,
		145, 224,  81, 206, 163,  45,  63,  90, 168, 114,  59,  33, 159,  95,
		 28, 139, 123,  98, 125, 196,  15,  70, 194, 253,  54,  14, 109, 226,
		 71,  17, 161,  93, 186,  87, 244, 138,  20,  52, 123, 251,  26,  36,
		 17,  46,  52, 231, 232,  76,  31, 221,  84,  37, 216, 165, 212, 106,
		197, 242,  98,  43,  39, 175, 254, 145, 190,  84, 118, 222, 187, 136,
		120, 163, 236, 249 };

		return rnd_table[Random(0, 255)];
	}

	action void A_FireGun(double spread = 0.0)
	{
		int dmg;

		Actor tgt = AimTarget();

		if (tgt)
		{
			dmg = WolfRandom();

			Vector2 offset = tgt.pos.xy - pos.xy;

			int dx = int(abs(offset.x));
			int dy = int(abs(offset.y));

			int dist = dx > dy ? dx : dy;
			dist /= 64;

			if (dist < 2) { dmg /= 4; }
			else if (dist < 4) { dmg /= 6; }
			else
			{
				if ((WolfRandom() / 12) < dist) { dmg = 0; }
				else { dmg /= 6; }
			}
		}

		A_FireBullets(spread, spread, 1, dmg, "WolfPuff", FBF_NORANDOM | FBF_USEAMMO);
	}

	override void DoEffect()
	{
		if (owner && owner.player && owner.player.ReadyWeapon == self)
		{
			CVar bobscale = CVar.GetCVar("g_viewbobscale", owner.player);
			if (bobscale)
			{
				bobrangex = Default.bobrangex * bobscale.GetFloat();
				bobrangey = Default.bobrangey * bobscale.GetFloat();
			}
		}
	}
}

class WolfPuff : BulletPuff
{
	override void PostBeginPlay()
	{
		bInvisible = g_noblood;

		Super.PostBeginPlay();
	}
}

class WolfClip : Ammo
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Ammo
		//$Title Bullets (8)
		//$Color 3

		Mass 10000;
		Inventory.Amount 8;
		Inventory.Icon "I_CLIP_O";
		Inventory.AltHUDIcon "I_CLIP";
		Inventory.MaxAmount 99;
		Inventory.PickupMessage "";
		Inventory.PickupSound "pickups/ammo";
		Ammo.BackpackAmount 20;
		Ammo.BackpackMaxAmount 199;
	}

	States
	{
		Spawn:
			CCLI A -1;
			Loop;
	}
}

class WolfClipLost : WolfClip
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Ammo/Lost Episodes
		//$Title Bullets (8, Lost)
		Inventory.Icon "WCLIB0";
	}

	States
	{
		Spawn:
			WCLI B -1;
			Loop;
	}
}

class WolfClipDrop : WolfClip
{
	Default
	{
		Inventory.Amount 4;
	}
}

class WolfClipDropLost : WolfClipLost
{
	Default
	{
		Inventory.Amount 4;
	}
}

class WolfClipBox : WolfClip
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Ammo
		//$Title Bullets (25)
		Inventory.Amount 25;
		Inventory.Pickupsound "pickups/ammobox";
	}

	States
	{
		Spawn:
			WAMM A -1;
			Loop;
	}
}

class WolfClipBoxLost : WolfClipBox
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Ammo/Lost Episodes
		//$Title Bullets (25, Lost)
	}

	States
	{
		Spawn:
			WAMM B -1;
			Loop;
	}
}

class WolfKnife : ClassicWeapon
{
	bool adrenaline;

	Default
	{
		//$Title Knife
		+Weapon.NoAlert
		AttackSound "";
		Tag "$WPN_KNIFE";
		Inventory.Icon "KNIFE";
		Weapon.AmmoUse 0;
		Weapon.SelectionOrder 4;
	}

	States
	{
		Spawn:
			CKNI P -1;
			Loop;
		Ready:
			CKNI A 1 A_WeaponReady();
			Loop;
		Fire:
			"####" B 3;
			"####" C 3 A_CustomPunch(invoker.WolfRandom() >> (invoker.adrenaline ? 1 : 4), 1, 0, "WolfPuff", meleesound:"weapons/wknife", misssound:"weapons/wknife");
			"####" DE 3;
			"####" A 0 A_Jump(256, "Refire");
	}

	override void DoEffect()
	{
		Super.DoEffect();

		if (owner && owner.player && owner.player.ReadyWeapon == self)
		{
			adrenaline = !!owner.FindInventory("PowerStrength", true);
		}
	}
}

class WolfPistol : ClassicWeapon
{
	Default
	{
		//$Title Pistol
		AttackSound "weapons/wpistol";
		Tag "$WPN_PISTOL";
		Inventory.Icon "LUGER";
		Inventory.PickupSound "pickups/ammo";
		Weapon.AmmoType "WolfClip";
		Weapon.AmmoGive 0;
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 3;
	}

	States
	{
		Spawn:
			CLUG P -1;
			Loop;
		Ready:
			CLUG A 1 A_WeaponReady();
			Loop;
		Fire:
			"####" B 3;
			"####" C 3 Bright A_FireGun(2.0);
			"####" DE 3;
			"####" A 0 A_Jump(256, "Refire");
	}
}
 
class WolfMachineGun : ClassicWeapon
{
	Default
	{
		//$Title Machine Gun
		AttackSound "weapons/wmachinegun";
		Tag "$WPN_MGUN";
		Inventory.Icon "MGUN";
		Inventory.PickupSound "pickups/MGUN";
		Weapon.AmmoType "WolfClip";
		Weapon.AmmoGive 6;
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 2;
	}

	States
	{
		Spawn:
			CMGU P -1;
			Loop;
		Ready:
			CMGU A 1 A_WeaponReady();
			Loop;
		Fire:
			"####" B 3;
		Hold:
			"####" C 3 Bright A_FireGun(3.0);
			"####" D 3;
			"####" E 3 A_ReFire();
			"####" A 0 A_Jump(256, "Ready");
	}
} 

class WolfChaingun : ClassicWeapon
{
	Default
	{
		//$Title Chain Gun
		AttackSound "weapons/wchaingun";
		Tag "$WPN_CGUN";
		Inventory.Icon "CGUN";
		Inventory.PickupSound "pickups/CGUN";
		Weapon.AmmoType "WolfClip";
		Weapon.AmmoGive 6;
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 1;
	}

	States
	{
		Spawn:
			CCGU P -1;
			Loop;
		Ready:
			CCGU A 1 A_WeaponReady();
			Loop;
		Fire:
			"####" B 3;
		Hold:
			"####" CD 3 Bright A_FireGun(4.0);
			"####" E 3 A_ReFire();
			"####" A 0 A_Jump(256, "Ready");
	}

	override void Touch(Actor toucher)
	{
		if (ClassicStatusBar(StatusBar)) { ClassicStatusBar(StatusBar).DoGrin(toucher); }

		Super.Touch(toucher);
	}
}

class WolfChaingunSoD : WeaponGiver
{
	Default
	{
		//$Title Chain Gun (Spear of Destiny)
		Inventory.PickupMessage "";
		Inventory.PickupSound "pickups/cgunsod";
		DropItem "WolfChaingun";
	}

	States
	{
		Spawn:
			CCGU P -1;
			Loop;
	}
}

class WolfKnifeLost : WolfKnife
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Weapons/Lost Episodes
		//$Title Knife (Lost)
		Weapon.SlotPriority 2;
		+Weapon.CHEATNOTWEAPON
	}

	States
	{
		Ready:
			KNIL A 1 A_WeaponReady();
			Loop;
	}
}

class WolfPistolLost : WolfPistol
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Weapons/Lost Episodes
		//$Title Pistol (Lost)
		AttackSound "weapons/wpistol2";
		Weapon.SlotPriority 2;
		+Weapon.CHEATNOTWEAPON
	}

	States
	{
		Ready:
			LUGL A 1 A_WeaponReady();
			Loop;
	}
}

class WolfMachineGunLost : WolfMachineGun
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Weapons/Lost Episodes
		//$Title Machine Gun (Lost)
		AttackSound "weapons/wmachinegun2";
		Weapon.SlotPriority 2;
		+Weapon.CHEATNOTWEAPON
	}

	States
	{
		Spawn:
			MGUN U -1;
			Loop;
		Ready:
			MGUL A 1 A_WeaponReady();
			Loop;
	}
}

class WolfChaingunLost : WolfChaingun
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Weapons/Lost Episodes
		//$Title Chain Gun (Lost)
		Inventory.PickupSound "pickups/cgunlost";
		AttackSound "weapons/wchaingun2";
		Weapon.SlotPriority 2;
		+Weapon.CHEATNOTWEAPON
	}

	States
	{
		Spawn:
			CGUN U -1;
			Loop;
		Ready:
			CGUL A 1 A_WeaponReady();
			Loop;
	}
}

class WolfGas : Ammo
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Ammo
		//$Title Flamethrower Ammo (14)
		Mass 10000;
		Inventory.Amount 14;
		Inventory.Icon "I_GAS_O";
		Inventory.AltHUDIcon "I_GAS";
		Inventory.MaxAmount 99;
		Inventory.PickupMessage "";
		Inventory.PickupSound "pickups/ammo";
		Ammo.BackpackAmount 2;
		Ammo.BackpackMaxAmount 199;
	}

	States
	{
		Spawn:
			WGAS A -1;
			Loop;
	}
}

class WolfFlameThrower : ClassicWeapon
{
	Default
	{
		//$Title Flame Thrower
		Tag "$WPN_FTHR";
		Inventory.Icon "FTHR";
		Inventory.PickupSound "pickups/ammo";
		Weapon.AmmoType "WolfGas";
		Weapon.AmmoGive 6;
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 1;
		Weapon.SlotNumber 5;
		+Weapon.CHEATNOTWEAPON
	}

	States
	{
		Spawn:
			FLAM P -1;
			Loop;
		Ready:
			WFLM A 1 A_WeaponReady();
			Loop;
		Fire:
			WFLM B 2;
		Hold:
			WFLM CD 3 Bright A_FireProjectile("WolfFlame", 0, 1, 0, -8);
			WFLM # 0 A_ReFire;
			Goto Ready;
	}
} 

class WolfRocketPickup : Ammo
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Ammo
		//$Title Rocket (1)
		Mass 10000;
		Inventory.Amount 1;
		Inventory.Icon "I_ROCKET_O";
		Inventory.AltHUDIcon "I_ROCKET";
		Inventory.MaxAmount 99;
		Inventory.PickupMessage "";
		Inventory.PickupSound "pickups/ammo";
		Ammo.BackpackAmount 5;
		Ammo.BackpackMaxAmount 99;
	}

	States
	{
		Spawn:
			WRKT A -1;
			Loop;
	}
}

class WolfRocketCrate : WolfRocketPickup
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Ammo
		//$Title Rockets (3)
		Inventory.Amount 5;
	}

	States
	{
		Spawn:
			WRKT B -1;
			Loop;
	}
}

class WolfRocketLauncher : ClassicWeapon
{
	Default
	{
		//$Title Rocket Launcher
		AttackSound "flame/fire";
		Tag "$WPN_ROCK";
		Inventory.Icon "ROCK";
		Inventory.PickupSound "pickups/ammo";
		Weapon.AmmoType "WolfRocketPickup";
		Weapon.AmmoGive 6;
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 5;
		Weapon.SlotNumber 6;
		+Weapon.CHEATNOTWEAPON
		+Weapon.EXPLOSIVE
	}

	States
	{
		Spawn:
			WROC P -1;
			Loop;
		Ready:
			WROC A 1 A_WeaponReady();
			Loop;
		Fire:
			WROC B 3;
		Hold:
			WROC B 2 Bright A_FireProjectile("WolfRocketPlayer", 0, 1, 0, -8);
			WROC C 10;
			WROC D 25;
			WROC D 5 A_ReFire;
			Goto Ready;
	}
}

class WolfBackpack : Backpack
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Ammo
		//$Color 3
		Inventory.PickupMessage "";
		Inventory.PickupSound "pickups/ammo";
	}

	States
	{
		Spawn:
			WPAK A -1;
			Stop;
	}
}