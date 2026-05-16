local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

local Feature = {
    name = "PlayerLinks",
    description = "Chat filters Player Links from Alliance Chat Links",
    message_channel = "FROZENGUILDCHAT_PLAYERINFO"
}

local mirrorlist = {
    "benchguild",
    "deutschguild",
    "gagtransfer",
    "galaguild",
    "glitzerguild",
    "undertransfe",
    "migguild",
    "klayguild",
    "kernhund",
    "coaguild"
}

local remap_mirror = function(orig_player)
    if table.Contains(mirrorlist, orig_player:lower()) then
        return "M"
    end
    return orig_player
end

function Feature:PlayerColorStr(playername)
    
    -- Try fetch UnitClass from known space (raid, guild, bg)
    local _, retUnitClass = UnitClass(playername)
    if retUnitClass then
        self:MemoPlayerClass(playername, retUnitClass)
    end

    -- Can just use playername as we only use
    local guildchatinfo = FrozenGuildChat:GetDB(Feature.name)
    if guildchatinfo[playername] and guildchatinfo[playername].class then
        local raid_color_entry = RAID_CLASS_COLORS[guildchatinfo[playername].class]
        if (raid_color_entry) then
            return raid_color_entry.colorStr
        end 
    end

    -- Fallback to default if we have no entry / cannot retrieve via API
    local DEFAULT_COLOR = "ffffffff"
    return DEFAULT_COLOR
end

function Feature:SharePlayerClass(to_player)
    local data = {
        class = select(2, UnitClass("player"))
    }

    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

    print(serialized)

    SendAddonMessage(self.message_channel, encoded, "WHISPER", to_player)
end

function Feature:ReceivePlayerClass(from_player, payload)
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then return end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return end
    local success, data = LibSerialize:Deserialize(decompressed)
    if not success then return end

    self:MemoPlayerClass(from_player, data.class)
end

function Feature:MemoPlayerClass(from_player, player_class)
    local db = FrozenGuildChat:GetDB(self.name)
    if not db[from_player] then
        db[from_player] = {}
    end
    db[from_player].class = player_class
end

function Feature:OnLogin()
    --- Find any cross name link
    local pattern = "%[(%w*)%]%[(%w*)%]"

    -- Define the filter function
    function FilterChatMessage(frame, event, msg, player, ...)
        -- Match the full pattern: [GuildHandle][Player] msg
        local startPos, endPos, guildprefix, playername = msg:find(pattern)

        -- We are returning from failure => skip and just resolve immediately
        if startPos and guildprefix and playername then
            local playerlinkname = guildprefix.."-"..playername
            FrozenGuildChat:Debug("Found cross-guild message from "..playerlinkname)

            -- Generate player link
            local playerlink = "|c"..Feature:PlayerColorStr(playername).."|Hplayer:"..playername.."|h["..playerlinkname.."]|h|r"
            -- Replace the entire matched string with the in-game link
            msg = msg:gsub(pattern, playerlink)
        end

        player = remap_mirror(player)

        -- Return false to allow the message to display
        return false, msg, player, ...
    end

    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", FilterChatMessage)

    local rec_guildchatinfo = CreateFrame("Frame")
    rec_guildchatinfo:RegisterEvent("CHAT_MSG_ADDON")
    rec_guildchatinfo:SetScript("OnEvent", function(self, event, addonPrefix, chatType, sourceName, ...) 
        if event == "CHAT_MSG_ADDON" and addonPrefix == self.message_channel then
            local msg = ...
            Feature:ReceivePlayerClass(sourceName, msg)
        end
    end)

    print "Loaded FrozenGuildChat:PlayerLinks"
end

-- Register with core
FrozenGuildChat:RegisterFeature(Feature)