# CritMatic Reborn

**A modernized and enhanced version of CritMatic for World of Warcraft**

---

## About

CritMatic Reborn is a comprehensive combat tracking addon that records and displays your highest critical hits, normal hits, critical heals, and normal heals for every spell you cast. Get notified with customizable alerts and sounds whenever you break a personal record!

This is a modernized fork of the original [CritMatic](https://www.curseforge.com/wow/addons/critmatic) by **InfiniteLoopAlchemist**, updated with new features, bug fixes, and compatibility improvements for modern WoW clients.

---

## Features

### Core Functionality
- **Real-time Combat Tracking** - Monitors combat logs and records your highest hits for each spell
- **Healing Tracking** - Records highest heals and critical heals for all healing spells
- **Persistent Data** - Your records are saved between sessions and character switches
- **Spell Tooltips** - Hover over any spell to see your personal bests

### New in Reborn
- **Redesigned Settings Panel** - Clean, intuitive 6-tab organization
- **Resizable Crit Log** - Drag corners to resize, content scales automatically
- **Smart Scrollbar** - Auto-hides when not needed
- **Right-click Context Menus** - Quick access to settings and spell management
- **Spell Icons in Alerts** - Visual feedback with animated icons
- **Ignored Spells Management** - Easy UI to manage which spells to track
- **ALT-drag Positioning** - Hold ALT to move windows (prevents accidental moves)
- **Cross-version Compatibility** - Works on Retail, Classic Era, and MoP Classic

### Notifications
- **Screen Alerts** - Animated on-screen notifications for new records
- **Sound Effects** - Customizable sounds for crits, hits, and heals
- **Chat Messages** - Optional chat notifications
- **Social Sharing** - Share records with party, raid, guild, or battleground

---

## Installation

1. Download the latest release from CurseForge
2. Extract to your `World of Warcraft/_retail_/Interface/AddOns/` folder (or `_classic_` for Classic)
3. Restart WoW or type `/reload`

---

## Slash Commands

| Command | Description |
|---------|-------------|
| `/cm` or `/critmatic` | Open settings panel |
| `/cmcritlog` | Toggle Crit Log window |
| `/cmlog` | Open changelog |
| `/cmhelp` | Show all commands |
| `/cmignore <spell>` | Ignore a spell |
| `/cmignoredspells` | List ignored spells |
| `/cmremoveignoredspell <spell>` | Remove spell from ignored list |
| `/cmwipeignoredspells` | Clear all ignored spells |
| `/cmreset` | Reset all saved data |
| `/cmcritlogdefaultpos` | Reset Crit Log position |

---

## Screenshots

### Crit Log Window
![Crit Log](https://i.ibb.co/H77Tq3K/Image-11-19-23-at-10-57-AM.jpg)

### Spell Tooltips
![Tooltip](https://i.ibb.co/7k1JtPf/pvw75876.png)

---

## Settings Overview

- **General** - Display options, notification toggles, startup settings
- **Alerts** - Timing, message formats, font/color customization
- **Sounds** - Sound selection for each record type
- **Sharing** - Social broadcast settings
- **Ignored** - Manage spells excluded from tracking
- **Advanced** - Changelog styling, data management, slash command reference

---

## Compatibility

| Client | Interface Version | Status |
|--------|-------------------|--------|
| Retail (The War Within) | 11.0.2 | Supported |
| Classic Era / Hardcore | 1.15.5 | Supported |
| MoP Remix / Classic | 5.4.1 | Supported |

---

## Credits

- **Original Addon**: [CritMatic](https://www.curseforge.com/wow/addons/critmatic) by **InfiniteLoopAlchemist**
- **Reborn Maintainer**: Croome
- **Libraries**: Ace3, LibSharedMedia-3.0, AceGUI-3.0-SharedMediaWidgets

---

## License

This project is licensed under the GNU General Public License v3.0.

---

## Changelog

See [CHANGE_LOG.md](CHANGE_LOG.md) for version history.
