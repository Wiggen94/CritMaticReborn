--[[
    CritMatic General Settings
    Core addon settings: display, notifications, and startup options
]]

Critmatic = Critmatic or {}
local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")

function Critmatic:GeneralTab_Initialize()
    return {
        name = "General",
        type = "group",
        order = 1,
        args = {
            -- ═══════════════════════════════════════════════════════════
            -- DISPLAY SECTION
            -- ═══════════════════════════════════════════════════════════
            displayHeader = {
                name = "|cffffd700Display|r",
                type = "header",
                order = 1,
            },
            displayDesc = {
                name = "Control the Crit Log window visibility and behavior.",
                type = "description",
                order = 1.1,
                fontSize = "medium",
            },
            showCritLogWindow = {
                name = "Show Crit Log Window",
                desc = "Toggle the Crit Log window visibility. You can also use |cffffd700/cmcritlog|r",
                type = "toggle",
                order = 1.2,
                width = 1.5,
                set = function(_, newVal)
                    Critmatic.db.profile.isCritLogFrameShown = newVal
                    if newVal then
                        if Critmatic.crit_log_frame and Critmatic.crit_log_frame.frame then
                            Critmatic.crit_log_frame.frame:Show()
                            if RedrawCritMaticWidget then
                                RedrawCritMaticWidget()
                            end
                        else
                            if toggleCritMaticCritLog then
                                toggleCritMaticCritLog()
                            end
                        end
                    else
                        if Critmatic.crit_log_frame and Critmatic.crit_log_frame.frame then
                            Critmatic.crit_log_frame.frame:Hide()
                        end
                    end
                end,
                get = function()
                    return Critmatic.db.profile.isCritLogFrameShown
                end,
            },
            lockCritLogPosition = {
                name = "Lock Position",
                desc = "Prevent the Crit Log window from being moved.",
                type = "toggle",
                order = 1.3,
                width = 1,
                set = function(_, newVal)
                    Critmatic.db.profile.critLogWidgetPos.lock = newVal
                end,
                get = function()
                    return Critmatic.db.profile.critLogWidgetPos.lock
                end,
            },

            -- ═══════════════════════════════════════════════════════════
            -- NOTIFICATIONS SECTION
            -- ═══════════════════════════════════════════════════════════
            notificationsHeader = {
                name = "|cffffd700Notifications|r",
                type = "header",
                order = 2,
            },
            notificationsDesc = {
                name = "Choose how you want to be notified about new records.",
                type = "description",
                order = 2.1,
                fontSize = "medium",
            },
            alertNotificationsEnabled = {
                name = "Screen Alerts",
                desc = "Show animated notifications on screen when you hit a new record.",
                type = "toggle",
                order = 2.2,
                width = 1.2,
                set = function(_, newVal)
                    Critmatic.db.profile.generalSettings.alertNotificationsEnabled = newVal
                end,
                get = function()
                    return Critmatic.db.profile.generalSettings.alertNotificationsEnabled
                end,
            },
            chatNotificationsEnabled = {
                name = "Chat Messages",
                desc = "Print notifications to your chat window when you hit a new record.",
                type = "toggle",
                order = 2.3,
                width = 1.2,
                set = function(_, newVal)
                    Critmatic.db.profile.generalSettings.chatNotificationsEnabled = newVal
                end,
                get = function()
                    return Critmatic.db.profile.generalSettings.chatNotificationsEnabled
                end,
            },

            -- ═══════════════════════════════════════════════════════════
            -- STARTUP SECTION
            -- ═══════════════════════════════════════════════════════════
            startupHeader = {
                name = "|cffffd700Startup|r",
                type = "header",
                order = 3,
            },
            isChangeLogAutoPopUpEnabled = {
                name = "Show Changelog on Updates",
                desc = "Automatically display the changelog when CritMatic is updated to a new version.",
                type = "toggle",
                order = 3.1,
                width = "full",
                set = function(_, newVal)
                    Critmatic.db.profile.generalSettings.isChangeLogAutoPopUpEnabled = newVal
                end,
                get = function()
                    return Critmatic.db.profile.generalSettings.isChangeLogAutoPopUpEnabled
                end,
            },

        }
    }
end
