# v0.5.1

- Fixed Channels not showing until first time ChanneLMute cmd usage (now shows immediately)

# v0.5

- Add ChannelMute feature which allows muting chnanels with `/frozenguildchat ChannelMute <ChannelName>` and `/frozenguildchat ChannelMute list` to list all
- there are also enable/disable cmds per feature like `/frozenguildchat <FeatureName>`

# v0.4

- Add class colors sharing across chats via ADDON whisper channel

# v0.3.1 

- Small fix to avoid duplicate messages when querying from server
- Added alt names for common GuildMirrors

# v0.3

- Critical Fix item links removing rest of the message
- Instead of replacing we add the item link behind an itemID found
- Add: PlayerLinks for cross-guild players, formatted like "GuildTag-PlayerName"

# v0.2

- Added async item link handling, so chat messages are always resolved if the item exists.
- - If a message cannot be resolved the original message is shown after 5 attempts

- Fixed /frozenguildchat command for listing features / enabling / toggling

# v0.1a

- Reduce the pattern to allow item=itemId

# v0.1

- Initial release
- Converts web item links to compatible chat links