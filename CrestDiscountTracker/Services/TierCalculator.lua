-- TierCalculator.lua - Responsible for tier calculations
local _, addon = ...
local CONSTANTS = addon.Core.CONSTANTS

local TierCalculator = {}
addon.Services.TierCalculator = TierCalculator

function TierCalculator:GetTierInfo(itemLevel)
    for _, tier in ipairs(CONSTANTS.TIERS) do
        if itemLevel >= tier.level then
            return tier.name, tier.discount, true
        end
    end
    return "Not eligible", "No discount", false
end

function TierCalculator:GetNextTierLevel(itemLevel)
    for _, tier in ipairs(CONSTANTS.TIERS) do
        if itemLevel < tier.level then
            return tier.level
        end
    end
    return CONSTANTS.TIERS[1].level -- Return highest tier if already at max
end

function TierCalculator:GetTierColor(itemLevel)
    if itemLevel >= CONSTANTS.TIERS[1].level then -- Gilded
        return CONSTANTS.COLORS.GOLD, 1
    elseif itemLevel >= CONSTANTS.TIERS[2].level then -- Runed
        return CONSTANTS.COLORS.PURPLE, 0.75
    elseif itemLevel >= CONSTANTS.TIERS[3].level then -- Carved
        return CONSTANTS.COLORS.TEAL, 0.5
    elseif itemLevel >= CONSTANTS.TIERS[4].level then -- Weathered
        return CONSTANTS.COLORS.GREEN, 0.25
    else
        return CONSTANTS.COLORS.RED, 0
    end
end 