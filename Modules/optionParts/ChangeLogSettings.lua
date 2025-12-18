--[[
    CritMatic Advanced Settings
    Changelog styling and data management
]]

local LSM = LibStub("LibSharedMedia-3.0")
Critmatic = Critmatic or {}
local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")

-- Reset functions
local function ResetChangeLogAppearance()
    Critmatic.db.profile.changeLogPopUp = defaults.profile.changeLogPopUp
    Critmatic:Print("|cffed9d09CritMatic Reborn|r: Changelog appearance reset to defaults.")
end

-- Allowed border textures
local allowedBorders = {
    ["Blizzard Achievement Wood"] = true,
    ["Blizzard Tooltip"] = true,
    ["Blizzard Dialog"] = true,
    ["Blizzard Dialog Gold"] = true,
    ["None"] = true,
}

local function GetFilteredBorders()
    local borders = {}
    local allBorders = LSM:HashTable("border")
    for name, path in pairs(allBorders) do
        if allowedBorders[name] then
            borders[name] = path
        end
    end
    return borders
end

local function GetFilteredBackgrounds()
    local backgrounds = {}
    local allBackgrounds = LSM:HashTable("background")
    for name, path in pairs(allBackgrounds) do
        if name ~= "None" then
            backgrounds[name] = path
        end
    end
    return backgrounds
end

function Critmatic:ChangeLogSettings_Initialize()
    return {
        name = "Advanced",
        type = "group",
        order = 6,
        childGroups = "tab",
        args = {
            -- ═══════════════════════════════════════════════════════════
            -- CHANGELOG APPEARANCE TAB
            -- ═══════════════════════════════════════════════════════════
            changelogTab = {
                name = "Changelog Style",
                type = "group",
                order = 1,
                args = {
                    changelogDesc = {
                        name = "Customize the appearance of the changelog popup window.",
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
                        desc = "Select the font for changelog text.",
                        type = "select",
                        dialogControl = "LSM30_Font",
                        values = LSM:HashTable("font"),
                        order = 1.1,
                        width = 1.5,
                        get = function() return Critmatic.db.profile.changeLogPopUp.fontSettings.font end,
                        set = function(_, val) Critmatic.db.profile.changeLogPopUp.fontSettings.font = val end,
                    },
                    fontSize = {
                        name = "Size",
                        desc = "Font size for changelog text.",
                        type = "range",
                        min = 8, max = 24, step = 1,
                        order = 1.2,
                        width = 1,
                        get = function() return Critmatic.db.profile.changeLogPopUp.fontSettings.fontSize end,
                        set = function(_, val) Critmatic.db.profile.changeLogPopUp.fontSettings.fontSize = val end,
                    },
                    fontColor = {
                        name = "Text Color",
                        desc = "Color for changelog text.",
                        type = "color",
                        hasAlpha = false,
                        order = 1.3,
                        width = 1,
                        get = function() return unpack(Critmatic.db.profile.changeLogPopUp.fontSettings.fontColor) end,
                        set = function(_, r, g, b) Critmatic.db.profile.changeLogPopUp.fontSettings.fontColor = {r, g, b} end,
                    },
                    fontOutline = {
                        name = "Outline",
                        desc = "Text outline style.",
                        type = "select",
                        values = {
                            [""] = "None",
                            ["OUTLINE"] = "Thin",
                            ["THICKOUTLINE"] = "Thick",
                            ["OUTLINEMONOCHROME"] = "Mono",
                            ["THICKOUTLINEMONOCHROME"] = "Thick Mono",
                        },
                        order = 1.4,
                        width = 1,
                        get = function() return Critmatic.db.profile.changeLogPopUp.fontSettings.fontOutline end,
                        set = function(_, val) Critmatic.db.profile.changeLogPopUp.fontSettings.fontOutline = val end,
                    },

                    -- Frame Settings
                    frameHeader = {
                        name = "|cffffd700Frame|r",
                        type = "header",
                        order = 2,
                    },
                    backgroundTexture = {
                        name = "Background",
                        desc = "Background texture for the changelog window.",
                        type = "select",
                        dialogControl = "LSM30_Background",
                        values = GetFilteredBackgrounds,
                        order = 2.1,
                        width = 1.5,
                        get = function() return Critmatic.db.profile.changeLogPopUp.borderAndBackgroundSettings.backgroundTexture end,
                        set = function(_, val) Critmatic.db.profile.changeLogPopUp.borderAndBackgroundSettings.backgroundTexture = val end,
                    },
                    borderTexture = {
                        name = "Border",
                        desc = "Border style for the changelog window.",
                        type = "select",
                        dialogControl = "LSM30_Border",
                        values = GetFilteredBorders,
                        order = 2.2,
                        width = 1.5,
                        get = function() return Critmatic.db.profile.changeLogPopUp.borderAndBackgroundSettings.borderTexture end,
                        set = function(_, val) Critmatic.db.profile.changeLogPopUp.borderAndBackgroundSettings.borderTexture = val end,
                    },
                    borderSize = {
                        name = "Border Size",
                        desc = "Thickness of the border.",
                        type = "range",
                        min = 1, max = 32, step = 1,
                        order = 2.3,
                        width = 1.5,
                        get = function() return Critmatic.db.profile.changeLogPopUp.borderAndBackgroundSettings.borderSize end,
                        set = function(_, val) Critmatic.db.profile.changeLogPopUp.borderAndBackgroundSettings.borderSize = val end,
                    },

                    spacer2 = { type = "description", name = " ", order = 3 },
                    resetChangelog = {
                        name = "Reset Changelog Style",
                        desc = "Reset changelog appearance to default settings.",
                        type = "execute",
                        order = 4,
                        func = ResetChangeLogAppearance,
                        confirm = true,
                        confirmText = "Reset changelog appearance to defaults?",
                    },
                },
            },

            -- ═══════════════════════════════════════════════════════════
            -- DATA MANAGEMENT TAB
            -- ═══════════════════════════════════════════════════════════
            dataTab = {
                name = "Data",
                type = "group",
                order = 2,
                args = {
                    dataDesc = {
                        name = "Manage your CritMatic data and records.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },
                    spacer1 = { type = "description", name = " ", order = 0.5 },

                    -- Actions
                    actionsHeader = {
                        name = "|cffffd700Actions|r",
                        type = "header",
                        order = 1,
                    },
                    openChangelog = {
                        name = "View Changelog",
                        desc = "Open the changelog to see recent updates.",
                        type = "execute",
                        order = 1.1,
                        width = 1.2,
                        func = function()
                            Critmatic:OpenChangeLog()
                        end,
                    },
                    openCritLog = {
                        name = "Open Crit Log",
                        desc = "Show the Crit Log window.",
                        type = "execute",
                        order = 1.2,
                        width = 1.2,
                        func = function()
                            if toggleCritMaticCritLog then
                                Critmatic.db.profile.isCritLogFrameShown = true
                                toggleCritMaticCritLog()
                            end
                        end,
                    },

                    -- Danger Zone
                    dangerHeader = {
                        name = "|cffff0000Danger Zone|r",
                        type = "header",
                        order = 2,
                    },
                    dangerWarning = {
                        name = "|cffff6b6bWarning: These actions cannot be undone!|r",
                        type = "description",
                        order = 2.1,
                        fontSize = "small",
                    },
                    spacer2 = { type = "description", name = " ", order = 2.2 },
                    resetAllData = {
                        name = "|cffff0000Reset All Data|r",
                        desc = "Delete all recorded spell data. This cannot be undone!",
                        type = "execute",
                        order = 3,
                        width = 1.5,
                        confirm = true,
                        confirmText = "|cffff0000WARNING|r\n\nThis will permanently delete ALL your CritMatic records!\n\nAre you absolutely sure?",
                        func = function()
                            Critmatic:CritMaticReset()
                        end,
                    },

                    -- Slash Commands Reference
                    spacer3 = { type = "description", name = "\n\n", order = 4 },
                    commandsHeader = {
                        name = "|cffffd700Slash Commands|r",
                        type = "header",
                        order = 5,
                    },
                    commandsList = {
                        name = [[
|cffffd700/cm|r - Open settings
|cffffd700/cmcritlog|r - Toggle Crit Log window
|cffffd700/cmlog|r - Open changelog
|cffffd700/cmhelp|r - Show all commands
|cffffd700/cmignore <spell>|r - Ignore a spell
|cffffd700/cmreset|r - Reset all data
]],
                        type = "description",
                        order = 5.1,
                        fontSize = "medium",
                    },
                },
            },
        },
    }
end
