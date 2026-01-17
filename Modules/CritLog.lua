local L = LibStub("AceLocale-3.0"):GetLocale("CritMatic")
local AceConsole = LibStub("AceConsole-3.0")

-- Use API wrapper for cross-version compatibility
local API = CritMaticAPI or {}
local GetSpellInfo = API.GetSpellInfo or GetSpellInfo
local GetSpellName = API.GetSpellName or function(id) return (GetSpellInfo(id)) end
local GetSpellTexture = API.GetSpellTexture or function(id) local _, _, icon = GetSpellInfo(id) return icon end

function toggleCritMaticCritLog()
    local db = Critmatic.db.profile
    local sizePos = Critmatic.db.profile.critLogWidgetPos
    if not Critmatic.crit_log_frame or not Critmatic.crit_log_frame.frame then

        --[[
            Crit Log Widget
            Note: This widget implementation incorporates certain elements and functionalities
            that are based on the DeathLog Widget.]]
        local Type, Version = "CritMatic_CritLog", 30
        local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
        if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
            return
        end

        local main_font = ''

        local pairs, assert, type = pairs, assert, type
        local wipe = table.wipe

        local PlaySound = PlaySound
        local CreateFrame, UIParent = CreateFrame, UIParent
        local column_types = {
            "Name",
            "Guild",
            "Lvl",
            "F's",
            "Race",
            "Class",
            "Source",
            "ColoredName",
            "Zone",
            "ClassLogo1",
            "ClassLogo2",
            "RaceLogoSquare",
            "LastWords",
        }

        local function Button_OnClick(frame)
            PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
            frame.obj:Hide()
        end

        local function Frame_OnShow(frame)
            frame.obj:Fire("OnShow")
        end

        local function Frame_OnClose(frame)
            frame.obj:Fire("OnClose")
        end

        local function Frame_OnMouseDown(frame)
            AceGUI:ClearFocus()
        end

        local function Title_OnMouseDown(frame)
            AceGUI:ClearFocus()
        end

        local function MoverSizer_OnMouseUp(mover)
            local frame = mover:GetParent()
            frame:StopMovingOrSizing()
            local self = frame.obj
            local status = self.status or self.localstatus
            status.width = frame:GetWidth()
            status.height = frame:GetHeight()
            status.top = frame:GetTop()
            status.left = frame:GetLeft()
        end

        local function SizerSE_OnMouseDown(frame)
            frame:GetParent():StartSizing("BOTTOMRIGHT")
            AceGUI:ClearFocus()
        end

        local function SizerS_OnMouseDown(frame)
            frame:GetParent():StartSizing("BOTTOM")
            AceGUI:ClearFocus()
        end

        local function SizerE_OnMouseDown(frame)
            frame:GetParent():StartSizing("RIGHT")
            AceGUI:ClearFocus()
        end

        local function StatusBar_OnEnter(frame)
            frame.obj:Fire("OnEnterStatusBar")
        end

        local function StatusBar_OnLeave(frame)
            frame.obj:Fire("OnLeaveStatusBar")
        end

        local methods = {
            ["OnAcquire"] = function(self)
                self.frame:SetParent(UIParent)
                self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
                self.frame:SetFrameLevel(100) -- Lots of room to draw under it
                self:SetTitle()
                self:SetSubTitle()
                self:SetStatusText()
                self:ApplyStatus()
                self:Show()
                self:EnableResize(true)
            end,

            ["OnRelease"] = function(self)
                self.status = nil
                wipe(self.localstatus)
            end,

            ["OnWidthSet"] = function(self, width)
                local content = self.content
                local contentwidth = width - 34
                if contentwidth < 0 then
                    contentwidth = 0
                end
                content:SetWidth(contentwidth)
                content.width = contentwidth
                self.titlebg:SetWidth(contentwidth - 35)
            end,

            ["OnHeightSet"] = function(self, height)
                local content = self.content
                local contentheight = height
                if contentheight < 0 then
                    contentheight = 0
                end
                content:SetHeight(contentheight)
                content.height = contentheight
            end,

            ["SetTitle"] = function(self, title)
                self.titletext:SetText(title)

            end,

            ["SetSubTitle"] = function(self, subtitle_data)
                local column_offset = 17
                if subtitle_data == nil then
                    return
                end

                for _, v in ipairs(column_types) do
                    self.subtitletext_tbl[v]:SetText("")
                end
                for _, v in ipairs(subtitle_data) do
                    if v[1] == "ClassLogo1" or v[1] == "ClassLogo2" or v[1] == "RaceLogoSquare" then
                        self.subtitletext_tbl[v[1]]:SetText("")
                    else
                        self.subtitletext_tbl[v[1]]:SetText(v[1])
                    end
                    self.subtitletext_tbl[v[1]]:SetPoint("LEFT", self.frame, "TOPLEFT", column_offset, -26)
                    column_offset = column_offset + v[2]
                end
            end,
            ["SetSubTitleOffset"] = function(self, _x, _y, subtitle_data)
                local column_offset = 17
                for _, v in ipairs(subtitle_data) do
                    self.subtitletext_tbl[v[1]]:SetPoint("LEFT", self.frame, "TOPLEFT", column_offset + _x, -26 + _y)
                    column_offset = column_offset + v[2]
                end
            end,

            ["SetStatusText"] = function(self, text)
                self.statustext:SetText(text)
            end,

            ["Hide"] = function(self)
                self.frame:Hide()
            end,

            ["Minimize"] = function(self)
                self.frame:Hide()
                is_minimized = true
            end,

            ["IsMinimized"] = function(self)
                return is_minimized
            end,

            ["Maximize"] = function(self)
                self.frame:Show()
                is_minimized = false
            end,

            ["Show"] = function(self)
                self.frame:Show()
            end,

            ["EnableResize"] = function(self, state)
                local func = state and "Show" or "Hide"
                self.sizer_se[func](self.sizer_se)
                self.sizer_s[func](self.sizer_s)
                self.sizer_e[func](self.sizer_e)
            end,

            -- called to set an external table to store status in
            -- Function to set an external table to store status in
            ["SetStatusTable"] = function(self, status)
                assert(type(status) == "table")
                self.status = status
                self:ApplyStatus()
            end,

            -- Function to apply the status to the frame
            ["ApplyStatus"] = function(self)
                local sizePos = Critmatic.db.profile.critLogWidgetPos
                local frame = self.frame

                -- Set the width and height from sizePos or use default values
                self:SetWidth(sizePos.size_x or 700)
                self:SetHeight(sizePos.size_y or 500)

                frame:ClearAllPoints()

                -- If sizePos has position data, use it to set the frame's position
                if sizePos.pos_x and sizePos.pos_y then
                    frame:SetPoint("CENTER", UIParent, "CENTER", sizePos.pos_x, sizePos.pos_y)

                end
            end,
        }

        local FrameBackdrop = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\CHATFRAME\\ChatFrameBorder",
            tile = false,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        }

        local PaneBackdrop = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Glues\\COMMON\\TextPanel-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 32,
            insets = { left = 3, right = 3, top = 5, bottom = 3 },
        }

        local function Constructor()
            local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            frame:Hide()

            frame:EnableMouse(true)
            frame:SetMovable(true)
            frame:SetResizable(true)
            frame:SetFrameStrata("FULLSCREEN_DIALOG")
            frame:SetFrameLevel(100) -- Lots of room to draw under it
            frame:SetBackdrop(PaneBackdrop)
            frame:SetBackdropColor(0, 0, 0, 0.6)
            frame:SetBackdropBorderColor(1, 1, 1, 1)
            frame:SetSize(250, 150)

            if frame.SetResizeBounds then
                frame:SetResizeBounds(100, 50)
            else
                frame:SetMinResize(150, 100)
            end
            frame:SetToplevel(true)
            frame:SetScript("OnShow", Frame_OnShow)
            frame:SetScript("OnHide", Frame_OnClose)
            frame:SetScript("OnMouseDown", Frame_OnMouseDown)

            local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            closebutton:SetScript("OnClick", Button_OnClick)
            closebutton:SetPoint("BOTTOMRIGHT", -27, 17)
            closebutton:SetHeight(0)
            closebutton:SetWidth(100)
            closebutton:SetText(CLOSE)
            closebutton:Hide()

            local statusbg = CreateFrame("Button", nil, frame, "BackdropTemplate")
            statusbg:SetPoint("BOTTOMLEFT", 15, 15)
            statusbg:SetPoint("BOTTOMRIGHT", -132, 15)
            statusbg:SetHeight(0)
            statusbg:SetBackdrop(PaneBackdrop)
            statusbg:SetBackdropColor(0.1, 0.1, 0.1)
            statusbg:SetBackdropBorderColor(0.4, 0.4, 0.4)
            statusbg:SetScript("OnEnter", StatusBar_OnEnter)
            statusbg:SetScript("OnLeave", StatusBar_OnLeave)
            statusbg:Hide()

            local statustext = statusbg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            statustext:SetPoint("TOPLEFT", 7, -2)
            statustext:SetPoint("BOTTOMRIGHT", -7, 2)
            statustext:SetHeight(0)
            statustext:SetJustifyH("LEFT")
            statustext:SetText("")
            statustext:Hide()

            local titlebg = frame:CreateTexture(nil, "OVERLAY")
            titlebg:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-DetailHeaderLeft")
            titlebg:SetTexCoord(0, 1, 0, 1)
            titlebg:SetPoint("TOP", 0, 12)
            titlebg:SetWidth(100)
            titlebg:SetHeight(40)
            titlebg:Hide()

            local title = CreateFrame("Frame", nil, frame)
            title:EnableMouse(true)
            title:SetMovable(true)
            title:RegisterForDrag("LeftButton")
            title:SetScript("OnMouseDown", Title_OnMouseDown)
            title:SetScript("OnMouseUp", MoverSizer_OnMouseUp)
            title:SetScript("OnDragStart", function(self)
                local db = Critmatic.db.profile
                if db and db.critLogWidgetPos.lock then return end
                if not IsAltKeyDown() then return end
                frame:StartMoving()
                if CritMaticIconFrame then
                    CritMaticIconFrame:StartMoving()
                end
            end)
            title:SetScript("OnDragStop", function(self)
                frame:StopMovingOrSizing()
                if CritMaticIconFrame then
                    CritMaticIconFrame:StopMovingOrSizing()
                end
            end)
            -- Position title bar to cover the top of the frame for dragging
            title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            title:SetHeight(20)

            local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            titletext:SetFont(main_font, 13, "")
            titletext:SetPoint("LEFT", frame, "TOPLEFT", 32, -10)

            local subtitletext_tbl = {}
            for _, v in ipairs(column_types) do
                subtitletext_tbl[v] = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                subtitletext_tbl[v]:SetPoint("LEFT", frame, "TOPLEFT", 20, -26)
                subtitletext_tbl[v]:SetFont(main_font, 12, "")
                subtitletext_tbl[v]:SetTextColor(0.5, 0.5, 0.5)
                subtitletext_tbl[v]:SetWordWrap(false)
            end

            local titlebg_l = frame:CreateTexture(nil, "OVERLAY")
            titlebg_l:SetTexture(131080) -- Interface\\DialogFrame\\UI-DialogBox-Header
            titlebg_l:SetTexCoord(0.21, 0.31, 0, 0.63)
            titlebg_l:SetPoint("RIGHT", titlebg, "LEFT")
            titlebg_l:SetWidth(30)
            titlebg_l:SetHeight(40)
            titlebg_l:Hide()

            local titlebg_r = frame:CreateTexture(nil, "OVERLAY")
            titlebg_r:SetTexture(131080) -- Interface\\DialogFrame\\UI-DialogBox-Header
            titlebg_r:SetTexCoord(0.67, 0.77, 0, 0.63)
            titlebg_r:SetPoint("LEFT", titlebg, "RIGHT")
            titlebg_r:SetWidth(30)
            titlebg_r:SetHeight(40)
            titlebg_r:Hide()

            local sizer_se = CreateFrame("Frame", nil, frame)
            sizer_se:SetPoint("BOTTOMRIGHT")
            sizer_se:SetWidth(25)
            sizer_se:SetHeight(25)
            sizer_se:EnableMouse()
            sizer_se:SetScript("OnMouseDown", SizerSE_OnMouseDown)
            sizer_se:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

            local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
            line1:SetWidth(14)
            line1:SetHeight(14)
            line1:SetPoint("BOTTOMRIGHT", -8, 8)
            line1:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
            local x = 0.1 * 14 / 17
            line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

            local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
            line2:SetWidth(8)
            line2:SetHeight(8)
            line2:SetPoint("BOTTOMRIGHT", -8, 8)
            line2:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
            x = 0.1 * 8 / 17
            line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

            local sizer_s = CreateFrame("Frame", nil, frame)
            sizer_s:SetPoint("BOTTOMRIGHT", -25, 0)
            sizer_s:SetPoint("BOTTOMLEFT")
            sizer_s:SetHeight(25)
            sizer_s:EnableMouse(true)
            sizer_s:SetScript("OnMouseDown", SizerS_OnMouseDown)
            sizer_s:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

            local sizer_e = CreateFrame("Frame", nil, frame)
            sizer_e:SetPoint("BOTTOMRIGHT", 0, 25)
            sizer_e:SetPoint("TOPRIGHT")
            sizer_e:SetWidth(25)
            sizer_e:EnableMouse(true)
            sizer_e:SetScript("OnMouseDown", SizerE_OnMouseDown)
            sizer_e:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

            --Container Support
            local content = CreateFrame("Frame", nil, frame)
            content:SetPoint("TOPLEFT", 3, -33)
            content:SetPoint("BOTTOMRIGHT", 15, 6)

            local scrollContainer = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
            scrollContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -20)
            scrollContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 20)

            local scrollChild = CreateFrame("Frame", nil, scrollContainer)
            scrollContainer:SetScrollChild(scrollChild)
            scrollChild:SetWidth(scrollContainer:GetWidth() or 180)
            scrollChild:SetHeight(200)  -- Will be adjusted dynamically based on content

            -- Get reference to scrollbar (created by UIPanelScrollFrameTemplate)
            local scrollBar = scrollContainer.ScrollBar or _G[scrollContainer:GetName() .. "ScrollBar"]

            -- Function to show/hide scrollbar based on content size
            local function UpdateScrollBarVisibility()
                local contentHeight = scrollChild:GetHeight() or 0
                local containerHeight = scrollContainer:GetHeight() or 0
                if scrollBar then
                    if contentHeight > containerHeight then
                        scrollBar:Show()
                    else
                        scrollBar:Hide()
                        scrollContainer:SetVerticalScroll(0)
                    end
                end
            end

            -- Update scroll child width and scrollbar visibility when container resizes
            scrollContainer:SetScript("OnSizeChanged", function(self, width, height)
                scrollChild:SetWidth(width)
                UpdateScrollBarVisibility()
            end)

            -- Table to keep track of created frames
            local createdSpellFrames = {}

            -- Create right-click context menu for spell entries
            local spellEntryMenu = CreateFrame("Frame", "CritMaticSpellEntryMenu", UIParent, "UIDropDownMenuTemplate")
            local selectedSpellName = nil
            local selectedSpellIDs = nil

            local function InitializeSpellEntryMenu(self, level)
                local info = UIDropDownMenu_CreateInfo()

                if level == 1 then
                    -- Header with spell name
                    info.isTitle = true
                    info.text = "|cffffd700" .. (selectedSpellName or "Spell") .. "|r"
                    info.notCheckable = true
                    UIDropDownMenu_AddButton(info, level)

                    -- Ignore Spell
                    info = UIDropDownMenu_CreateInfo()
                    info.text = "Ignore Spell"
                    info.notCheckable = true
                    info.func = function()
                        if selectedSpellName then
                            Critmatic.ignoredSpells[selectedSpellName:lower()] = true
                            Critmatic:Print("|cffed9d09" .. selectedSpellName .. "|r added to |cffff0000ignored|r spells.")
                            RedrawCritMaticWidget()
                        end
                    end
                    UIDropDownMenu_AddButton(info, level)

                    -- Delete Spell Data
                    info = UIDropDownMenu_CreateInfo()
                    info.text = "|cffff0000Delete Spell Data|r"
                    info.notCheckable = true
                    info.func = function()
                        if selectedSpellIDs then
                            for _, spellID in ipairs(selectedSpellIDs) do
                                CritMaticData[spellID] = nil
                            end
                            Critmatic:Print("|cffed9d09" .. (selectedSpellName or "Spell") .. "|r data has been deleted.")
                            Critmatic:InvalidateSpellAggregate()
                            RedrawCritMaticWidget()
                        end
                    end
                    UIDropDownMenu_AddButton(info, level)

                    -- Close
                    info = UIDropDownMenu_CreateInfo()
                    info.text = "Close"
                    info.notCheckable = true
                    info.func = function() CloseDropDownMenus() end
                    UIDropDownMenu_AddButton(info, level)
                end
            end

            UIDropDownMenu_Initialize(spellEntryMenu, InitializeSpellEntryMenu, "MENU")

            function RedrawCritMaticWidget()
                local yOffset = 0
                local spellFrameHeight = 45

                -- Hide or delete all previously created frames
                for _, frame in ipairs(createdSpellFrames) do
                    frame:Hide()
                    frame:SetParent(nil)
                end
                wipe(createdSpellFrames)

                local spellsByName = {}

                for spellID, spellData in pairs(CritMaticData) do
                    local spellName = GetSpellInfo(spellID)

                    if spellName then
                        if not spellsByName[spellName] then
                            spellsByName[spellName] = {
                                ids = { spellID },
                                data = spellData,
                                latestTimestamp = spellData.timestamp -- Initialize with the first timestamp
                            }
                        else
                            local spellGroup = spellsByName[spellName]
                            local existingData = spellGroup.data
                            table.insert(spellGroup.ids, spellID)

                            -- Compare and update the timestamp
                            spellGroup.latestTimestamp = math.max(spellGroup.latestTimestamp or 0, spellData.timestamp or 0)

                            -- Initialize a flag to track if data is updated


                            -- Update old values before merging the data
                            if spellData.highestCrit and spellData.highestCrit > (existingData.highestCrit or 0) then
                                existingData.highestCritOld = existingData.highestCrit
                                existingData.highestCrit = spellData.highestCrit

                            end
                            if spellData.highestNormal and spellData.highestNormal > (existingData.highestNormal or 0) then
                                existingData.highestNormalOld = existingData.highestNormal
                                existingData.highestNormal = spellData.highestNormal

                            end
                            if spellData.highestHealCrit and spellData.highestHealCrit > (existingData.highestHealCrit or 0) then
                                existingData.highestHealCritOld = existingData.highestHealCrit
                                existingData.highestHealCrit = spellData.highestHealCrit

                            end
                            if spellData.highestHeal and spellData.highestHeal > (existingData.highestHeal or 0) then
                                existingData.highestHealOld = existingData.highestHeal
                                existingData.highestHeal = spellData.highestHeal
                            end

                            -- Preserve spell icon if not already set
                            if not existingData.spellIcon and spellData.spellIcon then
                                existingData.spellIcon = spellData.spellIcon
                            end
                        end
                    end
                end

                -- Convert the spell data by name to a sortable list
                local sortableData = {}
                for spellName, spellGroup in pairs(spellsByName) do
                    table.insert(sortableData, {
                        name = spellName,
                        data = spellGroup.data,
                        ids = spellGroup.ids,
                        timestamp = spellGroup.latestTimestamp -- Use the latest timestamp for sorting
                    })
                end

                -- Sort by the latest timestamp, most recent first
                table.sort(sortableData, function(a, b)
                    return (a.timestamp or 0) > (b.timestamp or 0)
                end)

                for _, entry in ipairs(sortableData) do
                    local spellName = entry.name
                    local spellData = entry.data
                    -- Check if the spell is ignored
                    if not Critmatic.ignoredSpells or not Critmatic.ignoredSpells[spellName:lower()] then


                        local spellIDs = entry.ids  -- Now you have access to all IDs for this spell name
                        local spellIDToUse = spellIDs[1]

                        -- Use stored icon if available (fixes wrong icon for spells with shared names)
                        local spellIconPath = entry.data.spellIcon
                        if not spellIconPath then
                            -- Fallback to lookup if no stored icon
                            local _, _, iconPath = GetSpellInfo(spellIDToUse)
                            spellIconPath = iconPath
                        end

                        if spellIconPath then
                            local spellFrame = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
                            spellFrame:SetHeight(spellFrameHeight)
                            spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
                            spellFrame:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

                            -- Store spell info for context menu
                            spellFrame.spellName = spellName
                            spellFrame.spellIDs = spellIDs

                            -- Right-click to show context menu
                            spellFrame:RegisterForClicks("RightButtonUp")
                            spellFrame:SetScript("OnClick", function(self, button)
                                if button == "RightButton" then
                                    selectedSpellName = self.spellName
                                    selectedSpellIDs = self.spellIDs
                                    ToggleDropDownMenu(1, nil, spellEntryMenu, "cursor", 0, 0)
                                end
                            end)

                            -- Highlight on hover
                            spellFrame:SetScript("OnEnter", function(self)
                                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
                                self:SetBackdropColor(1, 1, 1, 0.1)
                            end)
                            spellFrame:SetScript("OnLeave", function(self)
                                self:SetBackdrop(nil)
                            end)

                            local spellIcon = spellFrame:CreateTexture(nil, "ARTWORK")
                            spellIcon:SetSize(30, 30)
                            spellIcon:SetPoint("LEFT", spellFrame, "LEFT", 5, 0)
                            spellIcon:SetTexture(spellIconPath)

                            local spellText = spellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                            spellText:SetJustifyH("LEFT")
                            spellText:SetPoint("LEFT", spellIcon, "RIGHT", 5, 0)
                            spellText:SetPoint("RIGHT", spellFrame, "RIGHT", -5, 0)
                            local gold = "|cffffd700"
                            local gray = "|cffd4d4d4"
                            local spellInfoText = gold .. "%s|r\n"

                            -- Construct the spell info text based on available data
                            spellInfoText = string.format(spellInfoText, GetSpellInfo(spellIDs[1]))

                            if spellData.highestCrit and spellData.highestCrit > 0 then
                                spellInfoText = spellInfoText .. string.format(gray .. L["crit_log_crit"] .. ": %s (" .. L["crit_log_old"] .. ": %s)|r\n", spellData.highestCrit, spellData.highestCritOld or "0")
                            end

                            if spellData.highestNormal and spellData.highestNormal > 0 then
                                spellInfoText = spellInfoText .. string.format(gray .. L["crit_log_hit"] .. ": %s (" .. L["crit_log_old"] .. ": %s)|r\n", spellData.highestNormal, spellData.highestNormalOld or "0")
                            end

                            if spellData.highestHealCrit and spellData.highestHealCrit > 0 then
                                spellInfoText = spellInfoText .. string.format(gray .. L["crit_log_crit"] .. " " .. L["crit_log_heal"] .. ": %s (" .. L["crit_log_old"] .. ": %s)|r\n", spellData.highestHealCrit, spellData.highestHealCritOld or "0")
                            end

                            if spellData.highestHeal and spellData.highestHeal > 0 then
                                spellInfoText = spellInfoText .. string.format(gray .. L["crit_log_heal"] .. ": %s (" .. L["crit_log_old"] .. ": %s)|r", spellData.highestHeal, spellData.highestHealOld or "0")
                            end

                            spellText:SetText(spellInfoText)


                            -- Add the new frame to the table
                            table.insert(createdSpellFrames, spellFrame)

                            yOffset = yOffset + spellFrameHeight

                        end
                        if scrollContainer and scrollContainer.SetVerticalScroll then
                            scrollContainer:SetVerticalScroll(0)
                        end
                    end
                end

                -- Update scroll child height to fit all content
                scrollChild:SetHeight(math.max(yOffset, 1))

                -- Update scrollbar visibility based on content vs container size
                UpdateScrollBarVisibility()
            end

            function RecordEvent(spellID)
                -- Check if the spellName is valid
                if not spellID then
                    return
                end

                -- Initialize spell data if not already present
                if not CritMaticData[spellID] then
                    CritMaticData[spellID] = {
                        timestamp = 0  -- Initialize the timestamp
                    }
                end

                -- Update the timestamp for the spell event
                CritMaticData[spellID].timestamp = time()
            end

            RedrawCritMaticWidget()
            -- A function to update CritMaticData and refresh the widget


            local widget = {
                localstatus = {},
                titletext = titletext,
                subtitletext_tbl = subtitletext_tbl,
                statustext = statustext,
                titlebg = titlebg,
                sizer_se = sizer_se,
                sizer_s = sizer_s,
                sizer_e = sizer_e,
                content = content,
                frame = frame,
                type = Type,
            }
            for method, func in pairs(methods) do
                widget[method] = func
            end
            closebutton.obj, statusbg.obj = widget, widget

            return AceGUI:RegisterAsContainer(widget)
        end

        AceGUI:RegisterWidgetType(Type, Constructor, Version)

        -- Frame creation and initial setup code
        Critmatic.crit_log_frame = AceGUI:Create("CritMatic_CritLog")

        Critmatic.crit_log_frame.frame:SetMovable(true)
        Critmatic.crit_log_frame.frame:EnableMouse(true)
        Critmatic.crit_log_frame:SetTitle("CritMatic Reborn")
        Critmatic.crit_log_frame:SetLayout("Fill")

        local function CritLogDefaultPosFrame()
            local frame = Critmatic.crit_log_frame
            local defaultPos = defaults.profile.critLogWidgetPos -- Adjust path if needed
            frame:Show()
            frame:ClearAllPoints()
            frame:SetPoint("RIGHT", UIParent, "RIGHT", defaultPos.pos_x, defaultPos.pos_y)
            Critmatic.db.profile.critLogWidgetPos.pos_x = defaultPos.pos_x
            Critmatic.db.profile.critLogWidgetPos.pos_y = defaultPos.pos_y

        end

        AceConsole:RegisterChatCommand("cmcritlogdefaultpos", CritLogDefaultPosFrame)

        -- Create icon frame as a Button so it's clickable, parented to UIParent for proper layering
        local critmatic_icon_frame = CreateFrame("Button", "CritMaticIconFrame", UIParent)
        critmatic_icon_frame:SetSize(32, 32)
        critmatic_icon_frame:SetMovable(true)
        critmatic_icon_frame:EnableMouse(true)
        critmatic_icon_frame:SetFrameStrata("HIGH")
        critmatic_icon_frame:SetFrameLevel(100)
        critmatic_icon_frame:SetPoint("TOPLEFT", Critmatic.crit_log_frame.frame, "TOPLEFT", -4, 10)

        -- Store reference to update position when main frame moves
        Critmatic.crit_log_icon_frame = critmatic_icon_frame

        -- CritMatic icon texture (no circle overlay)
        local texture_CritMatic_icon = critmatic_icon_frame:CreateTexture(nil, "ARTWORK")
        texture_CritMatic_icon:SetPoint("CENTER", critmatic_icon_frame, "CENTER", 0, 0)
        texture_CritMatic_icon:SetDrawLayer("ARTWORK", 1)
        texture_CritMatic_icon:SetHeight(32)
        texture_CritMatic_icon:SetWidth(32)
        texture_CritMatic_icon:SetTexture("Interface\\AddOns\\CritMatic\\Media\\Textures\\icon.blp")
        -- Sync icon frame visibility with main frame
        local function UpdateIconVisibility()
            if Critmatic.crit_log_frame.frame:IsShown() then
                critmatic_icon_frame:Show()
            else
                critmatic_icon_frame:Hide()
            end
        end

        -- Hook main frame show/hide to sync icon
        Critmatic.crit_log_frame.frame:HookScript("OnShow", function()
            critmatic_icon_frame:Show()
        end)
        Critmatic.crit_log_frame.frame:HookScript("OnHide", function()
            critmatic_icon_frame:Hide()
        end)

        -- Load the saved state and apply it
        if Critmatic.db.profile.isCritLogFrameShown then
            Critmatic.crit_log_frame.frame:ClearAllPoints()
            Critmatic.crit_log_frame.frame:SetPoint(sizePos.anchor, UIParent, sizePos.anchor2, sizePos.pos_x, sizePos.pos_y)
            Critmatic.crit_log_frame.frame:SetSize(300, 153)
            Critmatic.crit_log_frame.frame:Show()
            critmatic_icon_frame:Show()
            RedrawCritMaticWidget()
        else
            Critmatic.crit_log_frame.frame:Hide()
            critmatic_icon_frame:Hide()
        end

        -- Create right-click context menu for the icon
        local contextMenu = CreateFrame("Frame", "CritMaticContextMenu", UIParent, "UIDropDownMenuTemplate")

        local function InitializeContextMenu(self, level)
            local info = UIDropDownMenu_CreateInfo()

            if level == 1 then
                -- Header
                info.isTitle = true
                info.text = "|cffed9d09CritMatic Reborn|r"
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)

                -- Open Settings
                info = UIDropDownMenu_CreateInfo()
                info.text = "Open Settings"
                info.notCheckable = true
                info.func = function()
                    Critmatic:OpenOptions()
                end
                UIDropDownMenu_AddButton(info, level)

                -- Open Changelog
                info = UIDropDownMenu_CreateInfo()
                info.text = "Open Changelog"
                info.notCheckable = true
                info.func = function()
                    Critmatic:OpenChangeLog()
                end
                UIDropDownMenu_AddButton(info, level)

                -- Separator
                info = UIDropDownMenu_CreateInfo()
                info.text = ""
                info.isTitle = true
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)

                -- Lock/Unlock Position
                info = UIDropDownMenu_CreateInfo()
                info.text = Critmatic.db.profile.critLogWidgetPos.lock and "Unlock Position" or "Lock Position"
                info.notCheckable = true
                info.func = function()
                    Critmatic.db.profile.critLogWidgetPos.lock = not Critmatic.db.profile.critLogWidgetPos.lock
                    if Critmatic.db.profile.critLogWidgetPos.lock then
                        Critmatic:Print("|cffed9d09CritMatic Reborn|r: Crit Log position |cff00ff00locked|r")
                    else
                        Critmatic:Print("|cffed9d09CritMatic Reborn|r: Crit Log position |cffff0000unlocked|r")
                    end
                end
                UIDropDownMenu_AddButton(info, level)

                -- Reset Position
                info = UIDropDownMenu_CreateInfo()
                info.text = "Reset Position"
                info.notCheckable = true
                info.func = function()
                    CritLogDefaultPosFrame()
                end
                UIDropDownMenu_AddButton(info, level)

                -- Separator
                info = UIDropDownMenu_CreateInfo()
                info.text = ""
                info.isTitle = true
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)

                -- Reset All Data
                info = UIDropDownMenu_CreateInfo()
                info.text = "|cffff0000Reset All Data|r"
                info.notCheckable = true
                info.func = function()
                    StaticPopup_Show("CRITMATIC_CONFIRM_RESET")
                end
                UIDropDownMenu_AddButton(info, level)

                -- Hide Window
                info = UIDropDownMenu_CreateInfo()
                info.text = "Hide Crit Log"
                info.notCheckable = true
                info.func = function()
                    Critmatic.db.profile.isCritLogFrameShown = false
                    Critmatic.crit_log_frame.frame:Hide()
                    Critmatic:Print("|cffed9d09CritMatic Reborn|r: Crit Log hidden. Use |cffffd700/cmcritlog|r to show again.")
                end
                UIDropDownMenu_AddButton(info, level)

                -- Close menu option
                info = UIDropDownMenu_CreateInfo()
                info.text = "Close Menu"
                info.notCheckable = true
                info.func = function()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(contextMenu, InitializeContextMenu, "MENU")

        -- Create confirmation popup for reset
        StaticPopupDialogs["CRITMATIC_CONFIRM_RESET"] = {
            text = "Are you sure you want to reset ALL CritMatic data?\n\nThis cannot be undone!",
            button1 = "Yes, Reset",
            button2 = "Cancel",
            OnAccept = function()
                Critmatic:CritMaticReset()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }

        -- Register clicks on the icon frame
        critmatic_icon_frame:RegisterForClicks("AnyUp")
        critmatic_icon_frame:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 0)
            elseif button == "LeftButton" then
                -- Left click opens settings
                Critmatic:OpenOptions()
            end
        end)

        -- Add tooltip on hover
        critmatic_icon_frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cffed9d09CritMatic Reborn|r", 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Left-click: Open Settings", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Right-click: Quick Menu", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Hold ALT to move", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        critmatic_icon_frame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        -- Make sure the main frame is movable and draggable
        Critmatic.crit_log_frame.frame:SetMovable(true)
        Critmatic.crit_log_frame.frame:RegisterForDrag("LeftButton")

        -- When you start dragging the main frame, this will be called (requires ALT key)
        Critmatic.crit_log_frame.frame:SetScript("OnDragStart", function(self)
            if db.critLogWidgetPos.lock then
                return
            end
            if not IsAltKeyDown() then
                return
            end

            self:StartMoving()
            critmatic_icon_frame:StartMoving()
        end)

        -- When you stop dragging the main frame, this will be called
        Critmatic.crit_log_frame.frame:SetScript("OnDragStop", function(self)
            if db.critLogWidgetPos.lock then
                return
            end
            self:StopMovingOrSizing()
            local anchor, _, anchor2, xOfs, yOfs = self:GetPoint()  -- Get the current anchor point and offsets

            sizePos.anchor = anchor
            sizePos.anchor2 = anchor2-- Save the anchor point
            sizePos.pos_x = xOfs
            sizePos.pos_y = yOfs
        end)

        hooksecurefunc(Critmatic.crit_log_frame.frame, "StopMovingOrSizing", function()
            sizePos.size_x = Critmatic.crit_log_frame.frame:GetWidth()
            sizePos.size_y = Critmatic.crit_log_frame.frame:GetHeight()
        end)
        Critmatic.crit_log_frame.frame:SetFrameStrata("LOW")


    else
        -- Toggle visibility

        if Critmatic.crit_log_frame.frame:IsShown() then
            Critmatic.crit_log_frame.frame:Hide()
            db.isCritLogFrameShown = false


        else

            Critmatic.crit_log_frame.frame:Show()
            db.isCritLogFrameShown = true
            RedrawCritMaticWidget()
        end
        -- Save the visibility state

    end
end
