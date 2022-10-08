// Wolf3D Projectiles and Puffs

// Wolf3D Rocket
class WolfRocketBase : Actor
{
	Class<Actor> smoke;

	Property smoke:smoke;

	Default
	{
		Projectile;
		Radius 4;
		Speed 14;
		SeeSound "missile/fire";
		DeathSound "missile/hit";

		WolfRocketBase.Smoke "WolfRocketSmoke";
	}

	States
	{
		Spawn:
			MISL A 1 Bright;
			MISL A 1 Bright A_SpawnItemEx(smoke, 0, 0, 0);
			Loop;
		Death:
			BAL3 CDE 4 Bright A_Explode(16, 32, 1);
			Stop;
	}
}

class WolfRocket : WolfRocketBase
{
	Default
	{
		DamageType "WolfNazi";
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
		WolfRocketBase.Smoke "WolfRocketSmokeLost";
	}
}

class WolfRocketPlayer : WolfRocketBase
{
	Default
	{
		Speed 20;
		Damage 20;
		+RANDOMIZE
	}

	States
	{
		Death:
			BAL3 CDE 4 Bright A_Explode();
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
class Syringe : Actor
{
	Default
	{
		Projectile;
		Speed 14;
		Damage 6;
		ExplosionDamage 6;
		ExplosionRadius 10;
		SeeSound "syringe/throw";
		DamageType "WolfNaziSyringe";
	}

	States
	{
		Spawn:
			WB3P ABCD 3;
			Loop;
		Death:
			TNT1 AAA 4 A_Explode;
			Stop;
	}
}

// Hitler Ghost Fireballs 
class GhostFireBallBase : Actor
{
	Default
	{
		Projectile;
		+MTHRUSPECIES
		Radius 4;
		Speed 2;
		DamageType "Fire";
		SeeSound "flame/fire";
	}

	States
	{
		Spawn:
			BAL3 AB 4 Bright;
			Loop;
		Death:
			BAL3 A 0 Bright A_Explode(16, 16, 1);
			Stop;
	}
}

class GhostFireball : GhostFireballBase
{
	Default
	{
		DamageType "WolfNazi";
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

class WolfFlame : GhostFireballBase
{
	Default
	{
		Speed 25;
		Damage 5;
		-MTHRUSPECIES
	}

	States
	{
		Death:
			BAL3 CDE 4 Bright;
			Stop;
	}
}


class SoDFireballBase : Actor
{
	Default
	{
		Projectile;
		+MTHRUSPECIES
		Radius 4;
		Speed 14;
		DamageType "WolfNazi";
	}

	States
	{
		Spawn:
			TNT1 A 0;
		Fly:
			"####" ABCD 3 Bright;
			Loop;
		Death:
			"####" ABCD 1 Bright A_Explode(20, 16, 1);
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