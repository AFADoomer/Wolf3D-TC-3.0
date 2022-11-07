class ClassicBase : Actor
{
	bool active;
	int scoreamt;
	int skillhealth0, skillhealth1, skillhealth2, skillhealth3;
	String basesprite;
	int baseflags;

	Property ScoreAmount:scoreamt;
	Property SkillHealth:skillhealth0, skillhealth1, skillhealth2, skillhealth3;
	Property BaseSprite:basesprite;

	FlagDef Lost:baseflags, 0;
	FlagDef NerfWhenReplaced:baseflags, 1;

	Default
	{
		//$Category Wolfenstein 3D/Enemies
		//$Color 4

		MONSTER;
		+FULLVOLACTIVE
		+FULLVOLDEATH
		+DONTGIB
		+DONTTHRUST

		Height 64;
		Radius 24;
		Mass 10000;
		DeathHeight 0;
		Painchance 256;
		BloodColor "FF 00 00";
		DamageFactor "WolfNazi", 0.0;
	}

	States
	{
		Spawn:
			UNKN A 0;
			Loop;
		See:
			"####" A 1 {
				if (!active)
				{
					if (tid)
					{
						int lookup = (tid > 500) ? tid - 500 : tid;

						let it = level.CreateActorIterator(lookup, "Actor");
						Actor mo;

						while (mo = Actor(it.Next()))
						{
							if (mo == self) { continue; }
							if (!mo.bIsMonster || mo.bDormant || !mo.bShootable || mo.health <= 0) { continue; }

							if (ClassicBase(mo))
							{
								if (ClassicBase(mo).active) { continue; }
								else { ClassicBase(mo).active = true; }
							}

							mo.target = target;
							mo.SetState(SeeState);
						}
					}

					active = true;
				}

				SetStateLabel("Chase");
			}
		SpriteList:
			WDOG A 0;
			WDOB A 0;
			WBRN A 0;
			WGRN A 0;
			WBLU A 0;
			WBLA A 0;
			WWHT A 0;
			WWH2 A 0;
			WMUT A 0;
			WBAT A 0;
			WBOS A 0; // Hans
			WBO3 A 0; // Schabbs
			WHR1 A 0; // Hitler Mech
			WHR2 A 0; // Hitler
			WBO8 A 0; // Giftmacher
			WBO4 A 0; // Gretel
			WBO5 A 0; // Fettgesicht
			WBO2 A 0; // Trans
			WBO6 A 0; // Ubermutant
			WBO7 A 0; // Death Knight
			WB10 A 0; // Angel of Death
			WSPE A 0; // Spectre
			WBO9 A 0; // Barnacle Wilhelm
			LBO2 A 0; // Submarine Willy
			LBO6 A 0; // The Axe
			LBO7 A 0; // Robot Droid
			LB10 A 0; // Devil Incarnate
			LBO9 A 0; // QuarkBlitz
			LSPE A 0; // Ghost
			LSP2 A 0; // Radioactive Mist
	}

	override void BeginPlay()
	{
		if (basesprite.length())
		{
			int spr = GetSpriteIndex(Name(basesprite));

			if (spr > -1) { sprite = spr; }
		}

		Super.BeginPlay();
	}

	override void PostBeginPlay()
	{
		switch (skill)
		{
			default:
			case 0:
				health = skillhealth0 ? skillhealth0 : Default.health;
				break;
			case 1:
				health = skillhealth1 ? skillhealth1 : Default.health;
				break;
			case 2:
				health = skillhealth2 ? skillhealth2 : Default.health;
				break;
			case 3:
				health = skillhealth3 ? skillhealth3 : Default.health;
				break;
		}

		if (!Default.bNoBlood) { bNoBlood = g_noblood; }

		if (bNerfWhenReplaced)
		{
			// Nerf certain enemies if they're not in a Wolf3D map
			if (level.levelnum < 100 && floorpic != TexMan.CheckForTexture("FLOOR", TexMan.Type_Any)) { health /= 3; }
		}

		Super.PostBeginPlay();
	}

	void A_DeathDrop()
	{
		DropItem drops = GetDropItems();
		DropItem item;

		if (drops != null)
		{
			for (item = drops; item != null; item = item.Next)
			{
				String itemName = String.Format("%s", item.Name); // Don't know why I have to do this and the Length check, but 'DropItem ""' crashes without it, even if I check for != "", != null, etc...
				if (itemName.Length() > 0 && item.Name != 'None' && Random[DropItem](0, 256) <= item.Probability)
				{
					Actor mo = Spawn(item.Name, pos, ALLOW_REPLACE);

					if (mo)
					{
						mo.bDropped = true;
						mo.bNoGravity = false;	// [RH] Make sure it is affected by gravity

						let inv = Inventory(mo);
						if (inv)
						{
							inv.ModifyDropAmount(item.Amount);
							inv.bTossed = true;
							if (inv.SpecialDropAction(self))
							{
								// The special action indicates that the item should not spawn
								inv.Destroy();
							}
						}
					}
				}
			}
		}
	}

	void RemoveEnemies()
	{
		ThinkerIterator Actors = ThinkerIterator.Create("ClassicBase");
		Actor mo;

		while (mo = Actor(Actors.Next()))
		{
			if (mo == self) { continue; }
			if (!mo.bIsMonster && !mo.bMissile) { continue; }

			mo.SetStateLabel("null");
		}

	}

	void A_DeathScream()
	{
		int num = level.levelnum % 100;

		if (
			!Random(0, 128) &&
			(
				(Game.IsSoD() && (num == 19 || num == 20)) ||
				(!Game.IsSoD() && num == 10)
			)
		)
		{
			A_StartSound(level.levelnum > 800 ? "nazi/die2" : "nazi/die", CHAN_VOICE, CHANF_DEFAULT, 1, bBoss ? ATTN_NONE : ATTN_NORM);
		}
		else { A_Scream(); }
	}
}

class ClassicNazi : ClassicBase
{
	int deathtics;
	int flags;

	Property DeathTics:deathtics;
	FlagDef LongDeath:flags, 0;
	FlagDef Patrolling:flags, 1;

	Default
	{
		ClassicNazi.DeathTics 8;
	}

	States
	{
		Spawn:
			UNKN A 0;
		Spawn.Stand:
			"####" EEEEEE 4 A_LookEx (0, 0, 0, 2048, 0, "See");
			Loop;
		Spawn.PatrolNoClip:
			"####" A 0 A_JumpIf(angle % 45 != 0 || angle % 90 == 0, "TurnAround"); // Only do special "noclip" handling at precisely 45 degree diagonal angles
			"####" A 6 A_Warp(AAPTR_DEFAULT, 45, 0, 0, 0, WARPF_STOP | WARPF_INTERPOLATE, "Spawn.Patrol");
			"####" A 6 A_Warp(AAPTR_DEFAULT, 90, 0, 0, 0, WARPF_STOP | WARPF_INTERPOLATE, "Spawn.Patrol");
			"####" A 0 A_Jump(256, "TurnAround");
		TurnAround:
			"####" E 10;
			"####" EEE 1 ThrustThing (int(angle * 256 / 360), 1, 0, 0);
			"####" A 0 A_JumpIf((vel.x != 0) || (vel.y != 0), "Spawn.Patrol");
			"####" E 10;
			"####" EEE 1 ThrustThing (int(angle * 256 / 360), 1, 0, 0);
			"####" A 0 A_JumpIf((vel.x != 0) || (vel.y != 0), "Spawn.Patrol");
			"####" A 0 A_SetAngle(angle + 180);
			"####" A 0 A_Jump(256, "Spawn.Patrol");
		Spawn.Patrol:
			"####" AAA 1 ThrustThing (int(angle * 256 / 360), 1, 0, 0);
			"####" AAA 1 A_LookEx (0, 0, 0, 2048, 0, "See");
			"####" BBBBBB 1 A_LookEx (0, 0, 0, 2048, 0, "See");
			"####" CCC 1 ThrustThing (int(angle * 256 / 360), 1, 0, 0);
			"####" CCC 1 A_LookEx (0, 0, 0, 2048, 0, "See");
			"####" DDDDDD 1 A_LookEx (0, 0, 0, 2048, 0, "See");
			"####" A 0 A_JumpIf((vel.x == 0) && (vel.y == 0), "Spawn.PatrolNoClip");
			Loop;
		Chase:
			"####" A 0 { if (health <= 0) { SetStateLabel("Dead"); } }  // Just in case...
			"####" AAAAA 1 A_Chase;
			"####" A 1;
			"####" BBBB 1 A_Chase;
			"####" CCCCC 1 A_Chase;
			"####" CC 1;
			"####" DDDD 1 A_Chase;
			Loop;
		Pain:
			"####" A 0 A_JumpIf(health % 1, "Pain.Alt");
			"####" F 5 A_Pain;
			"####" A 0 A_Jump(256, "Chase");
		Pain.Alt:
			"####" J 5 A_Pain;
			"####" A 0 A_Jump(256, "Chase");
		Death:
			"####" A 0 {
				A_DeathScream();
				A_DeathDrop();
			}
			"####" K 7 A_SetTics(deathtics - 1);
			"####" L 8 A_SetTics(deathtics);
			"####" M 7 A_SetTics(deathtics - 1);
			"####" N 0 { if (bLongDeath) { A_SetTics(deathtics); } }
		Dead:
			"####" N -1 { if (bLongDeath) { frame = 14; } }
		Stop;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		if (bPatrolling) { SetStateLabel("Spawn.Patrol"); }
		else { SetStateLabel("Spawn.Stand"); }
	}
}

class ClassicBoss : ClassicBase
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Bosses

		+JUSTHIT
		+AMBUSH
		+LOOKALLAROUND
		+ClassicBase.NerfWhenReplaced

		MaxTargetRange 256;
		Painchance 0;
		DamageFactor "Rocket", 2.0;
		DamageFactor "Fire", 2.0;
	}

	States
	{
		Spawn:
			UNKN A 0;
		Stand:
			"####" A 5 A_Look();
			Loop;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		SetStateLabel("Stand");
	}
}

class Dog : ClassicNazi
{
	Default
	{
		//$Title Dog

		-CANUSEWALLS
		-ACTIVATEMCROSS

		Health 1;
		Height 38;
		Speed 5;
		MeleeDamage 2;
		SeeSound "dog/sight";
		AttackSound "dog/attack";
		DeathSound "dog/death";

		+ClassicNazi.Patrolling
		ClassicBase.ScoreAmount 200;
		ClassicBase.BaseSprite "WDOG";
	}

	States
	{
		TurnAround:
			"####" AB 5;
			"####" CCC 1 ThrustThing (int(angle * 256 / 360), 1, 0, 0);
			"####" A 0 A_JumpIf((vel.x != 0) || (vel.y != 0), "Spawn.Patrol");
			"####" DA 5;
			"####" BBB 1 ThrustThing (int(angle * 256 / 360), 1, 0, 0);
			"####" A 0 A_JumpIf((vel.x != 0) || (vel.y != 0), "Spawn.Patrol");
			"####" A 0 A_SetAngle(angle + 180);
			Goto Spawn.Patrol;
		Spawn.Stand:
			"####" AAAABBBBCCCCDDDD 1 A_LookEx (0, 0, 0, 2048, 0, "See");
			Loop;
		Melee:
			"####" E 0 A_Stop;
			"####" EF 5 A_FaceTarget;
			"####" G 5 A_CustomMeleeAttack(random(1,15));
			"####" EA 5;
			Goto Chase;
		Death:
			"####" A 0 A_DeathScream;
			"####" HIJ 5;
		Dead:
			"####" K -1;
			Stop;
	}
}

class Doberman : Dog
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Lost Episodes
		//$Title Doberman

		SeeSound "doberman/sight";
		AttackSound "doberman/attack";
		DeathSound "doberman/death";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "WDOB";
	}
}

class Guard : ClassicNazi
{
	Default
	{
		//$Title Guard
		//$Sprite "WBRNE2"

		Health 25;
		Speed 3;
		SeeSound "brown/sight";
		AttackSound "shots/single";
		DeathSound "brown/death";
		DropItem "WolfClip";

		ClassicBase.ScoreAmount 100;
		ClassicBase.BaseSprite "WBRN";
	}

	States
	{
		Missile:
			"####" # 0 A_Stop;
			"####" GH 10 A_FaceTarget;
			"####" I 8 Bright A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			Goto Chase;
	}
}

class GreenGuard : Guard
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Lost Episodes
		//$Sprite "WGRNE2"

		SeeSound "green/sight";
		AttackSound "shots/single2";
		DeathSound "green/death";
		DropItem "WolfClipLost";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "WGRN";
	}
}

class MGuard : Guard
{
	Default
	{
		//$Title Guard (Moving)
		//$Sprite "WBRNA2"

		+JUSTHIT
		+ClassicNazi.Patrolling
	}
}

class MGreenGuard : GreenGuard
{
	Default
	{
		//$Title Guard (Moving)
		//$Sprite "WGRNA2"

		+JUSTHIT
		+ClassicNazi.Patrolling
	}
}

class SS : ClassicNazi
{
	Default
	{
		//$Title SS Guard
		//$Sprite "WBLUE2"

		Health 100;
		Speed 4;
		SeeSound "blue/sight";
		AttackSound "shots/burst";
		DeathSound "blue/death";

		ClassicBase.ScoreAmount 500;
		ClassicBase.BaseSprite "WBLU";
	}

	States
	{
		Missile:
			"####" A 0 A_Stop;
			"####" GH 10 A_FaceTarget;
			"####" I 5 Bright A_WolfAttack(0, AttackSound, 0.666, 64, 64, 2, 4, 160.0);
			"####" H 5 A_FaceTarget;
			"####" I 5 Bright A_WolfAttack(0, AttackSound, 0.666, 64, 64, 2, 4, 160.0);
			"####" H 5 A_FaceTarget;
			"####" I 5 Bright A_WolfAttack(0, AttackSound, 0.666, 64, 64, 2, 4, 160.0);
			"####" H 5 A_FaceTarget;
			"####" I 5 Bright A_WolfAttack(0, AttackSound, 0.666, 64, 64, 2, 4, 160.0);
			Goto Chase;
		Death:
			"####" A 0 {
				if (target && target.CheckInventory(bLost ? "WolfMachinegunLost" : "WolfMachineGun", 1)) { A_SpawnItemEx(bLost ? "WolfCLipDropLost" : "WolfClipDrop"); }
				else { A_SpawnItemEx(bLost ? "WolfMachinegunLost" : "WolfMachineGun"); }
			}
			Goto Super::Death;
	}
}

class BlackSS : SS
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Lost Episodes
		//$Sprite "WBLAE2"

		SeeSound "black/sight";
		AttackSound "shots/burst2";
		DeathSound "black/death";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "WBLA";
	}
}

class MSS : SS
{
	Default
	{
		//$Title SS Guard (Moving)
		//$Sprite "WBLUA2"

		+JUSTHIT
		+ClassicNazi.Patrolling
	}
}

class MBlackSS : BlackSS
{
	Default
	{
		//$Title SS Guard (Moving)
		//$Sprite "WBLAA2"

		+JUSTHIT
		+ClassicNazi.Patrolling
	}

	States
	{
		Death:
			"####" A 0 {
				if (target && target.CheckInventory("WolfMachineGunLost", 1)) { A_SpawnItemEx("WolfClipDrop"); }
				else { A_SpawnItemEx("WolfMachineGunLost"); }
			}
			Goto ClassicNazi::Death;
	}
}

class Mutant : ClassicNazi
{
	Default
	{
		//$Title Mutant
		//$Sprite "WMUTE2"

		Speed 3;
		SeeSound "mutant/sight";
		AttackSound "shots/single";
		DeathSound "mutant/death";
		BloodColor "FF 00 FF";
		DropItem "WolfClip";

		+ClassicNazi.LongDeath
		ClassicBase.ScoreAmount 700;
		ClassicBase.SkillHealth 45, 55, 55, 65;
		ClassicNazi.DeathTics 4;
		ClassicBase.BaseSprite "WMUT";
	}

	States
	{
		Missile:
			"####" A 0 A_Stop;
			"####" G 3 A_FaceTarget;
			"####" H 10 Bright A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			"####" G 5 A_FaceTarget;
			"####" I 10 Bright A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			"####" A 0 A_JumpIfCloser(64.0, "Missile");
			Goto Chase;
	}
}

class BatLost : Mutant
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Lost Episodes
		//$Title Bat
		//$Sprite "WBATE0"
		DropItem "WolfClipLost";

		SeeSound "";
		AttackSound "shots/single2";
		DeathSound "gunbat/death";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "WBAT";
	}
}

class MMutant : Mutant
{
	Default
	{
		//$Title Mutant (Moving)
		//$Sprite "WMUTA2"

		+JUSTHIT
		+ClassicNazi.Patrolling
	}
}

class MBatLost : BatLost
{
	Default
	{
		//$Title Bat (Moving)
		//$Sprite "WBATA2"

		+JUSTHIT
		+ClassicNazi.Patrolling
	}
}

class Officer : ClassicNazi
{
	Default
	{
		//$Title Officer
		//$Sprite "WWHTE2"

		Speed 5;
		Health 50;
		SeeSound "white/sight";
		AttackSound "shots/single";
		DeathSound "white/death";
		DropItem "WolfClip";

		+ClassicNazi.LongDeath
		ClassicBase.ScoreAmount 400;
		ClassicNazi.DeathTics 6;
		ClassicBase.BaseSprite "WWHT";
	}

	States
	{
		Missile:
			"####" A 0 A_Stop;
			"####" G 3 A_FaceTarget;
			"####" H 10 A_FaceTarget;
			"####" I 5 Bright A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			Goto Chase;
	}
}

class AltOfficer : Officer
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Lost Episodes
		//$Sprite "WWHTE2"

		SeeSound "white2/sight";
		AttackSound "shots/single2";
		DeathSound "white2/death";
		DropItem "WolfClipLost";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "WWH2";
	}
}

class MOfficer : Officer
{
	Default
	{
		//$Title Officer (Moving)
		//$Sprite "WWHTA2"

		+JUSTHIT
		+ClassicNazi.Patrolling
	}
}

class MAltOfficer : AltOfficer
{
	Default
	{
		//$Title Officer (Moving)
		//$Sprite "WWH2A2"

		+JUSTHIT
		+ClassicNazi.Patrolling
	}
}

class HansGrosse : ClassicBoss
{
	Default
	{
		//$Title Hans Grosse

		Speed 3;
		MaxTargetRange 256;
		SeeSound "hans/sight";
		AttackSound "boss/attack";
		DeathSound "hans/death";
		DropItem "YellowKey";

		ClassicBase.BaseSprite "WBOS";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 850, 950, 1050, 1200;
	}

	States
	{
		Walk:
			"####" AAAAA 1 A_Chase (null, null);
			"####" A 1;
			"####" BBBB 1 A_Chase (null, null);
			"####" CCCCC 1 A_Chase (null, null);
			"####" CC 1;
			"####" DDDD 1 A_Chase (null, null);
		Chase:
			"####" AAAAA 1 A_Chase (null, "Missile");
			"####" A 1;
			"####" BBBB 1 A_Chase (null, "Missile");
			"####" CCCCC 1 A_Chase (null, "Missile");
			"####" CC 1;
			"####" DDDD 1 A_Chase (null, "Missile");
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 5 A_FaceTarget;
			"####" GFGFGE 5 Bright A_WolfAttack(0, AttackSound, 0.666, 64, 64, 2, 4, 160.0);
			"####" A 0 A_JumpIfCloser(64, "Missile");
			Goto Walk;
		Death:
			"####" H 3 A_DeathDrop();
			"####" H 4;
			"####" I 8 A_Scream;
			"####" J 7 A_BossDeath;
		Dead:
			"####" K -1;
			Stop;
	}
}

class DrSchabbs : ClassicBoss
{
	Default
	{
		//$Title Dr. Schabbs

		Speed 4;
		SeeSound "schabbs/sight";
		DeathSound "schabbs/death";

		ClassicBase.BaseSprite "WBO3";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 850, 950, 1550, 2400;
	}

	States
	{
		Chase:
			"####" AAAAA 1 A_Chase;
			"####" A 1;
			"####" BBBB 1 A_Chase;
			"####" CCCCC 1 A_Chase;
			"####" CC 1;
			"####" DDDD 1 A_Chase;
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 5 A_SpawnProjectile("Syringe", 30, 18, 0);
			Goto Chase;
		Death:
			"####" A 75 A_Scream;
			"####" H 5;
			"####" I 5;
			"####" J 5;
			"####" K 5 A_BossDeath;
		Dead:
			"####" K -1;
			Stop;
		Death.Cam:
			"####" K 5 A_FaceTarget;
			"####" K 5 RemoveEnemies();
			"####" K 60 A_SpawnItemEx("DeathCam", -64.0, 0, 32.0, 0, 0, 0, 180.0, 0, 0, 999);
			"####" A 60;
			"####" A 60 A_Scream;
			"####" HIJK 5;
			"####" K -1;
			Stop;
	}
}

class HitlerGhost : ClassicNazi
{
	Default
	{
		//$Title Fake Hitler

		+NOGRAVITY
		+DROPOFF
		+SPAWNFLOAT
		+FLOAT
		+JUSTHIT
		+AMBUSH
		+LOOKALLAROUND
		+ClassicBase.NerfWhenReplaced

		Speed 4;
		Painchance 0;
		SeeSound "hgst/sight";
		DeathSound "hgst/death";
		BloodColor "00 00 00";

		ClassicBase.ScoreAmount 2000;
		ClassicBase.SkillHealth 200, 300, 400, 500;
	}
	
	States
	{
		Spawn:
			WHGT A 0;
			Goto Spawn.Stand;
		Chase:
			WHGT AAAAA 1 A_Chase;
			WHGT A 1;
			WHGT BBBB 1 A_Chase;
			WHGT CCCCC 1 A_Chase;
			WHGT CC 1;
			WHGT DDDD 1 A_Chase;
			Loop;
		Missile:
			WHGT E 4 A_FaceTarget;
			WHGT EEEEEEEE 4 Bright A_SpawnProjectile(g_fastfireballs ? "FastGhostFireBall" : "GhostFireBall", 30, 0, 0);
			Goto Chase;
		Death:
			WHGT F 5 A_DeathDrop();
			WHGT G 5 A_Scream;
			WHGT HIJ 5;
		Dead:
			WHGT K -1;
			Stop;
	}
}

class HitlerMech : ClassicBoss
{
	Default
	{
		//$Title Hitler Mech

		Speed 2;
		SeeSound "hitler1/sight";
		AttackSound "boss/attack";
		PainSound "hitler1/death";
		DeathSound "hitler2/sight";

		ClassicBase.BaseSprite "WHR1";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 800, 950, 1050, 1200;
	}

	States
	{
		Chase:
			"####" AAAAA 1 A_Chase;
			"####" AAA 1 A_Pain;
			"####" BBBB 1 A_Chase;
			"####" CCCCC 1 A_Chase;
			"####" CCC 1 A_Pain;
			"####" DDDD 1 A_Chase;
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 5 A_FaceTarget;
			"####" GFGF 5 Bright A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			Goto Chase;
		Death:
			"####" H 5 A_Scream;
			"####" IJ 5;
			"####" K 0 A_SpawnItemEx("Hitler");
			"####" K 1 A_BossDeath;
			"####" K -1;
			Stop;
	}

}

class Hitler : ClassicBoss
{
	Default
	{
		Speed 4;
		AttackSound "boss/attack";
		PainSound "slurpie";
		DeathSound "hitler2/death";

		ClassicBase.BaseSprite "WHR2";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 500, 700, 800, 900;
	}

	States
	{
		Chase:
			"####" AAA 1 A_Chase;
			"####" AA 1;
			"####" B 1 A_Chase;
			"####" CCC 1 A_Chase;
			"####" CC 1;
			"####" D 1 A_Chase;
			Loop;
		Missile:
			"####" G 15 A_FaceTarget;
			"####" H 5 A_FaceTarget;
			"####" IHIH 5 Bright A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			Goto Chase;
		Death:
			"####" A 70 A_Scream;
			"####" JK 5 A_Pain;
			"####" LMNO 5;
			"####" P 5 A_BossDeath;
		Dead:
			"####" Q -1;
			Stop;
		Death.Cam:
			"####" Q 5 A_FaceTarget;
			"####" Q 5 RemoveEnemies();
			"####" Q 60 A_SpawnItemEx("DeathCam", -64.0, 0, 32.0, 0, 0, 0, 180.0, 0, 0, 999);
			"####" A 60;
			"####" A 70 A_Scream;
			"####" J 5 A_Pain;
			"####" KLMNOP 5;
			"####" Q -1;
			Stop;
	}
}

class Giftmacher : ClassicBoss
{
	Default
	{
		//$Title Giftmacher

		Speed 3;
		SeeSound "gift/sight";
		DeathSound "gift/death";

		ClassicBase.BaseSprite "WBO8";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 850, 950, 1050, 1200;
	}

	States
	{
		Chase:
			"####" AAAAA 1 A_Chase;
			"####" A 1;
			"####" BBBB 1 A_Chase;
			"####" CCCCC 1 A_Chase;
			"####" CC 1;
			"####" DDDD 1 A_Chase;
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 5 Bright A_SpawnProjectile("WolfRocket", 30, 13, 0);
			Goto Chase;
		Death:
			"####" A 70 A_Scream;
			"####" GHI 5;
			"####" J 1 A_BossDeath;
		Dead:
			"####" J -1;
			Stop;
		Death.Cam:
			"####" J 5 A_FaceTarget;
			"####" J 5 RemoveEnemies();
			"####" J 60 A_SpawnItemEx("DeathCam", -64.0, 0, 32.0, 0, 0, 0, 180.0, 0, 0, 999);
			"####" A 60;
			"####" A 70 A_Scream;
			"####" GHI 5;
			"####" J -1;
			Stop;
	}

}

class GretelGrosse : HansGrosse
{
	Default
	{
		//$Title Gretel Grosse

		SeeSound "gretel/sight";
		DeathSound "gretel/death";

		ClassicBase.BaseSprite "WBO4";
		ClassicBase.SkillHealth 850, 950, 1050, 1200;
	}
}

class Fettgesicht : ClassicBoss
{
	Default
	{
		//$Title FettGesicht

		Speed 4;
		SeeSound "fatface/sight";
		AttackSound "boss/attack";
		DeathSound "fatface/death";

		ClassicBase.BaseSprite "WBO5";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 850, 950, 1050, 1200;
	}

	States
	{
		Chase:
			"####" AAAAA 1 A_Chase;
			"####" A 1;
			"####" BBBB 1 A_Chase;
			"####" CCCCC 1 A_Chase;
			"####" CC 1;
			"####" DDDD 1 A_Chase;
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 5 A_FaceTarget;
			"####" G 5 Bright A_SpawnProjectile("WolfRocket", 30, 13, 0);
			"####" E 0 A_FaceTarget;
			"####" HGH 5 Bright A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			Goto Chase;
		Death:
			"####" A 70 A_Scream;
			"####" JK 5;
			"####" L 1;
			"####" L 4 A_BossDeath;
		Dead:
			"####" M -1;
			Stop;
		Death.Cam:
			"####" M 5 A_FaceTarget;
			"####" M 5 RemoveEnemies();
			"####" M 60 A_SpawnItemEx("DeathCam", -64.0, 0, 32.0, 0, 0, 0, 180.0, 0, 0, 999);
			"####" A 60;
			"####" A 70 A_Scream;
			"####" JK 5;
			"####" L 5;
			"####" M -1;
			Stop;
	}
}

class PacManGhost : ClassicBase
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Pacman

		MONSTER;
		+FLOAT
		+LOWGRAVITY
		+SPAWNFLOAT
		+INVULNERABLE
		+JUSTHIT
		+LOOKALLAROUND
		+NOBLOOD
		-COUNTKILL
		-CANPUSHWALLS
		-SOLID

		Radius 32;
		Speed 5;
		Painchance 0;
		SeeSound "";
		ActiveSound "";
		MeleeDamage 1;
	}

	States
	{
		Spawn:
			"####" AAAAABBBBB 1 A_Look;
			Loop;
		Chase:
			"####" AAAAABBBBB 1 A_Chase;
			Loop;
		Melee:
			"####" A 0 A_FaceTarget;
			"####" AAAAABBBBB 1 A_CustomMeleeAttack(MeleeDamage, "", "", "WolfNazi", false);
			Goto Chase;
		Dead:
			"####" A -1;
			Loop;
	}
}

class Blinky : PacManGhost
{
	Default
	{
		//$Title Blinky
	}

	States
	{
		Spawn:
			GHO0 A 0;
			Goto Super::Spawn;
	}
}

class Inky : PacManGhost
{
	Default
	{
		//$Title Inky
	}

	States
	{
		Spawn:
			GHO1 A 0;
			Goto Super::Spawn;
	}
}

class Pinky : PacManGhost
{
	Default
	{
		//$Title Pinky
	}

	States
	{
		Spawn:
			GHO2 A 0;
			Goto Super::Spawn;
	}
}

class Clyde : PacManGhost
{
	Default
	{
		//$Title Clyde
	}

	States
	{
		Spawn:
			GHO3 A 0;
			Goto Super::Spawn;
	}
}

class TransGrosse : HansGrosse
{
	Default
	{
		//$Title Trans Grosse

		SeeSound "trans/sight";
		DeathSound "trans/death";

		ClassicBase.BaseSprite "WBO2";
	}

	States
	{
		Death:
			"####" A 0 A_DeathDrop();
			"####" A 53 A_Scream;
			"####" H 7;
			"####" I 8;
			"####" J 7 A_BossDeath;
			"####" K -1;
			Stop;
	}
}

class SubmarineWilly : HansGrosse
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Bosses/Lost Episodes
		//$Title Submarine Willy

		SeeSound "willy/sight";
		DeathSound "willy/death";
		DropItem "YellowKeyLost";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "LBO2";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 950, 1050, 1150, 1300;
	}

	States
	{
		Death:
			"####" A 0 A_DeathDrop();
			"####" A 53 A_Scream;
			"####" H 7;
			"####" I 8;
			"####" J 7 A_BossDeath;
			"####" K -1 ;
			Stop;
	}
}

class UberMutant : ClassicBoss
{
	Default
	{
		//$Title Ubermutant

		BloodColor "FF 00 FF";
		Speed 5;
		SeeSound "uber/sight";
		AttackSound "shots/single";
		DeathSound "uber/death";
		DropItem "YellowKey";

		ClassicBase.BaseSprite "WBO6";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 1050, 1150, 1250, 1400;
	}

	States
	{
		Chase:
			"####" AAAAA 1 A_Chase;
			"####" A 1;
			"####" BBBB 1 A_Chase;
			"####" CCCCC 1 A_Chase;
			"####" CC 1;
			"####" DDDD 1 A_Chase;
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 6 BRIGHT A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			"####" E 0 A_FaceTarget;
			"####" G 6 BRIGHT A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			"####" E 0 A_FaceTarget;
			"####" H 6 BRIGHT A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			"####" E 0 A_FaceTarget;
			"####" G 6 BRIGHT A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			"####" E 0 A_FaceTarget;
			"####" F 6 BRIGHT A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			"####" E 0 A_FaceTarget;
			Goto Chase;
		Death:
			"####" A 36 A_Scream;
			"####" I 4 A_DeathDrop();
			"####" I 3;
			"####" J 8;
			"####" K 7;
			"####" L 8 A_BossDeath;
		Dead:
			"####" M -1;
			Stop;
	}
}

class TheAxe : UberMutant
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Bosses/Lost Episodes
		//$Title The Axe

		SeeSound "theaxe/sight";
		AttackSound "shots/single2";
		DeathSound "theaxe/death";
		DropItem "YellowKeyLost";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "LBO6";
	}
}

class DeathKnight : ClassicBoss
{
	Class<Actor> projectile;

	Property Projectile:projectile;

	Default
	{
		//$Title Death Knight

		Speed 4;
		SeeSound "dk/sight";
		AttackSound "boss/attack";
		DeathSound "dk/death";
		DropItem "YellowKey";

		ClassicBase.BaseSprite "WBO7";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 1250, 1350, 1450, 1600;

		DeathKnight.Projectile "WolfRocketSoD";
	}

	States
	{
		Chase:
			"####" AAAAA 1 A_Chase;
			"####" A 1;
			"####" BBBB 1 A_Chase;
			"####" CCCCC 1 A_Chase;
			"####" CC 1;
			"####" DDDD 1 A_Chase;
			Loop;
		Missile:
			"####" F 15 A_FaceTarget;
			"####" G 5 BRIGHT A_SpawnProjectile(projectile, 48, 15, 0);
			"####" I 5 BRIGHT A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			"####" I 0 A_FaceTarget;
			"####" H 5 BRIGHT A_SpawnProjectile(projectile, 48, -15, 0);
			"####" I 5 BRIGHT A_WolfAttack(0, AttackSound, 1.0, 64, 64, 2, 4, 160.0);
			Goto Chase;
		Death:
			"####" A 53 A_Scream;
			"####" K 5 A_DeathDrop();
			"####" LMNO 5;
			"####" P 5 A_BossDeath;
		Dead:
			"####" Q -1;
			Stop;
	}
}

class RobotDroid : DeathKnight
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Bosses/Lost Episodes
		//$Title Robot Droid

		SeeSound "robot/sight";
		AttackSound "shots/single2";
		DeathSound "robot/death";
		DropItem "YellowKeyLost";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "LBO7";

		DeathKnight.Projectile "WolfRocketLost";
	}
}

class AngelofDeath : ClassicBoss
{
	Class<Actor> ballclass;

	Property BallClass:ballclass;

	Default
	{
		//$Title Angel of Death

		Painchance 0;
		Speed 4;
		SeeSound "aod/sight";
		PainSound "aod/breathe";
		DeathSound "aod/death";

		ClassicBase.BaseSprite "WB10";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 1450, 1550, 1650, 2000;
		AngelOfDeath.BallClass "GreenBall";
	}

	States
	{
		Chase:
			"####" AAAAA 1 A_Chase;
			"####" A 1;
			"####" BBBB 1 A_Chase;
			"####" CCCCC 1 A_Chase;
			"####" CC 1;
			"####" DDDD 1 A_Chase;
			Loop;
		Missile:
			"####" G 5 A_FaceTarget;
			"####" H 10 A_FaceTarget;
			"####" G 5 BRIGHT A_SpawnProjectile(BallClass, 25, 13, 0);
			"####" G 0 A_Jump(127, "Chase");
			"####" G 5 A_FaceTarget;
			"####" H 10 A_FaceTarget;
			"####" G 5 BRIGHT A_SpawnProjectile(BallClass, 25, 13, 0);
			"####" G 0 A_Jump(127, "Chase");
			"####" G 5 A_FaceTarget;
			"####" H 10 A_FaceTarget;
			"####" G 5 BRIGHT A_SpawnProjectile(BallClass, 25, 13, 0);
		Tired:
			"####" I 20;
			"####" J 20 A_Pain;
			"####" I 20;
			"####" J 20 A_Pain;
			"####" I 20;
			"####" J 20 A_Pain;
			"####" I 20;
			"####" I 0 A_Pain;
			Goto Chase;
		Death:
			"####" A 52 A_Scream;
			"####" K 5;
			"####" L 5 A_StartSound("slurpie");
			"####" MNOP 5;
			"####" Q 5 A_BossDeath;
		Dead:
			"####" R -1;
			Stop;
	}
}

class DevilIncarnate : AngelOfDeath
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Bosses/Lost Episodes
		//$Title Devil Incarnate

		SeeSound "devil/sight";
		PainSound "";
		DeathSound "devil/death";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "LB10";
		AngelOfDeath.BallClass "DIBall";
	}
}

class BarnacleWilhelm : Fettgesicht
{
	Default
	{
		//$Title Trans Grosse

		SeeSound "wilhelm/sight";
		AttackSound "shots/single";
		DeathSound "wilhelm/death";
		DropItem "YellowKey";

		ClassicBase.BaseSprite "WBO9";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 950, 1050, 1150, 1300;
	}

	States
	{
		Death:
			"####" A 35 A_Scream;
			"####" J 5 A_DeathDrop();
			"####" K 5;
			"####" L 5 A_BossDeath;
		Dead:
			"####" M -1;
			Stop;
	}
}

class ProfessorQuarkblitz : BarnacleWilhelm
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Bosses/Lost Episodes
		//$Title Professor Quarkblitz

		SeeSound "quarkblitz/sight";
		AttackSound "shots/single2";
		DeathSound "quarkblitz/death";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "LBO9";
	}
}

class WolfSpectre : ClassicNazi
{
	Default
	{
		Monster;
		+FLOAT
		+LOWGRAVITY
		+SPAWNFLOAT
		+NOBLOOD
		+LOOKALLAROUND
		+AMBUSH
		-COUNTKILL
		+INVULNERABLE
		+ALLOWPAIN

		Speed 3;
		Painchance 256;
		RenderStyle "Translucent";
		Alpha 0.85;
		MeleeDamage 1;
		SeeSound "spectre/sight";
		PainSound "spectre/sight";

		ClassicBase.ScoreAmount 200;
		ClassicBase.BaseSprite "WSPE";
		ClassicBase.SkillHealth 5, 10, 15, 25;
	}

	States
	{
		Spawn.Stand:
			"####" AAAABBBBCCCCDDDD 1 A_Look;
			Loop;
		Chase:
			"####" AAAAABBBBBCCCCCDDDDD 1 A_Chase;
			Loop;
		Melee:
			"####" A 0 A_FaceTarget;
			"####" ABCD 2 A_CustomMeleeAttack(MeleeDamage, "", "", "WolfNazi", false);
			Goto Chase;
		Pain:
			"####" A 0 A_UnSetSolid;
			"####" A 0 A_UnSetShootable;
			"####" EFG 5;
			"####" H 160;
			"####" A 0 A_SetSolid;
			"####" A 0 A_SetShootable;
			"####" A 0 A_Pain;
			Goto Chase;
		Dead:
			"####" H -1;
			Stop;
	}
}

class WolfGhost : WolfSpectre
{
	Default
	{
		//$Category Wolfenstein 3D/Enemies/Lost Episodes/
		+ClassicBase.Lost
		ClassicBase.BaseSprite "LSPE";
	}
}

class RadioactiveMist : WolfGhost
{
	Default
	{
		+ClassicBase.Lost
		ClassicBase.BaseSprite "LSP2";
	}
}