p=animatable:create(8,112,0.15,-2,2,3)
local add_stage=function(...) p.anim:add_stage(...) end
add_stage("still",1,false,{16},{19})
add_stage("run",5,true,{16,17,16,18},{19,20,19,21})
add_stage("jump",1,false,{18},{21})
add_stage("fall",1,false,{17},{20})
add_stage("run_turn",3,false,{22},{22},"still")
add_stage("jump_turn",3,false,{22},{22},"jump")
add_stage("fall_turn",3,false,{22},{22},"fall")
add_stage("jump_fall",3,false,{22},{22},"fall")
p.anim:init("still",dir.right)
p.reset=function(self,full)
 self.anim.current.dir=dir.right
 self.max.prejump=8
 self.max.health=500
 self.is={
  grounded=false,
  jumping=false,
  falling=false
 }
 self.complete=false
 self.visible=true
 self.f=0
 self.x=8
 self.y=112
 self.dx=0
 self.dy=0
 self.camera=cam:create(p,1024,128)
 if full then
  self.weapon=weapon_types[1]
  self.health=self.max.health
 end
 self.shoot=30
 self.grenade=30
 p.btn1.released=false
end
p.btn1=button:create(pad.btn1)
p:reset(true)
p.cayote=counter:create(1,3)
p.add_health=function(self,health)
 self.health=min(self.health+health,self.max.health)
end
p.set_state=function(self,state)
 for s in pairs(self.is) do
  self.is[s]=false
 end
 self.is[state]=true
end
p.can_jump=function(self)
 if self.is.jumping
  and self.btn1:valid() then
  return true
 end
 if self.is.grounded
  and self.btn1.tick<self.max.prejump then
  self.btn1.tick=self.btn1.min
  return true
 end
 if self.is.grounded
  and self.cayote:valid() then
  return true
 end
 return false
end
p.can_move_x=function(self)
 local x=self.x+round(self.dx)
 if x<0 then return {ok=false,tx=-8} end
 return movable.can_move_x(self)
end
p.hit=function(self,health)
 p.camera:shake(2)
 smoke:create(self.x+4,self.y+4,20,{col=12,size={12,20}})
 shells:create(self.x+4,self.y+4,5,{col=8,life={20,30}})
end
p.destroy=function(self,health)
 self.complete=true
 p.camera:shake(3)
 doublesmoke(
  self.x+4,
  self.y+4,
  {20,10,10},
  {{col=12,size={12,30}},{col=7,size={12,30}},{col=8,life={40,80}}}
 )
 stage=stage_over
 stage:init()
end
p.update=function(self)
  if self.complete then return end
  local face=self.anim.current.dir
  local stage=self.anim.current.stage
  local move
  local check=function(self,stage,face)
   if face~=self.anim.current.dir then
    if stage=="still" then stage="run" end
    if stage=="jump_fall" then stage="fall" end
    if not self.anim.current.transitioning then
     self.anim.current:set(stage.."_turn")
     self.anim.current.transitioning=true
    end
   end
  end
  -- horizontal
  if btn(pad.left) then
   self.anim.current.dir=dir.left
   check(self,stage,face)
   self.dx=sself.dx-elf.ax
  elseif btn(pad.right) then
   self.anim.current.dir=dir.right
   check(self,stage,face)
   self.dx=self.dx+self.ax
  else
   if self.is.jumping or self.is.falling then
    self.dx=self.dx*drag.air
   else
    self.dx=self.dx*drag.ground
   end
  end
  self.dx=mid(-self.max.dx,self.dx,self.max.dx)
  move=self:can_move_x()
  if move.ok then
   move=self:collide_destructable(self.x+round(self.dx),self.y)
  end

  -- can move horizontally
  if move.ok then
   self.x=self.x+round(self.dx)
   local adx=abs(self.dx)
   if adx<0.05 then self.dx=0 end
   if adx>0.5 and self.is.grounded then
    smoke:create(self.x+(face==dir.left and 3 or 4),self.y+7,1,{size={1,3}})
   end
   if self.x>1023 and self.visible then
    self:add_health(250)
    --sfx(5)
    stage_main:complete()
    self.visible=false
   end

  -- cannot move horizontally
  else
   self.x=move.tx+(self.dx>0 and -8 or 8)
   self.dx=0
  end

  -- jump
  if self.btn1:pressed() and self:can_jump() then
   self.dy=self.dy+self.ay
   self.max.dy=3
  else
   if self.is.jumping then
    self.btn1.disabled=true
   else
    self.btn1.disabled=false
   end
  end
  self.dy=self.dy+drag.gravity
  self.dy=mid(-self.max.dy,self.dy,self.max.dy)
  move=self:can_move_y()
  if move.ok then
   move=self:collide_destructable(self.x,self.y+round(self.dy))
  end

  -- can move vertically
  if move.ok then
   -- moving down the screen
   if self.dy>0 then
    if self.is.grounded then
     self.cayote:increment()
     if self.cayote:valid() then
      self.dy=0
     else
      self.anim.current:set("fall")
      self:set_state("falling")
     end
    else
     if not self.anim.current.transitioning then
      self.anim.current:set(self.is.jumping and "jump_fall" or "fall")
     end
     self:set_state("falling")
    end
    self.f=self.f+1
   -- moving up the screen
   else
    if not self.is.jumping then
     self.anim.current:set("jump")
     smoke:create(self.x+(face==dir.left and 3 or 4),self.y+7,20,{col=7,size={4,8}})
    end
    self:set_state("jumping")
   end
   self.y=self.y+round(self.dy)

  -- cannot move vertically
  else
   self.y=move.ty+(self.dy>0 and -8 or 8)
   if self.dy>0 then
    if not self.anim.current.transitioning then
     self.anim.current:set(round(self.dx)==0 and "still" or "run")
    end
    -- falling
    if self.is.falling then
     smoke:create(
      self.x+(face==dir.left and 3 or 4),
      self.y+7,
      2*self.f,
      {col=self.f>10 and 10 or 7,size={self.f/3,self.f}}
     )
     if self.f>10 then
      p.camera:shake(self.f/16)
      self.dy=min(-3,-(round(self.f/6)))
      self.max.dy=6
      sfx(2)
     end
    end
    self:set_state("grounded")
    self.cayote:reset()
   -- hit a roof
   else
    self.btn1:reset()
    self.dy=0
    self.anim.current:set("jump_fall")
    self:set_state("falling")
   end
   self.f=0
  end

  -- fire
  if btn(pad.btn2) and self.shoot==0 then
   bullet:create(
    self.x+(face==dir.left and 0 or 8),
    self.y+5,
    face,
    self.weapon.bullet_type
   )
   shells:create(
    self.x+(face==dir.left and 2 or 4),
    self.y+4,
    1,
    {col=9}
   )
   self.shoot=self.weapon.rate
   sfx(self.weapon.sfx)
  end
  if self.shoot>0 then self.shoot=self.shoot-1 end

  -- grenade
  if btn(pad.down) and self.grenade==0 then
   bullet:create(
    self.x+(face==dir.left and 0 or 8),
    self.y+8,
    face,
    4
   )
   self.grenade=60
  end
  if self.grenade>0 then self.grenade=self.grenade-1 end

end
