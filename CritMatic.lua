--[[
    CritMatic Reborn - Critical Hit Tracker
    Records and displays highest critical hits and normal hits for spells

    A modernized fork of CritMatic by InfiniteLoopAlchemist
    Maintained by Croome

    Copyright (c) CritMatic Authors, Croome
    Licensed under GNU GPL v3
]]

-- Color constants for chat output
local COLORS = {
    GOLD_YELLOW = "|cffffd700",
    GOLD = "|cffed9d09",
    WHITE = "|cffe8e7e3",
    GRAY = "|cffc2bfb6",
    RED = "|cffd41313",
    BROWN = "|cffada27f",
    GREEN = "|cff00ff00",
}

-- Backward compatibility aliases
local CritMaticGoldYellow = COLORS.GOLD_YELLOW
local CritMaticGold = COLORS.GOLD
local CritMaticWhite = COLORS.WHITE
local CritMaticGray = COLORS.GRAY
local CritMaticRed = COLORS.RED
local CritMaticBrown = COLORS.BROWN

-- Create the main addon using Ace3 framework
Critmatic = LibStub("AceAddon-3.0"):NewAddon(
    CritMaticGold .. "CritMatic Reborn|r",
    "AceConsole-3.0",
    "AceTimer-3.0",
    "AceEvent-3.0",
    "AceComm-3.0"
)

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")

-- Constants
local MAX_HIT = 40000  -- Maximum hit value to record (filters out obviously bugged values)
local DEFAULT_GCD = 1.5

-- Cache frequently used API functions
local API = CritMaticAPI or {}
local GetSpellInfo = API.GetSpellInfo or GetSpellInfo
local GetSpellName = API.GetSpellName or function(id) return (GetSpellInfo(id)) end
local GetSpellCooldown = API.GetSpellCooldown or GetSpellCooldown
local GetSpellBaseCooldown = API.GetSpellBaseCooldown or GetSpellBaseCooldown or function() return 0 end
local IsAddOnLoaded = API.IsAddOnLoaded or C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local GetAddOnMetadata = API.GetAddOnMetadata or C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

--[[
    Get the Global Cooldown duration
    Uses the API layer for cross-version compatibility

    @return number - GCD duration in seconds
]]
local function GetGCD()
    if API.GetGlobalCooldown then
        return API.GetGlobalCooldown()
    end

    -- Fallback for when API layer isn't loaded
    local _, gcdDuration = GetSpellCooldown(61304) -- Global cooldown spell
    if gcdDuration and gcdDuration > 0 then
        return gcdDuration
    end
    return DEFAULT_GCD
end

--[[
    Check if a spell is in the player's spellbook
    Uses the API layer for cross-version compatibility

    @param spellName (string) - The spell name to check
    @return boolean
]]
local function IsSpellInSpellbook(spellName)
    if API.IsSpellInSpellbook then
        return API.IsSpellInSpellbook(spellName)
    end

    -- Fallback for Classic
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

-- Cache for aggregated spell data (prevents recalculation every tooltip)
local spellDataAggregate = {}
local aggregateNeedsRefresh = true

-- Mark aggregate as needing refresh when data changes
function Critmatic:InvalidateSpellAggregate()
    aggregateNeedsRefresh = true
end

--[[
    Refresh the spell data aggregate
    Called when CritMaticData changes or on first tooltip access
]]
local function RefreshSpellAggregate()
    if not aggregateNeedsRefresh then return end

    wipe(spellDataAggregate)

    if not CritMaticData then return end

    for spellID, data in pairs(CritMaticData) do
        local spellName = GetSpellName(spellID)
        if spellName then
            if not spellDataAggregate[spellName] then
                spellDataAggregate[spellName] = {
                    highestCrit = 0,
                    highestNormal = 0,
                    highestHealCrit = 0,
                    highestHeal = 0,
                }
            end

            local agg = spellDataAggregate[spellName]
            agg.highestCrit = math.max(agg.highestCrit, data.highestCrit or 0)
            agg.highestNormal = math.max(agg.highestNormal, data.highestNormal or 0)
            agg.highestHealCrit = math.max(agg.highestHealCrit, data.highestHealCrit or 0)
            agg.highestHeal = math.max(agg.highestHeal, data.highestHeal or 0)
        end
    end

    aggregateNeedsRefresh = false
end

--[[
    Check if tooltip line already exists
    @param tooltip - The tooltip frame
    @param leftText - Expected left text
    @param rightText - Expected right text
    @return boolean
]]
local function TooltipLineExists(tooltip, leftText, rightText)
    for i = 1, tooltip:NumLines() do
        local gtl = _G["GameTooltipTextLeft" .. i]
        local gtr = _G["GameTooltipTextRight" .. i]
        if gtl and gtr and gtl:GetText() == leftText and gtr:GetText() == rightText then
            return true
        end
    end
    return false
end

--[[
    Add highest hit/crit data to spell tooltips
    @param self - The tooltip frame
    @param slot - The action bar slot or spellbook slot
    @param isSpellBook - Whether this is from the spellbook
]]
local function AddHighestHitsToTooltip(self, slot, isSpellBook)
    if not slot then return end

    -- Get spell ID based on source
    local spellID
    if isSpellBook then
        spellID = select(3, GetSpellBookItemName(slot, BOOKTYPE_SPELL))
    else
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" then
            spellID = id
        end
    end

    if not spellID then return end

    local spellName = GetSpellName(spellID)
    if not spellName then return end

    -- Refresh aggregate data if needed
    RefreshSpellAggregate()

    local spellData = spellDataAggregate[spellName]
    if not spellData then return end

    -- Calculate effective time for DPS/HPS calculations
    local cooldown = (GetSpellBaseCooldown(spellID) or 0) / 1000
    local _, _, _, castTime = GetSpellInfo(spellID)
    castTime = castTime or 0
    local effectiveCastTime = castTime > 0 and (castTime / 1000) or GetGCD()
    local effectiveTime = math.max(effectiveCastTime, cooldown, 0.1) -- Prevent division by zero

    -- Prepare tooltip labels
    local dpsLabel = L["action_bar_dps"] .. ") "
    local hpsLabel = L["action_bar_hps"] .. ") "

    -- Add damage crit line
    if spellData.highestCrit > 0 then
        local dps = spellData.highestCrit / effectiveTime
        local leftText = L["action_bar_crit"] .. ": "
        local rightText = tostring(spellData.highestCrit) .. " (" .. format("%.1f", dps) .. dpsLabel

        if not TooltipLineExists(self, leftText, rightText) then
            self:AddDoubleLine(leftText, rightText, 0.9, 0.9, 0.9, 0.9, 0.82, 0)
        end
    end

    -- Add damage normal line
    if spellData.highestNormal > 0 then
        local dps = spellData.highestNormal / effectiveTime
        local leftText = L["action_bar_hit"] .. ": "
        local rightText = tostring(spellData.highestNormal) .. " (" .. format("%.1f", dps) .. dpsLabel

        if not TooltipLineExists(self, leftText, rightText) then
            self:AddDoubleLine(leftText, rightText, 0.9, 0.9, 0.9, 0.9, 0.82, 0)
        end
    end

    -- Add heal crit line
    if spellData.highestHealCrit > 0 then
        local hps = spellData.highestHealCrit / effectiveTime
        local leftText = L["action_bar_crit_heal"] .. ": "
        local rightText = tostring(spellData.highestHealCrit) .. " (" .. format("%.1f", hps) .. hpsLabel

        if not TooltipLineExists(self, leftText, rightText) then
            self:AddDoubleLine(leftText, rightText, 0.9, 0.9, 0.9, 0.9, 0.82, 0)
        end
    end

    -- Add heal normal line
    if spellData.highestHeal > 0 then
        local hps = spellData.highestHeal / effectiveTime
        local leftText = L["action_bar_heal"] .. ": "
        local rightText = tostring(spellData.highestHeal) .. " (" .. format("%.1f", hps) .. hpsLabel

        if not TooltipLineExists(self, leftText, rightText) then
            self:AddDoubleLine(leftText, rightText, 0.9, 0.9, 0.9, 0.9, 0.82, 0)
        end
    end

    self:Show()
end
--[[
    Create a new message frame for alert notifications
    Uses animation groups for bounce and fade effects

    @return frame - The configured message frame
]]
function Critmatic.CreateNewMessageFrame()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(1000, 30)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 350)

    -- Create text display
    frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    frame.text:SetAllPoints()

    -- Create bounce animation group
    frame.bounce = frame:CreateAnimationGroup()

    local scaleUp = frame.bounce:CreateAnimation("Scale")
    scaleUp:SetScale(1.5, 1.5)
    scaleUp:SetDuration(0.15)
    scaleUp:SetOrder(1)

    local pause = frame.bounce:CreateAnimation("Pause")
    pause:SetDuration(0.12)
    pause:SetOrder(2)

    local scaleDown = frame.bounce:CreateAnimation("Scale")
    scaleDown:SetScale(1 / 1.5, 1 / 1.5)
    scaleDown:SetDuration(0.15)
    scaleDown:SetOrder(3)

    -- Apply font settings if database is available
    if Critmatic.db and Critmatic.db.profile then
        local LSM = LibStub("LibSharedMedia-3.0")
        local fontSettings = Critmatic.db.profile.fontSettings
        local fontPath = LSM:Fetch("font", fontSettings.font)

        frame.text:SetFont(fontPath, fontSettings.fontSize, fontSettings.fontOutline)
        frame.text:SetShadowOffset(unpack(fontSettings.fontShadowSize))
        frame.text:SetShadowColor(unpack(fontSettings.fontShadowColor))
    end

    return frame
end

--[[
    Compare two version strings (e.g., "1.2.3" vs "1.3.0")
    @param version1 (string) - First version
    @param version2 (string) - Second version
    @return boolean - True if version1 is newer than version2
]]
local function CompareVersions(version1, version2)
    local function splitVersion(str)
        local parts = {}
        for part in string.gmatch(str, "[%d]+") do
            table.insert(parts, tonumber(part))
        end
        return parts
    end

    local parts1 = splitVersion(version1)
    local parts2 = splitVersion(version2)

    for i = 1, math.max(#parts1, #parts2) do
        local num1 = parts1[i] or 0
        local num2 = parts2[i] or 0
        if num1 > num2 then
            return true
        elseif num1 < num2 then
            return false
        end
    end
    return false
end

--[[
    Capitalize first letter of each word in a string
    @param str (string) - Input string
    @return string - Capitalized string
]]
local function CapitalizeWords(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

--[[
    Trim whitespace from string (polyfill for older Lua)
    @param str (string) - Input string
    @return string - Trimmed string
]]
local function TrimString(str)
    if not str then return "" end
    if str.trim then return str:trim() end
    return str:match("^%s*(.-)%s*$") or str
end

-- Slash command handlers (defined before OnInitialize for clarity)
local function ResetSingleSpellData(input)
    if not input or TrimString(input) == "" then
        Critmatic:Print(CritMaticRed .. "Please provide a spell name!" .. "|r")
        return
    end

    local capitalizedInput = CapitalizeWords(input)
    local inputSpellName = capitalizedInput:lower()

    for spellID, _ in pairs(CritMaticData) do
        local spellName = GetSpellName(spellID)
        if spellName and spellName:lower() == inputSpellName then
            CritMaticData[spellID] = nil
            Critmatic:Print(CritMaticGoldYellow .. capitalizedInput .. "|r" .. CritMaticRed .. " data has been reset." .. "|r")
            Critmatic:InvalidateSpellAggregate()
            if RedrawCritMaticWidget then RedrawCritMaticWidget() end
            return
        end
    end

    Critmatic:Print(CritMaticGoldYellow .. capitalizedInput .. "|r" .. CritMaticRed .. " is not a tracked spell currently" .. "|r")
end

local function AddIgnoredSpell(input)
    if not input or TrimString(input) == "" then
        Critmatic:Print(CritMaticRed .. "Please provide a spell name!" .. "|r")
        return
    end

    local capitalizedInput = CapitalizeWords(input)
    local inputSpellName = capitalizedInput:lower()

    -- Check if spell is being tracked
    local spellFound = false
    for spellID, _ in pairs(CritMaticData) do
        local spellName = GetSpellName(spellID)
        if spellName and spellName:lower() == inputSpellName then
            spellFound = true
            break
        end
    end

    if not spellFound then
        Critmatic:Print(CritMaticRed .. capitalizedInput .. "|r" .. CritMaticWhite .. " is not a tracked spell currently" .. "|r")
        return
    end

    Critmatic.ignoredSpells[inputSpellName] = true
    Critmatic:Print(CritMaticGoldYellow .. capitalizedInput .. "|r" .. CritMaticWhite .. " added to " .. CritMaticRed .. "ignored" .. "|r " .. CritMaticWhite .. "spells." .. "|r")
    if RedrawCritMaticWidget then RedrawCritMaticWidget() end
end

local function ListIgnoredSpells()
    if not Critmatic.ignoredSpells or next(Critmatic.ignoredSpells) == nil then
        Critmatic:Print(CritMaticRed .. "No spells are currently being ignored." .. "|r")
        return
    end

    Critmatic:Print(CritMaticRed .. "Ignored" .. "|r " .. "Spells:")
    for spellName, _ in pairs(Critmatic.ignoredSpells) do
        Critmatic:Print(CritMaticGoldYellow .. "- " .. CapitalizeWords(spellName) .. "|r")
    end
end

local function RemoveIgnoredSpell(input)
    if not input or TrimString(input) == "" then
        Critmatic:Print(CritMaticRed .. "Please provide a spell name." .. "|r")
        return
    end

    local spellName = input:lower()
    if Critmatic.ignoredSpells and Critmatic.ignoredSpells[spellName] then
        Critmatic.ignoredSpells[spellName] = nil
        Critmatic:Print(CritMaticGoldYellow .. CapitalizeWords(spellName) .. "|r" .. CritMaticRed .. " has been removed from ignored spells." .. "|r")
        if RedrawCritMaticWidget then RedrawCritMaticWidget() end
    else
        Critmatic:Print(CritMaticRed .. "Spell not found in ignored spells." .. "|r")
    end
end

local function WipeIgnoredSpells()
    if not Critmatic.ignoredSpells or next(Critmatic.ignoredSpells) == nil then
        Critmatic:Print(CritMaticRed .. "The ignored spells list is already empty!" .. "|r")
        return
    end

    wipe(Critmatic.ignoredSpells)
    Critmatic:Print(CritMaticRed .. "All ignored spells have been removed." .. "|r")
    if RedrawCritMaticWidget then RedrawCritMaticWidget() end
end

local function ShowHelp()
    Critmatic:Print(CritMaticBrown .. "Commands:|r")
    print(CritMaticBrown .. "There can be a short calibration period if you don't have any crit data, level up, or have multiple new gear upgrades" .. "|r")
    print(CritMaticGoldYellow .. "/cm" .. "|r " .. CritMaticGray .. "- Open the CritMatic options menu." .. "|r")
    print(CritMaticGoldYellow .. "/cmlog" .. "|r " .. CritMaticGray .. "- Open the CritMatic changelog." .. "|r")
    print(CritMaticGoldYellow .. "/cmcritlog" .. "|r " .. CritMaticGray .. "- Open the CritMatic crit log." .. "|r")
    print(CritMaticGoldYellow .. "/cmcritlogdefaultpos" .. "|r " .. CritMaticGray .. "- Resets the Crit Log position. Causes a Reload." .. "|r")
    print(CritMaticGoldYellow .. "/cmdeletespelldata spell name" .. "|r " .. CritMaticGray .. "- Reset a single spell's data." .. "|r")
    print(CritMaticGoldYellow .. "/cmreset" .. "|r " .. CritMaticGray .. "- Reset all CritMatic data." .. "|r")
    print(CritMaticGoldYellow .. "/cmignore spell name" .. "|r " .. CritMaticGray .. "- Ignore a spell." .. "|r")
    print(CritMaticGoldYellow .. "/cmignoredspells" .. "|r " .. CritMaticGray .. "- List all ignored spells." .. "|r")
    print(CritMaticGoldYellow .. "/cmremoveignoredspell spell name" .. "|r " .. CritMaticGray .. "- Remove a spell from the ignored spells list." .. "|r")
    print(CritMaticGoldYellow .. "/cmwipeignoredspells" .. "|r " .. CritMaticGray .. "- Remove all spells from the ignored spells list." .. "|r")
end

--[[
    Handle incoming version messages from other addon users
]]
function Critmatic:OnCommReceived(prefix, message, distribution, sender)
    local version = GetAddOnMetadata("CritMatic", "Version")
    if message and version then
        if CompareVersions(message, version) and not self.hasDisplayedUpdateMessage then
            self:Print(CritMaticRed .. L["new_version_notification"] .. "|r" .. CritMaticGray .. L["new_version_notification_part"] .. "|r")
            self.hasDisplayedUpdateMessage = true
        end
    end
end

--[[
    Broadcast addon version to group members
]]
function Critmatic:BroadcastVersion()
    local version = GetAddOnMetadata("CritMatic", "Version")
    if not version then return end

    -- Send to guild
    if IsInGuild() then
        self:SendCommMessage("Critmatic", version, "GUILD")
    end

    -- Don't broadcast in PvP instances
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "pvp" or instanceType == "arena") then
        return
    end

    -- Send to appropriate channel
    if IsPartyLFG and IsPartyLFG() then
        self:SendCommMessage("Critmatic", version, "INSTANCE_CHAT")
    elseif IsInRaid() then
        self:SendCommMessage("Critmatic", version, "RAID")
    elseif IsInGroup() then
        self:SendCommMessage("Critmatic", version, "PARTY")
    end
end

--[[
    Display loaded message with version info
]]
function Critmatic:ShowLoadedMessage()
    local version = GetAddOnMetadata("CritMatic", "Version") or "Unknown"
    self:Print(CritMaticGray .. " " .. L["version_string"] .. "|r" .. CritMaticWhite .. " " .. version .. "|r " ..
        CritMaticGray .. L["critmatic_loaded"] .. CritMaticGoldYellow .. "  /cm" .. "|r" ..
        CritMaticGray .. " " .. L["critmatic_loaded_for_options"] .. "|r " ..
        CritMaticGoldYellow .. L["critmatic_loaded_cmhelp"] .. "|r " ..
        CritMaticGray .. L["critmatic_loaded_for_all_slash_commands"] .. "|r ")
end

--[[
    Ace3 OnInitialize callback
    Called when addon is first loaded
]]
function Critmatic:OnInitialize()
    -- Initialize database
    self.db = LibStub("AceDB-3.0"):New("CritMaticDB14", defaults)
    CritMaticData = CritMaticData or {}

    -- Get addon version
    local version = GetAddOnMetadata("CritMatic", "Version")

    -- Initialize crit log if it was shown before
    if toggleCritMaticCritLog then
        toggleCritMaticCritLog()
    end

    -- Check for version updates and show changelog if needed
    local oldVersion = self.db.profile.oldVersion
    local newVersion = tostring(version)
    if newVersion and oldVersion and CompareVersions(newVersion, oldVersion) then
        if self.db.profile.generalSettings.isChangeLogAutoPopUpEnabled then
            if self.showChangeLog then
                self.showChangeLog()
            end
        end
        self.db.profile.oldVersion = newVersion
    end

    -- Register slash commands
    self:RegisterChatCommand("critmatic", "OpenOptions")
    self:RegisterChatCommand("cm", "OpenOptions")
    self:RegisterChatCommand(L["slash_cmlog"], "OpenChangeLog")
    self:RegisterChatCommand(L["slash_cmcritlog"], function() if toggleCritMaticCritLog then toggleCritMaticCritLog() end end)
    self:RegisterChatCommand("cmhelp", ShowHelp)
    self:RegisterChatCommand("cmdeletespelldata", ResetSingleSpellData)
    self:RegisterChatCommand("cmwipeignoredspells", WipeIgnoredSpells)
    self:RegisterChatCommand("cmremoveignoredspell", RemoveIgnoredSpell)
    self:RegisterChatCommand("cmignoredspells", ListIgnoredSpells)
    self:RegisterChatCommand(L["slash_cmignore"], AddIgnoredSpell)
    self:RegisterChatCommand(L["slash_cmreset"], "CritMaticReset")

    -- Register addon communication
    self:RegisterComm("Critmatic")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "BroadcastVersion")

    -- Hook tooltips for spell info display
    hooksecurefunc(GameTooltip, "SetAction", AddHighestHitsToTooltip)

    -- Support ElvUI's spellbook tooltip if available
    local spellbookTooltip = IsAddOnLoaded("ElvUI") and _G.ElvUISpellBookTooltip or GameTooltip
    hooksecurefunc(spellbookTooltip, "SetSpellBookItem", AddHighestHitsToTooltip)

    -- Create initial message frame
    Critmatic.CreateNewMessageFrame()

    -- Schedule loaded message (delayed to appear after other addon messages)
    local delay = IsAddOnLoaded("ElvUI") and 8 or 4
    self:ScheduleTimer("ShowLoadedMessage", delay)

    -- Initialize state
    self.hasDisplayedUpdateMessage = false
end

--[[
    Ace3 OnEnable callback
    Called when addon is enabled and saved variables are available
]]
function Critmatic:OnEnable()
    -- Ensure data tables exist
    CritMaticData = _G["CritMaticData"] or {}
    CritMatic_ignoredSpells = CritMatic_ignoredSpells or {}
    self.ignoredSpells = CritMatic_ignoredSpells

    -- Refresh the spell aggregate cache
    self:InvalidateSpellAggregate()

    -- Draw the crit log widget if available
    if RedrawCritMaticWidget then
        RedrawCritMaticWidget()
    end
end

--[[
    Ace3 OnDisable callback
    Called when addon is disabled
]]
function Critmatic:OnDisable()
    -- Cleanup if needed
end

--[[
    Open the options panel
]]
function Critmatic:OpenOptions()
    LibStub("AceConfigDialog-3.0"):Open("CritMaticOptions")
end

--[[
    Toggle the crit log display
]]
function Critmatic:OpenCritLog()
    if toggleCritMaticCritLog then
        toggleCritMaticCritLog()
    end
end

--[[
    Open the changelog popup
]]
function Critmatic:OpenChangeLog()
    if self.showChangeLog then
        self.showChangeLog()
    end
end

--[[
    Reset all tracked spell data
]]
function Critmatic:CritMaticReset()
    wipe(CritMaticData)
    self:InvalidateSpellAggregate()
    self:Print(CritMaticRed .. L["critmatic_reset"] .. "|r")

    if RedrawCritMaticWidget then
        RedrawCritMaticWidget()
    end
end

--------------------------------------------------------------------------------
-- Combat Log Event Handling
--------------------------------------------------------------------------------

-- Combat state tracking
local CombatState = {
    highestCritDuringCombat = 0,
    highestCritHealDuringCombat = 0,
    highestCritSpellName = "",
    highestCritHealSpellName = "",
}

-- Event types we care about
local TRACKED_DAMAGE_EVENTS = {
    SPELL_DAMAGE = true,
    SWING_DAMAGE = true,
    RANGE_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
}

local TRACKED_HEAL_EVENTS = {
    SPELL_HEAL = true,
    SPELL_PERIODIC_HEAL = true,
}

-- Auto Attack spell ID
local AUTO_ATTACK_SPELL_ID = 6603

-- Cache LibSharedMedia
local LSM = LibStub("LibSharedMedia-3.0")

--[[
    Check if a spell is in the ignored list
    @param spellName (string) - The spell name to check
    @return boolean - True if spell should be ignored
]]
local function IsSpellIgnored(spellName)
    if not Critmatic.ignoredSpells or not spellName then
        return false
    end

    local lowerName = spellName:lower()
    for ignoredName, _ in pairs(Critmatic.ignoredSpells) do
        if ignoredName:lower() == lowerName then
            return true
        end
    end
    return false
end

--[[
    Initialize spell data structure for a new spell
    Stores the icon at record time to avoid wrong icon issues with shared spell names

    @param spellID (number) - The spell ID
    @param spellName (string) - The spell name (optional, for icon lookup)
]]
local function InitializeSpellData(spellID, spellName)
    if not CritMaticData[spellID] then
        -- Get the icon at the time of recording to avoid wrong icon issues
        local icon
        if API.GetSpellTexture then
            icon = API.GetSpellTexture(spellID)
        else
            local _, _, iconPath = GetSpellInfo(spellID)
            icon = iconPath
        end

        CritMaticData[spellID] = {
            highestCrit = 0,
            highestCritOld = 0,
            highestNormal = 0,
            highestNormalOld = 0,
            highestHealCrit = 0,
            highestHealCritOld = 0,
            highestHeal = 0,
            highestHealOld = 0,
            spellIcon = icon,  -- Store the icon to fix wrong icon issues
        }
    end
end

--[[
    Play a notification sound if sounds are enabled
    @param soundKey (string) - The sound setting key
]]
local function PlayNotificationSound(soundKey)
    if Critmatic.db.profile.soundSettings.muteAllSounds then
        return
    end

    local soundFile = LSM:Fetch("sound", Critmatic.db.profile.soundSettings[soundKey])
    if soundFile then
        PlaySoundFile(soundFile)
    end
end

--[[
    Handle recording a new record and updating UI
    @param spellID (number) - The spell ID
    @param spellName (string) - The spell name
    @param amount (number) - The damage/heal amount
    @param recordType (string) - "crit", "normal", "healCrit", or "heal"
]]
local function HandleNewRecord(spellID, spellName, amount, recordType)
    local data = CritMaticData[spellID]
    local settings = Critmatic.db.profile

    -- Sound notifications
    local soundMap = {
        crit = "damageCrit",
        normal = "damageNormal",
        healCrit = "healCrit",
        heal = "healNormal",
    }
    PlayNotificationSound(soundMap[recordType])

    -- Get spell icon for the alert
    local spellIcon = data.spellIcon
    if not spellIcon then
        -- Fallback to API lookup
        if API.GetSpellTexture then
            spellIcon = API.GetSpellTexture(spellID)
        else
            local _, _, iconPath = GetSpellInfo(spellID)
            spellIcon = iconPath
        end
    end

    -- Alert notifications
    if settings.generalSettings.alertNotificationsEnabled then
        local alertMap = {
            crit = Critmatic.ShowNewCritMessage,
            normal = Critmatic.ShowNewNormalMessage,
            healCrit = Critmatic.ShowNewHealCritMessage,
            heal = Critmatic.ShowNewHealMessage,
        }
        if alertMap[recordType] then
            alertMap[recordType](spellName, amount, spellIcon)
        end
    end

    -- Chat notifications
    if settings.generalSettings.chatNotificationsEnabled then
        local chatMap = {
            crit = { color = CritMaticGoldYellow, key = "chat_crit", value = data.highestCrit },
            normal = { color = CritMaticWhite, key = "chat_hit", value = data.highestNormal },
            healCrit = { color = CritMaticGoldYellow, key = "chat_crit_heal", value = data.highestHealCrit },
            heal = { color = CritMaticWhite, key = "chat_heal", value = data.highestHeal },
        }
        local chat = chatMap[recordType]
        if chat then
            Critmatic:Print(chat.color .. L[chat.key] .. spellName .. ": |r" .. chat.value)
        end
    end

    -- Update widgets and caches
    Critmatic:InvalidateSpellAggregate()
    if RecordEvent then RecordEvent(spellID) end
    if RedrawCritMaticWidget then RedrawCritMaticWidget() end
end

--[[
    Process a combat log event for potential new records
    @param eventType (string) - The combat log event type
    @param spellID (number) - The spell ID
    @param spellName (string) - The spell name
    @param amount (number) - The damage/heal amount
    @param isCritical (boolean) - Whether this was a critical hit/heal
]]
local function ProcessCombatEvent(eventType, spellID, spellName, amount, isCritical)
    -- Validate inputs
    if not spellID or not amount or amount <= 0 or amount > MAX_HIT then
        return
    end

    -- Get localized spell name
    local localizedName = GetSpellName(spellID) or spellName
    if not localizedName then return end

    -- Check if spell is ignored
    if IsSpellIgnored(localizedName) then
        return
    end

    -- Initialize spell data if needed
    InitializeSpellData(spellID)
    local data = CritMaticData[spellID]

    -- Process heal events
    if TRACKED_HEAL_EVENTS[eventType] then
        if isCritical then
            if amount > data.highestHealCrit then
                data.highestHealCritOld = data.highestHealCrit
                data.highestHealCrit = amount
                CombatState.highestCritHealDuringCombat = amount
                CombatState.highestCritHealSpellName = localizedName
                HandleNewRecord(spellID, localizedName, amount, "healCrit")
            end
        else
            if amount > data.highestHeal then
                data.highestHealOld = data.highestHeal
                data.highestHeal = amount
                HandleNewRecord(spellID, localizedName, amount, "heal")
            end
        end
        return
    end

    -- Process damage events
    if TRACKED_DAMAGE_EVENTS[eventType] then
        if isCritical then
            if amount > data.highestCrit then
                data.highestCritOld = data.highestCrit
                data.highestCrit = amount
                CombatState.highestCritDuringCombat = amount
                CombatState.highestCritSpellName = localizedName
                HandleNewRecord(spellID, localizedName, amount, "crit")
            end
        else
            if amount > data.highestNormal then
                data.highestNormalOld = data.highestNormal
                data.highestNormal = amount
                HandleNewRecord(spellID, localizedName, amount, "normal")
            end
        end
    end
end

--[[
    Send combat records to chat channels based on settings
    @param chatType (string) - The chat channel type
]]
local function SendCombatRecordsToChat(chatType)
    if CombatState.highestCritDuringCombat > 0 then
        SendChatMessage(
            "{star}CritMatic: " .. L["social_crit"] ..
            CombatState.highestCritSpellName .. ": " ..
            CombatState.highestCritDuringCombat,
            chatType
        )
    end

    if CombatState.highestCritHealDuringCombat > 0 then
        SendChatMessage(
            "{star}CritMatic: " .. L["social_crit_heal"] ..
            CombatState.highestCritHealSpellName .. ": " ..
            CombatState.highestCritHealDuringCombat,
            chatType
        )
    end
end

--[[
    Handle end of combat - broadcast records if enabled
]]
local function HandleCombatEnd()
    local social = Critmatic.db.profile.social
    local inInstance, instanceType = IsInInstance()

    -- Send to guild
    if IsInGuild() and social.canSendCritsToGuild then
        SendCombatRecordsToChat("GUILD")
    end

    -- Send to group
    if IsInGroup() then
        if inInstance and instanceType == "pvp" and social.canSendCritsToBattleGrounds then
            SendCombatRecordsToChat("INSTANCE_CHAT")
        elseif IsPartyLFG and IsPartyLFG() and social.canSendCritsToParty then
            SendCombatRecordsToChat("INSTANCE_CHAT")
        elseif IsInRaid() and social.canSendCritsToRaid then
            SendCombatRecordsToChat("RAID")
        elseif social.canSendCritsToParty then
            SendCombatRecordsToChat("PARTY")
        end
    end

    -- Reset combat state
    CombatState.highestCritDuringCombat = 0
    CombatState.highestCritHealDuringCombat = 0
    CombatState.highestCritSpellName = ""
    CombatState.highestCritHealSpellName = ""
end

--[[
    Parse combat log event data
    @param eventInfo (table) - The event info from CombatLogGetCurrentEventInfo()
    @return eventType, spellID, spellName, amount, isCritical
]]
local function ParseCombatLogEvent(eventInfo)
    local _, eventType, _, sourceGUID, _, _, _, destGUID = unpack(eventInfo)

    -- Only process events from player or pet, not to player
    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")

    if sourceGUID ~= playerGUID and sourceGUID ~= petGUID then
        return nil
    end

    if destGUID == playerGUID then
        return nil
    end

    local spellID, spellName, amount, isCritical

    if eventType == "SWING_DAMAGE" then
        spellName = "Auto Attack"
        spellID = AUTO_ATTACK_SPELL_ID
        amount, _, _, _, _, _, isCritical = unpack(eventInfo, 12, 18)
    elseif TRACKED_HEAL_EVENTS[eventType] then
        spellID, spellName = unpack(eventInfo, 12, 13)
        amount, _, _, isCritical = unpack(eventInfo, 15, 18)
    elseif TRACKED_DAMAGE_EVENTS[eventType] then
        spellID, spellName = unpack(eventInfo, 12, 13)
        amount, _, _, _, _, _, isCritical = unpack(eventInfo, 15, 21)
    else
        return nil
    end

    return eventType, spellID, spellName, amount, isCritical
end

-- Create the event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local eventInfo = { CombatLogGetCurrentEventInfo() }
        local eventType, spellID, spellName, amount, isCritical = ParseCombatLogEvent(eventInfo)

        if eventType then
            ProcessCombatEvent(eventType, spellID, spellName, amount, isCritical)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        HandleCombatEnd()
    end
end)
