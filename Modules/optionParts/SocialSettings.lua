--[[
    CritMatic Sharing Settings
    Social broadcasting configuration for parties, raids, guilds, and battlegrounds
]]

Critmatic = Critmatic or {}
local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")

function Critmatic:SocialSettings_Initialize()
    return {
        name = "Sharing",
        type = "group",
        order = 4,
        args = {
            sharingDesc = {
                name = "Control where CritMatic broadcasts your new records to other players.",
                type = "description",
                order = 0,
                fontSize = "medium",
            },
            spacer1 = { type = "description", name = " ", order = 0.5 },

            -- ═══════════════════════════════════════════════════════════
            -- BROADCAST CHANNELS
            -- ═══════════════════════════════════════════════════════════
            channelsHeader = {
                name = "|cffffd700Broadcast Channels|r",
                type = "header",
                order = 1,
            },
            channelsNote = {
                name = "Enable channels where you want to share your new record achievements with other CritMatic users.",
                type = "description",
                order = 1.1,
                fontSize = "small",
            },

            canSendCritsToParty = {
                name = "|cff00ccffParty|r",
                desc = "Share your new records with party members who also have CritMatic.",
                type = "toggle",
                order = 2,
                width = 1.2,
                get = function() return Critmatic.db.profile.social.canSendCritsToParty end,
                set = function(_, val) Critmatic.db.profile.social.canSendCritsToParty = val end,
            },
            canSendCritsToRaid = {
                name = "|cffff7f00Raid|r",
                desc = "Share your new records with raid members who also have CritMatic.",
                type = "toggle",
                order = 3,
                width = 1.2,
                get = function() return Critmatic.db.profile.social.canSendCritsToRaid end,
                set = function(_, val) Critmatic.db.profile.social.canSendCritsToRaid = val end,
            },
            canSendCritsToGuild = {
                name = "|cff40ff40Guild|r",
                desc = "Share your new records with guild members who also have CritMatic.",
                type = "toggle",
                order = 4,
                width = 1.2,
                get = function() return Critmatic.db.profile.social.canSendCritsToGuild end,
                set = function(_, val) Critmatic.db.profile.social.canSendCritsToGuild = val end,
            },
            canSendCritsToBattleGrounds = {
                name = "|cffff0000Battlegrounds|r",
                desc = "Share your new records in battlegrounds with other CritMatic users.",
                type = "toggle",
                order = 5,
                width = 1.2,
                get = function() return Critmatic.db.profile.social.canSendCritsToBattleGrounds end,
                set = function(_, val) Critmatic.db.profile.social.canSendCritsToBattleGrounds = val end,
            },

            -- Info note
            spacer2 = { type = "description", name = " ", order = 6 },
            infoNote = {
                name = "|cff888888Note: Records are only shared with other players who have CritMatic installed. Messages are sent via addon communication channels, not chat.|r",
                type = "description",
                order = 7,
                fontSize = "small",
            },
        },
    }
end
