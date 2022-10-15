/*

  ListMenu extension that allows for menus in the style of Wolf3D's episode and
  skill selection screens.

  This code implements two new ListItem classes: 
	IconListMenu
	- Adds an image to the left of each menu entry, resulting in a menu that 
	  looks similar to the Wolf3D episode selection menu
	- Also handles automatically offsetting the selection cursor

	StaticIconListMenu
	- Adds an image to the center-right of the entire menu, similar to the one 
	  seen on the Wolf3D skill selection menu
	- Automatically calculates position and offsets based on the number and size
	  of the entries in the menu

  Both of these classes also add the ability to cause menu entries to generate a 
  popup message similar to Wolf3D shareware's "Click Read This to find out how to 
  order" message.

  To use these classes, they must be set up in MENUDEF by setting the class of
  the menu you are changing to one of these class names.  For example, if I
  wanted to have a Wolf3D-style episode select, my EpisodeMenu definition would
  look something like this:

		ListMenu "EpisodeMenu"
		{
			StaticPatchCentered 160, 5, "M_EPIS"

			NetgameMessage "$NEWGAME"
			Position 70, 60

			Linespacing 26

			Class "IconListMenu"
		}

  Once this is done, you must add the appropriate images and/or LANGUAGE lump
  entries to your mod. Note that if your image is taller than one line of the 
  menu font's text, you will also need to adjust Linespacing in MENUDEFS, since
  Episode properties aren't exported to ZScript (yet?). 

  All additional menu content must follows a specific naming convention!

  The name of the menu (with "Menu" removed from the end) is used as the base
  of all lookup strings (So, "Episode", "Skill", etc.).  The number of the menu
  item (1st item is 1, 2nd item is 2, etc.) is used as the index (this also 
  means that if you re-order your menu items, you'll need to rename your images
  and LANGUAGE entries as well).

    Lookup Strings Used:
	Icon Images (Texture name lookup):	
	[Lookup Base][index] 	   	Example: EPISODE1, SKILL2, etc.

	Popup Text (LANGUAGE lookup):
	[Lookup Base][index]MESSAGE	Example: EPISODE1MESSAGE, SKILL5MESSAGE

  Images will automatically be used if they are present.  If you do not 
  provide an image or string for a menu item, then the menu entry will appear 
  as it normally would in a standard ListMenu (though spacing and offsets may 
  still be affected if other icons are present).

  Popup messages are handled slightly differently.  In order to set up a popup 
  message, you must add "[Optional]" to the beginning of your episode's name
  in MAPINFO:

		episode C3M1
		{
			name = "[Optional]The Clash of Faith"
		}

  The "[Optional]" portion of the name will be stripped off when the episode 
  select screen is rendered, but is used as a flag internally by this code.

  If you add "[Optional]" to the episode name but do not include an 
  EPISODExMESSAGE string in LANGUAGE, the code will attempt to look up the 
  SWSTRING string as a fallback.  If that string is empty, no message will be
  displayed.

*/
// Base class that handles drawing informational text under menu entries and display of Wolf3D-style popup message on tagged menu entries
class ExtendedListMenu : ListMenu
{
	String lookupBase;
	int itemCount;
	String overlaytext;
	Array<int> placeholders;

	TextureID controls, bkg;

	String cursor;
	int blinktime;

	int fadetarget;
	int fadetime;
	double fadealpha;
	int fadecolor;
	double initialalpha;

	bool exitmenu;
	int exittimeout;

	bool nodim;

	ListMenuItem activated;

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		GetPlaceholders();

		// Allow generic lookups - strip "menu" off of the menu name, and use that stub as the lookup base (e.g., SKILL, EPISODE, etc.)
		String MenuName = mDesc.mMenuName;
		MenuName = MenuName.MakeUpper();
		MenuName.Replace("MENU", "");

		lookupBase = MenuName;

		controls = TexMan.CheckForTexture((Game.IsSoD() ? "M_SCNTRL" : "M_CNTRLS"), TexMan.Type_Any);
		bkg = TexMan.CheckForTexture("MENUBLUE", TexMan.Type_Any);

		if (gamestate != GS_FINALE) { S_ChangeMusic("WONDERIN"); }

		fadetime = 12;
		fadetarget = gametic;
		fadealpha = 1.0;
		initialalpha = 1.0;

		if (mParentMenu && !(mParentMenu is "IntroSlideshow")) { fadecolor = (Game.IsSoD() ? 0x000088 : 0x880000); }
		else if (!mParentMenu) { initialalpha = 0; fadealpha = 0; fadetarget = gametic + fadetime; }

		nodim = false;
		DontDim = true;
	}

	override void Drawer()
	{
		if (initialalpha < 1.0)
		{
			screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
			initialalpha = fadealpha;

			return;
		}

		screen.Dim((Game.IsSoD() ? 0x000088 : 0x880000), 1.0 * initialalpha, 0, 0, screen.GetWidth(), screen.GetHeight());
		mDesc.mSelector = TexMan.CheckForTexture((Game.IsSoD() ? "M_SSEL1" : "M_SEL1"), TexMan.Type_Any);
		if (Game.IsSoD())
		{
			if (bkg) { screen.DrawTexture(bkg, true, 0, 0, DTA_Fullscreen, 1); }
			mDesc.mSelectOfsY = 1;
		}
		else
		{
			mDesc.mSelectOfsY = -1;
		}

		double ratio = screen.GetAspectRatio();

		// Calculate width and height to keep the image at the same relative size, regardless of aspect ratio
		double width = ratio > 1.25 ? 200 * ratio : 320;
		double height = ratio < 1.25 ? 320 / ratio : 200;

		if (controls)
		{
			Vector2 size = TexMan.GetScaledSize(controls);

			screen.DrawTexture(controls, true, screen.GetWidth() / 2 - size.x * CleanXfac / 2, screen.GetHeight() - size.y * CleanyFac, DTA_CleanNoMove, true, DTA_DestWidth, int(size.x * CleanXfac), DTA_DestHeight, int(size.y * CleanYfac), DTA_Alpha, initialalpha);
		}

		Super.Drawer();

		DrawItemIcon(mDesc.mSelectedItem, alpha:initialalpha);

		screen.Dim(fadecolor, fadealpha * initialalpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		Super.Ticker();

		if (gametic > 1)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}

		if (exitmenu)
		{
			if (!mParentMenu) { initialalpha = fadealpha; }
			else { initialalpha = 1.0; }

			exittimeout++;

			if (exittimeout >= fadetime)
			{
				S_ChangeMusic(level.music);
				Close();
			}
		}

		if (activated && gametic >= fadetarget)
		{
			if (activated.Activate())
			{
				activated = null;
 				RestorePlaceholderMarkers();
			}
		}

		if (mDesc.mSelectedItem < 0 || !mDesc.mItems[mDesc.mSelectedItem].mEnabled)
		{
			mDesc.mSelectedItem = 0;
			while (!mDesc.mItems[mDesc.mSelectedItem].Selectable()) { mDesc.mSelectedItem++; }
		}
	}

	virtual void DrawItemIcon(int index, double x = -1, double y = -1, double alpha = 1.0)
	{
		return;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (fadealpha != 0) { return false; }

		switch (mkey)
		{
			case MKEY_Back:
				if (gamestate != GS_FINALE)
				{
					if (mParentMenu && !(mParentMenu is "IntroSlideshow")) // Only allow backing out of submenus, not the root/main menu
					{
						fadecolor = 0x000000;
						fadetarget = gametic + fadetime;
						exitmenu = true;

						RestorePlaceholderMarkers();
						return Super.MenuEvent(mkey, fromcontroller);
					}
					else
					{
						SetMenu("QuitMenu");
					}
				}
				return false;
			case MKEY_Enter:
				if (mDesc.mSelectedItem >= 0)
				{
					if (placeholders.Find(mDesc.mSelectedItem) != placeholders.Size())
					{
						overlaytext = StringTable.Localize("$" .. lookupBase .. mDesc.mSelectedItem .. "MESSAGE");
						if (overlaytext == lookupBase .. mDesc.mSelectedItem .. "MESSAGE") // Message wasn't found
						{
							overlaytext = StringTable.Localize("$SWSTRING");
							if (overlaytext == "SWSTRING") { overlaytext = ""; return false; } // Default wasn't found either
						}

						MenuSound("menu/alert");
						StartMessage(overlaytext, 1);
						return false;
					}
					else
					{
						let itemaction = mDesc.mItems[mDesc.mSelectedItem].GetAction();

						if (
							itemaction &&
							!(
								itemaction == "QuitMenu" ||
								itemaction == "EndGameMenu" ||
								itemaction == "CloseMenu"
							)
						)
						{
							if (itemaction == "StartGame" || itemaction == "StartGameConfirm" || itemaction == "HelpMenu")
							{
								fadecolor = 0x000000;
							}
							else
							{
								fadecolor = (Game.IsSoD() ? 0x000088 : 0x880000);
							}
							fadetarget = gametic + fadetime;
							activated = mDesc.mItems[mDesc.mSelectedItem];
							MenuSound("menu/select");
						}
						else if (mDesc.mItems[mDesc.mSelectedItem].Activate()) { MenuSound("menu/select"); }
					}
				}
				return true;
			default:
				return Super.MenuEvent(mkey, fromcontroller);
		}
	}

	override void OnReturn()
	{
		if (!nodim)
		{
			fadetarget = gametic;
			GetPlaceholders();
		}
		initialalpha = 1.0;
		nodim = false;
		fadecolor = (Game.IsSoD() ? 0x000088 : 0x880000);
	}

	void GetPlaceholders()
	{
		int index = 0;

		placeholders.Clear();

		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			if (mDesc.mItems[i] is "ListMenuItemTextItem" && mDesc.mItems[i].GetAction() == "SkillMenu")
			{
				index++;

				String temp = StringTable.Localize(ListMenuItemTextItem(mDesc.mItems[i]).mText);
				String temp2 = temp;

				temp.Replace("[Optional]", "");

				// If the replacement string wasn't there, then this one is good
				if (temp == temp2) { continue; }

				// Fix the text string...
				ListMenuItemTextItem(mDesc.mItems[i]).mText = temp;

				// Check to see if the map lump is present
				// Need access to native AllEpisodes array to do this properly...
				String map = "Maps/E" .. index .. "L1.wad";

				// If it's there, continue...
				if (Wads.CheckNumForFullName(map) > -1) { continue; }

				// Otherwise, recolor it, and add it to the list of known placeholders
				ListMenuItemTextItem(mDesc.mItems[i]).mColor = Font.FindFontColor("WolfMenuGreen");
				ListMenuItemTextItem(mDesc.mItems[i]).mColorSelected = Font.FindFontColor("WolfMenuGreenBright");

				placeholders.Push(i);
			}
		}
	}

	void RestorePlaceholderMarkers()
	{
		// Restore the placeholder marker for popup message menus so that they will be treated correctly next time the menu is opened
		if (placeholders.Size())
		{
			for (int p = 0; p < placeholders.Size(); p++)
			{
				ListMenuItemTextItem(mDesc.mItems[placeholders[p]]).mText = "[Optional]" .. ListMenuItemTextItem(mDesc.mItems[placeholders[p]]).mText;
			}
		}
	}
}

// For an icon beside the menu entry, like Wolf3D episode select
class IconListMenu : ExtendedListMenu
{
	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		Vector2 iconSize;

		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			TextureID tex = TexMan.CheckForTexture(lookupBase .. i, TexMan.Type_MiscPatch);

			if (tex.IsValid())
			{
				Vector2 texsize = TexMan.GetScaledSize(tex);

				if (texsize.x > iconSize.x) { iconSize.x = int(texsize.x); }
			}

			if (mDesc.mItems[i].Selectable()) { mDesc.mItems[i].SetX(mDesc.mXpos + iconsize.x / 2); }
		}

		if (mDesc.mXpos + mDesc.mSelectOfsX > mDesc.mXpos - iconSize.x * 1.3) { mDesc.mSelectOfsX -= iconSize.x * 1.3; }
	}

	override void DrawItemIcon(int index, double x, double y, double alpha)
	{
		double fontheight = mDesc.mFont.GetHeight();
		double drawx = x;
		double drawy = y;
		int itemindex = 0;

		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			if (mDesc.mItems[i].Selectable() && mDesc.mItems[i].GetAction() == 'SkillMenu')
			{
				itemindex++;

				// Again, semi-hard-coded, unfortunately - Icons must be named [Menu name]1, [Menu name]2, etc.
				TextureID tex = TexMan.CheckForTexture(lookupBase .. itemindex, TexMan.Type_MiscPatch);
				if (tex.IsValid())
				{
					Vector2 texsize = TexMan.GetScaledSize(tex);

					// Default to Wolf3D-style positioning, roughly vertically centered on the episode name
					if (x == -1) { drawx = mDesc.mItems[i].GetX() - texsize.x / 2 - 10; }
					if (y == -1) { drawy = mDesc.mItems[i].GetY() + fontheight; }

					// Use the center of the image for positioning
					drawx -= texsize.x / 2;
					drawy -= texsize.y / 2; 

					screen.DrawTexture(tex, false, drawx, drawy, DTA_Clean, true, DTA_Alpha, 1.0);
				}
			}
		}
	}
}

class EpisodeMenu : IconListMenu
{
	override void Drawer()
	{
		for (int i = 3; i < mDesc.mItems.Size(); i++)
		{
			mDesc.mItems[i].SetY(mDesc.mItems[i - 1].GetY() + 26);
		}

		Super.Drawer();

		if (Game.IsSoD())
		{
			Close();
			Menu.SetMenu("SkillMenu", 5 + Game.IsSoD());
		}
		else
		{
			for (int i = 8; i < mDesc.mItems.Size(); i++)
			{
				mDesc.mItems[i].mEnabled = false;
			}
		}
	}
}

class GameMenu : IconListMenu
{
	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		controls = TexMan.CheckForTexture("M_CNTRLS", TexMan.Type_Any);

		CVar sodvar = CVar.FindCVar("g_sod");
		if (sodvar) { sodvar.SetInt(-1); }

		fadetarget = gametic;
		fadealpha = 1.0;

		S_ChangeMusic("SALUTE");
	}

	override void Drawer()
	{
		screen.Dim(0x282828, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

		double ratio = screen.GetAspectRatio();

		// Calculate width and height to keep the image at the same relative size, regardless of aspect ratio
		double width = ratio > 1.25 ? 200 * ratio : 320;
		double height = ratio < 1.25 ? 320 / ratio : 200;

		// if (bkg) { screen.DrawTexture(bkg, true, 0, 0, DTA_FullscreenEx, 2); }

		if (controls)
		{
			Vector2 size = TexMan.GetScaledSize(controls);
			screen.DrawTexture(controls, true, screen.GetWidth() / 2 - size.x * CleanXfac / 2, screen.GetHeight() - size.y * CleanyFac, DTA_CleanNoMove, true, DTA_DestWidth, int(size.x * CleanXfac), DTA_DestHeight, int(size.y * CleanYfac), DTA_Alpha, 1.0, DTA_Desaturate, 255);
		}

		for(int i=0;i<mDesc.mItems.Size(); i++)
		{
			if (mDesc.mSelectedItem == i)
			{
				if (!menuDelegate.DrawSelector(mDesc))
					mDesc.mItems[mDesc.mSelectedItem].DrawSelector(mDesc.mSelectOfsX, mDesc.mSelectOfsY, mDesc.mSelector, mDesc);
			}

			if (mDesc.mItems[i].mEnabled) mDesc.mItems[i].Draw(mDesc.mSelectedItem == i, mDesc);
		}
		Menu.Drawer();

		DrawItemIcon(mDesc.mSelectedItem);

		screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void DrawItemIcon(int index, double x, double y, double alpha)
	{
		double fontheight = mDesc.mFont.GetHeight();
		double drawx = x;
		double drawy = y;
		int itemindex = 0;

		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			if (mDesc.mItems[i].Selectable() && mDesc.mItems[i].GetAction() == '')
			{
				itemindex++;

				// Again, semi-hard-coded, unfortunately - Icons must be named [Menu name]1, [Menu name]2, etc.
				TextureID tex = TexMan.CheckForTexture(lookupBase .. itemindex, TexMan.Type_MiscPatch);
				if (tex.IsValid())
				{
					Vector2 texsize = TexMan.GetScaledSize(tex);

					// Default to Wolf3D-style positioning, roughly vertically centered on the episode name
					if (x == -1) { drawx = mDesc.mItems[i].GetX() - texsize.x / 2 - 10; }
					if (y == -1) { drawy = mDesc.mItems[i].GetY() + fontheight; }

					// Use the center of the image for positioning
					drawx -= texsize.x / 2;
					drawy -= texsize.y / 2; 

					screen.DrawTexture(tex, false, drawx, drawy, DTA_Clean, true, DTA_Alpha, 1.0);
				}
			}
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		switch (mkey)
		{
			case MKEY_Enter:
				CVar sodvar = CVar.FindCVar("g_sod");
				if (sodvar) { sodvar.SetInt(mDesc.mSelectedItem - 2); }

				SetMenu("IntroSlideShow", -1);
				return true;
		}

		return Super.MenuEvent(mkey, fromcontroller);
	}

	override void Ticker()
	{
		Super.Ticker();

		if (gametic <= 35) { fadealpha = 1.0; }
	}
}

class ListMenuItemGameSelection : ListMenuItemTextItem
{
	override void Draw(bool selected, ListMenuDescriptor desc)
	{
		let fnt = menuDelegate.PickFont(mFont);
		String title = StringTable.Localize(mText);

		BrokenLines lines = fnt.BreakLines(title, CleanWidth_1);

		int offset = fnt.GetHeight() / 2 - ((lines.count() - 1) * fnt.GetHeight()) / 2;

		DrawText(desc, fnt, selected ? mColorSelected : mColor, mXpos, mYpos + offset, title);
	}
}

// For an icon that swaps out in place, like the Wolf3D skill menu
class StaticIconListMenu : ExtendedListMenu
{
	double iconOffset;
	int listsize;

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		// Some logic to determine the rightmost pixel point of the middle skill values
		//  Used for default positioning a la Wolf3D
		double maxWidth;
		int min;

		mDesc = desc;

		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			if (mDesc.mItems[i].Selectable())
			{
				listsize++;
			}
		}

		// Find the middle skill menu entry (with rounding if odd number of entries)
		double median = listsize / 2;
		if (median < int(median) + 0.5) { min = int(median); }
		else { min = int(median) + 1; } 

		// Figure out the widest skill name...
		int itemcount = 0;
		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			if (mDesc.mItems[i].Selectable())
			{
				itemcount++;
				if (itemcount >= min && itemcount < min + 2)
				{
					int width = mDesc.mItems[i].GetWidth();
					if (width > maxWidth) { maxWidth = width; }
				}
			}
		}

		// ... And use it's length to calculate the default x offset
		iconOffset = mDesc.mXPos + maxWidth * 5 / 7;

		Super.Init(parent, desc);
	}

	override void DrawItemIcon(int index, double x, double y, double alpha)
	{
		if (index < 0) { return; }

		double fontheight = mDesc.mFont.GetHeight();

		int itemindex = 1;	
		for (int i = 0; i < index; i++)
		{
			if (mDesc.mItems[i].Selectable())
			{
				itemindex++;
			}
		}

		// Again, semi-hard-coded, unfortunately - Icons must be named [Menu name]1, [Menu name]2, etc.
		TextureID tex = TexMan.CheckForTexture(lookupBase .. itemindex, TexMan.Type_MiscPatch);
		if (tex.IsValid())
		{
			Vector2 texsize = TexMan.GetScaledSize(tex);

			// Default to Wolf3D-style positioning, roughly vertically centered on the skill list, 
			//  horizontally centered between the screen edge and the longest of the middle skill names.
			if (x == -1) { x = (320 + iconOffset) / 2; }
			if (y == -1) { y = mDesc.mYpos + (listsize * mDesc.mLinespacing) / 2 - 4; }

			// Use the center of the image for positioning
			x -= texsize.x / 2;
			y -= texsize.y / 2; 

			screen.DrawTexture(tex, false, x, y, DTA_Clean, true, DTA_Alpha, alpha);
		}
	}
}

class SkillMenu : StaticIconListMenu
{
	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		if (Game.IsSoD()) { lookupbase = "S" .. lookupbase; }
	}

	override void Drawer()
	{
		Super.Drawer();
	}
}

class ExtendedLoadMenu : LoadMenu
{
	TextureID controls, bkg;
	double yoffset;

	int fadetarget;
	int fadetime;
	double fadealpha;
	int fadecolor;

	double initialalpha;

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		yoffset = desc.mYpos;

		SetYOffsets(yoffset);

		controls = TexMan.CheckForTexture((Game.IsSoD() ? "M_SCNTRL" : "M_CNTRLS"), TexMan.Type_Any);
		bkg = TexMan.CheckForTexture("MENUBLUE", TexMan.Type_Any);

		fadetime = 12;
		fadetarget = gametic;
		fadealpha = 1.0;
		fadecolor = (Game.IsSoD() ? 0x000088 : 0x880000);

		S_ChangeMusic("WONDERIN");
	}

	void SetYOffsets(double yoffset)
	{
		savepicTop = int(yoffset * CleanYfac);

		listboxTop = savepicTop;
		int listboxHeight1 = screen.GetHeight() - listboxTop - 10 * CleanYfac;
		listboxRows = (listboxHeight1 - 1) / rowHeight;
		listboxHeight = listboxRows * rowHeight + 1;

		commentTop = savepicTop + savepicHeight + 16;
		commentHeight = listboxHeight - savepicHeight - 16;
	}

	override void Drawer()
	{
		if (initialalpha < 1.0)
		{
			screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
			initialalpha = fadealpha;
		}

		screen.Dim((Game.IsSoD() ? 0x000088 : 0x880000), 1.0 * initialalpha, 0, 0, screen.GetWidth(), screen.GetHeight());
		if (Game.IsSoD() && bkg) { screen.DrawTexture(bkg, true, 0, 0, DTA_Fullscreen, 1); }

		int y = Screen.GetHeight() / 2 - 100 * CleanYfac;
		SetYOffsets(y / CleanYfac + yOffset);

		if (controls)
		{
			Vector2 size = TexMan.GetScaledSize(controls);

			screen.DrawTexture(controls, true, screen.GetWidth() / 2 - size.x * CleanXfac / 2, screen.GetHeight() - size.y * CleanyFac, DTA_CleanNoMove, true, DTA_DestWidth, int(size.x * CleanXfac), DTA_DestHeight, int(size.y * CleanYfac), DTA_Alpha, initialalpha);
		}

		Super.Drawer();

		screen.Dim(fadecolor, fadealpha * initialalpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		Super.Ticker();

		if (gametic > 35)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.Type == UIEvent.Type_KeyDown)
		{
			if (Selected != -1 && Selected < manager.SavegameCount())
			{
				switch (ev.KeyChar)
				{
				case UIEvent.Key_F1:
					manager.SetFileInfo(Selected);
					return true;

				case UIEvent.Key_DEL:
					{
						String EndString;
						EndString = String.Format("%s%s%s%s?\n\n%s", Stringtable.Localize("$MNU_DELETESG"), "\c[TrueBlack]'", manager.GetSavegame(Selected).SaveTitle, "'\c[TrueBlack]", Stringtable.Localize("$PRESSYN"));
						StartMessage (EndString, 0);
					}
					return true;
				}
			}
		}
		else if (ev.Type == UIEvent.Type_WheelUp)
		{
			if (TopItem > 0) TopItem--;
			return true;
		}
		else if (ev.Type == UIEvent.Type_WheelDown)
		{
			if (TopItem < manager.SavegameCount() - listboxRows) TopItem++;
			return true;
		}
		return Super.OnUIEvent(ev);
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (!mParentMenu && mkey == MKEY_Back) { S_ChangeMusic(level.music); }

		return Super.MenuEvent(mkey, fromcontroller);
	}
}

class ExtendedSaveMenu : SaveMenu
{
	TextureID controls, bkg;
	double yoffset;

	int fadetarget;
	int fadetime;
	double fadealpha;
	int fadecolor;

	double initialalpha;

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		yoffset = desc.mYpos;

		SetYOffsets(yoffset);

		controls = TexMan.CheckForTexture((Game.IsSoD() ? "M_SCNTRL" : "M_CNTRLS"), TexMan.Type_Any);
		bkg = TexMan.CheckForTexture("MENUBLUE", TexMan.Type_Any);

		fadetime = 12;
		fadetarget = gametic;
		fadealpha = 1.0;
		fadecolor = (Game.IsSoD() ? 0x000088 : 0x880000);
		
		S_ChangeMusic("WONDERIN");
	}

	void SetYOffsets(double yoffset)
	{
		savepicTop = int(yoffset * CleanYfac);

		listboxTop = savepicTop;
		int listboxHeight1 = screen.GetHeight() - listboxTop - 10 * CleanYfac;
		listboxRows = (listboxHeight1 - 1) / rowHeight;
		listboxHeight = listboxRows * rowHeight + 1;

		commentTop = savepicTop + savepicHeight + 16;
		commentHeight = listboxHeight - savepicHeight - 16;
	}

	override void Drawer()
	{
		if (initialalpha < 1.0)
		{
			screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
			initialalpha = fadealpha;
		}

		screen.Dim((Game.IsSoD() ? 0x000088 : 0x880000), 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());
		if (Game.IsSoD() && bkg) { screen.DrawTexture(bkg, true, 0, 0, DTA_Fullscreen, 1); }

		int y = Screen.GetHeight() / 2 - 100 * CleanYfac;
		SetYOffsets(y / CleanYfac + yOffset);

		if (controls)
		{
			Vector2 size = TexMan.GetScaledSize(controls);

			screen.DrawTexture(controls, true, screen.GetWidth() / 2 - size.x * CleanXfac / 2, screen.GetHeight() - size.y * CleanyFac, DTA_CleanNoMove, true, DTA_DestWidth, int(size.x * CleanXfac), DTA_DestHeight, int(size.y * CleanYfac), DTA_Alpha, initialalpha);
		}

		Super.Drawer();

		screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		Super.Ticker();

		if (gametic > 35)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.Type == UIEvent.Type_KeyDown)
		{
			if (Selected != -1 && Selected < manager.SavegameCount())
			{
				switch (ev.KeyChar)
				{
				case UIEvent.Key_F1:
					manager.SetFileInfo(Selected);
					return true;

				case UIEvent.Key_DEL:
					{
						String EndString;
						EndString = String.Format("%s%s%s%s?\n\n%s", Stringtable.Localize("$MNU_DELETESG"), "\c[TrueBlack]'", manager.GetSavegame(Selected).SaveTitle, "'\c[TrueBlack]", Stringtable.Localize("$PRESSYN"));
						StartMessage (EndString, 0);
					}
					return true;
				}
			}
		}
		else if (ev.Type == UIEvent.Type_WheelUp)
		{
			if (TopItem > 0) TopItem--;
			return true;
		}
		else if (ev.Type == UIEvent.Type_WheelDown)
		{
			if (TopItem < manager.SavegameCount() - listboxRows) TopItem++;
			return true;
		}
		return Super.OnUIEvent(ev);
	}
	
	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (Super.MenuEvent(mkey, fromcontroller))
		{
			if (mkey == MKEY_Back && !mParentMenu) { S_ChangeMusic(level.music); }
			return true;
		}

		if (mkey == MKEY_Input) { S_ChangeMusic(level.music); }
		return false;
	}
}

class ExtendedPlayerMenu : PlayerMenu
{
	int fadetarget;
	int fadetime;
	double fadealpha;
	int fadecolor;

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		fadetime = 12;
		fadetarget = gametic;
		fadealpha = 1.0;
		fadecolor = (Game.IsSoD() ? 0x000088 : 0x880000);
	}

	override void Drawer()
	{
		screen.Dim((Game.IsSoD() ? 0x000088 : 0x880000), 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

		ListMenu.Drawer();

		screen.Dim(fadecolor, fadealpha, 0, 0, screen.GetWidth(), screen.GetHeight());
	}

	override void Ticker()
	{
		Super.Ticker();

		if (gametic > 35)
		{
			fadealpha = 1.0 - abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}
	}
}

class ListMenuItemBox : ListMenuItem
{
	int x, y, w, h, yoffset, inputw, inputh;

	void Init(ListMenuDescriptor desc, int width, int height, int offset)
	{
		Super.Init(desc.mXpos, desc.mYpos);

		inputw = width;
		inputh = height;
		yoffset = offset;
	}
	
	override void Drawer(bool selected)
	{
		w = int(inputw * CleanXfac);
		h = int(inputh * CleanYfac);
		x = Screen.GetWidth() / 2 - w / 2;
		y = Screen.GetHeight() / 2 - 103 * CleanYfac + int((mYpos + yoffset) * CleanYfac);

		color clrt = 0x700000;
		color clrb = 0xD40000;

		if (g_sod < 0)
		{
			clrt = 0x0F0F0F;
			clrb = 0x5C5C5C;
			screen.Dim(0x282828, 1.0, x, y, w, h);
		}
		else if (Game.IsSoD())
		{
			// HACK: SoD has no "Read This" entry, so adjust box height for main menu
			Menu current = Menu.GetCurrentMenu();
			if (
				(
					ListMenu(current) &&
					ListMenu(current).mDesc.mMenuName == "Mainmenu"
				) || 
				(
					current is "MessageBoxMenu" &&
					ListMenu(current.mParentMenu) && 
					ListMenu(current.mParentMenu).mDesc.mMenuName == "Mainmenu"
				)
			) { h -= 13 * CleanYfac; }

			clrt = 0x000070;
			clrb = 0x0000D4;
			screen.Dim(0x000088, 1.0, x, y, w, h);
		}

		screen.Dim(0x000000, 0.35, x, y, w, h);

		int t = int(CleanYfac);
		screen.DrawThickLine(x - t, y - t / 2, x + w, y - t / 2, t, clrt);
		screen.DrawThickLine(x - t / 2, y, x - t / 2, y + h, t, clrt);
		screen.DrawThickLine(x - t, y + h + t / 2, x + w + t, y + h + t / 2, t, clrb);
		screen.DrawThickLine(x + w + t / 2, y - t, x + w + t / 2, y + h, t, clrb);
	}
}

class ListMenuItemTopStrip : ListMenuItem
{
	int yoffset;

	void Init(ListMenuDescriptor desc, int offset)
	{
		Super.Init();

		yoffset = offset;
	}

	override void Drawer(bool selected)
	{
		int y = Screen.GetHeight() / 2 - 100 * CleanYfac + int((yOffset + mYpos) * CleanYfac);

		screen.Dim(0x000000, 1.0, 0, y, screen.GetWidth(), int(22 * CleanYfac));
		screen.Dim(0x000000, 0.3, 0, y + int(22 * CleanYfac), screen.GetWidth(), int(1 * CleanYfac));
		screen.Dim(0x000000, 1.0, 0, y + int(23 * CleanYfac), screen.GetWidth(), int(1 * CleanYfac));
	}
}

class ListMenuItemStripTitle : ListMenuItemStaticPatch
{
	double xoffset, yoffset;
	String patchname;

	void Init(ListMenuDescriptor desc, double x_offs, double y_offs, String patch)
	{
		xoffset = x_offs;
		yoffset = y_offs;

		patchname = patch;

		Super.Init(desc, xoffset, yoffset, TexMan.CheckForTexture(patchname, TexMan.Type_Any), true);
	}

	override void Draw(bool selected, ListMenuDescriptor desc)
	{
		String patch = patchname;
		if (Game.IsSoD())
		{
			patch = patch.left(2) .. "S" .. patch.mid(2);
			patch = patch.left(8);
		}

		mTexture = TexMan.CheckForTexture(patch, TexMan.Type_Any);

		if (!mTexture.Exists()) { return; }

		Vector2 size = TexMan.GetScaledSize(mTexture);

		int x = (mCentered ? Screen.GetWidth() / 2 : 0) - int(size.x * CleanXfac / 2) + int(xOffset* CleanXfac);
		int y = Screen.GetHeight() / 2 - 100 * CleanYfac + int((yOffset + mYpos) * CleanYfac);

		screen.DrawTexture (mTexture, true, x, y, DTA_CleanNoMove, true);
	}
}

class ListMenuItemTextItemInGame : ListMenuItem
{
	int mHotkey;
	int mHeight;
	int mParam;
	String mText;
	Font mFont;
	int mColor;
	int mColorSelected;
	ListMenuDescriptor descriptor;
	double alpha;

	void Init(ListMenuDescriptor desc, String text, String hotkey, Name child, int param = 0)
	{
		Super.Init(desc.mXpos, desc.mYpos, child);
		mHeight = desc.mLineSpacing;
		mParam = param;
		mText = text;
		mFont = desc.mFont;
		mColor = desc.mFontColor;
		mColorSelected = desc.mFontcolor2;
		mHotkey = hotkey.ByteAt(0);
		descriptor = desc;

		alpha = 1.0;
	}

	override bool CheckCoordinate(int x, int y)
	{
		return mEnabled && y >= mYpos && y < mYpos + mHeight;	// no x check here
	}
	
	override bool Selectable()
	{
		return mEnabled;
	}

	override bool CheckHotkey(int c)
	{ 
		return c > 0 && c == mHotkey;
	}
	
	override bool Activate()
	{
		Menu.SetMenu(mAction, mParam);
		return true;
	}
	
	override bool MouseEvent(int type, int x, int y)
	{
		if (type == Menu.MOUSE_Release)
		{
			let m = Menu.GetCurrentMenu();
			if (m != NULL  && m.MenuEvent(Menu.MKEY_Enter, true))
			{
				return true;
			}
		}
		return false;
	}
	
	override Name, int GetAction()
	{
		return mAction, mParam;
	}

	override void Drawer(bool selected)
	{
		screen.DrawText(mFont, selected ? mColorSelected : mColor, mXpos, mYpos, mText, DTA_Clean, true, DTA_Alpha, alpha);
	}
	
	override int GetWidth()
	{
		return max(1, mFont.StringWidth(StringTable.Localize(mText))); 
	}

	override void OnMenuCreated()
	{
		mEnabled = gamestate == GS_LEVEL;

		AllocateSpace();
	}

	void AllocateSpace()
	{
		int index = 0;
		int lastenabled = 0;

		for (int i = 0; i < descriptor.mItems.Size(); i++)
		{
			if (!index)
			{
				if (descriptor.mItems[i] != self)
				{
					if (descriptor.mItems[i].mEnabled) { lastenabled = i; }
					continue;
				}
				index = i;
			}
			else
			{
				descriptor.mItems[i].mYpos = descriptor.mItems[lastenabled].mYpos + mHeight * (i - index) + mHeight * mEnabled; 
			}
		}
	}
}

class ListMenuItemTextItemNotInGame : ListMenuItemTextItemInGame 
{
	override void OnMenuCreated()
	{
		mEnabled = gamestate != GS_LEVEL;

		AllocateSpace();
	}
}

class ListMenuItemTextNotInGame : ListMenuItemTextItemInGame 
{
	void Init(ListMenuDescriptor desc, String text, int param = 0)
	{
		Super.Init(desc, text, "", 'None', param);
		mHeight = desc.mLineSpacing;
		mParam = param;
		mText = text;
		mFont = desc.mFont;
		mColor = desc.mFontColor;
		mColorSelected = desc.mFontcolor2;
		descriptor = desc;

		alpha = 0.25;
	}

	override void OnMenuCreated()
	{
		mEnabled = gamestate != GS_LEVEL;

		AllocateSpace();
	}

	override bool Selectable()
	{
		return false;
	}
}

class ListMenuItemTextItemInGameSoD : ListMenuItemTextItemInGame
{
	override void OnMenuCreated()
	{
		if (game.IsSoD())
		{
			mEnabled = false;
			AllocateSpace();
			return;
		}

		Super.OnMenuCreated();
	}
}

class ListMenuItemTextItemNotInGameSoD : ListMenuItemTextItemNotInGame
{
	override void OnMenuCreated()
	{
		if (game.IsSoD())
		{
			mEnabled = false;
			AllocateSpace();
			return;
		}

		Super.OnMenuCreated();
	}
}