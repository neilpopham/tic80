counter={
 create=function(self,min,max)
  local o={tick=0,min=min,max=max}
  setmetatable(o,self)
  self.__index=self
  return o
 end,
 increment=function(self)
  self.tick=self.tick+1
  if self.tick>self.max then
   self:reset()
   if type(self.on_max)=="function" then
    self:on_max()
   end
  end
 end,
 reset=function(self,value)
  value=value or 0
  self.tick=value
 end,
 valid=function(self)
  return self.tick>=self.min and self.tick<=self.max
 end
}

collection={
 create=function(self)
  local o={
   items={},
   count=0,
  }
  setmetatable(o,self)
  self.__index=self
  return o
 end,
 update=function(self)
  if self.count==0 then return end
  for _,i in pairs(self.items) do
   i:update()
   if i.complete then self:del(i) end
  end
 end,
 draw=function(self)
  if self.count==0 then return end
  for _,i in pairs(self.items) do
   i:draw()
  end
 end,
 add=function(self,object)
  add(self.items,object)
  self.count=self.count+1
 end,
 del=function(self,object)
  del(self.items,object)
  self.count=self.count-1
 end,
 reset=function(self)
  self.items={}
  self.count=0
 end
}

object={
 create=function(self,x,y)
  local o=setmetatable(
   {
    x=x,
    y=y,
    hitbox={x=0,y=0,w=8,h=8,x2=7,y2=7},
    complete=false,
    health=0
   },
   self
  )
  self.__index=self
  return o
 end,
 add_hitbox=function(self,w,h,x,y)
  x=x or 0
  y=y or 0
  self.hitbox={x=x,y=y,w=w,h=h,x2=x+w-1,y2=y+h-1}
 end,
 distance=function(self,target)
  local dx=(target.x+4)/1000-(self.x+4)/1000
  local dy=(target.y+4)/1000-(self.y+4)/1000
  return sqrt(dx^2+dy^2)*1000
 end,
 collide_object=function(self,object,x,y)
  if self.complete or object.complete then return false end
  local x=x or self.x
  local y=y or self.y
  local hitbox=self.hitbox
  return (x+hitbox.x<=object.x+object.hitbox.x2) and
   (object.x+object.hitbox.x<x+hitbox.w) and
   (y+hitbox.y<=object.y+object.hitbox.y2) and
   (object.y+object.hitbox.y<y+hitbox.h)
 end,
 damage=function(self,health)
  self.health=self.health-health
  if self.health>0 then
   self:hit(health)
  else
   self:destroy(health)
  end
 end,
 hit=function(self,health)
 end,
 destroy=function(self,health)
  self.complete=true
 end,
 collateral=function(self,range,health)
  if range==0 then return end
  local foo={}
  for _,d in pairs(destructables.items) do
   if d.visible and d~=self then
    add(foo,d)
   end
  end
  for _,e in pairs(enemies.items) do
   if e.visible and e~=self then
    add(foo,e)
   end
  end
  add(foo,p)
  for _,o in pairs(foo) do
   distance=self:distance(o)
   if distance<range then
    o:foobar(range/distance,health,o.x<self.x and -1 or 1)
   end
  end
 end,
 foobar=function(self,strength,health,dir)
  self:damage(health)
  if not self.complete then
   local dx=6*strength
   self.dx=self.dx+dx*dir
   self.dy=-dx
   self.max.dy=6
  end
 end,
 draw=function(self,sprite)
  if not self.complete then
   spr(sprite,self.x,self.y)
  end
 end
}

movable={
 create=function(self,x,y,ax,ay,dx,dy)
  local o=object.create(self,x,y)
  o=extend(
   o,
   {
    ax=ax,
    ay=ay,
    dx=0,
    dy=0,
    ox=0,
    sx=x,
    sy=y,
    min={dx=0.05,dy=0.05},
    max={dx=dx,dy=dy}
   }
  )
  return o
 end,
 can_move=function(self,points,flag)
  for _,p in pairs(points) do
   local tx,ty=flr(p[1]/8),flr(p[2]/8)
   local tile=mget(tx,ty)
   if flag and fget(tile,flag) then
    return {ok=false,flag=flag,tile=tile,tx=tx*8,ty=ty*8}
   elseif fget(tile,0) then
    return {ok=false,flag=0,tile=tile,tx=tx*8,ty=ty*8}
   end
  end
  return {ok=true}
 end,
 can_move_x=function(self)
  local x=self.x+round(self.dx)
  if self.dx>0 then x=x+self.hitbox.x2 end
  return self:can_move({{x,self.y},{x,self.y+self.hitbox.y2}},1)
 end,
 can_move_y=function(self,flag)
  local y=self.y+round(self.dy)
  if self.dy>0 then y=y+self.hitbox.y2 end
  return self:can_move({{self.x,y},{self.x+self.hitbox.x2,y}},flag)
 end,
 collide_destructable=function(self,x,y)
  for _,d in pairs(destructables.items) do
   if d.visible and self~=d and self:collide_object(d,x,y) then
    return {ok=false,ty=d.y,tx=d.x,d=d}
   end
  end
  return {ok=true}
 end
} setmetatable(movable,{__index=object})

animatable={
 create=function(self,...)
  local o=movable.create(self,...)
  o.anim={
   init=function(self,stage,dir)
    for s in pairs(self.stage) do
     for d=1,#self.stage[s].dir do
      self.stage[s].dir[d].fcount=#self.stage[s].dir[d].frames
     end
    end
    self.current:set(stage,dir)
   end,
   stage={},
   current={
    reset=function(self)
     self.frame=1
     self.tick=0
     self.loop=true
     self.transitioning=false
    end,
    set=function(self,stage,dir)
     if self.stage==stage then return end
     self.reset(self)
     self.stage=stage
     self.dir=dir or self.dir
    end
   },
   add_stage=function(self,name,ticks,loop,left,right,next)
    self.stage[name]={
     ticks=ticks,
     loop=loop,
     dir={{frames=left},{frames=right}},
     next=next
    }
   end
  }
  return o
 end,
 animate=function(self)
  local c=self.anim.current
  local s=self.anim.stage[c.stage]
  local d=s.dir[c.dir]
  if c.loop then
   c.tick=c.tick+1
   if c.tick==s.ticks then
    c.tick=0
    c.frame=c.frame+1
    if c.frame>d.fcount then
     if s.next then
      c:set(s.next)
      d=self.anim.stage[c.stage].dir[c.dir]
     elseif s.loop then
      c.frame=1
     else
      c.frame=d.fcount
      c.loop=false
     end
    end
   end
  end
  return s.dir[c.dir].frames[c.frame]
 end,
 draw=function(self)
  object.draw(self,self.animate(self))
 end
} setmetatable(animatable,{__index=movable})
