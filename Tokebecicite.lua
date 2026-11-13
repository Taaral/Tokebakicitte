local ADDON_NAME, ns = ...

local PREFIX = "|cff3399ffTokebecicite|r: "

-- Compatibilité : le client moderne (WoW Forever) déplace certaines fonctions
-- globales vers des espaces de noms. On prend la version disponible.
local SendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage

local function GetChatEditBox()
    local getActive = ChatEdit_GetActiveWindow
        or (ChatFrameUtil and ChatFrameUtil.GetActiveWindow)
    local getLast = ChatEdit_GetLastActiveWindow
        or (ChatFrameUtil and ChatFrameUtil.GetLastActiveWindow)
    return (getActive and getActive())
        or (getLast and getLast())
        or DEFAULT_CHAT_FRAME.editBox
end

local defaults = {
    autoLogin = true,           -- citation dans la guilde au login
    loginDelay = 5,             -- secondes, laisse le temps au roster de guilde de charger
    loginFavoritesOnly = false, -- au login, piger seulement dans les favoris
    manualFavoritesOnly = false,-- avec /tokebec, piger seulement dans les favoris
    randomOrder = true,         -- sinon, dans l'ordre de la liste
    minimap = {},               -- angle et visibilité du bouton de la minicarte
    panelOpacity = 0.1,         -- opacité des panneaux sombres sur le drapeau
    favorites = {},             -- [texte] = true
    custom = {},                -- citations ajoutées par le joueur
    used = {},                  -- [texte] = true, citations déjà dites dans le cycle courant
}

local db
local lastText

function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end
local Print = ns.Print

-- Liste combinée : citations intégrées puis personnalisées
ns.list = {}

function ns.RebuildList()
    wipe(ns.list)
    for _, text in ipairs(ns.sayings) do
        ns.list[#ns.list + 1] = { text = text }
    end
    for _, text in ipairs(db.custom) do
        ns.list[#ns.list + 1] = { text = text, custom = true }
    end
end

local function Exists(text)
    for _, entry in ipairs(ns.list) do
        if entry.text == text then return true end
    end
    return false
end

function ns.AddCustom(text)
    text = strtrim(text or "")
    if text == "" then return false, "Citation vide." end
    if #text > 255 then return false, "Citation trop longue (max 255 caractères)." end
    if Exists(text) then return false, "Cette citation existe déjà." end
    db.custom[#db.custom + 1] = text
    ns.RebuildList()
    return true
end

function ns.RemoveCustom(text)
    for i, t in ipairs(db.custom) do
        if t == text then
            table.remove(db.custom, i)
            db.favorites[text] = nil
            db.used[text] = nil
            ns.RebuildList()
            return true
        end
    end
    return false
end

function ns.IsFavorite(text)
    return db.favorites[text] == true
end

function ns.SetFavorite(text, value)
    db.favorites[text] = value and true or nil
end

function ns.CountFavorites()
    local n = 0
    for _, entry in ipairs(ns.list) do
        if db.favorites[entry.text] then n = n + 1 end
    end
    return n
end

-- Construit le bassin de citations. Si "favoris seulement" est demandé
-- mais qu'il n'y a aucun favori, on retombe sur toutes les citations.
local function BuildPool(favoritesOnly)
    local pool = {}
    for _, entry in ipairs(ns.list) do
        if not favoritesOnly or db.favorites[entry.text] then
            pool[#pool + 1] = entry.text
        end
    end
    if #pool == 0 and favoritesOnly then
        return BuildPool(false)
    end
    return pool
end

-- Progression du cycle : combien de citations ont été dites sur le total
function ns.CycleProgress(favoritesOnly)
    local pool = BuildPool(favoritesOnly)
    local said = 0
    for _, text in ipairs(pool) do
        if db.used[text] then said = said + 1 end
    end
    return said, #pool
end

function ns.ResetCycle()
    wipe(db.used)
end

-- Pige la prochaine citation. Chaque citation du bassin est dite une fois
-- avant qu'un nouveau cycle commence (le cycle persiste entre les sessions).
function ns.NextSaying(favoritesOnly)
    local pool = BuildPool(favoritesOnly)
    if #pool == 0 then return nil end

    local available = {}
    for _, text in ipairs(pool) do
        if not db.used[text] then available[#available + 1] = text end
    end
    if #available == 0 then
        for _, text in ipairs(pool) do db.used[text] = nil end
        available = pool
    end

    local choice
    if db.randomOrder and #available > 1 then
        -- Évite de répéter la dernière citation quand un nouveau cycle commence
        repeat
            choice = available[math.random(#available)]
        until choice ~= lastText
    else
        choice = available[1]
    end

    db.used[choice] = true
    lastText = choice
    return choice
end

function ns.LastSaying()
    return lastText
end

-- Délai minimum entre deux envois, pour éviter le spam (macro, clics répétés)
local COOLDOWN = 5
local lastSendTime = -math.huge

local function OnCooldown()
    local remaining = COOLDOWN - (GetTime() - lastSendTime)
    if remaining > 0 then
        Print(format("Doucement! Attends encore %d s.", math.ceil(remaining)))
        return true
    end
    lastSendTime = GetTime()
    return false
end

function ns.SendToGuild(text)
    if not IsInGuild() then return false end
    if OnCooldown() then return true end
    text = text or ns.NextSaying(db.loginFavoritesOnly)
    if text then
        SendChat(text, "GUILD")
    end
    return true
end

-- Envoie dans le canal présentement sélectionné dans la boîte de chat
-- (dire, groupe, raid, guilde, chuchotement, canal numéroté, etc.)
function ns.SendToCurrentChat(text)
    if OnCooldown() then return end
    text = text or ns.NextSaying(db.manualFavoritesOnly)
    if not text then return end

    local editBox = GetChatEditBox()
    local chatType = editBox and editBox:GetAttribute("chatType") or "SAY"

    if chatType == "WHISPER" then
        local target = editBox:GetAttribute("tellTarget")
        if not target or target == "" then
            Print("Aucune cible de chuchotement.")
            return
        end
        SendChat(text, "WHISPER", nil, target)
    elseif chatType == "CHANNEL" then
        local channel = editBox:GetAttribute("channelTarget")
        SendChat(text, "CHANNEL", nil, channel)
    elseif chatType == "BN_WHISPER" then
        local target = editBox:GetAttribute("tellTarget")
        local presenceID = target and BNet_GetBNetIDAccount and BNet_GetBNetIDAccount(target)
        if presenceID and BNSendWhisper then
            BNSendWhisper(presenceID, text)
        else
            Print("Impossible de trouver l'ami Battle.net.")
        end
    else
        SendChat(text, chatType)
    end
end

local function Debug(msg)
    if db and db.debug then
        Print("|cff999999[debug]|r " .. msg)
    end
end

-- Au login, les infos de guilde peuvent arriver quelques secondes en retard :
-- on réessaie plusieurs fois avant d'abandonner.
local LOGIN_RETRY_DELAY = 5
local LOGIN_MAX_ATTEMPTS = 6

local function LoginSend(attempt)
    if IsInGuild() then
        Debug("Envoi de la citation de login dans la guilde.")
        local ok, err = pcall(ns.SendToGuild)
        if not ok then
            Print("Erreur à l'envoi: " .. tostring(err))
        end
    elseif attempt < LOGIN_MAX_ATTEMPTS then
        Debug(format("Guilde pas encore chargée, nouvel essai dans %d s (%d/%d).",
            LOGIN_RETRY_DELAY, attempt, LOGIN_MAX_ATTEMPTS))
        C_Timer.After(LOGIN_RETRY_DELAY, function() LoginSend(attempt + 1) end)
    else
        Debug("Aucune guilde détectée, pas de citation au login.")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_ACTION_BLOCKED")
frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if (event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN") and arg1 == ADDON_NAME then
        Print(format("Le jeu a bloqué l'action %s (%s).", tostring(arg2), event))
    elseif event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        TokebeciciteDB = TokebeciciteDB or {}
        db = TokebeciciteDB
        for k, v in pairs(defaults) do
            if db[k] == nil then
                db[k] = type(v) == "table" and {} or v
            end
        end
        db.bgOpacity = nil -- ancien réglage (1.2.0), remplacé par panelOpacity
        ns.db = db
        ns.RebuildList()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- arg1 = isInitialLogin : vrai seulement au login, pas après un /reload
        Debug(format("Entrée dans le monde: login=%s, reload=%s, auto=%s, délai=%d s.",
            tostring(arg1), tostring(arg2), tostring(db.autoLogin), db.loginDelay))
        if arg1 and db.autoLogin then
            C_Timer.After(db.loginDelay, function() LoginSend(1) end)
        end
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

local function ShowHelp()
    Print("Commandes:")
    Print("  /tokebec - envoie une citation dans ton chat actif")
    Print("  /tokebec options - ouvre la fenêtre des favoris et options")
    Print("  /tokebec guilde - envoie une citation dans le chat de guilde")
    Print("  /tokebec fav - ajoute/retire la dernière citation des favoris")
    Print("  /tokebec auto - active/désactive la citation au login (" ..
        (db.autoLogin and "|cff00ff00activé|r" or "|cffff0000désactivé|r") .. ")")
    Print("  /tokebec minimap - affiche/cache le bouton de la minicarte")
    Print("  /tokebec test - affiche une citation pour toi seulement")
end

SLASH_TOKEBECICITE1 = "/tokebec"
SLASH_TOKEBECICITE2 = "/qc"
SlashCmdList.TOKEBECICITE = function(input)
    local cmd = strlower(strtrim(input or ""))
    if cmd == "" then
        ns.SendToCurrentChat()
    elseif cmd == "options" or cmd == "config" or cmd == "opt" then
        ns.ToggleOptions()
    elseif cmd == "minimap" or cmd == "carte" then
        local shown = db.minimap.hide
        ns.SetMinimapButtonShown(shown)
        Print("Bouton de la minicarte " .. (shown and "|cff00ff00affiché|r." or "|cffff0000caché|r."))
        ns.RefreshOptions()
    elseif cmd == "debug" then
        db.debug = not db.debug
        Print("Mode debug " .. (db.debug and "|cff00ff00activé|r." or "|cffff0000désactivé|r."))
    elseif cmd == "guilde" or cmd == "guild" then
        if not ns.SendToGuild() then
            Print("T'es pas dans une guilde.")
        end
    elseif cmd == "fav" then
        if not lastText then
            Print("Aucune citation dite depuis le login.")
            return
        end
        local fav = not ns.IsFavorite(lastText)
        ns.SetFavorite(lastText, fav)
        Print((fav and "Ajoutée aux favoris: " or "Retirée des favoris: ") .. lastText)
        ns.RefreshOptions()
    elseif cmd == "auto" then
        db.autoLogin = not db.autoLogin
        Print("Citation au login " ..
            (db.autoLogin and "|cff00ff00activée|r." or "|cffff0000désactivée|r."))
        ns.RefreshOptions()
    elseif cmd == "test" then
        Print(ns.NextSaying(db.manualFavoritesOnly) or "Aucune citation.")
    else
        ShowHelp()
    end
end
