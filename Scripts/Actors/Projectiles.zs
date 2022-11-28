// Wolf3D Projectiles and Puffs

class WolfProjectile : Actor
{
	Class<Actor> smoke;

	Property smoke:smoke;

	Default
	{
		Projectile;
		Radius 4;
		Speed 14;
		DamageType "WolfNazi";
	}

	virtual void SpawnSmoke()
	{
		if (smoke) { Spawn(smoke, pos); }
	}

	virtual int WolfExplode(int additional = 0, bool damage = true, int flags = XF_HURTSOURCE, int blastradius = 0)
	{
		int amt = (Game.WolfRandom() >> 3) + additional;

		if (blastradius <= 0) { blastradius = int(blastradius * 4); }

		if (damage) { A_Explode(amt, blastradius, flags); }

		return amt;
	}
}

// Wolf3D Rocket
class WolfRocket : WolfProjectile
{
	Default
	{
		SeeSound "missile/fire";
		DeathSound "missile/hit";

		WolfProjectile.Smoke "WolfRocketSmoke";
	}

	States
	{
		Spawn:
			ROCK A 1 Bright;
			ROCK A 1 Bright SpawnSmoke();
			Loop;
		Death:
			ROCP A 4 Bright WolfExplode(30);
			ROCP BC 4 Bright; // A_SetRenderStyle(0.5, STYLE_Translucent);
			Stop;
	}
}

class WolfRocketSOD : WolfRocket
{
	Default
	{
		SeeSound "missile/sodfire";
	}
}

class WolfRocketLost : WolfRocketSoD
{
	Default
	{
		WolfProjectile.Smoke "WolfRocketSmokeLost";
	}

	States
	{
		Spawn:
			ROCK B 1 Bright;
			ROCK B 1 Bright SpawnSmoke();
			Loop;
		Death:
			BAL4 A 4 Bright WolfExplode(30);
			BAL4 BC 4; // A_SetRenderStyle(0.5, STYLE_Translucent);
			Stop;
	}

}

class WolfRocketPlayer : WolfRocket
{
	Default
	{
		+RANDOMIZE
		Speed 20;
		DamageType "Rocket";
	}

	States
	{
		Death:
			ROCP A 4 Bright WolfExplode(100, true, XF_HURTSOURCE, 64);
			ROCP BC 4 Bright; // A_SetRenderStyle(0.5, STYLE_Translucent);
			Stop;
	}
}

class WolfRocketSmoke : Actor
{
	Default
	{
		+NOBLOCKMAP;
		+DROPOFF;
		+NOGRAVITY;
		-SOLID;
		Height 5;
		Radius 5;
		Speed 0;
	}

	States
	{
		Spawn:
			TNT1 A 3;
			RTRL ABC 2;
		Death:
			RTRL D 2;
			Stop;
	}
}

class WolfRocketSmokeLost : WolfRocketSmoke
{
	States
	{
		Spawn:
			TNT1 A 3;
			RTRL EFG 2;
		Death:
			RTRL H 2;
			Stop;
	}
}

// Schabbs Syringe
class Syringe : WolfProjectile
{
	Default
	{
		+ROLLSPRITE
		SeeSound "syringe/throw";
		DamageType "WolfNaziSyringe";
	}

	States
	{
		Spawn:
			WB3P ABCD 3;
			Loop;
		Death:
			SYRP A 2 {
				bInvisible = g_noblood;
				roll = Random(0, 7) * 45;
				scale.x *= RandomPick(-1, 1);
				WolfExplode(20);
			}
			SYRP BCD 2;
			Stop;
	}
}

// Hitler Ghost Fireballs 
class GhostFireBall : WolfProjectile
{
	Default
	{
		+ROLLSPRITE
		+MTHRUSPECIES
		Speed 2;
		SeeSound "flame/fire";
	}

	States
	{
		Spawn:
			BAL3 AB 4 Bright;
			Loop;
		Death:
			BALP A 4 Bright {
				bInvisible = g_noblood;
				roll = Random(0, 3) * 90;
				WolfExplode(0, flags:0);
			}
			BALP BC 4 Bright; // A_SetRenderStyle(0.5, STYLE_Translucent);
			Stop;
	}
}

//Used instead of GhostFireball when 'g_fastfireballs' cvar is true
// The original fireball speed in Wolf3D was dependant on processor speed
// instead of gametics...  So fireballs were faster on slower computers -
// the GhostFireBall actor above approximates the speed on a faster 
// machine; the one here is closer to the id-intended speed.
class FastGhostFireBall : GhostFireball
{
	Default
	{
		Speed 8;
	}
}

class WolfFlame : GhostFireball
{
	Default
	{
		DamageType "Fire";
		Speed 25;
	}
}

class SoDFireballBase : WolfProjectile
{
	Default
	{
		+MTHRUSPECIES
	}

	States
	{
		Spawn:
			TNT1 A 0;
		Fly:
			"####" ABCD 3 Bright;
			Loop;
		Death:
			"####" ABCD 1 Bright WolfExplode(30);
			Stop;
	}
}

//AoD Fireball
class GreenBall : SoDFireballBase
{
	Default
	{
		SeeSound "aod/fire";
	}

	States
	{
		Spawn:
			ADBL A 0 A_Jump(256, "Fly");
	}
}

//DI Fireball
class DIBall : SoDFireBallBase
{
	Default
	{
		SeeSound "aod/fire";
	}

	States
	{
		Spawn:
			DIBL A 0 A_Jump(256, "Fly");
	}
}