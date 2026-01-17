--[[
    CritMatic API Compatibility Layer
    Provides a unified API across Retail, Classic Era, and Cataclysm Classic
    This module abstracts version-specific API differences
]]

local _, addon = ...

-- Detect WoW version
local tocVersion = select(4, GetBuildInfo())
local IS_RETAIL = tocVersion >= 100000
local IS_CLASSIC_ERA = tocVersion < 20000
local IS_TBC_CLASSIC = tocVersion >= 20000 and tocVersion < 30000  -- TBC Anniversary: 20505
local IS_WRATH_CLASSIC = tocVersion >= 30000 and tocVersion < 40000
local IS_CATA_CLASSIC = tocVersion >= 40000 and tocVersion < 50000
local IS_MOP_CLASSIC = tocVersion >= 50000 and tocVersion < 60000

-- Export version info
CritMaticAPI = {
    IS_RETAIL = IS_RETAIL,
    IS_CLASSIC_ERA = IS_CLASSIC_ERA,
    IS_TBC_CLASSIC = IS_TBC_CLASSIC,
    IS_WRATH_CLASSIC = IS_WRATH_CLASSIC,
    IS_CATA_CLASSIC = IS_CATA_CLASSIC,
    IS_MOP_CLASSIC = IS_MOP_CLASSIC,
    TOC_VERSION = tocVersion,
}

--[[
    GetSpellInfo wrapper
    In Retail 10.1.5+, GetSpellInfo was deprecated in favor of C_Spell.GetSpellInfo
    This function provides backward compatibility

    @param spellID (number) - The spell ID to look up
    @return name, rank, icon, castTime, minRange, maxRange, spellID
]]
function CritMaticAPI.GetSpellInfo(spellID)
    if not spellID then return nil end

    -- Try the new API first (Retail 10.1.5+)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, "", info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
        end
    end

    -- Fall back to legacy API
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end

    return nil
end

--[[
    GetSpellName - Get just the spell name
    @param spellID (number) - The spell ID
    @return string - The localized spell name
]]
function CritMaticAPI.GetSpellName(spellID)
    if not spellID then return nil end

    -- Try new API first
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end

    -- Fall back to GetSpellInfo
    local name = CritMaticAPI.GetSpellInfo(spellID)
    return name
end

--[[
    GetSpellTexture - Get spell icon
    @param spellID (number) - The spell ID
    @return number - The texture/icon ID
]]
function CritMaticAPI.GetSpellTexture(spellID)
    if not spellID then return nil end

    -- Try new API first
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    end

    -- Fall back to GetSpellInfo
    local _, _, icon = CritMaticAPI.GetSpellInfo(spellID)
    return icon
end

--[[
    GetSpellCooldown wrapper
    Handles differences between Classic and Retail cooldown APIs

    @param spellID (number) - The spell ID
    @return startTime, duration, enabled, modRate
]]
function CritMaticAPI.GetSpellCooldown(spellID)
    if not spellID then return 0, 0, 0, 1 end

    -- Try new API (Retail 10.1.5+)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            return info.startTime, info.duration, info.isEnabled and 1 or 0, info.modRate
        end
    end

    -- Fall back to legacy API
    if GetSpellCooldown then
        return GetSpellCooldown(spellID)
    end

    return 0, 0, 0, 1
end

--[[
    GetSpellBaseCooldown wrapper
    In Retail, this may be accessed differently

    @param spellID (number) - The spell ID
    @return number - Base cooldown in milliseconds
]]
function CritMaticAPI.GetSpellBaseCooldown(spellID)
    if not spellID then return 0 end

    -- Try the legacy function first (works in Classic)
    if GetSpellBaseCooldown then
        return GetSpellBaseCooldown(spellID) or 0
    end

    -- In Retail, we might need to use GetSpellCooldown or spell data
    local _, duration = CritMaticAPI.GetSpellCooldown(spellID)
    return (duration or 0) * 1000
end

--[[
    GetGlobalCooldown - Get the current GCD duration
    Uses player's actual GCD rather than hardcoded spell ID

    @return number - GCD duration in seconds
]]
function CritMaticAPI.GetGlobalCooldown()
    local DEFAULT_GCD = 1.5

    -- Try to get GCD from the player's spell
    local _, gcdDuration

    -- First, try GetSpellCooldown with spell ID 61304 (GCD trigger spell)
    if GetSpellCooldown then
        _, gcdDuration = GetSpellCooldown(61304)
        if gcdDuration and gcdDuration > 0 then
            return gcdDuration
        end
    end

    -- Try C_Spell API for Retail
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(61304)
        if info and info.duration and info.duration > 0 then
            return info.duration
        end
    end

    -- Calculate based on haste if available
    if GetHaste then
        local haste = GetHaste() or 0
        return math.max(0.75, DEFAULT_GCD / (1 + haste / 100))
    end

    return DEFAULT_GCD
end

--[[
    IsSpellInSpellbook - Check if a spell is in the player's spellbook
    Handles API differences between versions

    @param spellNameOrID (string|number) - Spell name or ID to check
    @return boolean
]]
function CritMaticAPI.IsSpellInSpellbook(spellNameOrID)
    if not spellNameOrID then return false end

    -- Convert name to ID if needed
    local spellName
    if type(spellNameOrID) == "number" then
        spellName = CritMaticAPI.GetSpellName(spellNameOrID)
    else
        spellName = spellNameOrID
    end

    if not spellName then return false end

    -- Try C_SpellBook for Retail
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
            if skillLineInfo then
                for j = skillLineInfo.itemIndexOffset + 1, skillLineInfo.itemIndexOffset + skillLineInfo.numSpellBookItems do
                    local name = C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
                    if name == spellName then
                        return true
                    end
                end
            end
        end
        return false
    end

    -- Classic API
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
        for i = 1, GetNumSpellTabs() do
            local _, _, offset, numSpells = GetSpellTabInfo(i)
            for j = offset + 1, offset + numSpells do
                if GetSpellBookItemName(j, BOOKTYPE_SPELL) == spellName then
                    return true
                end
            end
        end
    end

    return false
end

--[[
    GetAddOnMetadata wrapper
    Handles the transition from GetAddOnMetadata to C_AddOns.GetAddOnMetadata

    @param addonName (string) - The addon name
    @param field (string) - The metadata field
    @return string - The metadata value
]]
function CritMaticAPI.GetAddOnMetadata(addonName, field)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addonName, field)
    elseif GetAddOnMetadata then
        return GetAddOnMetadata(addonName, field)
    end
    return nil
end

--[[
    IsAddOnLoaded wrapper
    Handles the transition from IsAddOnLoaded to C_AddOns.IsAddOnLoaded

    @param addonName (string) - The addon name
    @return boolean
]]
function CritMaticAPI.IsAddOnLoaded(addonName)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(addonName)
    elseif IsAddOnLoaded then
        return IsAddOnLoaded(addonName)
    end
    return false
end

--[[
    SafeCall - Safely call a function that might not exist

    @param func (function) - The function to call
    @param ... - Arguments to pass
    @return ... - Return values from the function, or nil if it doesn't exist
]]
function CritMaticAPI.SafeCall(func, ...)
    if func and type(func) == "function" then
        return func(...)
    end
    return nil
end

--[[
    ScheduleTimer - Use Ace timer or C_Timer based on availability
    Falls back to C_Timer.After if Ace isn't available

    @param callback (function) - The callback function
    @param delay (number) - Delay in seconds
    @return handle - Timer handle
]]
function CritMaticAPI.ScheduleTimer(callback, delay)
    -- Prefer C_Timer for consistency
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, callback)
        return true
    end

    -- Shouldn't happen if addon is loaded properly, but just in case
    return false
end

-- Print version info for debugging (only in debug mode)
local function PrintVersionInfo()
    local versionStr = "Retail"
    if IS_CLASSIC_ERA then
        versionStr = "Classic Era"
    elseif IS_TBC_CLASSIC then
        versionStr = "TBC Classic"
    elseif IS_WRATH_CLASSIC then
        versionStr = "Wrath Classic"
    elseif IS_CATA_CLASSIC then
        versionStr = "Cataclysm Classic"
    elseif IS_MOP_CLASSIC then
        versionStr = "MoP Classic"
    end
    -- Uncomment for debugging:
    -- print("CritMatic: Running on " .. versionStr .. " (TOC: " .. tocVersion .. ")")
end

PrintVersionInfo()
