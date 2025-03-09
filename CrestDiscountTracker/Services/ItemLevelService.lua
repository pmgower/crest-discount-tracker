-- ItemLevelService.lua - Responsible for retrieving item level data
local _, addon = ...

local ItemLevelService = {}
addon.Services.ItemLevelService = ItemLevelService

-- Map our internal slot IDs to WoW's inventory slot IDs
local function GetInventorySlotID(internalSlotID)
    -- WoW's inventory slot IDs
    local inventorySlotIDs = {
        [1] = 1,  -- Head
        [2] = 2,  -- Neck
        [3] = 3,  -- Shoulder
        [4] = 15, -- Back
        [5] = 5,  -- Chest
        [6] = 6,  -- Waist
        [7] = 7,  -- Legs
        [8] = 8,  -- Feet
        [9] = 9,  -- Wrist
        [10] = 10, -- Hands
        [11] = 11, -- Finger1
        [12] = 12, -- Finger2
        [13] = 13, -- Trinket1
        [14] = 14, -- Trinket2
        [15] = 16, -- MainHand
        [16] = 17  -- OffHand
    }
    
    return inventorySlotIDs[internalSlotID] or internalSlotID
end

-- Initialize saved variables
function ItemLevelService:Initialize()
    -- Create saved variables if they don't exist
    if not CrestDiscountTrackerDB then
        CrestDiscountTrackerDB = {
            highestItemLevels = {}
        }
    end
    
    -- Ensure the highestItemLevels table exists
    if not CrestDiscountTrackerDB.highestItemLevels then
        CrestDiscountTrackerDB.highestItemLevels = {}
    end
    
    -- Register for events to update highest item levels
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            ItemLevelService:UpdateAllHighestItemLevels()
        end
    end)
end

-- Update highest item levels for all slots
function ItemLevelService:UpdateAllHighestItemLevels()
    for internalSlotID = 1, 16 do
        local inventorySlotID = GetInventorySlotID(internalSlotID)
        local currentLevel = self:GetCurrentItemLevel(internalSlotID)
        
        -- Update highest level if current is higher
        if currentLevel > 0 then
            self:UpdateHighestItemLevel(inventorySlotID, currentLevel)
        end
    end
end

-- Update highest item level for a specific slot
function ItemLevelService:UpdateHighestItemLevel(inventorySlotID, currentLevel)
    -- Initialize if not exists
    if not CrestDiscountTrackerDB.highestItemLevels[inventorySlotID] then
        CrestDiscountTrackerDB.highestItemLevels[inventorySlotID] = 0
    end
    
    -- Update if current is higher
    if currentLevel > CrestDiscountTrackerDB.highestItemLevels[inventorySlotID] then
        CrestDiscountTrackerDB.highestItemLevels[inventorySlotID] = currentLevel
        
        -- Debug output
        if addon.CrestDiscountTracker and addon.CrestDiscountTracker.displayFrame and addon.CrestDiscountTracker.displayFrame.debugText then
            local debugInfo = addon.CrestDiscountTracker.displayFrame.debugText:GetText() or ""
            debugInfo = debugInfo .. "\nUpdated highest item level for slot " .. inventorySlotID .. " to " .. currentLevel
            addon.CrestDiscountTracker.displayFrame.debugText:SetText(debugInfo)
        end
    end
end

function ItemLevelService:GetCurrentItemLevel(slotID)
    local inventorySlotID = GetInventorySlotID(slotID)
    local slotItem = GetInventoryItemLink("player", inventorySlotID)
    
    if slotItem then
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
        
        -- Update highest item level if this is higher
        if itemLevel and itemLevel > 0 then
            self:UpdateHighestItemLevel(inventorySlotID, itemLevel)
        end
        
        return itemLevel or 0
    else
        return 0
    end
end

function ItemLevelService:GetHighestRecordedLevel(slotID)
    local inventorySlotID = GetInventorySlotID(slotID)
    
    -- Try to use GetHighestItemLevel API if available (added in patch 10.1.5)
    if C_Item and C_Item.GetHighestItemLevel then
        local success, itemLocation = pcall(function() 
            return ItemLocation:CreateFromEquipmentSlot(inventorySlotID) 
        end)
        
        if success and itemLocation and C_Item.DoesItemExist(itemLocation) then
            local highestItemLevel = C_Item.GetHighestItemLevel(itemLocation)
            if highestItemLevel and highestItemLevel > 0 then
                -- Update our saved variable if API reports higher
                self:UpdateHighestItemLevel(inventorySlotID, highestItemLevel)
                return highestItemLevel
            end
        end
    end
    
    -- Get current item level
    local currentLevel = self:GetCurrentItemLevel(slotID)
    
    -- Get saved highest level
    local savedHighestLevel = 0
    if CrestDiscountTrackerDB and CrestDiscountTrackerDB.highestItemLevels and CrestDiscountTrackerDB.highestItemLevels[inventorySlotID] then
        savedHighestLevel = CrestDiscountTrackerDB.highestItemLevels[inventorySlotID]
    end
    
    -- Return the higher of current and saved highest
    return math.max(currentLevel, savedHighestLevel)
end 