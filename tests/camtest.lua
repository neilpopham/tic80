flr=math.floor
abs=math.abs
min=math.min
max=math.max
function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end

local screen={width=240,height=136}

function create_camera(item,x,y)
 local c={
  target=item,
  x=item.x,
  y=item.y,
  buffer=16,
  min={x=flr(screen.width/2)-4,y=flr(screen.height/2)-4},
  tiles={width=flr(screen.width/8),height=flr(screen.height/8)}
 }
 c.max={x=c.min.x+screen.width-x,y=c.min.y+screen.height-y}
 c.map=function(self)
  self.ccx=self.x/8+(self.x%8==0 and 1 or 0)
  self.ccy=self.y/8+(self.y%8==0 and 1 or 0)
  map(
   (self.tiles.width/2)-self.ccx,
   (self.tiles.height/2)-self.ccy,
   self.tiles.width+1,
   self.tiles.height+1,
   (self.x%8)-8,
   (self.y%8)-8,
   0
  )
 end 
 c.update=function(self)


  self.x=math.min(self.min.x+4,self.min.x-self.target.x)
  self.y=math.min(self.min.y,self.min.y-self.target.y)
  self.x=math.max(self.max.x+4,self.x)
  self.y=math.max(self.max.y,self.y)
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
 c.map=function(self)
  self.ccx=self.x/8+(self.x%8==0 and 1 or 0)
  self.ccy=self.y/8+(self.y%8==0 and 1 or 0)
  map(
   flr(self.tiles.width/2)-self.ccx,
   flr(self.tiles.height/2)-self.ccy,
   self.tiles.width+1,
   self.tiles.height+1,
   (self.x%8)-8,
   (self.y%8)-8,
   0
  )
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
end 

function _update60()
  if btn(0) then p.y=p.y-1 end
  if btn(1) then p.y=p.y+1 end
  if btn(2) then p.x=p.x-1 end
  if btn(3) then p.x=p.x+1 end
  p.camera:update()
  _draw()
end

function _draw()
 cls()
 p.camera:map()
 spr(1,p.x+p.camera.x,p.y+p.camera.y)

 print ("camera x:"..p.camera.x,0,0)
 print ("camera y:"..p.camera.y,100,0)
 print ("camera ccx:"..p.camera.ccx,0,8)
 print ("camera ccy:"..p.camera.ccy,100,8) 

 print("min x:"..p.camera.min.x,0,77)
 print("y:"..p.camera.min.y,60,77)
 print("max x:"..p.camera.max.x,0,84)
 print("y:"..p.camera.max.y,60,84)

 print((p.camera.tiles.width/2)-p.camera.ccx,0,16)
 print((p.camera.tiles.height/2)-p.camera.ccy,0,24)
 print((p.camera.tiles.width/2)-p.camera.ccx,0,32)
 print((p.camera.x%8)-8,0,40)
 print((p.camera.y%8)-8,0,48)

 print ("player x:"..p.x,0,100)
 print ("player y:"..p.y,100,100) 

end

function TIC() _update60() end

_init()