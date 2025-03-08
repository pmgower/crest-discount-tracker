-- HighestItemLevel.lua (Main addon file)
local addonName, addon = ...

-- Slot mapping with ID numbers
addon.slots = {
    ["head"] = 1,
    ["neck"] = 2,
    ["shoulder"] = 3,
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
    ["back"] = 15,
    ["mainhand"] = 16,
    ["offhand"] = 17
}

-- Readable names for each slot
addon.slotNames = {
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

-- Function to get the highest ever equipped item level for a slot using alternative APIs
function addon:GetHighestEquippedLevel(slotID)
    -- Try various methods to get the highest item level
    
    local currentItemLink = GetInventoryItemLink("player", slotID)
    if currentItemLink then
        -- Use GetDetailedItemLevelInfo which is widely available
        local _, _, _, itemLevel = GetDetailedItemLevelInfo(currentItemLink)
        if itemLevel and itemLevel > 0 then
            return itemLevel
        end
    end
    
    -- Return 0 if no item or no item level found
    return 0
end

-- Function to check if addon is on Retail and has necessary APIs
function addon:CheckRetailAPIs()
    -- Check for the WoW version
    local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
    
    -- We don't need to check for C_Item API anymore since we're using GetDetailedItemLevelInfo
    return isRetail, true
end

-- Function to get current equipped item information
function addon:GetCurrentItemInfo(slotName, slotID)
    local slotItem = GetInventoryItemLink("player", slotID)
    
    if slotItem then
        -- Get basic item info
        local itemName, _, itemRarity = GetItemInfo(slotItem)
        
        -- Get item level using GetDetailedItemLevelInfo
        local _, _, _, itemLevel = GetDetailedItemLevelInfo(slotItem)
        
        -- If itemLevel is still nil or 0, try to extract it from the link directly
        if not itemLevel or itemLevel == 0 then
            -- Try to extract item level from tooltip
            local tip = CreateFrame("GameTooltip", "CDTScanningTooltip", nil, "GameTooltipTemplate")
            tip:SetOwner(WorldFrame, "ANCHOR_NONE")
            tip:SetHyperlink(slotItem)
            
            -- Scan tooltip lines for item level
            for i = 2, tip:NumLines() do
                local text = _G["CDTScanningTooltipTextLeft"..i]:GetText()
                if text and text:match("Item Level") then
                    itemLevel = tonumber(text:match("Item Level (%d+)"))
                    break
                end
            end
        end
        
        local itemQuality = ITEM_QUALITY_COLORS[itemRarity or 1]
        local coloredName = (itemQuality and itemQuality.hex or "|cFFFFFFFF")..
                           (itemName or "Unknown Item").."|r"
        
        return self.slotNames[slotName] or slotName, itemLevel or 0, coloredName
    else
        return self.slotNames[slotName] or slotName, 0, "None equipped"
    end
end

-- Function to check for specific item level thresholds
function addon:GetWarbandCrestInfo(itemLevel)
    -- Warband Crest Discount thresholds for The War Within Season 2
    if itemLevel >= 675 then
        return "Gilded of the Undermine", "33% discount", true
    elseif itemLevel >= 662 then
        return "Runed of the Undermine", "33% discount", true
    elseif itemLevel >= 649 then
        return "Carved of the Undermine", "33% discount", true
    elseif itemLevel >= 636 then
        return "Weathered of the Undermine", "33% discount", true
    else
        return "Not eligible", "No discount", false
    end
end

-- Display item level information using available methods
function addon:DisplayHighestItemLevels(targetSlot)
    -- Check if we're on retail and have the necessary APIs
    local isRetail, hasItemAPI = self:CheckRetailAPIs()
    
    -- Let the user know what we're showing
    print("|cFFFFD700===== Crest Discount Tracker =====|r")
    if not isRetail then
        print("Note: This addon works best on Retail WoW (The War Within)")
    end
    
    -- Debug info to help troubleshoot
    print("Debug: WOW_PROJECT_ID = " .. (WOW_PROJECT_ID or "nil"))
    
    if targetSlot == "all" then
        -- Display all slots
        local totalSlots = 0
        local totalItemLevel = 0
        local eligibleSlots = 0
        local lowestSlot = "none"
        local lowestItemLevel = 999
        
        -- First pass - get all item levels and find the lowest
        for slotName, slotID in pairs(self.slots) do
            -- Skip shirt and tabard slots
            if slotID ~= 4 and slotID ~= 19 then
                local name, currentLevel, currentItem = self:GetCurrentItemInfo(slotName, slotID)
                
                if currentLevel > 0 then
                    totalSlots = totalSlots + 1
                    totalItemLevel = totalItemLevel + currentLevel
                    
                    -- Track the lowest item level slot
                    if currentLevel < lowestItemLevel then
                        lowestItemLevel = currentLevel
                        lowestSlot = name
                    end
                end
                
                -- Count eligible slots for Warband Crest thresholds
                local _, _, isEligible = self:GetWarbandCrestInfo(currentLevel)
                if isEligible then
                    eligibleSlots = eligibleSlots + 1
                end
                
                -- Display the item level info
                print("|cFF00CCFF"..name.."|r: "..currentLevel.." - "..currentItem)
            end
        end
        
        -- Calculate average item level if we have items
        if totalSlots > 0 then
            local avgItemLevel = math.floor(totalItemLevel / totalSlots)
            print("\n|cFFFFD700Average Item Level:|r "..avgItemLevel)
            print("|cFFFFD700Lowest Item Level Slot:|r "..lowestSlot.." ("..lowestItemLevel..")")
            
            -- Show progress toward Warband Crest thresholds
            local tierName, discount, _ = self:GetWarbandCrestInfo(lowestItemLevel)
            print("\n|cFFFFD700Warband Crest Discount Status:|r "..tierName.." ("..discount..")")
            print("You have "..eligibleSlots.." out of 16 slots at the required item level")
        end
    elseif self.slots[targetSlot] then
        -- Display specific slot
        local slotID = self.slots[targetSlot]
        local name, currentLevel, currentItem = self:GetCurrentItemInfo(targetSlot, slotID)
        
        print("|cFFFFD700Slot Item Level: "..name.."|r")
        print("Current: "..currentLevel.." - "..currentItem)
        
        -- Show Warband Crest threshold info
        local tierName, discount, isEligible = self:GetWarbandCrestInfo(currentLevel)
        
        local statusColor = isEligible and "|cFF00FF00" or "|cFFFF0000"
        print("\n"..statusColor.."Warband Crest Status: "..tierName.." ("..discount..")|r")
        
        -- Show how much more item level is needed for next tier
        if not isEligible then
            print("You need "..tostring(636 - currentLevel).." more item levels to reach Weathered of the Undermine tier")
        elseif currentLevel < 649 then
            print("You need "..tostring(649 - currentLevel).." more item levels to reach Carved of the Undermine tier")
        elseif currentLevel < 662 then
            print("You need "..tostring(662 - currentLevel).." more item levels to reach Runed of the Undermine tier")
        elseif currentLevel < 675 then
            print("You need "..tostring(675 - currentLevel).." more item levels to reach Gilded of the Undermine tier")
        else
            print("|cFF00FF00You've reached the highest tier!|r")
        end
    else
        -- Invalid slot specified
        print("|cFFFF0000Error:|r Invalid slot name. Available slots:")
        local availableSlots = ""
        for slotName, _ in pairs(self.slots) do
            if self.slots[slotName] ~= 4 and self.slots[slotName] ~= 19 then
                availableSlots = availableSlots.." "..slotName
            end
        end
        print(availableSlots.." or 'all'")
    end
end

-- Register slash commands
SLASH_CRESTDISCOUNTTRACKER1 = "/crestdiscounttracker"
SLASH_CRESTDISCOUNTTRACKER2 = "/cdt"
SlashCmdList["CRESTDISCOUNTTRACKER"] = function(msg)
    local targetSlot = msg:lower()
    if targetSlot == "" then
        targetSlot = "all"
    end
    addon:DisplayHighestItemLevels(targetSlot)
end

-- Event handler frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FF00CrestDiscountTracker addon loaded!|r")
        print("Use |cFFFFD700/crestdiscounttracker [slot]|r or |cFFFFD700/cdt [slot]|r to check a specific slot, or |cFFFFD700/cdt all|r to check all slots.")
    end
end)