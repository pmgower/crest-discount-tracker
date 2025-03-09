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
        avgPvpItemLevel = math.floor(avgItemLevel + 0.5)
        
        local tierName, discount, _ = TierCalculator:GetTierInfo(summaryData.lowestItemLevel)
        
        -- Determine next tier needed
        local nextTierLevel = TierCalculator:GetNextTierLevel(summaryData.lowestItemLevel)
        
        -- Create tier progress indicators
        local progressText = ""
        
        -- Function to create a progress bar
        local function CreateProgressBar(progress, color)
            local barWidth = 20
            local filledBars = math.floor((progress / 100) * barWidth)
            local progressBar = "|c" .. color .. "["
            
            for i = 1, barWidth do
                if i <= filledBars then
                    progressBar = progressBar .. "="
                else
                    progressBar = progressBar .. "-"
                end
            end
            
            progressBar = progressBar .. "]|r " .. progress .. "%"
            return progressBar
        end
        
        -- Show progress for each tier
        progressText = "|cFFFFD700Achievement Progress:|r\n"
        
        -- Determine which tiers have been achieved (discount eligibility)
        local achievedTiers = {}
        for i, tier in ipairs(CONSTANTS.TIERS) do
            achievedTiers[i] = (summaryData.lowestItemLevel >= tier.level)
        end
        
        -- Define crest upgrade thresholds (these would be the max item level for each crest type)
        local crestMaxLevels = {
            [1] = 689, -- Gilded max upgrade level
            [2] = 676, -- Runed max upgrade level
            [3] = 663, -- Carved max upgrade level
            [4] = 650  -- Weathered max upgrade level
        }
        
        -- Determine which crests have been outgrown
        local outgrownCrests = {}
        for i, maxLevel in ipairs(crestMaxLevels) do
            outgrownCrests[i] = (summaryData.lowestItemLevel > maxLevel)
        end
        
        -- Generate progress bars for each tier achievement (discount eligibility)
        progressText = progressText .. "\n|cFFE6CC80Discount Tier Eligibility:|r\n"
        for i, tier in ipairs(CONSTANTS.TIERS) do
            local tierProgress = 0
            local progressBar = ""
            local nextTierThreshold = 0
            
            if achievedTiers[i] then
                -- Tier achieved - 100%
                tierProgress = 100
                progressBar = CreateProgressBar(tierProgress, "FF00FF00") -- Green
            else
                -- Calculate progress toward this tier
                if i < #CONSTANTS.TIERS then
                    -- For tiers other than the lowest
                    local prevTierLevel = CONSTANTS.TIERS[i+1].level
                    local range = tier.level - prevTierLevel
                    
                    if summaryData.lowestItemLevel < prevTierLevel then
                        -- Haven't reached previous tier yet
                        tierProgress = 0
                    else
                        -- Calculate progress between previous tier and this tier
                        local current = summaryData.lowestItemLevel - prevTierLevel
                        tierProgress = math.floor((current / range) * 100)
                    end
                else
                    -- For the lowest tier
                    local baseLevel = 600 -- Assume base level of 600 for calculation
                    local range = tier.level - baseLevel
                    local current = math.max(0, summaryData.lowestItemLevel - baseLevel)
                    tierProgress = math.floor((current / range) * 100)
                end
                
                -- Create progress bar with appropriate color
                local colorCode = "FF00CCFF" -- Default blue
                if tierProgress >= 75 then
                    colorCode = "FFFFFF00" -- Yellow for close to achievement
                end
                progressBar = CreateProgressBar(tierProgress, colorCode)
                
                -- Calculate how many more item levels needed
                nextTierThreshold = tier.level - summaryData.lowestItemLevel
            end
            
            -- Add tier info to progress text
            local tierInfo = string.format("  %s: %s", tier.name, progressBar)
            if not achievedTiers[i] and nextTierThreshold > 0 then
                tierInfo = tierInfo .. string.format(" (Need %d more)", nextTierThreshold)
            end
            progressText = progressText .. tierInfo .. "\n"
        end
        
        -- Generate progress bars for outgrown crest achievements
        progressText = progressText .. "\n|cFFE6CC80Outgrown Crest Achievements:|r\n"
        for i, tier in ipairs(CONSTANTS.TIERS) do
            local crestProgress = 0
            local progressBar = ""
            local nextThreshold = 0
            
            if outgrownCrests[i] then
                -- Crest outgrown - 100%
                crestProgress = 100
                progressBar = CreateProgressBar(crestProgress, "FF00FF00") -- Green
            else
                -- Calculate progress toward outgrowing this crest
                local maxLevel = crestMaxLevels[i]
                local prevTierLevel = i < #CONSTANTS.TIERS and CONSTANTS.TIERS[i+1].level or 600
                local range = maxLevel - prevTierLevel
                
                if summaryData.lowestItemLevel < prevTierLevel then
                    -- Haven't reached previous tier yet
                    crestProgress = 0
                else
                    -- Calculate progress between previous tier and max level for this crest
                    local current = math.min(summaryData.lowestItemLevel - prevTierLevel, range)
                    crestProgress = math.floor((current / range) * 100)
                end
                
                -- Create progress bar with appropriate color
                local colorCode = "FF00CCFF" -- Default blue
                if crestProgress >= 75 then
                    colorCode = "FFFFFF00" -- Yellow for close to achievement
                end
                progressBar = CreateProgressBar(crestProgress, colorCode)
                
                -- Calculate how many more item levels needed
                nextThreshold = maxLevel - summaryData.lowestItemLevel + 1
            end
            
            -- Add crest outgrown info to progress text
            local crestInfo = string.format("  Outgrown %s: %s", tier.name, progressBar)
            if not outgrownCrests[i] and nextThreshold > 0 then
                crestInfo = crestInfo .. string.format(" (Need %d more)", nextThreshold)
            end
            progressText = progressText .. crestInfo .. "\n"
        end
        
        local summaryInfo = string.format(
            "Item Levels:\n" ..
            "  |cFFFFD700Equipped:|r %d   |cFF00CCFF(Used for tier eligibility)|r\n" ..
            "  |cFFFFD700Overall:|r %d   |cFF888888(Including bags)|r\n" ..
            "  |cFFFFD700PvP:|r %d\n\n" ..
            "Lowest Item Level: %s (%d)\n" ..
            "Current Discount: %s (%s)\n\n",
            avgEquippedItemLevel, avgItemLevel, avgPvpItemLevel,
            summaryData.lowestSlot, summaryData.lowestItemLevel, tierName, discount
        )
        
        -- Add tier progress indicators
        summaryInfo = summaryInfo .. progressText
        
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