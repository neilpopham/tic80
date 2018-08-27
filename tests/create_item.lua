-- title:  create_item
-- author: Neil Popham
-- desc:   Platformer test
-- script: lua
-- input:  gamepad
-- saveid: ntp_create_item

sprf={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,3,1,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

-- http://pico-8.wikia.com/wiki/Mid
function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end

-- http://pico-8.wikia.com/wiki/Flr
flr=math.floor

-- http://pico-8.wikia.com/wiki/Abs
abs=math.abs

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

local dir={left=1,right=2}
local drag={air=1,ground=0.8,gravity=0.15,wall=0}

-- http://pico-8.wikia.com/wiki/btn
--local pad={l=0,r=1,u=2,d=3,b1=4,b2=5}

-- pad_left=0 pad_right=1 pad_up=2 pad_down=3 pad_b1=4 pad_b2=5

-- https://github.com/nesbox/tic-80/wiki/key-map
local pad={l=2,r=3,u=0,d=1,b1=4,b2=5,b3=6,b4=7}

function round(x) return flr(x+0.5) end

function create_item(x,y)
 local i={
  x=x,
  y=y
 }
 return i
end

function create_moveable_item(x,y,ax,ay)
 local i=create_item(x,y)
 i.dx=0
 i.dy=0
 i.min={dx=0.05,dy=0.05,btn=5}
 i.max={dx=1,dy=2,btn=15}
 i.ax=ax
 i.ay=ay
 i.is={grounded=false,jumping=false,sliding=false,falling=false}
 i.anim={
  init=function(self,stage,face)
   -- record frame count for each stage face
   for s in pairs(self.stage) do
    for f=1,2 do
     self.stage[s].face[f].fcount=#self.stage[s].face[f].frames
    end
   end
   -- init current values
   self.current:set(stage,face)
  end,
  stage={},
  current={
   reset=function(self)
    self.frame=1
    self.tick=0
    self.loop=true
    self.transitioning=false
   end,
   set=function(self,stage,face)
    if self.stage==stage then return end
    self.reset(self)
    self.stage=stage
    self.face=face or self.face
   end
  },
  add_stage=function(self,name,ticks,loop,left,right,next)
   self.stage[name]=create_stage(ticks,loop,left,right,next)
  end
 }
 i.camera=function(self)
  local x local y
  if self.x<64 then
   x=0
  elseif self.x>1024 then
   x=900
  else
   x=self.x-64
  end
  if self.y<64 then
   y=0
  elseif self.y>1024 then
   y=900
  else
   y=self.y-64
  end
  camera(x,y)
 end
 i.draw=function(self)
  sprite=self.animate(self)
  spr(sprite,self.x,self.y)
 end
 i.animate=function(self)
  local current=self.anim.current
  local stage=self.anim.stage[current.stage]
  assert(stage~=nil,"stage is "..current.stage) -- ###################################
  local face=stage.face[current.face]
  if current.loop then
   current.tick=current.tick+1
   if current.tick==stage.ticks then
    current.tick=0
    current.frame=current.frame+1
    if current.frame>face.fcount then
     if stage.next then
      current:set(stage.next)
      face=self.anim.stage[current.stage].face[current.face]
     elseif stage.loop then
      current.frame=1
     else
      current.frame=face.fcount
      current.loop=false
     end
    end
   end
  end
  return face.frames[current.frame]
 end
 i.canmovex=function(self,flag)
  local x=self.x+round(self.dx)
  if self.dx>0 then x=x+7 end
  for _,y in pairs({self.y,self.y+7}) do
   local tx=flr(x/8)
   local ty=flr(y/8)
   tile=mget(tx,ty)
   -- note
   -- this won't let us jump off at the moment
   -- need to know we can jump slide
   -- even if not moving into the wall 
   if fget(tile,0) or (flag and fget(tile,flag)) then
    if self.is.grounded then
     self.dx=0
    else
     if fget(tile,1) then
      if self.is.sliding==false then self.dy=0 end
      self.anim.current:set("wall")
      self.is.sliding=true
     end
    end
    return false
   end
  end
  return true
 end
 i.canmovey=function(self)
  local y=self.y+round(self.dy)
  if self.dy>0 then y=y+7 end
  for _,x in pairs({self.x,self.x+7}) do
   local tx=flr(x/8)
   local ty=flr(y/8)
   tile=mget(tx,ty)
   if fget(tile,0) then
    if self.dy>0 then
     self.y=(ty-1)*8
     self.is.grounded=true
     self.is.sliding=false
     self.is.falling=false
     if self.anim.current.stage~="walk_turn" then
      self.anim.current:set(round(self.dx)==0 and "still" or "walk")
     end
    else
     self.y=8+((ty)*8)
    end
    return false
   end
  end
  self.is.grounded=false
  return true
 end
 return i
end

function create_controllable_item(x,y,ax,ay)
 local i=create_moveable_item(x,y,ax,ay)
 i.update=function(self)
  local face=self.anim.current.face
  local stage=self.anim.current.stage

  local check=function(self,stage,face)
   if face~=self.anim.current.face then
    if stage=="still" then stage="walk" end
    if not self.anim.current.transitioning then
     self.anim.current:set(stage.."_turn")
     self.anim.current.transitioning=true
    end
   end
  end

  -- horizontal movement
  if btn(pad.l) then
   self.anim.current.face=dir.left
   check(self,stage,face)
   self.dx=self.dx-self.ax
  elseif btn(pad.r) then
   self.anim.current.face=dir.right
   check(self,stage,face)
   self.dx=self.dx+self.ax
  else
   if self.is.grounded then
    self.dx=self.dx*drag.ground
   elseif self.jumping then
    self.dx=self.dx*drag.air
   else
    self.dx=self.dx*drag.ground
   end
  end
  self.dx=mid(-self.max.dx,self.dx,self.max.dx)
  if abs(self.dx)<self.min.dx then self.dx=0 end
  if self.dx~=0 then
   if self.canmovex(self) then
    self.x=self.x+round(self.dx)
    if self.is.sliding then
     self.is.sliding=false
     if self.anim.current~="fall_turn" then
      self.anim.current:set("fall")
     end
    end
   end
  end

  -- vertical movement
  if self.is.sliding then
   self.dy=self.dy+drag.wall
  else
   self.dy=self.dy+drag.gravity
  end
  self.dy=mid(-self.max.dy,self.dy,self.max.dy)
  if abs(self.dy)<self.min.dy then self.dy=0 end
  if self.dy~=0 then
   if self.canmovey(self) then
    self.y=self.y+round(self.dy)
    if self.dy>0
     and self.is.sliding==false and self.is.grounded==false
     and self.is.falling==false then
     self.anim.current:set("fall")
     self.is.falling=true
    end
   end
  end

 end
 return i
end

function create_stage(ticks,loop,left,right,next)
 local s={
  ticks=ticks,
  loop=loop,
  face={{frames=left},{frames=right}},
  next=next
 }
 return s
end

function _init()
 p=create_controllable_item(40,0,0.1,-1.75)
 p.anim:add_stage("still",1,false,{6},{12})
 p.anim:add_stage("walk",5,true,{1,2,3,4,5,6},{7,8,9,10,11,12})
 p.anim:add_stage("jump",1,false,{1},{7})
 p.anim:add_stage("fall",1,false,{1},{7})
 p.anim:add_stage("wall",1,false,{13},{28})
 p.anim:add_stage("walk_turn",5,false,{20,18,21,6},{17,18,19,12},"still")
 p.anim:add_stage("jump_turn",5,false,{25,26,27},{22,23,24},"jump")
 p.anim:add_stage("fall_turn",5,false,{25,26,27},{22,23,24},"fall")
 p.anim:add_stage("wall_turn",5,false,{29,30,31},{14,15,16},"jump")
 p.anim:init("still",dir.right)

 enemies={{64,64},{24,88},{32,16}}
 for i,enemy in pairs(enemies) do
  enemies[i]=create_moveable_item(enemy[1],enemy[2],0.2,-1.75)
  enemies[i].anim:add_stage("walk",5,true,{64,65,66,67},{64,65,66,67})
  enemies[i].anim:add_stage("walk_turn",5,false,{68,69,70},{68,69,70},"walk")
  enemies[i].anim:init("walk",dir.right)
  enemies[i].update=function(self)
   local dir=self.anim.current.face==1 and -1 or 1
   self.dx=(self.dx+(self.ax*dir))*drag.ground
   self.dx=mid(-self.max.dx,self.dx,self.max.dx)
   if abs(self.dx)<self.min.dx then self.dx=self.min.dx end
    if self.anim.current.tick % 2==0 then
      if self.canmovex(self,2) then
      self.x=round(self.x+self.dx)
    else
     self.dx=0
     self.anim.current.face=self.anim.current.face==1 and 2 or 1
     self.anim.current:set("walk_turn")
    end
   end
  end
 end

  -- dump fget data to an array format that can be used in tic-80 code
 --d="" for s=0,127 do d=d..fget(s).."," end printh(d,"@clip")
end

function _update60()
 p:update()
 for _,enemy in pairs(enemies) do enemy:update() end -- e:update()
 _draw()
end

function _draw()
 cls()
 
 --p:camera()
 map(0,0)
 for _,enemy in pairs(enemies) do enemy:draw() end -- e:draw()
 p:draw()
 --camera(0,0)
 spr(37,114,4)
 spr(38,118,4)
 print("stage:"..p.anim.current.stage,0,106)
 print("dir:"..p.anim.current.face,62,106)
 print("frame:"..p.anim.current.frame,0,113)
 print("t:"..p.anim.current.tick,62,113)
 print("dx:"..p.dx,0,120) print("dy:"..p.dy,20,120)
 print("grounded:"..(p.is.grounded and "t" or "f"),86,106)
 print("jumping:"..(p.is.jumping and "t" or "f"),86,113)
 print("sliding:"..(p.is.sliding and "t" or "f"),86,120)
--[[
 print(e.dx,0,0)
 print(e.anim.current.stage,0,10)
 print(e.anim.current.face,0,20)
]]
end

function TIC() _update60() end

_init()