local _, ns = ...

local ROW_HEIGHT = 22
local NUM_ROWS = 12
local FRAME_WIDTH = 560
local FRAME_HEIGHT = 560 -- garder en phase avec tools/make_textures.py
local MEDIA = "Interface\\AddOns\\Tokebecicite\\Media\\"

local frame
local rows = {}
local filtered = {}
local filterText = ""
local favoritesOnlyView = false

local function CreateCheck(parent, label, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    fs:SetText(label)
    cb.label = fs
    cb:SetScript("OnClick", function(self)
        onClick(self:GetChecked() and true or false)
    end)
    return cb
end

local function CreateButton(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function CreateEditBox(parent, width)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 20)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(255)
    return eb
end

-- Panneau sombre semi-transparent pour garder le texte lisible sur le drapeau
local function CreatePanel(parent, top, bottom)
    local tex = parent:CreateTexture(nil, "BORDER", nil, -8)
    tex:SetPoint("TOPLEFT", 8, top)
    tex:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", -8, bottom)
    parent.panels = parent.panels or {}
    parent.panels[#parent.panels + 1] = tex
    return tex
end

local function SetPanelOpacity(parent, alpha)
    for _, tex in ipairs(parent.panels) do
        tex:SetColorTexture(0, 0, 0, alpha)
    end
end

-- Slider sans template : OptionsSliderTemplate n'est pas fiable sur le client moderne
local function CreateSlider(parent, minValue, maxValue, step, lowText, highText, onChange)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetSize(220, 16)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouseWheel(true)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(1, 1, 1, 0.35)
    track:SetHeight(4)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")

    local label = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("BOTTOM", slider, "TOP", 0, 2)
    local low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
    low:SetText(lowText)
    local high = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
    high:SetText(highText)

    slider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value / step + 0.5) * step
        label:SetText(onChange(value))
    end)
    slider:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta * step)
    end)
    return slider
end

-- Contour noir sur tous les textes de la fenêtre : lisibles même sur la
-- croix blanche du drapeau, sans devoir le cacher sous des panneaux sombres.
local function OutlineText(parent)
    for _, region in ipairs({ parent:GetRegions() }) do
        if region:IsObjectType("FontString") then
            local font, size = region:GetFont()
            if font then region:SetFont(font, size, "OUTLINE") end
        end
    end
    for _, child in ipairs({ parent:GetChildren() }) do
        OutlineText(child)
    end
end

local GOLD = { 1, 0.82, 0 }

-- Favori : fleur dorée. Sinon : fleur blanche pâle. Le disque sombre derrière
-- la garde visible autant sur le bleu que sur la croix blanche du drapeau.
local function SetFleur(button, isFavorite, hovered)
    if hovered then
        button.icon:SetVertexColor(1, 0.92, 0.5, 1)
    elseif isFavorite then
        button.icon:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
    else
        button.icon:SetVertexColor(1, 1, 1, 0.45)
    end
end

local function UpdateFiltered()
    wipe(filtered)
    local query = strlower(filterText)
    for _, entry in ipairs(ns.list) do
        if (not favoritesOnlyView or ns.IsFavorite(entry.text))
            and (query == "" or strlower(entry.text):find(query, 1, true)) then
            filtered[#filtered + 1] = entry
        end
    end
end

local function Refresh()
    if not frame or not frame:IsShown() then return end
    local db = ns.db

    frame.autoLogin:SetChecked(db.autoLogin)
    frame.loginFav:SetChecked(db.loginFavoritesOnly)
    frame.manualFav:SetChecked(db.manualFavoritesOnly)
    frame.randomOrder:SetChecked(db.randomOrder)
    frame.delay:SetValue(db.loginDelay)
    frame.opacity:SetValue(math.floor(db.panelOpacity * 100 + 0.5))
    frame.minimapButton:SetChecked(not db.minimap.hide)

    local said, total = ns.CycleProgress(db.manualFavoritesOnly)
    frame.cycleLabel:SetFormattedText("Cycle: %d / %d citations dites", said, total)

    UpdateFiltered()
    frame.countLabel:SetFormattedText("%d citations, %d favoris", #ns.list, ns.CountFavorites())

    FauxScrollFrame_Update(frame.scroll, #filtered, NUM_ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(frame.scroll)
    for i, row in ipairs(rows) do
        local entry = filtered[offset + i]
        if entry then
            row.entry = entry
            SetFleur(row.fav, ns.IsFavorite(entry.text))
            row.text:SetText(entry.text)
            if entry.custom then
                row.text:SetTextColor(0.6, 0.85, 1)
                row.delete:Show()
            else
                row.text:SetTextColor(1, 1, 1)
                row.delete:Hide()
            end
            row:Show()
        else
            row.entry = nil
            row:Hide()
        end
    end
end
ns.RefreshOptions = Refresh

local function SetRowHover(row, hovered)
    row.hover:SetShown(hovered)
    row.accent:SetShown(hovered)
end

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent.scroll, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", parent.scroll, "RIGHT", 0, 0)

    -- Bandes sombres alternées : chaque ligne reste lisible sur le drapeau
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, index % 2 == 0 and 0.25 or 0.4)

    -- Survol : ligne plus foncée + barre dorée à gauche (visible sur le blanc)
    row.hover = row:CreateTexture(nil, "BORDER")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(0, 0, 0, 0.35)
    row.hover:Hide()
    row.accent = row:CreateTexture(nil, "OVERLAY")
    row.accent:SetPoint("TOPLEFT")
    row.accent:SetPoint("BOTTOMLEFT")
    row.accent:SetWidth(3)
    row.accent:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
    row.accent:Hide()

    -- Bouton favori : fleur de lys sur un disque sombre
    row.fav = CreateFrame("Button", nil, row)
    row.fav:SetSize(20, 20)
    row.fav:SetPoint("LEFT", 6, 0)
    local disc = row.fav:CreateTexture(nil, "BACKGROUND")
    disc:SetPoint("CENTER")
    disc:SetSize(20, 20)
    disc:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    disc:SetVertexColor(0, 0, 0, 0.65)
    row.fav.icon = row.fav:CreateTexture(nil, "ARTWORK")
    row.fav.icon:SetPoint("CENTER")
    row.fav.icon:SetSize(16, 16)
    row.fav.icon:SetTexture(MEDIA .. "FleurDeLys")
    row.fav:SetScript("OnClick", function(self)
        local text = row.entry.text
        ns.SetFavorite(text, not ns.IsFavorite(text))
        Refresh()
        self:GetScript("OnEnter")(self) -- met à jour l'infobulle
    end)
    row.fav:SetScript("OnEnter", function(self)
        SetRowHover(row, true)
        SetFleur(self, ns.IsFavorite(row.entry.text), true)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(ns.IsFavorite(row.entry.text) and "Retirer des favoris" or "Ajouter aux favoris")
        GameTooltip:Show()
    end)
    row.fav:SetScript("OnLeave", function(self)
        SetRowHover(row, false)
        SetFleur(self, ns.IsFavorite(row.entry.text))
        GameTooltip:Hide()
    end)

    row.delete = CreateButton(row, "X", 24, function()
        ns.RemoveCustom(row.entry.text)
        Refresh()
    end)
    row.delete:SetPoint("RIGHT", -2, 0)

    row.say = CreateButton(row, "Dire", 50, function()
        ns.SendToCurrentChat(row.entry.text)
    end)
    row.say:SetPoint("RIGHT", -30, 0)

    -- Garder la ligne surlignée quand la souris est sur ses boutons
    for _, child in ipairs({ row.say, row.delete }) do
        child:HookScript("OnEnter", function() SetRowHover(row, true) end)
        child:HookScript("OnLeave", function() SetRowHover(row, false) end)
    end

    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.fav, "RIGHT", 6, 0)
    row.text:SetPoint("RIGHT", row.say, "LEFT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)

    row:SetScript("OnEnter", function(self)
        SetRowHover(self, true)
        -- Texte complet en infobulle seulement si la citation est tronquée
        if self.text.IsTruncated and self.text:IsTruncated() then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.entry.text, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        SetRowHover(self, false)
        GameTooltip:Hide()
    end)

    return row
end

local function CreateOptionsFrame()
    local db = ns.db
    local f = CreateFrame("Frame", "TokebeciciteOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnShow", Refresh)
    tinsert(UISpecialFrames, f:GetName()) -- Échap ferme la fenêtre

    if f.TitleText then
        f.TitleText:SetText("Tokebecicite")
    else
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -5)
        title:SetText("Tokebecicite")
    end

    -- Fond : drapeau du Québec ---------------------------------------------
    if f.Inset then f.Inset:Hide() end
    local flag = f:CreateTexture(nil, "BACKGROUND", nil, 7)
    flag:SetTexture(MEDIA .. "QuebecFlag")
    flag:SetPoint("TOPLEFT", 2, -22)
    flag:SetPoint("BOTTOMRIGHT", -2, 2)

    CreatePanel(f, -28, -206)                                 -- options
    CreatePanel(f, -208, -(FRAME_HEIGHT - 56))                -- liste
    CreatePanel(f, -(FRAME_HEIGHT - 54), -(FRAME_HEIGHT - 8)) -- ajout
    SetPanelOpacity(f, db.panelOpacity)

    -- Options ---------------------------------------------------------------
    local header = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", 16, -34)
    header:SetText("Options")

    f.autoLogin = CreateCheck(f, "Citation dans la guilde au login", function(v)
        db.autoLogin = v
    end)
    f.autoLogin:SetPoint("TOPLEFT", 14, -52)

    f.loginFav = CreateCheck(f, "Au login: favoris seulement", function(v)
        db.loginFavoritesOnly = v
    end)
    f.loginFav:SetPoint("TOPLEFT", 14, -76)

    f.randomOrder = CreateCheck(f, "Ordre aléatoire (sinon dans l'ordre)", function(v)
        db.randomOrder = v
    end)
    f.randomOrder:SetPoint("TOPLEFT", 284, -52)

    f.manualFav = CreateCheck(f, "/tokebec: favoris seulement", function(v)
        db.manualFavoritesOnly = v
        Refresh()
    end)
    f.manualFav:SetPoint("TOPLEFT", 284, -76)

    f.delay = CreateSlider(f, 2, 30, 1, "2 s", "30 s", function(value)
        db.loginDelay = value
        return format("Délai au login: %d s", value)
    end)
    f.delay:SetPoint("TOPLEFT", 24, -130)

    -- Opacité des panneaux sombres : plus bas = plus de drapeau visible
    f.opacity = CreateSlider(f, 0, 80, 5, "0 %", "80 %", function(value)
        db.panelOpacity = value / 100
        SetPanelOpacity(f, db.panelOpacity)
        return format("Fond sombre: %d %%", value)
    end)
    f.opacity:SetPoint("TOPLEFT", 24, -176)

    f.minimapButton = CreateCheck(f, "Bouton sur la minicarte", function(v)
        ns.SetMinimapButtonShown(v)
    end)
    f.minimapButton:SetPoint("TOPLEFT", 284, -170)

    f.cycleLabel = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    f.cycleLabel:SetPoint("TOPLEFT", 288, -116)

    local resetCycle = CreateButton(f, "Recommencer le cycle", 160, function()
        ns.ResetCycle()
        Refresh()
    end)
    resetCycle:SetPoint("TOPLEFT", 286, -132)

    -- Liste des citations ---------------------------------------------------
    local listHeader = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    listHeader:SetPoint("TOPLEFT", 16, -214)
    listHeader:SetText("Citations")

    local search = CreateEditBox(f, 170)
    search:SetPoint("LEFT", listHeader, "RIGHT", 14, 0)
    local placeholder = search:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", 2, 0)
    placeholder:SetText("Rechercher...")
    search:SetScript("OnTextChanged", function(self)
        filterText = self:GetText() or ""
        placeholder:SetShown(filterText == "")
        FauxScrollFrame_SetOffset(f.scroll, 0)
        f.scroll:SetVerticalScroll(0)
        Refresh()
    end)

    local favView = CreateCheck(f, "Favoris seulement", function(v)
        favoritesOnlyView = v
        FauxScrollFrame_SetOffset(f.scroll, 0)
        f.scroll:SetVerticalScroll(0)
        Refresh()
    end)
    favView:SetPoint("LEFT", search, "RIGHT", 10, 0)

    f.countLabel = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    f.countLabel:SetPoint("TOPRIGHT", -16, -216)

    local scroll = CreateFrame("ScrollFrame", "TokebeciciteOptionsScroll", f, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -236)
    scroll:SetPoint("TOPRIGHT", -34, -236)
    scroll:SetHeight(NUM_ROWS * ROW_HEIGHT)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, Refresh)
    end)
    f.scroll = scroll

    for i = 1, NUM_ROWS do
        rows[i] = CreateRow(f, i)
    end

    -- Ajouter une citation --------------------------------------------------
    local addBox = CreateEditBox(f, 400)
    addBox:SetPoint("BOTTOMLEFT", 22, 18)
    local addLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    addLabel:SetPoint("BOTTOMLEFT", addBox, "TOPLEFT", -4, 4)
    addLabel:SetText("Ajouter ta propre citation:")

    local function AddFromBox()
        local ok, err = ns.AddCustom(addBox:GetText())
        if ok then
            addBox:SetText("")
            addBox:ClearFocus()
            Refresh()
        else
            ns.Print(err)
        end
    end
    addBox:SetScript("OnEnterPressed", AddFromBox)

    local addButton = CreateButton(f, "Ajouter", 100, AddFromBox)
    addButton:SetPoint("LEFT", addBox, "RIGHT", 10, 0)

    OutlineText(f)
    return f
end

function ns.ToggleOptions()
    if not frame then
        frame = CreateOptionsFrame()
        frame:Hide()
    end
    frame:SetShown(not frame:IsShown())
end
