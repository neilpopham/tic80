stage_over={
 t=0,
 init=function(self)
  self.t=0
  self.step=1
 end,
 update=function(self)
  if self.step==3 then
   if btn(pad.btn1) then
    stage=stage_main
    stage:init()
   elseif btn(pad.btn2) or self.t>1800 then
    enemies:reset()
    bullets:reset()
    destructables:reset()
    pickups:reset()
    particles:reset()
    p:reset(true)
    stage=stage_intro
    stage:init()
   end
  else
   stage_main.update(self)
  end
  self.t=self.t+1
 end,
 draw=function(self)
  if self.step==3 then
   stage_main:draw_hud()
   print("game over",94,48,9)
   print("press z to restart",68,60,13)
   print("or x to return to the menu",44,70,13)
  else
   stage_main:draw()
  end
  if self.t>100 then
   if self.step==1 then
    self.step=2
    self.transition=minsky_out:create(p.camera:screenx(),p.y)
   elseif self.transition then
    if self.transition:draw() then
     if self.step==2 then
      self.step=3
      self.transition=minsky_in:create(p.camera:screenx(),p.y)
     else
      self.transition=nil
     end
    end
   end
  end
 end
}
