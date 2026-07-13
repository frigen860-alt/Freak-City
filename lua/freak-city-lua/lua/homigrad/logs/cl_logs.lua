if SERVER then return end

surface.CreateFont("ZLogs_Title", {
    font = "Tahoma",
    size = 16,
    weight = 800,
    antialias = true,
    extended = true
})

surface.CreateFont("ZLogs_Text", {
    font = "Tahoma",
    size = 14,
    weight = 600,
    antialias = true,
    extended = true
})

surface.CreateFont("ZLogs_Small", {
    font = "Tahoma",
    size = 13,
    weight = 500,
    antialias = true,
    extended = true
})

local categories = {
    "All Logs",
    "Chat",
    "Command",
    "Connect",
    "Disconnect",
    "Damage",
    "Team",
    "Sandbox",
    "Spawn",
    "ULX",
}

local currentCategory = "All Logs"
local searchText = ""
local listPanel
local frameRef

local col_bg = Color(10, 10, 10, 245)
local col_panel = Color(18, 18, 18, 255)
local col_panel2 = Color(25, 25, 25, 255)
local col_header = Color(5, 5, 5, 255)
local col_line = Color(32, 32, 32, 255)
local col_line2 = Color(24, 24, 24, 255)
local col_hover = Color(45, 45, 45, 255)
local col_blue = Color(0, 130, 220, 255)
local col_white = Color(245, 245, 245, 255)
local col_gray = Color(150, 150, 150, 255)
local col_border = Color(70, 70, 70, 255)

local function RequestLogs()
    net.Start("zlogs_request")
    net.WriteString(currentCategory)
    net.WriteString(searchText)
    net.SendToServer()
end

local function StyleButton(btn, textFunc, activeFunc)
    btn:SetText("")
    btn.Paint = function(self, w, h)
        local active = activeFunc and activeFunc() or false

        if active then
            surface.SetDrawColor(col_blue)
        elseif self:IsHovered() then
            surface.SetDrawColor(col_hover)
        else
            surface.SetDrawColor(col_panel2)
        end

        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_border)
        surface.DrawOutlinedRect(0, 0, w, h)

        draw.SimpleText(
            textFunc and textFunc() or "",
            "ZLogs_Small",
            w / 2,
            h / 2,
            col_white,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end
end

local function SkinTextEntry(entry)
    entry:SetTextColor(col_white)
    entry:SetCursorColor(col_white)
    entry:SetHighlightColor(col_blue)
    entry:SetFont("ZLogs_Small")
    entry.Paint = function(self, w, h)
        surface.SetDrawColor(35, 35, 35, 255)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_border)
        surface.DrawOutlinedRect(0, 0, w, h)

        self:DrawTextEntryText(col_white, col_blue, col_white)

        if self:GetValue() == "" and self:GetPlaceholderText() then
            draw.SimpleText(
                self:GetPlaceholderText(),
                "ZLogs_Small",
                8,
                h / 2,
                Color(130, 130, 130),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end
    end
end

local function SkinCombo(combo)
    combo:SetTextColor(col_white)
    combo:SetFont("ZLogs_Small")
    combo.Paint = function(self, w, h)
        surface.SetDrawColor(35, 35, 35, 255)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_border)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
end

local function OpenLogsMenu()
    if IsValid(frameRef) then
        frameRef:Remove()
    end

    local frame = vgui.Create("DFrame")
    frameRef = frame
    frame:SetSize(ScrW() * 0.75, ScrH() * 0.75)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        surface.SetDrawColor(col_bg)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, w, 32)

        surface.SetDrawColor(col_border)
        surface.DrawOutlinedRect(0, 0, w, h)

        draw.SimpleText("ZCity Logs", "ZLogs_Title", w / 2, 16, col_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(28, 22)
    close:SetPos(frame:GetWide() - 34, 5)
    StyleButton(close, function() return "X" end)
    close.DoClick = function()
        frame:Close()
    end

    local left = vgui.Create("DScrollPanel", frame)
    left:SetPos(8, 36)
    left:SetSize(140, frame:GetTall() - 82)
    left.Paint = function(self, w, h)
        surface.SetDrawColor(12, 12, 12, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local sbar = left:GetVBar()
    if IsValid(sbar) then
        sbar:SetWide(6)
        sbar.Paint = function(self, w, h)
            surface.SetDrawColor(15, 15, 15, 255)
            surface.DrawRect(0, 0, w, h)
        end
        sbar.btnGrip.Paint = function(self, w, h)
            surface.SetDrawColor(80, 80, 80, 255)
            surface.DrawRect(0, 0, w, h)
        end
        sbar.btnUp.Paint = function() end
        sbar.btnDown.Paint = function() end
    end

    local content = vgui.Create("DPanel", frame)
    content:SetPos(155, 36)
    content:SetSize(frame:GetWide() - 163, frame:GetTall() - 82)

    content.Paint = function(self, w, h)
        surface.SetDrawColor(col_panel)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_header)
        surface.DrawRect(0, 0, w, 26)

        surface.SetDrawColor(col_border)
        surface.DrawOutlinedRect(0, 0, w, h)

        draw.SimpleText(currentCategory, "ZLogs_Text", 8, 13, col_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    listPanel = vgui.Create("DListView", content)
    listPanel:SetPos(0, 27)
    listPanel:SetSize(content:GetWide(), content:GetTall() - 27)
    listPanel:SetMultiSelect(false)
    listPanel.Paint = function(self, w, h)
        surface.SetDrawColor(16, 16, 16, 255)
        surface.DrawRect(0, 0, w, h)
    end

    -- КОЛОНКИ С IP
    listPanel:AddColumn("Date / Time"):SetFixedWidth(155)
    listPanel:AddColumn("Player"):SetFixedWidth(185)
    listPanel:AddColumn("SteamID"):SetFixedWidth(180)
    listPanel:AddColumn("IP"):SetFixedWidth(120)
    listPanel:AddColumn("Action / Log")

    for _, col in pairs(listPanel.Columns or {}) do
        col.Header:SetTextColor(col_white)
        col.Header:SetFont("ZLogs_Small")
        col.Header.Paint = function(self, w, h)
            surface.SetDrawColor(35, 35, 35, 255)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(col_border)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    end

    function listPanel:OnRowSelected(id, line)
        if not IsValid(line) then return end
        SetClipboardText(table.concat({
            line:GetColumnText(1),
            line:GetColumnText(2),
            line:GetColumnText(3),
            line:GetColumnText(4),
            line:GetColumnText(5),
        }, " | "))
        surface.PlaySound("buttons/button15.wav")
    end

    for _, cat in ipairs(categories) do
        local btn = vgui.Create("DButton", left)
        btn:Dock(TOP)
        btn:SetTall(28)
        btn:DockMargin(0, 0, 0, 2)

        StyleButton(btn, function()
            return cat
        end, function()
            return currentCategory == cat
        end)

        btn.DoClick = function()
            currentCategory = cat
            RequestLogs()
        end
    end

    local bottomY = frame:GetTall() - 38

    local search = vgui.Create("DTextEntry", frame)
    search:SetPos(8, bottomY)
    search:SetSize(260, 26)
    search:SetPlaceholderText("Search nick / SteamID / IP ...")
    SkinTextEntry(search)

    search.OnEnter = function(self)
        searchText = self:GetValue()
        RequestLogs()
    end

    local searchBtn = vgui.Create("DButton", frame)
    searchBtn:SetPos(274, bottomY)
    searchBtn:SetSize(70, 26)
    StyleButton(searchBtn, function() return "Search" end)
    searchBtn.DoClick = function()
        searchText = search:GetValue()
        RequestLogs()
    end

    local choose = vgui.Create("DComboBox", frame)
    choose:SetPos(352, bottomY)
    choose:SetSize(190, 26)
    choose:SetValue("Choose Player")
    SkinCombo(choose)

    for _, ply in ipairs(player.GetAll()) do
        choose:AddChoice(ply:Nick() .. " | " .. ply:SteamID(), ply:SteamID())
    end

    choose.OnSelect = function(_, _, _, data)
        searchText = data
        search:SetValue(data)
        RequestLogs()
    end

    local reset = vgui.Create("DButton", frame)
    reset:SetPos(550, bottomY)
    reset:SetSize(70, 26)
    StyleButton(reset, function() return "Reset" end)

    reset.DoClick = function()
        searchText = ""
        search:SetValue("")
        currentCategory = "All Logs"
        RequestLogs()
    end

    RequestLogs()
end

net.Receive("zlogs_open", function()
    OpenLogsMenu()
end)

net.Receive("zlogs_send", function()
    local rows = net.ReadTable()

    if not IsValid(listPanel) then return end
    listPanel:Clear()

    for _, r in ipairs(rows or {}) do
        local line = listPanel:AddLine(
            r.time or "",
            r.nick or "",
            r.steamid or "",
            r.ip or "0.0.0.0",
            "[" .. tostring(r.category or "") .. "] " .. tostring(r.action or "") .. " | " .. tostring(r.details or "")
        )

        for i = 1, #line.Columns do
            line.Columns[i]:SetTextColor(col_white)
            line.Columns[i]:SetFont("ZLogs_Small")
        end

        line.Paint = function(self, w, h)
            if self:IsSelected() then
                surface.SetDrawColor(0, 100, 180, 255)
            elseif self:IsHovered() then
                surface.SetDrawColor(45, 45, 45, 255)
            elseif self:GetID() % 2 == 0 then
                surface.SetDrawColor(col_line)
            else
                surface.SetDrawColor(col_line2)
            end

            surface.DrawRect(0, 0, w, h)
        end
    end
end)

print("[ZLOGS] Client loaded")