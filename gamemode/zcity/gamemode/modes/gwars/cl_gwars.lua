MODE.name = "gwars"
local MODE = MODE

local playstart
local ended

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
local MusicVolume = GetConVar("snd_musicvolume")

net.Receive("gwars_start", function()
	surface.PlaySound("zbattle/nigshit.mp3")
	zb.RemoveFade()
	playstart = true
	ended = nil

	sound.PlayFile("sound/music_themes/ghetto_loop.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	sound.PlayFile("sound/music_themes/ghetto_police.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation2 = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	//music_themes/ghetto_loop.wav
	//music_themes/ghetto_start.wav
	
end)

local teams = {
	[0] = {
		objective = "Убей всех Зеленых Шаурмистов",
		name = "Красных Шаурмистов",
		color1 = Color(180, 0, 0),
		color2 = Color(180, 0, 0)
	},
	[1] = {
		objective = "Убей всех Красных Шаурмистов",
		name = "Зеленых Шаурмистов",
		color1 = Color(0, 180, 0),
		color2 = Color(0, 180, 0)
	},
}
local lerpsnd = 0.3
function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
end

surface.CreateFont("timer_Font2", {
	font = "Bahnschrift", 
	size = ScreenScale(12), 
	extended = true, 
	weight = 650,
	antialias = true,
	italic = false
})

function MODE:HUDPaint()
    if not IsValid(lply) then lply = LocalPlayer() end
	
    local sw, sh = ScrW(), ScrH()
    local ZCIntroStart = (zb and zb.ROUND_START) or StartTime or CurTime()
    local ZCIntroMul = ZC_RoleBG_Draw(ZCIntroStart, 8.5)
//if !lply.organism or !lply.organism.fear then return end

	local timeBeforeSWAT = (zb.ROUND_START - CurTime() + 120)
	if timeBeforeSWAT > 0 and zb.ROUND_START + 10.5 < CurTime() then
		local time = string.FormattedTime(timeBeforeSWAT, "%02i:%02i:%02i")
		local text = "00:00:00"
		surface.SetFont("timer_Font2")
		surface.SetDrawColor(255, 255, 255, 255)
		local w, h = surface.GetTextSize(text)
		local w2, h2 = surface.GetTextSize("11:11:11 Осталось время до прибытия спецназа!")
		surface.SetTextPos(sw * 0.5 - w2 / 2, sh * 0.05)
		surface.DrawText(time)
		surface.SetTextPos(sw * 0.5 - w2 / 2 + w, sh * 0.05)
		surface.DrawText("Осталось время до прибытия спецназа!")
		//draw.SimpleText(" Осталось время до прибытия спецназа!", "timer_Font2", sw * 0.432, sh * 0.05, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		//draw.SimpleText(time, "timer_Font2", sw * 0.36, sh * 0.05, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if zb.ROUND_START + 8 < CurTime() then
		if playstart then
			sound.PlayFile("sound/music_themes/ghetto_start.wav", "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0.3 * MusicVolume:GetFloat())
					station:Play()
				end
			end)

			playstart = nil
		end

		lerpsnd = LerpFT(0.01, lerpsnd, !ended and (IsValid(lply) and lply:Alive() and lply.organism and !lply.organism.otrub and lply.organism.fear and math.Clamp(lply.organism.fear + 0.3 + (timeBeforeSWAT <= 0 and 2 or 0), 0, 1) or 0.3) or 0)
		
		if zb.ROUND_START + 12 < CurTime() then
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
				GWARS_LoopStation:Play()
				
				if IsValid(GWARS_LoopStation2) then
					GWARS_LoopStation2:SetVolume(0)
					GWARS_LoopStation2:Play()
				end
			end
		end

		if IsValid(GWARS_LoopStation) and GWARS_LoopStation:GetState() == GMOD_CHANNEL_PLAYING then
			GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
		end
	
		if timeBeforeSWAT <= 0 then
			if IsValid(GWARS_LoopStation2) then
				GWARS_LoopStation2:SetVolume(lerpsnd * MusicVolume:GetFloat())
			end
			
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(0)
			end
		end
	end

	if zb.ROUND_START + 8.5 < CurTime() then return end

	if not IsValid(lply) or not lply:Alive() then return end
	zb.RemoveFade()
	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
    fade = ZC_RoleBG_TextAlpha(ZCIntroStart, 8.5) / 255
	local team_ = IsValid(lply) and lply:Team() or 0
	draw.SimpleText("FreakBattle | Война За Шаурмичку", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	local teamInfo = teams[team_] or teams[0]
	local Rolename = teamInfo.name
	local ColorRole = Color(teamInfo.color1.r, teamInfo.color1.g, teamInfo.color1.b)
	ColorRole.a = 255 * fade
	draw.SimpleText("Ты из " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	local Objective = teamInfo.objective
	local ColorObj = Color(teamInfo.color2.r, teamInfo.color2.g, teamInfo.color2.b)
	ColorObj.a = 255 * fade
	draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown and hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu
net.Receive("gwars_roundend", function()
	ended = true
	CreateEndMenu()
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

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")
	surface.PlaySound("ambient/alarms/warningbell1.wav")
	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2
	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	--hmcdEndMenu:SetBackgroundColor(colGray)
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

	hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Players:")
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	-- PLAYERS
	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
	function DScrollPanel:Paint(w, h)
		BlurBackground(self)
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	for i, ply in player.Iterator() do
		if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then continue end
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
			local col = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")
			local col = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - died" or "")) or "He quited...")
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local lengthX, lengthY = surface.GetTextSize(ply:Frags() or "He quited...")
			surface.SetTextPos(w - lengthX - 15, h / 2 - lengthY / 2)
			surface.DrawText(ply:Frags() or "He quited...")
		end

		function but:DoClick()
			if not IsValid(ply) or ply:IsBot() then
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