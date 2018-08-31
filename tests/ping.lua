-- title:  ping
-- author: Neil Popham
-- desc:   Platformer proof of concept
-- script: lua
-- input:  gamepad
-- saveid: ntp_ping

--  use tic create_item.tic -code create_item.lua command line parameters to inject the code to the cartridge once finished

-- __gff__ data
local sprf={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,3,1,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end
function sub(str,i,j) return str:sub(i,j) end
--function sub(string, s, i) return string.sub(string, s, i) end
flr=math.floor
abs=math.abs
min=math.min
max=math.max

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

-- [[ SHARED CODE ]]

local screen={width=240,height=136}

-- http://pico-8.wikia.com/wiki/btn
-- local pad={left=0,right=1,up=2,down=3,btn1=4,btn2=5}

-- https://github.com/nesbox/tic-80/wiki/key-map
local pad={left=2,right=3,up=0,down=1,btn1=4,btn2=5,btn3=6,btn4=7}

local dir={left=1,right=2}
local drag={air=1,ground=0.8,gravity=0.25,wall=0.05}

function round(x) return flr(x+0.5) end

function create_camera(item,x,y)
 local c={
  target=item,
  x=item.x,
  y=item.y,
  buffer=16,
  min={x=8*flr(screen.width/16),y=8*flr(screen.height/16)},
  tiles={width=flr(screen.width/8),height=flr(screen.height/8)},
  cell={},
  offset={}
 }
 c.max={x=x-screen.width,y=y-screen.height,shift=2}
 c.map=function(self)
  x=self.x
  y=self.y
  self.cell.x=math.floor(x/8)
  self.cell.y=math.floor(y/8)
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
 end 
 c.update=function(self)
  self.min_x = self.x+self.min.x-self.buffer
  self.max_x = self.x+self.min.x+self.buffer
  self.min_y = self.y+self.min.y-self.buffer
  self.max_y = self.y+self.min.y+self.buffer
  if self.min_x>self.target.x then
   self.x=self.x+min(self.target.x-self.min_x,self.max.shift)
  end
  if self.max_x<self.target.x then
   self.x=self.x+min(self.target.x-self.max_x,self.max.shift)
  end
  if self.min_y>self.target.y then
   self.y=self.y+min(self.target.y-self.min_y,self.max.shift)
  end
  if self.max_y<self.target.y then
   self.y=self.y+min(self.target.y-self.max_y,self.max.shift)
  end
  self.x=mid(0,self.x,self.max.x)
  self.y=mid(0,self.y,self.max.y)
 end
 c.spr=function(self,sprite,x,y)
  spr(sprite,x-self.x,y-self.y,0)
 end
 return c
end

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
 i.min={dx=0.05,dy=0.05}
 i.max={dx=1,dy=2,slide=15}
 i.slide={tick=0}
 i.ax=ax
 i.ay=ay
 i.is={
  grounded=false,
  jumping=false,
  sliding=false,
  falling=false,
  invisible=false
 }
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
 i.set_state=function(self, state)
  for s in pairs(self.is) do
   self.is[s]=false
  end
  self.is[state]=true
 end
 i.draw=function(self)
  if self.is.invisible then return end
  sprite=self.animate(self)
  p.camera:spr(sprite,self.x,self.y,0)
  if self.is.sliding then
   sprite=self.smoke:animate()
   p.camera:spr(sprite,self.x,self.y-8,0)
  end
 end
 i.animate=function(self)
  local current=self.anim.current
  local stage=self.anim.stage[current.stage]
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
 i.can_move_x=function(self,flag)
  local x=self.x+round(self.dx)
  if self.dx>0 then x=x+7 end
  for _,y in pairs({self.y,self.y+7}) do
   local tx=flr(x/8)
   local ty=flr(y/8)
   tile=mget(tx,ty)
   if fget(tile,0) or (flag and fget(tile,flag)) then
    if self.is.grounded then
     self.dx=0
    else
     if fget(tile,1) then
      if self.is.sliding==false then
       self.dy=0
       self.slide.tick=self.max.slide
      end
      local face=self.dx<0 and 1 or 2
      self.anim.current.face=face
      self.smoke.anim.current.face=face
      self.anim.current:set("wall")
      self:set_state("sliding")
     end
    end
    return false
   end
  end
  if self.is.sliding then
   self.is.sliding=false
  end
  return true
 end
 i.can_move_y=function(self)
  local y=self.y+round(self.dy)
  if self.dy>0 then y=y+7 end
  for _,x in pairs({self.x,self.x+7}) do
   local tx=flr(x/8)
   local ty=flr(y/8)
   tile=mget(tx,ty)
   if fget(tile,0) then
    if self.dy>0 then
     self.y=(ty-1)*8
     if self.is.falling then
      self.btn.tick=0
     end
     self:set_state("grounded")
     self.slide.tick=0
     if not self.anim.current.transitioning then
      self.anim.current:set(round(self.dx)==0 and "still" or "walk")
     end
    else
     self.y=8+(ty*8)
     if self.is.jumping then
      self:set_state("falling")
      self.anim.current:set("jump_fall")
      self.btn.tick=self.max.btn
      self.dy=0
     end
    end
    return false
   end
  end
  return true
 end
 return i
end

function create_controllable_item(x,y,ax,ay)
 local i=create_moveable_item(x,y,ax,ay)
 i.min.btn=5
 i.max.btn=20
 i.btn={tick=0}
 i.can_jump=function(self)
  if self.is.jumping
   and self.btn.tick>0 then
   return true
  end
  if self.is.grounded then
   return true
  end
  if self.is.falling
   and self.dx~=0
   and self.slide.tick>0 then
   return true
  end
  return false
 end
 i.update=function(self)
  local face=self.anim.current.face
  local stage=self.anim.current.stage

  -- checks for direction change
  local check=function(self,stage,face)
   if face~=self.anim.current.face then
    if stage=="still" then stage="walk" end
    if stage=="jump_fall" then stage="fall" end
    if not self.anim.current.transitioning then
     self.anim.current:set(stage.."_turn")
     self.anim.current.transitioning=true
    end
   end
  end

  -- horizontal movement
  if btn(pad.left) then
   self.anim.current.face=dir.left
   check(self,stage,face)
   self.dx=self.dx-self.ax
  elseif btn(pad.right) then
   self.anim.current.face=dir.right
   check(self,stage,face)
   self.dx=self.dx+self.ax
  else
   if self.is.jumping then
    self.dx=self.dx*drag.air
   else
    self.dx=self.dx*drag.ground
    if self.is.sliding then
     self.dx=0
     self:set_state("falling")
     self.anim.current:set("fall")
    end
   end
  end
  self.dx=mid(-self.max.dx,self.dx,self.max.dx)
  if abs(self.dx)<self.min.dx then self.dx=0 end
  if self.dx~=0 then
   if self.can_move_x(self) then
    self.x=self.x+round(self.dx)
   end
  end

  -- vertical movement
  if btn(pad.btn1)
   and self.can_jump(self) then
   self.btn.tick=self.btn.tick+1
  else
   self.btn.tick=0
  end
  if self.btn.tick>=self.min.btn
   and self.btn.tick<=self.max.btn then
   self:set_state("jumping")
   self.anim.current:set("jump")
   self.dy=self.dy+self.ay
  end
  if self.is.sliding then
   self.dy=self.dy+drag.wall
  else
   self.dy=self.dy+drag.gravity
   if self.is.falling then
    self.slide.tick=max(self.slide.tick-1,0)
   elseif self.is.grounded then
    self.slide.tick=0
   end
  end
  self.dy=mid(-self.max.dy,self.dy,self.max.dy)
  if abs(self.dy)<self.min.dy then self.dy=0 end
  if self.dy~=0 then
   if self.can_move_y(self) then
    self.y=self.y+round(self.dy)
    self.is.grounded=false
    if round(self.dy)>0 then
     if self.is.sliding then
      if self.dy==self.max.dy then
       self.slide.tick=max(self.slide.tick-1,0)
      end
     else
      if self.is.jumping then
       self.anim.current:set("jump_fall")
      else
       self.anim.current:set("fall")
      end
      self:set_state("falling")
     end
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

 -- player
 p=create_controllable_item(0,0,0.1,-1.75)
 p.anim:add_stage("still",1,false,{6},{12})
 p.anim:add_stage("walk",5,true,{1,2,3,4,5,6},{7,8,9,10,11,12})
 p.anim:add_stage("jump",1,false,{1},{7})
 p.anim:add_stage("fall",1,false,{32},{33})
 p.anim:add_stage("wall",1,false,{13},{28})
 p.anim:add_stage("walk_turn",5,false,{20,18,21,6},{17,18,19,12},"still")
 p.anim:add_stage("jump_turn",5,false,{25,26,27},{22,23,24},"jump")
 p.anim:add_stage("fall_turn",5,false,{25,26,27},{22,23,24},"fall")
 p.anim:add_stage("wall_turn",5,false,{29,30,31},{14,15,16},"fall")
 p.anim:add_stage("jump_fall",5,false,{2,3},{8,9},"fall")
 p.anim:init("still",dir.right)

 -- player wall slide smoke
 p.smoke=create_controllable_item(0,0,0,0)
 p.smoke.anim:add_stage("smoking",4,true,{34,35},{36,37})
 p.smoke.anim:init("smoking",dir.right)

 -- camera
 p.camera=create_camera(p,256,192)

 -- replace map placeholders
 gem_count=0
 gem_total=0
 gems={}
 local x local y
 for x=0,63 do for y=0,31 do
  local s=mget(x,y)
  if s==62 then
   gem_total=gem_total+1
   mset(x,y,0)
   local g=create_moveable_item(x*8,y*8,0,0)
   g.anim:add_stage("still",1,false,{62},{})
   g.anim:init("still",dir.left)
   g.update=function(self)
    if self.is.invisible then return end
    if p.x<self.x+7
     and p.x+8>self.x
     and p.y<self.y+7
     and p.y+8>self.y then
     self.is.invisible=true
     gem_count=gem_count+1
    end
   end
   gems[#gems+1]=g
  end
  if s==p.anim.current.frame then
   mset(x,y,0)
   p.x=x*8
   p.y=y*8
  end
 end end
 
--[[
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
   if self.anim.current.tick%2==0 then
    if self.can_move_x(self,2) then
     self.x=round(self.x+self.dx)
    else
     self.dx=0
     self.anim.current.face=self.anim.current.face==1 and 2 or 1
     self.anim.current:set("walk_turn")
    end
   end
  end
 end 

 waters={{64,32},{72,32},{80,32}}
 for i,water in pairs(waters) do
  waters[i]=create_moveable_item(water[1],water[2],0,0)
  waters[i].anim:add_stage("still",5,true,{44,45,46,47},{})
  waters[i].anim:init("still",dir.left)
 end
]]
end

function _update60()
 p:update()
 p.camera:update()
 for _,gem in pairs(gems) do gem:update() end
 --for _,enemy in pairs(enemies) do enemy:update() end
 _draw()
end

function _draw()
 cls()
 p.camera:map()
 --for _,enemy in pairs(enemies) do enemy:draw() end
 --for _,water in pairs(waters) do water:draw() end
 for _,gem in pairs(gems) do gem:draw() end
 p:draw()
 -- camera(0,0)
 spr(62,205,1,0)
 print(sub("0"..gem_count,-2).."'"..gem_total,214,2)

--[[
 print("stage:"..p.anim.current.stage,0,0)
 print("dir:"..p.anim.current.face,82,0)
 print("frame:"..p.anim.current.frame,0,7)
 print("t:"..p.anim.current.tick,82,7)
 print("b:"..p.btn.tick,82,14)
 print("dx:"..p.dx,0,14) print("dy:"..p.dy,30,14)

 print("grounded:"..(p.is.grounded and "t" or "f"),126,0)
 print("jumping:"..(p.is.jumping and "t" or "f"),126,7)
 print("falling:"..(p.is.falling and "t" or "f"),126,14)
 print("sliding:"..(p.is.sliding and "t" or "f"),126,21)

 print("camera:"..p.camera.x..","..p.camera.y,0,21)
 print("slide:"..p.slide.tick,0,28)

 print("x:"..(p.x).." y:"..(p.y),0,35)
--]]
end
function TIC() _update60() end

_init()