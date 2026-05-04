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

class DeathCamHandler : EventHandler
{
	TextureID deathcamtex;
	Vector2 size;
	Actor deathcam;

	int tick;
	bool draw;

	override void WorldThingSpawned(WorldEvent e)
	{
		if (e.Thing is "DeathCam")
		{
			deathcam = e.Thing;

			deathcamtex = TexMan.CheckForTexture("DEATHCAM", TexMan.Type_Any);
			if (deathcamtex.IsValid())
			{
				size = TexMan.GetScaledSize(deathcamtex);
				size *= 2;
			}
		}
	}

	override void RenderOverlay( RenderEvent e )
	{
		if (deathcam && draw && deathcamtex.IsValid() && size != (0, 0) && tick % 47 <= 35)
		{
			screen.DrawTexture(deathcamtex, true, 160 - size.x / 2, 4, DTA_320x200, true, DTA_DestWidth, int(size.x), DTA_DestHeight, int(size.y), DTA_TopOffset, 0, DTA_LeftOffset, 0);
		}
	}

	override void WorldTick()
	{
		if (deathcam)
		{
			switch (tick)
			{
				case 25:
					EventHandler.SendInterfaceEvent(consoleplayer, "fizzle", 0x004040, 1, 1920);
					break;
				case 60:
					Menu.SetMenu("DeathCamMessage");
					break;
				case 130:
					draw = true;
					if (deathcam.master) { deathcam.master.SetStateLabel("Death.Cam"); } 
					break;
				case 200:
					players[consoleplayer].camera = deathcam;
					EventHandler.SendInterfaceEvent(consoleplayer, "fizzle", 0x0, 0, -1920);
					break;
				case 445:
					Level.ExitLevel(0, false);
					break;
				default:
					break;
			}

			tick++;
		}
	}
}