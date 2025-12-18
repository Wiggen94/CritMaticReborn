--[[
    CritMatic Alert Settings
    Screen notification configuration: timing, messages, and appearance
]]

local notification_constructor = Critmatic:NewModule("notification_constructor")
local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")
local LSM = LibStub("LibSharedMedia-3.0")

-- Reset functions
local function ResetTimingToDefault()
    local defaults = defaults.profile.alertNotificationFormat.global
    Critmatic.db.profile.alertNotificationFormat.global.maxMessages = defaults.maxMessages
    Critmatic.db.profile.alertNotificationFormat.global.startDelay = defaults.startDelay
    Critmatic.db.profile.alertNotificationFormat.global.fadeTime = defaults.fadeTime
    Critmatic:Print("|cffed9d09CritMatic Reborn|r: Timing settings reset to defaults.")
end

local function ResetMessagesToDefault()
    Critmatic.db.profile.alertNotificationFormat.strings = defaults.profile.alertNotificationFormat.strings
    Critmatic.db.profile.alertNotificationFormat.global.isUpper = defaults.profile.alertNotificationFormat.global.isUpper
    Critmatic:Print("|cffed9d09CritMatic Reborn|r: Message formats reset to defaults.")
end

local function ResetAppearanceToDefault()
    Critmatic.db.profile.fontSettings = defaults.profile.fontSettings
    Critmatic:Print("|cffed9d09CritMatic Reborn|r: Appearance settings reset to defaults.")
end

function notification_constructor:OnInitialize() end
function notification_constructor:OnEnable() end

-- Preview notification with random spell
function notification_constructor:formatConstructor(message, isDamage, isCrit, sound_string)
    local spellNames = isDamage and {
        "Fireball", "Shadow Bolt", "Chain Lightning", "Death Coil", "Starfire",
        "Eviscerate", "Mind Blast", "Heroic Strike", "Arcane Shot", "Judgment"
    } or {
        "Circle of Healing", "Rejuvenation", "Lay on Hands", "Renew", "Riptide",
        "Holy Light", "Lifebloom", "Healing Rain", "Soothing Mist", "Penance"
    }

    local spellName = spellNames[math.random(#spellNames)]
    local amount = math.random(500, 8000)
    local text = string.format(message, spellName, amount)

    if Critmatic.db.profile.alertNotificationFormat.global.isUpper then
        text = string.upper(text)
    end

    local r, g, b = unpack(isCrit
        and Critmatic.db.profile.fontSettings.fontColorCrit
        or Critmatic.db.profile.fontSettings.fontColor)

    Critmatic.MessageFrame:CreateMessage(text, r, g, b)

    -- Play sound if not muted
    if not Critmatic.db.profile.soundSettings.muteAllSounds then
        local soundMap = {
            soundCrit = "damageCrit",
            soundHit = "damageNormal",
            soundCritHeal = "healCrit",
            soundHeal = "healNormal"
        }
        local soundKey = soundMap[sound_string]
        if soundKey then
            local sound = LSM:Fetch("sound", Critmatic.db.profile.soundSettings[soundKey])
            if sound then PlaySoundFile(sound) end
        end
    end
end

function Critmatic:AlertFontSettings_Initialize()
    return {
        name = "Alerts",
        type = "group",
        order = 2,
        childGroups = "tab",
        args = {
            -- ═══════════════════════════════════════════════════════════
            -- TIMING TAB
            -- ═══════════════════════════════════════════════════════════
            timingTab = {
                name = "Timing",
                type = "group",
                order = 1,
                args = {
                    timingDesc = {
                        name = "Control how long alerts stay on screen and how they fade out.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },
                    spacer1 = { type = "description", name = " ", order = 0.5 },

                    maxMessages = {
                        name = "Maximum Messages",
                        desc = "How many alert messages can be shown at once.",
                        type = "range",
                        min = 1, max = 8, step = 1,
                        order = 1,
                        width = "full",
                        get = function() return Critmatic.db.profile.alertNotificationFormat.global.maxMessages end,
                        set = function(_, val) Critmatic.db.profile.alertNotificationFormat.global.maxMessages = val end,
                    },
                    startDelay = {
                        name = "Display Duration",
                        desc = "How long (in seconds) the alert stays visible before fading.",
                        type = "range",
                        min = 1, max = 15, step = 0.5,
                        order = 2,
                        width = "full",
                        get = function() return Critmatic.db.profile.alertNotificationFormat.global.startDelay end,
                        set = function(_, val) Critmatic.db.profile.alertNotificationFormat.global.startDelay = val end,
                    },
                    fadeTime = {
                        name = "Fade Duration",
                        desc = "How long (in seconds) the fade-out animation takes.",
                        type = "range",
                        min = 0, max = 3, step = 0.1,
                        order = 3,
                        width = "full",
                        get = function() return Critmatic.db.profile.alertNotificationFormat.global.fadeTime end,
                        set = function(_, val) Critmatic.db.profile.alertNotificationFormat.global.fadeTime = val end,
                    },
                    spacer2 = { type = "description", name = " ", order = 4 },
                    resetTiming = {
                        name = "Reset Timing",
                        desc = "Reset all timing settings to their default values.",
                        type = "execute",
                        order = 5,
                        func = ResetTimingToDefault,
                        confirm = true,
                        confirmText = "Reset timing settings to defaults?",
                    },
                },
            },

            -- ═══════════════════════════════════════════════════════════
            -- MESSAGES TAB
            -- ═══════════════════════════════════════════════════════════
            messagesTab = {
                name = "Messages",
                type = "group",
                order = 2,
                args = {
                    messagesDesc = {
                        name = "Customize the text format for each notification type.\nUse |cffffd700%s|r for spell name and |cffffd700%d|r for damage/healing amount.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },
                    spacer1 = { type = "description", name = " ", order = 0.5 },

                    isUpper = {
                        name = "UPPERCASE Text",
                        desc = "Display all alert text in uppercase letters.",
                        type = "toggle",
                        order = 1,
                        width = "full",
                        get = function() return Critmatic.db.profile.alertNotificationFormat.global.isUpper end,
                        set = function(_, val) Critmatic.db.profile.alertNotificationFormat.global.isUpper = val end,
                    },

                    -- Damage Section
                    damageHeader = {
                        name = "|cffff6b6bDamage|r",
                        type = "header",
                        order = 2,
                    },
                    critFormat = {
                        name = "Critical Hit Format",
                        type = "input",
                        width = "double",
                        order = 2.1,
                        get = function() return Critmatic.db.profile.alertNotificationFormat.strings.critAlertNotificationFormat end,
                        set = function(_, val) Critmatic.db.profile.alertNotificationFormat.strings.critAlertNotificationFormat = val end,
                    },
                    previewCrit = {
                        name = "Preview",
                        type = "execute",
                        order = 2.2,
                        width = 0.6,
                        func = function()
                            notification_constructor:formatConstructor(
                                Critmatic.db.profile.alertNotificationFormat.strings.critAlertNotificationFormat,
                                true, true, "soundCrit")
                        end,
                    },
                    hitFormat = {
                        name = "Normal Hit Format",
                        type = "input",
                        width = "double",
                        order = 2.3,
                        get = function() return Critmatic.db.profile.alertNotificationFormat.strings.hitAlertNotificationFormat end,
                        set = function(_, val) Critmatic.db.profile.alertNotificationFormat.strings.hitAlertNotificationFormat = val end,
                    },
                    previewHit = {
                        name = "Preview",
                        type = "execute",
                        order = 2.4,
                        width = 0.6,
                        func = function()
                            notification_constructor:formatConstructor(
                                Critmatic.db.profile.alertNotificationFormat.strings.hitAlertNotificationFormat,
                                true, false, "soundHit")
                        end,
                    },

                    -- Healing Section
                    healingHeader = {
                        name = "|cff69db7cHealing|r",
                        type = "header",
                        order = 3,
                    },
                    critHealFormat = {
                        name = "Critical Heal Format",
                        type = "input",
                        width = "double",
                        order = 3.1,
                        get = function() return Critmatic.db.profile.alertNotificationFormat.strings.critHealAlertNotificationFormat end,
                        set = function(_, val) Critmatic.db.profile.alertNotificationFormat.strings.critHealAlertNotificationFormat = val end,
                    },
                    previewCritHeal = {
                        name = "Preview",
                        type = "execute",
                        order = 3.2,
                        width = 0.6,
                        func = function()
                            notification_constructor:formatConstructor(
                                Critmatic.db.profile.alertNotificationFormat.strings.critHealAlertNotificationFormat,
                                false, true, "soundCritHeal")
                        end,
                    },
                    healFormat = {
                        name = "Normal Heal Format",
                        type = "input",
                        width = "double",
                        order = 3.3,
                        get = function() return Critmatic.db.profile.alertNotificationFormat.strings.healAlertNotificationFormat end,
                        set = function(_, val) Critmatic.db.profile.alertNotificationFormat.strings.healAlertNotificationFormat = val end,
                    },
                    previewHeal = {
                        name = "Preview",
                        type = "execute",
                        order = 3.4,
                        width = 0.6,
                        func = function()
                            notification_constructor:formatConstructor(
                                Critmatic.db.profile.alertNotificationFormat.strings.healAlertNotificationFormat,
                                false, false, "soundHeal")
                        end,
                    },

                    spacer2 = { type = "description", name = " ", order = 4 },
                    resetMessages = {
                        name = "Reset Messages",
                        desc = "Reset all message formats to their default values.",
                        type = "execute",
                        order = 5,
                        func = ResetMessagesToDefault,
                        confirm = true,
                        confirmText = "Reset message formats to defaults?",
                    },
                },
            },

            -- ═══════════════════════════════════════════════════════════
            -- APPEARANCE TAB
            -- ═══════════════════════════════════════════════════════════
            appearanceTab = {
                name = "Appearance",
                type = "group",
                order = 3,
                args = {
                    appearanceDesc = {
                        name = "Customize the visual style of alert notifications.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },
                    spacer1 = { type = "description", name = " ", order = 0.5 },

                    -- Font Settings
                    fontHeader = {
                        name = "|cffffd700Font|r",
                        type = "header",
                        order = 1,
                    },
                    font = {
                        name = "Font Family",
                        desc = "Select the font for alert text.",
                        type = "select",
                        dialogControl = "LSM30_Font",
                        values = LSM:HashTable("font"),
                        order = 1.1,
                        width = 1.5,
                        get = function() return Critmatic.db.profile.fontSettings.font end,
                        set = function(_, val) Critmatic.db.profile.fontSettings.font = val end,
                    },
                    fontSize = {
                        name = "Size",
                        desc = "Font size for alert text.",
                        type = "range",
                        min = 12, max = 48, step = 1,
                        order = 1.2,
                        width = 1,
                        get = function() return Critmatic.db.profile.fontSettings.fontSize end,
                        set = function(_, val) Critmatic.db.profile.fontSettings.fontSize = val end,
                    },
                    fontOutline = {
                        name = "Outline",
                        desc = "Text outline style.",
                        type = "select",
                        values = {
                            ["NONE"] = "None",
                            ["OUTLINE"] = "Thin",
                            ["THICKOUTLINE"] = "Thick",
                            ["OUTLINEMONOCHROME"] = "Mono",
                            ["THICKOUTLINEMONOCHROME"] = "Thick Mono",
                        },
                        order = 1.3,
                        width = 1,
                        get = function() return Critmatic.db.profile.fontSettings.fontOutline end,
                        set = function(_, val) Critmatic.db.profile.fontSettings.fontOutline = val end,
                    },

                    -- Colors
                    colorsHeader = {
                        name = "|cffffd700Colors|r",
                        type = "header",
                        order = 2,
                    },
                    fontColorCrit = {
                        name = "Critical Color",
                        desc = "Color for critical hit/heal notifications.",
                        type = "color",
                        hasAlpha = false,
                        order = 2.1,
                        width = 1.2,
                        get = function() return unpack(Critmatic.db.profile.fontSettings.fontColorCrit) end,
                        set = function(_, r, g, b) Critmatic.db.profile.fontSettings.fontColorCrit = {r, g, b} end,
                    },
                    fontColor = {
                        name = "Normal Color",
                        desc = "Color for normal hit/heal notifications.",
                        type = "color",
                        hasAlpha = false,
                        order = 2.2,
                        width = 1.2,
                        get = function() return unpack(Critmatic.db.profile.fontSettings.fontColor) end,
                        set = function(_, r, g, b) Critmatic.db.profile.fontSettings.fontColor = {r, g, b} end,
                    },

                    -- Shadow
                    shadowHeader = {
                        name = "|cffffd700Shadow|r",
                        type = "header",
                        order = 3,
                    },
                    fontShadowX = {
                        name = "Horizontal Offset",
                        desc = "Shadow offset on the X axis.",
                        type = "range",
                        min = -10, max = 10, step = 1,
                        order = 3.1,
                        width = 1,
                        get = function() return Critmatic.db.profile.fontSettings.fontShadowSize[1] end,
                        set = function(_, val) Critmatic.db.profile.fontSettings.fontShadowSize[1] = val end,
                    },
                    fontShadowY = {
                        name = "Vertical Offset",
                        desc = "Shadow offset on the Y axis.",
                        type = "range",
                        min = -10, max = 10, step = 1,
                        order = 3.2,
                        width = 1,
                        get = function() return Critmatic.db.profile.fontSettings.fontShadowSize[2] end,
                        set = function(_, val) Critmatic.db.profile.fontSettings.fontShadowSize[2] = val end,
                    },
                    fontShadowColor = {
                        name = "Shadow Color",
                        desc = "Color of the text shadow.",
                        type = "color",
                        hasAlpha = false,
                        order = 3.3,
                        width = 1,
                        get = function() return unpack(Critmatic.db.profile.fontSettings.fontShadowColor) end,
                        set = function(_, r, g, b) Critmatic.db.profile.fontSettings.fontShadowColor = {r, g, b} end,
                    },

                    spacer2 = { type = "description", name = " ", order = 4 },
                    resetAppearance = {
                        name = "Reset Appearance",
                        desc = "Reset all appearance settings to their default values.",
                        type = "execute",
                        order = 5,
                        func = ResetAppearanceToDefault,
                        confirm = true,
                        confirmText = "Reset appearance settings to defaults?",
                    },
                },
            },
        },
    }
end
