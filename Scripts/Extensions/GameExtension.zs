/*
 * Copyright (c) 2026 ksavery
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

// Game extensions let a mod add its own games to the TC - map/graphics data
// files with their own extension (GAMEMAPS.XYZ, VSWAP.XYZ...) - and change
// how the TC presents and plays them, without editing TC code.
//
// A mod subclasses GameExtension; GameExtensionHandler creates one of each
// subclass at startup. Each hook is asked of the extension that claims the
// game being played (Handles), with that game's extension as 'game'. Before
// any game is picked, the extension that returns true from IsDefault is asked
// instead, with an empty 'game'. Every hook does nothing by default.
//
// The game picked in the game menu is kept in g_modgame; the map being played
// (MapHandler.curmap, or the queued one) takes precedence over it.
class GameExtension
{
	// Games ----------------------------------------------------------------

	// True for the data file extensions (upper case) this extension provides
	virtual bool Handles(String ext) { return false; }

	// The extensions of its games, to check for data files at startup
	virtual void ListGames(in out Array<String> exts) {}

	// Dress the TC's shared screens (startup, game menu) before a game is picked
	virtual bool IsDefault() { return false; }

	// Several games can share one VSWAP / GraphicMaps / TileCodes set
	virtual String DataSet(String ext) { return ext; }

	virtual String Title(String ext) { return ""; }

	// Game rules the maps run under, as g_sod (0 Wolf3D, 1 Spear...); -1 lets the TC decide
	virtual int GameType(String ext) { return -1; }

	// MAPINFO level number of a map (0-based slot in the GAMEMAPS file); -1 keeps the TC's
	virtual int MapNumber(String ext, int slot) { return -1; }

	// Map building -----------------------------------------------------------

	// Called once a map is read from its GAMEMAPS file
	virtual void PrepareMap(ParsedMap map) {}

	// Actor codes placed in wall tiles that should keep their wall
	virtual bool WallActor(String ext, int code) { return false; }

	// Floor/ceiling for the level: palette colours (-1 for the TC's), texture
	// names ("" for the TC's) and whether the ceiling is sky (set it up here)
	virtual play int, int, String, String, bool LevelFlats(String game, ParsedMap map) { return -1, -1, "", "", false; }

	// The map a fresh "Level" builds when nothing is queued; null for the TC's choice
	virtual play ParsedMap StartingMap(MapHandler handler) { return null; }

	// Doors and pushwalls ---------------------------------------------------

	// False keeps the activator from using a door or pushwall line
	virtual play bool AllowDoorUse(String game, Line ln, Actor activator) { return true; }

	// SNDSEQ door number for a door or pushwall; -1 for the TC's
	virtual play int DoorSound(String game, PolyobjectHandle po, bool pushwall) { return -1; }

	// How many tiles a pushwall may slide (setting: g_maxpushwallmove)
	virtual int PushwallMoves(String game, int setting) { return setting; }

	// Actors and rules --------------------------------------------------------

	// Hit points, score and speed of a stock enemy, as it spawns
	virtual play void SetupEnemy(String game, ClassicBase mo) {}

	// Message for picking up one of the TC's weapons; "" for its own (none)
	virtual play String PickupMessage(String game, Inventory item) { return ""; }

	// Whether taking the Spear ends this map: 1 yes, 0 no, -1 the TC's rule
	virtual play int SpearEndsLevel(String game, ParsedMap map) { return -1; }

	// Music and screens -------------------------------------------------------

	// The song to play for a TC song name (title, menu, intermission...); "" for the TC's
	virtual String Music(String game, String song) { return ""; }

	// Fill a screen rectangle where the TC fills with its background colour
	virtual ui bool DrawBackdrop(String game, int x, int y, int w, int h) { return false; }

	// Menu window fill, top/left and bottom/right edge colours
	virtual ui bool, Color, Color, Color WindowColors(String game) { return false, 0, 0, 0; }

	// Whether to draw the menu window box in this menu at all
	virtual ui bool MenuBox(String game, Menu current) { return true; }

	// Whether the main menu has a Read This! entry (Spear's has none)
	virtual ui bool ReadThis(String game) { return false; }

	// Font colour for disabled menu items; -1 for the TC's
	virtual ui int DisabledColor(String game) { return -1; }

	// The game's own version of a menu graphic; an invalid TextureID for the TC's
	virtual TextureID MenuTexture(String game, String name, int usetype)
	{
		TextureID none;
		none.SetInvalid();
		return none;
	}

	// Colour the screen fades through between menus; -1 for the TC's
	virtual ui int FadeColor(String game) { return -1; }

	// Intermission background colour; -1 for the TC's
	virtual ui int IntermissionColor(String game) { return -1; }

	// The ending sequence menu; 'None' for the TC's
	virtual Name FinaleMenu(String game) { return 'None'; }

	// Episode (MAPINFO cluster menu index) New Game goes straight to; -1 shows the episode menu
	virtual ui int Episode(String game) { return -1; }

	// Skip the TC's own intro after the startup notice, straight to the game menu
	virtual ui bool SkipIntro(String game) { return false; }

	// Startup slideshow graphics: "startup", "startup2", "title", "credits",
	// "warning", "selected"; "" for the TC's
	virtual ui String IntroGraphic(String game, String which) { return ""; }

	// Draw one of the startup slideshow screens itself
	virtual ui bool DrawIntroScreen(String game, String which, TextureID tex) { return false; }

	// Status bar and messages --------------------------------------------------

	// Draw the game's own status bar in place of the TC's
	virtual ui bool DrawStatusBar(String game, ClassicStatusBar sb, int points, int lives) { return false; }

	// Draw over the status bar and view (messages and the like)
	virtual ui void DrawOverlay(String game, ClassicStatusBar sb) {}

	// Take over a notification or centred message; true when handled
	virtual ui bool ProcessNotify(String game, ClassicStatusBar sb, int printlevel, String text) { return false; }
	virtual ui bool ProcessMidPrint(String game, ClassicStatusBar sb, String text) { return false; }

	// Input -------------------------------------------------------------------

	// Keyboard input in play (cheat keys...); true when handled
	virtual ui bool InputProcess(String game, InputEvent e) { return false; }

	// Whether Wolf3D's own cheat keys work in this game
	virtual ui bool StockCheats(String game) { return true; }

	// Lookups -----------------------------------------------------------------

	static clearscope GameExtensionHandler GetHandler()
	{
		return GameExtensionHandler(StaticEventHandler.Find("GameExtensionHandler"));
	}

	// The extension that provides a game, or null
	static clearscope GameExtension Find(String ext)
	{
		if (!ext.length()) { return null; }

		let handler = GetHandler();
		if (!handler) { return null; }

		ext = ext.MakeUpper();
		for (int e = 0; e < handler.extensions.Size(); e++)
		{
			if (handler.extensions[e].Handles(ext)) { return handler.extensions[e]; }
		}

		return null;
	}

	// The extension game being played (or about to be), else the one picked
	// in the game menu unless 'picked' is false; "" for the TC's own games
	static clearscope String CurrentGame(bool picked = true)
	{
		MapHandler maps = MapHandler.Get();
		ParsedMap pm = maps ? (maps.curmap ? maps.curmap : maps.queuedmap) : null;
		if (pm) { return Find(pm.extension) ? pm.extension.MakeUpper() : ""; }

		if (picked && Find(g_modgame)) { return g_modgame.MakeUpper(); }

		return "";
	}

	// The extension to ask about the current game: its owner, or before any
	// game is picked, the default one. Returns the game's extension too.
	static clearscope GameExtension, String Current()
	{
		String game = CurrentGame();
		if (game.length()) { return Find(game), game; }

		if (g_sod >= 0) { return null, ""; } // one of the TC's own games

		let handler = GetHandler();
		if (!handler) { return null, ""; }

		for (int e = 0; e < handler.extensions.Size(); e++)
		{
			if (handler.extensions[e].IsDefault()) { return handler.extensions[e], ""; }
		}

		return null, "";
	}

	// Shorthands for the TC's call sites

	static clearscope String GetDataSet(String ext)
	{
		let ex = Find(ext);
		return ex ? ex.DataSet(ext.MakeUpper()) : "";
	}

	static clearscope TextureID GetMenuTexture(String name, int usetype = TexMan.Type_Any)
	{
		GameExtension ex;
		String game;
		[ex, game] = Current();

		if (ex)
		{
			TextureID tex = ex.MenuTexture(game, name, usetype);
			if (tex.IsValid()) { return tex; }
		}

		return TexMan.CheckForTexture(name, usetype);
	}

	static ui bool Backdrop(int x, int y, int w, int h)
	{
		GameExtension ex;
		String game;
		[ex, game] = Current();

		return ex && ex.DrawBackdrop(game, x, y, w, h);
	}

	static ui bool, Color, Color, Color GetWindowColors()
	{
		GameExtension ex;
		String game;
		[ex, game] = Current();

		if (!ex) { return false, 0, 0, 0; }

		bool custom;
		Color fill, top, bottom;
		[custom, fill, top, bottom] = ex.WindowColors(game);
		return custom, fill, top, bottom;
	}

	static ui int GetFadeColor()
	{
		GameExtension ex;
		String game;
		[ex, game] = Current();

		return ex ? ex.FadeColor(game) : -1;
	}

	static ui int GetIntermissionColor()
	{
		GameExtension ex;
		String game;
		[ex, game] = Current();

		return ex ? ex.IntermissionColor(game) : -1;
	}

	static clearscope bool IsWallActor(String ext, int code)
	{
		let ex = Find(ext);
		return ex && ex.WallActor(ext.MakeUpper(), code);
	}

	static clearscope Name GetFinaleMenu()
	{
		GameExtension ex;
		String game;
		[ex, game] = Current();

		Name finale = ex ? ex.FinaleMenu(game) : 'None';
		return finale == 'None' ? 'SoDFinale' : finale;
	}
}

// Creates and keeps one of each GameExtension subclass. Listed first in
// MAPINFO's EventHandlers: the TC's handlers ask the extensions while they
// load their data.
class GameExtensionHandler : StaticEventHandler
{
	Array<GameExtension> extensions;

	override void OnRegister()
	{
		for (int c = 0; c < AllClasses.Size(); c++)
		{
			let cls = AllClasses[c];
			if (cls == "GameExtension" || !(cls is "GameExtension")) { continue; }

			extensions.Push(GameExtension(new(cls)));
		}
	}
}
