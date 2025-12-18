--[[
    CritMatic Database Defaults
    Defines the default configuration values for the addon
]]

defaults = {
    profile = {
        -- General settings
        generalSettings = {
            alertNotificationsEnabled = true,
            chatNotificationsEnabled = true,
            isChangeLogAutoPopUpEnabled = true,
        },

        -- Alert notification format settings
        alertNotificationFormat = {
            global = {
                isUpper = true,
                maxMessages = 4,
                startDelay = 7.5,
                fadeTime = 0.5,
            },
            strings = {
                critAlertNotificationFormat = "New %s Crit: %d!",
                hitAlertNotificationFormat = "New %s Hit: %d!",
                critHealAlertNotificationFormat = "New %s Crit Heal: %d!",
                healAlertNotificationFormat = "New %s Heal: %d!",
            },
        },

        -- Chat notification format settings
        chatNotificationFormat = {
            global = {
                isUpper = false,
            },
            strings = {
                critChatNotificationFormat = "New highest %s Crit: %d!",
                hitChatNotificationFormat = "New highest %s Hit: %d!",
                critHealChatNotificationFormat = "New highest %s Crit Heal: %d!",
                healChatNotificationFormat = "New highest %s Heal: %d!",
            },
        },

        -- Font settings for alert notifications
        fontSettings = {
            font = "Anton",
            fontOutline = "OUTLINEMONOCHROME",
            fontSize = 22,
            fontColorCrit = { 1, 0.84, 0 },      -- Gold color for crits
            fontColor = { 0.9, 0.9, 0.9 },       -- White for normal hits
            fontShadowSize = { 3, -3 },
            fontShadowColor = { 0.1, 0.1, 0.1 }, -- Near-black shadow
        },

        -- Sound settings
        soundSettings = {
            damageNormal = "Heroism Cast",
            damageCrit = "Level Up",
            healNormal = "Heaven",
            healCrit = "Level Up",
            muteAllSounds = false,
        },

        -- Social broadcasting settings
        social = {
            canSendCritsToParty = true,
            canSendCritsToGuild = false,
            canSendCritsToRaid = true,
            canSendCritsToBattleGrounds = true,
        },

        -- Changelog popup settings
        changeLogPopUp = {
            borderAndBackgroundSettings = {
                backgroundTexture = "Blizzard Parchment 2",
                borderTexture = "Blizzard Achievement Wood",
                borderSize = 15,
            },
            fontSettings = {
                font = "Friz Quadrata TT",
                fontColor = { 0.1, 0.1, 0.1 },
                fontOutline = "",
                fontSize = 13,
            },
        },

        -- Crit log widget settings
        isCritLogFrameShown = true,
        critLogWidgetPos = {
            anchor = "RIGHT",
            anchor2 = "RIGHT",
            pos_x = -90.8942287109375,
            pos_y = -114.91058349609,
            size_x = 255,
            size_y = 125,
            lock = false,
        },

        -- Version tracking
        oldVersion = "0.0.0",
        dataCleared = false,
    },
}
