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
    
    -- Summary frame
    local summaryFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    summaryFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
    summaryFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -40)
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
    local tableFrame = CreateFrame("Frame", nil, frame)
    tableFrame:SetPoint("TOPLEFT", summaryFrame, "BOTTOMLEFT", 0, -10)
    tableFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    
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
    rowsContainer:SetSize(tableFrame:GetWidth(), 800) -- Set a fixed height initially
    
    -- Create a scrollframe for the rows
    local scrollFrame = CreateFrame("ScrollFrame", "CDTScrollFrame", tableFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", headerContainer, "BOTTOMLEFT", 0, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", tableFrame, "BOTTOMRIGHT", -30, 0)
    scrollFrame:SetScrollChild(rowsContainer)
    
    -- Store references
    frame.titleText = titleText
    frame.summaryText = summaryText
    frame.tableFrame = tableFrame
    frame.headerContainer = headerContainer
    frame.rowsContainer = rowsContainer
    frame.scrollFrame = scrollFrame
    frame.slotFrames = {}
    
    return frame
end 