# CritMatic Reborn Changelog

*A modernized fork of [CritMatic](https://www.curseforge.com/wow/addons/critmatic) by InfiniteLoopAlchemist*

---

## [v0.5.1.0-release] - 01/17/2026

### TBC Anniversary Support

#### New Features
- Added TBC Classic Anniversary support (Interface 20505)
- New `CritMatic_TBC.toc` file for TBC Anniversary client

#### Bug Fixes
- Fixed `GetSpellInfo` error causing addon to fail on TBC Anniversary
- Fixed `/cm` slash command not working due to initialization errors
- CritLog.lua now uses API compatibility wrapper for spell info lookups

#### Technical Changes
- Added `IS_TBC_CLASSIC` and `IS_MOP_CLASSIC` version detection to CritMaticAPI
- CritLog.lua now properly uses CritMaticAPI wrapper for cross-version compatibility
- Improved API fallback handling for clients using `C_Spell.GetSpellInfo`

---

## [v0.5.0.0-release] - 12/16/2025

### Initial Release of CritMatic Reborn

#### New Features
- **Right-click context menu on CritMatic logo** - Quick access to settings, changelog, lock/unlock position, reset data, and hide window
- **Right-click on spell entries** - Ignore spells or delete their data directly from the crit log with hover highlight
- **Ignored Spells management in settings** - View, remove, or clear all ignored spells from the General settings tab
- **Show/Hide Crit Log in settings** - New options in General tab to show/hide and lock the crit log window
- **Spell icons in alert notifications** - Alerts now display the spell icon next to the text with bounce animation
- Added API compatibility layer for seamless support across Retail, Classic Era, and MoP Classic
- Improved tooltip caching system for better performance
- Enhanced error handling throughout the addon

#### Improvements
- **Completely redesigned Settings Panel** - Cleaner, more intuitive organization with 6 logical tabs:
  - **General** - Display, notifications, startup options
  - **Alerts** - Timing, message formats, appearance (font/colors/shadow)
  - **Sounds** - Damage and healing sounds with mute option
  - **Sharing** - Social broadcast settings with color-coded channels
  - **Ignored** - Dedicated spell management with clear instructions
  - **Advanced** - Changelog styling, data management, slash command reference
- **Crit Log window is now resizable** - Drag the corner to resize the window, content scales with window size
- **Smart scrollbar** - Scrollbar automatically hides when window is large enough to show all content
- **ALT-drag to move** - Hold ALT key while dragging to reposition the window (prevents accidental moves)
- **Reduced spacing between crit log entries** - More compact display shows more spells at once
- **Cleaner CritMatic logo** - Removed circle overlay for a cleaner look
- Updated interface versions for all WoW clients (Retail 11.0.2, Classic Era 1.15.5, MoP Classic 5.4.1)
- Modernized GCD detection using proper API calls instead of hardcoded spell IDs
- Refactored combat log event handling with better organization and maintainability
- Cleaned up redundant code and improved variable naming consistency
- Added proper documentation comments throughout the codebase
- Improved message frame handling with better animation cleanup
- Enhanced spell aggregate caching to reduce unnecessary recalculations

#### Technical Changes
- Created CritMaticAPI.lua compatibility layer for cross-version API abstraction
- Replaced deprecated GetSpellInfo calls with version-aware wrappers
- Replaced deprecated IsAddOnLoaded/GetAddOnMetadata with C_AddOns equivalents where available
- Restructured combat event parsing into modular functions
- Improved ignored spell checking performance
- Better separation of concerns in notification handling

#### Bug Fixes
- **Fixed wrong spell icons in crit log** - Icons are now stored at record time instead of looked up later, fixing issues with spells that share names across ranks/versions
- Fixed potential nil errors in spell name lookups
- Fixed tooltip lines being duplicated in some cases
- Fixed message frames not being properly cleaned up after fade

---

## [v0.4.2.8-release] - 12/25/2023


