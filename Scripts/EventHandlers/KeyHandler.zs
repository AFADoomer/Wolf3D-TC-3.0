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
 
class KeyHandler : EventHandler
{
	ui int gooberscount;
	ui int ilmcount, batcount;
	ui bool tabdown;
	ui ClassicMessageBox msg;

	bool cheatsenabled;

	override bool InputProcess(InputEvent e)
	{
		if (e.Type == InputEvent.Type_KeyDown)
		{
			if (msg) { msg.Close(); }

			switch (e.KeyScan)
			{
				case InputEvent.Key_F1:
					if (Game.IsSod() || GameHandler.CheckEpisode(allowunfiltered:false)) { Menu.SetMenu("BossScreen"); }
					else { Menu.SetMenu("HelpMenu"); }
					return true;
					break;
				case InputEvent.Key_LShift:
				case InputEvent.Key_LAlt:
				case InputEvent.Key_Backspace:
					if (goobers && !cheatsenabled) { gooberscount++; }
					break;
				case InputEvent.Key_Tab:
					if (goobers && cheatsenabled)
					{
						tabdown = true;
						return true;
					}
				default:
					break;
			}

			switch (e.KeyChar)
			{
				case 97: // A
				case 98: // B
					batcount++;
					break;
				case 101: // E
					if (tabdown)
					{
						Exit_Normal(0);
						return true;
					}
					break;
				case 103: // G
					if (tabdown)
					{
						String text;
						if (players[consoleplayer].cheats & CF_GODMODE2 || players[consoleplayer].cheats & CF_GODMODE) { text = StringTable.Localize("$CHEAT_GOD_OFF"); }
						else { text = StringTable.Localize("$CHEAT_GOD_ON"); }

						msg = ClassicMessageBox.PrintMessage(text, width:12, height:2, align:2);

						SendNetworkEvent("godmode");
						return true;
					}
					break;
				case 105: // I
					if (tabdown)
					{
						String text = StringTable.Localize("$CHEAT_ITEMS");
						msg = ClassicMessageBox.PrintMessage(text, width:12, height:3, align:2);

						SendNetworkEvent("items");
						return true;
						break;
					}
				case 108: // L
				case 109: // M
					ilmcount++;
					break;
				case 113: // Q
					if (tabdown)
					{
						Menu.SetMenu("QuitMenu");
						return true;
					}
					break;
				case 116: // T
					batcount++;
					break;
				default:
					break;
			}
		}
		else if (e.Type == InputEvent.Type_KeyUp)
		{
			switch (e.KeyScan)
			{
				case InputEvent.Key_LShift:
				case InputEvent.Key_LAlt:
				case InputEvent.Key_Backspace:
					if (goobers) { gooberscount--; }
					break;
				case InputEvent.Key_Tab:
					if (goobers && cheatsenabled) { tabdown = false; }
				default:
					break;
			}

			switch (e.KeyChar)
			{
				case 97:
				case 98:
				case 116:
					batcount--;
					break;
				case 105:
				case 108:
				case 109:
					ilmcount--;
					break;
				default:
					break;
			}
		}

		if (gooberscount == 3)
		{
			String text = StringTable.Localize("$GOOBERS");
			msg = ClassicMessageBox.PrintMessage(text, "BG_", 0x8c8c8c, 1);

			SendNetworkEvent("cheatsenabled");

			return true;
		}

		if (ilmcount == 3)
		{
			String text = StringTable.Localize("$CHEAT_ILM");
			msg = ClassicMessageBox.PrintMessage(text, "BG_", 0x8c8c8c, 1);

			SendNetworkEvent("ilm");

			return true;
		}

		if (batcount == 3)
		{
			String text = StringTable.Localize("$CHEAT_BAT");
			msg = ClassicMessageBox.PrintMessage(text, "BG_", 0x8c8c8c, 1);

			return true;
		}

		return false;
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		let mo = players[e.Player].mo;

		if (sv_cheats || (!netgame && !deathmatch))
		{
			if (e.Name == "ilm")
			{
				if (mo)
				{
					mo.GiveInventory("YellowKey", 1);
					mo.GiveInventory("BlueKey", 1);
					mo.GiveInventory("WolfClip", 99);
					mo.health = 100;

					mo.TakeInventory("Score", 0x7FFFFFFF);
				}
			}
			else if (e.Name == "cheatsenabled")
			{
				cheatsenabled = true;
			}
			else if (cheatsenabled)
			{
				if (e.Name == "godmode")
				{
					players[e.Player].cheats ^= CF_GODMODE2;
				}
				else if (e.Name == "items")
				{
					mo.GiveInventory("Score", 100000);
					mo.health = 100;
					mo.GiveInventory("WolfClip", 99);

					class<Weapon> wpn = "WolfMachineGun";

					if (mo.FindInventory(wpn)) { wpn = "WolfChaingun"; }

					mo.GiveInventory(wpn, 1);

					let current = Weapon(mo.Findinventory(wpn));
					if (mo.player.ReadyWeapon != current) { mo.player.PendingWeapon = current; }
				}
			}
		}
	}
}