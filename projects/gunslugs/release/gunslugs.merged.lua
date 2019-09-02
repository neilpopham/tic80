-- title:  runjumpdie
-- author: Neil Popham
-- desc:
-- script: lua
-- input:  gamepad
-- saveid:

pad={left=2,right=3,up=0,down=1,btn1=4,btn2=5,btn3=6,btn4=7}
screen={width=240,height=136,x2=239,y2=135}
dir={left=1,right=2}
drag={air=0.95,ground=0.65,gravity=0.7}

-- carts/projects/gunslugs/pico8

add=table.insert
sqrt=math.sqrt
abs=math.abs
min=math.min
max=math.max
flr=math.floor
ceil=math.ceil
function sub(str,i,j) return str:sub(i,j) end
function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end
function rnd(a) a=a or 1 return math.random()*a end
function cos(x) return math.cos((x or 0)*(math.pi*2)) end
function sin(x) return math.sin(-(x or 0)*(math.pi*2)) end
function atan2(x,y) return (0.75 + math.atan2(x,y) / (math.pi * 2)) % 1.0 end
function sgn(a) if a>=0 then return 1 end return -1 end
function sget(x,y)
 x,y=flr(x),flr(y)
 local addr=0x8000+64*(flr(x/8)+flr(y/8)*16)
  return peek4(addr+(y%8)*8+x%8)
end
function del(t,a)
 for i,v in ipairs(t) do
  if v==a then
   local r=v
   t[i]=t[#t]
   t[#t]=nil
   return r
  end
 end
end
function pal(c0,c1,type)
 c0=c0 or -1
 c1=c1 or -1
 type=type or 0
 if c0<0 and c1<0 then
  if type==0 then
   for i=0,15 do
    poke4(0x7FE0+i,i)
   end
  end
 else
  c0=flr(c0%16)
  if c1<0 then
   c1=c0
  end
  c1=flr(c1%16)
  if type==0 then
   poke4(0x7FE0+c0,c1)
  else
   local stri
   for i=0,5 do
    stri=#__p8_pal-(c1+1)*6+i
    poke4(0x3FC0*2+#__p8_pal-(c0+1)*6+i,tonumber(__p8_pal:sub(stri,stri),16))
   end
  end
 end
end

-- __gff__ data
local sprf={0,3,1,1,1}

-- http://pico-8.wikia.com/wiki/Fget
function fget(s,i)
  if sprf[s+1]==nil then sprf[s+1]=0 end
  if i==nil then
    return math.floor(sprf[s+1])
  else
    local b=2^i
    return sprf[s+1] % (2*b) >= b
  end
end

-- http://pico-8.wikia.com/wiki/Fset
function fset(s,i,b)
  if b==nil then
    sprf[s+1]=i
  else
    local e
    if sprf[s+1]==nil then
      sprf[s+1]=0
      e=false
    else
      e=fget(s,i)
    end
    if (e and not b) or (not e and b) then
      sprf[s+1]=sprf[s+1]+(b and 2^i or -2^i)
    end
  end
end

--function sfx() end

-- carts/projects/gunslugs/functions

function mrnd(x,f)
 if f==nil then f=true end
 local v=(rnd()*(x[2]-x[1]+(f and 1 or 0.0001)))+x[1]
 return f and flr(v) or flr(v*1000)/1000
end

function round(x)
 return flr(x+0.5)
end

function extend(...)
 local arg={...}
 local o=del(arg,arg[1])
 for _,a in pairs(arg) do
  for k,v in pairs(a) do
   o[k]=v
  end
 end
 return o
end

function clone(o)
 local c={}
 for k,v in pairs(o) do
  c[k]=v
 end
 return c
end

function set_visible(items)
 local cx=p.camera:position()
 local cx2=cx+screen.width
 for _,collection in pairs(items) do
  for _,o in pairs(collection.items) do
   o.visible=(o.complete==false and o.x>=cx-32 and o.x<=cx2+32)
  end
 end
end

function zget(tx,ty)
 local tile=mget(tx,ty)
 if fget(tx,ty,0) then return true end
 for _,d in pairs(destructables.items) do
  if d.visible then
   local dx,dy=flr(d.x/8),flr(d.y/8)
   if dx==tx and dy==ty then return true end
  end
 end
 return false
end

function oprint(text,x,y,col)
 for dx=-1,1 do
  for dy=-1,1 do
   print(text,x+dx,y+dy,0)
  end
 end
 print(text,x,y,col)
end

function lpad(x,n)
 n=n or 2
 return sub("0000000"..x,-n)
end

-- carts/projects/gunslugs/particles

particle={
 create=function(self,params)
  params=params or {}
  params.life=params.life or {60,120}
  params.angle=mrnd(params.angle,false)
  params.force=mrnd(params.force,false)
  local o=params
  o=extend(o,{x=params.x,y=params.y,life=mrnd(params.life),complete=false})
  setmetatable(o,self)
  self.__index=self
  return o
 end,
 draw=function(self,fn)
  self:_draw()
  self.life=self.life-1
  if self.life==0 then self.complete=true end
 end
}

spark={
 _draw=function(self)
  pset(self.x,round(self.y),self.col)
 end
} setmetatable(spark,{__index=particle})

circle={
 _draw=function(self)
  circfill(self.x,self.y,self.size,self.col)
 end
} setmetatable(circle,{__index=particle})

affector={

 gravity=function(self)
  local dx=cos(self.angle)*self.force
  local dy=-sin(self.angle)*self.force
  dy=dy+self.g
  self.angle=atan2(dx,-dy)
  self.force=sqrt(dx^2+dy^2)
  self.dx=cos(self.angle)*self.force
  self.dy=-sin(self.angle)*self.force
 end,

 bounce=function(self)
  local x,y=self.x+self.dx,self.y
  local tile=mget(flr(x/8),flr(y/8))
  if fget(tile,0) then
   self.force=self.force*self.b
   self.angle=(0.5-self.angle)%1
  end
  x,y=self.x,self.y+self.dy
  tile=mget(flr(x/8),flr(y/8))
  if fget(tile,0) then
   self.force=self.force*self.b
   self.angle=(1-self.angle)%1
  end
  self.dx=cos(self.angle)*self.force
  self.dy=-sin(self.angle)*self.force
 end,

 size=function(self)
  self.size=self.size*self.shrink
  if self.size<0.5 then self.complete=true end
 end,

 shells=function(self)
  affector.gravity(self)
  affector.bounce(self)
  affector.update(self)
 end,

 smoke=function(self)
  self.dx=cos(self.angle)*self.force
  self.dy=-sin(self.angle)*self.force
  affector.size(self)
  affector.update(self)
 end,

 update=function(self)
  self.x=self.x+self.dx
  self.y=self.y+self.dy
 end
}

shells={
 create=function(self,x,y,count,params)
  for i=1,count do
   local s=spark:create(
    extend(
     {
      x=x,
      y=y,
      life={30,50},
      force={1,2},
      g=0.2,
      b=0.7,
      angle={0.6,0.9}
     },
     params
    )
   )
   s.update=affector.shells
   particles:add(s)
  end
 end
}

smoke={
 create=function(self,x,y,count,params)
  for i=1,count do
   local s=circle:create(
    extend(
     {
      x=x,
      y=y,
      delay=0,
      col=7,
      life={10,20},
      force={0.3,1.2},
      angle={0,1},
      size={4,6},
      shrink=0.8
     },
     params
    )
   )
   if params.size then s.size=mrnd(params.size) end
   s.update=affector.smoke
   particles:add(s)
  end
 end
}

function doublesmoke(x,y,count,params)
 smoke:create(x,y,count[1],params[1])
 smoke:create(x+rnd(3),y-rnd(3),count[2],params[2])
 shells:create(x,y,count[3],params[3])
end

-- carts/projects/gunslugs/camera

camera_x,camera_y=0,0
camera=function(x,y)
 camera_x,camera_y=x,y
end

cam={
 create=function(self,item,width,height)
  local o={
   target=item,
   x=item.x,
   y=0,
   buffer=12,
   min=96,
   force=0,
   sx=0,
   sy=0,
   tiles={width=flr(screen.width/8),height=flr(screen.height/8)},
   cell={},
   offset={}
  }
  o.max=width-screen.width+o.min
  setmetatable(o,self)
  self.__index=self
  return o
 end,
 update=function(self)
  local min_x = self.x-self.buffer
  local max_x = self.x+self.buffer
  if min_x>self.target.x then
   self.x = self.x + (min(self.target.x-min_x,2))
  end
  if max_x<self.target.x then
   self.x = self.x + (min(self.target.x-max_x,2))
  end
  if self.x<self.min then
   self.x=self.min
  elseif self.x>self.max then
   self.x=self.max
  end
  if self.force>0 then
   self.sx=2-rnd(4)
   self.sy=2-rnd(4)
   self.sx = self.sx * (self.force)
   self.sy = self.sy * (self.force)
   self.force = self.force * 0.9
   if self.force<0.1 then
    self.force,self.sx,self.sy=0,0,0
   end
  end
 end,
 screenx=function(self)
  return self.target.x-max(0,self.x-self.min)
 end,
 position=function(self)
  return self.x-self.min
 end,
 map=function(self)
  local x=flr(self:position()+self.sx)
  local y=flr(self.sy)
  camera(x,y)
  self.cell.x=flr(x/8)
  self.cell.y=flr(y/8)
  self.offset.x=-(x%8)
  self.offset.y=-(y%8)
  map(
   self.cell.x,
   self.cell.y,
   self.tiles.width+1,
   self.tiles.height+1,
   self.offset.x,
   self.offset.y,
   0
  )
 end,
 shake=function(self,force)
  self.force=min(self.force+force,9)
 end
}

tic80spr=spr
function spr(sprite,x,y)
 tic80spr(sprite,x-camera_x,y-camera_y,0)
end
function pset(x,y,col)
 pix(x-camera_x,y-camera_y,col)
end
function circfill(x,y,r,col)
 circ(x-camera_x,y-camera_y,r,col)
end
function rectfill(x1,y1,x2,y2,col)
 rect(x1-camera_x,y1-camera_y,x2-x1+1,y2-y1+1,col)
end

-- carts/projects/gunslugs/objects

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

-- carts/projects/gunslugs/button

button={
 create=function(self,index)
  local o=counter.create(self,1,12)
  o.index=index
  o.released=true
  o.disabled=false
  return o
 end,
 check=function(self)
  if btn(self.index) then
   if self.disabled then return end
   if self.tick==0 and not self.released then return end
   self:increment()
   self.released=false
  else
   if not self.released then
    local tick=self.tick==0 and self.max or self.tick
    if type(self.on_release)=="function" then
     self:on_release(tick)
    end
    if tick>12 then
     if type(self.on_long)=="function" then
      self:on_long(tick)
     end
    else
     if type(self.on_short)=="function" then
      self:on_short(self.tick)
     end
    end
   end
   self:reset()
   self.released=true
  end
 end,
 pressed=function(self)
  self:check()
  return self:valid()
 end
} setmetatable(button,{__index=counter})

-- carts/projects/gunslugs/destructables

destructable_types={
 nil,
 {sprite=2,health=10,col=9,size={6,12}},
 {sprite=3,health=10,col=8,size={10,16},range=15,shake=2},
 {sprite=4,health=10,col=11,size={14,20},range=20,shake=3}
}

destructable={
 create=function(self,x,y,type)
  local ttype=destructable_types[type]
  local o=movable.create(self,x,y,0,0,0,3)
  o.type=ttype
  o.health=ttype.health
  o.t=0
  return o
 end,
 destroy=function(self,health)
  self.complete=true
  self.visible=false
  doublesmoke(
   (flr(self.x/8)*8)+4,
   (flr(self.y/8)*8)+4,
   {10,5,5},
   {
    {col=self.type.col,size=self.type.size},
    {col=7,size=self.type.size},
    {col=self.type.col,life={20,50}}
   }
  )
  if self.type.range then
   p.camera:shake(self.type.shake)
   self:collateral(self.type.range,abs(self.health))
   sfx(4)
  else
   sfx(2)
  end
 end,
 foobar=function(self,strength,health,dir)
  self.fb={strength,health,dir}
  local t=round(20/strength)
  if self.t>0 then
   self.t=min(self.t,t)
  else
   self.t=t
  end
 end,
 update=function(self)
  if not self.visible then return end
  if self.t>0 then
   self.t=self.t-1
   if self.t==0 then
    object.foobar(self,self.fb[1],self.fb[2],self.fb[3])
   end
  end
  self.dy=self.dy+0.25
  self.dy=mid(-self.max.dy,self.dy,self.max.dy)
  move=self:can_move_y()
  if move.ok then
   move=self:collide_destructable()
  end
  if move.ok then
   self.y=self.y+round(self.dy)
  else
   if self.dy>1 then
    particles:add(
     smoke:create(self.x+4,self.y+7,10,{size={4,8}})
    )
    sfx(2)
   end
   self.dy=0
  end
 end,
 draw=function(self)
  if not self.visible then return end
  spr(self.type.sprite,self.x,self.y)
 end
} setmetatable(destructable,{__index=movable})

-- carts/projects/gunslugs/weapons

weapon_types={
 -- pistol
 {
  bullet_type=1,
  rate=20,
  sfx=4,
  sprite=61
 },
 -- semi-auto
 {
  bullet_type=1,
  rate=10,
  sfx=4,
  sprite=61
 },
 --rocket launcher
 {
  bullet_type=3,
  rate=40,
  sfx=4,
  sprite=61
 }
}

-- carts/projects/gunslugs/enemies

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

-- carts/projects/gunslugs/player

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
   self.dx=self.dx-self.ax
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

-- carts/projects/gunslugs/bullets

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

-- carts/projects/gunslugs/pickups

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

-- carts/projects/gunslugs/levels

function fillmap(level)
 local data,levels,floors,pool,m,f={},{15,11,7},120
 -- init
 for x=0,127 do
  data[x]={}
  data[x][15]=1
 end
 -- place floors
 for x=0,127 do
  if x>7 and x<120 then
   if x%4==0 then
    if rnd()<0.5 then
     for i=x,x+3 do
      if not data[i] then data[i]={} end
      data[i][levels[2]]=1
     end
     floors=floors+4
    end
    if data[x-3][levels[2]]==1 then
     if rnd()<0.5 then
      for i=x,x+3 do
       if not data[i] then data[i]={} end
       data[i][levels[3]]=1
      end
      floors=floors+4
     end
    end
   end
  end
 end
 -- create destructables pool
 pool={}
 f=floors
 local green_barrels=4+2*level
 for i=1,green_barrels do
  add(pool,4)
 end
 local red_barrels=12+2*level
 for i=1,red_barrels do
  add(pool,3)
 end
 local count=#pool+1
 local total=70+level*2
 if count<total then
  for i=count,total do
   add(pool,2)
  end
 end
 -- place destructables
 for x=7,124 do
  local pcount=#pool
  local l1=2/3*pcount/f
  local l2=1/3*pcount/f
  for i,l in pairs(levels) do
   if data[x][l]==1 then
    local m=l1
    if data[x-1][l-1] then m=m*1.5 end
    if rnd()<m and #pool>0 then
     local d=del(pool,pool[mrnd{1,#pool}])
     data[x][l-1]=d
     if rnd()<l2 and #pool>0 then
      d=del(pool,pool[mrnd{1,#pool}])
      data[x][l-2]=d
     end
    end
    f=f-1
   end
  end
 end
 -- create enemies pool
 pool={}
 f=floors
 local total=6+level
 local best=min(level+1,8)
 local lower=flr((level+3)/4)
 for i=1,total do
   add(pool,mrnd({lower,best}))
 end
 for i=1,lower do
   if rnd()<0.5 then add(pool,9) end
 end
 local ecount=#pool
 -- place enemies
 local r=0
 repeat
  for x=124,32,-8 do
   for i,l in pairs(levels) do
    if ecount>0 and data[x] and data[x][l]==1 then
     local m=(ecount/(f/6))+r
     if rnd()<m then
      local p=l
      repeat p=p-1 until data[x][p]==nil
      data[x][p]=48
      ecount=ecount-1
      f=f-4
     end
    end
   end
  end
  r=r+0.3
 until ecount==0
 -- place medikits
 for x=120,32,-16 do
  for i,l in pairs(levels) do
   if data[x] and data[x][l]==1 then
    if rnd()<0.2 then
     data[x][l-3]=40
     break
    end
   end
  end
 end
 -- place bricks
 for x=0,127 do
  if x>0 then
   for y=2,9 do
    if not data[x][y] or (data[x][y]>=9 and data[x][y]<=13) then
     r=rnd()
     m=0.5/y
     if data[x][y-1] and data[x][y-1]>=9 and data[x][y-1]<=14 then m=0.8/y end
     if data[x-1][y] and data[x-1][y]>=9 and data[x-1][y]<=13 then m=1.4/y end
     if r<m then
      data[x][y]=13
      r=rnd()
      if r<0.2 then data[x][y]=mrnd({9,13}) end
      if not data[x-1][y] then data[x-1][y]=9 end
      if x<127 and not data[x+1] then
       data[x+1]={}
       if not data[x+1][y] then data[x+1][y]=10 end
      end
      if not data[x][y-1] then data[x][y-1]=11 end
      if not data[x][y+1] then data[x][y+1]=12 end
     end
    end
   end
  end
 end
 -- create map from data
 for x=0,127 do
  for y=0,15 do
   if not data[x][y] then data[x][y]=0 end
   if data[x][y]>=2 and data[x][y]<=4 then
    destructables:add(destructable:create(x*8,y*8,data[x][y]))
   elseif data[x][y]==48 then
    local type=del(pool,pool[mrnd{1,#pool}])
    enemies:add(enemy:create(x*8,y*8,type))
   elseif data[x][y]==40 then
    pickups:add(medikit:create(x*8,y*8))
   else
    mset(x,y,data[x][y])
   end
  end
 end
end

-- carts/projects/gunslugs/stages/transition

transition={
 create=function(self,x,y)
  local o=setmetatable(
   {
    x=x,
    y=y,
    t=0,
    complete=false
   },
   self
  )
  self.__index=self
  return o
 end
}

--[[
fade_in={
 create=function(self,x,y)
  return transition.create(self,x,y)
 end,
 draw=function(self)
  local f=flr(self.t/2)
  if f<6 then
   for y=8,127,8 do
    for x=0,127,8 do
     circfill(x+3,y+3,6-f,0)
    end
   end
  else
   self.complete=true
  end
  self.t=self.t+1
  return self.complete
 end
} setmetatable(fade_in,{__index=transition})

fade_out={
 create=function(self,x,y)
  return transition.create(self,x,y)
 end,
 draw=function(self)
  local f=flr(self.t/2)
  if f<6 then
   for y=8,127,8 do
    for x=0,127,8 do
     circfill(x+3,y+3,f,0)
    end
   end
  else
   self.complete=true
  end
  self.t=self.t+1
  return self.complete
 end
} setmetatable(fade_out,{__index=transition})

blinds_in={
 create=function(self,x,y)
  return transition.create(self,x,y)
 end,
 draw=function(self)
  rectfill(0,8,127,128-self.t*8,0)
  if self.t>14 then self.complete=true end
  self.t=self.t+1
  return self.complete
 end
} setmetatable(blinds_in,{__index=transition})

blinds_out={
 create=function(self,x,y)
  return transition.create(self,x,y)
 end,
 draw=function(self)
  rectfill(0,8,127,self.t*8,0)
  if self.t>14 then self.complete=true end
  self.t=self.t+1
  return self.complete
 end
} setmetatable(blinds_out,{__index=transition})

blinds_in={
 create=function(self,x,y)
  return transition.create(self,x,y)
 end,
 draw=function(self)
  for y=1,15 do
   rectfill(-8,y*8,mid(-1,127,(15+y-self.t)*8),(y+1)*8,0)
  end
  if self.t>30 then self.complete=true end
  self.t=self.t+1
  return self.complete
 end
} setmetatable(blinds_in,{__index=transition})
]]

squares_in={
 create=function(self,x,y)
  local o=transition.create(self,x,y)
  o.tx,o.ty=ceil(x/8),ceil(y/8)
  return o
 end,
 radius=function(self)
  return 20-self.t
 end,
 draw=function(self)
  local r=self:radius()
  local r2=r*r
  for y=-r,r do
   ry=self.ty+y
   if ry>0 and ry<16 then
    ry=ry*8
    for x=-r,r do
     rx=self.tx+x
     if rx>-1 and rx<16 and x*x+y*y<=r2 then
      rx=rx*8
      rectfill(rx,ry,rx+7,ry+7,0)
     end
    end
   end
  end
  if self.t>20 then self.complete=true end
  self.t=self.t+1
  return self.complete
 end
} setmetatable(squares_in,{__index=transition})

squares_out={
 create=function(self,x,y)
  return squares_in.create(self,x,y)
 end,
 radius=function(self)
  return self.t
 end
} setmetatable(squares_out,{__index=squares_in})

function minskycircfill(y,x,r)
 local size=8
 local r1=8/size
 local x=flr(x/size)
 local y=flr(y/size)
 local cells={x=(screen.width/size),y=(screen.height/size),x2=(screen.width/size)-1,y2=(screen.height/size)-1}
 local data={}
 local j,k,rat=r,0,1/r
 for i=1,r*0.786 do
  k=k-rat*j
  j=j+rat*k
  ij=round(j)
  mn,mx=max(0,flr(y+k)),min(cells.x2,ceil(y-k))
  if x+ij<cells.y then
   if data[x+ij]==nil then data[x+ij]={x1=128,x2=0} end
   if mn<data[x+ij].x1 then data[x+ij].x1=mn end
   if mx>data[x+ij].x2 then data[x+ij].x2=mx end
  end
  if x-ij>=r1 then
   if data[x-ij]==nil then data[x-ij]={x1=128,x2=0} end
   if mn<data[x-ij].x1 then data[x-ij].x1=mn end
   if mx>data[x-ij].x2 then data[x-ij].x2=mx end
  end
  ik=round(k)
  mn,mx=max(0,flr(y-j)),min(cells.x2,ceil(y+j))
  if x+ik>=r1 then
   if data[x+ik]==nil then data[x+ik]={x1=128,x2=0} end
   if mn<data[x+ik].x1 then data[x+ik].x1=mn end
   if mx>data[x+ik].x2 then data[x+ik].x2=mx end
  end
  if x-ik<cells.y then
   if data[x-ik]==nil then data[x-ik]={x1=128,x2=0} end
   if mn<data[x-ik].x1 then data[x-ik].x1=mn end
   if mx>data[x-ik].x2 then data[x-ik].x2=mx end
  end
 end
 if data[x]==nil then data[x]={x1=128,x2=0} end
 if y-r<data[x].x1 then data[x].x1=max(0,y-r) end
 if y+r>data[x].x2 then data[x].x2=min(cells.x2,y+r) end
 local mx,my={min=cells.x2,max=0},{min=cells.x2,max=0}
 for y,d in pairs(data) do
  if y<my.min then my.min=y end
  if y>my.max then my.max=y end
  if d.x1<mx.min then mx.min=d.x1 end
  if d.x2>mx.max then mx.max=d.x2 end
 end
 if my.min>r1 then
  rectfill(0,8,screen.x2,(my.min*size)-1,0)
 end
 if my.max<cells.y then
  rectfill(0,my.max*size+size,screen.x2,screen.y2,0)
 end
 for y,d in pairs(data) do
  if d.x1>0 then rectfill(0,y*size,(d.x1*size)-1,y*size+size-1,0) end
  if d.x2<cells.x2 then rectfill(d.x2*size+size,y*size,screen.x2,y*size+size-1,0) end
 end
end

minsky_in={
 create=function(self,x,y)
  local o=transition.create(self,x,y)
  return o
 end,
 radius=function(self)
  return self.t
 end,
 draw=function(self)
  minskycircfill(self.x,self.y,self:radius())
  if self.t>40 then self.complete=true end
  self.t=self.t+1
  return self.complete
 end
} setmetatable(squares_in,{__index=transition})

minsky_out={
 create=function(self,x,y)
  return squares_in.create(self,x,y)
 end,
 radius=function(self)
  return 40-self.t
 end
} setmetatable(minsky_out,{__index=minsky_in})

-- carts/projects/gunslugs/stages/intro

stage_intro={
 init=function(self)
 end,
 update=function(self)
  if btnp(pad.btn1) or btnp(pad.btn2) then
   stage=stage_main
   stage:init()
  end
 end,
 draw=function(self)
  print("press z or x to start",60,60,6)
 end
}

-- carts/projects/gunslugs/stages/main

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
  self.transition=minsky_in:create(p.camera:screenx(),p.y)
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

-- carts/projects/gunslugs/stages/over

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


function _init()
 enemies=collection:create()
 particles=collection:create()
 bullets=bullet_collection:create()
 destructables=collection:create()
 pickups=collection:create()
 stage=stage_intro
 draw_stage=stage
 stage:init()
end

function _update60()
 stage:update()
end

function _draw()
 cls()
 draw_stage:draw()
 draw_stage=stage
end

function TIC()
 _draw() _update60()
end

_init()

-- <TILES>
-- 001:777777767666666d7666666d7666666d7666666d7666666d7666666d6ddddddd
-- 002:aaaaaaa9a999999494444444a9999994a9999994aaaaaaa4a999999494444444
-- 003:8e6e882228e822228e6e8822822288222e2e2822822288228e6e882228e82222
-- 004:b6a6bb333b6b3333b6a6bb33b333bb333a3a3b33b333bb33b6a6bb333b6b3333
-- 006:000000001d6d11111d6d11111d6d111101d11110088000000000000000000000
-- 007:000000001d6d11111d6d11111d6d111101d11110000880000000000000000000
-- 008:000000001d6d11111d6d11111d6d111101d11110000008800000000000000000
-- 009:0000111100001111000011110000000000000000000000000000000000000000
-- 010:1110000011100000111000000000000011111110111111101111111000000000
-- 011:0000000000000000000000000000000011111110111111101111111000000000
-- 012:1110111111101111111011110000000000000000000000000000000000000000
-- 013:1110111111101111111011110000000011111110111111101111111000000000
-- 016:1111111104444411014144110444441104124410633333300334433002202220
-- 017:0000000011111111044444110141441104444411641244100443333000002220
-- 018:0000000011111111044444110141441104444411641244100333442002200000
-- 019:1111111111444440114414101144444001442140033336660331133002220220
-- 020:0000000011111111114444401144141011444440014421460331133002220000
-- 021:0000000011111111114444401144141011444440014421460222133000000220
-- 022:1111111114444441141441411444444114211241633333301333333002200220
-- 026:0000000066777766677887767788887777888877677887766677776600000000
-- 027:0000000006677770067788e00678888006788880067788e00667777000000000
-- 028:0000000000d6770000d6e80000d6880000d6880000d6e80000d6770000000000
-- 029:00000000000dd000000dd000000dd000000dd000000dd000000dd00000000000
-- 030:0000000000776d00008e6d0000886d0000886d00008e6d0000776d0000000000
-- 031:00000000077776600e88776008888760088887600e8877600777766000000000
-- 032:a7000000aa000000000000000000000000000000000000000000000000000000
-- 033:ba000000bb000000000000000000000000000000000000000000000000000000
-- 034:0990000099a90000999900000990000000000000000000000000000000000000
-- 035:02220000228e2000288820002282200002220000000000000000000000000000
-- 040:0000000008888880888778888877778888777788888778880888888000000000
-- 041:0000000000288800028878800287778002877780028878800028880000000000
-- 042:0000000000028000002288000028780000287800002288000002800000000000
-- 043:0000000000022000000220000002200000022000000220000002200000000000
-- 044:0000000000082000008822000087820000878200008822000008200000000000
-- 045:0000000000888200088788200877782008777820088788200088820000000000
-- 046:00000000055055005ddddd505ddd6d505ddddd5005ddd500005d500000050000
-- 047:0000000002202200288888202888e82028888820028882000028200000020000
-- 048:0f7fffff0f7fffff0171ffff0f7fffff0f7fffff6dddddd00dd11dd005505550
-- 049:000000000f7fffff0f7fffff0171ffff0f7fffff6f7fffff011dddd000005550
-- 050:000000000f7fffff0f7fffff0171ffff0f7fffff6f7fffff0ddd115005500000
-- 051:f7fffff0f7fffff0f7ff1f10f7fffff0f7fffff00dddd6660dd11dd005550550
-- 052:00000000f7fffff0f7fffff0f7ff1f10f7fffff0f7fffff60dd11dd005550000
-- 053:00000000f7fffff0f7fffff0f7ff1f10f7fffff0f7fffff605551dd000000550
-- 054:ff7fffffff7ffffff1dff11fff7fffffff7fffff65ddddd0d5ddddd005500550
-- 055:000000000001311000111211071121230c111211333111316331113030303030
-- 056:00000000011310001121110032121170112111c0131113330311133603030303
-- 057:000000000001311000111211071121230c111211333111316313111303030303
-- 058:00000000011310001121110032121170112111c0131113333111313630303030
-- 061:0d00000066666666dddddddd1116000055500000555000000000000000000000
-- 062:0000d000000266664444dddd4444206044400600000000000000000000000000
-- 063:0000000066666666dddddddd4444400000000000000000000000000000000000
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdefedcba98765432100
-- 002:00123456789abcdedcba456789aba987
-- 003:2456789abcddeeedcb98654321100000
-- 004:6655443332222222233334455667889a
-- 005:1577dc59fd88bc9f4a27d7deac54ca3e
-- </WAVES>

-- <SFX>
-- 000:d100c100b100a1008100710071006100610061006100610071008100810081009100a100a100a100a100b100b100c100d100d100e100e100e100f100507000000000
-- 001:f130e100c130a10091308100713071007130710081309100a130a100b130c100d130e100f130f100f130f100f130f100f130f100f130f100f130f100410000000000
-- 002:956bb56bd55ce55ce55ef55ff550f550f551f551f551f561f562f562f562f562f572f572f582f581f571f560f56ff56ef56df56df56df56cf56cf56c009000000000
-- 003:05301540254f555b655a656a756a856995699568a568b578b578c578c578c578d578d578d578e57fe57fe57ee57ee57de57ce57cf57bf57af57af579009000000000
-- 004:05c825b835983588756885689558a548b538c538d528e518e508f568f568f568f578f578f588f588f578f568f568f568f568f568f568f568f568f568009000000000
-- 005:21c311c11190117f216e214d314d317e31a031b141d241e441e541e54151414f513e513e514e614e615d617d718d819e91afa190b171d172e162e160202000000000
-- 006:8100810081008100810081008100810081009100910091009100a100a100b100b100b100c100c100c100d100d100d100e100e100e100f100f100f100205000000000
-- </SFX>

-- <PALETTE>
-- 000:0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77abffccaa
-- </PALETTE>

