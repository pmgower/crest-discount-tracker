-- DataCollector.lua - Responsible for collecting and processing slot data
local _, addon = ...
local SlotManager = addon.Core.SlotManager
local ItemLevelService = addon.Services.ItemLevelService
local TierCalculator = addon.Services.TierCalculator

local DataCollector = {}
addon.Data.DataCollector = DataCollector

function DataCollector:CollectSlotData(targetSlot)
    local slotData = {}
    local summaryData = {
        totalSlots = 0,
        totalItemLevel = 0,
        eligibleSlots = 0,
        lowestSlot = "none",
        lowestItemLevel = 999
    }
    
    -- Process all slots if viewing all, or just the target slot
    local slotsToProcess = {}
    if targetSlot == "all" then
        slotsToProcess = SlotManager:GetAllSlots()
    elseif SlotManager:GetSlotID(targetSlot) then
        slotsToProcess = {[targetSlot] = SlotManager:GetSlotID(targetSlot)}
    else
        return nil, "Error: Invalid slot name."
    end
    
    -- Process slots
    for slotName, slotID in pairs(slotsToProcess) do
        -- Skip shirt and tabard slots
        if slotID ~= 18 and slotID ~= 19 then
            -- Get slot info
            local name = SlotManager:GetSlotName(slotName)
            local currentLevel = ItemLevelService:GetCurrentItemLevel(slotID)
            local highestLevel = ItemLevelService:GetHighestRecordedLevel(slotID)
            
            -- Use the higher of current or highest for tier calculations
            local effectiveLevel = math.max(currentLevel, highestLevel)
            
            -- Store data
            table.insert(slotData, {
                slotName = slotName,
                slotID = slotID,
                name = name,
                currentLevel = currentLevel,
                highestLevel = highestLevel,
                effectiveLevel = effectiveLevel
            })
            
            -- Track summary data
            if effectiveLevel > 0 then
                summaryData.totalSlots = summaryData.totalSlots + 1
                summaryData.totalItemLevel = summaryData.totalItemLevel + effectiveLevel
                
                if effectiveLevel < summaryData.lowestItemLevel then
                    summaryData.lowestItemLevel = effectiveLevel
                    summaryData.lowestSlot = name
                end
            end
            
            local _, _, isEligible = TierCalculator:GetTierInfo(effectiveLevel)
            if isEligible then
                summaryData.eligibleSlots = summaryData.eligibleSlots + 1
            end
        end
    end
    
    -- Sort by slot ID
    table.sort(slotData, function(a, b)
        return a.slotID < b.slotID
    end)
    
    return slotData, summaryData
end 