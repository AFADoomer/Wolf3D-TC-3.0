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

class ClassicBase : Actor
{
	int scoreamt;
	int skillhealth0, skillhealth1, skillhealth2, skillhealth3;
	String basesprite;
	SpriteID spr;
	State AttackState;
	Vector2 lastpos;
	Class<Inventory> dropweapon;
	MapHandler handler;

	int baseflags;

	Property ScoreAmount:scoreamt;
	Property SkillHealth:skillhealth0, skillhealth1, skillhealth2, skillhealth3;
	Property BaseSprite:basesprite;
	Property DropWeapon:dropweapon;

	FlagDef Lost:baseflags, 0;
	FlagDef NerfWhenReplaced:baseflags, 1;
	FlagDef Active:baseflags, 2;
	FlagDef Run:baseflags, 3;
	FlagDef OptionalRotations:baseflags, 4;

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
		FastSpeed 6; // Generic handling for supporting fast monsters 
		BloodColor "FF 00 00";
		DamageFactor "WolfNazi", 0.0;
	}

	States
	{
		Spawn:
			UNKN A 1;
			Loop;
		See:
			"####" A 1 {
				ActivatePeers();
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
			spr = GetSpriteIndex(Name(basesprite));

			if (spr > -1) { sprite = spr; }
		}
		else { spr = -1; }

		handler = MapHandler.Get();

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
			if (level.levelnum < 100 && level.levelnum > 999 && floorpic != TexMan.CheckForTexture("FLOOR", TexMan.Type_Any)) { health /= 3; }
		}

		AttackState = FindState("Attack");

		Super.PostBeginPlay();
	}

	override void Tick()
	{
		if (health > 0)
		{
			if (spr > -1 && sprite != spr) { sprite = spr; }

			if (!multiplayer && target && target.player && target.health <= 0)
			{
				if (AttackState) { frame = AttackState.frame; }
				tics = 105; // Make this friendly to the resurrect cheat and only freeze them for 3 seconds
			}
		}

		Super.Tick();

		if (
			!multiplayer && 
			(bOptionalRotations || InStateSequence(CurState, MissileState) || InStateSequence(CurState, ResolveState("Pain"))) &&
			!g_userotations
		)
		{
			spriterotation = deltaangle(angle, AngleTo(players[consoleplayer].mo));
		}
		else
		{
			spriterotation = 0;
		}
	}

	virtual void A_NaziChase(statelabel melee = '_a_chase_default', statelabel missile = '_a_chase_default', int chance = 0)
	{
		if (bDormant || !target) { return; }

		if (target.health <= 0)
		{
			target = null;
			SetStateLabel("Spawn.Stand");
			
			return;
		}

		bool dodge = false;
		State curmelee, curmissile;

		Vector2 delta = Vec2To(target);
		int dist = int(max(abs(delta.x) / 64, abs(delta.y) / 64));

		if (melee != '_a_chase_default') { curmelee = FindState(melee); }
		else { curmelee = MeleeState; }

		if (missile != '_a_chase_default') { curmissile = FindState(missile); }
		else { curmissile = MissileState; }

		if (CheckSight(target))
		{
			if (curmelee && Distance2D(target) <= MeleeRange)
			{
				if (AttackSound) { A_StartSound(AttackSound, CHAN_WEAPON, CHANF_DEFAULT, 1.0, ATTN_NORM); }
				SetState(curmelee);
				return;
			}
			else if (
				curmissile && 
				(
					GameHandler.WolfRandom() < chance || // Some boss enemies and fake Hitler
					(
						!chance && // All other enemies
						(
							dist < 1 || // // Allow enemies to fire repeatedly without moving if they are within one 64x64 map chunk
							GameHandler.WolfRandom() < (64 / dist) // or randomly, based on distance
						)
					)
				)
			)
			{
				SetState(curmissile);
				return;
			}

			dodge = true;
		}

		if (movedir == DI_NODIR)
		{
			if (dodge) { movedir = GetDodgeDir(); }
			else { movedir = GetChaseDir(); }

			if (movedir == DI_NODIR) { return; }

			lastpos = pos.xy;
			angle = movedir * 45;
		}

		if (level.Vec2Diff(pos.xy, lastpos).length() < 32.0)
		{
			if (TryWalk()) { return; }
			else if (BlockingLine && BlockingLine.special == 8)
			{
				if (bCanUseWalls && BlockingLine.activation & SPAC_MUse)
				{
					BlockingLine.Activate(self, 0, SPAC_Use);
					
					frame = 4;
					tics = 25;

					return;
				}
			}
		}

		if (bRun && dist < 4) { movedir = GetRunDir(); }
		else if (dodge) { movedir = GetDodgeDir(); }
		else { movedir = GetChaseDir(); }

		lastpos = pos.xy;
		angle = movedir * 45;
	}

	static const dirtype_t opposite[] = { DI_WEST, DI_SOUTHWEST, DI_SOUTH, DI_SOUTHEAST, DI_EAST, DI_NORTHEAST, DI_NORTH, DI_NORTHWEST, DI_NODIR };
	static const dirtype_t diags[] = { DI_NORTHWEST, DI_NORTHEAST, DI_SOUTHWEST, DI_SOUTHEAST };

	int GetDodgeDir()
	{
		int d[4];
		Vector2 delta;
		int temp, olddir, turnaround;

		olddir = movedir;
		turnaround = opposite[movedir];

		[delta, d[0], d[1]] = GetDirections();

		movedir = diags[((delta.y < 0) << 1) + (delta.x > 0)];
		if (TryWalk()) { return movedir; }

		if (d[0] == DI_NODIR) { d[0] = DI_WEST; }
		d[2] = opposite[d[0]];

		if (d[1] == DI_NODIR) { d[1] = DI_SOUTH; }
		d[3] = opposite[d[1]];

		Vector2 absdelta;
		absdelta.x = abs(delta.x);
		absdelta.y = abs(delta.y);
	
		if (absdelta.x > absdelta.y)
		{
			temp = d[0];
			d[0] = d[1];
			d[1] = temp;

			temp = d[2];
			d[2] = d[3];
			d[3] = temp;
		}

		if (GameHandler.WolfRandom() < 128)
		{
			temp = d[0];
			d[0] = d[1];
			d[1] = temp;

			temp = d[2];
			d[2] = d[3];
			d[3] = temp;
		}

		for (int i = 0; i < 4; i++)
		{
			if (d[i] == DI_NODIR || d[i] == turnaround) { continue; }

			movedir = d[i];
			if (TryWalk()) { return movedir; }
		}

		if (turnaround != DI_NODIR)
		{
			movedir = turnaround;
			if (TryWalk()) { return movedir; }
		}

		movedir = DI_NODIR;

		return movedir;
	}

	int GetChaseDir()
	{
		int d[2];
		Vector2 delta;
		int temp, olddir, turnaround;

		olddir = movedir;
		turnaround = opposite[movedir];
		[delta, d[0], d[1]] = GetDirections();
		
		Vector2 absdelta;
		absdelta.x = abs(delta.x);
		absdelta.y = abs(delta.y);

		if (absdelta.y > absdelta.x)
		{
			temp = d[0];
			d[0] = d[1];
			d[1] = temp;
		}

		if (d[0] == turnaround) { d[0] = DI_NODIR; }
		if (d[1] == turnaround) { d[1] = DI_NODIR; }

		if (d[0] != DI_NODIR)
		{
			movedir = d[0];
			if (TryWalk()) { return movedir; }
		}

		if (d[1] != DI_NODIR)
		{
			movedir = d[1];
			if (TryWalk()) { return movedir; }
		}

		if (olddir != DI_NODIR)
		{
			movedir = olddir;
			if (TryWalk()) { return movedir; }
		}

		if (GameHandler.WolfRandom() > 128)
		{
			for (temp = DI_EAST; temp <= DI_SOUTH; temp += 2)
			{
				if (temp == turnaround) { continue; }
				movedir = temp;
				if (TryWalk()) { return movedir; }
			}
		}
		else
		{
			for (temp = DI_SOUTH; temp >= DI_EAST; temp -= 2)
			{
				if (temp == turnaround) { continue; }
				movedir = temp;
				if (TryWalk()) { return movedir; }
			}
		}

		if (turnaround != DI_NODIR)
		{
			movedir = turnaround;
			if (TryWalk()) { return movedir; }
		}

		movedir = DI_NODIR;

		return movedir;
	}

	int GetRunDir()
	{
		int d[2];
		Vector2 delta;
		int temp;

		[delta, d[0], d[1]] = GetDirections();

		d[0] = opposite[d[0]];
		d[1] = opposite[d[1]];

		if (d[0] == DI_NODIR) { d[0] = DI_WEST; }
		if (d[1] == DI_NODIR) { d[1] = DI_SOUTH; }

		Vector2 absdelta;
		absdelta.x = abs(delta.x);
		absdelta.y = abs(delta.y);

		if (absdelta.y > absdelta.x)
		{
			temp = d[0];
			d[0] = d[1];
			d[1] = temp;
		}

		movedir = d[0];
		if (TryWalk()) { return movedir; }

		movedir = d[1];
		if (TryWalk()) { return movedir; }

		if (GameHandler.WolfRandom() > 128)
		{
			for (temp = DI_EAST; temp <= DI_SOUTH; temp += 2)
			{
				movedir = temp;
				if (TryWalk()) { return movedir; }
			}
		}
		else
		{
			for (temp = DI_SOUTH; temp >= DI_EAST; temp -= 2)
			{
				movedir = temp;
				if (TryWalk()) { return movedir; }
			}
		}

		movedir = DI_NODIR;		// can't move

		return movedir;
	}

	int MoveDirToTarget()
	{
		if (!target) { return DI_NODIR; }

		int d[2];
		Vector2 delta;
		
		[delta, d[0], d[1]] = GetDirections();

		if (d[0] != DI_NODIR && d[1] != DI_NODIR)
		{
			return diags[((delta.y < 0) << 1) + (delta.x > 0)];
		}

		if (d[0] != DI_NODIR) { return d[0]; }

		return d[1];
	}

	Vector2, int, int GetDirections()
	{
		if (!target) return (0, 0), DI_NODIR, DI_NODIR;

		int d[2];

		Vector2 delta = Vec2To(target);
		delta.x = int(delta.x / 64);
		delta.y = int(delta.y / 64);

		if (delta.x > 0) { d[0] = DI_EAST; }
		else if (delta.x < 0) { d[0] = DI_WEST; }
		else { d[0] = RandomPick[GetDirX](DI_EAST, DI_WEST); }

		if (delta.y < 0) { d[1] = DI_SOUTH; }
		else if (delta.y > 0) { d[1] = DI_NORTH; }
		else { d[1] = RandomPick[GetDirY](DI_SOUTH, DI_NORTH); }

		return delta, d[0], d[1];
	}

	void A_DeathDrop()
	{
		if (dropweapon && target && !target.CheckInventory(dropweapon, 1))
		{
			A_SpawnItemEx(dropweapon);
			return;
		}

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
			!GameHandler.WolfRandom() &&
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

	// Custom implementation of Wolf-style firing logic
	void A_NaziShoot(double rangemultiplier = 1.0, Class<Actor> pufftype = "WolfPuff")
	{
		A_StartSound(AttackSound, CHAN_WEAPON, 0, 1.0, ATTN_NORM);

		if (!target || !CheckSight(target)) { return; }

		int damage = GameHandler.WolfRandom();

		A_FaceTarget();

		Vector2 vec = Vec2To(target);
		double dx = abs(vec.x);
		double dy = abs(vec.y);
		int dist = int((dx > dy ? dx : dy) * rangemultiplier / 64.0);

		double targetspeed = target.vel.length();

		let w = WolfPlayer(target);
		if (w && targetspeed == 0.0)
		{
			// Handle the fact that player movement velocity is nullified every tic
			// by manually calculating movement speed here
			targetspeed = (w.lastpos - w.pos).length();
		}

		// Lower starting hit chance for running enemies
		int hitchance = targetspeed < 10.0 ? 256 : 160;

		// Lower hitchance for enemies that are in the player's FOV (hard-coded to 45 degrees right/left)
		double targetangle = target.AngleTo(self);
		int multiplier = absangle(target.angle, targetangle) < 45 ? 16 : 8;
		
		// Lower hitchance based on distance
		hitchance -= dist * multiplier;

		let puffclass = GetReplacement(pufftype);
		Vector3 bloodpos = target.Vec3Angle(target.radius, targetangle + Random[BloodPos](-40, 40), target.height / 2 + Random[BloodPos](-8, 8));

		if (GameHandler.CheckForClass("BulletZPuff") && puffclass is String.Format("BulletZPuff"))
		{
			SpawnPuff(puffclass, bloodpos, targetangle, targetangle, 0, 0, target);
		}
		else if (GameHandler.WolfRandom() < hitchance)
		{
			// Lower damage based on distance
			if (dist < 2) { damage = damage >> 2; }
			else if (dist < 4) { damage = damage >> 3; }
			else { damage = damage >> 4; }

			Name mod = 'Bullet';
			let puff = GetDefaultByType(puffclass);
			if (puff) { mod = puff.DamageType; }

			int damagecalc = target.DamageMobj(self, self, damage, mod, DMG_THRUSTLESS);

			if (!g_noblood)
			{
				if (bNoBlood || bDormant)
				{
					SpawnPuff(puffclass, bloodpos, targetangle, targetangle, 0, 0, target);
				}
				else
				{
					SpawnBlood(bloodpos, targetangle, damagecalc > 0 ? damagecalc : damage);
				}
			}
		}
	}

	void ActivatePeers()
	{
		if (bActive || !target) { return; }

		int lookup = MapHandler.TileAt(pos.xy);
		if (lookup < 0x6B) { lookup = tid; }

		if (lookup == 0) { return; }

		let it = level.CreateActorIterator(lookup, "Actor");
		Actor mo;

		while (mo = Actor(it.Next()))
		{
			if (mo == self) { continue; }
			if (!mo.bIsMonster || mo.bDormant || !mo.bShootable || mo.health <= 0 || mo.bAmbush) { continue; }

			let c = ClassicBase(mo);
			if (c)
			{
				if (c.bActive) { continue; }
				else { c.bActive = true; }
			}

			mo.target = target;
			mo.SetState(mo.SeeState);
			mo.vel *= 0;
		}

		bActive = true;
	}

	virtual void SpawnFlames(int count = 8, double maxheight = 32, double rad = -1)
	{
		for (int f = 0; f < count; f++)
		{
			if (rad == -1) { rad = radius / 2; }

			Vector3 spawnpos = pos + (FRandom[SpawnFlames](-rad, rad), FRandom(-rad, rad), FRandom[SpawnFlames](0, maxheight));
			Spawn("Fire", spawnpos);
			Spawn("SmallFire", spawnpos + (FRandom[SpawnFlames](-16, 16), FRandom[SpawnFlames](-16, 16), FRandom[SpawnFlames](-8, 8)));
			SmokeSpawner ss = SmokeSpawner(Spawn("SmokeSpawner", spawnpos + (FRandom[SpawnFlames](-16, 16), FRandom[SpawnFlames](-16, 16), FRandom[SpawnFlames](-16, 16))));
			if (ss) { ss.duration = Random[SpawnFlames](45, 105); }
		}
	}

	override void Activate(Actor activator)
	{
		Super.Activate(activator);

		bDormant = false;
		if (target) { SetStateLabel("Chase"); }
		else { SetStateLabel("Spawn.Patrol"); }
	}

	override void Deactivate(Actor activator)
	{
		if (target && (CheckSight(target) || Distance2D(target) < 256)) { return; }
		Super.Deactivate(activator);

		movedir = int(angle / 45);
		bDormant = true;
		SetStateLabel("Spawn.Stand");
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		if (!target) { target = source; }
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}
}

class ClassicNazi : ClassicBase
{
	int deathtics;
	int flags;

	Property DeathTics:deathtics;
	FlagDef LongDeath:flags, 0;
	FlagDef Patrolling:flags, 1;

	// [DenisBelmondo]: in OG Doom (p_inter.c > P_KillMobj), there is a random
	// amount of tics between 0 and 3 subtracted from the death animation. This
	// behavior, of course carries in GZDoom, but Wolf3D never had this
	// behavior. This is a quick hack that fixes it because evidently, calling
	// A_SetTics on the first death state doesn't do the trick.

	override void Die(Actor source, Actor inflictor, int dmgflags, Name meansofdeath)
	{
		super.Die(source, inflictor, dmgflags, meansofdeath);
		tics = deathtics;
	}

	Default
	{
		ClassicNazi.DeathTics 8;
	}

	States
	{
		Spawn:
			UNKN A 0;
		Spawn.Stand:
			"####" EEEEEE 4 {
				if (bDormant || level.time < 2 || LifeHandler.CheckFizzle()) { return; }
				A_LookEx (0, 0, 0, 2048, 0, "See");
			}
			Loop;
		Spawn.PatrolNoClip:
			"####" # 0 {
				if (level.time > 30 && angle % 90 != 45)
				{
					SetStateLabel("TurnAround");
					return;
				}
				
				if (handler && handler.curmap)
				{
					bool initial = (level.time < 30);
					sector nextsector = Level.PointInSector((pos.xy + RotateVector((radius * 1.4 + 32, 0), angle)));
					Vector2 newpos = ParsedMap.CoordsToGrid(nextsector.CenterSpot);

					bool blocked = false;
					int t = handler.TileAt(nextsector.CenterSpot);
					int a = handler.ActorAt(nextsector.CenterSpot);

					if (t > 0 && t < 0x5A)
					{
						// Special handling to recreate holo-wall engine bug
						if (initial)
						{
							nextsector.MoveFloor(256, nextsector.floorplane.PointToDist(nextsector.CenterSpot, nextsector.CenterFloor() - 64), 0, -1, 0, true);
							nextsector.SetTexture(Sector.floor, floorpic);

							// Remove line blocking and set textures
							for (int l = 0; l < nextsector.lines.Size(); l++)
							{
								let ln = nextsector.lines[l];

								ln.flags |= Line.ML_TWOSIDED;
								ln.flags &= ~(Line.ML_BLOCKING | Line.ML_BLOCKSIGHT | Line.ML_SOUNDBLOCK);
								ln.activation = 0; // Allow walkthrough of elevators

								// TextureID tex = handler.curmap.GetTexture(newpos, ln);

								// for (int s = 0; s < 2; s++)
								// {
								// 	if (ln.sidedef[s] && ln.sidedef[s].sector != nextsector || ln.frontsector.CenterFloor() != ln.backsector.CenterFloor())
								// 	{
								// 		ln.sidedef[s].SetTexture(side.mid, tex);
								// 	}
								// }
								Sector texsec = (ln.frontsector == nextsector) ? ln.backsector : ln.frontsector;
								Vector2 texpos = (texsec ? texsec.CenterSpot : (-4096, 4096));
								texpos = ParsedMap.CoordsToGrid(texpos);
								TextureID tex = handler.curmap.GetTexture(texpos, ln);

								for (int s = 0; s < 2; s++)
								{
									if (ln.sidedef[s] && ln.sidedef[s].sector == nextsector)
									{
										if (texsec.CenterFloor() != 0)
										{
											ln.sidedef[s].SetTexture(side.mid, tex);
											ln.sidedef[s].SetTexture(side.bottom, tex);
										}
										else
										{
											ln.sidedef[s].SetTexture(side.mid, TexMan.CheckForTexture("-", TexMan.Type_Any));
										}
									}
								}
							}

							SetOrigin((nextsector.CenterSpot, pos.z), true);
						}
						else
						{
							blocked = true;
						}
					}
					else
					{
						SetOrigin((nextsector.CenterSpot, pos.z), true);
					}
				
					if (a)
					{
						BlockThingsIterator it = BlockThingsIterator.CreateFromPos(nextsector.CenterSpot.x, nextsector.CenterSpot.y, pos.z, 64, 32, false);

						while (it.Next())
						{
							if (it.thing.bSolid)
							{
								if (it.thing == self) { continue; }

								// Special handling to recreate non-solid thing engine bug
								if (initial) { it.thing.bSolid = false; }
								else { blocked = true; }
							}
						}
					}

					if (blocked) { SetStateLabel("TurnAround"); }
					else { SetStateLabel("Spawn.Patrol"); }
				}
			}
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
			"####" AAAAA 1 A_NaziChase();
			"####" A 1;
			"####" BBBB 1 A_NaziChase();
			"####" CCCCC 1 A_NaziChase();
			"####" CC 1;
			"####" DDDD 1 A_NaziChase();
			Loop;
		Pain:
			"####" A 0 A_JumpIf(health % 1, "Pain.Alt");
			"####" F 5 A_Pain;
			"####" A 0 A_Jump(256, "Chase");
		Pain.Alt:
			"####" J 5 A_Pain;
			"####" A 0 A_Jump(256, "Chase");
		Death:
			"####" A 0 A_DeathDrop();
			"####" K 8 A_SetTics(deathtics);
		Death.Resume:
			"####" L 7 { A_SetTics(deathtics - 1); A_DeathScream(); }
			"####" M 8 A_SetTics(deathtics);
			"####" N 0 { if (bLongDeath) { A_SetTics(deathtics); } }
		Dead:
			"####" N -1 { if (bLongDeath) { frame = 14; } }
		Death.Fire:
			"####" A 0 { if (g_noblood) { SetStateLabel("Death"); } }
			"####" A 0 {
				vel.xy *= 0;
				A_DeathScream();
				A_DeathDrop();
				SpawnFlames();
			}
			"####" K 6 A_SetTranslation("Ash25");
			"####" K 6 A_SetTranslation("Ash50");
			"####" K 6 A_SetTranslation("Ash75");
			"####" K 6 A_SetTranslation("Ash100");
			Goto Death.Resume;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		if (bPatrolling) { SetStateLabel("Spawn.Patrol"); }
		else { SetStateLabel("Spawn.Stand"); }
	}

	override void Tick()
	{
		Super.Tick();

		if (vel.xy.length() > 0 && BlockingLine && BlockingLine.special == 8)
		{
			if (bCanUseWalls && BlockingLine.activation & SPAC_MUse)
			{
				BlockingLine.Activate(self, 0, SPAC_Use);
				
				frame = 4;
				tics = 25;
				BlockingLine = null;
			}
		}
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
		+ClassicBase.OptionalRotations

		MaxTargetRange 256;
		Painchance 0;
		DamageFactor "Rocket", 2.0;
		DamageFactor "Fire", 2.0;
	}

	States
	{
		Spawn:
			UNKN A 0;
		Spawn.Stand:
			"####" A 5 A_Look();
			Loop;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		SetStateLabel("Spawn.Stand");
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
		MeleeRange 64;
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
		Attack:
			"####" G 5 A_CustomMeleeAttack(GameHandler.WolfRandom() < 180 ? GameHandler.WolfRandom() >> 4 : 0);
			"####" EA 5;
			Goto Chase;
		Death:
			"####" H 8 A_DeathDrop();
		Death.Resume:
			"####" I 7 A_DeathScream();
			"####" J 8;
		Dead:
			"####" K -1;
			Stop;
		Death.Fire:
			"####" A 0 { if (g_noblood) { SetStateLabel("Death"); } }
			"####" A 0 {
				vel.xy *= 0;
				A_DeathScream();
				SpawnFlames(8, 16);
			}
			"####" H 6 A_SetTranslation("Ash25");
			"####" H 6 A_SetTranslation("Ash50");
			"####" H 6 A_SetTranslation("Ash75");
			"####" H 6 A_SetTranslation("Ash100");
			Goto Death.Resume;
	}

	override bool CanCollideWith(Actor other, bool passive)
	{
		if (other is "Dog" && other.InStateSequence(other.curState, other.MeleeState)) { return false; }
		
		return Super.CanCollideWith(other, passive);
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
		ClassicBase.DropWeapon "WolfPistol";
	}

	States
	{
		Missile:
			"####" # 0 A_Stop;
			"####" GH 10 A_FaceTarget;
		Attack:
			"####" I 10 A_NaziShoot();
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
		ClassicBase.DropWeapon "WolfPistolLost";
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
		DropItem "WolfClip";

		ClassicBase.ScoreAmount 500;
		ClassicBase.BaseSprite "WBLU";
		ClassicBase.DropWeapon "WolfMachineGun";
	}

	States
	{
		Missile:
			"####" A 0 A_Stop;
			"####" GH 10 A_FaceTarget;
		Attack:
			"####" I 5 A_NaziShoot(0.666);
			"####" H 5 A_FaceTarget;
			"####" I 5 A_NaziShoot(0.666);
			"####" H 5 A_FaceTarget;
			"####" I 5 A_NaziShoot(0.666);
			"####" H 5 A_FaceTarget;
			"####" I 5 A_NaziShoot(0.666);
			Goto Chase;
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
		DropItem "WolfClipLost";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "WBLA";
		ClassicBase.DropWeapon "WolfMachineGunLost";
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
		Attack:
			"####" H 10 A_NaziShoot();
			"####" I 5 A_FaceTarget;
			"####" P 10 A_NaziShoot();
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
		ClassicBase.DropWeapon "WolfPistol";
	}

	States
	{
		Missile:
			"####" A 0 A_Stop;
			"####" G 3 A_FaceTarget;
			"####" H 10 A_FaceTarget;
		Attack:
			"####" I 5 A_NaziShoot();
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
		ClassicBase.DropWeapon "WolfPistolLost";
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
			"####" AAAAA 1 A_NaziChase(null, null);
			"####" A 1;
			"####" BBBB 1 A_NaziChase(null, null);
			"####" CCCCC 1 A_NaziChase(null, null);
			"####" CC 1;
			"####" DDDD 1 A_NaziChase(null, null);
		Chase:
			"####" AAAAA 1 A_NaziChase(null, "Missile");
			"####" A 1;
			"####" BBBB 1 A_NaziChase(null, "Missile");
			"####" CCCCC 1 A_NaziChase(null, "Missile");
			"####" CC 1;
			"####" DDDD 1 A_NaziChase(null, "Missile");
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 5 A_FaceTarget;
		Attack:
			"####" GFGFGE 5 A_NaziShoot(0.666);
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
		Death.Fire:
			"####" A 0 { if (g_noblood) { SetStateLabel("Death"); } }
			"####" A 0 {
				A_DeathScream();
				SpawnFlames(16, 48, 24);
			}
			"####" H 6 A_SetTranslation("Ash25");
			"####" H 6 A_SetTranslation("Ash50");
			"####" H 6 A_SetTranslation("Ash75");
			"####" H 6 A_SetTranslation("Ash100");
			Goto Death;
	}
}

class DrSchabbs : ClassicBoss
{
	Default
	{
		//$Title Dr. Schabbs

		+ClassicBase.RUN

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
			"####" AAAAA 1 A_NaziChase(chance:16);
			"####" A 1;
			"####" BBBB 1 A_NaziChase(chance:16);
			"####" CCCCC 1 A_NaziChase(chance:16);
			"####" CC 1;
			"####" DDDD 1 A_NaziChase(chance:16);
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
		Attack:
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
		+ClassicBase.OptionalRotations

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
			WHGT AAAAA 1 A_NaziChase(chance:4);
			WHGT A 1;
			WHGT BBBB 1 A_NaziChase(chance:4);
			WHGT CCCCC 1 A_NaziChase(chance:4);
			WHGT CC 1;
			WHGT DDDD 1 A_NaziChase(chance:4);
			Loop;
		Missile:
			WHGT E 4 A_FaceTarget;
		Attack:
			WHGT EEEEEEEE 4 A_SpawnProjectile(g_fastfireballs ? "FastGhostFireBall" : "GhostFireBall", 30, 0, 0);
			Goto Chase;
		Death:
			WHGT F 5 A_DeathDrop();
			WHGT G 5 A_Scream;
			WHGT HIJ 5;
		Dead:
			WHGT K -1;
			Stop;
		Death.Fire:
			"####" A 0 { if (g_noblood) { SetStateLabel("Death"); } }
			"####" F 0 SpawnFlames();
			"####" F 2 A_SetTranslation("Ash25");
			"####" F 2 A_SetTranslation("Ash50");
			"####" F 2 A_SetTranslation("Ash75");
			"####" F 2 A_SetTranslation("Ash100");
			Goto Death;
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
			"####" AAAAA 1 A_NaziChase();
			"####" AAA 1 A_Pain;
			"####" BBBB 1 A_NaziChase();
			"####" CCCCC 1 A_NaziChase();
			"####" CCC 1 A_Pain;
			"####" DDDD 1 A_NaziChase();
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 5 A_FaceTarget;
			"####" GFGF 5 A_NaziShoot();
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
		-AMBUSH

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
			"####" AAA 1 A_NaziChase();
			"####" AA 1;
			"####" B 1 A_NaziChase();
			"####" CCC 1 A_NaziChase();
			"####" CC 1;
			"####" D 1 A_NaziChase();
			Loop;
		Missile:
			"####" G 15 A_FaceTarget;
			"####" H 5 A_FaceTarget;
		Attack:
			"####" IHIH 5 A_NaziShoot();
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

		+ClassicBase.RUN

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
			"####" AAAAA 1 A_NaziChase(chance:16);
			"####" A 1;
			"####" BBBB 1 A_NaziChase(chance:16);
			"####" CCCCC 1 A_NaziChase(chance:16);
			"####" CC 1;
			"####" DDDD 1 A_NaziChase(chance:16);
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
		Attack:
			"####" F 5 A_SpawnProjectile("WolfRocket", 30, 13, 0);
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

		+ClassicBase.RUN

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
			"####" AAAAA 1 A_NaziChase(chance:16);
			"####" A 1;
			"####" BBBB 1 A_NaziChase(chance:16);
			"####" CCCCC 1 A_NaziChase(chance:16);
			"####" CC 1;
			"####" DDDD 1 A_NaziChase(chance:16);
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
			"####" F 5 A_FaceTarget;
		Attack:
			"####" G 5 A_SpawnProjectile("WolfRocket", 30, 13, 0);
			"####" E 0 A_FaceTarget;
			"####" HGH 5 A_NaziShoot();
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
		+AMBUSH
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
			"####" AAAAABBBBB 1 A_NaziChase();
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
		Death.Fire:
			"####" A 0 { if (g_noblood) { SetStateLabel("Death"); } }
			"####" A 10 {
				A_DeathDrop();
				A_Scream();
				SpawnFlames(16, 48, 24);
			}
			"####" A 10 A_SetTranslation("Ash25");
			"####" A 10 A_SetTranslation("Ash50");
			"####" A 10 A_SetTranslation("Ash75");
			"####" A 10 A_SetTranslation("Ash100");
			Goto Death + 2;
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
		Death.Fire:
			"####" A 0 { if (g_noblood) { SetStateLabel("Death"); } }
			"####" A 10 {
				A_DeathDrop();
				A_Scream();
				SpawnFlames(16, 48, 24);
			}
			"####" A 10 A_SetTranslation("Ash25");
			"####" A 10 A_SetTranslation("Ash50");
			"####" A 10 A_SetTranslation("Ash75");
			"####" A 10 A_SetTranslation("Ash100");
			Goto Death + 2;
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
			"####" AAAAA 1 A_NaziChase();
			"####" A 1;
			"####" BBBB 1 A_NaziChase();
			"####" CCCCC 1 A_NaziChase();
			"####" CC 1;
			"####" DDDD 1 A_NaziChase();
			Loop;
		Missile:
			"####" E 15 A_FaceTarget;
		Attack:
			"####" F 6 A_NaziShoot();
			"####" E 0 A_FaceTarget;
			"####" G 6 A_NaziShoot();
			"####" E 0 A_FaceTarget;
			"####" H 6 A_NaziShoot();
			"####" E 0 A_FaceTarget;
			"####" G 6 A_NaziShoot();
			"####" E 0 A_FaceTarget;
			"####" F 6 A_NaziShoot();
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
		Death.Fire:
			"####" A 0 { if (g_noblood) { SetStateLabel("Death"); } }
			"####" A 6 {
				A_Scream();
				SpawnFlames(16, 48, 24);
			}
			"####" A 6 A_SetTranslation("Ash25");
			"####" A 6 A_SetTranslation("Ash50");
			"####" A 6 A_SetTranslation("Ash75");
			"####" A 6 A_SetTranslation("Ash100");
			Goto Death + 1;
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
		BloodColor "FC 00 FC";

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

		+ClassicBase.RUN

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
			"####" AAAAA 1 A_NaziChase(chance:16);
			"####" A 1;
			"####" BBBB 1 A_NaziChase(chance:16);
			"####" CCCCC 1 A_NaziChase(chance:16);
			"####" CC 1;
			"####" DDDD 1 A_NaziChase(chance:16);
			Loop;
		Missile:
			"####" F 15 A_FaceTarget;
		Attack:
			"####" G 5 A_SpawnProjectile(projectile, 48, 15, 4, CMF_AIMDIRECTION);
			"####" I 5 A_NaziShoot();
			"####" I 0 A_FaceTarget;
			"####" H 5 A_SpawnProjectile(projectile, 48, -15, -4, CMF_AIMDIRECTION);
			"####" I 5 A_NaziShoot();
			Goto Chase;
		Death:
			"####" A 53 A_Scream;
			"####" K 5 A_DeathDrop();
			"####" LMNO 5;
			"####" P 5 A_BossDeath;
		Dead:
			"####" Q -1;
			Stop;
		Death.Fire:
			"####" A 0 { if (g_noblood) { SetStateLabel("Death"); } }
			"####" A 6 {
				A_Scream();
				SpawnFlames(16, 48, 24);
			}
			"####" A 6 A_SetTranslation("Ash25");
			"####" A 6 A_SetTranslation("Ash50");
			"####" A 6 A_SetTranslation("Ash75");
			"####" A 6 A_SetTranslation("Ash100");
			Goto Death + 1;
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
		BloodColor "00 00 00";

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

		+ClassicBase.RUN

		Painchance 0;
		Speed 4;
		SeeSound "aod/sight";
		PainSound "aod/breathe";
		DeathSound "aod/death";
		BloodColor "FF 00 FF";

		ClassicBase.BaseSprite "WB10";
		ClassicBase.ScoreAmount 5000;
		ClassicBase.SkillHealth 1450, 1550, 1650, 2000;
		AngelOfDeath.BallClass "GreenBall";
	}

	States
	{
		Chase:
			"####" AAAAA 1 A_NaziChase(chance:16);
			"####" A 1;
			"####" BBBB 1 A_NaziChase(chance:16);
			"####" CCCCC 1 A_NaziChase(chance:16);
			"####" CC 1;
			"####" DDDD 1 A_NaziChase(chance:16);
			Loop;
		Missile:
			"####" G 5 A_FaceTarget;
			"####" H 10 A_FaceTarget;
		Attack:
			"####" G 5 A_SpawnProjectile(BallClass, 25, 13, 0);
			"####" G 0 A_Jump(127, "Chase");
			"####" G 5 A_FaceTarget;
			"####" H 10 A_FaceTarget;
			"####" G 5 A_SpawnProjectile(BallClass, 25, 13, 0);
			"####" G 0 A_Jump(127, "Chase");
			"####" G 5 A_FaceTarget;
			"####" H 10 A_FaceTarget;
			"####" G 5 A_SpawnProjectile(BallClass, 25, 13, 0);
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
		BloodColor "00 FC 00";

		+ClassicBase.Lost
		ClassicBase.BaseSprite "LB10";
		AngelOfDeath.BallClass "DIBall";
	}
}

class BarnacleWilhelm : Fettgesicht
{
	Default
	{
		//$Title Barnacle Wilhelm

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
		//$Title Spectre

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
			"####" AAAAABBBBBCCCCCDDDDD 1 A_NaziChase();
			Loop;
		Melee:
			"####" A 0 A_FaceTarget;
		Attack:
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
		Death:
		Dead:
			TNT1 A 5;
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
		//$Title Radioactive Mist

		+ClassicBase.Lost

		ClassicBase.BaseSprite "LSP2";
	}
}