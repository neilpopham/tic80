-- title:  floormaker2
-- author: Neil Popham
-- desc:   
-- script: lua
-- input:  gamepad

add=table.insert
sqrt=math.sqrt
abs=math.abs
min=math.min
max=math.max
flr=math.floor
function rnd(a) a=a or 1 return math.random()*a end
function cos(x) return math.cos((x or 0)*(math.pi*2)) end
function sin(x) return math.sin(-(x or 0)*(math.pi*2)) end
function pset(x,y,c) rectb(x,y,1,1,c) end
function del(t,a)
 for i,v in ipairs(t) do
   if v==a then
    t[i]=t[#t]
    t[#t]=nil
      return
    end
  end
end

screen={width=240,height=136,x2=239,y2=135}
pad={left=2,right=3,up=0,down=1,btn1=4,btn2=5,btn3=6,btn4=7}
canvas={width=240,height=136,x2=239,y2=135,ratio=2}

function extend(...)
 local o,arg={},{...}
 for _,a in pairs(arg) do
  for k,v in pairs(a) do o[k]=v end
 end
 return o
end

floormaker={
 create=function(self,params)
  params=params or {}
  local o={}
  o.t90=params.t90 or 0.1
  o.t180=params.t180 or 0.05
  o.x2=params.x2 or 0.5
  o.x3=params.x3 or 0.4
  o.limit=params.limit or 6
  o.new=params.new or 0.05
  o.life=params.life or 0.02
  o.angle=params.angle or 0
  o.x=params.x or flr(canvas.width/2)
  o.y=params.y or flr(canvas.height/2)
  o.total=params.total or 192
  o.params=extend(o)
  setmetatable(o,self)
  self.__index=self
  canvas.pow={
   x=max(3,flr(canvas.width/20)),
   y=max(3,flr(canvas.height/20))
  }
  return o
 end,
 run=function(self)
  self.complete=false
  self.threads={}
  self.cells={}
  self.count=0
  self.min={x=self.x,y=self.y}
  self.max={x=self.x,y=self.y}
  self:spawn()
  repeat
   for _,thread in pairs(self.threads) do
    local done=thread:update(self)
    if done then
     if #self.threads==1 then self:spawn() end
     del(self.threads,thread)
    end
   end
  until self.count>=self.total
  -- shift cells so that the map starts at 0,0
  local dx=self.max.x-self.min.x+1
  local dy=self.max.y-self.min.y+1
  local sx=flr(screen.width/8)
  local sy=flr(screen.height/8)
  local ox=max(1,flr((sx-dx)/2))
  local oy=max(1,flr((sy-dy)/2))
  self.width=max(sx,ox*2+dx)
  self.height=max(sy,oy*2+dy)
  local ox=ox-self.min.x
  local oy=oy-self.min.y
  local cells={}
  for index,cell in pairs(self.cells) do
   local i=self:get_index({cell[1]+ox,cell[2]+oy})
   cells[i]={cell[1]+ox,cell[2]+oy}
  end
  self.cells=cells
  self.x=self.x+ox
  self.y=self.y+oy
  self.complete=true
  return self.cells
 end,
 spawn=function(self,params)
  local t=self:thread(params)
  t:add_cell(self,{t.x,t.y})
  add(self.threads,t)
 end,
 get_index=function(self,cell)
  return cell[2]*canvas.width+cell[1]
 end,
 thread=function(self,params)
  params=params or {}
  local o=extend(self.params,params)
  o.lx=1
  o.ly=1
  o.update=function(self,parent)
   self.lx=cos(self.angle)
   self.ly=-sin(self.angle)
   local cells={{0,0}}
   local added=0
   local done=false
   local t90=self.t90
   local da=0.25
   local m=0.5
   local n=0
   local t=0
   -- #1 if we're moving up or down then
   -- increase the chance (t90) to turn 90º
   -- as we need to stay wider than higher
   -- #2 if we're close to the edge of the canvas
   -- increase the chance (t90) to turn 90º
   -- and increase the chance (m)
   -- that the correct turn (da) is chosen
   if self.angle==0.25 or self.angle==0.75 then
    t90=t90*canvas.ratio
    n=min(self.y,canvas.y2-self.y)
    if n==0 then t=1 else t=2/n end
    t90=max(t90,t)
    m=max(0.5,(1-n/canvas.y2)^canvas.pow.y)
    if self.x<canvas.width/2 then
     da=self.angle-0.5
    else
     da=0.5-self.angle
    end
   else
    n=min(self.x,canvas.x2-self.x)
    if n==0 then t=1 else t=2/n end
    t90=max(t90,t)
    m=max(0.5,(1-n/canvas.x2)^canvas.pow.x)
    if self.y<canvas.height/2 then
     da=0.25-self.angle
    else
     da=self.angle-0.25
    end
   end
   -- change direction
   local r=rnd()
   if r<t90 then
    if rnd()<m then
     self.angle=self.angle+da
    else
     self.angle=self.angle-da
    end
   elseif r<t90+self.t180 then
    self.angle=self.angle+0.5
   end
   -- set new position
   self.angle=self.angle%1
   self.x=self.x+cos(self.angle)
   self.y=self.y-sin(self.angle)
   -- add room
   r=rnd()
   if r<self.x2 then
    cells=self:get_room(2)
   elseif r<self.x2+self.x3 then
    cells=self:get_room(3)
   end
   -- spawn new thread
   if #parent.threads<parent.limit then
    r=rnd()
    if r<self.new then
     local angle=self:get_angle()
     local m=parent:spawn({x=self.x,y=self.y,angle=angle})
    end
   end
   -- kill this thread
   r=rnd()
   if r<#parent.threads*self.life then
    done=true
   end
   -- kill this thread if we've strayed off canvas
   if self.x<0 or self.x>canvas.x2
    or self.y<0 or self.y>canvas.y2 then
    done=true
    cells={}
   end
   -- add the cells to the collection
   for _,cell in pairs(cells) do
    self:add_cell(
     parent,
     {self.x+cell[1],self.y+cell[2]}
    )
   end
   -- return the thread's status
   return done
  end
  o.add_cell=function(self,parent,cell)
   local index=parent:get_index(cell)
   if parent.cells[index]==nil then
    parent.cells[index]=cell
    parent.count=parent.count+1
    if cell[1]<parent.min.x then
     parent.min.x = cell[1]
    elseif cell[1]>parent.max.x then
     parent.max.x = cell[1]
    end
    if cell[2]<parent.min.y then
     parent.min.y = cell[2]
    elseif cell[2]>parent.max.y then
     parent.max.y = cell[2]
    end
   end
  end
  o.get_room=function(self,size)
   local dx=-self.lx
   local dy=-self.ly
   if self.x<size+4
    then dx=1
   elseif self.x>canvas.x2-size-4 then
    dx=-1
   end
   if self.y<size+4 then
    dy=1
   elseif self.y>canvas.y2-size-4 then
    dy=-1
   end
   local r={}
   for x=0,size-1 do
    for y=0,size-1 do
     add(r,{x*dx,y*dy})
    end
   end
   return r
  end
  o.get_angle=function(self)
   local options={}
   if self.x>7 then add(options,0) end
   if self.x<canvas.width-8 then add(options,0.5) end
   if self.y>7 then add(options,0.75) end
   if self.y<canvas.height-8 then add(options,0.25) end
   return options[flr(rnd(4)+1)]
   --return flr(rnd(4))*0.25
  end
  return o
 end
}

function reset()
 maker=floormaker:create()
 cells=maker:run()
 --printh("width:"..maker.width.." height:"..maker.height)
 cam=create_camera({x=maker.x*8,y=maker.y*8},maker.width*8,maker.height*8)
end

function _init()
 --printh("==================")
 t=0
 reset()
end

function _update()
 t=t+1
 if t%180==0 then reset() end
 cam:update()
end

function _draw()
 cls()

 local sprite={roof=1,wall=2,shadow=3,floor=4}
 for x=0,maker.width-1 do
  for y=0,maker.height-1 do
   mset(x,y,sprite.roof)
  end
 end
 for index,cell in pairs(cells) do
  local north={cell[1],cell[2]-1}
  local n=maker:get_index(north)
  if cells[n]==nil then
   mset(cell[1],cell[2],sprite.wall)
  else
   north={cell[1],cell[2]-2}
   n=maker:get_index(north)
   if cells[n]==nil then
    mset(cell[1],cell[2],sprite.shadow)
   else
    mset(cell[1],cell[2],sprite.floor)
   end
  end
 end

 cam:map()
 cam:spr(5,maker.x*8,maker.y*8)

 rect(0,0,maker.width,maker.height,1)
 for index,cell in pairs(cells) do
  pset(cell[1],cell[2],6)
 end
 pset(maker.x,maker.y,8)
 local cx,cy=cam.x,cam.y
 rectb(cx/8,cy/8,screen.width/8,screen.height/8,3)

end

function TIC() _update() _draw() end

function create_camera(item,x,y)
 local c={
  target=item,
  x=item.x,
  y=item.y,
  buffer=16,
  min={x=8*flr(screen.width/16),y=8*flr(screen.height/16)},
  max={x=x-screen.width,y=y-screen.height,shift=2},
  tiles={width=flr(screen.width/8),height=flr(screen.height/8)},
  cell={},
  offset={}
 }
 c.update=function(self)
  local min_x = self.x+self.min.x-self.buffer
  local max_x = self.x+self.min.x+self.buffer
  local min_y = self.y+self.min.y-self.buffer
  local max_y = self.y+self.min.y+self.buffer
  if min_x>self.target.x then
   self.x=self.x+math.min(self.target.x-min_x,self.max.shift)
  end
  if max_x<self.target.x then
   self.x=self.x+math.min(self.target.x-max_x,self.max.shift)
  end
  if min_y>self.target.y then
   self.y=self.y+math.min(self.target.y-min_y,self.max.shift)
  end
  if max_y<self.target.y then
   self.y=self.y+math.min(self.target.y-max_y,self.max.shift)
  end
  self.x=math.min(math.max(0,self.x),self.max.x)
  self.y=math.min(math.max(0,self.y),self.max.y)
  self.cell.x=flr(self.x/8)
  self.cell.y=flr(self.y/8)
  self.offset.x=-(self.x%8)
  self.offset.y=-(self.y%8)
 end
 c.map=function(self)
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
 c.spr=function(self,sprite,x,y)
  spr(sprite,x-self.x,y-self.y,0)
 end
 return c
end

_init()

-- <TILES>
-- 000:7777777777777777777777777777777777777777777777777777777777777777
-- 001:9999999999999999999999999999999999999999999999999999999999999999
-- 002:4444444444444444444444444444444466666666666666666666666666666666
-- 003:6666666666666666666666666767676777777777777777777777777777777777
-- 004:7777777777777777777777777777777777777777777777777777777777777777
-- 005:1111111111111111111111111111111111111111111111111111111111111111
-- </TILES>

-- <PALETTE>
-- 000:0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77abffccaa
-- </PALETTE>

