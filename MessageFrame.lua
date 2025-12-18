--[[
    CritMatic Message Frame
    Handles alert notification display with animations
]]

local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")

-- Configuration
local MESSAGE_SPACING = 3
local MESSAGE_DELAY = 0.45  -- Delay before showing message (seconds)

-- Active message frames
local activeMessages = {}

--[[
    Adjust positions of all active messages
    First message is centered, subsequent messages stack below
]]
local function AdjustMessagePositions()
    if #activeMessages == 0 then return end

    -- Position the first message at the top
    activeMessages[1]:ClearAllPoints()
    activeMessages[1]:SetPoint("CENTER", UIParent, "CENTER", 0, 350)

    -- Position subsequent messages relative to the previous one
    for i = 2, #activeMessages do
        activeMessages[i]:ClearAllPoints()
        activeMessages[i]:SetPoint("TOP", activeMessages[i - 1], "BOTTOM", 0, -MESSAGE_SPACING)
    end
end

--[[
    Remove the oldest message from the queue
]]
local function RemoveOldestMessage()
    local oldestMessage = table.remove(activeMessages)
    if oldestMessage then
        oldestMessage:Hide()
        oldestMessage:ClearAllPoints()
    end
end

-- Message frame handler
Critmatic.MessageFrame = {}

-- Icon size for alerts
local ICON_SIZE = 32
local ICON_SPACING = 8

--[[
    Create and display a new notification message with optional spell icon
    @param text (string) - The message text
    @param r (number) - Red color component (0-1)
    @param g (number) - Green color component (0-1)
    @param b (number) - Blue color component (0-1)
    @param spellIcon (number|string) - Optional spell icon texture
]]
function Critmatic.MessageFrame:CreateMessage(text, r, g, b, spellIcon)
    local settings = Critmatic.db.profile.alertNotificationFormat.global
    local maxMessages = settings.maxMessages or 4

    local function showMessage()
        -- Create a new message frame
        local frame = Critmatic.CreateNewMessageFrame()
        if not frame then return end

        -- Set the text and color
        frame.text:SetText(text)
        frame.text:SetTextColor(r or 1, g or 1, b or 1)

        -- Add spell icon if provided
        if spellIcon then
            -- Create icon texture if it doesn't exist
            if not frame.icon then
                frame.icon = frame:CreateTexture(nil, "ARTWORK")
                frame.icon:SetSize(ICON_SIZE, ICON_SIZE)
            end

            frame.icon:SetTexture(spellIcon)
            frame.icon:Show()

            -- Calculate text width to position icon correctly
            -- The text is centered, so we need to offset the icon based on text width
            local textWidth = frame.text:GetStringWidth() or 200
            local totalWidth = textWidth + ICON_SIZE + ICON_SPACING
            local iconOffsetX = -(totalWidth / 2) + (ICON_SIZE / 2)

            -- Position icon to the left of the centered text
            frame.icon:ClearAllPoints()
            frame.icon:SetPoint("CENTER", frame, "CENTER", iconOffsetX, 0)

            -- Adjust text position to make room for icon
            frame.text:ClearAllPoints()
            frame.text:SetPoint("CENTER", frame, "CENTER", (ICON_SIZE + ICON_SPACING) / 2, 0)

            -- Add icon animation to bounce group
            if not frame.iconBounce then
                frame.iconBounce = frame.icon:CreateAnimationGroup()
                local iconScaleUp = frame.iconBounce:CreateAnimation("Scale")
                iconScaleUp:SetScale(1.5, 1.5)
                iconScaleUp:SetDuration(0.15)
                iconScaleUp:SetOrder(1)
                local iconPause = frame.iconBounce:CreateAnimation("Pause")
                iconPause:SetDuration(0.12)
                iconPause:SetOrder(2)
                local iconScaleDown = frame.iconBounce:CreateAnimation("Scale")
                iconScaleDown:SetScale(1 / 1.5, 1 / 1.5)
                iconScaleDown:SetDuration(0.15)
                iconScaleDown:SetOrder(3)
            end
            frame.iconBounce:Play()
        else
            -- Hide icon if not needed and reset text position
            if frame.icon then
                frame.icon:Hide()
            end
            frame.text:ClearAllPoints()
            frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
        end

        -- Create fade-out animation
        frame.fadeOut = frame:CreateAnimationGroup()
        local fade = frame.fadeOut:CreateAnimation("Alpha")
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0)
        fade:SetDuration(settings.fadeTime or 0.5)
        fade:SetStartDelay(settings.startDelay or 7.5)

        frame.fadeOut:SetScript("OnFinished", function()
            frame:Hide()
            if frame.icon then
                frame.icon:Hide()
            end
            -- Remove from active messages when fade completes
            for i, msg in ipairs(activeMessages) do
                if msg == frame then
                    table.remove(activeMessages, i)
                    break
                end
            end
        end)

        -- Show the frame and play animations
        frame:Show()
        frame.bounce:Play()
        frame.fadeOut:Play()

        -- Insert at the beginning of the queue
        table.insert(activeMessages, 1, frame)
        AdjustMessagePositions()

        -- Remove oldest if we have too many
        if #activeMessages > maxMessages then
            RemoveOldestMessage()
        end
    end

    -- Use C_Timer if available, otherwise use Ace timer
    if C_Timer and C_Timer.After then
        C_Timer.After(MESSAGE_DELAY, showMessage)
    elseif Critmatic.ScheduleTimer then
        Critmatic:ScheduleTimer(showMessage, MESSAGE_DELAY)
    else
        showMessage()
    end
end

--[[
    Format a message with optional uppercase conversion
    @param formatStr (string) - The format string
    @param spellName (string) - The spell name
    @param amount (number) - The damage/heal amount
    @param useUpper (boolean) - Whether to uppercase the result
    @return string - The formatted message
]]
local function FormatMessage(formatStr, spellName, amount, useUpper)
    local message = string.format(formatStr, spellName, amount)
    if useUpper then
        message = string.upper(message)
    end
    return message
end

--[[
    Show a new critical hit notification
    @param spellName (string) - The spell name
    @param amount (number) - The damage amount
    @param spellIcon (number|string) - Optional spell icon texture
]]
function Critmatic.ShowNewCritMessage(spellName, amount, spellIcon)
    local settings = Critmatic.db.profile.alertNotificationFormat
    local formatStr = settings.strings.critAlertNotificationFormat
    local message = FormatMessage(formatStr, spellName, amount, settings.global.isUpper)

    local r, g, b = unpack(Critmatic.db.profile.fontSettings.fontColorCrit)
    Critmatic.MessageFrame:CreateMessage(message, r, g, b, spellIcon)
end

--[[
    Show a new normal hit notification
    @param spellName (string) - The spell name
    @param amount (number) - The damage amount
    @param spellIcon (number|string) - Optional spell icon texture
]]
function Critmatic.ShowNewNormalMessage(spellName, amount, spellIcon)
    local settings = Critmatic.db.profile.alertNotificationFormat
    local formatStr = settings.strings.hitAlertNotificationFormat
    local message = FormatMessage(formatStr, spellName, amount, settings.global.isUpper)

    local r, g, b = unpack(Critmatic.db.profile.fontSettings.fontColor)
    Critmatic.MessageFrame:CreateMessage(message, r, g, b, spellIcon)
end

--[[
    Show a new critical heal notification
    @param spellName (string) - The spell name
    @param amount (number) - The heal amount
    @param spellIcon (number|string) - Optional spell icon texture
]]
function Critmatic.ShowNewHealCritMessage(spellName, amount, spellIcon)
    local settings = Critmatic.db.profile.alertNotificationFormat
    local formatStr = settings.strings.critHealAlertNotificationFormat
    local message = FormatMessage(formatStr, spellName, amount, settings.global.isUpper)

    local r, g, b = unpack(Critmatic.db.profile.fontSettings.fontColorCrit)
    Critmatic.MessageFrame:CreateMessage(message, r, g, b, spellIcon)
end

--[[
    Show a new normal heal notification
    Handles spells that already end with "Heal" to avoid redundancy
    @param spellName (string) - The spell name
    @param amount (number) - The heal amount
    @param spellIcon (number|string) - Optional spell icon texture
]]
function Critmatic.ShowNewHealMessage(spellName, amount, spellIcon)
    local settings = Critmatic.db.profile.alertNotificationFormat
    local formatStr = settings.strings.healAlertNotificationFormat

    -- Check if spell name already ends with "Heal" to avoid "Spell Heal Heal: X"
    if spellName and string.sub(spellName, -4):lower() == "heal" then
        formatStr = string.gsub(formatStr, "%%s Heal", "%%s")
        formatStr = string.gsub(formatStr, "%%s heal", "%%s")
        formatStr = string.gsub(formatStr, "%%s HEAL", "%%s")
    end

    local message = FormatMessage(formatStr, spellName, amount, settings.global.isUpper)

    local r, g, b = unpack(Critmatic.db.profile.fontSettings.fontColor)
    Critmatic.MessageFrame:CreateMessage(message, r, g, b, spellIcon)
end
