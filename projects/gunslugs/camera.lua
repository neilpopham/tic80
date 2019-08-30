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