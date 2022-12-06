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

// Secret door helper actors
class Secret_Block : Actor
{
	Default
	{
		Radius 32;
	}

	States
	{
		Spawn:
			TNT1 A -1;
			Stop;
	}
}

class Secret_Check : Actor
{
	Default
	{
		Radius 0;
		Height 64;
	}

	States
	{
		Spawn:
			TNT1 A -1;
			Stop;
	}
}

class SecretMarker : Actor
{
	bool activated;
	int touchRange;

	Property TouchRange:touchRange;

	Default
	{
		+INVISIBLE
		+NOTONAUTOMAP
		SecretMarker.TouchRange 30.0;
	}

	States
	{
		Spawn:
		Active:
			PUSH A -1;
			Stop;
		Inactive:
			TNT1 A -1;
			Stop;
	}

	override void PostBeginPlay ()
	{
		Super.PostBeginPlay();

		level.total_secrets++;

		if (!(SpawnFlags & MTF_DORMANT)) { Activate(null); }
		else { Deactivate(null); }
	}

	override void Activate (Actor activator)
	{
		if (bDormant) { level.total_secrets++; }

		bDormant = false; 
		touchRange = Default.touchRange; // Allow resetting touch deactivation by re-activating the actor
		SetStateLabel("Active");
	}

	override void OnDestroy()
	{
		Deactivate(null);
	}

	override void Deactivate (Actor activator)
	{
		if (!bDormant && activator) { Level.GiveSecret(activator, 0, 0); }
		bDormant = true;
		SetStateLabel("Inactive");
	}

	override void Tick()
	{
		Actor.Tick();

		if (!bDormant)
		{
			BlockThingsIterator it = BlockThingsIterator.Create(self, touchRange);

			while (it.Next())
			{
				if (!it.thing.player) { continue; }
				if (Distance2D(it.thing) > touchRange) { continue; }

				Deactivate(it.thing);
			}
		}
	}
}

// Patrol turn points
class Turn : SwitchableDecoration
{
	double ang;

	Property TurnAngle:ang;

	Default
	{
		//$Category Wolfenstein 3D/Patrol Turns
		//$Title Patrol Point - 0 degrees
		//$NotAngled
		//$Color 8
		//$Sprite AN000

		+SHOOTABLE
		+BUMPSPECIAL
		+NOTONAUTOMAP
		+INVISIBLE

		Mass 10000;
		Radius 30;
		Height 1;
		Activation THINGSPEC_Activate | THINGSPEC_TriggerActs | THINGSPEC_MonsterTrigger | THINGSPEC_ThingTargets | THINGSPEC_Switch;

		Turn.TurnAngle 0;
	}

	States
	{
		Spawn:
			TNT1 A 1;
			Wait;
		Inactive:
		Active:
			TNT1 A 10;
			TNT1 A 35 {
				if (target && ClassicBase(target) && !ClassicBase(target).bActive)
				{
					if (target.health <= 0) { return;}
					
					target.SetStateLabel("Spawn.Stand");
					target.vel *= 0;
					target.angle = ang;
					target.SetStateLabel("Spawn.Patrol");
				}
			}
			TNT1 A 70;
			Wait;
	}

	override void PostBeginPlay()
	{
		A_SetSize(0, 1, false);
		angle = ang;

		Super.PostBeginPlay();
	}
}

class Turn45 : Turn
{
	Default
	{
		//$Sprite AN045
		//$Title Patrol Point - 45 degrees
		Turn.TurnAngle 45;
	}
}

class Turn90 : Turn
{
	Default
	{
		//$Sprite AN090
		//$Title Patrol Point - 90 degrees
		Turn.TurnAngle 90;
	}
}

class Turn135 : Turn
{
	Default
	{
		//$Sprite AN135
		//$Title Patrol Point - 135 degrees
		Turn.TurnAngle 135;
	}
}

class Turn180 : Turn
{
	Default
	{
		//$Sprite AN180
		//$Title Patrol Point - 180 degrees
		Turn.TurnAngle 180;
	}
}

class Turn225 : Turn
{
	Default
	{
		//$Sprite AN225
		//$Title Patrol Point - 225 degrees
		Turn.TurnAngle 225;
	}
}

class Turn270 : Turn
{
	Default
	{
		//$Sprite AN270
		//$Title Patrol Point - 270 degrees
		Turn.TurnAngle 270;
	}
}

class Turn315 : Turn
{
	Default
	{
		//$Sprite AN315
		//$Title Patrol Point - 315 degrees
		Turn.TurnAngle 315;
	}
}

// Deathcam Spot
class DeathCam : Actor
{
	Default
	{
		+NOGRAVITY
		+NOBLOCKMAP

		Height 0;
		Radius 8;
	}

	States
	{
		Spawn:
			TNT1 A -1;
			Stop;
	}
}

// BJ victory run
class BJ : Actor
{
	Default
	{
		MONSTER;
		-COUNTKILL
		-SOLID
		-SHOOTABLE
		+FRIENDLY
		+FULLVOLDEATH
		+INVULNERABLE
		+NOTARGET
		+AMBUSH

		Renderstyle "None";
		Height 0;
		Radius 0;
		Speed 1.25;
		Health 5;
		DeathSound "bj/yell";
	}

	States
	{
		Spawn:
		Melee:
		Missile:
			BJJU AAABBBCCCDDD 2 A_Look;
			Loop;
		See: 
			BJJU ABCD 6 { Thrust(speed, angle); }
			BJJU ABCD 6 { Thrust(speed, angle); }
			BJJU ABCD 6 { Thrust(speed, angle); }
		Death:
		Jump:
			BJJU EF 7;
			BJJU G 7 A_Scream;
			BJJU H -1;
			Stop;
	}
}

class Fire : Actor
{
	Default
	{
		+BRIGHT
		+NOGRAVITY
		+NOINTERACTION
		RenderStyle "Translucent";
		Alpha 1.0;
	}

	States
	{
		Spawn:
			FIRE # 4 Advance();
			Loop;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		frame = Random(0, 7);
		vel.z = FRandom(0.05, 0.5);
	}

	void Advance()
	{
		frame = (frame + 1) % 8;

		if (GetAge() > 16)
		{
			alpha -= 0.1;
			if (alpha <= 0) { Destroy(); }
		}
	}
}

class SmallFire : Fire
{
	States
	{
		Spawn:
			FLA2 # 2 Advance();
	}
}

class Smoke : Actor
{
	Default
	{
		+NOGRAVITY
		+NOINTERACTION
		+ROLLSPRITE
		RenderStyle "Translucent";
		Alpha 0.72;
	}

	States
	{
		Spawn:
			RTRL A 1 A_FadeOut(0.02);
			Loop;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		vel.z = FRandom(0.05, 0.5);
		scale = FRandom(0.25, 0.75) * (1.0, 1.0);
		roll = Random(0, 7) * 45;
	}

	override void Tick()
	{
		if (IsFrozen()) { return; }

		Super.Tick();

		scale *= 1.025;
	}
}

class SmokeSpawner : Actor
{
	int interval, counter;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		interval = Random(10, 35);
	}

	override void Tick()
	{
		if (IsFrozen()) { return; }

		Super.Tick();

		if (counter++ % interval == 0)
		{
			Spawn("Smoke", pos);
		}

		if (counter++ > 105) { Destroy(); }
	}
}