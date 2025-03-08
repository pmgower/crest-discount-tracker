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

-- Add sorting state to the addon
addon.sortInfo = {
    column = "slot", -- Default sort by slot name
    ascending = true -- Default sort direction
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

-- Function to get the highest ever equipped item level for a slot
function addon:GetHighestRecordedLevel(slotName)
    local slotID = self.slots[slotName]
    if not slotID then return 0 end
    
    -- First try to use the current item level API (most reliable in current retail)
    if C_Item and C_Item.GetCurrentItemLevel and ItemLocation then
        -- Create an ItemLocation from the equipment slot
        local success, itemLocation = pcall(function() 
            return ItemLocation:CreateFromEquipmentSlot(slotID) 
        end)
        
        if success and itemLocation and C_Item.DoesItemExist(itemLocation) then
            local itemLevel = C_Item.GetCurrentItemLevel(itemLocation)
            if itemLevel and itemLevel > 0 then
                return itemLevel
            end
        end
    end
    
    -- Fallback to GetDetailedItemLevelInfo for the current item
    local currentItemLink = GetInventoryItemLink("player", slotID)
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

-- Function to create a sortable column header
function addon:CreateSortableHeader(parent, text, width, anchor, anchorTo, xOffset, sortKey)
    local header = CreateFrame("Button", nil, parent)
    header:SetHeight(25)
    header:SetWidth(width)
    header:SetPoint(anchor, anchorTo, xOffset, 0)
    
    -- Background texture
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.4, 0.8)
    
    -- Header text
    local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerText:SetPoint("LEFT", 5, 0)
    headerText:SetWidth(width - 20) -- Leave room for arrow
    headerText:SetText(text)
    headerText:SetTextColor(1, 0.82, 0)
    headerText:SetJustifyH("LEFT")
    
    -- Sort arrow using texture
    local arrow = header:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(16, 16) -- Larger size for visibility
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    
    -- Set initial arrow state
    if sortKey == self.sortInfo.column then
        if self.sortInfo.ascending then
            arrow:SetTexCoord(0, 0.5625, 0, 1) -- Up arrow
        else
            arrow:SetTexCoord(0, 0.5625, 1, 0) -- Down arrow (flipped)
        end
        arrow:Show()
    else
        arrow:Hide()
    end
    
    -- Click handler for sorting
    header:SetScript("OnClick", function()
        -- Debug print to see what's happening
        print("Header clicked: " .. sortKey .. ", Current sort: " .. self.sortInfo.column .. ", Ascending: " .. tostring(self.sortInfo.ascending))
        
        -- Toggle sort direction if same column, otherwise set new column
        if self.sortInfo.column == sortKey then
            self.sortInfo.ascending = not self.sortInfo.ascending
            print("Toggling direction to: " .. tostring(self.sortInfo.ascending))
        else
            self.sortInfo.column = sortKey
            self.sortInfo.ascending = true
            print("Setting new column: " .. sortKey)
        end
        
        -- Apply the sort
        self:SortSlotData(sortKey)
        
        -- Update the arrows
        self:UpdateSortArrows()
        
        -- Refresh the display with the new sort
        self:UpdateDisplay(self.currentTargetSlot or "all", true)
    end)
    
    -- Highlight on mouse over
    header:SetHighlightTexture("Interface\\Buttons\\UI-ListBox-Highlight", "ADD")
    
    -- Store references
    header.text = headerText
    header.arrow = arrow
    header.sortKey = sortKey
    
    return header
end

-- Function to update sort arrows on all headers
function addon:UpdateSortArrows()
    if not self.displayFrame or not self.displayFrame.headers then return end
    
    for _, header in pairs(self.displayFrame.headers) do
        if header.sortKey == self.sortInfo.column then
            if self.sortInfo.ascending then
                header.arrow:SetTexCoord(0, 0.5625, 0, 1) -- Up arrow
            else
                header.arrow:SetTexCoord(0, 0.5625, 1, 0) -- Down arrow (flipped)
            end
            header.arrow:Show()
        else
            header.arrow:Hide()
        end
    end
end

-- Function to sort slot data
function addon:SortSlotData(column)
    -- If clicking the same column, toggle direction
    if self.sortInfo.column == column then
        self.sortInfo.ascending = not self.sortInfo.ascending
    else
        -- New column, set to ascending by default
        self.sortInfo.column = column
        self.sortInfo.ascending = true
    end
    
    -- Sort the slot frames based on the selected column
    table.sort(self.slotData, function(a, b)
        local aValue, bValue
        
        if column == "slot" then
            aValue = a.name
            bValue = b.name
        elseif column == "current" then
            aValue = a.currentLevel
            bValue = b.currentLevel
        elseif column == "highest" then
            aValue = a.highestLevel
            bValue = b.highestLevel
        elseif column == "item" then
            aValue = a.itemName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") -- Strip color codes
            bValue = b.itemName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        end
        
        -- Handle numeric vs string comparison
        if type(aValue) == "number" and type(bValue) == "number" then
            if self.sortInfo.ascending then
                return aValue < bValue
            else
                return aValue > bValue
            end
        else
            -- Convert to strings for comparison
            aValue = tostring(aValue)
            bValue = tostring(bValue)
            
            if self.sortInfo.ascending then
                return aValue < bValue
            else
                return aValue > bValue
            end
        end
    end)
end

-- Create the main display frame with sortable headers
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
    
    -- Create a table container for the slot list
    local tableFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    tableFrame:SetPoint("TOPLEFT", 0, -130)
    tableFrame:SetPoint("TOPRIGHT", 0, -130)
    tableFrame:SetHeight(800)
    
    -- Create sortable headers with adjusted widths
    local headers = {}
    local headerContainer = CreateFrame("Frame", nil, tableFrame)
    headerContainer:SetPoint("TOPLEFT", 0, 0)
    headerContainer:SetPoint("TOPRIGHT", 0, 0)
    headerContainer:SetHeight(25)
    
    -- Create sortable headers with adjusted widths
    headers.slot = self:CreateSortableHeader(headerContainer, "Slot", 100, "TOPLEFT", headerContainer, 0, "slot")
    headers.current = self:CreateSortableHeader(headerContainer, "Current", 70, "LEFT", headers.slot, "RIGHT", 0, "current")
    headers.highest = self:CreateSortableHeader(headerContainer, "Highest", 70, "LEFT", headers.current, "RIGHT", 0, "highest")
    headers.item = self:CreateSortableHeader(headerContainer, "Item", 200, "LEFT", headers.highest, "RIGHT", 0, "item")
    
    -- Create a container for the slot rows
    local rowsContainer = CreateFrame("Frame", nil, tableFrame)
    rowsContainer:SetPoint("TOPLEFT", 0, -25) -- Below headers
    rowsContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    
    -- Store references
    frame.content = content
    frame.scrollFrame = scrollFrame
    frame.summaryText = summaryText
    frame.tableFrame = tableFrame
    frame.rowsContainer = rowsContainer
    frame.headers = headers
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
    
    -- Update the table layout
    self:UpdateTableLayout()
end

-- Function to update the table layout
function addon:UpdateTableLayout()
    if not self.displayFrame then return end
    
    local frame = self.displayFrame
    local tableWidth = frame.tableFrame:GetWidth()
    
    -- Adjust header widths based on available space
    local slotWidth = 100
    local currentWidth = 70
    local highestWidth = 70
    local itemWidth = tableWidth - slotWidth - currentWidth - highestWidth - 10
    
    -- Update header positions and widths
    frame.headers.slot:SetWidth(slotWidth)
    frame.headers.current:SetWidth(currentWidth)
    frame.headers.highest:SetWidth(highestWidth)
    frame.headers.item:SetWidth(itemWidth)
    
    -- Update row layouts
    for i, slotFrame in pairs(frame.slotFrames) do
        if slotFrame:IsShown() then
            -- Update position and width of elements
            slotFrame.slotName:SetWidth(slotWidth - 10)
            slotFrame.currentLevel:SetWidth(currentWidth - 5)
            slotFrame.highestLevel:SetWidth(highestWidth - 5)
            slotFrame.itemName:SetWidth(itemWidth - 10)
        end
    end
end

-- Function to create a slot row
function addon:CreateSlotRow(parent, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index-1) * 35))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index-1) * 35))
    row:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Slot name
    local slotName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slotName:SetPoint("TOPLEFT", 10, -8)
    slotName:SetPoint("BOTTOMLEFT", 10, 8)
    slotName:SetWidth(90) -- Increased width
    slotName:SetJustifyH("LEFT")
    
    -- Current item level
    local currentLevel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    currentLevel:SetPoint("TOPLEFT", 110, -8) -- Adjusted position
    currentLevel:SetPoint("BOTTOMLEFT", 110, 8)
    currentLevel:SetWidth(60) -- Increased width
    currentLevel:SetJustifyH("CENTER") -- Center align for better appearance
    
    -- Highest recorded item level
    local highestLevel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    highestLevel:SetPoint("TOPLEFT", 180, -8) -- Adjusted position
    highestLevel:SetPoint("BOTTOMLEFT", 180, 8)
    highestLevel:SetWidth(60) -- Increased width
    highestLevel:SetJustifyH("CENTER") -- Center align for better appearance
    
    -- Item name
    local itemName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemName:SetPoint("TOPLEFT", 250, -8) -- Adjusted position
    itemName:SetPoint("TOPRIGHT", -10, -8)
    itemName:SetPoint("BOTTOMRIGHT", -10, 8)
    itemName:SetJustifyH("LEFT")
    
    -- Status indicator (colored bar for tier eligibility)
    local statusBar = CreateFrame("StatusBar", nil, row)
    statusBar:SetPoint("BOTTOMLEFT", 5, 5)
    statusBar:SetPoint("BOTTOMRIGHT", -5, 5)
    statusBar:SetHeight(3)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)
    
    -- Add tooltip to show tier information on hover
    row:SetScript("OnEnter", function(self)
        local level = tonumber(self.currentLevel:GetText()) or 0
        local highest = tonumber(self.highestLevel:GetText()) or 0
        local effectiveLevel = math.max(level, highest)
        
        if effectiveLevel > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.slotName:GetText())
            
            GameTooltip:AddLine("Current Item Level: " .. level, 1, 1, 1)
            GameTooltip:AddLine("Highest Item Level: " .. highest, 1, 1, 1)
            
            -- Determine tier information
            local nextTierLevel = 636
            if effectiveLevel >= 636 then nextTierLevel = 649 end
            if effectiveLevel >= 649 then nextTierLevel = 662 end
            if effectiveLevel >= 662 then nextTierLevel = 675 end
            
            local tierName, discount, isEligible = addon:GetWarbandCrestInfo(effectiveLevel)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Current Tier: " .. tierName, 1, 1, 1)
            GameTooltip:AddLine("Discount: " .. discount, 1, 1, 1)
            
            if effectiveLevel < 675 then
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
    
    -- Store references
    row.slotName = slotName
    row.currentLevel = currentLevel
    row.highestLevel = highestLevel
    row.itemName = itemName
    row.statusBar = statusBar
    
    return row
end

-- Function to update the display with current item data
function addon:UpdateDisplay(targetSlot, keepSort)
    -- Store the current target slot
    self.currentTargetSlot = targetSlot
    
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
    
    -- Collect slot data for sorting
    self.slotData = {}
    
    -- Process slots
    for slotName, slotID in pairs(slotsToProcess) do
        -- Skip shirt and tabard slots
        if slotID ~= 4 and slotID ~= 19 then
            -- Get slot info
            local name, currentLevel, currentItem = self:GetCurrentItemInfo(slotName, slotID)
            
            -- Get the highest recorded level directly from API
            local highestLevel = self:GetHighestRecordedLevel(slotName)
            
            -- Use the higher of current or highest for tier calculations
            local effectiveLevel = math.max(currentLevel, highestLevel)
            
            -- Store data for sorting
            table.insert(self.slotData, {
                slotName = slotName,
                slotID = slotID,
                name = name,
                currentLevel = currentLevel,
                highestLevel = highestLevel,
                effectiveLevel = effectiveLevel,
                itemName = currentItem
            })
            
            -- Track summary data
            if effectiveLevel > 0 then
                totalSlots = totalSlots + 1
                totalItemLevel = totalItemLevel + effectiveLevel
                
                if effectiveLevel < lowestItemLevel then
                    lowestItemLevel = effectiveLevel
                    lowestSlot = name
                end
            end
            
            local _, _, isEligible = self:GetWarbandCrestInfo(effectiveLevel)
            if isEligible then
                eligibleSlots = eligibleSlots + 1
            end
        end
    end
    
    -- Sort the data if needed
    if not keepSort then
        -- Default sort by slot name
        self.sortInfo.column = "slot"
        self.sortInfo.ascending = true
    else
        -- Debug print to verify sort is maintained
        print("Keeping sort: " .. self.sortInfo.column .. ", Ascending: " .. tostring(self.sortInfo.ascending))
    end
    
    -- Apply the current sort
    self:SortSlotData(self.sortInfo.column)
    
    -- Update sort arrows
    self:UpdateSortArrows()
    
    -- Display the sorted data
    for i, slotData in ipairs(self.slotData) do
        -- Create or get slot frame
        if not frame.slotFrames[i] then
            frame.slotFrames[i] = self:CreateSlotRow(frame.rowsContainer, i)
        end
        
        local slotFrame = frame.slotFrames[i]
        slotFrame:Show()
        
        -- Update slot frame with item info
        slotFrame.slotName:SetText(slotData.name)
        slotFrame.currentLevel:SetText(slotData.currentLevel)
        slotFrame.highestLevel:SetText(slotData.highestLevel)
        slotFrame.itemName:SetText(slotData.itemName)
        
        -- Determine status color based on tier eligibility
        local tierName, discount, isEligible = self:GetWarbandCrestInfo(slotData.effectiveLevel)
        local r, g, b = 1, 0, 0 -- Default red for not eligible
        local statusValue = 0
        
        if slotData.effectiveLevel >= 675 then
            r, g, b = 1, 0.84, 0 -- Gold for highest tier
            statusValue = 1
        elseif slotData.effectiveLevel >= 662 then
            r, g, b = 0.6, 0.6, 1 -- Purple for Runed
            statusValue = 0.75
        elseif slotData.effectiveLevel >= 649 then
            r, g, b = 0, 0.7, 0.7 -- Teal for Carved
            statusValue = 0.5
        elseif slotData.effectiveLevel >= 636 then
            r, g, b = 0, 0.7, 0 -- Green for Weathered
            statusValue = 0.25
        end
        
        slotFrame.statusBar:SetStatusBarColor(r, g, b)
        slotFrame.statusBar:SetValue(statusValue)
        
        -- Set the backdrop color based on how close to next tier
        local nextTierLevel = 636
        if slotData.effectiveLevel >= 636 then nextTierLevel = 649 end
        if slotData.effectiveLevel >= 649 then nextTierLevel = 662 end
        if slotData.effectiveLevel >= 662 then nextTierLevel = 675 end
        
        local distanceToNextTier = nextTierLevel - slotData.effectiveLevel
        
        if distanceToNextTier <= 5 and distanceToNextTier > 0 then
            -- Close to next tier - highlight
            slotFrame:SetBackdropColor(0.3, 0.3, 0.1, 0.8)
            slotFrame.currentLevel:SetTextColor(1, 1, 0) -- Yellow
            slotFrame.highestLevel:SetTextColor(1, 1, 0) -- Yellow
        elseif slotData.effectiveLevel >= 675 then
            -- Max tier
            slotFrame:SetBackdropColor(0.2, 0.2, 0.1, 0.8)
            slotFrame.currentLevel:SetTextColor(1, 0.84, 0) -- Gold
            slotFrame.highestLevel:SetTextColor(1, 0.84, 0) -- Gold
        else
            -- Normal
            slotFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
            slotFrame.currentLevel:SetTextColor(1, 1, 1) -- White
            slotFrame.highestLevel:SetTextColor(1, 1, 1) -- White
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
    self:UpdateTableLayout()
    
    -- Only show this message on initial open, not on resort
    if not keepSort then
        print("|cFF00CCFF[CrestDiscountTracker]|r Window opened. Type '/cdt close' to close the window.")
    end
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