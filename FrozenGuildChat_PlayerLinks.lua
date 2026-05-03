local Feature = {
    name = "PlayerLinks",
    description = "Chat filters Player Links from Alliance Chat Links",
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
    "kernhund"
}

local remap_mirror = function(orig_player)
    if table.Contains(mirrorlist, orig_player:lower()) then
        return "M"
    end
    return orig_player
end

G_REMAP_MIRROR = remap_mirror

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
            local playerlink = "|cffffffff|Hplayer:"..playername.."|h["..playerlinkname.."]|h|r"
            -- Replace the entire matched string with the in-game link
            msg = msg:gsub(pattern, playerlink)
        end

        player = remap_mirror(player)

        -- Return false to allow the message to display
        return false, msg, player, ...
    end

    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", FilterChatMessage)

    print "Loaded FrozenGuildChat:PlayerLinks"
end

-- Register with core
FrozenGuildChat:RegisterFeature(Feature)