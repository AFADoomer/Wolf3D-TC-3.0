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

class MenuHandler : EventHandler
{
	ui Array<ItemInfo> Items;

	static ui MenuHandler Get()
	{
		return MenuHandler(EventHandler.Find("MenuHandler"));
	}

	static ui ItemInfo FindItem(OptionMenuItem item)
	{
		MenuHandler handler = MenuHandler.Get();

		for (int i = 0; i < handler.Items.Size(); i++)
		{
			if (handler.Items[i].item == item)
			{
				return handler.Items[i];
			}
		}

		ItemInfo new = New("ItemInfo");
		handler.Items.Push(new);
		new.item = item;
		new.width = 0;

		return new;
	}

	static ui int ItemsWidth(Array<ItemInfo> items, int default = 100)
	{
		int width = default;

		for (int i = 0; i < items.Size(); i++)
		{
			if (items[i].menu == Menu.GetCurrentMenu())
			{
				width = max(width, items[i].width);
			}
		}

		return width;
	}
}

class ItemInfo
{
	OptionMenu menu;
	OptionMenuItem item;
	int x, y;
	int cursor, height, width, valueleft, valueright;
}

class GenericOptionMenu : OptionMenu
{
	double alpha;
	int columnwidth, columnspacing, bottomclip;
	String menuprefix;
	MenuHandler handler;
	OptionMenu source;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);

		alpha = 1.0;
		columnwidth = -1;
		columnspacing = 20;

		menuprefix = "Generic";

		DontDim = true;

		handler = MenuHandler.Get();
	}

	override void Drawer()
	{
		if (g_defaultmenus)
		{
			OptionMenu.Drawer();
			return;
		}

		DrawMenu(20, 20);
	}

	static GenericOptionMenu Draw(OptionMenu current, String cls = "GenericOptionMenu", int left = 0, int spacing = 0, Font fnt = null, int scrolltop = 0, int scrollheight = 0)
	{
		let generic = GenericOptionMenu(New(cls));
		if (!generic) { return null; }

		generic.Init(current.mParentMenu, current.mDesc);
		generic.source = current;

		generic.DrawMenu(left, spacing, fnt, scrolltop, scrollheight);

		return generic;
	}

	virtual void DrawMenu(int left = 0, int spacing = 0, Font fnt = null, int scrolltop = 0, int scrollheight = 0)
	{
		if (!fnt) { fnt = SmallFont; }

		int x = left;
		int y = (scrolltop ? scrolltop : OptionMenuSettings.mLinespacing * 4 / 3) + OptionMenuSettings.mLinespacing;
		
		if (mDesc.mTitle.Length())
		{
			Menu parent = mParentMenu;

			String title = Stringtable.Localize(mDesc.mTitle) .. ":";

			while (parent)
			{
				if (OptionMenu(parent))
				{
					title = Stringtable.Localize(OptionMenu(parent).mDesc.mTitle) .. " / " .. title;
					parent = parent.mParentMenu;
				}
				else
				{
					parent = null;
				}
			}

			DrawPath(title, x, y, fnt);
		}

		mDesc.mDrawTop = y;

		int ytop = y + mDesc.mScrollTop * BigFont.GetHeight();
		int lastrow = scrollheight ? scrollheight : screen.GetHeight() - y;
		bottomclip = lastrow + (BigFont.GetHeight() + 1) * CleanYfac_1;

		int indent = x + spacing;

		if (columnwidth > -1) { indent = columnwidth; }
		else
		{
			for (int j = 0; j < source.mDesc.mItems.Size(); j++)
			{
				indent = columnwidth = max(indent, OptionWidth(Stringtable.Localize(mDesc.mItems[j].mLabel), fnt));
			}
		}

		indent += columnspacing;

		int enableditems;
		for (int k = 0; k < mDesc.mItems.Size(); k++)
		{
			if (mDesc.mItems[k].mEnabled) { enableditems++; }
		}

		for (int l = 0; l < mDesc.mItems.Size(); l++)
		{
			ItemInfo i = DrawItemType(mDesc.mItems[l], -0x7FFFFFFF,  -0x7FFFFFFF, indent, fnt);
		}

		int i, r;
		for (i = 0; i < mDesc.mItems.Size() && y <= lastrow; i++)
		{
			// Don't scroll the uppermost items
			if (i == mDesc.mScrollTop)
			{
				i += mDesc.mScrollPos;
				if (i >= mDesc.mItems.Size()) { break; } // skipped beyond end of menu 
			}

			ItemInfo info = DrawItemType(mDesc.mItems[i], x, y, indent, fnt, mDesc.mSelectedItem == i);

			if (info)
			{ 
				y += info.height;
				if (y <= lastrow) { r = i; }
			}
		}

		source.CanScrollUp = !!(mDesc.mScrollPos > 0);
		source.CanScrollDown = !!(r < mDesc.mItems.Size() - 1);
		source.VisBottom = r;

		DrawScrollArrows(x - 34, ytop - 4 * CleanYfac_1, lastrow - 14 * CleanYfac_1);
	}

	virtual ItemInfo DrawItemType(OptionMenuItem item, int x, int y, int indent, Font fnt, bool isSelected = false)
	{
		if (item.mEnabled)
		{
			if (isSelected && item.Selectable())
			{
				DrawCursor(x - 12 * CleanXfac_1, y);
				DrawCaption(item);
			}

			if (item is "OptionMenuItemControlBase")
			{
				return DrawControl(OptionMenuItemControlBase(item), x, y, indent, fnt, isSelected, columnwidth);
			}
			else if (item is "OptionMenuItemOptionBase")
			{
				return DrawOption(OptionMenuItemOptionBase(item), x, y, indent, fnt, isSelected, columnwidth);
			}
			else if (item is "OptionMenuSliderBase")
			{
				return DrawSlider(OptionMenuSliderBase(item), x, y, indent, fnt, isSelected, breakwidth:columnwidth);
			}
			else if (item is "OptionMenuItemStaticTextSwitchable")
			{
				return DrawStaticTextSwitchable(OptionMenuItemStaticTextSwitchable(item), x, y, fnt);
			}
			else if (item is "OptionMenuItemColorPicker")
			{
				return DrawColorPicker(item, x, y, indent, fnt, isSelected, columnwidth);
			}
			else if (item is "OptionMenuItemStaticText")
			{
				return DrawStaticText(OptionMenuItemStaticText(item), x, y, fnt);
			}
			else if (item is "OptionMenuFieldBase")
			{
				return DrawField(OptionMenuFieldBase(item), x, y, indent, fnt, isSelected);
			}
			else if (item is "OptionMenuItemCommand")
			{
				return DrawCommand(item, x, y, fnt, isSelected, columnwidth);
			}
			else if (item is "OptionMenuItemJoyConfigMenu")
			{
				return DrawJoyConfigMenu(OptionMenuItemJoyConfigMenu(item), x, y, indent, fnt, isSelected, columnwidth);
			}
			else if (item is "OptionMenuItemSubmenu")
			{
				return DrawSubmenu(OptionMenuItemSubmenu(item), x, y, indent, fnt, isSelected, columnwidth);
			}
			else
			{
				return DrawItem(item, x, y, fnt, isSelected, columnwidth);
			}
		}

		return null;
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (g_defaultmenus)
		{
			return OptionMenu.MouseEvent(type, x, y);
		}

		if (mFocusControl)
		{
			ItemInfo item = MenuHandler.FindItem(mFocusControl);

			if
			(
				y >= item.y && y <= item.y + item.height &&
				x >= item.x && x <= item.valueright
			)
			{
				if (type == MOUSE_Release)
				{
					if (item.item is "OptionMenuSliderBase")
					{
						ReleaseFocus();
					}
					else
					{
						int newselection = mDesc.mItems.Find(mFocusControl);
						if (newselection > -1 && newselection < mDesc.mItems.Size())
						{
							mDesc.mSelectedItem = newselection;
							return MenuEvent(Menu.MKEY_Enter, true);
						}
					}
				}

				SetSlider(item, x);

				return true;
			}
			else
			{
				if (item.item is "OptionMenuSliderBase" && type == MOUSE_Move)
				{
					SetSlider(item, x);
				}
				else
				{
					ReleaseFocus();
				}
			}
		}

		if (!mFocusControl && type == MOUSE_Click)
		{
			for (int i = 0; i < handler.Items.Size(); i++)
			{
				ItemInfo item = handler.Items[i];

				if (
					item.menu == GetCurrentMenu() &&
					y >= item.y && y <= item.y + item.height &&
					x >= item.x && x <= item.valueright
				)
				{
					SetFocus(item.item);
					SetSlider(item, x);
				}
			}
		}

		if (mFocusControl)
		{
			y -= mDesc.mDrawTop;
			mFocusControl.MouseEvent(type, x, y);
			return true;
		}
		else
		{
			for (int i = 0; i < mDesc.mItems.Size(); i++)
			{
				ItemInfo item = MenuHandler.FindItem(mDesc.mItems[i]);

				if (
					item &&
					y >= item.y && y <= item.y + item.height
				)
				{
					mDesc.mSelectedItem = i;
					mDesc.mItems[i].MouseEvent(type, x, y);
					return true;
				}
			}
		}

		return Menu.MouseEvent(type, x, y);
	}

	void SetSlider(ItemInfo item, int x)
	{
		if (item.item is "OptionMenuSliderBase")
		{
			x = clamp(x, item.valueleft, item.valueright);

			OptionMenuSliderBase slider = OptionMenuSliderBase(item.item);

			double middle = (item.valueright - item.valueleft) / 2;
			x = int((x - item.valueleft - middle) * 1.1 + middle + item.valueleft);

			slider.SetSliderValue(slider.mMin + (x - item.valueleft) * (slider.mMax - slider.mMin) / (item.valueright - item.valueleft));
		}
	}

	int DrawOptionText(String text, int x, int y, Font fnt = null, int color = 0, bool grayed = false, double textalpha = 1.0, int breakwidth = -1, Vector2 scale = (1.0, 1.0))
	{
		if (fnt == null) { fnt = SmallFont; }
		if (breakwidth == -1) { breakwidth = int(CleanWidth_1 * scale.x / 2); }
		else { breakwidth = int(breakwidth / CleanXfac_1 * scale.x); }

		int fontheight = int((fnt.GetHeight() - 2) * CleanYfac_1 * scale.y);
		
		int height = 0;
		int overlay = grayed ? Color(128, 64, 64, 64) : 0;

		String label = Stringtable.Localize(text);
		BrokenLines lines = fnt.BreakLines(text, breakwidth);

		for (int i = 0; i < lines.count(); i++)
		{
			screen.DrawText(fnt, color, x, y + i * fontheight, lines.StringAt(i), DTA_Alpha, textalpha * alpha, DTA_ColorOverlay, overlay, DTA_ScaleX, scale.x * CleanXfac_1, DTA_ScaleY, scale.y * CleanYfac_1, DTA_ClipBottom, bottomclip);
		}

		height += lines.Count() * fontheight + 6 * CleanYfac_1;

		if (lines.count() > 1) { height += OptionMenuSettings.mLinespacing - fontheight; }

		return max(height, OptionMenuSettings.mLinespacing);
	}

	int DrawValue(String text, int x, int y, int spacing, Font fnt, int color, bool grayed = false, int breakwidth = -1)
	{
		return DrawOptionText(text, x + spacing, y, fnt, color, grayed, 1.0, breakwidth);
	}

	int DrawSliderElements(OptionMenuSliderBase this, int x, int y, int spacing, Font fnt, double min, double max, double cur, int fracdigits, Vector2 size = (16, 16), Vector2 handlesize = (-1, -1))
	{
		size.x *= CleanXfac_1;
		size.y *= CleanYfac_1;

		if (handlesize == (-1, -1)) { handlesize = size; }
		else
		{
			handlesize.x *= CleanXfac_1;
			handlesize.y *= CleanYfac_1;
		}
		
		x += int(spacing + size.x / 2);

		String formater;
		if (fracdigits >= 0) { formater = String.format("%%.%df", fracdigits); } // The format function cannot do the '%.*f' syntax.
		else
		{
			formater = "%i%%";
			fracdigits = 1;
		}

		String textbuf;
		double range;
		int maxlen = 0;
		int right = x + int(11.5 * size.x);
		int cy = y - 2;

		range = max - min;
		double ccur = clamp(cur, min, max) - min;

		if (fracdigits >= 0)
		{
			textbuf = String.format(formater, max);
			maxlen = OptionWidth(textbuf, fnt);
		}

		this.mSliderShort = right + maxlen > screen.GetWidth();

		if (!this.mSliderShort)
		{
			DrawElement(x, cy, "Slider_L", 0, size);
			for (int s = 1; s < 11; s++) { DrawElement(x + s * size.x, cy, "Slider_M", 0, size); }
			DrawElement(x + 11 * size.x, cy, "Slider_R", 0, size);
			DrawElement(x + 1 + int(ccur * (11 * size.x - 2) / range), cy, "Slider_H", 0, handlesize);
		}
		else
		{
			// On 320x200 we need a shorter slider
			DrawElement(x, cy, "Slider_L", 0, size);
			for (int s = 1; s < 6; s++) { DrawElement(x + s * size.x, cy, "Slider_M", 0, size); }
			DrawElement(x + 6 * size.x, cy, "Slider_R", 0, size);
			DrawElement(x + 1 + int(ccur * (7 * size.x - 2) / range), cy, "Slider_H", 0, handlesize);

			right -= int(5 * size.x);
		}

		if (fracdigits >= 0 && right + maxlen <= screen.GetWidth())
		{
			textbuf = String.format(formater, cur);
			DrawOptionText(textbuf, right + 4 * CleanXfac_1, y, fnt, HighlightColor());
		}

		return right;
	}

	void DrawElement(double x, double y, String pic, int clr = 0, Vector2 size = (16, 16))
	{
		let tex = TexMan.CheckForTexture(pic, TexMan.Type_MiscPatch);

		if (tex.isValid())
		{
			x -= size.x / 2;
			y += OptionMenuSettings.mLinespacing * CleanYfac_1 / 2 - size.y / 2;
			screen.DrawTexture(tex, true, int(x), int(y), DTA_DestWidth, int(size.x), DTA_DestHeight, int(size.y), DTA_Alpha, alpha, DTA_ClipBottom, bottomclip);
			if (clr > 0) { screen.DrawTexture(tex, true, int(x), int(y), DTA_DestWidth, int(size.x), DTA_DestHeight, int(size.y), DTA_FillColor, clr, DTA_Alpha, 0.5 * alpha, DTA_ClipBottom, bottomclip); }
		}
	}

	int OptionWidth(String s, Font fnt)
	{
		return fnt.StringWidth(s);
	}

	virtual int DrawCaption(OptionMenuItem this)
	{
		int x = 10;
		int y = 10;

		String text = StringTable.Localize(this.mLabel);
		text.Replace(" ", "");

		String lookupbase = StringTable.Localize(mDesc.mTitle);
		lookupbase.Replace(" ", "");

		String lookup = lookupBase .. "_" .. text;
		text = StringTable.Localize("$" .. lookup);
		if (text == lookup) { return 0; }

		return DrawOptionText(text, x, y, SmallFont, TextColor(), false, alpha, Screen.GetWidth() / 2);
	}

	virtual void DrawPath(String title, int x, int y, Font fnt = null)
	{
		DrawOptionText(title, x + 10, 20, fnt, TitleColor());
	}

	virtual ItemInfo DrawControl(OptionMenuItemControlBase this, int x, int y, int spacing = 20, Font fnt = null, bool isSelected = false, int breakwidth = -1)
	{
		ItemInfo info = MenuHandler.FindItem(this);
		info.x = x;
		info.y = y;

		int height = 0;
		String label = Stringtable.Localize(this.mLabel);
		height = DrawOptionText(label, x, y, fnt, this.mWaiting ? HighlightColor() : SelectionColor(isSelected), false, 1.0, breakwidth);

		String Description;
		int Key1, Key2;

		[Key1, Key2] = this.mBindings.GetKeysForCommand(this.GetAction());

		description = KeyBindings.NameKeys(Key1, Key2);
		if (!description.Length()) { description = "---"; }

		info.valueleft = x + spacing;
		info.width = spacing + OptionWidth(description, fnt);
		info.valueright = x + info.width;

		height = max(DrawValue(description, x, y, spacing, fnt, HighlightColor()), height);

		info.height = height;

		return info;
	}

	virtual ItemInfo DrawOption(OptionMenuItemOptionBase this, int x, int y, int spacing = 20, Font fnt = null, bool isSelected = false, int breakwidth = -1)
	{
		ItemInfo info = MenuHandler.FindItem(this);
		info.x = x;
		info.y = y;

		int height = 0;
		String label = Stringtable.Localize(this.mLabel);
		height = DrawOptionText(label, x, y, fnt, SelectionColor(isSelected), this.isGrayed(), 1.0, breakwidth);

		int Selection = this.GetSelection();
		String text = StringTable.Localize(OptionValues.GetText(this.mValues, Selection));
		if (text.Length() == 0) text = "Unknown";

		info.valueleft = x + spacing;
		info.width = spacing + OptionWidth(text, fnt);
		info.valueright = x + info.width;

		if (this is "os_AnyOrAllOption")
		{
			height = max(DrawValue(text, x + fnt.StringWidth(label), y, spacing, fnt, ValueColor(), this.isGrayed()), height);	
		}
		else
		{
			height = max(DrawValue(text, x, y, spacing, fnt, ValueColor(), this.isGrayed()), height);
		}

		info.height = height;

		return info;
	}

	virtual ItemInfo DrawSlider(OptionMenuSliderBase this, int x, int y, int spacing = 20, Font fnt = null, bool isSelected = false, Vector2 size = (16, 16), Vector2 handlesize = (-1, -1), int breakwidth = -1)
	{
		ItemInfo info = MenuHandler.FindItem(this);
		info.x = x;
		info.y = y;

		int height = 0;
		String label = Stringtable.Localize(this.mLabel);
		height = DrawOptionText(label, x, y, fnt, SelectionColor(isSelected), false, 1.0, breakwidth);

		info.valueleft = x + spacing;

		if (this is "OptionMenuItemScaleSlider")
		{
			int Selection = int(this.GetSliderValue());
			if ((Selection == 0 || Selection == -1) && OptionMenuItemScaleSlider(this).mClickVal <= 0)
			{
				String text = Selection == 0 ? OptionMenuItemScaleSlider(this).TextZero : Selection == -1 ? OptionMenuItemScaleSlider(this).TextNegOne : "";

				info.width = OptionWidth(text, fnt);
				info.valueright = info.valueleft + info.width;

				height = max(DrawValue(text, x, y, spacing, fnt, ValueColor()), height);
			}
			else
			{
				if (OptionMenuItemScaleSlider(this).TextZero ~== "$TXT_DISABLED")
				{
					info.valueright = DrawSliderElements(this, x, y, spacing, fnt, 0.0, 100.0, this.GetSliderValue() * 100 / (this.mMax - this.mMin), -1, size, handlesize);
				}
				else
				{
					info.valueright = DrawSliderElements(this, x, y, spacing, fnt, this.mMin, this.mMax, this.GetSliderValue(), this.mShowValue, size, handlesize);
				}
				info.width = info.valueright - x;
			}
		}
		else
		{
			info.valueright = DrawSliderElements(this, x, y, spacing, fnt, this.mMin, this.mMax, this.GetSliderValue(), this.mShowValue, size, handlesize);
			info.width = info.valueright - x;
		}

		int maxlen = 0;
		if (this.mShowValue >= 0)
		{
			String maxval = String.Format("%%.%df", this.mShowValue);
			String textbuf = String.Format(maxval, this.mMax);
			info.width += OptionWidth(textbuf, fnt);
		}

		info.height = max(height, int(max(size.y, handlesize.y)));

		return info;
	}

	virtual ItemInfo DrawStaticText(OptionMenuItemStaticText this, int x, int y, Font fnt = null)
	{
		ItemInfo info = MenuHandler.FindItem(this);
		info.x = x;
		info.y = y;

		String label = StringTable.Localize(this.mLabel);
		info.height = DrawOptionText(label, x, y, fnt, TitleColor());
		info.width = OptionWidth(label, fnt);
		info.valueleft = info.valueright = x + info.width;
		
		return info;
	}

	virtual ItemInfo DrawStaticTextSwitchable(OptionMenuItemStaticTextSwitchable this, int x, int y, Font fnt = null)
	{
		ItemInfo info = MenuHandler.FindItem(this);
		info.x = x;
		info.y = y;

		String label = StringTable.Localize(this.mCurrent ? this.mAltText : this.mLabel);
		info.height = DrawOptionText(label, x, y, fnt, TitleColor());
		info.width = OptionWidth(label, fnt);
		info.valueleft = info.valueright = x + info.width;

		return info;
	}

	virtual ItemInfo DrawColorPicker(out OptionMenuItem item, int x, int y, int spacing = 20, Font fnt = null, bool isSelected = false, int breakwidth = -1)
	{
		OptionMenuItemColorPicker this = OptionMenuItemColorPicker(item);

		ItemInfo info = MenuHandler.FindItem(this);
		info.x = x;
		info.y = y;

		int height = 0;
		String label = Stringtable.Localize(this.mLabel);

		height = DrawOptionText(label, x, y, fnt, SelectionColor(isSelected), false, 1.0, breakwidth);

		if (this.mCVar != null)
		{
			int box_x = x + spacing;
			int box_y = y;

			info.valueleft = box_x;
			info.width = 32;
			info.valueright = info.valueleft + info.width;

			screen.Clear(box_x - 1, box_y - 1, box_x + 33, box_y + OptionMenuSettings.mLinespacing * 3 / 4 + 1, 0xff454545);
			screen.Clear(box_x, box_y, box_x + 32, box_y + OptionMenuSettings.mLinespacing * 3 / 4, this.mCVar.GetInt() | 0xff000000);
		}

		if (!(this is "GenericOptionMenuItemColorPicker"))
		{
			let newitem = new("GenericOptionMenuItemColorPicker");

			String menu = "Generic" .. this.GetAction();

			newitem.Init(this.mLabel, "");
			newitem.mCVar = this.mCVar;

			item = newitem;
		}

		info.height = height;

		return info;
	}

	virtual ItemInfo DrawItem(OptionMenuItem item, int x, int y, Font fnt = null, bool isSelected = false, int breakwidth = -1)
	{
		ItemInfo info = MenuHandler.FindItem(item);
		info.x = x;
		info.y = y;

		String label = Stringtable.Localize(item.mLabel);
		info.height = DrawOptionText(label, x, y, fnt, SelectionColor(isSelected), false, 1.0, breakwidth);
		info.width = OptionWidth(label, fnt);
		info.valueleft = info.valueright = x + info.width;

		return info;
	}

	virtual ItemInfo DrawCommand(OptionMenuItem item, int x, int y, Font fnt = null, bool isSelected = false, int breakwidth = -1)
	{
		return DrawItem(item, x, y, fnt, isSelected, breakwidth);
	}

	virtual ItemInfo DrawField(OptionMenuFieldBase item, int x, int y, int spacing, Font fnt = null, bool isSelected = false)
	{
		ItemInfo info = MenuHandler.FindItem(item);
		info.x = x;
		info.y = y;

		int height = 0;
		String label = Stringtable.Localize(item.mLabel);
		bool grayed = item.mGrayCheck && !item.mGrayCheck.GetInt();

		height = DrawOptionText(label, x, y, fnt, SelectionColor(isSelected), grayed);

		info.valueleft = x + spacing;

		if (item is "OptionMenuItemTextField")
		{
			// reposition the text so that the cursor is visible when in entering mode.
			String text = OptionMenuItemTextField(item).Represent();
			int tlen = OptionWidth(text, fnt);

			info.width = tlen;
			info.valueright = info.valueleft + info.width;

			if (text.RightIndexOf(Menu.OptionFont().GetCursor()) == text.Length() - 1)
			{
				if (Menu.MenuTime() % 40 < 20) { text.DeleteLastCharacter(); }
			}

			if (item is "os_SearchField")
			{
				height = max(DrawValue(text, fnt.StringWidth(label), y, spacing, fnt, ValueColor(), grayed), height);
			}
			else
			{
				height = max(DrawValue(text, x, y, spacing, fnt, ValueColor(), grayed), height);
			}
		}
		else
		{
			String text = item.Represent();

			info.width = OptionWidth(text, fnt);
			info.valueright = info.valueleft + info.width;

			height = max(DrawValue(text, x, y, spacing, fnt, ValueColor(), grayed), height);
		}

		info.height = height;

		return info;
	}

	virtual ItemInfo DrawJoyConfigMenu(OptionMenuItemJoyConfigMenu item, int x, int y, int spacing, Font fnt = null, bool isSelected = false, int breakwidth = -1)
	{
		ItemInfo info = MenuHandler.FindItem(item);
		info.x = x;
		info.y = y;

		int height = 0;
		String label = Stringtable.Localize(item.mLabel);
		height = max(DrawOptionText(label, x, y, fnt, SelectionColor(isSelected), false, 1.0, breakwidth), height);

		info.width = OptionWidth(label, fnt);
		info.valueleft = info.valueright = x + info.width;

		if (!(item is "GenericOptionMenuItemJoyConfigMenu"))
		{
			let newitem = new("GenericOptionMenuItemJoyConfigMenu");

			String menu = item.GetAction();
			menu = menuprefix .. menu;

			newitem.Init(item.mLabel, item.mJoy);

			int i = mDesc.mItems.Find(OptionMenuItem(item));
			mDesc.mItems[i] = newitem;
		}

		info.height = height;

		return info;
	}

	virtual ItemInfo DrawSubmenu(OptionMenuItemSubmenu item, int x, int y, int spacing, Font fnt = null, bool isSelected = false, int breakwidth = -1)
	{
		ItemInfo info = MenuHandler.FindItem(item);
		info.x = x;
		info.y = y;

		int height = 0;
		String label = Stringtable.Localize(item.mLabel);
		height = max(DrawOptionText(label, x, y, fnt, SelectionColor(isSelected), false, 1.0, breakwidth), height);

		info.width = OptionWidth(label, fnt);
		info.valueleft = info.valueright = x + info.width;

		if (!(item is "GenericOptionMenuItemSubmenu"))
		{
			let newitem = new("GenericOptionMenuItemSubmenu");

			String menu = item.GetAction();

			if (
				menu ~== "NewPlayerMenu" ||
				menu ~== "JoystickConfigMenu" ||
				menu ~== "GameplayOptions" ||
				menu ~== "DeathmatchOptions" ||
				menu ~== "CoopOptions" ||
				menu ~== "CompatibilityOptions" ||
				menu ~== "CompatActorMenu" ||
				menu ~== "CompatDehackedMenu" ||
				menu ~== "CompatMapMenu" ||
				menu ~== "CompatPhysicsMenu" ||
				menu ~== "CompatRenderMenu" ||
				menu ~== "CompatSoundMenu" ||
				menu ~== "GLTextureGLOptions" ||
				menu ~== "ReverbEdit" ||
				menu ~== "ReverbSelect" ||
				menu ~== "ReverbSave"
			)
			{
				menu = menuprefix .. menu;
			}

			newitem.Init(item.mLabel, menu, OptionMenuItemSubmenu(item).mParam, item.mCentered);

			int i = mDesc.mItems.Find(OptionMenuItem(item));
			mDesc.mItems[i] = newitem;
		}

		info.height = height;

		return info;
	}

	virtual void DrawCursor(int x, int y)
	{
		double cursoralpha = sin(Menu.MenuTime() * 10) / 2 + 0.5;
		screen.DrawText(NewSmallFont, SelectionColor(true), x, y, "►", DTA_Alpha, cursoralpha * alpha, DTA_CleanNoMove_1, true, DTA_ClipBottom, bottomclip);
	}

	virtual void DrawScrollArrows(int x, int ytop, int ybottom)
	{
		if (CanScrollUp)
		{
			screen.DrawText(NewSmallFont, SelectionColor(true), x, ytop, "▲", DTA_Alpha, alpha);
		}
		if (CanScrollDown)
		{
			screen.DrawText(NewSmallFont, SelectionColor(true), x, ybottom, "▼", DTA_Alpha, alpha);
		}
	}

	virtual int TextColor()
	{
		return OptionMenuSettings.mFontColor;
	}

	virtual int ValueColor()
	{
		return OptionMenuSettings.mFontColorValue;
	}

	virtual int SelectionColor(bool selected = false)
	{
		if (selected) { return OptionMenuSettings.mFontColorSelection; }
		return OptionMenuSettings.mFontColor;
	}

	virtual int TitleColor()
	{
		return OptionMenuSettings.mTitleColor;
	}

	virtual int HighlightColor()
	{
		return OptionMenuSettings.mFontColorHighlight;
	}
}

class GenericOptionMenuItemSubmenu : OptionMenuItemSubmenu {}

class GenericOptionMenuItemJoyConfigMenu : OptionMenuItemJoyConfigMenu {}

class GenericOptionMenuItemColorPicker : OptionMenuItemColorPicker
{
	override bool Activate()
	{
		if (mCVar != null)
		{
			Menu.MenuSound("menu/choose");
			
			// This code is a bit complicated because it should allow subclassing the
			// colorpicker menu.
			// New color pickers must inherit from the internal one to work here.
			
			let desc = MenuDescriptor.GetDescriptor('ColorpickerMenu');
			if (desc != NULL && (desc.mClass == null || desc.mClass is "ColorPickerMenu"))
			{
				let odesc = OptionMenuDescriptor(desc);
				if (odesc != null)
				{
					let cls = desc.mClass;
					if (cls == null) cls = "ColorpickerMenu";
					let picker = ColorpickerMenu(new(cls));
					picker.Init(Menu.GetCurrentMenu(), mLabel, odesc, mCVar);
					picker.ActivateMenu();
					return true;
				}
			}
		}
		return false;
	}
}

class GenericNewPlayerMenu : NewPlayerMenu
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));

		mPlayerDisplay.Drawer(false);
		
		int x = screen.GetWidth()/(CleanXfac_1*2) + PLAYERDISPLAY_X + PLAYERDISPLAY_W/2;
		int y = PLAYERDISPLAY_Y + PLAYERDISPLAY_H + 5;
		String str = Stringtable.Localize("$PLYRMNU_PRESSSPACE");
		screen.DrawText (NewSmallFont, Font.CR_GOLD, x - NewSmallFont.StringWidth(str)/2, y, str, DTA_VirtualWidth, CleanWidth_1, DTA_VirtualHeight, CleanHeight_1, DTA_KeepRatio, true);
		str = Stringtable.Localize(mRotation ? "$PLYRMNU_SEEFRONT" : "$PLYRMNU_SEEBACK");
		y += NewSmallFont.GetHeight();
		screen.DrawText (NewSmallFont, Font.CR_GOLD,x - NewSmallFont.StringWidth(str)/2, y, str, DTA_VirtualWidth, CleanWidth_1, DTA_VirtualHeight, CleanHeight_1, DTA_KeepRatio, true);
	}
}

class GenericJoystickConfigMenu : JoystickConfigMenu
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));
	}
}

class GenericGameplayMenu : GameplayMenu
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));

		String s = String.Format("dmflags = %d\ndmflags2 = %d", dmflags, dmflags2);
		screen.DrawText (OptionFont(), OptionMenuSettings.mFontColorValue, 40, screen.GetHeight() - OptionFont().GetHeight() * 2.5, s);
	}
}

class GenericCompatibilityMenu : CompatibilityMenu
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));

		String s = String.Format("compatflags = %d\ncompatflags2 = %d", compatflags, compatflags2);
		screen.DrawText (OptionFont(), OptionMenuSettings.mFontColorValue, 40, screen.GetHeight() - OptionFont().GetHeight() * 2.5, s);
	}
}

class GenericGLTextureGLOptions : GLTextureGLOptions
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));
	}
}

class GenericReverbEdit : ReverbEdit
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));
	}
}

class GenericReverbSelect : ReverbSelect
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));
	}
}

class GenericReverbSave : ReverbSave
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));
	}
}

class GenericColorPickerMenu : ColorPickerMenu
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));

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
	}
}

class GenericOS_Menu : OS_Menu
{
	override void Drawer()
	{
		GenericOptionMenu.Draw(self, "GenericOptionMenu", 20, 20, Font.GetFont("BigFont"));
	}
}