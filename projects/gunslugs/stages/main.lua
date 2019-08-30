stage_main={
 t=0,
 init=function(self)
  level=0
  self:next(true)
 end,
 next=function(self,full)
  level=level+1
  enemies:reset()
  bullets:reset()
  destructables:reset()
  pickups:reset()
  particles:reset()
  p:reset(full)
  fillmap(level)
  self.draw=self.draw_intro
  self.transition=minsky_out:create(p.camera:screenx(),p.y)
  self.t=0
 end,
 complete=function(self)
  self.draw=self.draw_outro
 end,
 update=function(self)
  p:update()
  p.camera:update()
  bullets:update()
  set_visible({destructables,enemies,pickups})
  enemies:update()
  destructables:update()
  pickups:update()
  particles:update()
 end,
 draw_intro=function(self)
  self:draw_core()
  if self.transition then
   if self.transition:draw() then
    self.transition=nil
    self.draw=self.draw_core
   end
  end
 end,
 draw_outro=function(self)
  if self.transition then
   self:draw_core()
   if self.transition:draw() then
    self.transition=nil
    self:next()
   end
  else
   self.transition=minsky_out:create(p.camera:screenx(),p.y)
  end
 end,
 draw_core=function(self)
  p.camera:map()
  enemies:draw()
  pal()
  bullets:draw()
  destructables:draw()
  pickups:draw()
  particles:draw()
  p:draw()
  self:draw_hud()
 end,
 draw_hud=function(self)
  camera(0,0)
  print("level",1,1,6)
  print(lpad(level),32,1,9)
  --spr(62,48,1)
  --spr(63,56,1)
  spr(p.weapon.sprite,116,1,0)
  -- health
  for i=1,p.max.health/100 do
   spr(p.health>=i*100 and 47 or 46,199+(8*(i-1)),0,0)
  end
 end
}
