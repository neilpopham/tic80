bullet_collection={
 create=function(self)
  local o=collection.create(self)
  o.reset(self)
  return o
 end,
 add=function(self,object)
  if object.type.player then
   self.player=self.player+1
  else
   self.enemy=self.enemy+1
  end
  collection.add(self,object)
 end,
 del=function(self,object)
  if object.type.player then
   self.player=self.player-1
  else
   self.enemy=self.enemy-1
  end
  collection.del(self,object)
 end,
 reset=function(self)
  collection.reset(self)
  self.player=0
  self.enemy=0
 end
} setmetatable(bullet_collection,{__index=collection})

bullet_update_linear=function(self,face)
 self.x=self.x+(face==dir.left and -self.ax or self.ax)
 self:check_visibility()
end

bullet_update_arc=function(self,face)
 if self.t==0 then
  self.x=self.x+(face==dir.left and 4 or -4)
  self.y=self.y-self.type.h/2
  self.angle=face==dir.left and 0.7 or 0.8
  self.angle=self.angle+flr(p.dx)*0.05
  self.force=6
  self.g=0.5
  self.b=0.7
 end
 local md=6
 affector.gravity(self)
 local move=self:can_move_x()
 if not move.ok then
  self.force=self.force*self.b
  self.angle=(0.5-self.angle)%1
 end
 move=self:can_move_y()
 if not move.ok then
  self.force=self.force*self.b
  self.angle=(1-self.angle)%1
 end
 self.dx=cos(self.angle)*self.force
 self.dy=-sin(self.angle)*self.force
 self.dx=mid(-md,self.dx,md)
 self.dy=mid(-md,self.dy,md)
 self.x=self.x+self.dx
 self.y=self.y+self.dy
 if self.t>60 then
  self:destroy()
 end
 self:check_visibility()
end

bullet_types={
 {
  sprite=32,
  ax=3,
  w=2,
  h=2,
  player=true,
  health=100,
  update=bullet_update_linear
 },
 {
  sprite=33,
  ax=3,
  w=2,
  h=2,
  player=false,
  health=100,
  update=bullet_update_linear
 },
 {
  sprite=34,
  ax=3,
  w=4,
  h=4,
  player=false,
  health=200,
  update=bullet_update_linear,
  range=15,
  shake=3
 },
 {
  sprite=35,
  w=5,
  h=5,
  player=true,
  health=200,
  update=bullet_update_arc,
  range=20,
  shake=3
 }
}

bullet={
 create=function(self,x,y,face,type)
  local ttype=bullet_types[type]
  local o=movable.create(
   self,
   x-(face==dir.left and ttype.w or 0),
   flr(y-ttype.h/2),
   ttype.ax,
   ttype.ay,
   ttype.dx,
   ttype.dy
  )
  o.type=ttype
  o.dir=face
  o.t=0
  o:add_hitbox(ttype.w,ttype.h)
  bullets:add(o)
 end,
 check_visibility=function(self)
  local cx=p.camera:position()
  if self.x<(cx-self.type.w-8) or self.x>(cx+screen.width+8) then
    self.complete=true
  end
 end,
 destroy=function(self)
  self.complete=true
  local angle=self.dir==dir.left and {0.75,1.25} or {0.25,0.75}
  smoke:create(
   self.x+self.type.w/2,
   self.y+self.type.h/2,
   5,
   {col=12,angle=angle,force={2,3},size={1,3}}
  )
  if self.type.range then
   doublesmoke(
    self.x,
    self.y,
    {20,10,10},
    {
     {col=8,size={8,12}},
     {col=7,size={8,12}},
     {col=8,life={20,40}}
    }
   )
   sfx(3)
   p.camera:shake(self.type.shake)
   self:collateral(self.type.range,self.type.health)
  end
 end,
 update=function(self)
  if self.complete then return end
  self.type.update(self,self.dir)
  if not self.complete then
   if self.type.player then
    for _,e in pairs(enemies.items) do
     if e.visible and self:collide_object(e) then
      self:destroy()
      e:damage(self.type.health)
      break
     end
    end
   elseif self:collide_object(p) then
    self:destroy()
    p:damage(self.type.health)
   end
   if self.complete then return end
   local move=self:collide_destructable()
   if not move.ok then
    self:destroy()
    move.d:damage(self.type.health)
   end
  end
  self.t=self.t+1
 end,
 draw=function(self)
  spr(self.type.sprite,self.x,self.y)
 end
} setmetatable(bullet,{__index=movable})
