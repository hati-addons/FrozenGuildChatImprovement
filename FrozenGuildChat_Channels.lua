local Feature = {
    name = "ChannelMute",
    description = "Chat filters to hide certain channels",
}

function Feature:OnLogin()
    local db = FrozenGuildChat:GetDB(Feature.name)

    local function ShouldFilter(prefix)
        return (db.filters and db.filters[prefix]) or false
    end

    --- Find any cross name link
    local pattern = "^%[(%w*)%]%[(%w*)%]"

    -- Define the filter function
    function FilterChatMessage(frame, event, msg, player, ...)
        -- Match the full pattern: [GuildHandle][Player] msg
        local startPos, endPos, guildprefix, playername = msg:find(pattern)

        if not guildprefix then -- bypass filter
            return false, msg, player, ...
        end

        -- Return false to allow the message to display
        return ShouldFilter(guildprefix), msg, player, ...
    end

    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", FilterChatMessage)
    print "Loaded FrozenGuildChat:PlayerLinks"
end

function Feature:processcmd(opts, fullmsg)
    local db = FrozenGuildChat:GetDB(Feature.name)
    db.filters = db.filters or {}

    if opts:trim() == "list" then
        local mutedchannels = {}
        local unmutedchannels = {}
        for channelmute in pairs(db.filters) do
            if db.filters[channelmute] then
                tinsert(mutedchannels, channelmute)
            else
                tinsert(unmutedchannels, channelmute)
            end
        end
        FrozenGuildChat:Log("Muted channels: "..string.join(", ", unpack(mutedchannels)))
        FrozenGuildChat:Log("Unmuted channels: "..string.join(", ", unpack(unmutedchannels)))
        return
    end

    for channelmute in string.gmatch(opts, "%a+") do
        db.filters[channelmute] = not (db.filters[channelmute] or false)
        if db.filters[channelmute] then
            FrozenGuildChat:Log("Muting channel: "..channelmute)
        else
            FrozenGuildChat:Log("Unmuting channel: "..channelmute)
        end
    end
end

-- Register with core
FrozenGuildChat:RegisterFeature(Feature)