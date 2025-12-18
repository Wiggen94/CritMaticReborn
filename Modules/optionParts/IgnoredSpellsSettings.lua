--[[
    CritMatic Ignored Spells Settings
    Manage spells excluded from tracking and notifications
]]

Critmatic = Critmatic or {}
local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")

function Critmatic:IgnoredSpellsSettings_Initialize()
    return {
        name = "Ignored",
        type = "group",
        order = 5,
        args = {
            ignoredDesc = {
                name = "Manage spells that are excluded from tracking. Ignored spells won't appear in the Crit Log, tooltips, chat, or screen notifications.",
                type = "description",
                order = 0,
                fontSize = "medium",
            },
            spacer1 = { type = "description", name = " ", order = 0.5 },

            -- ═══════════════════════════════════════════════════════════
            -- HOW TO IGNORE
            -- ═══════════════════════════════════════════════════════════
            howToHeader = {
                name = "|cffffd700How to Ignore Spells|r",
                type = "header",
                order = 1,
            },
            howToDesc = {
                name = "• |cffffd700Right-click|r a spell in the Crit Log window\n• Use |cffffd700/cmignore Spell Name|r in chat",
                type = "description",
                order = 1.1,
                fontSize = "medium",
            },

            -- ═══════════════════════════════════════════════════════════
            -- MANAGE IGNORED SPELLS
            -- ═══════════════════════════════════════════════════════════
            manageHeader = {
                name = "|cffffd700Manage Ignored Spells|r",
                type = "header",
                order = 2,
            },
            ignoredSpellSelect = {
                name = "Select Spell",
                desc = "Choose an ignored spell to remove from the list.",
                type = "select",
                order = 2.1,
                width = "double",
                values = function()
                    local spells = {}
                    if Critmatic.ignoredSpells then
                        for spellName, _ in pairs(Critmatic.ignoredSpells) do
                            local displayName = spellName:gsub("(%a)([%w_']*)", function(a, b)
                                return a:upper() .. b
                            end)
                            spells[spellName] = displayName
                        end
                    end
                    if next(spells) == nil then
                        spells["none"] = "|cff888888No ignored spells|r"
                    end
                    return spells
                end,
                get = function()
                    return Critmatic.selectedIgnoredSpell or "none"
                end,
                set = function(_, value)
                    Critmatic.selectedIgnoredSpell = (value ~= "none") and value or nil
                end,
            },
            removeSelected = {
                name = "Remove Selected",
                desc = "Remove the selected spell from the ignored list, allowing it to be tracked again.",
                type = "execute",
                order = 2.2,
                width = 0.9,
                disabled = function()
                    return not Critmatic.selectedIgnoredSpell or Critmatic.selectedIgnoredSpell == "none"
                end,
                func = function()
                    if Critmatic.selectedIgnoredSpell and Critmatic.ignoredSpells then
                        local spellName = Critmatic.selectedIgnoredSpell
                        Critmatic.ignoredSpells[spellName] = nil
                        local displayName = spellName:gsub("(%a)([%w_']*)", function(a, b)
                            return a:upper() .. b
                        end)
                        Critmatic:Print("|cffed9d09" .. displayName .. "|r removed from ignored spells.")
                        Critmatic.selectedIgnoredSpell = nil
                        if RedrawCritMaticWidget then RedrawCritMaticWidget() end
                    end
                end,
            },

            spacer2 = { type = "description", name = " ", order = 3 },

            clearAllIgnored = {
                name = "|cffff6b6bClear All Ignored Spells|r",
                desc = "Remove all spells from the ignored list.",
                type = "execute",
                order = 4,
                disabled = function()
                    return not Critmatic.ignoredSpells or next(Critmatic.ignoredSpells) == nil
                end,
                confirm = true,
                confirmText = "Remove all spells from the ignored list?\n\nThis will allow all previously ignored spells to be tracked again.",
                func = function()
                    if Critmatic.ignoredSpells then
                        wipe(Critmatic.ignoredSpells)
                        Critmatic.selectedIgnoredSpell = nil
                        Critmatic:Print("|cffed9d09CritMatic Reborn|r: All ignored spells cleared.")
                        if RedrawCritMaticWidget then RedrawCritMaticWidget() end
                    end
                end,
            },

            -- Info note
            spacer3 = { type = "description", name = "\n", order = 5 },
            infoNote = {
                name = "|cff888888Tip: Common spells to ignore include Auto Attack, wand attacks, or any spells you don't want cluttering your records.|r",
                type = "description",
                order = 6,
                fontSize = "small",
            },
        },
    }
end
