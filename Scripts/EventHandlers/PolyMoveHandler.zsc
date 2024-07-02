/*
 * Copyright (c) 2024 AFADoomer
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
**/

// Handle moving WALLTHING-flagged actors that are placed "on" polyobjects

class ThingInfo
{
	Actor thing;
	Vector2 offset;

	static ThingInfo Add(Array<ThingInfo> things, Actor mo)
	{
		if (!mo) { return null; }
		
		for (int t = 0; t < things.Size(); t++)
		{
			if (things[t].thing == mo) { return things[t]; }
		}

		ThingInfo new = New("ThingInfo");
		new.thing = mo;

		things.Push(new);

		return new;
	}
}

class PolyMoveEffector: PolyobjectEffector
{
	Array<ThingInfo> things; // Array of things that are attached to the polyobject

	override void PolyTick()
	{
		for (int t = 0; t < things.Size(); t++)
		{
			let mo = things[t].thing;
			if (!mo) { continue; }

			if (!things[t].offset.length()) { things[t].offset = mo.pos.xy - PolyObject.GetPos(); }

			if (PolyObject.IsMoving())
			{
				mo.SetOrigin((PolyObject.GetPos() + Actor.RotateVector(things[t].offset, PolyObject.GetAngle()), mo.pos.z), true);
			}
		}
	}

	Line CheckForOverlappingLines(Line checkline)
	{
		for (int l = 0; l < PolyObject.Lines.Size(); l++)
		{
			let ln = PolyObject.Lines[l];
			if (
				(
				ln.v1.p == checkline.v1.p &&
				ln.v2.p == checkline.v2.p
				) ||
				(
				ln.v1.p == checkline.v2.p &&
				ln.v2.p == checkline.v1.p
				)
			) { return ln; }
		}

		return null;
	}
}

class PolyMoveHandler: EventHandler
{
	// This applies PolyMoveEffector to every polyobject on the map.
	override void WorldLoaded(WorldEvent e)
	{
		// Don't apply effectors if the map has been visited before
		if (e.IsReopen) { return; }

		// Iterate through all polyobjects on the map
		let it = PolyobjectIterator.Create();
		PolyobjectHandle po;
		while ((po = it.Next()) != NULL)
		{
			// Create a new effector instance and add it to polyobject's effectors
			PolyMoveEffector eff = New("PolyMoveEffector");
			po.AddEffector(eff);

			if (po.StartLine.special == Polyobj_ExplicitLine)
			{
				po.Lines.Push(po.StartLine);
			}
			else
			{
				// Find all lines that belong to this polyobject
				Sector sec = po.StartLine.frontsector;
				Vertex start = po.StartLine.v1;
				Vertex current = po.StartLine.v2;
				int count = 0;

				while (current.Index() != start.Index() && count < level.lines.Size())
				{
					for (int l = 0; l < sec.lines.Size(); l++)
					{
						count++;
						let ln = sec.lines[l];
						if (ln.v1 == current)
						{
							if (po.Lines.Find(ln) == po.Lines.Size()) { po.Lines.Push(ln); }
							current = ln.v2;
							count = 0;
							break;
						}
						if (count > level.lines.Size()) { break; }
					}
				}
			}
		}
	}

	// This checks spawned things to see if they need to be attached to a polyobject
	override void WorldThingSpawned(WorldEvent e)
	{
		let mo = e.Thing;

		if (mo.bMissile || mo.bNoSector || mo.bNoInteraction) { return; }
		if (!(mo.bWallSprite)) { return; }
		
		PolyobjectHandle po = CheckForPolyobject(mo);
		if (!po) { return; }
		
		PolyMoveEffector eff = PolyMoveEffector(po.FindEffector("PolyMoveEffector"));
		if (!eff) { return; }

		ThingInfo.Add(eff.things, mo);
	}

	PolyobjectHandle CheckForPolyobject(Actor mo)
	{
		// If the thing is not on a line or in front of a sector that could
		// hold a polyobject, skip further processing
		Line linedef = ZScriptTools.GetCurrentLine(mo);
		if (!linedef || !(linedef.flags & Line.ML_TWOSIDED)) { return null; }
		if (
			linedef.backsector.CenterCeiling() == linedef.backsector.CenterFloor() ||
			linedef.frontsector.CenterCeiling() == linedef.frontsector.CenterFloor()
		) { return null; }

		PolyobjectHandle po;
		let it = ThinkerIterator.Create('PolyobjectHandle');
		while ((po = PolyobjectHandle(it.Next())) != null)
		{
			PolyMoveEffector eff = PolyMoveEffector(po.FindEffector("PolyMoveEffector"));
			if (eff && eff.CheckForOverlappingLines(linedef)) { return po; }
		}

		return null;
	}
}
