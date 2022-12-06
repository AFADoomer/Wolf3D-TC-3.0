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
	bool active;
	TextureID deathcam;
	Vector2 size;

	int tick;

	override void WorldThingSpawned(WorldEvent e)
	{
		if (e.Thing is "DeathCam")
		{
			active = true;
			deathcam = TexMan.CheckForTexture("DEATHCAM", TexMan.Type_Any);
			if (deathcam)
			{
				size = TexMan.GetScaledSize(deathcam);
				size *= 2;
			}
		}
	}

	override void RenderOverlay( RenderEvent e )
	{
		if (active && deathcam && size != (0, 0) && tick <= 35)
		{
			screen.DrawTexture(deathcam, true, 160 - size.x / 2, 4, DTA_320x200, true, DTA_DestWidth, int(size.x), DTA_DestHeight, int(size.y), DTA_TopOffset, 0, DTA_LeftOffset, 0);
		}
	}

	override void WorldTick()
	{
		if (active) { tick = (tick + 1) % 47; }
	}
}