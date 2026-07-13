local PANEL = {}
local orange = Color(230,115,35,230)
local gridX, gridY = 17,30

local function DrawGrid(w,h)
 surface.SetDrawColor(230,115,35,35)
 for i=1,gridY do
  local x=(w/gridY)*i-(CurTime()*25%(w/gridY))
  surface.DrawRect(x,0,1,h)
 end
 for i=1,gridX do
  local y=(h/gridX)*i+(CurTime()*25%(h/gridX))
  surface.DrawRect(0,y,w,1)
 end
end

function PANEL:Paint(w,h)
 if hg and hg.DrawBlur then hg.DrawBlur(self,2) end
 draw.RoundedBox(14,0,0,w,h,Color(35,18,8,245))
 DrawGrid(w,h)
 surface.SetDrawColor(orange)
 surface.DrawOutlinedRect(0,0,w,h,2)
 draw.SimpleText('Time to Rock The Vote','ZB_InterfaceMediumLarge',w/2,25,color_white,TEXT_ALIGN_CENTER)
end

vgui.Register('ZB_RTVMenu',PANEL,'ZFrame')
