# Crest Discount Tracker

## Overview
Crest Discount Tracker is a World of Warcraft addon that helps players track their eligibility for Warband Crest discounts in The War Within expansion. The addon analyzes your currently equipped gear and shows which tier of discount you qualify for based on your item levels.

## Features
- Displays item level information for all equipped gear slots
- Calculates your eligibility for Warband Crest discounts
- Shows how many more item levels you need to reach the next tier
- Identifies your lowest item level slot to help you prioritize upgrades
- Color-coded status bars to easily see your tier progress
- Clean, organized UI with detailed tooltips
- **NEW in v2.0**: Resizable UI window for better customization
- **NEW in v2.0**: Debug tab for troubleshooting and advanced information
- **NEW in v2.0**: Persistent tracking of highest item levels across sessions

## Architecture
The addon is built using SOLID principles for better maintainability:

1. **SlotManager**: Handles slot data and mapping
2. **ItemLevelService**: Retrieves item level data from the game
3. **TierCalculator**: Calculates tier eligibility and requirements
4. **DataCollector**: Collects and processes slot data
5. **UIFactory**: Creates UI elements
6. **TooltipManager**: Manages tooltip functionality
7. **UIController**: Updates the UI with data
8. **CrestDiscountTracker**: Main addon controller

## Usage
The addon provides a simple interface with the following commands:

- `/cdt` - Opens the Crest Discount Tracker window
- `/cdt debug` - Opens the Crest Discount Tracker window with the debug tab active
- `/cdt close` - Closes the addon window
- `/crestdiscounttracker` - Alternative to `/cdt`

## UI Features

### Main Tab
The main tab displays your current item level information and discount eligibility:
- Summary section showing average item level, lowest slot, and current discount tier
- Table of all gear slots with current and highest recorded item levels
- Color-coded status bars indicating tier progress
- Resizable window with drag handle in the bottom-right corner

### Debug Tab
The debug tab provides detailed information for troubleshooting:
- Addon information (current target slot, frame size, etc.)
- Saved highest item levels for each slot
- Slot mappings showing internal IDs
- WoW inventory slot information with equipped items
- Current slot data with detailed item level information

## Highest Item Level Tracking
The addon tracks the highest item level you've had in each slot, even if you're not currently wearing that item. This data is:
- Saved between game sessions
- Updated automatically when you equip new items
- Updated when you upgrade existing items
- Used to calculate your tier eligibility

## Warband Crest Tiers
The addon tracks your eligibility for the following tiers:

1. **Gilded of the Undermine** (675+ item level) - 33% discount
2. **Runed of the Undermine** (662+ item level) - 33% discount
3. **Carved of the Undermine** (649+ item level) - 33% discount
4. **Weathered of the Undermine** (636+ item level) - 33% discount

## Available Slots
head, neck, shoulder, back, chest, waist, legs, feet, wrist, hands, finger1, finger2, trinket1, trinket2, mainhand, offhand

## Requirements
- World of Warcraft: The War Within
- Works best on Retail WoW

## Installation
1. Download the addon
2. Extract the folder to your World of Warcraft\_retail_\Interface\AddOns directory
3. Ensure the folder is named "CrestDiscountTracker"
4. Restart World of Warcraft or reload your UI (/reload)
5. The addon will appear in your addon list with its icon

## Screenshots

<details>
  <summary><strong>Main Tab Screenshot (Click to expand)</strong></summary>
  
  ![Main Tab](screenshots/crest-discount-tracker-ui-v2.png)
</details>

<details>
  <summary><strong>Debug Tab Screenshot (Click to expand)</strong></summary>
  
  ![Debug Tab](screenshots/crest-discount-tracker-ui-v2-debug.png)
</details>

## Author
Paul Gower

## Version
2.0.0

## Changelog
### v2.0.0
- Added resizable UI window with minimum and maximum size constraints
- Added debug tab with detailed information for troubleshooting
- Added persistent tracking of highest item levels across sessions
- Fixed slot ordering to correctly position the back slot as slot 4
- Renumbered mainhand and offhand slots to 15 and 16 respectively
- Improved UI layout and responsiveness
- Added custom tab system for better compatibility across WoW versions

### v1.0.0
- Initial release with basic functionality
- Display of item level information for all equipped gear slots
- Calculation of eligibility for Warband Crest discounts 