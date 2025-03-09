-- UIController.lua - Responsible for updating the UI with data
local _, addon = ...
local CONSTANTS = addon.Core.CONSTANTS
local TierCalculator = addon.Services.TierCalculator

local UIController = {}
addon.UI.UIController = UIController

function UIController:UpdateSummary(frame, summaryData)
    if summaryData.totalSlots > 0 then
        -- Use WoW's built-in function to get average item level
        local avgEquippedItemLevel, avgItemLevel, avgPvpItemLevel = GetAverageItemLevel()
        -- Round to nearest integer
        avgEquippedItemLevel = math.floor(avgEquippedItemLevel + 0.5)
        avgItemLevel = math.floor(avgItemLevel + 0.5)
        avgPvpItemLevel = math.floor(avgPvpItemLevel + 0.5)
        
        local tierName, discount, _ = TierCalculator:GetTierInfo(summaryData.lowestItemLevel)
        
        -- Determine next tier needed
        local nextTierLevel = TierCalculator:GetNextTierLevel(summaryData.lowestItemLevel)
        
        -- Create a visual progress indicator
        local progressText = ""
        if summaryData.lowestItemLevel < CONSTANTS.TIERS[1].level then
            local currentTierLevel = 0
            local nextTierName = ""
            
            -- Find current tier level and next tier name
            for i, tier in ipairs(CONSTANTS.TIERS) do
                if summaryData.lowestItemLevel >= tier.level then
                    -- Already at this tier
                    currentTierLevel = tier.level
                    if i > 1 then
                        nextTierName = CONSTANTS.TIERS[i-1].name
                        nextTierLevel = CONSTANTS.TIERS[i-1].level
                    end
                    break
                elseif i == #CONSTANTS.TIERS then
                    -- Below lowest tier
                    nextTierName = tier.name
                    nextTierLevel = tier.level
                end
            end
            
            -- Calculate progress percentage
            local progress = 0
            if currentTierLevel > 0 then
                local range = nextTierLevel - currentTierLevel
                local current = summaryData.lowestItemLevel - currentTierLevel
                progress = math.floor((current / range) * 100)
            end
            
            -- Create progress bar visual
            local barWidth = 20
            local filledBars = math.floor((progress / 100) * barWidth)
            local progressBar = "|cFF00CCFF["
            
            for i = 1, barWidth do
                if i <= filledBars then
                    progressBar = progressBar .. "="
                else
                    progressBar = progressBar .. "-"
                end
            end
            
            progressBar = progressBar .. "]|r " .. progress .. "%"
            
            progressText = string.format(
                "Progress to %s: %s\n",
                nextTierName, progressBar
            )
        end
        
        local summaryInfo = string.format(
            "Item Levels:\n" ..
            "  |cFFFFD700Equipped:|r %d   |cFF00CCFF(Used for tier eligibility)|r\n" ..
            "  |cFFFFD700Overall:|r %d   |cFF888888(Including bags)|r\n" ..
            "  |cFFFFD700PvP:|r %d\n\n" ..
            "Lowest Item Level: %s (%d)\n" ..
            "Current Discount: %s (%s)\n",
            avgEquippedItemLevel, avgItemLevel, avgPvpItemLevel,
            summaryData.lowestSlot, summaryData.lowestItemLevel, tierName, discount
        )
        
        -- Add progress indicator if not at max tier
        if summaryData.lowestItemLevel < CONSTANTS.TIERS[1].level then
            summaryInfo = summaryInfo .. progressText
            
            summaryInfo = summaryInfo .. string.format(
                "Next Tier: Need %d more item levels in %s",
                nextTierLevel - summaryData.lowestItemLevel, summaryData.lowestSlot
            )
        else
            summaryInfo = summaryInfo .. "\n|cFFFFD700You've reached the highest tier!|r"
        end
        
        frame.summaryText:SetText(summaryInfo)
        
        -- Also update debug info if available
        if frame.UpdateDebugInfo then
            frame.UpdateDebugInfo()
        end
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