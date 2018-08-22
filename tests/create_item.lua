-- title:  create_item
-- author: Neil Popham
-- desc:   Platformer test
-- script: lua
-- input:  gamepad
-- saveid: ntp_create_item

local dir={left=1,right=2}
local drag={air=1,ground=0.8,gravity=0.15}

-- http://pico-8.wikia.com/wiki/Btn
-- local pad={l=0,r=1,u=2,d=3,b14,b2=5}

-- https://github.com/nesbox/TIC-80/wiki/key-map
local pad={l=2,r=3,u=0,d=1,b1=4,b2=5,b3=6,b4=7}

function round(x)
 return flr(x+0.5)
end

--function mid(...)
-- table.sort(arg)
-- return arg[2]
--end

function mid(x,y,z)
 t={x,y,z}
 table.sort(t)
 return t[2]
end

function flr(x) return math.floor(x) end

function abs(x) return math.abs(x) end

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
 i.is={grounded=true}
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
   end,
   set=function(self,stage,face)
    self.reset(self)
    self.stage=stage
    self.face=face or self.face
   end
  },
  add_stage=function(self,name,ticks,loop,left,right,next)
   self.stage[name]=create_stage(ticks,loop,left,right,next)
  end
 }
 i.draw=function(self)
  sprite=self.animate(self)
  spr(sprite,self.x,self.y)
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
 return i
end

function create_controllable_item(x,y,ax,ay)
 local i=create_moveable_item(x,y,ax,ay)
 i.update=function(self)
  local face=self.anim.current.face
  local stage=self.anim.current.stage

  local check=function(anim,stage,face)
   if face~=anim.current.face then
    if stage=="still" then stage="walk" end
    anim.current:set(stage.."_turn")
   elseif stage=="still" then
    anim.current:set("walk")
   end
  end

  -- horizontal movement
  if btn(pad.l) then
   self.anim.current.face=dir.left
   check(self.anim,stage,face)
   p.dx=p.dx-p.ax
  elseif btn(pad.r) then
   self.anim.current.face=dir.right
   check(self.anim,stage,face)
   p.dx=p.dx+p.ax
  else
   if p.is.grounded then
    self.anim.current:set("still")
    p.dx=p.dx*drag.ground
   else
    p.dx=p.dx*drag.air
   end   
  end
  p.dx=mid(-p.max.dx,p.dx,p.max.dx)
  if abs(p.dx)<p.min.dx then p.dx=0 end
  p.x=p.x+round(p.dx)

  -- vertical movement

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
 p=create_controllable_item(63,63,0.05,-1.75)
 p.anim:add_stage("still",1,false,{5},{11})
 p.anim:add_stage("walk",5,true,{0,1,2,3,4,5},{6,7,8,9,10,11})
 p.anim:add_stage("jump",1,false,{0},{6})
 p.anim:add_stage("fall",1,false,{0},{6})
 p.anim:add_stage("walk_turn",5,false,{19,17,20,5},{16,17,18,11},"walk")
 p.anim:add_stage("jump_turn",5,false,{24,25,26},{21,22,23},"jump")
 p.anim:add_stage("fall_turn",5,false,{24,25,26},{21,22,23},"fall")
 p.anim:init("still",dir.right)
end

_init()

function TIC()
 cls()
 p:update()
 p:draw()

 print("current.frame:"..p.anim.current.frame,0,10)
 print("face:"..p.anim.current.face,0,0)
 print("tick:"..p.anim.current.tick,0,20)
 print("dx:"..p.dx,0,30)
end