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
        
        return itemLevel or 0
    else
        return 0
    end
end

function ItemLevelService:GetHighestRecordedLevel(slotID)
    local inventorySlotID = GetInventorySlotID(slotID)
    
    -- First try to use the current item level API (most reliable in current retail)
    if C_Item and C_Item.GetCurrentItemLevel and ItemLocation then
        -- Create an ItemLocation from the equipment slot
        local success, itemLocation = pcall(function() 
            return ItemLocation:CreateFromEquipmentSlot(inventorySlotID) 
        end)
        
        if success and itemLocation and C_Item.DoesItemExist(itemLocation) then
            local itemLevel = C_Item.GetCurrentItemLevel(itemLocation)
            if itemLevel and itemLevel > 0 then
                return itemLevel
            end
        end
    end
    
    -- Fallback to GetDetailedItemLevelInfo for the current item
    local currentItemLink = GetInventoryItemLink("player", inventorySlotID)
    if currentItemLink then
        local _, _, _, itemLevel = GetDetailedItemLevelInfo(currentItemLink)
        if itemLevel and itemLevel > 0 then
            return itemLevel
        end
    end
    
    -- Last resort - try to get from tooltip
    if currentItemLink then
        local tip = CreateFrame("GameTooltip", "CDTScanningTooltip", nil, "GameTooltipTemplate")
        tip:SetOwner(WorldFrame, "ANCHOR_NONE")
        tip:SetHyperlink(currentItemLink)
        
        -- Scan tooltip lines for item level
        for i = 2, tip:NumLines() do
            local text = _G["CDTScanningTooltipTextLeft"..i]:GetText()
            if text and text:match("Item Level") then
                local level = tonumber(text:match("Item Level (%d+)"))
                if level and level > 0 then
                    return level
                end
            end
        end
    end
    
    return 0
end 