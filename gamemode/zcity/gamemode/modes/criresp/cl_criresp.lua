local MODE = MODE
MODE.name = "criresp"
local song
local songfade = 0

-- ============================================================
-- ZCITY EMBEDDED ROLE INTRO BACKGROUND
-- Фон встроен прямо в файл режима. Дополнительные lua не нужны.
-- ============================================================

local ZC_RoleBG_GradientL = Material("vgui/gradient-l")
local ZC_RoleBG_GradientD = Material("vgui/gradient-d")

local function ZC_RoleBG_Scale(v)
    return math.max(ScreenScale(v), 1)
end

local function ZC_RoleBG_GetFade(startTime, showTime)
    startTime = startTime or 0
    showTime = showTime or 8.5

    local t = CurTime() - startTime

    local appear = math.Clamp(t / 0.35, 0, 1)

    local slideStart = showTime - 1.25
    local slide = math.Clamp((t - slideStart) / 1.25, 0, 1)
    slide = slide * slide * (3 - 2 * slide)

    return appear, slide
end

local function ZC_RoleBG_TextAlpha(startTime, showTime)
    local appear, slide = ZC_RoleBG_GetFade(startTime, showTime)
    return 255 * appear * (1 - slide)
end

local function ZC_RoleBG_Draw(startTime, showTime)
    local w, h = ScrW(), ScrH()
    local appear, slide = ZC_RoleBG_GetFade(startTime, showTime)

    if appear <= 0 or slide >= 1 then return 0 end

    local yoff = -h * slide
    local alphaMul = appear
    local speed = CurTime() * 40

    draw.RoundedBox(0, 0, yoff, w, h, Color(8, 18, 45, 245 * alphaMul))

    surface.SetMaterial(ZC_RoleBG_GradientD)
    surface.SetDrawColor(0, 80, 210, 45 * alphaMul)
    surface.DrawTexturedRect(0, yoff, w, h)

    surface.SetMaterial(ZC_RoleBG_GradientL)
    surface.SetDrawColor(0, 0, 0, 180 * alphaMul)
    surface.DrawTexturedRect(0, yoff, w, h)

    local gridX = 30
    local gridY = 20
    local thick = ZC_RoleBG_Scale(0.55)
    local cellW = w / gridX
    local cellH = h / gridY

    surface.SetDrawColor(70, 130, 255, 45 * alphaMul)

    for i = 0, gridX + 1 do
        local x = (i * cellW + speed) % (w + cellW) - cellW
        surface.DrawRect(x, yoff, thick, h)
    end

    for i = 0, gridY + 1 do
        local y = ((i * cellH - speed * 0.55) % (h + cellH) - cellH) + yoff
        surface.DrawRect(0, y, w, thick)
    end

    surface.SetDrawColor(0, 160, 255, 70 * alphaMul)

    for i = 0, gridX do
        local x = (i * cellW + speed) % (w + cellW) - cellW

        for j = 0, gridY do
            if (i + j) % 4 == 0 then
                local y = ((j * cellH - speed * 0.55) % (h + cellH) - cellH) + yoff
                surface.DrawRect(x - 1, y - 1, 3, 3)
            end
        end
    end

    surface.SetDrawColor(0, 160, 255, 120 * alphaMul)
    surface.DrawRect(0, yoff + h - ZC_RoleBG_Scale(2), w, ZC_RoleBG_Scale(2))

    return alphaMul * (1 - slide)
end

--\\Local Functions
local function screen_scale_2(num)
	return ScreenScale(num) / (ScrW() / ScrH())
end
--//

net.Receive("criresp_start", function()
	surface.PlaySound("zbattle/criresp.mp3") 

	timer.Simple(3, function()
		sound.PlayFile("sound/zbattle/criresp/criepmission.mp3", "mono noblock", function(station)
			if IsValid(station) then
				station:Play()
				song = station
				songfade = 1
			end
		end)
	end)
end)

local teams = {
	[0] = {
		objective = "Ликвидируйте Преступников",
		name = "Полицейский",
		color1 = Color(68, 10, 255),
		color2 = Color(68, 10, 255)
	},
	[1] = {
		objective = "Убейте Полицию.",
		name = "Преступник",
		color1 = Color(228, 49, 49),
		color2 = Color(228, 49, 49)
	},
}

function MODE:RenderScreenspaceEffects()
	zb.RemoveFade()
	
	if zb.ROUND_START + 85 < CurTime() then
		if songfade <= 0.01 and IsValid(song) then
			song:Stop()
			if IsValid(lply) then
				surface.PlaySound(lply:Team() == 0 and "zbattle/criresp/barricadedsuspectstart.mp3" or "snd_jack_hmcd_policesiren.wav")
			end
		elseif IsValid(song) then
			songfade = Lerp(0.01, songfade, 0)
			song:SetVolume(songfade)
		end
	end
	
	if zb.ROUND_START + 7.5 < CurTime() then return end
end

local posadd = 0

function MODE:HUDPaint()
	
    local sw, sh = ScrW(), ScrH()
    local ZCIntroStart = (zb and zb.ROUND_START) or StartTime or CurTime()
    local ZCIntroMul = ZC_RoleBG_Draw(ZCIntroStart, 8.5)
if not IsValid(lply) then return end
	
	if zb.ROUND_START + 90 > CurTime() then
		posadd = Lerp(FrameTime() * 5, posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4)
		
		local color = Color(255 * -math.sin(CurTime() * 3), 25, 255 * math.sin(CurTime() * 3))
		local timeText = string.FormattedTime(zb.ROUND_START + 90 - CurTime(), "%02i:%02i")
		
		draw.SimpleText("Гаишники Прибудут через: " .. timeText, "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.95, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Гаишники Прибудут через: " .. timeText, "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.95) - 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		local fadeBlack = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
end

	if zb.ROUND_START + 8.5 > CurTime() then
		if not lply:Alive() and lply:Team() ~= 0 then return end
		
		local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
    fade = ZC_RoleBG_TextAlpha(ZCIntroStart, 8.5) / 255
		local team_ = lply:Team()
		
		if not teams[team_] then return end
		
		draw.SimpleText("Наркоманы VS Дпсники", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		local Rolename = teams[team_].name
		local ColorRole = Color(teams[team_].color1.r, teams[team_].color1.g, teams[team_].color1.b, 255 * fade)
		draw.SimpleText("Ты Теперь " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		local Objective = teams[team_].objective
		local ColorObj = Color(teams[team_].color2.r, teams[team_].color2.g, teams[team_].color2.b, 255 * fade)
		draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
    fade = ZC_RoleBG_TextAlpha(ZCIntroStart, 8.5) / 255
	if hg.PluvTown and hg.PluvTown.Active and fade then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu
net.Receive("cri_roundend", function()
	CreateEndMenu(net.ReadBool())
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local colBlue = Color(10, 10, 160)
local colBlueUp = Color(40, 40, 160)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)
local colorBG = Color(55, 55, 55, 255)
local colorBGBlacky = Color(40, 40, 40, 255)
local blurMat = Material("pp/blurscreen")
local Dynamic = 0
BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function(whowin)
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")
	surface.PlaySound((whowin == 1) and "zbattle/criresp/failedSWAT.mp3" or "ambient/alarms/warningbell1.wav")
	
	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX, posY = ScrW() / 2 - sizeX / 2, ScrH() / 2 - sizeY / 2  -- Исправлено: по центру
	
	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)
	
	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	closebutton:SetPos(5, 5)
	closebutton:SetSize(ScrW() / 20, ScrH() / 30)
	closebutton:SetText("")
	
	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self, w, h)
		surface.SetDrawColor(122, 122, 122, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize("Close")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.PaintOver = function(self, w, h)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Players:")
	end

	-- PLAYERS
	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if not IsValid(ply) then continue end
		
		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		
		but.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			
			local col1 = (ply:Alive() and colRed) or colGray
			local col2 = (ply:Alive() and colRedUp) or colSpect1
			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)
			
			local plyColor = ply:GetPlayerColor()
			local textColor = plyColor and plyColor:ToColor() or Color(255, 255, 255, 255)
			
			surface.SetFont("ZB_InterfaceMediumLarge")
			local nameX, nameY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			
			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - nameY / 2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")
			
			surface.SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
			surface.SetTextPos(w / 2, h / 2 - nameY / 2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")
			
			local col = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			
			local status = ""
			if ply:GetNetVar("handcuffed", false) then
				status = " - neutralized"
			elseif not ply:Alive() then
				status = " - dead"
			end
			
			surface.SetTextPos(15, h / 2 - nameY / 2)
			surface.DrawText(ply:Name() .. status)
			
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local fragsX, fragsY = surface.GetTextSize(ply:Frags() or 0)
			surface.SetTextPos(w - fragsX - 15, h / 2 - fragsY / 2)
			surface.DrawText(ply:Frags() or 0)
		end

		function but:DoClick()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "no, you can't")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end
	return true
end

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end