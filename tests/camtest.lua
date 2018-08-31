flr=math.floor
abs=math.abs
min=math.min
max=math.max
function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end
function round(x) return flr(x+0.5) end

local screen={width=240,height=136}

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
 c.max={x=x-c.min.x,y=y-c.min.y,shift=2}
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

  self.x=math.min(self.min.x, self.target.x-self.min.x)

  self.x=max(0,self.target.x-self.min.x)
  self.y=max(0,self.target.y-self.min.y)


 end
 c.spr=function(self,sprite,x,y)
  --spr(sprite,x+self.x,y+self.y)
  --spr(sprite,x,y)
  spr(sprite,x-self.x,y-self.y)
 end
 c.update222222=function(self)
  self.x=math.min(120,120-self.target.x)
  self.y=math.min(64,64-self.target.y)
  --[[
  local min_x = self.x-self.buffer
  local max_x = self.x+self.buffer
  local min_y = self.y-self.buffer
  local max_y = self.y+self.buffer
  if min_x>self.target.x then
   self.x=self.x+min(self.target.x-min_x,self.max.shift)
  end
  if max_x<self.target.x then
   self.x=self.x+min(self.target.x-max_x,self.max.shift)
  end
  if min_y>self.target.y then
   self.y=self.y+min(self.target.y-min_y,self.max.shift)
  end
  if max_y<self.target.y then
   self.y=self.y+min(self.target.y-max_y,self.max.shift)
  end
  if self.x<self.min.x then
   self.x=self.min.x
  elseif self.x>self.max.x then
   self.x=self.max.x
  end
  if self.y<self.min.y then
   self.y=self.min.y
  elseif self.y>self.max.y then
   self.y=self.max.y
  end
  ]]
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

function _init()
  p=create_item(40,40)
  p.camera=create_camera(p,320,192)

  x=0
  t=0
end 

function _update60()
  if btn(0) then p.y=p.y-1 end
  if btn(1) then p.y=p.y+1 end
  if btn(2) then p.x=p.x-1 end
  if btn(3) then p.x=p.x+1 end
  p.camera:update()
  _draw()
  t=t+1
  if t%30==0 then x=x+1 end
end

function _draw()
 cls()
 p.camera:map()
 p.camera:spr(1,p.x,p.y)

 print("player.x:"..p.x, 0, 0)
 print("y:"..p.y, 100, 0)

 print("camera.x:"..p.camera.x, 0, 7)
 print("y:"..p.camera.y, 100, 7)


 print("cell.x:"..p.camera.cell.x,0,14)
 print("y:"..p.camera.cell.y,100,14)

 print("offset.x:"..p.camera.offset.x,0,21)
 print("y:"..p.camera.offset.y,100,21)


 print("min.x:"..p.camera.min.x,0,30)
 print("y:"..p.camera.min.y,100,30)

end

function TIC() _update60() end

_init()