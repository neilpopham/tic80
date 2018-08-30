local screen={width=240,height=136}

function create_camera(item)
 local c={
  target=item,
  x=item.x,
  y=item.y,
  buffer=16,
  min={x=screen.width/2,y=screen.height/2},
  max={x=128,y=128,shift=2},
  tiles={width=screen.width/8,height=screen.height/8}
 }
 c.update=function(self)
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
  self.x=math.min(120,120-p.x)
  self.y=math.min(64,64-p.y)

  self.x=screen.width/2
  self.y=screen.height/2
 end
 c.position=function(self)
  return self.x-self.min.x,self.y-self.min.y
 end
 --c.camera=function(self)

 --end
 c.map=function(self)
  local ccx=self.x/8+(self.x%8==0 and 1 or 0)
  local ccy=self.y/8+(self.y%8==0 and 1 or 0)
  map(
   (self.tiles.width/2)-ccx,
   (self.tiles.height/2)-ccy,
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
  p.camera=create_camera(p)
end 

function _update60()
  if btn(0) then p.y=p.y-1 end
  if btn(1) then p.y=p.y+1 end
  if btn(2) then p.x=p.x-1 end
  if btn(3) then p.x=p.x+1 end

  _draw()
end

function _draw()
 cls()
 --p.camera:camera()
 p.camera:map()
 spr(1,p.x+p.camera.x,p.y+p.camera.y)
end

function TIC() _update60() end

_init()
-- <PALETTE>
-- 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

