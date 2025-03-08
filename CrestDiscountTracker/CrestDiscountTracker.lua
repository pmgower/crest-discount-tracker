-- HighestItemLevel.lua (Main addon file)
local addonName, addon = ...

-- Slot mapping with ID numbers
addon.slots = {
    ["head"] = 1,
    ["neck"] = 2,
    ["shoulder"] = 3,
    ["chest"] = 5,
    ["waist"] = 6,
    ["legs"] = 7,
    ["feet"] = 8,
    ["wrist"] = 9,
    ["hands"] = 10,
    ["finger1"] = 11,
    ["finger2"] = 12,
    ["trinket1"] = 13,
    ["trinket2"] = 14,
    ["back"] = 15,
    ["mainhand"] = 16,
    ["offhand"] = 17
}

-- Readable names for each slot
addon.slotNames = {
    ["head"] = "Head",
    ["neck"] = "Neck",
    ["shoulder"] = "Shoulder",
    ["chest"] = "Chest",
    ["waist"] = "Waist",
    ["legs"] = "Legs",
    ["feet"] = "Feet",
    ["wrist"] = "Wrist",
    ["hands"] = "Hands",
    ["finger1"] = "Finger 1",
    ["finger2"] = "Finger 2",
    ["trinket1"] = "Trinket 1",
    ["trinket2"] = "Trinket 2",
    ["back"] = "Back",
    ["mainhand"] = "Main Hand",
    ["offhand"] = "Off Hand"
}

-- Function to get the highest ever equipped item level for a slot using alternative APIs
function addon:GetHighestEquippedLevel(slotID)
    -- Try various methods to get the highest item level
    
    local currentItemLink = GetInventoryItemLink("player", slotID)
    if currentItemLink then
        -- Use GetDetailedItemLevelInfo which is widely available
        local _, _, _, itemLevel = GetDetailedItemLevelInfo(currentItemLink)
        if itemLevel and itemLevel > 0 then
            return itemLevel
        end
    end
    
    -- Return 0 if no item or no item level found
    return 0
end

-- Function to check if addon is on Retail and has necessary APIs
function addon:CheckRetailAPIs()
    -- Check for the WoW version
    local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
    
    -- We don't need to check for C_Item API anymore since we're using GetDetailedItemLevelInfo
    return isRetail, true
end

-- Function to get current equipped item information
function addon:GetCurrentItemInfo(slotName, slotID)
    local slotItem = GetInventoryItemLink("player", slotID)
    
    if slotItem then
        -- Get basic item info
        local itemName, _, itemRarity = GetItemInfo(slotItem)
        
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
        
        local itemQuality = ITEM_QUALITY_COLORS[itemRarity or 1]
        local coloredName = (itemQuality and itemQuality.hex or "|cFFFFFFFF")..
                           (itemName or "Unknown Item").."|r"
        
        return self.slotNames[slotName] or slotName, itemLevel or 0, coloredName
    else
        return self.slotNames[slotName] or slotName, 0, "None equipped"
    end
end

-- Function to check for specific item level thresholds
function addon:GetWarbandCrestInfo(itemLevel)
    -- Warband Crest Discount thresholds for The War Within Season 2
    if itemLevel >= 675 then
        return "Gilded of the Undermine", "33% discount", true
    elseif itemLevel >= 662 then
        return "Runed of the Undermine", "33% discount", true
    elseif itemLevel >= 649 then
        return "Carved of the Undermine", "33% discount", true
    elseif itemLevel >= 636 then
        return "Weathered of the Undermine", "33% discount", true
    else
        return "Not eligible", "No discount", false
    end
end

-- Create the main display frame
function addon:CreateDisplayFrame()
    -- Create the main frame
    local frame = CreateFrame("Frame", "CrestDiscountTrackerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(450, 550)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Try to set resizable if the API supports it
    local canResize = pcall(function() frame:SetResizable(true) end)
    
    -- Only set min/max resize if the frame is resizable
    if canResize then
        -- Use pcall to safely try these methods
        pcall(function() frame:SetMinResize(400, 300) end)
        pcall(function() frame:SetMaxResize(800, 800) end)
    end
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Add a title bar
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", 12, -12)
    titleBar:SetPoint("TOPRIGHT", -12, -12)
    titleBar:SetHeight(30)
    titleBar:SetBackdrop({
        bgFile = "Interface\\PaperDollInfoFrame\\UI-Character-Title-Backdrop",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    titleBar:SetBackdropColor(0.1, 0.1, 0.3, 1)
    
    -- Add a title
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", titleBar, "CENTER")
    title:SetText("Crest Discount Tracker")
    title:SetTextColor(1, 0.82, 0)
    
    -- Add a close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    
    -- Add resize grip
    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    resizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    
    resizeButton:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            frame:StopMovingOrSizing()
            -- Update the scroll frame and content when resizing is done
            addon:UpdateScrollFrameLayout()
        end
    end)
    
    -- Create a scrollframe for the content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)
    
    -- Create the scrolling content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1000) -- Height will adjust as needed
    scrollFrame:SetScrollChild(content)
    
    -- Create a summary section at the top
    local summaryFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    summaryFrame:SetPoint("TOPLEFT", 0, 0)
    summaryFrame:SetPoint("TOPRIGHT", 0, 0)
    summaryFrame:SetHeight(120)
    summaryFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    summaryFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
    
    -- Summary text
    local summaryTitle = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    summaryTitle:SetPoint("TOPLEFT", 10, -10)
    summaryTitle:SetText("Summary")
    summaryTitle:SetTextColor(1, 0.82, 0)
    
    local summaryText = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryText:SetPoint("TOPLEFT", 10, -35)
    summaryText:SetPoint("BOTTOMRIGHT", -10, 10)
    summaryText:SetJustifyH("LEFT")
    summaryText:SetJustifyV("TOP")
    summaryText:SetText("")
    
    -- Create a slot list section
    local slotListFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    slotListFrame:SetPoint("TOPLEFT", 0, -130)
    slotListFrame:SetPoint("TOPRIGHT", 0, -130)
    slotListFrame:SetHeight(800)
    
    -- Create a header for the slot list
    local headerFrame = CreateFrame("Frame", nil, slotListFrame, "BackdropTemplate")
    headerFrame:SetHeight(25)
    headerFrame:SetPoint("TOPLEFT", 0, 0)
    headerFrame:SetPoint("TOPRIGHT", 0, 0)
    headerFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    headerFrame:SetBackdropColor(0.2, 0.2, 0.4, 0.8)
    
    -- Header columns
    local slotHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slotHeader:SetPoint("TOPLEFT", 10, -6)
    slotHeader:SetWidth(100)
    slotHeader:SetText("Slot")
    slotHeader:SetTextColor(1, 0.82, 0)
    
    local ilevelHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ilevelHeader:SetPoint("LEFT", slotHeader, "RIGHT", 10, 0)
    ilevelHeader:SetWidth(50)
    ilevelHeader:SetText("iLevel")
    ilevelHeader:SetTextColor(1, 0.82, 0)
    
    local itemHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemHeader:SetPoint("LEFT", ilevelHeader, "RIGHT", 10, 0)
    itemHeader:SetText("Item")
    itemHeader:SetTextColor(1, 0.82, 0)
    
    -- Store references
    frame.content = content
    frame.scrollFrame = scrollFrame
    frame.summaryText = summaryText
    frame.slotListFrame = slotListFrame
    frame.slotFrames = {}
    frame:Hide() -- Hide by default
    
    return frame
end

-- Function to update the scroll frame layout after resizing
function addon:UpdateScrollFrameLayout()
    if not self.displayFrame then return end
    
    local frame = self.displayFrame
    local scrollFrame = frame.scrollFrame
    local content = frame.content
    
    -- Update content width to match scroll frame
    content:SetWidth(scrollFrame:GetWidth())
    
    -- Reposition all slot frames to fit the new width
    for i, slotFrame in pairs(frame.slotFrames) do
        if slotFrame:IsShown() then
            slotFrame:SetPoint("TOPRIGHT", frame.slotListFrame, "TOPRIGHT", 0, -((i-1) * 45 + 25))
            slotFrame:SetPoint("TOPLEFT", frame.slotListFrame, "TOPLEFT", 0, -((i-1) * 45 + 25))
        end
    end
end

-- Function to create a slot item frame
function addon:CreateSlotFrame(parent, index)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetHeight(40)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index-1) * 45 + 25)) -- +25 for header
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index-1) * 45 + 25))
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Slot name
    local slotName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slotName:SetPoint("TOPLEFT", 10, -10)
    slotName:SetPoint("BOTTOMLEFT", 10, 10)
    slotName:SetWidth(100)
    slotName:SetJustifyH("LEFT")
    
    -- Item level
    local itemLevel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemLevel:SetPoint("LEFT", slotName, "RIGHT", 10, 0)
    itemLevel:SetWidth(50)
    
    -- Item name
    local itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemName:SetPoint("LEFT", itemLevel, "RIGHT", 10, 0)
    itemName:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    itemName:SetJustifyH("LEFT")
    
    -- Status indicator (colored bar for tier eligibility)
    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetPoint("BOTTOMLEFT", 5, 5)
    statusBar:SetPoint("BOTTOMRIGHT", -5, 5)
    statusBar:SetHeight(4)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)
    
    -- Add tooltip to show tier information on hover
    frame:SetScript("OnEnter", function(self)
        local level = tonumber(self.itemLevel:GetText()) or 0
        if level > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Item Level: " .. level)
            
            -- Determine tier information
            local nextTierLevel = 636
            if level >= 636 then nextTierLevel = 649 end
            if level >= 649 then nextTierLevel = 662 end
            if level >= 662 then nextTierLevel = 675 end
            
            local tierName, discount, isEligible = addon:GetWarbandCrestInfo(level)
            GameTooltip:AddLine("Current Tier: " .. tierName, 1, 1, 1)
            GameTooltip:AddLine("Discount: " .. discount, 1, 1, 1)
            
            if level < 675 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Next Tier: " .. (nextTierLevel - level) .. " item levels needed", 1, 0.82, 0)
            else
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Maximum tier reached!", 0, 1, 0)
            end
            
            GameTooltip:Show()
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Store references
    frame.slotName = slotName
    frame.itemLevel = itemLevel
    frame.itemName = itemName
    frame.statusBar = statusBar
    
    return frame
end

-- Function to update the display with current item data
function addon:UpdateDisplay(targetSlot)
    if not self.displayFrame then
        self.displayFrame = self:CreateDisplayFrame()
    end
    
    local frame = self.displayFrame
    frame:Show()
    
    -- Check if we're on retail
    local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
    
    -- Clear existing slot frames
    for _, slotFrame in pairs(frame.slotFrames) do
        slotFrame:Hide()
    end
    
    -- Variables for summary
    local totalSlots = 0
    local totalItemLevel = 0
    local eligibleSlots = 0
    local lowestSlot = "none"
    local lowestItemLevel = 999
    local nextTierNeeded = 0
    
    -- Process all slots if viewing all, or just the target slot
    local slotsToProcess = {}
    if targetSlot == "all" then
        slotsToProcess = self.slots
    elseif self.slots[targetSlot] then
        slotsToProcess = {[targetSlot] = self.slots[targetSlot]}
    else
        -- Invalid slot
        frame.summaryText:SetText("Error: Invalid slot name. Available slots: head, neck, shoulder, chest, waist, legs, feet, wrist, hands, finger1, finger2, trinket1, trinket2, back, mainhand, offhand or 'all'")
        return
    end
    
    -- Process slots
    local index = 1
    for slotName, slotID in pairs(slotsToProcess) do
        -- Skip shirt and tabard slots
        if slotID ~= 4 and slotID ~= 19 then
            -- Get slot info
            local name, currentLevel, currentItem = self:GetCurrentItemInfo(slotName, slotID)
            
            -- Create or get slot frame
            if not frame.slotFrames[index] then
                frame.slotFrames[index] = self:CreateSlotFrame(frame.slotListFrame, index)
            end
            
            local slotFrame = frame.slotFrames[index]
            slotFrame:Show()
            
            -- Update slot frame with item info
            slotFrame.slotName:SetText(name)
            slotFrame.itemLevel:SetText(currentLevel)
            slotFrame.itemName:SetText(currentItem)
            
            -- Determine status color based on tier eligibility
            local tierName, discount, isEligible = self:GetWarbandCrestInfo(currentLevel)
            local r, g, b = 1, 0, 0 -- Default red for not eligible
            local statusValue = 0
            
            if currentLevel >= 675 then
                r, g, b = 1, 0.84, 0 -- Gold for highest tier
                statusValue = 1
            elseif currentLevel >= 662 then
                r, g, b = 0.6, 0.6, 1 -- Purple for Runed
                statusValue = 0.75
            elseif currentLevel >= 649 then
                r, g, b = 0, 0.7, 0.7 -- Teal for Carved
                statusValue = 0.5
            elseif currentLevel >= 636 then
                r, g, b = 0, 0.7, 0 -- Green for Weathered
                statusValue = 0.25
            end
            
            slotFrame.statusBar:SetStatusBarColor(r, g, b)
            slotFrame.statusBar:SetValue(statusValue)
            
            -- Set the backdrop color based on how close to next tier
            local nextTierLevel = 636
            if currentLevel >= 636 then nextTierLevel = 649 end
            if currentLevel >= 649 then nextTierLevel = 662 end
            if currentLevel >= 662 then nextTierLevel = 675 end
            
            local distanceToNextTier = nextTierLevel - currentLevel
            
            if distanceToNextTier <= 5 and distanceToNextTier > 0 then
                -- Close to next tier - highlight
                slotFrame:SetBackdropColor(0.3, 0.3, 0.1, 0.8)
                slotFrame.itemLevel:SetTextColor(1, 1, 0) -- Yellow
            elseif currentLevel >= 675 then
                -- Max tier
                slotFrame:SetBackdropColor(0.2, 0.2, 0.1, 0.8)
                slotFrame.itemLevel:SetTextColor(1, 0.84, 0) -- Gold
            else
                -- Normal
                slotFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
                slotFrame.itemLevel:SetTextColor(1, 1, 1) -- White
            end
            
            -- Track summary data
            if currentLevel > 0 then
                totalSlots = totalSlots + 1
                totalItemLevel = totalItemLevel + currentLevel
                
                if currentLevel < lowestItemLevel then
                    lowestItemLevel = currentLevel
                    lowestSlot = name
                end
            end
            
            if isEligible then
                eligibleSlots = eligibleSlots + 1
            end
            
            index = index + 1
        end
    end
    
    -- Update summary
    if totalSlots > 0 then
        local avgItemLevel = math.floor(totalItemLevel / totalSlots)
        local tierName, discount, _ = self:GetWarbandCrestInfo(lowestItemLevel)
        
        -- Determine next tier needed
        local nextTierLevel = 636
        if lowestItemLevel >= 636 then nextTierLevel = 649 end
        if lowestItemLevel >= 649 then nextTierLevel = 662 end
        if lowestItemLevel >= 662 then nextTierLevel = 675 end
        
        local summaryInfo = string.format(
            "Average Item Level: %d\n" ..
            "Lowest Item Level: %s (%d)\n" ..
            "Current Discount: %s (%s)\n" ..
            "Eligible Slots: %d out of 16\n",
            avgItemLevel, lowestSlot, lowestItemLevel, tierName, discount, eligibleSlots
        )
        
        if lowestItemLevel < 675 then
            summaryInfo = summaryInfo .. string.format(
                "\nNext Tier: Need %d more item levels in %s",
                nextTierLevel - lowestItemLevel, lowestSlot
            )
        else
            summaryInfo = summaryInfo .. "\n|cFFFFD700You've reached the highest tier!|r"
        end
        
        frame.summaryText:SetText(summaryInfo)
    else
        frame.summaryText:SetText("No items equipped")
    end
    
    -- Update the layout
    self:UpdateScrollFrameLayout()
    
    -- Also output to chat for convenience
    print("|cFF00CCFF[CrestDiscountTracker]|r Window opened. Type '/cdt close' to close the window.")
end

-- Modified display function to use the enhanced window
function addon:DisplayHighestItemLevels(targetSlot)
    self:UpdateDisplay(targetSlot)
end

-- Register slash commands
SLASH_CRESTDISCOUNTTRACKER1 = "/crestdiscounttracker"
SLASH_CRESTDISCOUNTTRACKER2 = "/cdt"
SlashCmdList["CRESTDISCOUNTTRACKER"] = function(msg)
    local targetSlot = msg:lower()
    
    if targetSlot == "close" then
        -- Close the window if it exists
        if addon.displayFrame then
            addon.displayFrame:Hide()
        end
        return
    end
    
    if targetSlot == "" then
        targetSlot = "all"
    end
    
    addon:DisplayHighestItemLevels(targetSlot)
end

-- Event handler frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FF00CrestDiscountTracker addon loaded!|r")
        print("Use |cFFFFD700/crestdiscounttracker [slot]|r or |cFFFFD700/cdt [slot]|r to check a specific slot, or |cFFFFD700/cdt all|r to check all slots.")
    end
end)