class PolyobjectEffector: Thinker abstract
{
  // Base abstract class for Polyobject Effectors
  // Polyobject Effectors affect how a polyobject behaves.
  // Polyobject Effectors contain a pointer to the next Effector of a polyobject, 
  // forming a circular linked list.
  // To add an effector to a polyobject, call AddEffector() on a PolyobjectHandle.
  // To remove an effector, simply call Destroy() on it.

  PolyobjectHandle Polyobject;
  PolyobjectEffector Next;

  // OnAdd() is called once after adding the effector to a PolyobjectHandle
  virtual void OnAdd()
  {

  }

  // PolyTick() is called every tic by a PolyobjectHandle
  virtual void PolyTick()
  {

  }

  override void OnDestroy()
  {
    PolyobjectEffector e = Polyobject.EffectorList;
    if (e != NULL)
    {
      // Find previous effector
      while (e && e.Next != self)
      {
        e = e.Next;
      }

      // Link previous effector to the next effector
      e.Next = Next;

      // Check if this effector is the last one
      if (e == self)
      {
        // Polyobject has no other effectors, set EffectorList to NULL
        Polyobject.EffectorList = NULL;
      }
    }
    Super.OnDestroy();
  }
}
