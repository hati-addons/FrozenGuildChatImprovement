local Feature = {
    name = "DBItemLink",
    description = "Chat filters Item Links from DB Links",
}

--- [[
--- @class PendingItemLoads
--- @field msg string original chat message
--- @field player string original player name
--- @field event string Chat event
--- @field frame Frame the frame that triggered this message
--- @field other table packed additional (...) data send with the event
--- ]]
local pendingItemLoads = {}
--- [[
--- @class FailuresForItemIds
--- ]]
local failuresForItemId = {}
--- Const
local FAILURE_LIMIT = 5
--- Flag to avoid triggering multiple queries at the same time
local DispatcherQueried = false

local queuedLineIds = {}

function DispatchLatentResolve(itemId)
    if not DispatcherQueried then
        DispatcherQueried = true
        C_Timer.After(0.05, function ()
            ProcessPendingMessages()
        end)
    end
end

if not string.insert then
    function string.insert(str1, str2, pos)
        return str1:sub(1,pos)..str2..str1:sub(pos+1)
    end
end

local bannedChatFrames = {
    ["WIM_workerFrame"] = true ---[[ @TODO(hati) fix WIM support ]]
}

function Feature:OnLogin()
    local QueryTooltip = CreateFrame("GameTooltip")
    
    --- Find any item=ItemId in a message
    local pattern = "%<?%[?[^%s]*item=(%d+)[^%s]*%]?>?"

    local DbLinkPrefixPattern = function(itemid)
        -- Capture anything that is kind of [Item Name with potential spaces]*item=MatchingId
        return "(.*)%[?(%[.*%])%]?(%(?[^%s]*item="..itemid.."%)?)"
    end

    function ProcessPendingMessages()
        DispatcherQueried = false
        for itemId, messages in pairs(pendingItemLoads) do
            local itemLink = GetItemLink(itemId)
            FrozenGuildChat:Debug("Trying to resolve pending itemid msg: "..itemId)
            if itemLink then  -- Item data is now available
                for _, msgData in ipairs(messages) do
                    FrozenGuildChat:Debug("Successfully resolved pending itemLink: "..itemId.." ItemLink: "..itemLink)
                    local msg, player, event, frame = msgData.msg, msgData.player, msgData.event, msgData.frame
                    -- Resend the unmodified message via original frame
                    ChatFrame_OnEvent(frame, event, msg, player, unpack(msgData.other))
                end
                -- Clear the pending messages for this item ID
                pendingItemLoads[itemId] = nil
            else
                if not failuresForItemId[itemId] then
                    failuresForItemId[itemId] = 0
                end
                failuresForItemId[itemId] = failuresForItemId[itemId]+1
                if failuresForItemId[itemId] < FAILURE_LIMIT then
                    FrozenGuildChat:Debug("Failed to resolve, "..itemId.." Dispatching another resolve (Failure: "..failuresForItemId[itemId]..")")
                    DispatchLatentResolve(itemId) -- try again with less than 5 failrues
                else
                    FrozenGuildChat:Debug("Fully failed to resolve "..itemId.." Dispatching the original message (Failure: "..failuresForItemId[itemId]..")")
                    -- Still have not found item data, just send the regular message
                    for _, msgData in ipairs(messages) do
                        local msg, player, event, frame = msgData.msg, msgData.player, msgData.event, msgData.frame
                        -- Resend the original message via original frame
                        if frame and not bannedChatFrames[frame:GetName()] then -- Exclude banned frames for inter-com issues
                            ChatFrame_OnEvent(frame, event, msg, player, unpack(msgData.other))
                        end
                    end
                    -- Resetting the failure attempts after resending
                    failuresForItemId[itemId] = 0
                    -- Voiding message as invalid itemId
                    pendingItemLoads[itemId] = nil
                end
            end
        end
    end

    -- Define the filter function
    function FilterChatMessage(frame, event, msg, player, ...)
        -- Example: [[Progression 2 Chest Token]](<https://db.ascension.gg/?item=422013>) 
        if not msg:lower():find("item") then
            return false, msg, player, ...
        end

        local lineId = select(9, ...)

        -- Match the full pattern: [[Item Name]](<https://db.ascension.gg/?item=12345>)
        local startPos, endPos, itemId = msg:find(pattern)
        -- We are returning from failure => skip and just resolve immediately
        if startPos and itemId and failuresForItemId[itemId] and failuresForItemId[itemId] >= FAILURE_LIMIT then
            FrozenGuildChat:Debug("Falling back for failed item resolve to original message "..itemId)
            return false, msg, player, ...
        end

        if startPos and itemId then
            FrozenGuildChat:Debug("Message received and filtering "..msg)
            -- Generate the in-game item link
            local itemLink = GetItemLink(tonumber(itemId))
            if not itemLink then
                -- Request item info from server
                if queuedLineIds[lineId] then -- don't queue multiple line ids
                    return false, msg, player, ...
                end
                queuedLineIds[lineId] = true

                if not pendingItemLoads[itemId] then
                    pendingItemLoads[itemId] = {}
                end

                -- Create pending entry and dispatch server query
                FrozenGuildChat:Debug("Uncached item. Querying from server.")

                table.insert(pendingItemLoads[itemId], {
                    msg = msg,
                    player = player,
                    event = event,
                    frame = frame,
                    other = {...},
                })

                QueryTooltip:SetHyperlink("item:" .. itemId)
                DispatchLatentResolve(itemId)
                return true -- block message from chat as dispatched to once item is loaded
            end
    
            if itemLink then
                -- Append the entire matched string with the in-game link
                local item_name_ref_pattern = DbLinkPrefixPattern(itemId)
                local dblink_startPos, dblink_endPos, itemText = msg:find(item_name_ref_pattern)
                if dblink_startPos and itemText then -- We have a start and some potential capture to replace
                    -- replace our captured "itemlink like with the real item link"
                    msg = msg:gsub(item_name_ref_pattern, function (prefix, match, rest) return prefix..itemLink..rest end)
                else
                    msg = string.insert(msg, itemLink, endPos)
                end

                FrozenGuildChat:Debug("Resolved itemLink immediately showing message "..msg)
            end
        end

        table.remove(queuedLineIds, lineId)
    
        -- Return false to allow the message to display
        return false, msg, player, ...
    end

    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FilterChatMessage)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", FilterChatMessage)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", FilterChatMessage)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", FilterChatMessage)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", FilterChatMessage)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", FilterChatMessage)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", FilterChatMessage)

    print "Loaded FrozenGuildChat:DBItemLink"
end

-- Register with core
FrozenGuildChat:RegisterFeature(Feature)