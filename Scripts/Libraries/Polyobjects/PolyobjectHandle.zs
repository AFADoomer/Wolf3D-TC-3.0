class PolyobjectHandle: Thinker
{
	// This thinker keeps track of a polyobject's position, angle, movement speed etc.
	// Instances of this thinker should only be created by the included map postprocessor

	enum EPolyobjType
	{
		POTYP_NORMAL = 9301,  // Normal StartSpot
		POTYP_CRUSH = 9302,   // Crush StartSpot
		POTYP_HURT = 9303     // Hurt StartSpot
	}

	// Polyobject Number
	int PolyobjectNum;

	// Line defining the polyobject (Polyobj_StartLine, or one of Polyobj_ExplicitLine)
	Line StartLine;

	// Initial angle of StartLine
	double StartAngle;

	// Last tic angle of StartLine
	double LastAngle;

	// Starting positions of StartLine vertices
	Vector2[2] VertexStartingPos;

	// Last tic positions of StartLine vertices
	Vector2[2] VertexLastPos;

	// Last tic position of the polyobject
	Vector2 LastPos;

	// SoundSequence number
	int SoundSequenceNum;

	// StartSpot position
	Vector2 StartSpotPos;
	Vector2 Origin;

	int StartSpotIndex;

	// For bounds checking
	double z;

	// Sector the polyobject spawns in ()
	Sector StartSector;

	// Polyobject type (normal, crush, hurt)
	EPolyobjType Type;

	// Mirror Polyobject
	PolyobjectHandle Mirror;

	// Circular linked list of attached Polyobject Effectors
	PolyobjectEffector EffectorList;

	// Whether the initalization has finished
	bool IsInitialized;

	// Array of lines that make up the polyobject
	Array<Line> Lines;

	// Creates a PolyobjectHandle
	static PolyobjectHandle Create()
	{
		PolyobjectHandle po = PolyobjectHandle(new('PolyobjectHandle'));
		// Sets the underlying Thinker StatNum to 127 so that LastPos, LastAngle etc. get 
		// updated after all the other thinkers.
		po.ChangeStatNum(127);

		return po;
	}

	// Returns a PolyobjectHandle corresponding to the provided polyobject number
	// Returns NULL if no such handler exists.
	static PolyobjectHandle FindPolyobj(int pobjnum)
	{
		PolyobjectHandle po;
		let it = ThinkerIterator.Create('PolyobjectHandle');
		while ((po = PolyobjectHandle(it.Next())) != NULL)
		{
			if (po.PolyobjectNum == pobjnum)
			return po;
		}
		return NULL;
	}

	// Returns a PolyobjectHandle corresponding to the polyobject at provided location
	// Returns NULL if no such handler exists.
	static PolyobjectHandle FindPolyobjAt(Vector2 pos)
	{
		PolyobjectHandle po;
		let it = ThinkerIterator.Create('PolyobjectHandle');
		while ((po = PolyobjectHandle(it.Next())) != NULL)
		{
			if (po.StartSpotPos == pos)
			return po;
		}
		return NULL;
	}


	// Adds effector to the end of current effector list 
	void AddEffector(PolyobjectEffector effector)
	{
		effector.Polyobject = self;

		// If effector list is empty, new effector becomes head of the list
		if (EffectorList == NULL)
		{
			EffectorList = effector;
			effector.Next = effector;
		}
		else
		{
			PolyobjectEffector e = EffectorList;
			// Go through every effector until the last item
			while (e.Next != EffectorList)
			{
				e = e.Next;
			}
			effector.Next = EffectorList;
			e.Next = effector;
		}
		if (IsInitialized)
		{
			// If we're initialized, run the OnAdd effect immediately
			effector.OnAdd();
		}
	}

	// Finds effector of specified class, and returns it
	PolyobjectEffector FindEffector(class<PolyobjectEffector> effectorclass)
	{
		// No effectors? Nothing to find then
		if (EffectorList == NULL)
			return NULL;

		// Go through each effector
		PolyobjectEffector e = EffectorList;
		do
		{

			// Effector is of specified class, return it
			if (e is effectorclass)
			return e;

			e = e.Next;
		}
		while (e != EffectorList);
		return NULL;
	}

	override void PostBeginPlay()
	{
		// Initialization shouldn't happen when reentering the map
		if (Level.Time > 0)
			return;

		// Map has no lines corresponding to this polyobject, destroy the handle
		if (StartLine == NULL)
		{
			Destroy();
			return;
		}

		// Using polyobject linedefs is the only way to track polyobject movements.
		// All geometric calculations will be done relative to StartLine.

		// Store initial position and angle
		StartAngle = VectorAngle(StartLine.Delta.x, StartLine.Delta.y);
		VertexStartingPos[0] = VertexLastPos[0] = StartLine.v1.p;
		VertexStartingPos[1] = VertexLastPos[1] = StartLine.v2.p;

		// Now that the map is loaded, it's safe to call effectors' OnAdd() methods
		PolyobjectEffector e = EffectorList;
		if (e != NULL)
		{
			do
			{
				e.OnAdd();
				e = e.Next;
			}
			while (e != EffectorList);
		}

		// Done initializing
		IsInitialized = true;
	}

	override void Tick()
	{
		// Call PolyTick() for each effector
		if (EffectorList != NULL)
		{
			PolyobjectEffector e = EffectorList;
			do
			{
				e.PolyTick();
				e = e.Next;
			}
			while (e != EffectorList);
		}

		// Store current position/angle to be used during the next tic
		VertexLastPos[0] = StartLine.v1.p;
		VertexLastPos[1] = StartLine.v2.p;
		LastAngle = GetAngle();
		LastPos = GetPos();
	}

	override void OnDestroy()
	{
		// Clean up effectors first
		PolyobjectEffector e = EffectorList;
		if (e != NULL)
		{
			PolyobjectEffector next;
			do
			{
				next = e.Next;
				e.Destroy();
				e = next;
			}
			while (e != EffectorList);
		}
	}

	Sector GetSector()
	{
		if (StartSector) { return StartSector; }

		Vector2 SpotPos = StartSpotPos;

		// Sometimes if StartSpot lies on a one-sided linedef, its position is considered
		// out of bounds by GZDoom, which makes Level.PointInSector() produce unexpected
		// results. In that case, we need to compensate.
		if (!Level.IsPointInLevel((SpotPos, z)))
		{
			// Look at points in a 5x5 square around the StartSpot
			for (int x = -2; x <= 2; x++)
			{
				for (int y = -2; y <= 2; y++)
				{
					SpotPos = StartSpotPos + (x, y);

					if (Level.IsPointInLevel((SpotPos, z)))
					{
						// Found a point within bounds, should be good enough
						StartSector = Level.PointInSector(SpotPos);
						return StartSector;
					}
				}
			}
		}

		// Fall back to level.PointInSector()
		StartSector = Level.PointInSector(SpotPos);
		return StartSector;
	}

	// Returns initial StartSpot position
	Vector2 GetOrigin()
	{
		return StartSpotPos;
	}

	// Returns current polyobject angle
	double GetAngle()
	{
		double lineangle = VectorAngle(StartLine.Delta.x, StartLine.Delta.y);
		return Actor.DeltaAngle(StartAngle, lineangle);
	}

	// Returns current polyobject startspot position 
	Vector2 GetPos()
	{
		let spotdelta = StartSpotPos - VertexStartingPos[0];
		return StartLine.v1.p + Actor.RotateVector(spotdelta, GetAngle());
	}

	// Returns polyobject coordinates relative to the startspot
	Vector2 GetPosDelta()
	{
		return GetPos() - StartSpotPos;
	}

	// Returns last polyobject angle
	double GetLastAngle()
	{
		return LastAngle;
	}

	// Returns last polyobject startspot position
	Vector2 GetLastPos()
	{
		return LastPos;
	}

	// Returns last coordinates relative to the startspot
	Vector2 GetLastPosDelta()
	{
		return LastPos - StartSpotPos;
	}

	// Returns current polyobject velocity
	Vector2 GetVel()
	{
		return StartLine.v1.p - VertexLastPos[0];
	}

	// Returns current polyobject rotation speed
	double GetRotationSpeed()
	{
		return GetAngle() - LastAngle;
	}

	// Returns whether the polyobject has moved from its spawn position
	bool IsAtOrigin()
	{
		return (VertexStartingPos[0] == StartLine.v1.p && VertexStartingPos[1] == StartLine.v2.p);
	}

	// Returns whether the polyobject is in motion
	bool IsMoving()
	{
		return (GetPos() != GetLastPos() || GetAngle() != GetLastAngle());
	}

	// Moves the polyobject to specified location, with specified speed, and plays the
	// specified sound of its sound sequence
	// (i.e. for a door sound sequence, sndseqmode 0 plays the open sound, 1 plays the 
	// closing sound)
	void MoveTo(Actor activator, Vector2 dest, int Speed, int sndseqmode = 0)
	{
		// Stop any polyobject movement
		Level.ExecuteSpecial(Polyobj_Stop, activator, StartLine, Line.Front, PolyobjectNum);
		if (Mirror) { Level.ExecuteSpecial(Polyobj_Stop, activator, StartLine, Line.Front, Mirror.PolyobjectNum); }
		// Move the polyobject
		Level.ExecuteSpecial(Polyobj_OR_MoveTo, activator, StartLine, Line.Front, PolyobjectNum, Speed, int(dest.x), int(dest.y));

		// Polyobj_OR_MoveTo doesn't account for sound sequence modes.
		// Stop any sound and play the proper sound inside the sector containing the polyobject.
		if (SoundSequenceNum)
		{
			Level.ExecuteSpecial(Polyobj_StopSound, activator, StartLine, Line.Front, PolyobjectNum);
			if (Mirror) { Level.ExecuteSpecial(Polyobj_StopSound, activator, StartLine, Line.Front, Mirror.PolyobjectNum); }
			if (sndseqmode > -1) { GetSector().StartSoundSequenceID(PolyobjectNum, SoundSequenceNum, SeqNode.DOOR, sndseqmode, false); }
		}
	}
}

// Class for iterating over polyobjects
class PolyobjectIterator: Object
{
	private ThinkerIterator it;
	static PolyobjectIterator Create()
	{
		let it = New('PolyobjectIterator');
		it.it = ThinkerIterator.Create('PolyobjectHandle');
		return it;
	}

	PolyobjectHandle Next()
	{
		return PolyobjectHandle(it.Next());
	}

	void Reinit()
	{
		it.Reinit();
	}
}