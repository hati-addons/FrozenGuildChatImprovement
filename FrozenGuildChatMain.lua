local ADDON_NAME = ...
FrozenGuildChat = FrozenGuildChat or CreateFrame("Frame", ADDON_NAME .. "Frame")

FrozenGuildChat.features = {}
FrozenGuildChatDB = FrozenGuildChatDB or {}

function FrozenGuildChat:InitDB()
    FrozenGuildChatDB.features = FrozenGuildChatDB.features or {}
    for name in pairs(self.features) do
        if FrozenGuildChatDB.features[name] == nil then
            FrozenGuildChatDB.features[name] = true
            if self.features[name].enabledByDefault ~= nil then
                FrozenGuildChatDB.features[name] = self.features[name].enabledByDefault
            end
        end
    end
end

function FrozenGuildChat:RegisterFeature(feature)
    if not feature or not feature.name then
        error("FrozenGuildChat: Feature must have a name")
        return
    end

    self.features[feature.name] = feature
end

function FrozenGuildChat:GetFeature(name)
    if self.features[name] then
        return self.features[name]
    end
    return nil
    
end

--------------------------------------------------
-- Events
--------------------------------------------------
FrozenGuildChat:RegisterEvent("ADDON_LOADED")
FrozenGuildChat:RegisterEvent("PLAYER_LOGIN")

FrozenGuildChat:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            self:InitDB()
            self:OnAddonLoaded()
        end
    elseif event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    end
end)

--------------------------------------------------
-- Event Handlers
--------------------------------------------------
function FrozenGuildChat:OnAddonLoaded()
    FrozenGuildChat:Log("loaded.")
end

function FrozenGuildChat:OnPlayerLogin()
    self:Enablefeatures()
end

function FrozenGuildChat:Enablefeatures()
    for name, feature in pairs(self.features) do
        if feature.OnLogin then
            feature:OnLogin()
        end
        if FrozenGuildChatDB.features[name] ~= false then
            if feature.Enable then
                feature:Enable()
            end
        end
    end
end

SLASH_FROZENGUILDCHAT1 = "/frozenguildchat"
SlashCmdList["FROZENGUILDCHAT"] = function(msg)
    if not msg or msg:trim() == "" then
        for key, value in pairs(FrozenGuildChatDB.features) do
            FrozenGuildChat:Log(key.."="..(value and "enabled" or "disabled"))
        end
        return
    end
    msg = msg:trim()
    if FrozenGuildChatDB.features[msg] ~= nil then
        FrozenGuildChatDB.features[msg] = not FrozenGuildChatDB.features[msg]
        FrozenGuildChat:Log(msg..(FrozenGuildChatDB.features[msg] and " enabled" or " disabled")..". ReloadUI to load proper state.")
    else
        FrozenGuildChat:Log("Feature '" .. msg .. "' not found.")
    end
end

function FrozenGuildChat:Log(msg)
    print("|cFF66CCFFFrozenGuildChat|r: "..msg)
end

--------------------------------------------------
-- Debug helper
--------------------------------------------------

local DebugFeature = {
    name = "Debug",
    description = "Debug functinonality for FrozenGuildChat",
    enabledByDefault = false
}

function FrozenGuildChat:Debug(msg)
    -- Enable if needed
    if FrozenGuildChatDB.features[DebugFeature.name] then
        print("|cFF66CCFFFrozenGuildChat|r:", msg)
    end
end

FrozenGuildChat:RegisterFeature(DebugFeature)
