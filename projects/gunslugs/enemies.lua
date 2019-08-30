enemy_shoot_dumb=function(self)
 local face=self.anim.current.dir
 bullet:create(
  self.x+(face==dir.left and 0 or 8),self.y+5,face,self.type.bullet_type
 )
 shells:create(self.x+(face==dir.left and 2 or 4),self.y+3,1,{col=3})
 sfx(4)
end

enemy_has_shot_dumb=function(self,target)
 return true
end

enemy_has_shot_cautious=function(self,target)
 if p.complete then return false end
 if target.y~=self.y then return false end
 local tx,ty=flr(self.x/8),flr(self.y/8)
 local px=flr(target.x/8)
 local step=target.x>self.x and 1 or -1
 for x=tx,px,step do
  if zget(x,ty) then return false end
 end
 return true
end

enemy_add_stages=function(o,stage,count,loop,left,right,next)
 o.anim:add_stage(stage,count,loop,left,right,next)
end

enemy_stages_goon=function(o)
 enemy_add_stages(o,"still",1,false,{48},{51})
 enemy_add_stages(o,"run",5,true,{48,49,48,50},{51,52,51,53})
 enemy_add_stages(o,"jump",1,false,{50},{53})
 enemy_add_stages(o,"fall",1,false,{49},{52})
 enemy_add_stages(o,"run_turn",3,false,{54},{54},"still")
 enemy_add_stages(o,"jump_turn",3,false,{54},{54},"jump")
 enemy_add_stages(o,"fall_turn",3,false,{54},{54},"fall")
 enemy_add_stages(o,"jump_fall",3,false,{54},{54},"fall")
end

enemy_stages_spider=function(o)
 enemy_add_stages(o,"still",1,false,{55},{56})
 enemy_add_stages(o,"run",5,true,{55,57},{56,58})
end

local goons={
 {itchy=0.5,b=60,dx=1},
 {itchy=0.5,b=60,dx=1,has_shot=enemy_has_shot_cautious},
 {itchy=0.5,b=60,dx=1,jumps=true},
 {itchy=0.5,b=60,dx=1,jumps=true,has_shot=enemy_has_shot_cautious},
 {itchy=0.5,b=60,dx=1,col=9,has_shot=enemy_has_shot_cautious,bullet_type=3},
 {itchy=0.7,b=60,dx=1,col=9,jumps=true,has_shot=enemy_has_shot_cautious,bullet_type=3},
 {itchy=0.5,b=60,dx=2,jumps=true,has_shot=enemy_has_shot_cautious,bullet_type=2},
}

enemy_types={
 {
  health=100,
  col=6,
  size={8,12},
  b=60,
  itchy=0.3,
  bullet_type=2,
  dx=1,
  jumps=false,
  has_shot=enemy_has_shot_dumb,
  shoot=enemy_shoot_dumb,
  add_stages=enemy_stages_goon
 }
}

for _,e in pairs(goons) do
  local o=extend(clone(enemy_types[1]),e)
  add(enemy_types,o)
end

add(
 enemy_types, -- spider
 {
  health=50,
  col=1,
  size={8,12},
  b=60,
  itchy=0,
  dx=2,
  jumps=true,
  add_stages=enemy_stages_spider
 }
)

enemy={
 create=function(self,x,y,type)
  local ttype=enemy_types[type]
  local o=animatable.create(self,x,y,0.15,-2,ttype.dx,3)
  ttype.add_stages(o)
  o.anim:init("run",dir.left)
  o.type=ttype
  o.health=ttype.health
  o.b=0
  o.p=0
  o.button=counter:create(1,13)
  return o
 end,
 hit=function(self)
  smoke:create(self.x+4,self.y+4,10,{col=7,size=self.type.size})
  shells:create(self.x+4,self.y+4,5,{col=8,life={20,40}})
 end,
 destroy=function(self)
  self.complete=true
  self.visible=false
  doublesmoke(
   (flr(self.x/8)*8)+4,
   (flr(self.y/8)*8)+4,
   {20,10,10},
   {
    {col=self.type.col,size=self.type.size},
    {col=7,size=self.type.size},
    {col=8,life={20,40}}
   }
  )
 end,
 update=function(self)
  if not self.visible then return end
  if not p.complete then
   if p.x<self.x then
     self.anim.current.dir=dir.left
     self.dx=self.dx-self.ax
   else
     self.anim.current.dir=dir.right
     self.dx=self.dx+self.ax
   end
  end
  self.dx=mid(-self.max.dx,self.dx,self.max.dx)
  move=self:can_move_x()
  if move.ok then
   move=self:collide_destructable(self.x+round(self.dx),self.y)
  end
  if move.ok then
   self.x=self.x+round(self.dx)
  else
   if self.type.jumps then
    if self.dy==0 then self.button:increment() end
    if self.button:valid() then
     self.dy=self.dy+self.ay
     self.max.dy=3
     self.button:increment()
    end
   else
    self.dx=0
   end
  end
  self.dy=self.dy+drag.gravity
  move=self:can_move_y()
  if move.ok then
   --if self.dy>0 then self.max.dy=3 end
   move=self:collide_destructable(self.x,self.y+round(self.dy))
  end
  self.dy=mid(-self.max.dy,self.dy,self.max.dy)
  if move.ok then
   self.y=self.y+round(self.dy)
  else
   self.y=move.ty+(self.dy>0 and -8 or 8)
   self.dy=0
   self.button:reset()
  end
  self.anim.current:set(round(self.dx)==0 and "still" or "run")
  if self.p>0 then
   self.p=max(0,self.p-1)
  elseif self:collide_object(p) then
   printh(p.f)
   if p.f>10 then
    self:damage(p.f*5)
   else
    p:foobar(1,20,sgn(self.dx))
    sfx(2)
    self.p=30
   end
  end
  if self.b>0 then
   self.b=self.b-1
  else
   local r=rnd()
   if r<self.type.itchy and self.type.has_shot(self,p) then
    self.type.shoot(self)
   end
   self.b=self.type.b
  end
 end,
 draw=function(self)
  if not self.visible then return end
  pal(15,self.type.col)
  animatable.draw(self)
 end
} setmetatable(enemy,{__index=animatable})
