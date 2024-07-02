// Creates a PolyobjectHandle for every polyobject in the map
class PolyobjectHandlePostProcessor: LevelPostProcessor
{
  protected void Apply(Name checksum, String mapname)
  {
    Array<int> pobjnums;
    Array<PolyobjectHandle> pobjhandles;

    // Make sure initialization doesn't happen when reentering a map
    if (Level.Time > 0)
      return;

    // Look for Polyobject StartSpots and create a handle for each
    for (uint i = 0; i < GetThingCount(); i++)
    {
      // Ignore every thing that isn't a Polyobject StartSpot
      int ednum = GetThingEdNum(i);
      if (ednum < PolyobjectHandle.POTYP_NORMAL || ednum > PolyobjectHandle.POTYP_HURT)
        continue;

      // Create a PolyobjectHandle
      PolyobjectHandle handle = PolyobjectHandle.Create();
      
      // Get polyobject number from StartSpot angle
      handle.PolyobjectNum = GetThingAngle(i);

      // Store StartSpot position
      Vector3 pos = GetThingPos(i);
      handle.StartSpotPos = pos.xy;
      handle.z = pos.z;
      handle.StartSpotIndex = i;

      // Store StartSpot type (normal, crush, hurt)
      handle.Type = ednum;

      // Append polyobject number and corresponding handle to the respective arrays
      pobjnums.Push(handle.PolyobjectNum);
      pobjhandles.Push(handle);
    }

    // Look for Polyobj_StartLine/Polyobj_ExplicitLine lines
    for (int i = 0; i < Level.Lines.Size(); i++)
    {
      Line line = Level.Lines[i];

      // Ignore every line that doesn't have a Polyobj_StartLine or Polyobj_ExplicitLine
      // line special
      if (line.Special != Polyobj_StartLine && line.Special != Polyobj_ExplicitLine)
        continue;

      // Get polyobject number
      // (Args[0] for both Polyobj_StartLine and Polyobj_ExplicitLine)
      int pobjnum = line.Args[0];

      // Find the array index of the corresponding handle
      int pobjhandleindex = pobjnums.Find(pobjnum);
      if (pobjhandleindex >= pobjnums.Size())
        continue;  // Polyobject doesn't have a corresponding StartSpot
      
      PolyobjectHandle handle = pobjhandles[pobjhandleindex];

      // Get mirror polyobject number
      // (Args[1] for Polyobj_StartLine, Args[2] for Polyobj_ExplicitLine)
      int mirrorpobjnum = line.Special == Polyobj_StartLine ? line.Args[1] : line.Args[2];
      if (mirrorpobjnum != 0)
      {
        // Find the array index of the mirror polyobject handle
        int mirrorpobjhandleindex = pobjnums.Find(mirrorpobjnum);
        if (mirrorpobjhandleindex < pobjnums.Size())
        {
          // Mirror polyobject handle exists, store it
          handle.Mirror = pobjhandles[mirrorpobjhandleindex];
        }
      }

      // Get sound sequence number and store it
      // (Args[2] for Polyobj_StartLine, Args[3] for Polyobj_ExplicitLine)
      int soundseq = line.Special == Polyobj_StartLine ? line.Args[2] : line.Args[3];
      handle.SoundSequenceNum = soundseq;

      // Store the line
      handle.StartLine = line;
    }
  }
}