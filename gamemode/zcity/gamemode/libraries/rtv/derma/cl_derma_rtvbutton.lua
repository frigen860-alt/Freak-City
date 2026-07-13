local PANEL={}
BlurBackground=BlurBackground or hg.DrawBlur
local orange=Color(230,115,35)

function PANEL:Init()
 self.Map=''
 self.Votes=0
 self.lerp=0
 self.alpha=0
 self:SetFont('ZB_ScrappersMedium')
 self:SetPaintBackground(false)
 self:SetTextColor(color_white)
end

function PANEL:Paint(w,h)
 if self.MapIcon then
  surface.SetDrawColor(255,255,255)
  surface.SetMaterial(self.MapIcon)
  surface.DrawTexturedRect(0,0,w,h)
 end
 if BlurBackground then BlurBackground(self) end
 draw.RoundedBox(10,0,0,w,h,Color(10,5,2,150))
 surface.SetDrawColor(orange)
 surface.DrawOutlinedRect(0,0,w,h,2)
 self.lerp=Lerp(FrameTime()*5,self.lerp,w*(self.Votes/math.max(player.GetCount(),1)))
 draw.RoundedBox(8,0,h-5,self.lerp,5,orange)
 draw.RoundedBox(6,w-115,h-32,105,24,Color(70,30,5,220))
 draw.SimpleText('VOTE THIS MAP','DermaDefaultBold',w-62,h-20,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
 if self.alpha>0 then draw.RoundedBox(10,0,0,w,h,Color(230,115,35,self.alpha)) end
end
function PANEL:OnCursorEntered() self.alpha=90 end
function PANEL:OnCursorExited() self.alpha=0 end
vgui.Register('ZB_RTVButton',PANEL,'DButton')
