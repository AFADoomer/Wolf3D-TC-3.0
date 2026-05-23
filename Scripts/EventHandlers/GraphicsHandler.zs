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

	override void OnRegister()
	{
		ParseGraphics();
	}

	void ParseGraphics()
	{
		// Load default graphics
		DataHandler handler = DataHandler(StaticEventHandler.Find("DataHandler"));
		
		for (int g = 0; g < handler.graphicmaps.Size(); g++)
		{
			ParsedValue data = handler.graphicmaps[g];
			if (!data) { continue; }

			ParsedValue texturenames = data.Find("Textures");

			for (int t = 0; t < texturenames.children.Size(); t++)
			{
				ParsedValue texture = texturenames.children[t];
				if (texture.children.Size())
				{
					for (int c = 0; c < texture.children.Size(); c++)
					{
						bool flip = false;
						if (texture.children[c].children.Size())
						{
							for (int p = 0; p < texture.children[c].children.Size(); p++)
							{
								if (texture.children[c].children[p].keyname ~== "Flip") { flip = true; }
							}
						}

						String texname = FileReader.StripQuotes(texture.children[c].keyname);
						String shortname = texname.Mid(texname.RightIndexOf("/") + 1);
						shortname.Replace(".png", "");

						Canvas currentcanvas = TexMan.GetCanvas(texname);
						if (!currentcanvas) { continue; }

						currentcanvas.Clear(0, 0, 64, 64, 0x0, -1);

						TextureID tex = TexMan.CheckForTexture(shortname, TexMan.Type_WallPatch);
						if (tex.IsValid()) { currentcanvas.DrawTexture(tex, true, 0, 0, DTA_FlipX, flip); }
					}
				}
				else
				{
					String texname = FileReader.StripQuotes(texture.keyname);
					String shortname = texname.Mid(texname.RightIndexOf("/") + 1);
					shortname.Replace(".png", "");

					Canvas currentcanvas = TexMan.GetCanvas(texname);
					if (!currentcanvas) { continue; }

					currentcanvas.Clear(0, 0, 64, 64, 0x0, -1);

					TextureID tex = TexMan.CheckForTexture(texname, TexMan.Type_WallPatch);
					if (tex.IsValid()) { currentcanvas.DrawTexture(tex, true, 0, 0); }
				}
			}
		}

		// Parse any loaded VSWAP files
		for (int l = 0; l < Wads.GetNumLumps(); l++)
		{
			String lumpname = Wads.GetLumpFullName(l);
			lumpname = lumpname.MakeUpper();
			if (lumpname.IndexOf("VSWAP.") > -1)
			{
				let e = GraphicDataFile.Find(datafiles, lumpname, lumpname);
				WolfGraphicParser.Parse(parsedgraphics, e);
			}
		}
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

	void Parse(bool expand = false)
	{
		DataHandler handler = DataHandler(StaticEventHandler.Find("DataHandler"));
		
		if (expand)
		{
			int readoffset;
			int firstcolumn, lastcolumn;
			uint instructionoffset;

			[firstcolumn, readoffset] = WolfMapParser.GetLittleEndian(data, readoffset, 2);
			[lastcolumn, readoffset] = WolfMapParser.GetLittleEndian(data, readoffset, 2);

			for (int c = firstcolumn; c <= lastcolumn; ++c)
			{
				[instructionoffset, readoffset] = WolfMapParser.GetLittleEndian(data, readoffset, 2);
				uint linecmds = instructionoffset;

				int start, bottom, top;
				while (linecmds < data.length())
				{
					[bottom, linecmds] = WolfMapParser.GetLittleEndian(data, linecmds, 2);
					if (bottom == 0) { break; }

					[start, linecmds] = WolfMapParser.GetLittleEndian(data, linecmds, 2);
					[top, linecmds] = WolfMapParser.GetLittleEndian(data, linecmds, 2);

					top /= 2;
					bottom /= 2;

					let post = GraphicPost.Create(c, top, bottom);
					posts.Push(post);

					for (int r = top; r < bottom; ++r)
					{
						int paletteindex = data.ByteAt(start + r);
						post.data.Push(handler.palette[paletteindex]);
					}
				}
			}
		}
		else
		{
			for (int x = 0; x < 64; x++)
			{
				let post = GraphicPost.Create(x);
				posts.Push(post);
				
				for (int y = 0; y < 64; y++)
				{
					int paletteindex = data.ByteAt(x * 64 + y);
					post.data.Push(handler.palette[paletteindex]);
				}
			}
		}
	}
}

class WolfGraphicParser
{
	static void Parse(in out WolfGraphicParser parsedgraphics, in out GraphicDataFile d)
	{
		int graphicslump = -1;

		if (!parsedgraphics) { parsedgraphics = New("WolfGraphicParser"); }
		if (!d) { return; }

		if (d.lump) { graphicslump = d.lump; }
		else { graphicslump = Wads.CheckNumForFullName(d.path); }

		if (graphicslump == -1) { return; }

		String game = d.path.Mid(d.path.length() - 3);
		d.content = Wads.ReadLump(graphicslump);

		int readoffset = 0;
		[d.chunkcount, readoffset] = WolfMapParser.GetLittleEndian(d.content, readoffset, 2);
		[d.spriteaddress, readoffset] = WolfMapParser.GetLittleEndian(d.content, readoffset, 2);
		[d.soundaddress, readoffset] = WolfMapParser.GetLittleEndian(d.content, readoffset, 2);

		parsedgraphics.ReadGraphics(d, readoffset);
	}

	void ReadGraphics(GraphicDataFile d, int readoffset)
	{
		DataHandler handler = DataHandler(StaticEventHandler.Find("DataHandler"));

		String content = d.content;
		String gamename = d.path.Mid(d.path.length() - 3);
		if (gamename ~== "SOD") { gamename = "SD1"; }

		ParsedValue data = handler.GetGraphicMap(gamename);
		if (!data)
		{
			gamename = ParsedMap.GetGameName(max(0, g_sod));
			data = handler.GetGraphicMap(gamename);
		}

		ParsedValue texturenames = data.Find("Textures");
		ParsedValue spritenames = data.Find("Sprites");

		int wallcount = 0;
		int spritecount = 0;

		int sizereadoffset = readoffset + d.chunkcount * 4;

		// let spriteoffsets = new("Shape2DTransform");
		// spriteoffsets.Translate((-32, 64));

		for (int a = 0; a < d.soundaddress; a++)
		{
			ParsedGraphic newgraphic = New("ParsedGraphic");
			newgraphic.datafile = d;
			[newgraphic.position, readoffset] = WolfMapParser.GetLittleEndian(content, readoffset, 4);
			[newgraphic.size, sizereadoffset] = WolfMapParser.GetLittleEndian(content, sizereadoffset, 2);

			if (a < d.spriteaddress)
			{
				newgraphic.data = content.Mid(newgraphic.position, newgraphic.size);
				newgraphic.Parse();

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

							CreateGraphic(newgraphic, FileReader.StripQuotes(texture.children[t].keyname), flip);
						}
					}
					else
					{
						newgraphic.graphicname = FileReader.StripQuotes(texturenames.children[a].keyname);
						CreateGraphic(newgraphic);
					}
				}
				else
				{
					newgraphic.graphicname = String.Format("Patches/Walls/WALL%i%03i.png", 0, a);
					CreateGraphic(newgraphic);
				}
				
				wallcount++;

				d.graphics.Push(newgraphic);
			}
			// else if (a < d.soundaddress)
			// {
			// 	newgraphic.data = content.Mid(newgraphic.position, newgraphic.size);
			// 	newgraphic.Parse(true);

			// 	Canvas graphic;
				
			// 	if (spritenames && a - wallcount < spritenames.children.Size())
			// 	{
			// 		newgraphic.graphicname = FileReader.StripQuotes(spritenames.children[a - wallcount].keyname);
			// 		graphic = CreateGraphic(newgraphic, newgraphic.graphicname, true);
			// 	}
			// 	else
			// 	{
			// 		newgraphic.graphicname = String.Format("WSPR%04i", a - wallcount);
			// 		graphic = CreateGraphic(newgraphic, newgraphic.graphicname, true);
			// 	}
			
			// 	graphic.SetTransform(spriteoffsets);

			// 	if (a - wallcount == 3) { DumpGraphicToConsole(newgraphic); }

			// 	spritecount++;

			// 	d.graphics.Push(newgraphic);
			// }
		}
	}

	static void DumpGraphicToConsole(ParsedGraphic graphic)
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
				row.AppendFormat("\c%s%s", ZScriptTools.BestTextColor(data[c][r]), "██");
			}
			
			console.printf(row);
			row = "";
		}
	}

	static Canvas CreateGraphic(ParsedGraphic graphic, String canvasname = "", bool flip = false)
	{
		if (canvasname == "") { canvasname = graphic.graphicname; }

		Canvas currentcanvas = TexMan.GetCanvas(canvasname);
		if (!currentcanvas) { return null; }

		String typename = "graphic"; 
		if (currentcanvas)
		{
			currentcanvas.Clear(0, 0, 64, 64, 0x0, -1);
			currentcanvas.Dim(Color(152, 0, 136), 1.0, 0, 0, 64, 64);

			for (int p = 0; p < graphic.posts.Size(); p++)
			{
				let post = graphic.posts[p];
				int y = post.start;
				for (int d = 0; d < post.data.Size(); d++)
				{
					currentcanvas.Dim(post.data[d], 1.0, post.column, flip ? 63 - y++ : y++, 1, 1);
				}
			}

			if (developer) { console.printf("Writing %s: %s (offset 0x%x, size %d)", typename, canvasname, graphic.position, graphic.size); }

			return currentcanvas;
		}

		console.printf("\c[Yellow]Unable to write %s: %s (offset 0x%x, size %d)!", typename, canvasname, graphic.position, graphic.size);

		return null;
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