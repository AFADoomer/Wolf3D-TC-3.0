/*
 * Copyright (c) 2025 AFADoomer
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

class GraphicsHandler : StaticEventHandler
{
	WolfGraphicParser parsedgraphics;
	Array<GraphicDataFile> datafiles;
	Array<String> touchedcanvas;

	override void OnRegister()
	{
		ParseGraphics();
	}

	void ParseGraphics()
	{
		DataHandler handler = DataHandler(StaticEventHandler.Find("DataHandler"));

		// Parse any loaded VSWAP files
		for (int l = 0; l < Wads.GetNumLumps(); l++)
		{
			String lumpname = Wads.GetLumpFullName(l);
			lumpname = lumpname.MakeUpper();
			if (lumpname.IndexOf("VSWAP.") > -1)
			{
				if (developer) { console.printf("Writing graphics from %s...", lumpname); }
				let e = GraphicDataFile.Find(datafiles, lumpname, lumpname);
				WolfGraphicParser.Parse(parsedgraphics, e, touchedcanvas);
			}
		}
	}

	static clearscope bool CheckTouched(String texname)
	{
		if (!texname.length()) { return false; }

		texname = texname.MakeUpper();

		let handler = GraphicsHandler.Get();
		if (!handler) { return false; }

		for (int c = 0; c < handler.touchedcanvas.Size(); c++)
		{
			String current = handler.touchedcanvas[c];
			if (!current.length()) { continue; }

			if (current ~== texname) { return true; }
		}

		return false;
	}

	static clearscope GraphicsHandler Get()
	{
		return GraphicsHandler(StaticEventHandler.Find("GraphicsHandler"));
	}
}

class GraphicPost
{
	int column;
	int start;
	int end;
	Array<Color> data;

	static GraphicPost Create(int column, int start = 0, int end = 63)
	{
		let post = New("GraphicPost");
		post.column = column;
		post.start = start;
		post.end = end;

		return post;
	}
}

class ParsedGraphic
{
	String graphicname;
	GraphicDataFile datafile;
	uint position;
	uint size;
	String data;
	Array<GraphicPost> posts;
	Canvas graphiccanvas;

	void Parse(Array<Color> palette, bool expand = false)
	{
		if (!palette.Size()) { return; }

		if (expand)
		{
			uint readoffset;
			uint firstcolumn, lastcolumn;
			uint instructionoffset;

			[firstcolumn, readoffset] = WolfMapParser.GetLittleEndian(data, readoffset, 2);
			[lastcolumn, readoffset] = WolfMapParser.GetLittleEndian(data, readoffset, 2);

			for (uint c = firstcolumn; c <= lastcolumn; ++c)
			{
				[instructionoffset, readoffset] = WolfMapParser.GetLittleEndian(data, readoffset, 2);

				int start;
				uint bottom, top;
				while (instructionoffset < data.length())
				{
					[bottom, instructionoffset] = WolfMapParser.GetLittleEndian(data, instructionoffset, 2);
					if (bottom == 0) { break; }

					[start, instructionoffset] = WolfMapParser.GetLittleEndian(data, instructionoffset, 2);
					[top, instructionoffset] = WolfMapParser.GetLittleEndian(data, instructionoffset, 2);

					top /= 2;
					bottom /= 2;

					if (start > 0x7FFF) { start = -(0xFFFF - start + 1); } // Convert to signed integer

					let post = GraphicPost.Create(c, top, bottom);
					posts.Push(post);

					for (uint r = top; r < bottom; ++r)
					{
						uint paletteindex = data.ByteAt(start + r);
						post.data.Push(palette[paletteindex]);
					}
				}
			}
		}
		else
		{
			for (uint x = 0; x < 64; x++)
			{
				let post = GraphicPost.Create(x);
				posts.Push(post);

				for (uint y = 0; y < 64; y++)
				{
					int paletteindex = data.ByteAt(x * 64 + y);
					post.data.Push(palette[paletteindex]);
				}
			}
		}
	}
}

class WolfGraphicParser
{
	static void Parse(in out WolfGraphicParser parsedgraphics, in out GraphicDataFile d, in out Array<String> touchedcanvas)
	{
		int graphicslump = -1;

		if (!parsedgraphics) { parsedgraphics = New("WolfGraphicParser"); }
		if (!d) { return; }

		if (d.lump) { graphicslump = d.lump; }
		else { graphicslump = Wads.CheckNumForFullName(d.path); }

		if (graphicslump == -1) { return; }

		d.content = Wads.ReadLump(graphicslump);

		int readoffset = 0;
		[d.chunkcount, readoffset] = WolfMapParser.GetLittleEndian(d.content, readoffset, 2);
		[d.spriteaddress, readoffset] = WolfMapParser.GetLittleEndian(d.content, readoffset, 2);
		[d.soundaddress, readoffset] = WolfMapParser.GetLittleEndian(d.content, readoffset, 2);

		parsedgraphics.ReadGraphics(d, readoffset, touchedcanvas);
	}

	void ReadGraphics(GraphicDataFile d, int readoffset, in out Array<String> touchedcanvas)
	{
		DataHandler handler = DataHandler(StaticEventHandler.Find("DataHandler"));

		String content = d.content;
		String gamename = d.path.Mid(d.path.length() - 3);
		if (gamename ~== "SOD" || gamename ~== "SDM") { gamename = "SD1"; }

		ParsedValue data = handler.GetGraphicMap(gamename);
		if (!data)
		{
			gamename = ParsedMap.GetGameName(max(0, g_sod));
			data = handler.GetGraphicMap(gamename);
		}

		ParsedValue palettepath = data.Find("Palette");
		ParsedValue texturenames = data.Find("Textures");
		ParsedValue spritenames = data.Find("Sprites");

		int wallcount = 0;
		int spritecount = 0;

		int sizereadoffset = readoffset + d.chunkcount * 4;

		Array<Color> palette;

		if (palettepath)
		{
			DataHandler.ParsePalette(FileReader.StripQuotes(palettepath.value), palette);
		}

		for (int a = 0; a < d.soundaddress; a++)
		{
			ParsedGraphic newgraphic = New("ParsedGraphic");
			newgraphic.datafile = d;
			[newgraphic.position, readoffset] = WolfMapParser.GetLittleEndian(content, readoffset, 4);
			[newgraphic.size, sizereadoffset] = WolfMapParser.GetLittleEndian(content, sizereadoffset, 2);

			if (a < d.spriteaddress)
			{
				if (!newgraphic.size) { wallcount++; continue; }

				newgraphic.data = content.Mid(newgraphic.position, newgraphic.size);

				newgraphic.Parse(palette);

				if (a < texturenames.children.Size())
				{
					ParsedValue texture = texturenames.children[a];
					if (texture.children.Size())
					{
						newgraphic.graphicname = FileReader.StripQuotes(texture.children[0].keyname);
						for (int t = 0; t < texture.children.Size(); t++)
						{
							bool flip = false;
							if (texture.children[t].children.Size())
							{
								for (int p = 0; p < texture.children[t].children.Size(); p++)
								{
									if (texture.children[t].children[p].keyname ~== "Flip") { flip = true; }
								}
							}

							String canvasname = FileReader.StripQuotes(texture.children[t].keyname);
							CreateGraphic(newgraphic, canvasname, flip);

							touchedcanvas.push(canvasname);
						}
					}
					else
					{
						newgraphic.graphicname = FileReader.StripQuotes(texturenames.children[a].keyname);
						CreateGraphic(newgraphic);

						touchedcanvas.push(newgraphic.graphicname);
					}
				}
				else
				{
					newgraphic.graphicname = String.Format("Patches/Walls/WALL%i%03i.png", 0, a);
					CreateGraphic(newgraphic);

					touchedcanvas.push(newgraphic.graphicname);
				}

				wallcount++;

				d.graphics.Push(newgraphic);
			}
			else if (a < d.soundaddress)
			{
				if (!newgraphic.size) { spritecount++; continue; }

				newgraphic.data = content.Mid(newgraphic.position, newgraphic.size);

				Canvas graphic;

				if (spritenames && a - wallcount < spritenames.children.Size())
				{
					newgraphic.graphicname = FileReader.StripQuotes(spritenames.children[a - wallcount].keyname);
					newgraphic.Parse(palette, true);
					graphic = CreateGraphic(newgraphic, newgraphic.graphicname, true, true);
				}
				else
				{
					newgraphic.graphicname = String.Format("WSPR%04i", a - wallcount);
					newgraphic.Parse(palette, true);
					graphic = CreateGraphic(newgraphic, newgraphic.graphicname, true, true);
				}
				spritecount++;

				d.graphics.Push(newgraphic);
			}
		}
	}

	static void DumpGraphicToConsole(ParsedGraphic graphic, bool halt = false)
	{
		Color data[64][64];
		for (int x = 0; x < 64; x++) { for (int y = 0; y < 64; y++) { data[x][y] = Color(152, 0, 136); } }

		for (int p = 0; p < graphic.posts.Size(); p++)
		{
			let post = graphic.posts[p];
			int y = post.start;
			for (int d = 0; d < post.data.Size(); d++)
			{
				data[post.column][y++] = post.data[d];
			}
		}

		String row;
		for (int r = 0; r < 64; r++)
		{
			for (int c = 0; c < 64; c++)
			{
				int index = c * 64 + r;
				Color colorindex = data[c][r];
				if (colorindex == Color(152, 0, 136)) { row.AppendFormat(" "); }
				else { row.AppendFormat("\c%s%s", ZScriptTools.BestTextColor(data[c][r]), "█"); }
			}

			console.printf(row);
			row = "";
		}

		if (halt) { ThrowAbortException("Halting..."); }
	}

	static Canvas CreateGraphic(ParsedGraphic graphic, String canvasname = "", bool flip = false, bool transparent = false)
	{
		if (canvasname == "") { canvasname = graphic.graphicname; }

		Canvas currentcanvas = TexMan.GetCanvas(canvasname, TexMan.Type_Any);
		if (!currentcanvas)
		{
			if (developer && canvasname.length()) { console.printf("Missing canvas for '%s'", canvasname); }
			return null;
		}

		currentcanvas.Dim(0x0, 0.0, 0, 0, 64, 64, overwritealpha:true);

		TextureID overlay;
		if (transparent)
		{
			overlay = TexMan.CheckForTexture("Materials/Shadows/" .. graphic.graphicname .. ".png", TexMan.Type_Any);
			if (overlay.IsValid())
			{
				currentcanvas.EnableStencil(true);
				currentcanvas.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
				currentcanvas.DrawTexture(overlay, false, 0, 0, DTA_FlipY, flip);
				currentcanvas.SetStencil(0, SOP_Keep, SF_AllOn);
			}
		}

		if (canvasname ~== "POB3A0" && false)
		{
			TextureID tex = TexMan.CheckForTexture("Sprites/Items/AARDA0.png", TexMan.Type_Any);
			currentcanvas.DrawTexture(tex, false, 0, 0, DTA_FlipY, flip, DTA_TopOffset, 0, DTA_LeftOffset, 0);
		}
		else
		{
			for (int p = 0; p < graphic.posts.Size(); p++)
			{
				let post = graphic.posts[p];
				int y = post.start;
				for (int d = 0; d < post.data.Size(); d++)
				{
					currentcanvas.Dim(post.data[d], 1.0, post.column, flip ? 63 - y++ : y++, 1, 1, overwritealpha:true);
				}
			}
		}

		if (g_debugvswaptextures)
		{
			Font fnt = Font.GetFont("MiniFont");

			Array<String> lines;
			graphic.graphicname.Split(lines, "/");

			for (int l = 0; l < lines.Size(); l++)
			{
				String line = l == lines.Size() - 1 ? lines[l] : lines[l] .. "/";
				currentcanvas.DrawText(fnt, Font.FindFontColor("TrueBlack"), 2, flip ? 62 - 8 * (l + 1) : 8 * l + 1, line, DTA_FlipY, flip);
				currentcanvas.DrawText(fnt, -1, 1, flip ? 63 - 8 * (l + 1) : 8 * l, line, DTA_FlipY, flip);
			}
		}

		if (transparent && overlay.IsValid())
		{
			currentcanvas.SetStencil(1, SOP_Keep, SF_AllOn);
			CVar dynlights = CVar.GetCVar("g_dynamiclights", players[consoleplayer]);
			for (int p = 0; p < graphic.posts.Size(); p++)
			{
				let post = graphic.posts[p];
				int y = post.start;
				for (int d = 0; d < post.data.Size(); d++)
				{
					Color clr = post.data[d];
					double alpha = 2 * (110 - clr.r) / 255.0;
					if (alpha > 0)
					{
						alpha = clamp(alpha, 0.0, 1.0);
						currentcanvas.Dim(0x0, alpha, post.column, flip ? 63 - y++ : y++, 1, 1, overwritealpha:true);
					}
					else if (alpha < 0)
					{
						if (dynlights && !dynlights.GetInt())
						{
							int r = int(145 + clr.r * clr.r / 255.0 * 2);
							int g = int(145 + clr.g * clr.b / 255.0 * 2);
							int b = int(145 + clr.g * clr.b / 255.0 * 2);
							clr = Color(r, g, b);
							currentcanvas.Dim(0xD0D0D0, -alpha * 0.85, post.column, flip ? 63 - y++ : y++, 1, 1, overwritealpha:true);
						}
					}
				}
			}

			currentcanvas.EnableStencil(false);
			currentcanvas.ClearStencil();
		}

		return currentcanvas;
	}

	static int, int GetLittleEndian(String input, int offset = 0, int count = 2)
	{
		int ret = 0;

		for (int b = count - 1; b >= 0; b--)
		{
			ret += int((0x100 ** b) * input.ByteAt(offset + b));
		}

		return ret, offset + count;
	}
}

class GraphicDataFile
{
	String gametitle;
	String path;
	String content;
	int lump;
	int chunkcount;
	int spriteaddress;
	int soundaddress;
	Array<ParsedGraphic> graphics;

	static GraphicDataFile Find(in out Array<GraphicDataFile> datafiles, String title, String path)
	{
		for (int i = 0; i < datafiles.Size(); i++)
		{
			if (datafiles[i].gametitle == title)
			{
				return datafiles[i];
			}
		}

		let d = New("GraphicDataFile");

		d.path = path;
		d.lump = Wads.CheckNumForFullName(path);

		if (!d.gametitle.length()) { d.gametitle = path; }

		datafiles.Push(d);

		return d;
	}
}