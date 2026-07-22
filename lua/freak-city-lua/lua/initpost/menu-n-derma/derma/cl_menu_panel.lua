    local PANEL = {}
    local curent_panel
    local red_select = Color(180, 220, 255)

    local FC_ESC_BG_SHADE = Color(0, 0, 0, 55)
    local FC_ESC_BG_PATH = "materials/freakcity/menu/bg.png"
    local FC_ESC_BG_MATERIAL_PATH = "freakcity/menu/bg.png"

    local FC_ESC_LOGO_FILE = "materials/freakcity/menu/logo.png"
    local FC_ESC_LOGO_PATH = "freakcity/menu/logo.png"
    local FC_ESC_LOGO
    local FC_ESC_LOGO_WIDTH = 650
    local FC_ESC_LOGO_HEIGHT = 280
    local FC_ESC_LOGO_Y = -20

    local FC_BUTTON_MATERIAL = Material("freakcity/menu/button.png", "smooth noclamp")

    local FC_MENU_MUSIC_PATH = "sound/freakcity/menu/chainsaww.mp3"
    local FC_MENU_MUSIC_VOLUME = CreateClientConVar(
        "fc_menu_music_volume",
        "0.15",
        true,
        false,
        "Громкость музыки ESC-меню Freak-City (0-1)",
        0,
        1
    )
    local FC_MENU_MUSIC_ENABLED = CreateClientConVar(
        "fc_menu_music_enabled",
        "1",
        true,
        false,
        "Включить музыку ESC-меню Freak-City"
    )

    local FC_MenuMusicChannel
    local FC_MenuMusicOwner
    local FC_MenuMusicRequest = 0

    local function FC_StopMenuMusic(owner)
        if owner and FC_MenuMusicOwner ~= owner then return end

        FC_MenuMusicRequest = FC_MenuMusicRequest + 1
        FC_MenuMusicOwner = nil

        if IsValid(FC_MenuMusicChannel) then
            FC_MenuMusicChannel:Stop()
        end

        FC_MenuMusicChannel = nil
    end

    local function FC_PlayMenuMusic(owner)
        if not IsValid(owner) then return end
        if not FC_MENU_MUSIC_ENABLED:GetBool() then return end

        FC_StopMenuMusic()

        FC_MenuMusicOwner = owner
        FC_MenuMusicRequest = FC_MenuMusicRequest + 1
        local requestID = FC_MenuMusicRequest

        sound.PlayFile(FC_MENU_MUSIC_PATH, "noplay noblock", function(channel, errorID, errorName)
            if requestID ~= FC_MenuMusicRequest or FC_MenuMusicOwner ~= owner or not IsValid(owner) then
                if IsValid(channel) then
                    channel:Stop()
                end
                return
            end

            if not IsValid(channel) then
                return
            end

            FC_MenuMusicChannel = channel
            channel:SetVolume(math.Clamp(FC_MENU_MUSIC_VOLUME:GetFloat(), 0, 1))
            channel:EnableLooping(true)
            channel:Play()
        end)
    end

    local function FC_GetLogoMaterial()
        if not file.Exists(FC_ESC_LOGO_FILE, "GAME") then
            return nil, false
        end

        FC_ESC_LOGO = FC_ESC_LOGO or Material(FC_ESC_LOGO_PATH, "smooth noclamp")

        if not FC_ESC_LOGO or FC_ESC_LOGO:IsError() then
            return nil, false
        end

        return FC_ESC_LOGO, true
    end

local FC_ESC_GRID_GRADIENT = Material("vgui/gradient-l")
    local FC_ESC_GRID_COLUMNS = 30
    local FC_ESC_GRID_ROWS = 17
    local FC_ESC_GRID_SPEED = 30
    local FC_ESC_GRID_COLOR = Color(55, 105, 190, 38)

    local FC_ESC_BG_MAT
    local FC_ESC_BG_LAST_CHECK = 0
    local FC_ESC_BG_EXISTS = false

    local function FC_GetEscBackgroundMaterial()
        if CurTime and CurTime() < FC_ESC_BG_LAST_CHECK then
            return FC_ESC_BG_MAT, FC_ESC_BG_EXISTS
        end

        FC_ESC_BG_LAST_CHECK = (CurTime and CurTime() or 0) + 1
        FC_ESC_BG_EXISTS = file.Exists(FC_ESC_BG_PATH, "GAME")

        if FC_ESC_BG_EXISTS then
            FC_ESC_BG_MAT = FC_ESC_BG_MAT or Material(FC_ESC_BG_MATERIAL_PATH, "smooth noclamp")
            return FC_ESC_BG_MAT, not FC_ESC_BG_MAT:IsError()
        end

        return nil, false
    end

local function ZCityEaseOutCubic(x)
        x = math.Clamp(x or 0, 0, 1)
        return 1 - math.pow(1 - x, 3)
    end

    local function ZCityDrawRisingText(text, font, x, y, color, alignX, alignY, progress, rise)
        progress = math.Clamp(progress or 0, 0, 1)

        local e = ZCityEaseOutCubic(progress)
        local a = (color.a or 255) * e
        local y2 = y + (1 - e) * (rise or ScreenScaleH(18))

        draw.SimpleText(
            text or "",
            font,
            x,
            y2,
            Color(color.r, color.g, color.b, a),
            alignX or TEXT_ALIGN_LEFT,
            alignY or TEXT_ALIGN_CENTER
        )
    end

    local function ZCityUtf8Chars(str)
        local chars = {}
        str = tostring(str or "")

        for char in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
            chars[#chars + 1] = char
        end

        return chars
    end

    local function ZCityUpper(str)
        local rus = {
            ["а"] = "А", ["б"] = "Б", ["в"] = "В", ["г"] = "Г", ["д"] = "Д",
            ["е"] = "Е", ["ё"] = "Ё", ["ж"] = "Ж", ["з"] = "З", ["и"] = "И",
            ["й"] = "Й", ["к"] = "К", ["л"] = "Л", ["м"] = "М", ["н"] = "Н",
            ["о"] = "О", ["п"] = "П", ["р"] = "Р", ["с"] = "С", ["т"] = "Т",
            ["у"] = "У", ["ф"] = "Ф", ["х"] = "Х", ["ц"] = "Ц", ["ч"] = "Ч",
            ["ш"] = "Ш", ["щ"] = "Щ", ["ъ"] = "Ъ", ["ы"] = "Ы", ["ь"] = "Ь",
            ["э"] = "Э", ["ю"] = "Ю", ["я"] = "Я"
        }

        local out = {}
        for _, char in ipairs(ZCityUtf8Chars(str)) do
            out[#out + 1] = rus[char] or string.upper(char)
        end

        return table.concat(out)
    end

    local function ZCityAnimatedUpper(str, amount)
        local chars = ZCityUtf8Chars(str)
        local limit = math.ceil(#chars * math.Clamp(amount or 0, 0, 1))
        local out = {}

        for i, char in ipairs(chars) do
            out[#out + 1] = i <= limit and ZCityUpper(char) or char
        end

        return table.concat(out)
    end

    local function MakeLabelClickable(lbl)
        if not IsValid(lbl) then return end
        lbl:SetMouseInputEnabled(true)
        function lbl:OnMousePressed(mouseCode)
            if mouseCode == MOUSE_LEFT and self.DoClick then
                self:DoClick()
            end
        end
    end

    local function OpenStandaloneContent(drawFunc)
        if not isfunction(drawFunc) then return end

        hg = hg or {}
        if IsValid(hg.StandaloneEscPanel) then
            hg.StandaloneEscPanel:Remove()
        end

        local panel = vgui.Create("EditablePanel")
        panel:SetSize(ScrW(), ScrH())
        panel:SetPos(0, 0)
        panel:SetMouseInputEnabled(true)
        panel:SetKeyboardInputEnabled(true)
        panel:MakePopup()

        function panel:OnKeyCodePressed(keyCode)
            if keyCode == KEY_ESCAPE then
                self:Remove()
            end
        end

        function panel:OnRemove()
            if hg then
                hg.StandaloneEscPanel = nil
            end
            gui.EnableScreenClicker(false)
        end

        hg.StandaloneEscPanel = panel
        gui.EnableScreenClicker(true)
        drawFunc(panel)
    end

    local function ZCityShowGoodbyeAndDisconnect(luaMenu)
        if IsValid(luaMenu) then
            luaMenu:Close()
        end

        if IsValid(hg_GoodbyePanel) then
            hg_GoodbyePanel:Remove()
        end

        local pnl = vgui.Create("DPanel")
        hg_GoodbyePanel = pnl
        pnl:SetSize(ScrW(), ScrH())
        pnl:SetPos(0, 0)
        pnl:SetMouseInputEnabled(true)
        pnl:SetKeyboardInputEnabled(true)
        pnl:MakePopup()
        pnl.Created = RealTime()
        pnl.TextLerp = 0

        local goodbyeGridX = 20
        local goodbyeGridY = 30
        local goodbyeGradient = Material("vgui/gradient-l")

        function pnl:Paint(w, h)
            self.TextLerp = LerpFT(0.08, self.TextLerp or 0, 1)

            draw.RoundedBox(0, 0, 0, w, h, Color(12, 22, 45, 255))

            surface.SetDrawColor(55, 105, 190, 42)

            for i = 1, (goodbyeGridY + 1) do
                local x = (w / goodbyeGridY) * i - (CurTime() * 40 % (w / goodbyeGridY))
                surface.DrawRect(x, 0, ScreenScale(1), h)
            end

            for i = 1, (goodbyeGridX + 1) do
                local y = (h / goodbyeGridX) * (i - 1) + (CurTime() * 40 % (h / goodbyeGridX))
                surface.DrawRect(0, y, w, ScreenScale(1))
            end

            surface.SetDrawColor(0, 0, 0, 200)
            surface.SetMaterial(goodbyeGradient)
            surface.DrawTexturedRect(0, 0, 8, h)

            local a = 255 * (self.TextLerp or 0)
            local y = h * 0.5 + (1 - (self.TextLerp or 0)) * ScreenScaleH(20)

            draw.SimpleText(
                "ПРОЩАЙ",
                "ZC_MM_Title",
                w * 0.5,
                y,
                Color(180, 220, 255, a),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )

            draw.SimpleText(
                "Отключение от сервера...",
                "ZCity_Small",
                w * 0.5,
                y + ScreenScaleH(48),
                Color(100, 150, 255, a * 0.8),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        timer.Simple(1.6, function()
            RunConsoleCommand("disconnect")
        end)
    end

    local function ZCityOpenAuthorsMenu(luaMenu)
        if IsValid(luaMenu) then
            luaMenu:Close()
        end

        hg = hg or {}

        if IsValid(hg.AuthorsStandalonePanel) then
            hg.AuthorsStandalonePanel:Remove()
        end

        local panel = vgui.Create("EditablePanel")
        hg.AuthorsStandalonePanel = panel

        panel:SetSize(ScrW(), ScrH())
        panel:SetPos(0, 0)
        panel:SetMouseInputEnabled(true)
        panel:SetKeyboardInputEnabled(true)
        panel:MakePopup()
        panel.AppearLerp = 0

        local authorsGridX = 20
        local authorsGridY = 30
        local authorsGradient = Material("vgui/gradient-l")

        function panel:OnKeyCodePressed(keyCode)
            if keyCode == KEY_ESCAPE then
                self:Remove()
            end
        end

        function panel:OnRemove()
            if hg then
                hg.AuthorsStandalonePanel = nil
            end
            gui.EnableScreenClicker(false)
        end

        function panel:Think()
            self.AppearLerp = LerpFT(0.08, self.AppearLerp or 0, 1)

            if input.IsKeyDown(KEY_ESCAPE) then
                self:Remove()
            end
        end

        function panel:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(12, 22, 45, 245))

            surface.SetDrawColor(55, 105, 190, 38)

            for i = 1, (authorsGridY + 1) do
                local x = (w / authorsGridY) * i - (CurTime() * 40 % (w / authorsGridY))
                surface.DrawRect(x, 0, ScreenScale(1), h)
            end

            for i = 1, (authorsGridX + 1) do
                local y = (h / authorsGridX) * (i - 1) + (CurTime() * 40 % (h / authorsGridX))
                surface.DrawRect(0, y, w, ScreenScale(1))
            end

            surface.SetDrawColor(0, 0, 0, 200)
            surface.SetMaterial(authorsGradient)
            surface.DrawTexturedRect(0, 0, 8, h)
        end

        local boxW = math.max(ScreenScaleH(480), ScrW() * 0.38)
        local boxH = math.max(ScreenScaleH(220), ScrH() * 0.26)

        local box = vgui.Create("DPanel", panel)
        box:SetSize(boxW, boxH)
        box:SetPos((ScrW() - boxW) * 0.5, (ScrH() - boxH) * 0.5)
        box:SetMouseInputEnabled(false)

        function box:Paint(w, h)
            local a = 255 * (panel.AppearLerp or 0)

            draw.RoundedBox(8, 0, 0, w, h, Color(15, 28, 58, 220))
            surface.SetDrawColor(80, 140, 255, 140)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            draw.SimpleText(
                "АВТОРЫ",
                "ZCity_Small",
                w * 0.5,
                ScreenScaleH(22),
                Color(180, 220, 255, a),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_TOP
            )

            draw.SimpleText(
                "Frigen",
                "ZC_MM_Title",
                w * 0.5,
                h * 0.5 - ScreenScaleH(18),
                Color(180, 220, 255, a),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )

            draw.SimpleText(
                "Разработчик и создатель сервера",
                "ZCity_Small",
                w * 0.5,
                h * 0.5 + ScreenScaleH(42),
                Color(100, 150, 255, a * 0.9),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )

            draw.SimpleText(
                "ESC — закрыть",
                "ZCity_Tiny",
                w * 0.5,
                h - ScreenScaleH(18),
                Color(100, 150, 255, a * 0.65),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_BOTTOM
            )
        end

        gui.EnableScreenClicker(true)
    end

        local Selects = {
        {Title = "Играть", Func = function(luaMenu) luaMenu:Close() end},
        {Title = "Главное меню", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
        {Title = "Телеграм", Func = function(luaMenu)
            luaMenu:Close()
            gui.OpenURL("https://t.me/freakcitygmod")
        end},
        {Title = "Discord", Func = function(luaMenu)
            luaMenu:Close()
            gui.OpenURL("https://discord.gg/kWpK3RP8y6")
        end},
        {Title = "Авторы", Func = function(luaMenu) ZCityOpenAuthorsMenu(luaMenu) end},
        {Title = "Роль трейтора",
        GamemodeOnly = true,
        NoMainClick = true,
        CreatedFunc = function(self, parent, luaMenu)
            local options = {}
            local optionGap = ScreenScale(3)
            local optionW = ScreenScale(28)
            local optionH = ScreenScaleH(13)
            local rightMargin = ScreenScale(5)

            self.RoleTitleShiftAmount = -ScreenScale(34)
            self.RoleOptionsRevealLerp = 0
            self.RoleOptionsHideAt = 0

            local function OpenOldRoleSelector(roleMode)
                if not hg or not isfunction(hg.SelectPlayerRole) then
                    notification.AddLegacy(
                        "Старый выбор роли недоступен: hg.SelectPlayerRole не найден.",
                        NOTIFY_ERROR,
                        5
                    )
                    return
                end

                FreakCitySelectedTraitorMode = roleMode

                if IsValid(luaMenu) then
                    luaMenu:Close()
                end

                timer.Simple(0.15, function()
                    if hg and isfunction(hg.SelectPlayerRole) then
                        hg.SelectPlayerRole(nil, roleMode)
                    end
                end)
            end

            local function CreateRoleOption(textValue, roleMode, index)
                local option = vgui.Create("DButton", self)
                option:SetText("")
                option:SetCursor("hand")
                option:SetZPos(20)
                option.HoverLerp = 0
                option.RoleMode = roleMode
                option.TextValue = textValue
                option:SetVisible(true)
                option:SetAlpha(0)
                option:SetMouseInputEnabled(false)

                function option:Think()
                    local parentButton = self:GetParent()
                    if not IsValid(parentButton) then
                        self:Remove()
                        return
                    end

                    local reveal = math.Clamp(parentButton.RoleOptionsRevealLerp or 0, 0, 1)
                    local visible = reveal > 0.015

                    self:SetVisible(true)
                    self:SetMouseInputEnabled(reveal > 0.2)
                    self:SetAlpha(math.floor(255 * reveal))

                    if not visible then
                        self:SetCursor("arrow")
                        return
                    end

                    self:SetCursor("hand")

                    self.HoverLerp = LerpFT(
                        0.18,
                        self.HoverLerp or 0,
                        self:IsHovered() and 1 or 0
                    )

                    local totalW = optionW * 2 + optionGap
                    local startX = parentButton:GetWide() - totalW - rightMargin
                    local slide = (1 - reveal) * ScreenScale(8)

                    self:SetSize(optionW, optionH)
                    self:SetPos(
                        startX + (index - 1) * (optionW + optionGap) + slide,
                        (parentButton:GetTall() - optionH) * 0.5
                    )
                end

                function option:Paint(w, h)
                    local hover = self.HoverLerp or 0
                    local selected = FreakCitySelectedTraitorMode == self.RoleMode

                    local bg = selected
                        and Color(115, 30, 22, 235)
                        or Color(
                            Lerp(hover, 30, 92),
                            Lerp(hover, 24, 28),
                            Lerp(hover, 20, 22),
                            225
                        )

                    draw.RoundedBox(3, 0, 0, w, h, bg)

                    surface.SetDrawColor(
                        selected and Color(205, 76, 55, 235)
                            or Color(105, 77, 56, 190)
                    )
                    surface.DrawOutlinedRect(0, 0, w, h, 1)

                    draw.SimpleText(
                        self.TextValue,
                        "ZCity_Tiny",
                        w * 0.5,
                        h * 0.5,
                        Color(240, 232, 215),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end

                function option:DoClick()
                    OpenOldRoleSelector(self.RoleMode)
                end

                options[#options + 1] = option
                return option
            end

            CreateRoleOption("SOE", "soe", 1)
            CreateRoleOption("STD", "standard", 2)

            self.RoleOptionButtons = options
        end,
        Func = function(luaMenu)

        end,
        },
        {Title = "Правила", Func = function(luaMenu)
            luaMenu:Close()
            timer.Simple(0, function()
                if hg and hg.DrawRules then
                    OpenStandaloneContent(hg.DrawRules)
                end
            end)
        end},
        {Title = "Достижения", Func = function(luaMenu)
            luaMenu:Close()
            timer.Simple(0, function()
                OpenStandaloneContent(hg.DrawAchievmentsMenu)
            end)
        end},
        {Title = "Настройки", Func = function(luaMenu)
            luaMenu:Close()
            timer.Simple(0, function()
                OpenStandaloneContent(hg.DrawSettings)
            end)
        end},
        {Title = "Раздевалка", Func = function(luaMenu)
            luaMenu:Close()
            timer.Simple(0, function()
                if hg and hg.CreateApperanceMenu then
                    hg.CreateApperanceMenu()
                end
            end)
        end},
        {Title = "Отключение", Func = function(luaMenu) ZCityShowGoodbyeAndDisconnect(luaMenu) end},
    }

    local splasheh = {
        '.',
        '.',
        '.',
        '.',
        '.',
        '.',
        '.'
    }

    surface.CreateFont("ZC_MM_Title", {
        font = "Bahnschrift",
        size = ScreenScale(40),
        weight = 800,
        antialias = true
    })

    surface.CreateFont("ZCity_Small", {
        font = "Bahnschrift",
        size = ScreenScale(10),
        weight = 500,
        antialias = true
    })

    surface.CreateFont("ZCity_Tiny", {
        font = "Bahnschrift",
        size = ScreenScale(10),
        weight = 400,
        antialias = true
    })

surface.CreateFont("FC_Newspaper", {
    font = "Special Elite (Rus by Lomzz)",
    size = ScreenScale(14),
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("FC_Newspaper_Title", {
    font = "Special Elite (Rus by Lomzz)",
    size = ScreenScale(25),
    weight = 700,
    antialias = true,
    extended = true
})

surface.CreateFont("FC_Newspaper_Small", {
    font = "Special Elite (Rus by Lomzz)",
    size = ScreenScale(10),
    weight = 400,
    antialias = true,
    extended = true
})

    local FC_MenuHoverFontsReady = false
    local function FC_GetMenuHoverFont(v)
        if not FC_MenuHoverFontsReady then
            FC_MenuHoverFontsReady = true
            for i = 0, 8 do
                surface.CreateFont("ZCity_Small_Hover_" .. i, {
                    font = "Bahnschrift",
                    size = math.Round(ScreenScale(10) * (1 + i * 0.025)),
                    weight = 500 + i * 25,
                    antialias = true
                })
            end
        end

        local id = math.Clamp(math.Round((v or 0) * 8), 0, 8)
        return "ZCity_Small_Hover_" .. id
    end

    surface.CreateFont("Freak-City", {
        font = "Bahnschrift",
        size = ScreenScale(15),
        weight = 600,
        antialias = true
    })

    local Pluv = Material("pluv/pluvkid.jpg")

    function PANEL:InitializeMarkup()
        local mapname = game.GetMap()
        local prefix = string.find(mapname, "_")

        if prefix then
            mapname = string.sub(mapname, prefix + 1)
        end

        local gm = ". | " .. string.NiceName(mapname)

        return markup.Parse(
            "<font=ZCity_Tiny><colour=105,105,105>" ..
            gm ..
            "</colour></font>"
        )
    end

    local color_red = Color(100, 150, 255, 45)
    local clr_gray = Color(255,255,255,25)
    local clr_verygray = Color(25, 35, 60, 242)

    function PANEL:RestoreMainMenuButtons()
        if IsValid(self.RoleSubMenu) and self.RoleSubMenu ~= self.panelparrent then
            self.RoleSubMenu:Remove()
        end

        if IsValid(self.panelparrent) then
            self.panelparrent:Clear()
            self.panelparrent:SetZPos(3)
            self.panelparrent:SetMouseInputEnabled(false)
        end

        self.RoleSubMenu = nil
        self.InRoleSubMenu = false

        for _, btn in ipairs(self.Buttons or {}) do
            if IsValid(btn) then
                btn:SetVisible(true)
                btn:SetMouseInputEnabled(true)
            end
        end

        if IsValid(self.lDock) then
            self.lDock:SetVisible(true)
            self.lDock:SetMouseInputEnabled(true)
        end

        if IsValid(self.previewHolder) then
            self.previewHolder:SetVisible(true)
        end

        if IsValid(self.bottomDock) then
            self.bottomDock:SetVisible(true)
        end

        curent_panel = nil
    end

    local FC_ESC_CHAR = {

        x = 0.650,
        y = 0.045,
        w = 0.330,
        h = 0.92,

        fov = 29,
        camPos = Vector(86, -5, 56),
        lookAt = Vector(0, 0, 55),

        sequence = "idle_suitcase",
    }

    local function FC_ESC_CleanupPreviewAccessories(ent)
        if not IsValid(ent) or not ent.modelAccess then return end

        for k, v in pairs(ent.modelAccess) do
            if IsValid(v) then
                v:Remove()
            end

            ent.modelAccess[k] = nil
        end
    end

    function PANEL:FC_ESC_GetPreviewAppearance()
        if not hg or not hg.Appearance then return nil, nil end

        local app = hg.Appearance
        local appearance

        if app.LoadAppearanceFile and app.SelectedAppearance then
            appearance = app.LoadAppearanceFile(app.SelectedAppearance:GetString())
        end

        appearance = appearance or (app.GetRandomAppearance and app.GetRandomAppearance())

        if not istable(appearance) then return nil, nil end

        appearance.AAttachments = istable(appearance.AAttachments) and appearance.AAttachments or {"none", "none", "none"}
        appearance.AClothes = istable(appearance.AClothes) and appearance.AClothes or {}
        appearance.ABodygroups = istable(appearance.ABodygroups) and appearance.ABodygroups or {}
        appearance.AColor = appearance.AColor or Color(255, 255, 255)
        appearance.AFacemap = appearance.AFacemap or "Default"

        local pm = app.PlayerModels or {}
        local male = pm[1] or {}
        local female = pm[2] or {}
        local modelData = male[appearance.AModel] or female[appearance.AModel]

        if not modelData then
            local firstName, firstData = next(male)
            if not firstData then
                firstName, firstData = next(female)
            end

            if firstData then
                appearance.AModel = firstName
                modelData = firstData
            end
        end

        if not modelData then
            modelData = {
                mdl = "models/player/group01/male_07.mdl",
                submatSlots = {},
                sex = false
            }
        end

        modelData.submatSlots = modelData.submatSlots or {}

        return table.Copy(appearance), modelData
    end

    function PANEL:FC_ESC_ApplyAppearanceToEntity(ent, appearance, modelData)
        if not IsValid(ent) then return end
        if not istable(appearance) then return end
        if not istable(modelData) then return end
        if not hg or not hg.Appearance then return end

        appearance.AAttachments = istable(appearance.AAttachments) and appearance.AAttachments or {"none", "none", "none"}
        appearance.AClothes = istable(appearance.AClothes) and appearance.AClothes or {}
        appearance.ABodygroups = istable(appearance.ABodygroups) and appearance.ABodygroups or {}
        appearance.AColor = appearance.AColor or Color(255, 255, 255)
        appearance.AFacemap = appearance.AFacemap or "Default"

        if modelData.mdl and ent:GetModel() ~= modelData.mdl and util.IsValidModel(tostring(modelData.mdl)) then
            FC_ESC_CleanupPreviewAccessories(ent)
            ent:SetModel(modelData.mdl)
        end

        local col = appearance.AColor or Color(255, 255, 255)
        ent:SetNWVector("PlayerColor", Vector((col.r or 255) / 255, (col.g or 255) / 255, (col.b or 255) / 255))

        local seq = ent:LookupSequence(FC_ESC_CHAR.sequence)
        if seq and seq >= 0 then
            ent:SetSequence(seq)
        end

        ent:SetPlaybackRate(1)
        ent:SetSubMaterial()

        local mats = ent:GetMaterials() or {}
        local sexID = modelData.sex and 2 or 1

        for k, v in SortedPairs(modelData.submatSlots or {}) do
            local slot = nil

            for i = 1, #mats do
                if mats[i] == v then
                    slot = i - 1
                    break
                end
            end

            if slot then
                local clothesTable = hg.Appearance.Clothes and hg.Appearance.Clothes[sexID]
                local mat = clothesTable and (clothesTable[appearance.AClothes[k]] or clothesTable.normal)
                ent:SetSubMaterial(slot, mat)
                ent:SetNWString("Colthes" .. tostring(k), tostring(appearance.AClothes[k] or ""))
            end
        end

        for i = 1, #mats do
            if hg.Appearance.FacemapsSlots
                and hg.Appearance.FacemapsSlots[mats[i]]
                and hg.Appearance.FacemapsSlots[mats[i]][appearance.AFacemap] then
                ent:SetSubMaterial(i - 1, hg.Appearance.FacemapsSlots[mats[i]][appearance.AFacemap])
            end
        end

        for k, bg in SortedPairs(ent:GetBodyGroups() or {}) do
            local selected = appearance.ABodygroups[bg.name]
            if not selected then continue end

            local bodygroupData = hg.Appearance.Bodygroups
                and hg.Appearance.Bodygroups[bg.name]
                and hg.Appearance.Bodygroups[bg.name][sexID]
                and hg.Appearance.Bodygroups[bg.name][sexID][selected]

            if not bodygroupData then continue end

            for i = 0, #bg.submodels do
                if bodygroupData[1] == bg.submodels[i] then
                    ent:SetBodygroup(k - 1, i)
                    break
                end
            end
        end
    end

    function PANEL:FC_ESC_DrawPreviewAccessories(ent, appearance)
        if not IsValid(ent) then return end
        if not istable(appearance) then return end
        if not DrawAccesories then return end

        appearance.AAttachments = istable(appearance.AAttachments) and appearance.AAttachments or {"none", "none", "none"}

        for _, attach in ipairs(appearance.AAttachments) do
            if attach and attach ~= "none" and hg and hg.Accessories and hg.Accessories[attach] then
                DrawAccesories(ent, ent, attach, hg.Accessories[attach], false, true)
            end
        end

        ent:SetupBones()
    end

    function PANEL:CreateAppearancePreview()
        if IsValid(self.previewHolder) then
            self.previewHolder:Remove()
            self.previewHolder = nil
        end

        local appearance, modelData = self:FC_ESC_GetPreviewAppearance()
        if not appearance or not modelData then return end

        if hg and hg.Appearance and hg.Appearance.PrecacheModels then
            hg.Appearance.PrecacheModels()
        end

        local holder = vgui.Create("DPanel", self)
        self.previewHolder = holder

        local holderW = ScrW() * FC_ESC_CHAR.w
        local holderH = ScrH() * FC_ESC_CHAR.h
        local targetX = ScrW() * FC_ESC_CHAR.x
        local targetY = ScrH() * FC_ESC_CHAR.y

        holder:SetSize(holderW, holderH)
        holder:SetPos(targetX, ScrH())
        holder:SetAlpha(0)
        holder:SetMouseInputEnabled(false)
        holder:SetKeyboardInputEnabled(false)
        holder:SetZPos(7)
        holder.Paint = function() end

        local viewer = vgui.Create("DModelPanel", holder)
        self.previewModel = viewer
        viewer:Dock(FILL)
        viewer:SetMouseInputEnabled(false)
        viewer:SetKeyboardInputEnabled(false)
        viewer:SetPaintBackground(false)

        viewer.AppearanceTable = appearance
        viewer.ModelData = modelData
        viewer:SetModel(util.IsValidModel(tostring(modelData.mdl)) and tostring(modelData.mdl) or "models/player/group01/male_07.mdl")

        viewer:SetFOV(FC_ESC_CHAR.fov)
        viewer:SetCamPos(FC_ESC_CHAR.camPos)
        viewer:SetLookAt(FC_ESC_CHAR.lookAt)
        viewer:SetLookAng(Angle(7, 180, 0))

        viewer:SetAmbientLight(Color(55, 58, 65))
        viewer:SetDirectionalLight(BOX_FRONT, Color(165, 170, 180))
        viewer:SetDirectionalLight(BOX_RIGHT, Color(120, 150, 210))
        viewer:SetDirectionalLight(BOX_LEFT, Color(55, 65, 85))
        viewer:SetDirectionalLight(BOX_TOP, Color(170, 175, 185))
        viewer:SetDirectionalLight(BOX_BACK, Color(5, 5, 8))
        viewer:SetDirectionalLight(BOX_BOTTOM, Color(5, 5, 8))

        local oldPaint = viewer.Paint
        function viewer:Paint(w, h)

            DisableClipping(true)
            oldPaint(self, w, h)
            DisableClipping(false)
        end

        function viewer:LayoutEntity(ent)
            local owner = self:GetParent() and self:GetParent():GetParent()
            if not IsValid(owner) then return end

            local appearanceData = self.AppearanceTable
            local modelData2 = self.ModelData

            owner:FC_ESC_ApplyAppearanceToEntity(ent, appearanceData, modelData2)

            local mx, my = gui.MouseX(), gui.MouseY()
            local nx = math.Clamp((mx / ScrW() - 0.5) * 2, -1, 1)
            local ny = math.Clamp((my / ScrH() - 0.5) * 2, -1, 1)

            ent:SetAngles(Angle(0, -2 - nx * 5, 0))
            ent:SetPoseParameter("head_yaw", -nx * 10)
            ent:SetPoseParameter("head_pitch", -ny * 4)
            ent:FrameAdvance(RealFrameTime())

            self:SetFOV(FC_ESC_CHAR.fov)
            self:SetCamPos(FC_ESC_CHAR.camPos)
            self:SetLookAt(FC_ESC_CHAR.lookAt)
        end

        function viewer:PostDrawModel(ent)
            local owner = self:GetParent() and self:GetParent():GetParent()
            if not IsValid(owner) then return end

            owner:FC_ESC_DrawPreviewAccessories(ent, self.AppearanceTable)
        end

        function viewer:OnRemove()
            if IsValid(self.Entity) then
                FC_ESC_CleanupPreviewAccessories(self.Entity)
            end
        end

        timer.Simple(0, function()
            if not IsValid(holder) then return end
            holder:MoveTo(targetX, targetY, 0.65, 0, 0.12)
            holder:AlphaTo(255, 0.45, 0.12)
        end)
    end

    function PANEL:Init()
        self:SetAlpha(0)
        self:SetSize(ScrW(), ScrH())

        FC_PlayMenuMusic(self)

        self.OpenedAt = RealTime()
        self.MenuOpenLerp = 0
        self.MenuOpenOffset = ScreenScaleH(34)
        self.MenuTextRise = ScreenScaleH(22)
        self:Center()
        self:SetTitle("")
        self:SetDraggable(false)
        self:SetBorder(false)
        self:SetColorBG(clr_verygray)
        self:SetDraggable(false)
        self:ShowCloseButton(false)
        curent_panel = nil
        self.Title, self.TitleShadow = self:InitializeMarkup()

        timer.Simple(0, function()
            if self.First then
                self:First()
            end
        end)

        self.lDock = vgui.Create("DPanel", self)
        local lDock = self.lDock
        lDock:SetZPos(10)

        self.MenuLeftX = math.max(ScreenScaleH(28), ScrW() * 0.035)
        self.MenuTopY = ScrH() * 0.17
        self.MenuWidth = math.max(ScreenScaleH(330), ScrW() * 0.27)

        lDock:SetSize(self.MenuWidth, ScrH() * 0.6)
        lDock:SetPos(self.MenuLeftX, self.MenuTopY)
        lDock:DockPadding(0, ScreenScaleH(104), 0, 0)
        lDock.Paint = function(this, w, h)
            local openedAt = self.OpenedAt or RealTime()
            local shouldAppear = RealTime() >= openedAt + (self.TitleAppearDelay or 0)

            self.TitleAppearLerp = LerpFT(
                0.07,
                self.TitleAppearLerp or 0,
                shouldAppear and 1 or 0
            )

            local titleProgress = ZCityEaseOutCubic(self.TitleAppearLerp or 0)
            local alpha = 255 * titleProgress
            local riseOffset = (1 - titleProgress) * (self.TitleAppearOffset or 0)

            local logoW = FC_ESC_LOGO_WIDTH
            local logoH = logoW * (FC_ESC_LOGO_HEIGHT / FC_ESC_LOGO_WIDTH)
            local logoX = w * 0.5 - logoW * 0.5
            local logoY = FC_ESC_LOGO_Y + riseOffset

            local logoMaterial, logoIsValid = FC_GetLogoMaterial()

            if logoIsValid then
                surface.SetMaterial(logoMaterial)
                surface.SetDrawColor(255, 255, 255, alpha)
                surface.DrawTexturedRect(logoX, logoY, logoW, logoH)
            else
                draw.SimpleText(
                    "Freak-City",
                    "ZC_MM_Title",
                    w * 0.5,
                    ScreenScaleH(4) + riseOffset,
                    Color(210, 220, 235, alpha),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_TOP
                )
            end

            self.Title:Draw(
                w * 0.5,
                ScreenScaleH(72) + riseOffset,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_TOP,
                alpha,
                TEXT_ALIGN_CENTER
            )
        end

        self.Buttons = {}
        self.FC_MenuExtraOffset = 0
        for k, v in ipairs(Selects) do
            if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
            self:AddSelect(lDock, v.Title, v)
        end

        local totalButtons = #self.Buttons
        for index, btn in ipairs(self.Buttons) do
            if IsValid(btn) then

                btn.AppearDelay = (totalButtons - index) * 0.10
                btn.AppearOffset = ScreenScaleH(32)
            end
        end

        local buttonTall = ScreenScale(15)
        local buttonGap = ScreenScaleH(5)
        local topPadding = ScreenScaleH(104)
        local minTall = ScrH() * 0.6
        local needTall = topPadding + (#self.Buttons * (buttonTall + buttonGap)) + ScreenScaleH(20)
        local targetTall = math.min(ScrH() * 0.85, math.max(minTall, needTall))
        lDock:SetTall(targetTall)
        lDock:SetPos(
            self.MenuLeftX or math.max(ScreenScaleH(28), ScrW() * 0.035),
            math.Clamp(self.MenuTopY or ScrH() * 0.17, ScreenScaleH(10), ScrH() - targetTall - ScreenScaleH(10))
        )

        local bottomDock = vgui.Create("DPanel", self)
        self.bottomDock = bottomDock
        local footerLineH = math.max(16, ScreenScaleH(16))
        local footerPad = 6
        bottomDock:SetVisible(true)
        bottomDock:SetSize(math.min(ScrW() * 0.65, math.max(600, ScreenScaleH(600))), footerLineH * 4 + footerPad * 2)
        bottomDock.BaseX = ScreenScale(15)
        bottomDock.AppearOffset = ScreenScaleH(34)
        bottomDock.AppearDelay = 0.18
        bottomDock.AppearLerp = 0
        bottomDock:SetAlpha(0)
        bottomDock:SetPos(bottomDock.BaseX, ScrH() - bottomDock:GetTall() - ScreenScale(10) + bottomDock.AppearOffset)
        bottomDock.Paint = function(this, w, h) end
        bottomDock.Think = function(this)
            local parentPanel = this:GetParent()
            local openedAt = IsValid(parentPanel) and (parentPanel.OpenedAt or RealTime()) or RealTime()
            local shouldAppear = RealTime() >= openedAt + this.AppearDelay

            this.AppearLerp = LerpFT(0.07, this.AppearLerp or 0, shouldAppear and 1 or 0)
            local footerEase = ZCityEaseOutCubic(this.AppearLerp or 0)
            this:SetAlpha(255 * footerEase)
            this:SetPos(this.BaseX, ScrH() - this:GetTall() - ScreenScale(10) + (1 - footerEase) * this.AppearOffset)

            for _, child in ipairs(this:GetChildren()) do
                if IsValid(child) then
                    child:SetAlpha(this:GetAlpha())
                end
            end
        end

        self.panelparrent = vgui.Create("DPanel", self)
        self.panelparrent:SetPos(0, 0)
        self.panelparrent:SetSize(ScrW(), ScrH())
        self.panelparrent:SetMouseInputEnabled(false)
        self.panelparrent:SetZPos(3)
        self.panelparrent.Paint = function(this, w, h) end

        local infoColor = Color(255, 255, 255, 230)

        local authors = vgui.Create("DLabel", bottomDock)
        authors:SetPos(0, footerPad + footerLineH * 0)
        authors:SetSize(bottomDock:GetWide(), footerLineH)
        authors:SetFont("ZCity_Tiny")
        authors:SetTextColor(infoColor)
        authors:SetText("")
        authors:SetContentAlignment(4)

        local freakAuthors = vgui.Create("DLabel", bottomDock)
        freakAuthors:SetPos(0, footerPad + footerLineH * 3)
        freakAuthors:SetSize(bottomDock:GetWide(), footerLineH)
        freakAuthors:SetFont("ZCity_Tiny")
        freakAuthors:SetTextColor(infoColor)
        freakAuthors:SetText("FreakCity authors: Frigen, Variola")
        freakAuthors:SetContentAlignment(4)

        self:CreateAppearancePreview()
    end

    function PANEL:Paint(w, h)

        if self.InRoleSubMenu then

            return
        end

        local bgMat, exists = FC_GetEscBackgroundMaterial()

        if exists and bgMat then
            surface.SetMaterial(bgMat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(0, 0, w, h)
        else
            draw.RoundedBox(0, 0, 0, w, h, Color(12, 22, 45, 255))
        end

        surface.SetDrawColor(0, 0, 0, 80)
        surface.DrawRect(0, 0, w, h)
    end

    function PANEL:First( ply )
        self.OpenedAt = RealTime()
        self.MenuOpenLerp = 0
        self.TitleAppearDelay = 0.08
        self.TitleAppearOffset = ScreenScaleH(34)
        self.TitleAppearLerp = 0
        self:AlphaTo(255, 0.22, 0, nil)
    end

    function PANEL:Think()
        self.MenuOpenLerp = LerpFT(0.07, self.MenuOpenLerp or 0, 1)

    end

    local sw, sh = ScrW(), ScrH()
    local gridX = 20
    local gridY = 30

    function PANEL:AddSelect( pParent, strTitle, tbl )
        local id = #self.Buttons + 1

        self.Buttons[id] = vgui.Create("DButton", pParent)
        local btn = self.Buttons[id]
        local buttonTall = ScreenScale(15)
        local buttonGap = ScreenScaleH(5)
        local hitPad = ScreenScaleH(18)

        btn:SetText("")
        btn:SetCursor("hand")
        btn:SetFont("FC_Newspaper")
        local previousExtraOffset = self.FC_MenuExtraOffset or 0
        btn.BaseY = ScreenScaleH(104) + (id - 1) * (buttonTall + buttonGap) + previousExtraOffset
        btn.MenuExtraHeight = tbl.ExtraHeight or 0
        self.FC_MenuExtraOffset = previousExtraOffset + btn.MenuExtraHeight
        btn.AppearOffset = ScreenScaleH(32)
        btn.AppearDelay = 0
        btn.AppearLerp = 0
        btn.TextDrawLerp = 0
        btn.HoverLerp = 0
        btn.PressLerp = 0
        btn.DisplayText = strTitle
        btn.DisplayColor = Color(100, 150, 255)
        btn:SetAlpha(0)
        btn.Func = tbl.Func
        btn.HoveredFunc = tbl.HoveredFunc

        surface.SetFont(FC_GetMenuHoverFont(1))
        local maxText = ZCityUpper(strTitle or "")
        local maxW, maxH = surface.GetTextSize(maxText)
btn.HitW = ScreenScaleH(220)
btn.HitH = ScreenScaleH(35)
        btn:SetSize(btn.HitW, btn.HitH)
        btn:SetPos((pParent:GetWide() - btn.HitW) * 0.5, btn.BaseY + btn.AppearOffset)

        local luaMenu = self
        if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end

        function btn:DoClick()
            if tbl.NoMainClick then return end

            if curent_panel == string.lower(strTitle) then
                for i = 1, 3 do
                    surface.PlaySound("shitty/tap_release.wav")
                end
                if luaMenu.panelparrent and IsValid(luaMenu.panelparrent) then
                    luaMenu.panelparrent:AlphaTo(0, 0.2, 0, function()
                        if luaMenu.panelparrent then luaMenu.panelparrent:Remove() end
                        luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                        luaMenu.panelparrent:SetSize(ScrW(), ScrH())
                        luaMenu.panelparrent.Paint = function(this, w, h) end
                        curent_panel = nil
                    end)
                end
                return
            end

            if luaMenu.panelparrent and IsValid(luaMenu.panelparrent) then
                luaMenu.panelparrent:AlphaTo(0, 0.2, 0, function()
                    if luaMenu.panelparrent then luaMenu.panelparrent:Remove() end
                    luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                    luaMenu.panelparrent:SetSize(ScrW(), ScrH())
                    luaMenu.panelparrent.Paint = function(this, w, h) end
                    btn.Func(luaMenu, luaMenu.panelparrent)
                    curent_panel = string.lower(strTitle)
                end)
            else
                luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                luaMenu.panelparrent:SetSize(ScrW(), ScrH())
                luaMenu.panelparrent.Paint = function(this, w, h) end
                btn.Func(luaMenu, luaMenu.panelparrent)
                curent_panel = string.lower(strTitle)
            end

            for i = 1, 3 do
                surface.PlaySound("shitty/tap_depress.wav")
            end
        end

        function btn:Think()
            local openedAt = luaMenu.OpenedAt or RealTime()
            local shouldAppear = RealTime() >= openedAt + self.AppearDelay
            self.AppearLerp = LerpFT(0.07, self.AppearLerp or 0, shouldAppear and 1 or 0)
            local appearEase = ZCityEaseOutCubic(self.AppearLerp or 0)
            self.TextDrawLerp = appearEase
            self:SetAlpha(255 * appearEase)

            self:SetSize(self.HitW, self.HitH)
            self:SetPos((pParent:GetWide() - self.HitW) * 0.5, self.BaseY + (1 - appearEase) * self.AppearOffset)

            local roleOptionHovered = false
            for _, roleOption in ipairs(self.RoleOptionButtons or {}) do
                if IsValid(roleOption)
                    and (roleOption:GetAlpha() or 0) > 10
                    and roleOption:IsHovered() then
                    roleOptionHovered = true
                    break
                end
            end

            local directHover = self:IsHovered()

            if directHover or roleOptionHovered then

                self.RoleOptionsHideAt = RealTime() + 0.35
            end

            local roleOptionsOpen = directHover
                or roleOptionHovered
                or RealTime() < (self.RoleOptionsHideAt or 0)

            self.RoleOptionsRevealLerp = LerpFT(
                0.22,
                self.RoleOptionsRevealLerp or 0,
                roleOptionsOpen and 1 or 0
            )

            local isHovered = roleOptionsOpen
            local isDown = self:IsDown()
            self.HoverLerp = LerpFT(0.18, self.HoverLerp or 0, isHovered and 1 or 0)
            self.PressLerp = LerpFT(0.22, self.PressLerp or 0, isDown and 1 or 0)

            local v = self.HoverLerp or 0
            local isCurrent = curent_panel == string.lower(strTitle) and strTitle ~= "Роль трейтора"
            local baseText = isCurrent and ("[ " .. strTitle .. " ]") or strTitle

            self.DisplayText = ZCityAnimatedUpper(baseText, isCurrent and 1 or v)
  self.DisplayColor = Color(
    Lerp(v, 65, 160),
    Lerp(v, 20, 35),
    Lerp(v, 15, 25),
    255
)
        end

        function btn:Paint(w, h)
            local v = self.HoverLerp or 0
            local p = self.PressLerp or 0
            local text = self.DisplayText or strTitle
            local font = "FC_Newspaper"
            local roleReveal = math.Clamp(self.RoleOptionsRevealLerp or 0, 0, 1)
            local x = w * 0.5 + (self.RoleTitleShiftAmount or 0) * roleReveal
            local y = h * 0.5 + Lerp(p, 0, ScreenScaleH(1))
            local col = self.DisplayColor or Color(100, 150, 255)
            local alpha = 255 * (self.TextDrawLerp or self.AppearLerp or 0)

            if FC_BUTTON_MATERIAL and not FC_BUTTON_MATERIAL:IsError() then
                local scale = 1 + v * 0.04

                surface.SetMaterial(FC_BUTTON_MATERIAL)
                surface.SetDrawColor(255, 255 - v * 55, 255 - v * 55, alpha)

                surface.DrawTexturedRect(
                    (w - w * scale) / 2,
                    (h - h * scale) / 2,
                    w * scale,
                    h * scale
                )
            end

            draw.SimpleText(
                text or "",
                font or "ZCity_Small",
                x or 0,
                y or 0,
                Color(col.r or 255, col.g or 255, col.b or 255, alpha or 255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end
    end

    function PANEL:Close()
        FC_StopMenuMusic(self)

        if IsValid(self.previewHolder) then
            self.previewHolder:Remove()
            self.previewHolder = nil
        end

        curent_panel = nil
        self:RestoreMainMenuButtons()
        if IsValid(self.panelparrent) then
            self.panelparrent:Remove()
            self.panelparrent = nil
        end
        self:AlphaTo(0, 0.18, 0, function() self:Remove() end)
        gui.EnableScreenClicker(false)
        self:SetKeyboardInputEnabled(false)
        self:SetMouseInputEnabled(false)
    end

    function PANEL:OnKeyCodePressed(keyCode)
        if keyCode ~= KEY_ESCAPE then return end
        if self.InRoleSubMenu then
            self:RestoreMainMenuButtons()
            return
        end
        self:Close()
        MainMenu = nil
    end

    function PANEL:OnRemove()

        FC_StopMenuMusic(self)
    end

    vgui.Register( "ZMainMenu", PANEL, "ZFrame")

    hook.Add("OnPauseMenuShow","OpenMainMenu",function()
        if IsValid(zpan) then
            zpan:Close()
            zpan = nil
            return false
        end

        if hg and IsValid(hg.StandaloneEscPanel) then
            hg.StandaloneEscPanel:Remove()
            hg.StandaloneEscPanel = nil
            return false
        end

        local run = hook.Run("OnShowZCityPause")
        if run != nil then
            return run
        end

        if MainMenu and IsValid(MainMenu) then
            MainMenu:Close()
            MainMenu = nil
            return false
        end

        MainMenu = vgui.Create("ZMainMenu")
        MainMenu:MakePopup()
        MainMenu:SetMouseInputEnabled(true)
        MainMenu:SetKeyboardInputEnabled(true)
        gui.EnableScreenClicker(true)
        return false
    end)
