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

// Wolf3D Weapons
class ClassicWeapon : Weapon
{
	int flags;

	FlagDef DOGRIN:flags, 0;

	Default
	{
		//$Category Wolfenstein 3D/Items/Weapons
		//$Color 3

		Mass 10000;
		Obituary "";
		Inventory.PickupMessage "";
		Weapon.YAdjust 2.0;
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
			"####" "#" 0 A_QuickRaise();
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

	// Raise the weapon sprite immediately to the ready position
	action void A_QuickRaise()
	{
		let psp = player.GetPSprite(PSP_WEAPON);
		if (!psp) { return; }

		ResetPSprite(psp);

		psp.SetState(player.ReadyWeapon.GetReadyState());
	}

	action void A_FireGun(double spread = 0.0)
	{
		int dmg;

		Actor tgt = AimTarget();

		if (tgt)
		{
			dmg = GameHandler.WolfRandom();
			
			if (ClassicBase(tgt))
			{
				if (!ClassicBase(tgt).bActive)
				{
					dmg <<= 1; // Double damage for non-awake enemies
					if (!(player.cheats & CF_NOTARGET)) { tgt.SetStateLabel("See"); } // And wake up the enemy and their peers
				}
			}

			Vector2 offset = tgt.pos.xy - pos.xy;

			int dx = int(abs(offset.x));
			int dy = int(abs(offset.y));

			int dist = dx > dy ? dx : dy;
			dist /= 64;

			if (dist < 2) { dmg /= 4; }
			else if (dist < 4) { dmg /= 6; }
			else
			{
				if ((GameHandler.WolfRandom() / 12) < dist) { dmg = 0; }
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
				bobrangex = Default.bobrangex * bobscale.GetFloat() / WeaponScaleY;
				bobrangey = Default.bobrangey * bobscale.GetFloat() / WeaponScaleY;
			}

			SetYPosition();
		}
	}

	virtual void SetYPosition()
	{
		let psp = owner.player.GetPSprite(PSP_WEAPON);
		if (!psp) { return; }

		if (screenblocks < 11) { psp.y = WEAPONTOP - 15.0 * max(st_scale, 0) / WeaponScaleY; }
		else { psp.y = WEAPONTOP + 6.0 / WeaponScaleY; }
	}

	override void Touch(Actor toucher)
	{
		if (bDoGrin && ClassicStatusBar(StatusBar)) { ClassicStatusBar(StatusBar).DoGrin(toucher); }

		Super.Touch(toucher);
	}

	override void BeginPlay()
	{
		Super.BeginPlay();

		// If the weapon sprite is 64x64, assume it's an original sprite and scale it up.
		// Otherwise don't mess with it
		State ReadyState = FindState("Ready");
		if (ReadyState && ReadyState.sprite)
		{
			TextureID tex = ReadyState.GetSpriteTexture(0);
			if (tex.IsValid())
			{
				Vector2 size = TexMan.GetScaledSize(tex);
				if (size.x == size.y && size.x <= 64.0)
				{
					double factor = 160.0 / size.x;
					WeaponScaleX = Default.WeaponScaleX * factor;
					WeaponScaleY = Default.WeaponScaleY * factor;
				}
			}
		}
	}
}

class WolfPuff : BulletPuff
{
	Default
	{
		+ROLLSPRITE
		Alpha 1.0;
	}

	override void PostBeginPlay()
	{
		bInvisible = g_noblood;

		Super.PostBeginPlay();

		roll = Random(0, 3) * 90;
	}

	States
	{
		Spawn:
			WPUF A 4 Bright;
			WPUF B 4 Bright { if (!g_noblood) { A_FadeOut(0.25); } }
		Melee:
			WPUF CD 4 { if (!g_noblood) { A_FadeOut(0.2); } }
			Stop;
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
		AttackSound "";
		Tag "$WPN_KNIFE";
		Inventory.Icon "KNIFE";
		Inventory.PickupSound "pickups/knife";
		Weapon.AmmoUse 0;
		Weapon.SelectionOrder 4;
		+Weapon.NOALERT
		+Weapon.MELEEWEAPON
		+Weapon.WIMPY_WEAPON
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
			"####" C 3;
			"####" D 3 A_WolfPunch(GameHandler.WolfRandom() >> (invoker.adrenaline ? 1 : 4), 1, 0, "WolfPuff", meleesound:"weapons/wknife", misssound:"weapons/wknife");
			"####" E 3;
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

	// Specialized A_CustomPunch that doubles damage for non-alerted actors
	action void A_WolfPunch(int damage, bool norandom = false, int flags = CPF_USEAMMO, class<Actor> pufftype = "BulletPuff", double range = 0, double lifesteal = 0, int lifestealmax = 0, class<BasicArmorBonus> armorbonustype = "ArmorBonus", sound MeleeSound = 0, sound MissSound = "")
	{
		let player = self.player;
		if (!player) return;

		let weapon = player.ReadyWeapon;

		double angle;
		double pitch;
		FTranslatedLineTarget t;
		int			actualdamage;

		if (!norandom)
			damage *= random[cwpunch](1, 8);

		angle = self.Angle + random2[cwpunch]() * (5.625 / 256);
		if (range == 0) range = DEFMELEERANGE;
		pitch = AimLineAttack (angle, range, t, 0., ALF_CHECK3D);

		if (t.linetarget && ClassicBase(t.linetarget))
		{
			if (!ClassicBase(t.linetarget).bActive)
			{
				damage <<= 1; // Double damage for non-awake enemies
				if (!(player.cheats & CF_NOTARGET)) { t.linetarget.SetStateLabel("See"); } // And wake up the enemy and their peers
			}
		}

		// only use ammo when actually hitting something!
		if ((flags & CPF_USEAMMO) && t.linetarget && weapon && stateinfo != null && stateinfo.mStateType == STATE_Psprite)
		{
			if (!weapon.DepleteAmmo(weapon.bAltFire, true))
				return;	// out of ammo
		}

		if (pufftype == NULL)
			pufftype = 'BulletPuff';
		int puffFlags = LAF_ISMELEEATTACK | ((flags & CPF_NORANDOMPUFFZ) ? LAF_NORANDOMPUFFZ : 0);

		Actor puff;
		[puff, actualdamage] = LineAttack (angle, range, pitch, damage, 'Melee', pufftype, puffFlags, t);

		if (!t.linetarget)
		{
			if (MissSound) A_StartSound(MissSound, CHAN_WEAPON);
		}
		else
		{
			if (lifesteal > 0 && !(t.linetarget.bDontDrain))
			{
				if (flags & CPF_STEALARMOR)
				{
					if (armorbonustype == NULL)
					{
						armorbonustype = 'ArmorBonus';
					}
					if (armorbonustype != NULL)
					{
						let armorbonus = BasicArmorBonus(Spawn(armorbonustype));
						if (armorbonus)
						{
							armorbonus.SaveAmount *= int(actualdamage * lifesteal);
							if (lifestealmax > 0) armorbonus.MaxSaveAmount = lifestealmax;
							armorbonus.bDropped = true;
							armorbonus.ClearCounters();

							if (!armorbonus.CallTryPickup(self))
							{
								armorbonus.Destroy ();
							}
						}
					}
				}
				else
				{
					GiveBody (int(actualdamage * lifesteal), lifestealmax);
				}
			}
			if (weapon != NULL)
			{
				if (MeleeSound) A_StartSound(MeleeSound, CHAN_WEAPON);
				else			A_StartSound(weapon.AttackSound, CHAN_WEAPON);
			}

			if (!(flags & CPF_NOTURN))
			{
				// turn to face target
				self.Angle = t.angleFromSource;
			}

			if (flags & CPF_PULLIN) self.bJustAttacked = true;
			if (flags & CPF_DAGGER) t.linetarget.DaggerAlert (self);
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
		Inventory.PickupSound "pickups/pistol";
		Weapon.AmmoType "WolfClip";
		Weapon.AmmoGive 8;
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 3;
		+Weapon.WIMPY_WEAPON
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
			"####" C 3 Bright;
			"####" D 3 A_FireGun(2.0);
			"####" E 3;
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
			"####" C 3 Bright;
			"####" D 3 A_FireGun(3.0);
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
		+ClassicWeapon.DOGRIN
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
			"####" C 3 Bright;
			"####" D 3 Bright A_FireGun(4.0);
			"####" "#" 0 A_FireGun(4.0);
			"####" E 3 A_ReFire();
			"####" A 0 A_Jump(256, "Ready");
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

	override void Touch(Actor toucher)
	{
		if (ClassicStatusBar(StatusBar)) { ClassicStatusBar(StatusBar).DoGrin(toucher); }

		Super.Touch(toucher);
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
		//$Color 3
		Mass 10000;
		Inventory.Amount 14;
		Inventory.Icon "I_GAS_O";
		Inventory.AltHUDIcon "I_GAS";
		Inventory.MaxAmount 99;
		Inventory.PickupMessage "";
		Inventory.PickupSound "pickups/gas";
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
		Inventory.PickupSound "pickups/flamer";
		Weapon.AmmoType "WolfGas";
		Weapon.AmmoGive 6;
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 1;
		Weapon.SlotNumber 5;
		Weapon.WeaponScaleX 1.0;
		Weapon.WeaponScaleY 1.2;
		+Weapon.CHEATNOTWEAPON
		+ClassicWeapon.DOGRIN
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
		//$Color 3
		Mass 10000;
		Inventory.Amount 1;
		Inventory.Icon "I_ROCKET_O";
		Inventory.AltHUDIcon "I_ROCKET";
		Inventory.MaxAmount 99;
		Inventory.PickupMessage "";
		Inventory.PickupSound "pickups/rocket";
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
		Inventory.PickupSound "pickups/rocketbox";
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
		Inventory.PickupSound "pickups/rocketlauncher";
		Weapon.AmmoType "WolfRocketPickup";
		Weapon.AmmoGive 6;
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 5;
		Weapon.SlotNumber 6;
		Weapon.WeaponScaleX 1.0;
		Weapon.WeaponScaleY 1.2;
		+Weapon.CHEATNOTWEAPON
		+Weapon.EXPLOSIVE
		+ClassicWeapon.DOGRIN
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
		Inventory.PickupSound "pickups/backpack";
	}

	States
	{
		Spawn:
			WPAK A -1;
			Stop;
	}
}