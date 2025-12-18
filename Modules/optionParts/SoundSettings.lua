--[[
    CritMatic Sound Settings
    Audio feedback configuration for damage and healing events
]]

local LSM = LibStub("LibSharedMedia-3.0")
Critmatic = Critmatic or {}
local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")

local function ResetSoundsToDefault()
    Critmatic.db.profile.soundSettings = defaults.profile.soundSettings
    Critmatic:Print("|cffed9d09CritMatic Reborn|r: Sound settings reset to defaults.")
end

function Critmatic:SoundSettings_Initialize()
    return {
        name = "Sounds",
        type = "group",
        order = 3,
        args = {
            soundsDesc = {
                name = "Configure audio feedback for new damage and healing records.",
                type = "description",
                order = 0,
                fontSize = "medium",
            },
            spacer1 = { type = "description", name = " ", order = 0.5 },

            -- Master Control
            muteAllSounds = {
                name = "|cffff6b6bMute All Sounds|r",
                desc = "Disable all CritMatic sound effects.",
                type = "toggle",
                order = 1,
                width = "full",
                get = function() return Critmatic.db.profile.soundSettings.muteAllSounds end,
                set = function(_, val) Critmatic.db.profile.soundSettings.muteAllSounds = val end,
            },

            -- ═══════════════════════════════════════════════════════════
            -- DAMAGE SOUNDS
            -- ═══════════════════════════════════════════════════════════
            damageHeader = {
                name = "|cffff6b6bDamage Sounds|r",
                type = "header",
                order = 2,
            },
            damageCrit = {
                name = "Critical Hit",
                desc = "Sound to play when you score a new highest critical hit.",
                type = "select",
                dialogControl = "LSM30_Sound",
                values = LSM:HashTable("sound"),
                order = 2.1,
                width = 1.5,
                disabled = function() return Critmatic.db.profile.soundSettings.muteAllSounds end,
                get = function() return Critmatic.db.profile.soundSettings.damageCrit end,
                set = function(_, val) Critmatic.db.profile.soundSettings.damageCrit = val end,
            },
            damageNormal = {
                name = "Normal Hit",
                desc = "Sound to play when you score a new highest normal hit.",
                type = "select",
                dialogControl = "LSM30_Sound",
                values = LSM:HashTable("sound"),
                order = 2.2,
                width = 1.5,
                disabled = function() return Critmatic.db.profile.soundSettings.muteAllSounds end,
                get = function() return Critmatic.db.profile.soundSettings.damageNormal end,
                set = function(_, val) Critmatic.db.profile.soundSettings.damageNormal = val end,
            },

            -- ═══════════════════════════════════════════════════════════
            -- HEALING SOUNDS
            -- ═══════════════════════════════════════════════════════════
            healingHeader = {
                name = "|cff69db7cHealing Sounds|r",
                type = "header",
                order = 3,
            },
            healCrit = {
                name = "Critical Heal",
                desc = "Sound to play when you score a new highest critical heal.",
                type = "select",
                dialogControl = "LSM30_Sound",
                values = LSM:HashTable("sound"),
                order = 3.1,
                width = 1.5,
                disabled = function() return Critmatic.db.profile.soundSettings.muteAllSounds end,
                get = function() return Critmatic.db.profile.soundSettings.healCrit end,
                set = function(_, val) Critmatic.db.profile.soundSettings.healCrit = val end,
            },
            healNormal = {
                name = "Normal Heal",
                desc = "Sound to play when you score a new highest normal heal.",
                type = "select",
                dialogControl = "LSM30_Sound",
                values = LSM:HashTable("sound"),
                order = 3.2,
                width = 1.5,
                disabled = function() return Critmatic.db.profile.soundSettings.muteAllSounds end,
                get = function() return Critmatic.db.profile.soundSettings.healNormal end,
                set = function(_, val) Critmatic.db.profile.soundSettings.healNormal = val end,
            },

            -- Reset
            spacer2 = { type = "description", name = " ", order = 4 },
            resetSounds = {
                name = "Reset Sounds",
                desc = "Reset all sound settings to their default values.",
                type = "execute",
                order = 5,
                func = ResetSoundsToDefault,
                confirm = true,
                confirmText = "Reset sound settings to defaults?",
            },
        },
    }
end
