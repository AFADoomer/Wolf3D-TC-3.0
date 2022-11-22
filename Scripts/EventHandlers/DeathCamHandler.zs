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