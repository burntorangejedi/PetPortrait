local AceGUI = LibStub("AceGUI-3.0")
local PetPortrait = LibStub("AceAddon-3.0"):NewAddon("PetPortrait")

local petPortraitWindow

local lastPetID

local function GetSelectedPetID()
    if PetJournalPetCard and PetJournalPetCard.petID then
        return PetJournalPetCard.petID
    end
    if PetJournal and PetJournal.listScroll and PetJournal.listScroll.selectedPetID then
        return PetJournal.listScroll.selectedPetID
    end
    return nil
end

local function ShowPetPortrait(petID)
    if not petPortraitWindow then
        petPortraitWindow = AceGUI:Create("Frame")
        petPortraitWindow:SetTitle("Pet Portrait")
        petPortraitWindow:SetWidth(350)
        petPortraitWindow:SetHeight(400)
        petPortraitWindow:EnableResize(true)
        
        -- Create a container for the model
        local container = AceGUI:Create("SimpleGroup")
        container:SetFullWidth(true)
        container:SetHeight(300)
        petPortraitWindow:AddChild(container)
        
        -- Create the player model
        local model = CreateFrame("PlayerModel", nil, container.frame)
        model:SetAllPoints(true)
        container.frame:SetFrameLevel(container.frame:GetFrameLevel() + 1)
        
        -- Track rotation state
        local isRotating = false
        local lastMouseX = 0
        local currentYaw = 0
        
        -- Handle mouse down (right-click to start rotation)
        model:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                isRotating = true
                lastMouseX = GetCursorPosition()
            end
        end)
        
        -- Handle mouse up (stop rotation)
        model:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                isRotating = false
            end
        end)
        
        -- Handle mouse motion during rotation
        model:SetScript("OnUpdate", function(self)
            if isRotating then
                local x = GetCursorPosition()
                local delta = (x - lastMouseX) * 0.005
                currentYaw = currentYaw + delta
                self:SetRotation(currentYaw)
                lastMouseX = x
            end
        end)
        
        -- Enable mouse for the model
        model:EnableMouse(true)
        model:SetScript("OnMouseWheel", function(self, delta)
            -- Optional: allow scroll wheel to zoom (if supported)
        end)
        
        -- Store the model for later access
        petPortraitWindow.model = model
    end
    
    if petPortraitWindow.model and petID then
        local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, companionID, unused = C_PetJournal.GetPetInfoByPetID(petID)
        if displayID then
            petPortraitWindow.model:SetDisplayInfo(displayID)
        end
    end
    
    petPortraitWindow:Show()
end

local function OnPetSelected(petID)
    if petPortraitWindow and petPortraitWindow:IsShown() then
        if petPortraitWindow.model and petID then
            local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, companionID, unused = C_PetJournal.GetPetInfoByPetID(petID)
            if displayID then
                petPortraitWindow.model:SetDisplayInfo(displayID)
            end
        end
    end
    lastPetID = petID
end

local function AddButtonToPetJournal()
    if PetJournal and PetJournal.SummonButton and not PetJournal.EnlargeButton then
        local btn = CreateFrame("Button", nil, PetJournal, "UIPanelButtonTemplate")
        btn:SetText("Enlarge")
        btn:SetSize(70, 22)
        btn:SetPoint("LEFT", PetJournal.SummonButton, "RIGHT", 8, 0)
        btn:SetScript("OnClick", function()
            local petID = GetSelectedPetID()
            if petID then
                ShowPetPortrait(petID)
            end
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Show Large Portrait", 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        PetJournal.EnlargeButton = btn
    end
end

function PetPortrait:OnInitialize()
    -- Addon initialization
end

function PetPortrait:OnEnable()
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local addon = ...
            if addon == "Blizzard_Collections" then
                AddButtonToPetJournal()
            end
        elseif event == "PET_JOURNAL_LIST_UPDATE" then
            AddButtonToPetJournal()
        end
    end)
    
    -- Poll for pet selection changes while PetJournal is shown
    local pollFrame = CreateFrame("Frame")
    pollFrame:SetScript("OnUpdate", function()
        if PetJournal and PetJournal:IsShown() then
            local petID = GetSelectedPetID()
            if petID and petID ~= lastPetID then
                OnPetSelected(petID)
            end
        end
    end)
end
