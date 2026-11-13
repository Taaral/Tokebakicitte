local ADDON_NAME, ns = ...

local ICON = "Interface\\AddOns\\Tokebecicite\\Media\\FlagIcon"
local DEFAULT_ANGLE = 225 -- en bas à gauche de la minicarte

local button

-- Formes de minicarte (GetMinimapShape) : pour chaque quadrant, vrai si le
-- coin est arrondi. Permet de suivre le bord d'une minicarte carrée (ElvUI, etc.).
local SHAPES = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function UpdatePosition()
    local angle = math.rad(ns.db.minimap.angle)
    local x, y = math.cos(angle), math.sin(angle)
    local quadrant = 1
    if x < 0 then quadrant = quadrant + 1 end
    if y > 0 then quadrant = quadrant + 2 end

    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local rounded = (SHAPES[shape] or SHAPES.ROUND)[quadrant]
    local w = Minimap:GetWidth() / 2 + 5
    local h = Minimap:GetHeight() / 2 + 5
    if rounded then
        x, y = x * w, y * h
    else
        local diagW = math.sqrt(2 * w * w) - 10
        local diagH = math.sqrt(2 * h * h) - 10
        x = math.max(-w, math.min(x * diagW, w))
        y = math.max(-h, math.min(y * diagH, h))
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    ns.db.minimap.angle = math.deg(math.atan2(py - my, px - mx)) % 360
    UpdatePosition()
end

local function CreateButton()
    button = CreateFrame("Button", "TokebeciciteMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Dimensions reprises de LibDBIcon : la bordure de 50x50 ancrée en haut à
    -- gauche a son anneau centré sur le bouton de 31x31, donc le fond et
    -- l'icône sont simplement centrés sur le bouton.
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(24, 24)
    background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexture(ICON)
    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            ns.SendToCurrentChat()
        else
            ns.ToggleOptions()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnDragUpdate)
        GameTooltip:Hide()
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Tokebecicite")
        GameTooltip:AddLine("Clic gauche: favoris et options", 1, 1, 1)
        GameTooltip:AddLine("Clic droit: dire une citation", 1, 1, 1)
        GameTooltip:AddLine("Glisser: déplacer le bouton", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    UpdatePosition()
end

function ns.UpdateMinimapButton()
    local settings = ns.db.minimap
    if settings.hide then
        if button then button:Hide() end
        return
    end
    if not button then CreateButton() end
    button:Show()
end

function ns.SetMinimapButtonShown(shown)
    ns.db.minimap.hide = not shown
    ns.UpdateMinimapButton()
end

-- Menu des add-ons du client moderne (## AddonCompartmentFunc dans le .toc)
function Tokebecicite_OnAddonCompartmentClick()
    ns.ToggleOptions()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    if ns.db.minimap.angle == nil then ns.db.minimap.angle = DEFAULT_ANGLE end
    ns.UpdateMinimapButton()
end)
