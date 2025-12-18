--[[
    CritMatic Options
    Main options panel configuration
]]

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
Critmatic = Critmatic or {}

function Critmatic:CreateOptionsTable()
    -- Initialize all option tabs
    local general = Critmatic:GeneralTab_Initialize()
    local alerts = Critmatic:AlertFontSettings_Initialize()
    local sounds = Critmatic:SoundSettings_Initialize()
    local sharing = Critmatic:SocialSettings_Initialize()
    local ignored = Critmatic:IgnoredSpellsSettings_Initialize()
    local advanced = Critmatic:ChangeLogSettings_Initialize()

    return {
        name = "|cffed9d09CritMatic Reborn|r",
        type = "group",
        args = {
            general = general,      -- General settings (order 1)
            alerts = alerts,        -- Alert notifications (order 2)
            sounds = sounds,        -- Sound settings (order 3)
            sharing = sharing,      -- Social/sharing (order 4)
            ignored = ignored,      -- Ignored spells (order 5)
            advanced = advanced,    -- Advanced/data (order 6)
        },
    }
end

-- Register the options table
AceConfig:RegisterOptionsTable("CritMaticOptions", Critmatic.CreateOptionsTable)

-- Add to Blizzard's Interface Options
AceConfigDialog:AddToBlizOptions("CritMaticOptions", "CritMatic Reborn")
