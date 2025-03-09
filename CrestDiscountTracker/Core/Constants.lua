-- Constants.lua - Define addon-wide constants
local _, addon = ...

addon.Core.CONSTANTS = {
    TIERS = {
        { level = 675, name = "Gilded of the Undermine", discount = "33%" },
        { level = 662, name = "Runed of the Undermine", discount = "33%" },
        { level = 649, name = "Carved of the Undermine", discount = "33%" },
        { level = 636, name = "Weathered of the Undermine", discount = "33%" },
    },
    COLORS = {
        GOLD = { r = 1, g = 0.84, b = 0 },
        PURPLE = { r = 0.6, g = 0.6, b = 1 },
        TEAL = { r = 0, g = 0.7, b = 0.7 },
        GREEN = { r = 0, g = 0.7, b = 0 },
        RED = { r = 1, g = 0, b = 0 },
        YELLOW = { r = 1, g = 1, b = 0 },
        WHITE = { r = 1, g = 1, b = 1 },
    }
} 