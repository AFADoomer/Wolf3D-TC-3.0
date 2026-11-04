// Mark solid scenery after its sector is discovered. The line map uses an X;
// the textured map uses the scenery's current sprite.
class Wolf3DBlockMarker : MapMarker
{
	Default
	{
		Scale 0.45;
	}

	States
	{
		Spawn:
			WMBK A -1;
			Stop;
	}

	override void Tick()
	{
		if (!master || !master.bSolid) { Destroy(); return; }

		CVar textured = CVar.FindCVar("am_textured");
		if (textured && textured.GetBool() && !master.bInvisible && master.sprite > 0)
		{
			sprite = master.sprite;
			frame = master.frame;
			Scale = master.Scale * 0.625;
		}
		else
		{
			sprite = GetSpriteIndex("WMBK");
			frame = 0;
			Scale = (0.45, 0.45);
		}

		Super.Tick();
	}
}

class MapBlockMarkers : StaticEventHandler
{
	bool pending;

	override void WorldLoaded(WorldEvent e)
	{
		pending = true;
	}

	override void WorldTick()
	{
		if (!pending) { return; }
		pending = false;

		MapHandler handler = MapHandler.Get();
		if (!handler || !handler.curmap || handler.curmap.extension.length()) { return; }

		// Markers are serialized with the level. Older saves need them created here.
		if (ThinkerIterator.Create("Wolf3DBlockMarker", Thinker.STAT_MAPMARKER).Next()) { return; }

		let it = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (!mo.bSolid || mo.bIsMonster || mo.player || mo is "Inventory") { continue; }

			let marker = Actor.Spawn("Wolf3DBlockMarker", mo.pos);
			if (!marker) { continue; }

			marker.master = mo;
			marker.args[1] = 1; // only after its sector is seen
			marker.args[2] = 1; // scale with automap zoom
		}
	}
}
