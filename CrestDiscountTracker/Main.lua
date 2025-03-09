-- Main.lua - Main addon controller and entry point
local _, addon = ...

-- Import modules
local SlotManager = addon.Core.SlotManager
local ItemLevelService = addon.Services.ItemLevelService
local TierCalculator = addon.Services.TierCalculator
local DataCollector = addon.Data.DataCollector
local UIFactory = addon.UI.UIFactory
local UIController = addon.UI.UIController

-- Main addon controller
local CrestDiscountTracker = {}
addon.CrestDiscountTracker = CrestDiscountTracker

function CrestDiscountTracker:Initialize()
    -- Initialize any addon-wide settings
    self.currentTargetSlot = "all"
    
    -- Debug: Print slot mappings to verify back slot is in position 4
    print("|cFF00CCFF[CrestDiscountTracker Debug]|r Slot mappings:")
    for slotName, slotID in pairs(SlotManager:GetAllSlots()) do
        local itemLink = GetInventoryItemLink("player", slotID)
        local itemName = itemLink and GetItemInfo(itemLink) or "No item"
        print(string.format("  %s: Internal ID=%d, Item=%s", slotName, slotID, itemName))
    end
    
    -- Debug: Print WoW's inventory slot IDs
    print("|cFF00CCFF[CrestDiscountTracker Debug]|r WoW inventory slots:")
    for i = 1, 19 do
        local itemLink = GetInventoryItemLink("player", i)
        local itemName = itemLink and GetItemInfo(itemLink) or "No item"
        print(string.format("  Slot %d: %s", i, itemName))
    end
end

function CrestDiscountTracker:UpdateDisplay(targetSlot)
    -- Store the current target slot
    self.currentTargetSlot = targetSlot
    
    if not self.displayFrame then
        self.displayFrame = UIFactory:CreateMainFrame()
    end
    
    local frame = self.displayFrame
    frame:Show()
    
    -- Clear existing slot frames
    for _, slotFrame in pairs(frame.slotFrames) do
        slotFrame:Hide()
    end
    
    -- Collect data
    local slotData, summaryData = DataCollector:CollectSlotData(targetSlot)
    
    if not slotData then
        -- Error occurred
        frame.summaryText:SetText(summaryData) -- summaryData contains error message
        return
    end
    
    -- Update summary
    UIController:UpdateSummary(frame, summaryData)
    
    -- Debug output to help diagnose issues
    print("|cFF00CCFF[CrestDiscountTracker Debug]|r Found " .. #slotData .. " slots to display")
    
    -- Display the slot data
    for i, data in ipairs(slotData) do
        -- Create or get slot frame
        if not frame.slotFrames[i] then
            frame.slotFrames[i] = UIFactory:CreateSlotRow(frame.rowsContainer, i)
            print("|cFF00CCFF[CrestDiscountTracker Debug]|r Created new row " .. i)
        end
        
        local slotFrame = frame.slotFrames[i]
        slotFrame:Show()
        
        -- Debug output
        print(string.format("|cFF00CCFF[CrestDiscountTracker Debug]|r Updating slot: %s (ID: %d) - Current: %d, Highest: %d", 
            data.name, data.slotID, data.currentLevel, data.highestLevel))
        
        -- Update the slot row
        UIController:UpdateSlotRow(slotFrame, data)
    end
    
    -- Update the height of the rows container based on the number of rows
    frame.rowsContainer:SetHeight(#slotData * 35 + 10)
    
    print("|cFF00CCFF[CrestDiscountTracker]|r Window opened. Type '/cdt close' to close the window.")
end

-- Register slash commands
SLASH_CRESTDISCOUNTTRACKER1 = "/crestdiscounttracker"
SLASH_CRESTDISCOUNTTRACKER2 = "/cdt"
SlashCmdList["CRESTDISCOUNTTRACKER"] = function(msg)
    local command = msg:lower()
    
    if command == "close" then
        -- Close the window if it exists
        if CrestDiscountTracker.displayFrame then
            CrestDiscountTracker.displayFrame:Hide()
        end
        return
    elseif command == "debug" then
        -- Add a debug command to help diagnose issues
        print("CrestDiscountTracker Debug Information:")
        print("Current target slot: " .. CrestDiscountTracker.currentTargetSlot)
        print("Display frame exists: " .. (CrestDiscountTracker.displayFrame and "Yes" or "No"))
        if CrestDiscountTracker.displayFrame then
            print("Number of slot frames: " .. (#CrestDiscountTracker.displayFrame.slotFrames or 0))
        end
        
        -- Show current slot data
        print("Collecting slot data for debugging...")
        local slotData, summaryData = DataCollector:CollectSlotData("all")
        if slotData then
            print("Found " .. #slotData .. " slots:")
            for i, data in ipairs(slotData) do
                print(string.format("  %d. %s (ID: %d) - Current: %d, Highest: %d", 
                    i, data.name, data.slotID, data.currentLevel, data.highestLevel))
            end
        else
            print("Error collecting slot data: " .. (summaryData or "Unknown error"))
        end
        return
    end
    
    -- For any other command or empty command, just show the UI
    CrestDiscountTracker:UpdateDisplay("all")
end

-- Event handler frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        CrestDiscountTracker:Initialize()
        print("|cFF00FF00CrestDiscountTracker addon loaded!|r")
        print("Use |cFFFFD700/cdt|r to open the tracker window, and |cFFFFD700/cdt close|r to close it.")
    end
end) 