-- TooltipManager.lua - Responsible for tooltip functionality
local _, addon = ...
local CONSTANTS = addon.Core.CONSTANTS
local TierCalculator = addon.Services.TierCalculator

local TooltipManager = {}
addon.UI.TooltipManager = TooltipManager

function TooltipManager:SetupRowTooltip(row, slotData)
    row:SetScript("OnEnter", function(self)
        local level = slotData.currentLevel
        local highest = slotData.highestLevel
        local effectiveLevel = slotData.effectiveLevel
        
        if effectiveLevel > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(slotData.name)
            
            GameTooltip:AddLine("Current Item Level: " .. level, 1, 1, 1)
            GameTooltip:AddLine("Highest Item Level: " .. highest, 1, 1, 1)
            
            -- Determine tier information
            local nextTierLevel = TierCalculator:GetNextTierLevel(effectiveLevel)
            local tierName, discount, isEligible = TierCalculator:GetTierInfo(effectiveLevel)
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Current Tier: " .. tierName, 1, 1, 1)
            GameTooltip:AddLine("Discount: " .. discount, 1, 1, 1)
            
            if effectiveLevel < CONSTANTS.TIERS[1].level then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Next Tier: " .. (nextTierLevel - effectiveLevel) .. " item levels needed", 1, 0.82, 0)
            else
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Maximum tier reached!", 0, 1, 0)
            end
            
            GameTooltip:Show()
        end
    end)
    
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end 