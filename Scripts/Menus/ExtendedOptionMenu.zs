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

class ExtendedOptionMenu : GenericOptionMenu
{
	TextureID title, generictitle, bkg;
	TextureID controls;
	TextureID select0, select1;
	TextureID cursor0, cursor1;

	int fadetarget;
	int fadetime;
	int fadecolor;
	int leftedge;

	bool exitmenu;
	int exittimeout;

	bool nodim;

	OptionMenuItem activated;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		String titlestring = mDesc.mTitle;
		if (Game.IsSoD())
		{
			titlestring = titlestring.left(3) .. "S" .. titlestring.mid(3);
			title = TexMan.CheckForTexture(titlestring.Mid(1), TexMan.Type_Any);

			if (!title.IsValid()) { titlestring = titlestring.left(9); }

			bkg = TexMan.CheckForTexture("MENUBLUE", TexMan.Type_Any);
		}

		if (!title.IsValid()) { title = TexMan.CheckForTexture(titlestring.Mid(1), TexMan.Type_Any); }
		generictitle = TexMan.CheckForTexture((Game.IsSoD() ? "M_SCUSTO" : "M_CUSTOM"), TexMan.Type_Any);
		controls = TexMan.CheckForTexture((Game.IsSoD() ? "M_SCNTRL" : "M_CNTRLS"), TexMan.Type_Any);

		select0 = TexMan.CheckForTexture((Game.IsSoD() ? "M_SSELC0" : "M_SELCT0"), TexMan.Type_Any);
		select1 = TexMan.CheckForTexture((Game.IsSoD() ? "M_SSELC1" : "M_SELCT1"), TexMan.Type_Any);

		cursor0 = TexMan.CheckForTexture((Game.IsSoD() ? "M_SSEL1" : "M_SEL1"), TexMan.Type_Any);
		cursor1 = TexMan.CheckForTexture((Game.IsSoD() ? "M_SSEL2" : "M_SEL2"), TexMan.Type_Any);

		if (gamestate != GS_FINALE) { GameHandler.ChangeMusic("WONDERIN"); }

		fadetime = 12;
		fadetarget = gametic;

		if (mParentMenu && !(mParentMenu is "IntroSlideshow")) { fadecolor = (Game.IsSoD() ? 0x000088 : 0x880000); }

		nodim = true;
		DontDim = true;

		columnwidth = -1;
		columnspacing = 16;
		menuprefix = "Wolf";
	}

	override void OnReturn()
	{
		if (!nodim) { fadetarget = gametic; }
		nodim = false;
		fadecolor = 0x880000;
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (g_defaultmenus)
		{
			return OptionMenu.MenuEvent(mkey, fromcontroller);
		}

		if (alpha != 1.0) { return false; }

		int startedAt = mDesc.mSelectedItem;

		switch (mkey)
		{
		case MKEY_Back:
			if (gamestate != GS_FINALE)
			{ 
				fadetarget = gametic + fadetime;
				exitmenu = true;
			}
			return false;
		case MKEY_Up:
			if (mDesc.mSelectedItem == -1)
			{
				mDesc.mSelectedItem = FirstSelectable();
				break;
			}
			do
			{
				--mDesc.mSelectedItem;

				if (mDesc.mScrollPos > 0 &&
					mDesc.mSelectedItem <= mDesc.mScrollTop + mDesc.mScrollPos)
				{
					mDesc.mScrollPos = MAX(mDesc.mSelectedItem - mDesc.mScrollTop - 1, 0);
				}

				if (mDesc.mSelectedItem < 0) 
				{
					// Figure out how many lines of text fit on the menu
					int y = mDesc.mDrawTop;

					int fontheight = (BigFont.GetHeight() + 1) * CleanYfac_1;
							
					int ytop = y + mDesc.mScrollTop * fontheight;
					int lastrow = screen.GetHeight() - fontheight * 2;
					int maxheight = lastrow - ytop;

					int i = 0;
					int totalheight = 0;
					for (i = mDesc.mItems.Size() - 1; i > 0; i--)
					{
						ItemInfo info = MenuHandler.FindItem(mDesc.mItems[i]);
						if (info) { totalheight += info.height; }
						else { totalheight += fontheight; }

						int nextheight = 0;
						if (i > 0)
						{
							ItemInfo nextinfo = MenuHandler.FindItem(mDesc.mItems[i - 1]);
							if (nextinfo) { nextheight = info.height; }
							else { nextheight = fontheight; }
						}

						if (totalheight + nextheight > maxheight) { break; }
					}

					mDesc.mScrollPos = i;
					mDesc.mSelectedItem = mDesc.mItems.Size() - 1;
				}
			}
			while (!mDesc.mItems[mDesc.mSelectedItem].Selectable() && mDesc.mSelectedItem != startedAt);
			break;

		case MKEY_Down:
			if (mDesc.mSelectedItem == -1)
			{
				mDesc.mSelectedItem = FirstSelectable();
				break;
			}
			do
			{
				++mDesc.mSelectedItem;
				if (!source) { source = self; }

				if (source.CanScrollDown && mDesc.mSelectedItem >= source.VisBottom)
				{
					mDesc.mScrollPos++;
					source.VisBottom++;
				}
				if (mDesc.mSelectedItem >= mDesc.mItems.Size()) 
				{
					if (startedAt == -1)
					{
						mDesc.mSelectedItem = -1;
						mDesc.mScrollPos = -1;
						break;
					}
					else
					{
						mDesc.mSelectedItem = 0;
						mDesc.mScrollPos = 0;
					}
				}
			}
			while (!mDesc.mItems[mDesc.mSelectedItem].Selectable() && mDesc.mSelectedItem != startedAt);
			break;

		case MKEY_PageUp:
			if (mDesc.mScrollPos > 0)
			{
				if (!source) { source = self; }
				mDesc.mScrollPos -= source.VisBottom - mDesc.mScrollPos - mDesc.mScrollTop;
				if (mDesc.mScrollPos < 0)
				{
					mDesc.mScrollPos = 0;
				}
				if (mDesc.mSelectedItem != -1)
				{
					mDesc.mSelectedItem = mDesc.mScrollTop + mDesc.mScrollPos + 1;
					while (!mDesc.mItems[mDesc.mSelectedItem].Selectable())
					{
						if (++mDesc.mSelectedItem >= mDesc.mItems.Size())
						{
							mDesc.mSelectedItem = 0;
						}
					}
					if (mDesc.mScrollPos > mDesc.mSelectedItem)
					{
						mDesc.mScrollPos = mDesc.mSelectedItem;
					}
				}
			}
			break;

		case MKEY_PageDown:
			if (!source) { source = self; }
			if (source.CanScrollDown)
			{
				int pagesize = source.VisBottom - mDesc.mScrollPos - mDesc.mScrollTop;
				mDesc.mScrollPos += pagesize;
				if (mDesc.mScrollPos + mDesc.mScrollTop + pagesize > mDesc.mItems.Size())
				{
					mDesc.mScrollPos = mDesc.mItems.Size() - mDesc.mScrollTop - pagesize;
				}
				if (mDesc.mSelectedItem != -1)
				{
					mDesc.mSelectedItem = mDesc.mScrollTop + mDesc.mScrollPos;
					while (!mDesc.mItems[mDesc.mSelectedItem].Selectable())
					{
						if (++mDesc.mSelectedItem >= mDesc.mItems.Size())
						{
							mDesc.mSelectedItem = 0;
						}
					}
					if (mDesc.mScrollPos > mDesc.mSelectedItem)
					{
						mDesc.mScrollPos = mDesc.mSelectedItem;
					}
				}
			}
			break;

		case MKEY_Enter:
			if (mDesc.mSelectedItem >= 0)
			{
				if (mDesc.mItems[mDesc.mSelectedItem] is "OptionMenuItemSubmenu")
				{
					if (mDesc.mItems[mDesc.mSelectedItem] is "OptionMenuItemCommand")
					{
						nodim = true;
						return Super.MenuEvent(Menu.MKEY_Enter, false);
					}
					else if (mDesc.mItems[mDesc.mSelectedItem] is "OptionMenuItemJoyConfigMenu")
					{
						let item = OptionMenuItemJoyConfigMenu(mDesc.mItems[mDesc.mSelectedItem]);

						let desc = OptionMenuDescriptor(MenuDescriptor.GetDescriptor('WolfJoystickConfigMenu'));
						if (desc != NULL)
						{
							item.SetController(OptionMenuDescriptor(desc), item.mJoy);
						}

						SetMenu("WolfJoystickConfigMenu");

						fadecolor = 0x880000;
						MenuSound("menu/select");
						fadetarget = gametic + fadetime;

						return true;
					}

					fadecolor = 0x880000;
					activated = mDesc.mItems[mDesc.mSelectedItem];
					MenuSound("menu/select");
					fadetarget = gametic + fadetime;

					return true;
				}
				else if (mDesc.mItems[mDesc.mSelectedItem].Activate())
				{
					nodim = true;
					return true;
				}
			}
		default:
			if (mDesc.mSelectedItem >= 0 && 
				mDesc.mItems[mDesc.mSelectedItem].MenuEvent(mkey, fromcontroller)) return true;
			return Super.MenuEvent(mkey, fromcontroller);
		}

		if (mDesc.mSelectedItem != startedAt)
		{
			MenuSound ("menu/cursor");
		}
		return true;
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (!source) { source = self; }

		if (ev.type == UIEvent.Type_RButtonUp)
		{
			return MenuEvent(MKEY_Back, false);
		}
		else if (ev.type == UIEvent.Type_WheelUp)
		{
			int scrollamt = MIN(2, mDesc.mScrollPos);
			mDesc.mScrollPos -= scrollamt;
			return true;
		}
		else if (ev.type == UIEvent.Type_WheelDown)
		{
			if (source.CanScrollDown)
			{
				if (source.VisBottom >= 0 && source.VisBottom < (mDesc.mItems.Size()-2))
				{
					mDesc.mScrollPos += 2;
					source.VisBottom += 2;
				}
				else if (source.VisBottom < mDesc.mItems.Size()-1)
				{
					mDesc.mScrollPos++;
					source.VisBottom++;
				}
			}
			return true;
		}
		else if (ev.type == UIEvent.Type_Char)
		{
			int key = String.CharLower(ev.keyChar);
			int itemsNumber = mDesc.mItems.Size();
			int direction = ev.IsAlt ? -1 : 1;
			for (int i = 0; i < itemsNumber; ++i)
			{
				int index = (mDesc.mSelectedItem + direction * (i + 1) + itemsNumber) % itemsNumber;
				if (!mDesc.mItems[index].Selectable()) continue;
				String label = StringTable.Localize(mDesc.mItems[index].mLabel);
				int firstLabelCharacter = String.CharLower(label.GetNextCodePoint(0));
				if (firstLabelCharacter == key)
				{
					mDesc.mSelectedItem = index;
					break;
				}
			}
			if (mDesc.mSelectedItem <= mDesc.mScrollTop + mDesc.mScrollPos
				|| mDesc.mSelectedItem > source.VisBottom)
			{
				int pagesize = source.VisBottom - mDesc.mScrollPos - mDesc.mScrollTop;
				mDesc.mScrollPos = clamp(mDesc.mSelectedItem - mDesc.mScrollTop - 1, 0, mDesc.mItems.size() - pagesize - 1);
			}
		}

		return Super.OnUIEvent(ev);
	}

	override void Drawer()
	{
		if (g_defaultmenus)
		{
			OptionMenu.Drawer();
			return;
		}

		int fontheight = (BigFont.GetHeight() + 1) * CleanYfac_1;

		if (!source) { source = self; }
		Draw(source, "ExtendedOptionMenu");

		Menu.Drawer(); // Make sure to draw the back button
	}

	override void DrawMenu(int left, int spacing, Font fnt, int scrolltop, int scrollheight)
	{
		screen.Dim((Game.IsSoD() ? 0x000088 : 0x880000), 1.0, 0, 0, screen.GetWidth(), screen.GetHeight());

		if (bkg) { screen.DrawTexture(bkg, true, 0, 0, DTA_Fullscreen, 1); }

		if (controls)
		{
			Vector2 size = TexMan.GetScaledSize(controls);
			screen.DrawTexture(controls, true, screen.GetWidth() / 2 - size.x * CleanXfac / 2, screen.GetHeight() - size.y * CleanyFac, DTA_CleanNoMove, true, DTA_DestWidth, int(size.x * CleanXfac), DTA_DestHeight, int(size.y * CleanYfac));
		}

		int y = mDesc.mPosition * CleanYfac_1;

		if (y <= 0)
		{
			y = DrawStrip(10 * CleanYfac);

			if (!title.Exists() && BigFont && mDesc.mTitle.Length() > 0)
			{
				if (generictitle.Exists())
				{
					y = DrawTitle(generictitle) + 10 * CleanYfac;
				}

				let tt = Stringtable.Localize(mDesc.mTitle);
				tt = tt.MakeUpper();
				screen.DrawText (BigFont, TitleColor(),
					(screen.GetWidth() - BigFont.StringWidth(tt) * CleanXfac_1) / 2, y,
					tt, DTA_CleanNoMove_1, true);

				y += (BigFont.GetHeight() + 2) * CleanYfac;
			}

			if (title.Exists())
			{
				y = DrawTitle(title) + 4 * CleanYfac;
			}
		}

		mDesc.mDrawTop = y;
		
		int fontheight = (BigFont.GetHeight() + 1) * CleanYfac_1;

		int ytop = y + mDesc.mScrollTop * BigFont.GetHeight();
		int lastrow = scrollheight ? scrollheight : screen.GetHeight() - fontheight * 2;

//		int framewidth = MenuHandler.ItemsWidth(handler.Items) + 48; // Has calculation issues...
		int framewidth = max(620, Screen.GetWidth() * 2 / 3);

		int x = left + DrawFrame(framewidth, lastrow - y, -y);
		leftedge = x;
		
		x += 32 * CleanXfac_1;

		screen.Dim(fadecolor, 1.0 - alpha, 0, 0, screen.GetWidth(), screen.GetHeight());

		Super.DrawMenu(x, 120, Font.GetFont("BigFont"), ytop, lastrow - fontheight);
	}

	override void Ticker()
	{
		Super.Ticker();

		if (gametic > 35)
		{
			alpha = abs(clamp(double(fadetarget - gametic) / fadetime, -1.0, 1.0));
		}

		if (exitmenu)
		{
			if (exittimeout == 0) { MenuSound ("menu/backup"); }

			exittimeout++;

			if (exittimeout >= fadetime)
			{
				if (!mParentMenu || (mParentMenu is "IntroSlideshow")) { GameHandler.ChangeMusic("*"); }
				Close();
			}
		}

		if (activated && gametic >= fadetarget)
		{
			if (activated.Activate()) { activated = null; }
		}
	}

	int DrawStrip(int yOffset = 0)
	{
		int y;

		if (yoffset < 0) { y = -yOffset; }
		else { y = Screen.GetHeight() / 2 - 100 * CleanYfac + yOffset; }

		screen.Dim(0x000000, 1.0, 0, y, screen.GetWidth(), int(22 * CleanYfac));
		screen.Dim(0x000000, 0.3, 0, y + int(22 * CleanYfac), screen.GetWidth(), int(1 * CleanYfac));
		screen.Dim(0x000000, 1.0, 0, y + int(23 * CleanYfac), screen.GetWidth(), int(1 * CleanYfac));

		return y + 24 * CleanYfac;
	}

	int DrawFrame(int w, int h, int yoffset = 0)
	{
		int x = Screen.GetWidth() / 2 - w / 2;
		int y;
		
		if (yoffset < 0) { y = -yOffset; }
		else { y = Screen.GetHeight() / 2 - 100 * CleanYfac + yOffset; }

		color clrt = 0x700000;
		color clrb = 0xD40000;

		if (Game.IsSoD())
		{
			clrt = 0x000070;
			clrb = 0x0000D4;
			screen.Dim(0x000088, alpha, x, y, w, h);
		}

		screen.Dim(0x000000, 0.35 * alpha, x, y, w, h);

		int t = int(CleanYfac);
		screen.DrawThickLine(x - t, y - t / 2, x + w, y - t / 2, t, clrt);
		screen.DrawThickLine(x - t / 2, y, x - t / 2, y + h, t, clrt);
		screen.DrawThickLine(x - t, y + h + t / 2, x + w + t, y + h + t / 2, t, clrb);
		screen.DrawThickLine(x + w + t / 2, y - t, x + w + t / 2, y + h, t, clrb);

		return x;
	}

	int DrawTitle(TextureID title, int yoffset = 0, bool dodraw = true)
	{
		Vector2 size = TexMan.GetScaledSize(title);

		int x = Screen.GetWidth() / 2 - int(size.x * CleanXfac / 2);
		int y;

		if (yoffset < 0) { y = -yOffset; }
		else { y = Screen.GetHeight() / 2 - 100 * CleanYfac + yOffset; }

		if (dodraw) { screen.DrawTexture (title, true, x, y, DTA_CleanNoMove, true); }

		return y + int(size.y * CleanYfac);
	}

	// Don't draw menu path
	override void DrawPath(String title, int x, int y, Font fnt) {}

	override ItemInfo DrawOption(OptionMenuItemOptionBase this, int x, int y, int spacing, Font fnt, bool isSelected, int breakwidth)
	{
		int selectstate = -1;

		if (this.mValues == "YesNo" || this.mValues == "OnOff")
		{
			if (this.GetSelection() > 0) { selectstate = 1; }
			else { selectstate = 0; }
		}
		else if (this.mValues == "NoYes" || this.mValues == "OffOn")
		{
			if (this.GetSelection() > 0) { selectstate = 0; }
			else { selectstate = 1; }
		}

		if (selectstate > -1)
		{
			ItemInfo info = MenuHandler.FindItem(this);
			info.x = x;
			info.y = y;

			int fontheight = OptionMenuSettings.mLinespacing * 3 / 4;

			int height = 0;
			String label = Stringtable.Localize(this.mLabel);
			height = DrawOptionText(label, x, y, fnt, SelectionColor(isSelected), this.isGrayed(), 1.0, breakwidth);

			screen.DrawTexture(selectstate ? select1 : select0, true, x + spacing, y + 1, DTA_DestHeight, fontheight * CleanYfac_1, DTA_DestWidth, (3 * fontheight) * CleanXfac_1, DTA_Alpha, alpha, DTA_ClipBottom, bottomclip);

			info.valueleft = x + spacing;
			info.width = OptionWidth(label, fnt) + spacing + 3 * fontheight;
			info.valueright = info.valueleft + 3 * fontheight;
			info.height = max(height, fontheight);

			return info;
		}
		else
		{
			return Super.DrawOption(this, x, y, spacing, fnt, isSelected, breakwidth);
		}
	}

	override ItemInfo DrawStaticText(OptionMenuItemStaticText this, int x, int y, Font fnt)
	{
		ItemInfo info = MenuHandler.FindItem(this);

		String label = StringTable.Localize(this.mLabel);
		label = label.MakeUpper();
		label = ZScriptTools.StripColorCodes(label);

		if (!label.length())
		{
			int i = mDesc.mItems.Find(OptionMenuItem(this));
			if (i < mDesc.mScrollTop) { return null; }
		}

		info.width = OptionWidth(label, fnt);
		info.x = this.mCentered ? Screen.GetWidth() / 2 - info.width / 2 : x;
		info.y = y;

		if (this.mCentered && ZScriptTools.Trim(label).length())
		{
			info.width = max(OptionWidth(label, fnt) + 16, Game.IsSoD() ? 0 : 136) * CleanXfac_1;
			info.x = this.mCentered ? Screen.GetWidth() / 2 - info.width / 2 : x;

			DrawToHUD.DrawFrame("BU_D_", info.x, info.y - 2 * CleanYfac_1, info.width, 14 * CleanYfac_1, 0xa8a8a8, 1.0, 1.0, (CleanWidth_1, CleanHeight_1), DrawToHUD.TEX_MENU, 1.0);
			info.height = DrawOptionText(label, info.x + info.width / 2 - OptionWidth(label, fnt) * CleanXfac_1 / 2, info.y, fnt, Font.FindFontColor("WolfMenuDarkGray"), scale:(1.0, 0.75));
		}
		else
		{
			info.height = DrawOptionText(label, info.x, info.y, fnt, TitleColor());
		}

		info.valueleft = info.valueright = x + info.width;

		return info;
	}

	override ItemInfo DrawStaticTextSwitchable(OptionMenuItemStaticTextSwitchable this, int x, int y, Font fnt)
	{
		ItemInfo info = MenuHandler.FindItem(this);
		info.x = x;
		info.y = y;

		String label = StringTable.Localize(this.mCurrent ? this.mAltText : this.mLabel);
		info.height = DrawOptionText(label, this.mCentered ? Screen.GetWidth() / 2 - fnt.StringWidth(label) * CleanXfac_1 / 2 : x, y - 16, fnt, TitleColor());
		info.width = OptionWidth(label, fnt);
		info.valueleft = info.valueright = x + info.width;

		return info;
	}

	override ItemInfo DrawSlider(OptionMenuSliderBase this, int x, int y, int spacing, Font fnt, bool isSelected, Vector2 size, Vector2 handlesize, int breakwidth)
	{
		return Super.DrawSlider(this, x, y, spacing, fnt, isSelected, (16, 8), (8, 14), breakwidth);
	}

	override ItemInfo DrawControl(OptionMenuItemControlBase this, int x, int y, int spacing, Font fnt, bool isSelected, int breakwidth)
	{
		ItemInfo info = MenuHandler.FindItem(this);
		info.x = x;
		info.y = y;

		int height = 0;
		String label = Stringtable.Localize(this.mLabel);
		height = DrawOptionText(label, x, y, fnt, this.mWaiting ? HighlightColor() : SelectionColor(isSelected), false, 1.0, breakwidth);
		height = max(int(16 * CleanYfac_1), height);

		KeyBindings binds;
		if (this is "OptionMenuItemMapControl") { binds = AutomapBindings; }

		info.valueleft = x + spacing;

		if (y + height <= bottomclip + 1)
		{
			info.width = spacing + DrawToHUD.DrawCommandButtons((info.valueleft, y + (OptionMenu.OptionHeight() / 2)), this.GetAction(), 1.0, (CleanWidth_1, CleanHeight_1), 1.0, Button.BTN_MIDDLE | Button.BTN_MENU, binds);
		}

		info.valueright = x + info.width;
		info.height = height;

		return info;
	}

	override void DrawCursor(int x, int y)
	{
		double cursoralpha = sin(Menu.MenuTime() * 10) / 2 + 0.5;
		screen.DrawTexture(cursor0, true, x - 16 * CleanXfac_1, y, DTA_Alpha, alpha, DTA_CleanNoMove_1, true);
		screen.DrawTexture(cursor1, true, x - 16 * CleanXfac_1, y, DTA_Alpha, alpha * cursoralpha, DTA_CleanNoMove_1, true);
	}

	override void DrawScrollArrows(int x, int ytop, int ybottom)
	{
		if (!source) { source = self; }
		if (source.CanScrollUp)
		{
			screen.DrawText(NewSmallFont, TitleColor(), x - 16, ytop, "▲", DTA_Alpha, alpha);
		}
		if (source.CanScrollDown)
		{
			screen.DrawText(NewSmallFont, TitleColor(), x - 16, ybottom, "▼", DTA_Alpha, alpha);
		}
	}

	override int TextColor()
	{
		if (g_defaultmenus) { return Super.TextColor(); }

		return Font.FindFontColor("TrueWhite");
	}

	override int ValueColor()
	{
		if (g_defaultmenus) { return Super.ValueColor(); }

		return Font.FindFontColor("TrueWhite");
	}

	override int SelectionColor(bool selected)
	{
		if (g_defaultmenus)
		{
			return Super.SelectionColor(selected);
		}

		if (selected) { return Font.FindFontColor("WolfMenuLightGray"); }

		return Font.FindFontColor("WolfMenuGray");
	}

	override int TitleColor()
	{
		if (g_defaultmenus) { return Super.TitleColor(); }

		return Font.FindFontColor("WolfMenuYellow");
	}

	override int HighlightColor()
	{
		if (g_defaultmenus) { return Super.HighlightColor(); }

		return Font.FindFontColor("WolfMenuWhite");
	}

	override int DrawCaption(OptionMenuItem this)
	{
		String text = this.mLabel;
		text.Replace(" ", "");
		text.Replace("$", "");

		String lookupbase = mDesc.mTitle;
		text.Replace(" ", "");
		lookupbase.Replace("$", "");

		String lookup = lookupBase .. "_" .. text;
		text = lookup;
		text = StringTable.Localize("$" .. lookup);
		if (text == lookup) { return 0; }
		
		int lineheight = SmallFont.GetHeight();
		screen.DrawText (SmallFont, Font.FindFontColor("WolfMenuYellowBright"), leftedge, screen.GetHeight() - lineheight * 2.5, text);

		return lineheight;
	}
}

class OptionMenuItemBox : OptionMenuItem
{
	int x, y, w, h, yoffset, inputw, inputh;

	OptionMenuItemBox Init(int width, int height, int offset, string prefix = "M_BOR")
	{
		Super.Init("Box", 'None', true);

		inputw = width;
		inputh = height;
		yoffset = offset;

		return self;
	}
	
	override int Draw(OptionMenuDescriptor desc, int ypos, int indent, bool selected)
	{
		w = int(inputw * CleanXfac);
		h = int(inputh * CleanYfac);
		x = Screen.GetWidth() / 2 - w / 2;
		y = Screen.GetHeight() / 2 - 103 * CleanYfac + int(yoffset * CleanYfac);

		color clrt = 0x700000;
		color clrb = 0xD40000;

		if (Game.IsSoD())
		{
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

		return indent;
	}

	override bool Selectable() { return false; }
}

class OptionMenuItemTopStrip : OptionMenuItem
{
	int yoffset;

	OptionMenuItemTopStrip Init(int offset)
	{
		Super.Init("Strip", 'None', true);

		yoffset = offset;

		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		int y = Screen.GetHeight() / 2 - 100 * CleanYfac + int((yOffset + mYpos) * CleanYfac);

		screen.Dim(0x000000, 1.0, 0, y, screen.GetWidth(), int(22 * CleanYfac));
		screen.Dim(0x000000, 0.3, 0, y + int(22 * CleanYfac), screen.GetWidth(), int(1 * CleanYfac));
		screen.Dim(0x000000, 1.0, 0, y + int(23 * CleanYfac), screen.GetWidth(), int(1 * CleanYfac));

		return indent;
	}

	override bool Selectable() { return false; }
}

class OptionMenuItemStripTitle : OptionMenuItem
{
	TextureID mTexture;
	double xoffset, yoffset;

	OptionMenuItemStripTitle Init(double x_offs, double y_offs, String patch)
	{
		xoffset = x_offs;
		yoffset = y_offs;

		if (Game.IsSoD())
		{
			patch = patch.left(2) .. "S" .. patch.mid(2);
			patch = patch.left(8);
		}

		mTexture = TexMan.CheckForTexture(patch, TexMan.Type_Any);

		Super.Init("Title", 'None', true);

		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		if (!mTexture.Exists()) { return indent; }

		Vector2 size = TexMan.GetScaledSize(mTexture);

		int x = Screen.GetWidth() / 2 - int(size.x * CleanXfac / 2) + int(xOffset* CleanXfac);
		int y = Screen.GetHeight() / 2 - 100 * CleanYfac + int((yOffset + mYpos) * CleanYfac);

		screen.DrawTexture (mTexture, true, x, y, DTA_CleanNoMove, true);

		return indent;
	}

	override bool Selectable() { return false; }
}

class WolfNewPlayerMenu : NewPlayerMenu
{
	ExtendedOptionMenu generic;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		mPlayerDisplay.mBackdrop = TexMan.CheckForTexture("BACKDROP", TexMan.Type_Any);
		mPlayerDisplay.mBaseColor = color(255, 255, 255);
	}

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		mPlayerDisplay.Drawer(false);
		
		int x = screen.GetWidth()/(CleanXfac_1*2) + PLAYERDISPLAY_X + PLAYERDISPLAY_W/2;
		int y = PLAYERDISPLAY_Y + 5;
		String str = Stringtable.Localize("$PLYRMNU_PRESSSPACE");
		screen.DrawText (SmallFont, Font.CR_GOLD, x - SmallFont.StringWidth(str)/2, y, str, DTA_VirtualWidth, CleanWidth_1, DTA_VirtualHeight, CleanHeight_1, DTA_KeepRatio, true);
		str = Stringtable.Localize(mRotation ? "$PLYRMNU_SEEFRONT" : "$PLYRMNU_SEEBACK");
		y += SmallFont.GetHeight();
		screen.DrawText (SmallFont, Font.CR_GOLD,x - SmallFont.StringWidth(str)/2, y, str, DTA_VirtualWidth, CleanWidth_1, DTA_VirtualHeight, CleanHeight_1, DTA_KeepRatio, true);

		Menu.Drawer();
	}
	
	override void Ticker()
	{
		if (generic) { generic.Ticker(); }

		Super.Ticker();
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic && generic.MenuEvent(mkey, fromcontroller)) { return true; }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfJoystickConfigMenu : JoystickConfigMenu
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		else { Super.Ticker(); }
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic) { return generic.MenuEvent(mkey, fromcontroller); }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfGameplayMenu : GameplayMenu
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		String s = String.Format("dmflags = %d\ndmflags2 = %d", dmflags, dmflags2);
		screen.DrawText (SmallFont, OptionMenuSettings.mFontColorValue, 40, screen.GetHeight() - SmallFont.GetHeight() * 2.5, s);

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		else { Super.Ticker(); }
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic && generic.MenuEvent(mkey, fromcontroller)) { return true; }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfCompatibilityMenu : CompatibilityMenu
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		String s = String.Format("compatflags = %d\ncompatflags2 = %d", compatflags, compatflags2);
		screen.DrawText (SmallFont, OptionMenuSettings.mFontColorValue, 40, screen.GetHeight() - SmallFont.GetHeight() * 2.5, s);

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		else { Super.Ticker(); }
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic) { return generic.MenuEvent(mkey, fromcontroller); }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfGLTextureGLOptions : GLTextureGLOptions
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		Super.Ticker();
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic) { return generic.MenuEvent(mkey, fromcontroller); }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfReverbEdit : ReverbEdit
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		else { Super.Ticker(); }
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic) { return generic.MenuEvent(mkey, fromcontroller); }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfReverbSelect : ReverbSelect
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		else { Super.Ticker(); }
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic) { return generic.MenuEvent(mkey, fromcontroller); }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfReverbSave : ReverbSave
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		else { Super.Ticker(); }
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic) { return generic.MenuEvent(mkey, fromcontroller); }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfColorPickerMenu : ColorPickerMenu
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		if (mCVar == null) return;
		int y = (-mDesc.mPosition + BigFont.GetHeight() + mDesc.mItems.Size() * OptionMenuSettings.mLinespacing) * CleanYfac_1;
		int fh = OptionMenuSettings.mLinespacing * CleanYfac_1;
		int h = (screen.GetHeight() - y) / 16;
		int w = fh;
		int yy = y;

		if (h > fh) h = fh;
		else if (h < 4) return;	// no space to draw it.
		
		int indent = (screen.GetWidth() / 2);
		int p = 0;

		for(int i = 0; i < 16; i++)
		{
			int box_x, box_y;
			int x1;

			box_y = y - 2 * CleanYfac_1;
			box_x = indent - 16*w;
			for (x1 = 0; x1 < 16; ++x1)
			{
				screen.Clear (box_x, box_y, box_x + w, box_y + h, 0, p);
				if ((mDesc.mSelectedItem == mStartItem+7) && 
					(/*p == CurrColorIndex ||*/ (i == mGridPosY && x1 == mGridPosX)))
				{
					int r, g, b;
					Color col;
					double blinky;
					if (i == mGridPosY && x1 == mGridPosX)
					{
						r = 255; g = 128; b = 0;
					}
					else
					{
						r = 200; g = 200; b = 255;
					}
					// Make sure the cursors stand out against similar colors
					// by pulsing them.
					blinky = abs(sin(MSTime()/1000.0)) * 0.5 + 0.5;
					col = Color(255, int(r*blinky), int(g*blinky), int(b*blinky));

					screen.Clear (box_x, box_y, box_x + w, box_y + 1, col);
					screen.Clear (box_x, box_y + h-1, box_x + w, box_y + h, col);
					screen.Clear (box_x, box_y, box_x + 1, box_y + h, col);
					screen.Clear (box_x + w - 1, box_y, box_x + w, box_y + h, col);
				}
				box_x += w;
				p++;
			}
			y += h;
		}
		y = yy;
		color newColor = Color(255, int(mRed), int(mGreen), int(mBlue));
		color oldColor = mCVar.GetInt() | 0xFF000000;

		int x = screen.GetWidth()*2/3;

		screen.Clear (x, y, x + 48*CleanXfac_1, y + 48*CleanYfac_1, oldColor);
		screen.Clear (x + 48*CleanXfac_1, y, x + 48*2*CleanXfac_1, y + 48*CleanYfac_1, newColor);

		y += 49*CleanYfac_1;
		screen.DrawText (SmallFont, Font.CR_GRAY, x+(48-SmallFont.StringWidth("---->")/2)*CleanXfac_1, y, "---->", DTA_CleanNoMove_1, true);

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		else { Super.Ticker(); }
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic) { return generic.MenuEvent(mkey, fromcontroller); }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}

class WolfOS_Menu : OS_Menu
{
	ExtendedOptionMenu generic;

	override void Drawer()
	{
		if (generic) { generic.Drawer(); }
		else { generic = ExtendedOptionMenu(GenericOptionMenu.Draw(self, "ExtendedOptionMenu")); }

		Menu.Drawer();
	}

	override void Ticker()
	{
		if (generic) { generic.Ticker(); }
		else { Super.Ticker(); }
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (generic) { return generic.MenuEvent(mkey, fromcontroller); }
		
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (generic && generic.MouseEvent(type, x, y)) { return true; }

		return Super.MouseEvent(type, x, y);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (generic && generic.OnUIEvent(ev)) { return true; }

		return Super.OnUIEvent(ev);
	}
}