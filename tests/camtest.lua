flr=math.floor
ceil=math.ceil
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
  buffer={x=32,y=16},
  min={x=8*flr(screen.width/16),y=8*flr(screen.height/16)},
  max={x=x-screen.width,y=y-screen.height,shift=2},
  tiles={width=flr(screen.width/8),height=flr(screen.height/8)},
  cell={},
  offset={}
 }
 c.map=function(self)
  self.cell.x=flr(self.x/8)
  self.cell.y=flr(self.y/8)
  self.offset.x=-(self.x%8)
  self.offset.y=-(self.y%8)
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
  self.min_x=self.x+self.min.x-self.buffer.x
  self.max_x=self.x+self.min.x+self.buffer.x
  self.min_y=self.y+self.min.y-self.buffer.y
  self.max_y=self.y+self.min.y+self.buffer.y
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

function _init()
  p=create_item(40,40)
  p.camera=create_camera(p,512,256)

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
end

function _draw()
 cls()
 p.camera:map()
 p.camera:spr(1,p.x,p.y)

 p.camera:spr(4,160,160)

 print("player.x: "..p.x, 0, 0)
 print("y: "..p.y, 100, 0)

 print("camera.x: "..p.camera.x, 0, 7)
 print("y: "..p.camera.y, 100, 7)


 print("cell.x: "..p.camera.cell.x,0,14)
 print("y: "..p.camera.cell.y,100,14)

 print("offset.x: "..p.camera.offset.x,0,21)
 print("y: "..p.camera.offset.y,100,21)


 print("min.x: "..p.camera.min.x,0,30)
 print("y: "..p.camera.min.y,100,30)
 print("max.x: "..p.camera.max.x,0,37)
 print("y: "..p.camera.max.y,100,37)

 print("min_x: "..p.camera.min_x,0,50)
 print("max_x: "..p.camera.max_x,0,57)
 print("min_y: "..p.camera.min_y,0,64)
 print("max_y: "..p.camera.max_y,0,71)

 --mset(flr(p.x/8), flr(p.y/8), 4)

end

function TIC() _update60() end

_init()