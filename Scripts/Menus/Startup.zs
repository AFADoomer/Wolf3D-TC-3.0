
class Startup : GenericMenu
{
	int ticcount;

	override void Init(Menu parent)
	{
		S_ChangeMusic("");

		Super.Init(parent);
	}

	override void Ticker()
	{
		ticcount++;

		Super.Ticker();
	}

	override void Drawer()
	{
		screen.Dim(0, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

	}	
}
/*
class DOSItem
{
	String title;
	String extension;
	int size;
	String date;
	Array<DOSItem> children;
	DOSItem parent;
	int lump;
}

class Startup : GenericMenu
{
	Font DOSFont;
	Vector2 dimcoords, dimsize;

	String buffer[26][80];
	String backgroundbuffer[26][80];
	String cursorbuffer[26][80];
	String command;
	String path, prompt;
	String FColor;
	String BColor;

	int cursorx, cursory, prompty;

	int ticcount, curstate, cursortimeout, typestart;

	bool SoDMenu;

	Array<String> history;
	int historyindex;

	DOSItem curdir;
	DOSItem root;

	static const String DOSColors[] = { "TrueBlack", "DOSBlue", "DOSGreen", "DOSCyan", "DOSRed", "DOSMagenta", "DOSBrown", "DOSWhite", "DOSGray", "DOSLightBlue", "DOSLightGreen", "DOSLightCyan", "DOSLightRed", "DOSLightMagenta", "DOSYellow", "TrueWhite" };
	bool echo;

	int instances;

	bool noinput;

	override void Init(Menu parent)
	{
		S_ChangeMusic("");

		Super.Init(parent);

		DontDim = true;

		DOSFont = Font.GetFont("DOSFont");

		[dimcoords, dimsize] = screen.VirtualToRealCoords((0, 0), (320, 200), (320, 200));

		curstate = 0;
		ticcount = 0;

		FColor = "White";
		BColor = "TrueBlack";

		root = New("DOSItem");

		curdir = NewNode(root, "C:", "", 134217728);
		NewNode(curdir, "COMMAND", "COM", 47845, "11-11-1991   5:00a");
		DOSItem data = NewNode(curdir, "DATADIR");
		curdir = NewNode(curdir, "GAMES");
		curdir = NewNode(curdir, "WOLF3D");
		NewNode(curdir, "AUDIOHED", "WL6", 1156, "02-04-1993   4:01p");
		NewNode(curdir, "AUDIOT", "WL6", 320209, "02-04-1993   4:01p");
		NewNode(curdir, "GAMEMAPS", "WL6", 150652, "02-04-1993   3:54p");
		NewNode(curdir, "MAPHEAD", "WL6", 402, "02-04-1993   3:54p");
		NewNode(curdir, "VGADICT", "WL6", 1024, "02-04-1993   1:40p");
		NewNode(curdir, "VGAGRAPH", "WL6", 334506, "02-04-1993   1:40p");
		NewNode(curdir, "VGAHEAD", "WL6", 486, "02-04-1993   1:40p");
		NewNode(curdir, "VSWAP", "WL6", 1545400, "02-04-1993   4:02p");
		NewNode(curdir, "WOLF3D", "EXE", 110715, "02-04-1993   1:40p");

		for (int i = 0, count = Wads.GetNumLumps(); i < count; ++i)
		{
			String nm = Wads.GetLumpFullName(i);

			if (nm != "" && nm.IndexOf("/") > -1 && Wads.FindLump(Wads.GetLumpName(i)))
			{
				NewNodeFromPath(data, Wads.GetLumpFullName(i), lump:i);
			}
		}

		curdir = FindPath("C:\\Games\\Wolf3D");

		echo = true;
		prompt = String.Format("%s>", GetPath(curdir));

		Clear();

		Print(prompt, nobreak:true);
sodmenu = true;
	}

	override void Ticker()
	{
//		Boot();
		ticcount++;

		Super.Ticker();
	}

	override void Drawer()
	{
		screen.Dim(0, 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

		if (sodmenu) { DrawSoDMenu(); }
		else
		{
			DrawBuffer();

			DrawCursor();
		}
	}

	void Clear()
	{
		for (int r = 0; r < 25; r++)
		{
			for (int c = 0; c < 80; c++)
			{
				buffer[r][c] = "";
				backgroundbuffer[r][c] = "\c[" .. BColor .. "]�";
			}
		}

		cursorx = 0;
		cursory = 0;
	}


	void ClearLine(int linenum = -1, int startcol = -1)
	{
		if (linenum < 0) { linenum = cursory; }
		if (startcol < 0) { startcol = cursorx; }

		for (int c = startcol; c < 80; c++)
		{
			buffer[linenum][c] = "";
			backgroundbuffer[linenum][c] = "\c[" .. BColor .. "]�";
		}
	}

	void Print(String text = "", int x = -1, int y = -1, bool nobreak = false)
	{
		bool ins = true;

		if (x > -1 && x != cursorx || y > -1 && y != cursory) { ins = false; }

		if (x > -1) { cursorx = x; }
		if (y > -1) { cursory = y; }

		for (int i = 0; i < text.Length(); i++)
		{
			if (text.Mid(i, 1) == "\n" || cursorx > 79)
			{
				text = text.Mid(i);
				i = 0;

				NewLine();
			}

			if (ins) { Insert(); }
			backgroundbuffer[cursory][cursorx] = "\c[" .. BColor .. "]�";
			buffer[cursory][cursorx] = "\c[" .. FColor .. "]" .. text.Mid(i, 1);

			cursorx++;
		}

		if (!nobreak) { NewLine(); }
	}

	void DrawBuffer(int width = 640, int height = 400, int charwidth = 8, int lineheight = 16)
	{
		charwidth = charwidth * width / 640;
		lineheight = lineheight * height / 400;

		int xoffset = width / 4;
		int yoffset = height / 4;
		width += xoffset * 2;
		height += yoffset * 2;

		double cratio = Screen.GetHeight() / height;
		int cwidth = int(charwidth * cratio);
		int cheight = int(lineheight * cratio);

		for (int r = 0; r < 25; r++)
		{
			for (int c = 0; c < 80; c++)
			{
				if (!(backgroundbuffer[r][c] ~== "\c[TrueBlack]�"))
				{
					screen.DrawText(DOSFont, Font.FindFontColor("TrueBlack"), xoffset + c * charwidth - 1, yoffset + r * lineheight - 2, backgroundbuffer[r][c], DTA_VirtualWidth, width, DTA_VirtualHeight, height, DTA_CellX, cwidth + int(2 * cratio), DTA_CellY, int(cheight + 5 * cratio));
				}
				screen.DrawText(DOSFont, Font.FindFontColor("White"), xoffset + c * charwidth, yoffset + r * lineheight, buffer[r][c], DTA_VirtualWidth, width, DTA_VirtualHeight, height, DTA_CellX, cwidth, DTA_CellY, cheight);
				screen.DrawText(DOSFont, Font.FindFontColor("White"), xoffset + c * charwidth, yoffset + r * lineheight, cursorbuffer[r][c], DTA_VirtualWidth, width, DTA_VirtualHeight, height, DTA_CellX, cwidth, DTA_CellY, cheight);
			}
		}
	}

	void NewLine(int amt = 1)
	{
		cursorx = 0;
		cursory++;

		for (int h = cursory; h < 25; h++)
		{
			for (int w = cursorx; w < 80; w++)
			{
				backgroundbuffer[h][w] = "\c[" .. BColor .. "]�";
			}
		}

		if (cursory > 24)
		{
			amt = max(amt, cursory - 24);

			for (int r = 0; r < 25; r++)
			{
				for (int c = 0; c < 80; c++)
				{	
					backgroundbuffer[r][c] = backgroundbuffer[r + amt][c];
					buffer[r][c] = buffer[r + amt][c];
					cursorbuffer[r][c] = cursorbuffer[r + amt][c];
				}
			}

			for (int r = 0; r < amt; r++)
			{
				for (int c = 0; c < 80; c++)
				{
					backgroundbuffer[25 - amt][c] = "\c[" .. BColor .. "]�";
					buffer[25 - amt][c] = "";
					cursorbuffer[25 - amt][c] = "";
				}
			}

			cursory--;
		}

		if (echo) { prompt = String.Format("%s>", GetPath(curdir)); }
	}

	void Delete()
	{
		for (int r = cursory; r < 25; r++)
		{
			for (int c = 0; c < 79; c++)
			{	
				if (r == cursory && c >= cursorx || r > cursory)
				{
					backgroundbuffer[r][c] = backgroundbuffer[r][c + 1];
					buffer[r][c] = buffer[r][c + 1];
				}
			}
			backgroundbuffer[r][79] = "\c[" .. BColor .. "]�";
			buffer[r][79] = "";
		}

		command = command.Left(cursorx - prompt.Length()) .. command.Mid(cursorx - prompt.Length() + 1);
	}

	void Insert()
	{
		for (int r = cursory; r < 25; r++)
		{
			for (int c = 78; c > 0; c--)
			{	
				if (r == cursory && c >= cursorx || r > cursory)
				{
					backgroundbuffer[r][c + 1] = backgroundbuffer[r][c];
					buffer[r][c + 1] = buffer[r][c];
				}
			}
		}
	}

	void DrawCursor()
	{
		for (int r = 0; r < 25; r++)
		{
			for (int c = 0; c < 80; c++)
			{
				if (c == cursorx && r ==cursory) { cursorbuffer[cursory][cursorx] = (cursortimeout || gametic % 30 < 15) ? "\c[" .. FColor .. "]_" : ""; }
				else { cursorbuffer[r][c] = ""; }
			}
		}
		cursortimeout = max(0, cursortimeout - 1);
	}

	void DrawSoDMenu()
	{
		Clear();

		screen.Dim(0x0000AA, 1.0, int(dimcoords.x), int(dimcoords.y), int(dimsize.x), int(dimsize.y));

		DrawTextSpan(15, 3, 48, 1, "�", clr:Font.FindFontColor("StartupBlue"));
		DrawTextSpan(15, 4, 1, 13, "�", clr:Font.FindFontColor("StartupBlue"));
		DrawTextSpan(62, 4, 1, 13, "�", clr:Font.FindFontColor("StartupBlue"));
		DrawTextSpan(15, 17, 48, 1, "�", clr:Font.FindFontColor("StartupBlue"));

		DrawText(20, 6, "1 - Spear of Destiny (original mission)", clr:Font.FindFontColor("TrueWhite"));
		DrawText(20, 8, "2 - Mission 2: Return to Danger", clr:Font.FindFontColor("TrueWhite"));
		DrawText(20, 10, "3 - Mission 3: Ultimate Challenge", clr:Font.FindFontColor("TrueWhite"));

		DrawText(20, 14, "0 - Exit to DOS", clr:Font.FindFontColor("TrueWhite"));
	}

	void Boot()
	{
		ticcount++;

		switch(curstate)
		{
			case 0:
				noinput = true;

				Print(String.Format("%4i KB OK", clamp((ticcount - 70) * 20, 0, 1024)), 0, 1, true);
				if (ticcount >= 140) { ticcount = 0; curstate++; }
				break;
			case 1:
				Clear();
				curstate++;
				break;
			case 2:
				if (ticcount > 70) { ticcount = 0; curstate++; }
				break;
			case 3:
				Clear();
				curstate++;
				break;
			case 4:
				Print("Starting MS-DOS...", 0, 2);
				NewLine();
				if (ticcount > 70) { ticcount = 0; curstate++; }
				break;
			case 5:
				if (ticcount == 1) { Print(prompt, nobreak:true); prompty = cursory; }
				noinput = false;
			default:
				break;
		}
	}

	void DrawText(int x, int y, String text, Font fnt = null, color clr = Font.CR_GRAY, int width = 640, int height = 400, int charwidth = 8, int lineheight = 16)
	{
		if (!fnt) { fnt = DOSFont; }

		text = StringTable.Localize(text);

		int linecount = 0;

		double cratio = Screen.GetHeight() / height;
		int cwidth = int(charwidth * cratio);
		int cheight = int(lineheight * cratio);

		for (int c = 0; c < text.Length(); c++)
		{
			if (text.Mid(c, 1) == "\n" || x + c > 79)
			{
				text = text.Mid(c);
				c = 0;

				linecount++;
			}

			screen.DrawText(fnt, clr, (x + c - (linecount > 0)) * charwidth, (y + linecount) * lineheight, text.Mid(c, 1), DTA_VirtualWidth, width, DTA_VirtualHeight, height, DTA_CellX, cwidth, DTA_CellY, cheight);
		}
	}

	void DrawTextSpan(int x, int y, int w, int h, String text, Font fnt = null, color clr = Font.CR_GRAY)
	{
		if (!fnt) { fnt = DOSFont; }

		text = StringTable.Localize(text);

		for (int r = y; r < y + h; r++)
		{
			for (int c = x; c < x + w; c++)
			{
				DrawText(c, r, text, fnt, clr);
			}
		}
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.type == UIEvent.Type_KeyDown)
		{
			switch (ev.KeyChar)
			{
				case UIEvent.Key_Del:
					Delete();
					break;
				case UIEvent.Key_Home:
					cursorx = prompt.Length();
					break;
				case UIEvent.Key_End:
					cursorx = prompt.Length() + command.Length();
					break;
				default:
					break;
			}
		}
		else if (ev.type == UIEvent.Type_Char)
		{
			String key = String.Format("%c", ev.KeyChar);

			if (sodmenu)
			{
				if (key == "0")
				{
					sodmenu = false;
					Clear();
					Print(prompt, nobreak:true);
				}
				else
				{
					console.printf("TODO: Option " .. key);
				}
			}
			else if (!noinput)
			{
				command = command.Left(cursorx - prompt.Length()) .. key .. command.Mid(cursorx - prompt.Length());
				Print(key, nobreak:true);
			}
		}

		return false;
	}	

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		switch (mkey)
		{
			case MKEY_ENTER:
				if (command.length())
				{ 
					history.Push(command);
					historyindex = history.Size();
					ParseCommand(command .. "\n");
				}
				else
				{
					NewLine();
				}

				command = "";
				Print(prompt, nobreak:true);
				prompty = cursory;
				break;
			case MKEY_CLEAR:
				if (command.Length())
				{
					cursorx--;
					if (cursorx < 0)
					{
						cursorx = 79;
						cursory--;
					}

					Delete();
				}
				break;
			case MKEY_LEFT:
				if (cursorx > (command.Length() > 80 - prompt.Length() ? 0 : prompt.Length()))
				{
					cursorx--;
					cursorbuffer[cursory][cursorx] = "_";
					cursortimeout = 5;
				}
				break;
			case MKEY_RIGHT:
				int linelength = 0;

				for (int c = 79; c > 0 && !linelength; c--) { if (buffer[cursory][c] != "") { linelength = c + 1; } }

				if (cursorx < linelength)
				{
					cursorx++;
					cursorbuffer[cursory][cursorx] = "_";
					cursortimeout = 5;
				}
				break;
			case MKEY_BACK:
				for (int r = prompty; r < 25; r++)
				{
					for (int c = 0; c < 80; c++)
					{	
						if (r == prompty && c >= prompt.Length() || r > prompty) { buffer[r][c] = ""; }
					}
				}
				command = "";
				cursory = prompty;
				cursorx = prompt.Length();
				break;
			case MKEY_UP:
				historyindex--;
				if (historyindex >= 0)
				{
					command = history[historyindex];
				}
				else
				{
					historyindex = 0;
				}

				ClearLine(-1, prompt.length());
				Print(command, prompt.length(), -1, true);
				break;
			case MKEY_DOWN:
				historyindex++;

				if (historyindex >= history.Size())
				{
					historyindex = history.Size();
					command = "";
				}
				else
				{
					command = history[historyindex];
				}

				ClearLine(-1, prompt.length());
				Print(command, prompt.length(), -1, true);
				break;
			default:
				break;
		}

		return false;
	}

	int HexStrToInt(String input)
	{
		int output;

		input = input.MakeUpper();

		for (int i = 0; i < input.Length(); i++)
		{		
			int index = input.Mid(i, 1).ToInt();

			if (!(input.Mid(i, 1) == "0") && !index)
			{
				index = input.ByteAt(i) - 55;
				if (index > 15) { return -1; }
			}

			if (index < 0) { return -1; }

			int multiplier = 1;
			for (int j = 0; j < input.Length() - i - 1; j++)
			{
				multiplier *= 16;
			}

			output += multiplier * index;
		}

		return output;
	}

	String GetPath(DOSItem item)
	{
		String path;

		if (item.parent == root) { return item.title .. "\x5C"; }

		while (item && item != root)
		{
			if (!path) { path = item.title .. (item.extension.length() ? item.extension : ""); }
			else { path = item.title .. (item.extension.length() ? item.extension : "") .. "\x5C" .. path; }

			item = item.parent;	
		}

		return path;
	}

	String CleanPath(String path)
	{
		for (int c = 0; c < path.Length(); c++)
		{
			if (c == 0 && (path.ByteAt(c) == 0x20 || path.ByteAt(c) == 0x5C))
			{
				path.Remove(c, 1);
				c--;
			}
			else if (path.ByteAt(c) == 0x5C)
			{
				path = path.Left(c) .. "/" .. path.Mid(c + 1);
				c++;
			}
		}

		return path;
	}

	DOSItem, bool FindPath(String path)
	{
		if (!path) { return null; }

		Array<String> tree;

		path = CleanPath(path);

		path.Split(tree, "/");

		bool same = false;
		String node;
		DOSItem curnode = curdir;

		for (int nodeindex = 0; nodeindex < tree.Size(); nodeindex++)
		{
			node = tree[nodeindex];

			if (node.Mid(1, 1) == ":")
			{
				for (int i = 0; i < root.children.Size(); i++)
				{
					if (root.children[i].title ~== node) { curnode = root.children[i]; }
				}
			}
			else if (node == "..")
			{
				if (curnode.parent != root) { curnode = curnode.parent; }
				else { same = true; }
			}
			else if (node == ".")
			{
				same = true;
			}
			else if (node == "")
			{
				while (curnode.parent && curnode.parent != root)
				{
					curnode = curnode.parent;
				}

				return curnode, true;
			}
			else
			{
				int extensionindex = node.RightIndexOf(".");
				String nodeextension = (extensionindex > -1 ? node.mid(extensionindex + 1) : "");
				String nodetitle = node.left(extensionindex);

				for (int i = 0; i < curnode.children.Size(); i++)
				{
					if (curnode.children[i].title ~== nodetitle && curnode.children[i].extension ~== nodeextension && curnode.children[i].children.Size()) { curnode = curnode.children[i]; }
				}
			}
		}

		return curnode, same;	
	}

	void ParseCommand(String command)
	{
		Array<string> tokens;

		for (int c = 0; c < command.length(); c++)
		{
			if (c == 0 && command.Mid(c, 1) == "@")
			{
				command = command.Mid(c + 1);
				c = 0;
			}
			else if (command.Mid(c, 1) == "-" || command.Mid(c, 1) == "/")
			{
				tokens.Push(command.Left(c));
				command = command.Mid(c);
				c = 1;
			}
			else if (command.Mid(c, 1) == "\x5C")
			{
				tokens.Push(command.Left(c));
				tokens.Push("\x5C");
				command = command.Mid(c + 1);

				c = 0;
			}
			else if (command.Mid(c, 1) == ".")
			{
				if (command.Mid(c + 1, 1) == ".")
				{
					tokens.Push(command.Left(c));
					tokens.Push("..");
					command = command.Mid(c + 2);
				}
				else
				{
					tokens.Push(command.Left(c));
					tokens.Push(".");
					command = command.Mid(c + 1);
				}

				c = 0;
			}
			else if (command.ByteAt(c) == 0x20 || command.ByteAt(c) == 0x5C || command.Mid(c, 1) == "\n")
			{
				tokens.Push(command.Left(c));
				if (command.ByteAt(c) == 0x5C && c == command.length() - 2) { tokens.Push("\x5C"); }
				command = command.Mid(c + 1);
				c = 0;
			}
		}

		String parameters;
		for (int i = 1; i < tokens.Size(); i++) { parameters = parameters .. (parameters.length() ? " " : "") .. tokens[i]; }

		if (tokens[0].length() == 2 && tokens[0].Mid(1, 1) == ":")
		{
			curdir = FindPath(tokens[0]);
			NewLine();
		}
		else if (tokens[0] ~== "CLS") { Clear(); }
		else if (tokens[0] ~== "EXIT")
		{
			if (instances == 0)
			{
				S_ChangeMusic(level.music);
				Close();
			}
			else
			{
				instances--;
				NewLine();
				NewLine();
			}
		}
		else if (tokens[0] ~== "ECHO")
		{
			NewLine();

			if (tokens.Size() == 1)
			{
				Print("ECHO is " .. (echo ? "ON" : "OFF") .. ".");
				NewLine();
			}
			else if (tokens[1] ~== "ON")
			{
				echo = true;
				Print("ECHO is on.");
				NewLine();
			}
			else if (tokens[1] ~== "OFF")
			{
				echo = false;
				prompt = "";
			}
			else
			{
				Print(parameters);
				NewLine();
			}
		}
		else if (tokens[0] ~== "DEL" || tokens[0] ~== "MKDIR" || tokens[0] ~== "RM" || tokens[0] ~== "MOVE")
		{
			NewLine();
			Print("Access is denied.");
			NewLine();
		}
		else if (tokens[0] ~== "CD" || tokens[0] ~== "CHDIR")
		{
			if (tokens.Size() == 1)
			{
				NewLine();
				Print(GetPath(curdir));
				NewLine();
			}
			else
			{
				String pathto = "";

				for (int i = 1; i < tokens.Size(); i++) { pathto = pathto .. (pathto.length() ? "\x5C" : "") .. tokens[i]; }

				if (pathto == "\x5C") { curdir = root.children[0];}
				else
				{
					DOSItem newpath;
					bool same;

					[newpath, same] = FindPath(pathto);

					if (newpath == curdir && !same)
					{
						NewLine();
						Print("The system could not find the path specified.");
					}
					else
					{
						curdir = newpath;
					}
				}

				NewLine();
			}
		}
		else if (tokens[0] ~== "DIR")
		{
			PrintChildren(curdir, tokens.Size() > 1 ? tokens[1] : "");
			NewLine();
		}
		else if (tokens[0] ~== "COLOR")
		{
			if (tokens.Size() == 1)
			{
				FColor = "White";
				BColor = "TrueBlack";
			}
			else
			{
				int fore = HexStrToInt(tokens[1].Mid(1, 1));
				int back = HexStrToInt(tokens[1].Mid(0, 1));

				if (fore != back)
				{
					if (fore < 0 ) { FColor = "White"; }
					else { FColor = DOSColors[fore]; }
					if (back < 0 ) { BColor = "TrueBlack"; }
					else { BColor = DOSColors[back]; }
				}
			}
			NewLine();
		}
		else if (tokens[0] ~== "VER")
		{
			NewLine();
			NewLine();
			Print("MS-DOS Version 5.00");
			NewLine();
			NewLine();
		}
		else if (tokens[0] ~== "COMMAND")
		{
			NewLine();
			NewLine();
			NewLine();
			Print("Microsoft(R) MS-DOS(R) Version 5.00");
			Print("             (C)Copyright Microsoft Corp 1981-1991.");
			NewLine();
			instances++;
		}
		else if (tokens[0] ~== "TYPE")
		{
			if (tokens.Size() > 1)
			{
				bool found;
				DOSItem item;

				[found, item] = FindChild(tokens[1], tokens.Size() > 3 ? tokens[3] : "");

				NewLine();

				if (found && item.lump > -1)
				{
					Print(Wads.ReadLump(item.lump));
				}
				else
				{
					tokens[1] = tokens[1].MakeUpper();
					Print("File not found - " .. tokens[1] .. (tokens.Size() > 3 ? "." .. tokens[3] : ""));
				}

				NewLine();
			}
			else
			{
				NewLine();
				Print("Required parameter missing");
				NewLine();
			}
		}
		else if (tokens[0] == "")
		{
			NewLine();
		}
		else
		{
			if (!CheckCommand(tokens[0], parameters))
			{
				NewLine();
				Print("Bad command or file name");
				NewLine();
			}
		}
	}

	bool CheckCommand(String cmd, String params)
	{
		for (int c = 0; c < params.Length(); c++)
		{
			if (c == 0 && (params.ByteAt(c) == 0x20 || params.ByteAt(c) == "."))
			{
				params.Remove(c, 1);
				c--;
			}
		}

		if (!FindChild(cmd, params)) { return false; }

		if (cmd ~== "WOLF3D")
		{
			Close();
			SetMenu("IntroSlideShow", -1);
			return true;
		}
		else if (cmd ~== "SOD")
		{
			sodmenu = true;
			return true;
		}

		return false;
	}

	void PrintChildren(DOSItem node, string params = "")
	{
		NewLine();

		if (!node) { return; }

		int dircount = 0;
		int filecount = 0;
		int dirsize = 0;

		DOSItem drive = node;

		while (drive.parent != root) { drive = drive.parent; }

		NewLine();

		Print(String.Format(" Volume in drive %s has no label.", drive.title.mid(0, 1)));
		Print(String.Format(" Volume Serial Number is 0505-923D."));
		Print(String.Format(" Directory of %s", GetPath(node)));

		NewLine();

		if (node.parent != root)
		{
			Print(".               <DIR>            " .. node.date);
			Print("..              <DIR>            " .. node.parent.date);
			dircount = 2;
		}

		for (int i = 0; i < node.children.Size(); i++)
		{
			DOSItem child = node.children[i];

			if (child.title) { child.title = child.title.MakeUpper(); }
			if (child.extension) { child.extension = child.extension.MakeUpper(); }

			if (child.children.Size())
			{
				dircount++;
				Print(String.Format("%-8s %-3s %s %s", child.title, child.extension, "   <DIR>           ", child.date));
			}

			dirsize += child.size;
		}

		for (int i = 0; i < node.children.Size(); i++)
		{
			DOSItem child = node.children[i];

			if (!child.children.Size())
			{
				filecount++;
				Print(String.Format("%-8s %-3s  %18s %s", child.title, child.extension, CommaSeparate(child.size), child.date));
			}

			dirsize += child.size;
		}

		if (filecount) { Print(String.Format("%5i File(s) %18s Bytes.", filecount, CommaSeparate(dirsize))); }
		else { Print(String.Format("               %18s Bytes.", CommaSeparate(dirsize))); }

		if (dircount) { Print(String.Format("%5i Dir(s)  %18s Bytes free.", dircount, CommaSeparate(node.size))); }
		else { Print(String.Format("               %18s Bytes free.", CommaSeparate(node.size))); }
	}

	DOSItem NewNode(DOSItem parent, String title, String extension = "", int size = -1, String date = "", int lump = -1)
	{
		if (!parent) { return null; }

		DOSItem node = New("DOSItem");
		node.parent = parent;
		node.title = title;
		node.extension = extension;
		node.size = size > 0 ? size : Random(1, 999999);
		node.date = GetDate(date);
		node.lump = lump;

		parent.children.Push(node);

		return node;
	}

	DOSItem NewNodeFromPath(DOSItem parent, String path, int size = -1, String date = "", int lump = -1)
	{
		if (!parent) { return null; }

		Array<String> tree;

		path = CleanPath(path);

		path.Split(tree, "/");

		for (int i = 0; i < tree.Size() - 1; i++)
		{
			if (tree[i].length() > 8)
			{
				tree[i] = tree[i].left(6) .. "~1";
			}

			DOSItem node = FindPath(GetPath(parent) .. "\x5C" .. tree[i]);

			while (!(GetPath(node) ~== GetPath(parent) .. "\x5C" .. tree[i]))
			{
				node = NewNodeFromPath(parent, tree[i]);
			}

			parent = node;
		}

		Array<String> file;
		tree[tree.Size() - 1].split(file, ".");

		if (file[0] && file[0].length() > 8)
		{
			int index = 1;

			for (int f = 0; f < parent.children.Size(); f++)
			{
				if (parent.children[f].title.left(6) ~== file[0].left(6)) { index++; }
			}

			file[0] = file[0].left(6) .. "~" .. index;
		}

		DOSItem node = New("DOSItem");
		node.parent = parent;
		node.title = file[0];
		node.extension = (file.Size() > 1 ? file[1] : "");
		node.size = size > 0 ? size : Random(1, 999999);
		node.date = GetDate(date);
		node.lump = lump;

		parent.children.Push(node);

		return node;
	}

	String GetDate(string input = "")
	{
		String temp = String.Format("%02i-%02i-%i  %2i:%02i%s", Random(1, 12), Random(1, 28), Random(1992, 1993), Random(1, 12), Random(0, 59), Random(0, 1) ? "a" : "p");

		return input .. temp.mid(input.length());
	}

	bool, DOSItem FindChild(String title, String extension = "")
	{
		for (int i = 0; i < curdir.children.Size(); i++)
		{
			if (curdir.children[i].children.Size()) { continue; }

			if (curdir.children[i].title ~== title)
			{
				if (extension.Length())
				{
					if (curdir.children[i].extension ~== extension) { return true, curdir.children[i]; }
				}
				else { return true, curdir.children[i]; }
			}
		}

		return false, null;
	}

	String CommaSeparate(int input)
	{
		String output;
		int temp;

		for (int i = input; i > 0; i /= 1000)
		{
			temp = i % 1000;
			output = (i > 1000 ? "," : "") .. temp .. output;
		}

		return output;
	}
}
*/