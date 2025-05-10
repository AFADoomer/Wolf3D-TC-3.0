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
	Color palette[256];

	override void NewGame()
	{
		ParsePalette();
		ParseGraphics();
	}

	void ParsePalette()
	{
		int lump = Wads.CheckNumForFullName("Wolf3D.pal");

		if (lump > -1)
		{
			ScriptScanner sc = New("ScriptScanner");

			sc.OpenLumpNum(lump);
			sc.MustGetString();
			sc.MustGetNumber();
			sc.MustGetNumber();

			int colors = min(256, sc.Number);

			for (int i = 0; i < colors; i++)
			{
				sc.MustGetNumber();
				palette[i].r = sc.Number;
				sc.MustGetNumber();
				palette[i].g = sc.Number;
				sc.MustGetNumber();
				palette[i].b = sc.Number;
			}

			sc.Close();
		}
		else
		{
			console.printf("PLAYPAL lump not found!");
		}
	}

	void ParseGraphics()
	{
		for (int l = 0; l < Wads.GetNumLumps(); l++)
		{
			String lumpname = Wads.GetLumpFullName(l);
			String shortlumpname = Wads.GetLumpName(l);
			if (shortlumpname ~== "vswap")
			{
				let e = GraphicDataFile.Find(datafiles, lumpname, lumpname);
				WolfGraphicParser.Parse(parsedgraphics, e);
			}
		}
	}

	// void ParseActorMaps()
	// {
	// 	console.printf("Parsing actor data...");

	// 	actormaps = FileReader.Parse("Data/ActorCodes.txt");
			
	// 	for (int d = 0; d < actormaps.children.Size(); d++)
	// 	{
	// 		let gamedata = actormaps.children[d];
			
	// 		for (int e = 0; e < gamedata.children.Size(); e++)
	// 		{
	// 			let entry = gamedata.children[e];

	// 			String value = entry.value;

	// 			Array<String> values;
	// 			value.split(values, ",");
	// 			if (!values.Size()) { values.Push(value); }
		
	// 			ParsedValue m;
	// 			m = entry.AddKey(true);
	// 			m.keyname = "Class";
	// 			m.value = ZScriptTools.Trim(values[0]);

	// 			m = entry.AddKey(true);
	// 			m.keyname = "Skill";
	// 			if (values.Size() > 1) { m.value = ZScriptTools.Trim(values[1]); }
	// 			else { m.value = "-1"; }
				
	// 			m = entry.AddKey(true);
	// 			m.keyname = "Angle";
	// 			if (values.Size() > 2) { m.value = ZScriptTools.Trim(values[2]); }
	// 			else { m.value = "90"; }

	// 			m = entry.AddKey(true);
	// 			m.keyname = "Patrolling";
	// 			if (values.Size() > 3) { m.value = ZScriptTools.Trim(values[3]); }
	// 			else { m.value = "0"; }

	// 			entry.value = "";
	// 		}
	// 	}
	// }


	static clearscope GraphicsHandler Get()
	{
		return GraphicsHandler(StaticEventHandler.Find("GraphicsHandler"));
	}
}

class ParsedGraphic
{
	String graphicname;
	GraphicDataFile datafile;
	uint position;
	uint size;
	String data;
	Canvas graphiccanvas;
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
		String game = d.path.Mid(d.path.length() - 3);

		ParsedValue data = handler.graphicdata.Find(game);
		if (!data) { data = handler.graphicdata.Find("Default"); }

		ParsedValue texturenames = data.Find("Textures");

		int wallcount = 0;
		int spritecount = 0;

		for (int a = 0; a < d.spriteaddress; a++)
		{
			ParsedGraphic newgraphic = New("ParsedGraphic");
			newgraphic.datafile = d;
			[newgraphic.position, readoffset] = WolfMapParser.GetLittleEndian(content, readoffset, 4);
			newgraphic.size = WolfMapParser.GetLittleEndian(content, readoffset + 4 * d.chunkcount, 2);

			if (a < d.spriteaddress)
			{
				newgraphic.size = 64 * 64;
				newgraphic.data = content.Mid(newgraphic.position, newgraphic.size);

				if (a < texturenames.children.Size())
				{
					ParsedValue texture = texturenames.children[a];
					if (texture.children.Size())
					{
						for (int t = texture.children.Size() - 1; t > -1; t--)
						{
							newgraphic.graphicname = FileReader.StripQuotes(texture.children[t].keyname);

							bool flip = false;
							if (texture.children[t].children.Size())
							{
								for (int p = 0; p < texture.children[t].children.Size(); p++)
								{
									if (texture.children[t].children[p].keyname ~== "Flip") { flip = true; }
								}
							}

							CreateGraphic(newgraphic, newgraphic.graphicname, flip);
						}
					}
					else
					{
						newgraphic.graphicname = FileReader.StripQuotes(texturenames.children[a].keyname);
						CreateGraphic(newgraphic, newgraphic.graphicname);
					}
				}
				else
				{
					newgraphic.graphicname = String.Format("Patches/Walls/WALL%i%03i.png", 0, a);
					CreateGraphic(newgraphic, newgraphic.graphicname);
				}
				wallcount++;
			}
			// else if (a < d.soundaddress)
			// {
			// 	newgraphic.size = 64 * 64;
			// 	newgraphic.data = content.Mid(newgraphic.position, newgraphic.size);
				
			// 	newgraphic.graphicname = String.Format("WSPR%04i", a - wallcount);
			// 	CreateGraphic(newgraphic, newgraphic.graphicname);

			// 	spritecount++;
			// }

			// console.printf("Writing graphic %d: %s %x, %d", a, newgraphic.graphicname, newgraphic.position, newgraphic.size);

			d.graphics.Push(newgraphic);
		}
	}

	static void CreateGraphic(ParsedGraphic graphic, String canvasname, bool flip = false)
	{
		Canvas currentcanvas = TexMan.GetCanvas(canvasname);
		if (currentcanvas)
		{
			for (int y = 0; y < 64; y++)
			{
				for (int x = 0; x < 64; x++)
				{
					int index = y * 64 + x;
					if (index < graphic.data.length())
					{
						GraphicsHandler handler = GraphicsHandler(StaticEventHandler.Find("GraphicsHandler"));
						currentcanvas.Dim(handler.palette[graphic.data.ByteAt(index)], 1.0, flip ? 63 - y : y, x, 1, 1);
					}
				}
			}
		}
		else
		{
			console.printf("Canvas %s not found!", canvasname);
		}
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