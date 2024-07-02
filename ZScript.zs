version "4.8.0"

// Classes/Libraries
#include "Scripts/Libraries/DrawToHUD.zs" 		// Drawing and coordinate translation to match HUD element scaling and positioning
#include "Scripts/Libraries/zstools.zs"			// Helper scripts for string manipulation
#include "Scripts/Libraries/MD5.zs"				// 3saster's MD5 hashing algorithm
#include "Scripts/Libraries/BreakString.zs"		// Unicode-aware string/line splitting
#include "scripts/libraries/Polyobjects/Polyobjects.zs" // ZPolyobject by mikolah - https://forum.zdoom.org/viewtopic.php?f=105&t=69999

// Menu Components
#include "Scripts/Menus/ExtendedListMenu.zs"	// New menu with background and skill/episode icons
#include "Scripts/Menus/GenericOptionMenu.zs"	// New option menu with background and generic drawing
#include "Scripts/Menus/ExtendedOptionMenu.zs"	// New menu with background
#include "Scripts/Menus/CloseMenu.zs"			// Menu that closes parent menu when opened
#include "Scripts/Menus/SlideshowMenu.zs"		// Read This and Finale text screens
#include "Scripts/Menus/MessageBox.zs"			// Messages and exit prompts
#include "Scripts/Menus/GetPsyched.zs"			// "Get Psyched" loading bar
#include "Scripts/Menus/Startup.zs"				// Spear of Destiny mission selector

// Event Handler
#include "Scripts/EventHandlers/MapStatsHandler.zs"
#include "Scripts/EventHandlers/LifeHandler.zs"
#include "Scripts/EventHandlers/DeathCamHandler.zs"
#include "Scripts/EventHandlers/KeyHandler.zs"
#include "Scripts/EventHandlers/ConsoleHandler.zs"
#include "Scripts/EventHandlers/ReplacementHandler.zs"
#include "Scripts/EventHandlers/GameHandler.zs"
#include "Scripts/EventHandlers/MapHandler.zs"
#include "Scripts/EventHandlers/DoorHandler.zsc"
#include "Scripts/EventHandlers/PolyMoveHandler.zsc"

// Level Post-processing
#include "Scripts/WolfPostProcessing.zs"

// Status Bar
#include "Scripts/ClassicStatusBar.zs"
#include "Scripts/ClassicWidgets.zs"

// Stats Screen
#include "Scripts/ClassicStats.zs"

// Actors
#include "Scripts/Actors/Player.zs"
#include "Scripts/Actors/Stackable.zs"
#include "Scripts/Actors/Enemies.zs"
#include "Scripts/Actors/Objects.zs"
#include "Scripts/Actors/Weapons.zs"
#include "Scripts/Actors/Projectiles.zs"
#include "Scripts/Actors/Miscellaneous.zs"