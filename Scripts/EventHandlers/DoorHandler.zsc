/*
  All new sliding doors and pushwalls should be set up using the PolyObj_DoorSlide special

  Special:	PolyObj_DoorSlide (8)
    Arg 0:	<polyobject number>
    Arg 1:	<movement speed - if zero, calculated by event handler using a base speed of 12>
    Arg 2:	<byte angle of movement - e.g., 0, 64, 128, 192, etc.>
    Arg 3:	<distance to move - if zero, calculated by event handler based on line length>
    Arg 4:	<tics to delay before closing the door - if zero, use default time of 4 seconds; if negative, never close>

  For a normal door:
	Action: PolyObj_DoorSlide
	Polyobject Number: <as appropriate>
	Movement Speed: 0
	Movement Angle: <as appropriate>
	Movement Distance: 0
	Delay: 0

  For a pushwall:
	Action: PolyObj_DoorSlide
	Polyobject Number: <as appropriate>
	Movement Speed: 4
	Movement Angle: <as appropriate>
	Movement Distance: 128 (or higher, as required)
	Delay: -1

  For locked doors, use the line's 'Lock number' field to set the needed key:
  	Yellow Key (was lock 2 in ACS)
	Blue Key (was lock 1 in ACS)

  For paired/mirrored doors, all activation lines should have the same polyobject set in Arg 0,
  and that polyobject should have the second polyobject's number in the 'Mirror Polyobject Number' 
  field of its start line.

  Sounds are configured using the 'Sound Number' argument on the polyobject's start line:
	1: Normal Doors
	2: Lost Episodes Doors
	2: Lost Episodes Secret Doors
	4: Secret Doors

  To open a door from an ACS script, use:
   ScriptCall("DoorHandler", "OpenDoor", <PolyNumber>, <Byte Angle>, <Delay>, <Speed>, <MoveDistance>);
  with the same standard application as detailed above.
*/

// Handler and Polyobject Effector modified by AFADoomer from ZPolyobject demo effector by mikolah

class DoorHandler: EventHandler
{
	// This event handler adds Wolf3D-like behavior to sliding polyobject doors by
	// intercepting linedef activations of Polyobj_SlideDoor action special and 
	// using DoorEffector instead
	override void WorldLinePreActivated(WorldEvent e)
	{
		Line ln = e.ActivatedLine;

		// Ignore all other specials
		if (ln.special != Polyobj_DoorSlide) { return; }

		// Prevent line from activating
		e.ShouldActivate = false;

		// Save and temporarily unset the line special to prevent infinite recursion
		int special = ln.special;
		ln.Special = -1;
		ln.flags |= Line.ML_MONSTERSCANACTIVATE; // Make sure enemies can open the door (if they are set to use walls)

		OpenDoor(e.Thing, ln.Args[0], ln.Args[2], ln.Args[4], ln.Args[1], ln.Args[3], ln);

		// Reset line special
		ln.special = special;
	}

	static void OpenDoor(Actor activator, int polynum, int angle, int delay = 0, int speed = 0, int distance = 0, Line ln = null)
	{
		if (!polynum) { return; }

		// Get the handle to the activated polyobject 
		PolyobjectHandle po = PolyobjectHandle.FindPolyobj(polynum);
		if (!po) { return; }

		// Check if the polyobject has this effector already
		// (for cases like trying to open the door while it's closing)
		DoorEffector eff = DoorEffector(po.FindEffector("DoorEffector"));
		if (!eff)
		{
			// Create an effector instance from scratch
			eff = DoorEffector(New('DoorEffector'));
			eff.ActivationLine = ln;
			eff.Angle = angle * 360.0 / 256.0;
			eff.Delay = (delay ? delay : speed == 4 ? -1 : 150);
			eff.Speed = (speed ? speed : 12);
			eff.Distance = distance;

			if (!po.StartSector)
			{
				po.StartSector = Level.PointInSector(po.StartSpotPos);
			}

			for (int l = 0; l < po.StartSector.lines.Size(); l++)
			{
				Line ln = po.StartSector.lines[l];

				if (ln.flags & Line.ML_TWOSIDED) { eff.SoundLines.Push(ln.Index()); }
			}

			// Add effector to the polyobject
			po.AddEffector(eff);
		}

		// Assign a sound sequence if one wasn't set
		if (!po.SoundSequenceNum)
		{
			int gametype = MapHandler.GetGameType();
			if (gametype < 0) { gametype = max(0, g_sod); }

			if (eff.delay < 0) { po.SoundSequenceNum = gametype <= 1 ? 4 : 3; } // A pushwall
			else { po.SoundSequenceNum = gametype <= 1 ? 1 : 2; } // Otherwise a normal door
		}

		// Check if activator is actually able to activate the line
		if (!ln || ln.Activate(activator, Line.front, ln.Activation) || activator.bIsMonster)
		{
			eff.Activator = activator;

			if (ln)
			{
				eff.PlaneLine = null;

				for (int l = 0; l < eff.SoundLines.Size(); l++)
				{
					let sln = level.lines[eff.SoundLines[l]];

					if (sln.special) { continue; } // Don't choose lines that already have specials

					if (
						(
							VertexInRange(sln.v1, ln.v1) &&
							VertexInRange(sln.v2, ln.v2)
						) ||
						(
							VertexInRange(sln.v1, ln.v2) && 
							VertexInRange(sln.v2, ln.v1)
						)
					)
					{
						eff.PlaneLine = sln;
					}
				}
			}

			// Open the door if possible
			eff.TryOpen();
		}
	}

	static bool VertexInRange(Vertex v1, Vertex v2, int r = 32)
	{
		if (
			v1.p.x <= v2.p.x + r && 
			v1.p.x >= v2.p.x - r &&
			v1.p.y <= v2.p.y + r && 
			v1.p.y >= v2.p.y - r
		) { return true; }

		return false;
	}

	static bool IsActive(int polynum)
	{
		PolyobjectHandle po = PolyobjectHandle.FindPolyobj(polynum);
		if (!po) { return false; }

		if (po.Mirror && !po.Mirror.IsAtOrigin()) { return true; }

		return !po.IsAtOrigin();
	}

	static void Close(int polynum)
	{
		PolyobjectHandle po = PolyobjectHandle.FindPolyobj(polynum);
		if (!po) { return; }

		DoorEffector eff = DoorEffector(po.FindEffector("DoorEffector"));
		if (eff) { eff.Counter = 0; }
	}
}

class DoorEffector: PolyobjectEffector
{
	// This effector makes a polyobject behave like a Wolf3D door.
	// The behavior is similar to the Polyobj_DoorSlide action special, slightly changed.
	// Trying to open the door while it's closing will cause it to start re-opening.
	// The door won't close if a player or a monster (either dead or alive)
	// is blocking its way, and will stay open until the blocking moves aside.

	Actor Activator; // Actor activating the door
	int Delay; // Tics to wait before closing the door
	int Speed; // Door speed
	Vector2 Destination; // Open door position
	int Counter; // Tics remaining before the door closes
	Vector3 CenterSpot; // Center coordinates of the sector containing the polyobject
	double BlockRadius; // Radius around CenterSpot in which actors can block the door
	Actor Blocker; // Actor blocking the door from closing
	int Distance; // Distance to move the door
	double Angle; // Angle to move the door
	Line ActivationLine; // The line that was used to activate the door
	Array<int> SoundLines; // Sound blocking lines that belong to this door
	Line PlaneLine; // The sound blocking line that roughly corresponds to the activation line

	// Possible door statuses
	enum WolfDoorStatus
	{
		WDST_CLOSED,   // Fully closed (and can be opened)
		WDST_FIRSTOPENING, // Initial opening; moving toward destination (and cannot be closed)
		WDST_OPENING,  // Moving towards destination (and can be closed)
		WDST_OPEN,     // Fully open (and can be closed)
		WDST_CLOSING,  // Moving towards initial position (and can be re-opened)
	}

	// Current door status
	WolfDoorStatus Status;

	// Open the door
	void Open()
	{
		Polyobject.StartSector.SetTexture(Sector.floor, Activator.floorpic);

		// Door is opening, set status accordingly
		if (Status == WDST_CLOSED)
		{
			Status = WDST_FIRSTOPENING;
			if (delay < 0) { MapHandler.MarkPushwallAt(PolyObject.StartSpotPos); }

			/*
				Notes for implementing memory overflow bug floor tiles:
					One side must be: 0 (No floor code)
					Other side: Effect:
						0x40	NoClip
						0xA0	Fire
						0xD6	Strafe
						0xD7	Use
						0xF6	Forward
						0xFB	Right Turn
			*/
		}
		else { Status = WDST_OPENING; }

		Counter = Delay; // Reset the countdown 

		// Move the polyobject to destination
		Polyobject.MoveTo(Activator, Destination, Speed, 0);  // SNDSEQ sound 0 for opening

		if (delay > 0)
		{
			for (int l = 0; l < Polyobject.Lines.Size(); l++)
			{
				Polyobject.Lines[l].flags &= ~Line.ML_BLOCKING;
			}
		}

		// Remove sound blocking flag from lines
		for (int l = 0; l < SoundLines.Size(); l++)
		{
			level.lines[SoundLines[l]].flags &= ~Line.ML_SOUNDBLOCK;
		}
	}

	// Try to open the door, if possible
	void TryOpen()
	{
		if (distance == 0) { return; }

		// Close an open door (unless it's currently opening for the first time), and open a closed door
		if (Status == WDST_OPENING || Status == WDST_OPEN)
		{
			if (Delay >= 0) { TryClose(); }
		}
		else if (Status == WDST_CLOSING || Status == WDST_CLOSED) { Open(); }
	}

	// Check if a given actor prevents the door from closing
	bool IsActorBlocking(Actor a)
	{
		// Doors are blocked by players and monsters (including corpses) if they are close enough to CenterSpot
		if (a.bIsMonster || a.Player)
		{
			Vector2 v1, v2;

			if (Polyobject.Mirror)
			{
				// Calculate distance from an imaginary line between the two polyobject start spots
				v1 = Polyobject.StartSpotPos;
				v2 = Polyobject.Mirror.StartSpotPos;
			}
			else if (PlaneLine)
			{
				// Calculate distance from an imaginary line through Centerspot and parallel to the door's movement
				v1 = Centerspot.xy + Actor.RotateVector((distance / 2, 0), angle);
				v2 = Centerspot.xy + Actor.RotateVector((-distance / 2, 0), angle);
			}

			if (v1.length() || v2.length())
			{
				double dist = 0;

				Vector2 delta = v2 - v1;
				Vector2 point = a.pos.xy;

				double lengthsquared = (v2 - v1).length() ** 2;

				if (!lengthsquared) { dist = (v1 - point).length(); }
				else
				{
					double t = clamp((point - v1) dot delta / lengthsquared, 0, 1);
					Vector2 projection = v1 + t * delta;

					dist = (point - projection).length();
				}

				return dist < a.Radius + 32;
			}

			// Fall back to naive check if we can't (mostly) guarantee that the distance corresponds
			// closely enough to the door's actual width (e.g., with large double doors)
			return (BlockRadius + a.Radius > (CenterSpot.xy - a.Pos.xy).Length());
		}
		
		return false;
	}

	// Find an actor that prevents the door from closing, if one exists
	Actor FindBlockingActor(Vector3 spot, int dist, bool simple)
	{
		// Iterate over actors that are close to the door
		BlockThingsIterator it = BlockThingsIterator.CreateFromPos(spot.x, spot.y, spot.z, 0, dist, false);
		while (it.Next())
		{
			if (simple)
			{
				if (it.thing.bSolid && Level.Vec2Diff(spot.xy, it.thing.pos.xy).length() < dist) { return it.thing; }
			}
			else if (IsActorBlocking(it.Thing)) { return it.thing; }
		}

		return null;
	}

	bool IsBlocked(Vector3 spot = (0, 0, 0), int dist = -1, bool simple = false)
	{
		if (!spot.length()) { spot = Centerspot; }
		if (dist < 0) { dist = distance; }

		// Check if still blocked by the same actor
		if (!simple && Blocker && IsActorBlocking(Blocker)) { return true; }
		else
		{
			// Check if any actors are blocking the door
			Blocker = FindBlockingActor(spot, dist, simple);
			if (Blocker) { return true; }
		}

		return false;
	}

	// Try to close the door, if possible
	bool TryClose()
	{
		if (IsBlocked()) { return false; }

		// Close the door
		Close();
		return true;
	}

	// Close the door
	void Close()
	{
		// Door is closing, set status accordingly
		Status = WDST_CLOSING;
		Polyobject.MoveTo(Activator, Polyobject.StartSpotPos, Speed, 1); // SNDSEQ sound 1 for closing

		for (int l = 0; l < Polyobject.Lines.Size(); l++)
		{
			Polyobject.Lines[l].flags |= Line.ML_BLOCKING;
		}

		// Restore player blocking flag to lines
		for (int l = 0; l < SoundLines.Size(); l++)
		{
			level.lines[SoundLines[l]].flags |= Line.ML_BLOCK_PLAYERS;
		}
	}

	override void OnAdd()
	{
		Sector sec = Polyobject.GetSector();
		Polyobject.VertexStartingPos[0] = Polyobject.VertexLastPos[0] = Polyobject.StartLine.v1.p;
		Polyobject.VertexStartingPos[1] = Polyobject.VertexLastPos[1] = Polyobject.StartLine.v2.p;

		// We assume that the door is contained within a sector that more-or-less matches
		// the door shape, and its center is close enough to the middle of the door.
		CenterSpot = (Polyobject.GetSector().CenterSpot, Polyobject.GetSector().FloorPlane.ZAtPoint(Polyobject.GetSector().CenterSpot));

		if (!distance)
		{
			PolyMoveEffector moveeff = PolyMoveEffector(Polyobject.FindEffector("PolyMoveEffector"));
			if (moveeff)
			{
				if (!ActivationLine || Polyobject.Lines.Find(ActivationLine) == Polyobject.Lines.Size())
				{
					for (int d = 0; d < Polyobject.Lines.size(); d++)
					{
						int l = int(Polyobject.Lines[d].delta.length());
						if (l > distance) { distance = l; }
					}
				}
				else { distance = int(ActivationLine.delta.length()); }
			}
			else { distance = (ActivationLine ? int(ActivationLine.delta.length()) : (speed == 4 ? 128 : 64)); }
		}

		if (delay < 0) // Secret door
		{
			Vector2 moveunit = Actor.AngleToVector(angle, 64);

			// See how far the door can move without being blocked
			int m = 1;
			for (m = 1; m <= g_maxpushwallmove; m++)
			{
				Vector2 spot = Polyobject.StartSpotPos + moveunit * m;
				int t = MapHandler.TileAt(spot);
				int a = MapHandler.ActorAt(spot);

				bool blocked = false;
				
				if (a == 0x62) // Can't move through pushwalls - but make sure it's still there
				{
					PolyobjectHandle ph = PolyobjectHandle.FindPolyobjAt(spot);
					if (ph) { break; }
				}
				else if (t > 0 && t < 0x5A) { break; } // Can't move through solid walls
				else if (t < 0x6A)
				{
					ThinkerIterator it = ThinkerIterator.Create('PolyobjectHandle');
					PolyobjectHandle ph;
					while (ph = PolyobjectHandle(it.Next()))
					{
						if (ph.StartSpotPos == spot)
						{
							DoorEffector eff = DoorEffector(ph.FindEffector("DoorEffector"));
							// Can't move through closed doors
							if (!eff || eff.Status != DoorEffector.WDST_OPEN)
							{
								blocked = true;
								break;
							}
						}
					}
				}

				if (blocked) { break; }
				
				if (a == 0x7C) { break; } // Dead guard always blocks pushwalls
				else
				{
					BlockThingsIterator it = BlockThingsIterator.CreateFromPos(spot.x, spot.y, 0, 0, 32, false);
					
					while (it.Next())
					{
						if (it.thing.bSolid && abs(it.thing.pos.x - spot.x) <= 32 &&  abs(it.thing.pos.y - spot.y) <= 32)
						{
							blocked = true;
							break;
						}
					}
				}

				if (blocked) { break; }
			}

			distance = (m - 1) * 64;
			speed = max(speed, int(speed * max(g_maxpushwallmove * 64, distance) / 64.0));
		}
		else
		{
			// Scale speed so that door movement takes the same amount of time regardless
			// of distance so that door sounds always are the right length
			speed = max(speed, int(speed * distance / 64.0));
		}

		Destination = Actor.AngleToVector(angle, distance) + Polyobject.StartSpotPos;

		// We assume that any actor within a half-width radius is close enough to block the door
		BlockRadius = distance / 2.0;
	}

	override void PolyTick()
	{
		// Track polyobject position and update door status accordingly

		// A negative delay amount means 'stay open forever'...  So stop processing
		if (delay < 0 )
		{
			if (Status == WDST_OPEN) { return; }
			else if (Status == WDST_FIRSTOPENING)
			{
				for (int n = 0; n < PolyObject.Lines.Size(); n++)
				{
					let dln = PolyObject.Lines[n];

					for (int s = 0; s < 2; s++)
					{
						if (dln.sidedef[s])
						{
							dln.sidedef[s].EnableAdditiveColor(side.mid, false);
						}
					}
				}

				// Re-check at intervals for the pushwall being blocked...
				Vector2 pos = PolyObject.GetPos();
				int movedist = int((pos - PolyObject.StartSpotPos).length());
	
				if (movedist % 16 == 0)
				{
					Vector2 moveunit = Actor.AngleToVector(angle, 64);
				
					Vector2 dest = pos + moveunit;
					if (IsBlocked((dest, 0), 32, true))
					{
						Destination = PolyObject.StartSpotPos + moveunit * ceil(movedist / 64.0);
						Level.ExecuteSpecial(Polyobj_Stop, Blocker, PolyObject.StartLine, Line.Front, PolyObject.PolyobjectNum);
						Level.ExecuteSpecial(Polyobj_OR_MoveTo, Blocker, PolyObject.StartLine, Line.Front, PolyObject.PolyobjectNum, Speed, int(Destination.x), int(Destination.y));
					}
				}

				PolyobjectHandle door = PolyobjectHandle.FindPolyobjAt(PolyObject.StartSpotPos);
				if (door && door != PolyObject)
				{
					if (movedist == 0)
					{
						TextureID nulltex = TexMan.CheckForTexture("-", TexMan.Type_Any);
						for (int l = 0; l < door.Lines.Size(); l++)
						{
							let ln = door.lines[l];

							ln.special = 0;
							ln.flags &= ~Line.ML_BLOCKING;

							for (int s = 0; s < 2; s++)
							{
								if (ln.sidedef[s])
								{
									ln.sidedef[s].SetTexture(side.mid, nulltex);
								}
							}
						}

						let handler = MapHandler.Get();

						if (handler)
						{
							int t = handler.curmap.CountDoors(ParsedMap.CoordsToGrid(PolyObject.StartSpotPos));
							for (int l = 0; l < PolyObject.Lines.Size(); l++)
							{
								let ln = PolyObject.lines[l];

								for (int s = 0; s < 2; s++)
								{
									if (ln.sidedef[s])
									{
										ln.sidedef[s].SetTexture(side.mid, handler.curmap.GetTileTexture(t, (0, 0), ln));
									}
								}
							}
						}
					}
					else if (movedist == 64)
					{
						let handler = MapHandler.Get();

						if (handler)
						{
							Vector2 pos = ParsedMap.CoordsToGrid(PolyObject.StartSpotPos);
							int t = handler.curmap.TileAt(pos);

							for (int l = 0; l < PolyObject.StartSector.Lines.Size(); l++)
							{
								let ln = PolyObject.StartSector.lines[l];

								if (ln.flags & Line.ML_TWOSIDED)
								{
									if (t % 2 == 1 && ln.delta.x) { continue; }
									if (t % 2 == 0 && ln.delta.y) { continue; }
								}

								for (int s = 0; s < 2; s++)
								{
									if (ln.sidedef[s] && ln.sidedef[s].sector == PolyObject.StartSector)
									{
										int tt = 0;
										if (t % 2 == 1)
										{
											if (ln.v1.p.x > PolyObject.StartSpotPos.x) { tt = handler.curmap.TileAt(pos + (1, 0)); }
											else { tt = handler.curmap.TileAt(pos - (1, 0)); }
										}
										else
										{
											if (ln.v1.p.y > PolyObject.StartSpotPos.y) { tt = handler.curmap.TileAt(pos - (0, 1)); }
											else { tt = handler.curmap.TileAt(pos + (0, 1)); }
										}
										
										ln.sidedef[s].SetTexture(side.mid, handler.curmap.GetTileTexture(tt, (0, 0), ln));
									}
								}
							}
						}
					}
				}
			}
		}

		if (!Polyobject.IsMoving() && (!PolyObject.Mirror || !Polyobject.Mirror.IsMoving()))
		{
			if (Polyobject.GetPos() == Destination)
			{
				// Polyobject reached its destination and stopped moving, the door is fully open
				Status = WDST_OPEN;

				// Remove player blocking flag from lines
				for (int l = 0; l < SoundLines.Size(); l++)
				{
					level.lines[SoundLines[l]].flags &= ~Line.ML_BLOCK_PLAYERS;
				}
			}
			else if (Status == WDST_CLOSING)
			{
				if (Polyobject.IsAtOrigin() && (!PolyObject.Mirror || Polyobject.Mirror.IsAtOrigin()))
				{
					// Polyobject reached its origin and stopped moving, the door is fully closed
					Status = WDST_CLOSED;

					// Restore sound blocking lines
					for (int l = 0; l < SoundLines.Size(); l++)
					{
						level.lines[SoundLines[l]].flags |= Line.ML_SOUNDBLOCK;
					}

					if (PlaneLine)
					{
						PlaneLine.activation = 0;
					}
				}
				else
				{
					// The door has stopped midway while closing, something is blocking it.
					// Reopen the door
					if (IsBlocked()) { Open(); }
				}
			}
		}

		if (Status == WDST_OPEN)
		{
			// Otherwise decrement tics remaining until the door closes
			if (Delay >= 0 && --Counter <= 0)
			{
				// No more tics remaining, close the door if possible
				Counter = 0;
				TryClose();
			}

			if (delay < 0) // Negative delay leaves the door open forever
			{
				PolyObject.StartSpotPos = Destination;

				if (MapHandler.CheckPushwallAt(Destination)) // Unless there's another unused secret door spot at the destination
				{
					Destroy();

					if (g_highlightpushwalls)
					{
						for (int n = 0; n < PolyObject.Lines.Size(); n++)
						{
							let dln = PolyObject.Lines[n];

							for (int s = 0; s < 2; s++)
							{
								if (dln.sidedef[s])
								{
									dln.sidedef[s].EnableAdditiveColor(side.mid, true);
								}
							}
						}
					}
				}

				PolyObject.StartSector = Level.PointInSector(Destination);
				if (PolyObject.StartSector)
				{
					int t = MapHandler.TileAt(PolyObject.Origin);

					if (t == 0x40 && Level.Vec2Diff(PolyObject.Origin, PolyObject.StartSpotPos).length() > 64)
					{
						// Special handling for "disappearing pushwall"
						Level.ExecuteSpecial(Polyobj_OR_MoveTo, null, PolyObject.StartLine, Line.Front, PolyObject.PolyobjectNum, 8192, -2176, 2176);
					}
					else
					{
						// Handling for secret door placed on top of regular door (door turns into a pushwall)
						int gametype = MapHandler.GetGameType();
						if (gametype < 0) { gametype = max(0, g_sod); }

						TextureID tex;

						if (t >= 0x5A && t <= 0x65)
						{
							let handler = MapHandler.Get();

							if (handler)
							{
								int t = handler.curmap.CountDoors(ParsedMap.CoordsToGrid(PolyObject.Origin));
								tex = handler.curmap.GetTileTexture(t, (0, 0), null);
							}
						}
						else
						{
							int game = gametype;
							while (game > -1 && !tex.IsValid())
							{
								String texpath = String.Format("Patches/Walls/Wall%i%03i.png", game, (t - 1) * 2);
								tex = TexMan.CheckForTexture(texpath, TexMan.Type_Any);

								if (!tex.IsValid()) { game--; }
							}
						}

						PolyObject.StartSector.SetTexture(Sector.floor, tex);
					}
				}
			}
		}
		else if (Status == WDST_CLOSED)
		{
			// The door is fully closed, destroy the effector
			Destroy();
		}
	}
}