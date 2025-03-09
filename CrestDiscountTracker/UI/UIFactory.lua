-- UIFactory.lua - Responsible for creating UI elements
local _, addon = ...

local UIFactory = {}
addon.UI.UIFactory = UIFactory

function UIFactory:CreateSlotRow(parent, index)
    local row = CreateFrame("Frame", "CDTRow"..index, parent, "BackdropTemplate")
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
    
    -- Slot ID - first column
    local slotID = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    slotID:SetPoint("TOPLEFT", 10, -8)
    slotID:SetPoint("BOTTOMLEFT", 10, 8)
    slotID:SetWidth(40) -- Width for ID
    slotID:SetJustifyH("CENTER")
    
    -- Slot name - second column
    local slotName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slotName:SetPoint("TOPLEFT", 60, -8) -- Position after ID
    slotName:SetPoint("BOTTOMLEFT", 60, 8)
    slotName:SetWidth(100) -- Width for slot name
    slotName:SetJustifyH("LEFT")
    
    -- Current item level - third column
    local currentLevel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    currentLevel:SetPoint("TOPLEFT", 170, -8) -- Position after slot name
    currentLevel:SetPoint("BOTTOMLEFT", 170, 8)
    currentLevel:SetWidth(70) -- Width for current level
    currentLevel:SetJustifyH("CENTER")
    
    -- Highest recorded item level - fourth column
    local highestLevel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    highestLevel:SetPoint("TOPLEFT", 250, -8) -- Position after current level
    highestLevel:SetPoint("BOTTOMLEFT", 250, 8)
    highestLevel:SetWidth(70) -- Width for highest level
    highestLevel:SetJustifyH("CENTER")
    
    -- Status bar at the bottom of the row
    local statusBar = CreateFrame("StatusBar", nil, row)
    statusBar:SetPoint("BOTTOMLEFT", 5, 5)
    statusBar:SetPoint("BOTTOMRIGHT", -5, 5)
    statusBar:SetHeight(3)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)
    
    -- Store references
    row.slotID = slotID
    row.slotName = slotName
    row.currentLevel = currentLevel
    row.highestLevel = highestLevel
    row.statusBar = statusBar
    
    return row
end

function UIFactory:CreateMainFrame()
    -- Create the main frame
    local frame = CreateFrame("Frame", "CrestDiscountTrackerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 600)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    
    -- Title text
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", 0, -15)
    titleText:SetText("Crest Discount Tracker")
    titleText:SetTextColor(1, 0.82, 0)
    
    -- Create resize handle
    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", -5, 5)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    resizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Use StartSizing with no direction for compatibility
            frame:StartSizing()
        end
    end)
    
    resizeButton:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            frame:StopMovingOrSizing()
            
            -- Update the container height when resizing
            if frame.rowsContainer then
                frame.rowsContainer:SetHeight(#frame.slotFrames * 35 + 10)
            end
        end
    end)
    
    -- Add OnSizeChanged handler to update scroll frames when resizing
    frame:SetScript("OnSizeChanged", function(self, width, height)
        -- Enforce minimum and maximum size manually
        if width < 350 then 
            self:SetWidth(350)
        elseif width > 600 then
            self:SetWidth(600)
        end
        
        if height < 400 then
            self:SetHeight(400)
        elseif height > 800 then
            self:SetHeight(800)
        end
    end)
    
    -- Create tab container
    local tabContainer = CreateFrame("Frame", nil, frame)
    tabContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
    tabContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -40)
    tabContainer:SetHeight(25)
    
    -- Create custom tab function
    local function CreateTab(parent, id, text, isFirst)
        local tab = CreateFrame("Button", nil, parent)
        tab:SetSize(100, 25)
        if isFirst then
            tab:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        else
            tab:SetPoint("TOPLEFT", parent.lastTab, "TOPRIGHT", 2, 0)
        end
        
        -- Create background texture
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
        tab.bg = bg
        
        -- Create border
        local border = CreateFrame("Frame", nil, tab, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
        tab.border = border
        
        -- Tab highlight
        tab:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight", "ADD")
        
        -- Tab text
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tabText:SetPoint("CENTER", 0, 0)
        tabText:SetText(text)
        tab.text = tabText
        
        -- Tab ID
        tab:SetID(id)
        
        -- Store reference to last tab
        parent.lastTab = tab
        
        return tab
    end
    
    -- Create tabs
    local mainTab = CreateTab(tabContainer, 1, "Main", true)
    local debugTab = CreateTab(tabContainer, 2, "Debug", false)
    
    -- Function to update tab appearance
    local function UpdateTabAppearance()
        local selectedTab = frame.selectedTab or 1
        
        -- Update main tab
        if selectedTab == 1 then
            mainTab.text:SetTextColor(1, 1, 1)
            mainTab.bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)
            mainTab.border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
        else
            mainTab.text:SetTextColor(0.7, 0.7, 0.7)
            mainTab.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
            mainTab.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
        end
        
        -- Update debug tab
        if selectedTab == 2 then
            debugTab.text:SetTextColor(1, 1, 1)
            debugTab.bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)
            debugTab.border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
        else
            debugTab.text:SetTextColor(0.7, 0.7, 0.7)
            debugTab.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
            debugTab.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
        end
    end
    
    -- Create content frames for each tab
    local mainContent = CreateFrame("Frame", nil, frame)
    mainContent:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT", 0, -5)
    mainContent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    mainContent:Show()
    
    local debugContent = CreateFrame("Frame", nil, frame)
    debugContent:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT", 0, -5)
    debugContent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    debugContent:Hide()
    
    -- Create debug scroll frame
    local debugScrollFrame = CreateFrame("ScrollFrame", "CDTDebugScrollFrame", debugContent, "UIPanelScrollFrameTemplate")
    debugScrollFrame:SetPoint("TOPLEFT", 0, 0)
    debugScrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)
    
    local debugScrollChild = CreateFrame("Frame", "CDTDebugScrollChild", debugScrollFrame)
    debugScrollChild:SetWidth(debugScrollFrame:GetWidth())
    debugScrollChild:SetHeight(800)
    debugScrollFrame:SetScrollChild(debugScrollChild)
    
    local debugText = debugScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugText:SetPoint("TOPLEFT", 10, -10)
    debugText:SetPoint("TOPRIGHT", -10, -10)
    debugText:SetJustifyH("LEFT")
    debugText:SetJustifyV("TOP")
    debugText:SetText("Debug information will appear here.\nUse '/cdt debug' to refresh.")
    debugText:SetTextColor(1, 1, 1)
    
    -- Create summary frame in main content
    local summaryFrame = CreateFrame("Frame", nil, mainContent, "BackdropTemplate")
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
    
    -- Summary text
    local summaryText = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryText:SetPoint("TOPLEFT", 10, -10)
    summaryText:SetPoint("BOTTOMRIGHT", -10, 10)
    summaryText:SetJustifyH("LEFT")
    summaryText:SetJustifyV("TOP")
    summaryText:SetText("Loading summary...")
    
    -- Table frame for the slot data
    local tableFrame = CreateFrame("Frame", nil, mainContent)
    tableFrame:SetPoint("TOPLEFT", summaryFrame, "BOTTOMLEFT", 0, -10)
    tableFrame:SetPoint("BOTTOMRIGHT", mainContent, "BOTTOMRIGHT", 0, 0)
    
    -- Header container
    local headerContainer = CreateFrame("Frame", nil, tableFrame)
    headerContainer:SetPoint("TOPLEFT")
    headerContainer:SetPoint("TOPRIGHT")
    headerContainer:SetHeight(25)
    
    -- Create header labels
    local idHeader = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    idHeader:SetPoint("TOPLEFT", 10, -8)
    idHeader:SetWidth(40)
    idHeader:SetText("ID")
    idHeader:SetTextColor(1, 0.82, 0)
    
    local slotHeader = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slotHeader:SetPoint("TOPLEFT", 60, -8)
    slotHeader:SetWidth(100)
    slotHeader:SetText("Slot")
    slotHeader:SetTextColor(1, 0.82, 0)
    
    local currentHeader = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    currentHeader:SetPoint("TOPLEFT", 170, -8)
    currentHeader:SetWidth(70)
    currentHeader:SetText("Current")
    currentHeader:SetTextColor(1, 0.82, 0)
    
    local highestHeader = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    highestHeader:SetPoint("TOPLEFT", 250, -8)
    highestHeader:SetWidth(70)
    highestHeader:SetText("Highest")
    highestHeader:SetTextColor(1, 0.82, 0)
    
    -- Create a container for the slot rows
    local rowsContainer = CreateFrame("Frame", "CDTRowsContainer", tableFrame)
    rowsContainer:SetWidth(tableFrame:GetWidth())
    rowsContainer:SetHeight(800) -- Set a fixed height initially
    
    -- Create a scrollframe for the rows
    local scrollFrame = CreateFrame("ScrollFrame", "CDTScrollFrame", tableFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", headerContainer, "BOTTOMLEFT", 0, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", tableFrame, "BOTTOMRIGHT", -30, 0)
    scrollFrame:SetScrollChild(rowsContainer)
    
    -- Tab click handler
    local function OnTabClick(self)
        -- Set selected tab
        frame.selectedTab = self:GetID()
        
        -- Update tab appearance
        UpdateTabAppearance()
        
        if self:GetID() == 1 then
            mainContent:Show()
            debugContent:Hide()
        else
            mainContent:Hide()
            debugContent:Show()
            -- Update debug info when switching to debug tab
            if frame.UpdateDebugInfo then
                frame.UpdateDebugInfo()
            end
            -- Update scroll frames when switching tabs
            if frame.UpdateScrollFrames then
                frame.UpdateScrollFrames()
            end
        end
    end
    
    mainTab:SetScript("OnClick", OnTabClick)
    debugTab:SetScript("OnClick", OnTabClick)
    
    -- Initialize tab system
    frame.selectedTab = 1
    UpdateTabAppearance()
    
    -- Store references
    frame.titleText = titleText
    frame.summaryText = summaryText
    frame.tableFrame = tableFrame
    frame.headerContainer = headerContainer
    frame.rowsContainer = rowsContainer
    frame.scrollFrame = scrollFrame
    frame.slotFrames = {}
    frame.debugText = debugText
    frame.mainContent = mainContent
    frame.debugContent = debugContent
    frame.mainTab = mainTab
    frame.debugTab = debugTab
    
    -- Function to update debug info
    frame.UpdateDebugInfo = function()
        local debugInfo = {}
        
        table.insert(debugInfo, "|cFFFFD700CrestDiscountTracker Debug Information:|r")
        table.insert(debugInfo, "")
        
        -- Add addon info
        table.insert(debugInfo, "|cFF00CCFF[Addon Info]|r")
        if addon.CrestDiscountTracker then
            table.insert(debugInfo, "Current target slot: " .. addon.CrestDiscountTracker.currentTargetSlot)
        end
        table.insert(debugInfo, "Frame size: " .. math.floor(frame:GetWidth()) .. "x" .. math.floor(frame:GetHeight()))
        table.insert(debugInfo, "Number of slot frames: " .. (#frame.slotFrames or 0))
        table.insert(debugInfo, "")
        
        -- Add slot mappings
        table.insert(debugInfo, "|cFF00CCFF[Slot Mappings]|r")
        for slotName, slotID in pairs(addon.Core.SlotManager:GetAllSlots()) do
            table.insert(debugInfo, string.format("  %s: Internal ID=%d", slotName, slotID))
        end
        table.insert(debugInfo, "")
        
        -- Add WoW inventory slot info
        table.insert(debugInfo, "|cFF00CCFF[WoW Inventory Slots]|r")
        for i = 1, 19 do
            local itemLink = GetInventoryItemLink("player", i)
            local itemName = itemLink and GetItemInfo(itemLink) or "No item"
            table.insert(debugInfo, string.format("  Slot %d: %s", i, itemName))
        end
        table.insert(debugInfo, "")
        
        -- Add slot data
        table.insert(debugInfo, "|cFF00CCFF[Current Slot Data]|r")
        local slotData, summaryData = addon.Data.DataCollector:CollectSlotData("all")
        if slotData then
            table.insert(debugInfo, "Found " .. #slotData .. " slots:")
            for i, data in ipairs(slotData) do
                table.insert(debugInfo, string.format("  %d. %s (ID: %d) - Current: %d, Highest: %d", 
                    i, data.name, data.slotID, data.currentLevel, data.highestLevel))
            end
        else
            table.insert(debugInfo, "Error collecting slot data: " .. (summaryData or "Unknown error"))
        end
        
        -- Set the debug text
        frame.debugText:SetText(table.concat(debugInfo, "\n"))
    end
    
    -- Function to update scroll frames after resize
    frame.UpdateScrollFrames = function()
        -- Update debug scroll child
        local debugScrollChild = frame.debugText:GetParent()
        if debugScrollChild then
            debugScrollChild:SetWidth(frame.debugContent:GetWidth() - 30)
        end
        
        -- Update main scroll child
        if frame.rowsContainer then
            frame.rowsContainer:SetWidth(frame.tableFrame:GetWidth() - 30)
        end
    end
    
    -- Call UpdateScrollFrames when size changes
    frame:HookScript("OnSizeChanged", function()
        frame.UpdateScrollFrames()
    end)
    
    return frame
end 