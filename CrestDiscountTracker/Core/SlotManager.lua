-- SlotManager.lua - Responsible for slot data and mapping
local _, addon = ...

local SlotManager = {}
addon.Core.SlotManager = SlotManager

SlotManager.slots = {
    ["head"] = 1,
    ["neck"] = 2,
    ["shoulder"] = 3,
    ["back"] = 4,
    ["chest"] = 5,
    ["waist"] = 6,
    ["legs"] = 7,
    ["feet"] = 8,
    ["wrist"] = 9,
    ["hands"] = 10,
    ["finger1"] = 11,
    ["finger2"] = 12,
    ["trinket1"] = 13,
    ["trinket2"] = 14,
    ["mainhand"] = 15,
    ["offhand"] = 16
}

SlotManager.slotNames = {
    ["head"] = "Head",
    ["neck"] = "Neck",
    ["shoulder"] = "Shoulder",
    ["chest"] = "Chest",
    ["waist"] = "Waist",
    ["legs"] = "Legs",
    ["feet"] = "Feet",
    ["wrist"] = "Wrist",
    ["hands"] = "Hands",
    ["finger1"] = "Finger 1",
    ["finger2"] = "Finger 2",
    ["trinket1"] = "Trinket 1",
    ["trinket2"] = "Trinket 2",
    ["back"] = "Back",
    ["mainhand"] = "Main Hand",
    ["offhand"] = "Off Hand"
}

function SlotManager:GetSlotID(slotName)
    return self.slots[slotName]
end

function SlotManager:GetSlotName(slotName)
    return self.slotNames[slotName] or slotName
end

function SlotManager:GetAllSlots()
    return self.slots
end 