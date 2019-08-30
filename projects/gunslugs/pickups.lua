pickup={
 destroy=function(self)
  self.visible=false
  self.complete=true
  sfx(5)
 end,
 update=function(self)
  if not self.visible then return end
 end,
 draw=function(self)
  if not self.visible then return end
  animatable.draw(self)
 end
} setmetatable(pickup,{__index=animatable})

medikit={
 create=function(self,x,y)
  local o=animatable.create(self,x,y,0,0,0,0)
  o.anim:add_stage("still",4,true,{26,27,28,29,30,31},{})
  o.anim:init("still",dir.left)
  return o
 end,
 update=function(self)
  if not self.visible then return end
  if self:collide_object(p) then
   p:add_health(250)
   smoke:create(self.x+4,self.y+4,10,{col=8,size={8,16}})
   self:destroy()
  end
 end
} setmetatable(medikit,{__index=pickup})
