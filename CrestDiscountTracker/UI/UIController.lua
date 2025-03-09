-- UIController.lua - Responsible for updating the UI with data
local _, addon = ...
local CONSTANTS = addon.Core.CONSTANTS
local TierCalculator = addon.Services.TierCalculator

local UIController = {}
addon.UI.UIController = UIController

function UIController:UpdateSummary(frame, summaryData)
    if summaryData.totalSlots > 0 then
        local avgItemLevel = math.floor(summaryData.totalItemLevel / summaryData.totalSlots)
        local tierName, discount, _ = TierCalculator:GetTierInfo(summaryData.lowestItemLevel)
        
        -- Determine next tier needed
        local nextTierLevel = TierCalculator:GetNextTierLevel(summaryData.lowestItemLevel)
        
        local summaryInfo = string.format(
            "Average Item Level: %d\n" ..
            "Lowest Item Level: %s (%d)\n" ..
            "Current Discount: %s (%s)\n" ..
            "Eligible Slots: %d out of 16\n",
            avgItemLevel, summaryData.lowestSlot, summaryData.lowestItemLevel, tierName, discount, summaryData.eligibleSlots
        )
        
        if summaryData.lowestItemLevel < CONSTANTS.TIERS[1].level then
            summaryInfo = summaryInfo .. string.format(
                "\nNext Tier: Need %d more item levels in %s",
                nextTierLevel - summaryData.lowestItemLevel, summaryData.lowestSlot
            )
        else
            summaryInfo = summaryInfo .. "\n|cFFFFD700You've reached the highest tier!|r"
        end
        
        frame.summaryText:SetText(summaryInfo)
        
        -- Debug output
        print("|cFF00CCFF[CrestDiscountTracker Debug]|r Summary updated:")
        print(string.format("  Average Item Level: %d", avgItemLevel))
        print(string.format("  Lowest Item Level: %s (%d)", summaryData.lowestSlot, summaryData.lowestItemLevel))
        print(string.format("  Current Discount: %s (%s)", tierName, discount))
        print(string.format("  Eligible Slots: %d out of 16", summaryData.eligibleSlots))
    else
        frame.summaryText:SetText("No items equipped")
    end
end

function UIController:UpdateSlotRow(slotFrame, slotData)
    -- Update slot frame with item info
    slotFrame.slotID:SetText(slotData.slotID)
    slotFrame.slotName:SetText(slotData.name)
    slotFrame.currentLevel:SetText(slotData.currentLevel)
    slotFrame.highestLevel:SetText(slotData.highestLevel)
    
    -- Debug output
    print(string.format("|cFF00CCFF[CrestDiscountTracker Debug]|r Setting row text - ID: %s, Name: %s, Current: %s, Highest: %s",
        slotData.slotID, slotData.name, slotData.currentLevel, slotData.highestLevel))
    
    -- Determine status color based on tier eligibility
    local color, statusValue = TierCalculator:GetTierColor(slotData.effectiveLevel)
    
    slotFrame.statusBar:SetStatusBarColor(color.r, color.g, color.b)
    slotFrame.statusBar:SetValue(statusValue)
    
    -- Set the backdrop color based on how close to next tier
    local nextTierLevel = TierCalculator:GetNextTierLevel(slotData.effectiveLevel)
    local distanceToNextTier = nextTierLevel - slotData.effectiveLevel
    
    if distanceToNextTier <= 5 and distanceToNextTier > 0 then
        -- Close to next tier - highlight
        slotFrame:SetBackdropColor(0.3, 0.3, 0.1, 0.8)
        slotFrame.currentLevel:SetTextColor(CONSTANTS.COLORS.YELLOW.r, CONSTANTS.COLORS.YELLOW.g, CONSTANTS.COLORS.YELLOW.b)
        slotFrame.highestLevel:SetTextColor(CONSTANTS.COLORS.YELLOW.r, CONSTANTS.COLORS.YELLOW.g, CONSTANTS.COLORS.YELLOW.b)
    elseif slotData.effectiveLevel >= CONSTANTS.TIERS[1].level then
        -- Max tier
        slotFrame:SetBackdropColor(0.2, 0.2, 0.1, 0.8)
        slotFrame.currentLevel:SetTextColor(CONSTANTS.COLORS.GOLD.r, CONSTANTS.COLORS.GOLD.g, CONSTANTS.COLORS.GOLD.b)
        slotFrame.highestLevel:SetTextColor(CONSTANTS.COLORS.GOLD.r, CONSTANTS.COLORS.GOLD.g, CONSTANTS.COLORS.GOLD.b)
    else
        -- Normal
        slotFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
        slotFrame.currentLevel:SetTextColor(CONSTANTS.COLORS.WHITE.r, CONSTANTS.COLORS.WHITE.g, CONSTANTS.COLORS.WHITE.b)
        slotFrame.highestLevel:SetTextColor(CONSTANTS.COLORS.WHITE.r, CONSTANTS.COLORS.WHITE.g, CONSTANTS.COLORS.WHITE.b)
    end
    
    -- Setup tooltip
    addon.UI.TooltipManager:SetupRowTooltip(slotFrame, slotData)
end 