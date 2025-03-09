# Crest Discount Tracker

A World of Warcraft addon that helps players track their eligibility for Warband Crest discounts in The War Within expansion.

![Main Tab](screenshots/crest-discount-tracker-ui-v2.png)

## What It Does

Crest Discount Tracker analyzes your gear and shows which tier of Warband Crest discount you qualify for based on your item levels. It helps you:

- See your current discount tier eligibility at a glance
- Identify which gear slots need upgrading to reach the next tier
- Track the highest item level you've had in each slot (even if not currently equipped)
- Visualize your progress toward the next discount tier

## Discount Tiers

The addon tracks your eligibility for these Warband Crest discount tiers:

| Tier | Name | Required Item Level | Discount |
|------|------|---------------------|----------|
| 1 | Gilded of the Undermine | 675+ | 33% |
| 2 | Runed of the Undermine | 662+ | 33% |
| 3 | Carved of the Undermine | 649+ | 33% |
| 4 | Weathered of the Undermine | 636+ | 33% |

## Interface

### Main Tab
![Main Tab](screenshots/crest-discount-tracker-ui-v2.png)

The main tab shows:
- **Summary Section**:
  - Equipped, Overall, and PvP item levels
  - Your lowest item level slot (upgrade priority)
  - Current discount tier eligibility
  - Comprehensive achievement tracking:
    - Discount tier eligibility progress for all tiers
    - Outgrown crest achievement progress
  - Color-coded progress bars showing completion status
  - Item levels needed to reach each achievement
- **Gear Table**:
  - All equipment slots with current and highest recorded item levels
  - Color-coded status bars showing tier progress
  - Highlighting for slots close to reaching next tier
- **Resizable UI**:
  - Default size of 500×1000 pixels (adjusts to screen size)
  - Resizable with minimum height of 400 pixels
  - Maximum height dynamically adjusts to content
  - Drag handle in the bottom-right corner

### Debug Tab
![Debug Tab](screenshots/crest-discount-tracker-ui-v2-debug.png)

The debug tab provides detailed information for troubleshooting:
- Addon status information
- Saved highest item levels for each slot
- Slot mappings and inventory information
- Current slot data with detailed item level information

## Commands

- `/cdt` - Opens the main window
- `/cdt debug` - Opens with the debug tab active
- `/cdt close` - Closes the window
- `/crestdiscounttracker` - Alternative to `/cdt`

## Installation

1. Download the addon
2. Extract to `World of Warcraft\_retail_\Interface\AddOns`
3. Ensure the folder is named "CrestDiscountTracker"
4. Restart WoW or reload your UI (`/reload`)

## Requirements

- World of Warcraft: The War Within
- Retail WoW client

## Author & Version

**Author:** Paul Gower  
**Current Version:** 2.1.0

## Changelog

<details>
  <summary><strong>Click to expand</strong></summary>

### v2.1.0
- Refactored into modular file structure
- Fixed error with unknown event "ITEM_UPGRADE_MASTER_UPDATE"
- Fixed nil value error when calling GetInventorySlotID function
- Added proper inventory slot ID mapping
- Improved event handling
- Enhanced debug information display

### v2.0.0
- Added resizable UI window
- Added debug tab for troubleshooting
- Added persistent tracking of highest item levels
- Fixed slot ordering and numbering
- Improved UI layout and responsiveness
- Added custom tab system for better compatibility

### v1.0.0
- Initial release with basic functionality
</details>

## Future Plans

Future updates may include:
- Upgrade cost tracking and optimization
- Upgrade material tracking
- Gear set optimization suggestions
- Upgrade history tracking
- Vault reward evaluation 