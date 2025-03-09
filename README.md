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
The addon provides a simple interface with just two commands:

- `/cdt` - Opens the Crest Discount Tracker window
- `/cdt close` - Closes the addon window
- `/crestdiscounttracker` - Alternative to `/cdt`

## Warband Crest Tiers
The addon tracks your eligibility for the following tiers:

1. **Gilded of the Undermine** (675+ item level) - 33% discount
2. **Runed of the Undermine** (662+ item level) - 33% discount
3. **Carved of the Undermine** (649+ item level) - 33% discount
4. **Weathered of the Undermine** (636+ item level) - 33% discount

## Available Slots
head, neck, shoulder, chest, waist, legs, feet, wrist, hands, finger1, finger2, trinket1, trinket2, back, mainhand, offhand

## Requirements
- World of Warcraft: The War Within
- Works best on Retail WoW

## Author
Paul Gower

## Version
1.0.0 