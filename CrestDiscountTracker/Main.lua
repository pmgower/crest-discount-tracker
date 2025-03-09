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
    
    -- Print a simple loading message
    print("|cFF00FF00CrestDiscountTracker addon loaded!|r")
    print("Use |cFFFFD700/cdt|r to open the tracker window")
    print("Use |cFFFFD700/cdt debug|r to open the debug window")
    print("Use |cFFFFD700/cdt close|r to close the window")
end

function CrestDiscountTracker:UpdateDisplay(targetSlot)
    -- Store the current target slot
    self.currentTargetSlot = targetSlot
    
    if not self.displayFrame then
        self.displayFrame = UIFactory:CreateMainFrame()
    end
    
    local frame = self.displayFrame
    frame:Show()
    
    -- Switch to main tab
    frame.selectedTab = 1
    if frame.mainContent then
        frame.mainContent:Show()
    end
    if frame.debugContent then
        frame.debugContent:Hide()
    end
    
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
    
    -- Display the slot data
    for i, data in ipairs(slotData) do
        -- Create or get slot frame
        if not frame.slotFrames[i] then
            frame.slotFrames[i] = UIFactory:CreateSlotRow(frame.rowsContainer, i)
        end
        
        local slotFrame = frame.slotFrames[i]
        slotFrame:Show()
        
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
        -- Show the UI with the debug tab active
        if not CrestDiscountTracker.displayFrame then
            CrestDiscountTracker.displayFrame = UIFactory:CreateMainFrame()
        end
        
        local frame = CrestDiscountTracker.displayFrame
        frame:Show()
        
        -- Switch to debug tab
        frame.selectedTab = 2
        if frame.mainContent then
            frame.mainContent:Hide()
        end
        if frame.debugContent then
            frame.debugContent:Show()
        end
        
        -- Update debug info
        if frame.UpdateDebugInfo then
            frame.UpdateDebugInfo()
        end
        
        print("|cFF00CCFF[CrestDiscountTracker]|r Debug window opened. Type '/cdt close' to close the window.")
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
    end
end) 