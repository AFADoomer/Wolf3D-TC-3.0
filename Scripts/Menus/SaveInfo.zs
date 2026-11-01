// What a save is. The engine's comment only knows the shared "Level" map, and
// nothing outside a save can read inside one, so saves carry this in their title
// after SEPARATOR.
//
// The engine's autosaves name themselves and share one rotation across games.
// They stay for respawning but aren't listed: each game instead keeps its own
// few, made as ordinary saves a moment into a level.
class SaveInfo : StaticEventHandler
{
	const SEPARATOR = "\x1F";
	const KEEPSAVES = 4; // Of each game's autosaves, and of its quicksaves
	const AUTOSAVEDELAY = 35; // Tics into a level, clear of the engine's own autosave

	ui Map<String, String> known; // By file name
	int autosaves; // Levels entered
	ui int autosaveswritten;

	static clearscope SaveInfo Get()
	{
		return SaveInfo(StaticEventHandler.Find("SaveInfo"));
	}

	// game|map|level tics|total tics|level number
	static clearscope String Current()
	{
		MapHandler handler = MapHandler.Get();
		ParsedMap map = handler ? handler.curmap : null;

		String mapname = level.LevelName;
		if (map)
		{
			int len = 0;
			while (len < int(map.mapname.Length()) && map.mapname.ByteAt(len) >= 0x20) { len++; }
			mapname = ZScriptTools.Trim(map.mapname.Left(len));
		}
		mapname.Replace("|", "/");

		return String.Format("%s|%s|%i|%i|%i", handler ? handler.gametitle : "", mapname, level.maptime, level.totaltime, map ? map.mapnum % 100 : 0);
	}

	static void RequestAutosave()
	{
		let this = SaveInfo.Get();
		if (this) { this.autosaves++; }
	}

	override void UiTick()
	{
		if (gamestate != GS_LEVEL || Menu.GetCurrentMenu()) { return; }

		if (autosaveswritten == autosaves || level.maptime < AUTOSAVEDELAY) { return; }
		autosaveswritten = autosaves;

		if (multiplayer || disableautosave >= 2) { return; }

		WriteSave("Autosave");
	}

	// The engine's quicksave goes over whichever save was made last, autosaves
	// included, and asks first. This makes a new one, as with autosaves
	override bool InputProcess(InputEvent e)
	{
		if (e.Type != InputEvent.Type_KeyDown || gamestate != GS_LEVEL || multiplayer) { return false; }

		int key1, key2;
		[key1, key2] = Bindings.GetKeysForCommand("quicksave");
		if (e.KeyScan != key1 && e.KeyScan != key2) { return false; }

		if (players[consoleplayer].health > 0) { WriteSave("Quicksave"); }

		return true;
	}

	// A new save of this game's, in place of its oldest of this kind once it has them all
	ui void WriteSave(String kind)
	{
		MapHandler handler = MapHandler.Get();
		if (!handler || !handler.curmap) { return; }

		SavegameManager manager = SavegameManager.GetManager();
		manager.ReadSaveStrings();
		ReadTitles(manager);

		int count, oldest = -1;
		String oldesttitle;
		for (int s = 0; s < manager.SavegameCount(); s++)
		{
			SaveGameNode node = manager.GetSavegame(s);
			if (!node || IsEngineAutosave(node) || node.SaveTitle.Left(kind.Length()) != kind) { continue; }
			if (!known.CheckKey(node.Filename) || !(GameOf(known.Get(node.Filename)) ~== handler.gametitle)) { continue; }

			count++;
			if (oldest < 0 || node.SaveTitle < oldesttitle)
			{
				oldest = s;
				oldesttitle = node.SaveTitle;
			}
		}

		String title = Tagged(kind .. " " .. SystemTime.Format("%Y-%m-%d %H:%M:%S", SystemTime.Now()));

		// Row 0 of the list is always the new save, and that needs to exist
		manager.InsertNewSaveNode();
		manager.DoSave(count >= KEEPSAVES ? oldest + 1 : 0, title);
		manager.RemoveNewSaveNode();
	}

	// With this moment's details in place of any it has
	static clearscope String Tagged(String title)
	{
		int at = title.IndexOf(SEPARATOR);

		return (at < 0 ? title : title.Left(at)) .. SEPARATOR .. Current();
	}

	// The engine's own: auto00.zds and so on
	static ui bool IsEngineAutosave(SaveGameNode node)
	{
		String file = node.Filename;
		file = file.Mid(file.RightIndexOf("/") + 1);

		return file.Left(4) ~== "auto";
	}

	// Move each save's details out of its title, where the list would draw them
	ui void ReadTitles(SavegameManager manager)
	{
		for (int s = 0; s < manager.SavegameCount(); s++)
		{
			SaveGameNode node = manager.GetSavegame(s);
			if (!node || !node.Filename.length()) { continue; }

			int at = node.SaveTitle.IndexOf(SEPARATOR);
			if (at < 0) { continue; }

			known.Insert(node.Filename, node.SaveTitle.Mid(at + 1));
			node.SaveTitle = node.SaveTitle.Left(at);
		}
	}

	static clearscope String FormatTime(int tics)
	{
		int seconds = tics / GameTicRate;

		return String.Format("%02i:%02i:%02i", seconds / 3600, (seconds / 60) % 60, seconds % 60);
	}

	static clearscope String GameOf(String info)
	{
		int at = info.IndexOf("|");

		return at < 0 ? "" : info.Left(at);
	}

	static clearscope String MapOf(String info)
	{
		Array<String> parts;
		info.Split(parts, "|");
		if (parts.Size() < 2) { return ""; }

		int number = parts.Size() > 4 ? parts[4].ToInt() : 0;

		return number ? String.Format("Level %i - %s", number, parts[1]) : parts[1];
	}

	static clearscope String Describe(String info)
	{
		Array<String> parts;
		info.Split(parts, "|");
		if (parts.Size() < 4) { return ""; }

		String text = MapOf(info) .. "\n";
		if (parts[0].length()) { text = parts[0] .. "\n" .. text; }

		return text .. "Level time: " .. FormatTime(parts[2].ToInt()) .. "\nTotal time: " .. FormatTime(parts[3].ToInt());
	}
}

mixin class SaveListInfo
{
	const ROWLINES = 2; // Each save has what it is and, under it, its name

	Array<int> rows; // The saves listed: the running or picked game's, or all before one is picked
	int toprow;
	bool filtering;
	bool mixedgames;

	void ReadSaveInfo()
	{
		let store = SaveInfo.Get();
		if (store) { store.ReadTitles(manager); }

		ListSaves();
	}

	// Saves from before these details can't be told apart, so they stay listed
	void ListSaves()
	{
		// The game running, or the one picked in the menus before starting it
		MapHandler handler = MapHandler.Get();
		String game;
		filtering = true;
		if (gamestate == GS_LEVEL && handler && handler.curmap) { game = handler.gametitle; }
		else if (GameExtension.Find(g_modgame)) { game = GameExtension.Find(g_modgame).Title(g_modgame.MakeUpper()); }
		else { filtering = false; }

		let store = SaveInfo.Get();
		rows.Clear();
		mixedgames = false;
		String listed;
		for (int s = 0; s < manager.SavegameCount(); s++)
		{
			SaveGameNode node = manager.GetSavegame(s);
			if (!node || SaveInfo.IsEngineAutosave(node)) { continue; }

			String info = store && store.known.CheckKey(node.Filename) ? store.known.Get(node.Filename) : "";
			if (filtering && info.length() && !(SaveInfo.GameOf(info) ~== game)) { continue; }

			rows.Push(s);

			if (!info.length()) { continue; }
			if (listed.length() && !(SaveInfo.GameOf(info) ~== listed)) { mixedgames = true; }
			listed = SaveInfo.GameOf(info);
		}

		// Whatever was selected may have just been filtered out or deleted
		if (Selected >= 0 && rows.Find(Selected) == rows.Size()) { SelectRow(rows.Size() ? 0 : -1); }
		toprow = clamp(toprow, 0, max(0, rows.Size() - RowsShown()));
	}

	int RowsShown()
	{
		return max(1, listboxRows / ROWLINES);
	}

	void SelectRow(int row)
	{
		Selected = row < 0 ? -1 : rows[row];

		if (row >= 0)
		{
			if (row < toprow) { toprow = row; }
			else if (row >= toprow + RowsShown()) { toprow = row - RowsShown() + 1; }
		}

		manager.UnloadSaveData();
		manager.ExtractSaveData(Selected);
		UpdateSaveComment();
	}

	bool MoveSelection(int mkey)
	{
		if (mkey != MKEY_Up && mkey != MKEY_Down && mkey != MKEY_PageUp && mkey != MKEY_PageDown) { return false; }
		if (rows.Size() < 2) { return true; }

		int row = rows.Find(Selected);
		bool none = row == rows.Size();

		if (mkey == MKEY_Up) { row = none ? toprow : (row + rows.Size() - 1) % rows.Size(); }
		else if (mkey == MKEY_Down) { row = none ? toprow : (row + 1) % rows.Size(); }
		else
		{
			int last = max(0, rows.Size() - RowsShown());
			if (mkey == MKEY_PageDown) { toprow = toprow >= last ? 0 : min(toprow + RowsShown(), last); }
			else { toprow = toprow == 0 ? last : max(toprow - RowsShown(), 0); }
			row = toprow;
		}

		SelectRow(row);

		return true;
	}

	// True if it was over the list
	bool ClickRow(int type, int x, int y)
	{
		if (x < listboxLeft || x >= listboxLeft + listboxWidth || y < listboxTop || y >= listboxTop + listboxHeight) { return false; }

		int row = toprow + (y - listboxTop) / (rowHeight * ROWLINES);
		if (row >= rows.Size())
		{
			Selected = -1;
			return true;
		}

		SelectRow(row);
		if (type == MOUSE_Release) { MenuEvent(MKEY_Enter, true); }

		return true;
	}

	bool ScrollRows(UIEvent ev)
	{
		if (ev.Type == UIEvent.Type_WheelUp) { toprow = max(toprow - 1, 0); return true; }
		if (ev.Type == UIEvent.Type_WheelDown) { toprow = min(toprow + 1, max(0, rows.Size() - RowsShown())); return true; }

		return false;
	}

	// The list is drawn here from rows, so the engine's own loop has nothing to do
	void HideEngineRows()
	{
		TopItem = manager.SavegameCount();
	}

	void DrawSaveRows()
	{
		if (gameaction == ga_loadgame || gameaction == ga_loadgamehidecon || gameaction == ga_savegame) { return; }

		double vwidth = screen.GetWidth() / FontScale;
		double vheight = screen.GetHeight() / FontScale;

		if (!rows.Size())
		{
			if (!manager.SavegameCount()) { return; }

			String text = StringTable.Localize("$MNU_NOFILES");
			int textlen = int(NewConsoleFont.StringWidth(text) * FontScale);
			screen.DrawText(NewConsoleFont, Font.CR_GOLD, (listboxLeft + (listboxWidth - textlen) / 2) / FontScale, (listboxTop + (listboxHeight - rowHeight) / 2) / FontScale, text, DTA_VirtualWidthF, vwidth, DTA_VirtualHeightF, vheight, DTA_KeepRatio, true);
			return;
		}

		let store = SaveInfo.Get();
		for (int i = 0; i < RowsShown() && toprow + i < rows.Size(); i++)
		{
			int s = rows[toprow + i];
			SaveGameNode node = manager.GetSavegame(s);
			if (!node) { continue; }

			int colr = node.bOldVersion ? Font.CR_RED : node.bMissingWads ? Font.CR_YELLOW : s == Selected ? Font.CR_WHITE : Font.CR_TAN;
			int top = listboxTop + rowHeight * ROWLINES * i;
			double y = (top + FontScale) / FontScale; // What it is
			double titley = y + rowHeight / FontScale; // Then its name

			if (s == Selected) { screen.Clear(listboxLeft, top, listboxRight, top + rowHeight * ROWLINES, mEntering ? Color(255, 255, 0, 0) : Color(255, 0, 0, 255)); }

			if (s == Selected && mEntering)
			{
				String typed = mInput.GetText() .. NewConsoleFont.GetCursor();
				int length = int(NewConsoleFont.StringWidth(typed) * FontScale);
				int displacement = min(0, listboxWidth - 2 - length);
				screen.SetClipRect(listboxLeft, top + rowHeight, listboxRight, top + rowHeight * ROWLINES);
				screen.DrawText(NewConsoleFont, Font.CR_WHITE, (listboxLeft + 1 + displacement) / FontScale, titley, typed, DTA_VirtualWidthF, vwidth, DTA_VirtualHeightF, vheight, DTA_KeepRatio, true);
				screen.ClearClipRect();
			}
			else { screen.DrawText(NewConsoleFont, colr, (listboxLeft + 1) / FontScale, titley, FitRow(node.SaveTitle), DTA_VirtualWidthF, vwidth, DTA_VirtualHeightF, vheight, DTA_KeepRatio, true); }

			// The map, and whose it is if the list has more than one game's
			String info = store && store.known.CheckKey(node.Filename) ? store.known.Get(node.Filename) : "";
			if (!info.length()) { continue; }

			String subtitle = SaveInfo.MapOf(info);
			if (mixedgames && SaveInfo.GameOf(info).length()) { subtitle = GameExtension.GetShortTitle(SaveInfo.GameOf(info)) .. " - " .. subtitle; }
			subtitle = FitRow(subtitle);

			screen.DrawText(NewConsoleFont, s == Selected ? Font.CR_GRAY : Font.CR_DARKGRAY, (listboxLeft + 1) / FontScale, y, subtitle, DTA_VirtualWidthF, vwidth, DTA_VirtualHeightF, vheight, DTA_KeepRatio, true);
		}
	}

	// Clipping doesn't reach text drawn to a virtual size
	String FitRow(String text)
	{
		int room = listboxWidth - 4;
		if (NewConsoleFont.StringWidth(text) * FontScale <= room) { return text; }

		while (text.Length() && NewConsoleFont.StringWidth(text .. "...") * FontScale > room) { text.DeleteLastCharacter(); }

		return text .. "...";
	}

	void ShowSaveInfo()
	{
		ListSaves();

		// Nothing listed, so nothing to preview either
		if (!rows.Size())
		{
			manager.UnloadSaveData();
			BrokenSaveComment = NewConsoleFont.BreakLines("", int(commentWidth / FontScale));
			return;
		}

		let store = SaveInfo.Get();
		if (!store) { return; }

		// Until a row is picked the comment is the first one's
		int shown = Selected < 0 ? rows[0] : Selected;
		if (shown >= manager.SavegameCount()) { return; }

		SaveGameNode node = manager.GetSavegame(shown);
		if (!node) { return; }

		String info;
		if (!node.Filename.length()) { info = SaveInfo.Current(); }
		else if (store.known.CheckKey(node.Filename)) { info = store.known.Get(node.Filename); }

		// The menu puts the engine's comment back whenever the selection moves
		String text = SaveInfo.Describe(info);
		if (text.length()) { BrokenSaveComment = NewConsoleFont.BreakLines(text, int(commentWidth / FontScale)); }
	}
}
