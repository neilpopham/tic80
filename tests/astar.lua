-- title:  
-- author: Neil Popham
-- desc:   
-- script: lua
-- input:  gamepad
-- saveid: 

add=table.insert
sqrt=math.sqrt
function mget(x,y) return 0 end
function fget(x,y) return false end
function del(t,a)
 for i,v in ipairs(t) do
   if v==a then
    t[i]=t[#t]
    t[#t]=nil
      return
    end
  end
end

vec2={
 create=function(self,x,y)
  local o={x=x,y=y}
  setmetatable(o,self)
  self.__index=self
  return o
 end,
 distance=function(self,cell)
  local dx=cell.x-self.x
  local dy=cell.y-self.y
  return sqrt(dx^2+dy^2)
 end,
 manhattan=function(self,cell)
  return abs(cell.x-self.x)+abs(cell.y-self.y)
 end,
 index=function(self)
  return ((self.x+1)*16)+self.y
 end
}

astar={
 create=function(self,x,y,g,h,parent)
  local o=vec2:create(x,y)
  o.f=g+h
  o.g=g
  o.h=h
  o.parent=parent
  return o
 end
} setmetatable(astar,{__index=vec2})

pathfinder={
 find=function(self,start,finish)
  self.open={}
  self.closed={}
  self.path={}
  self.start=start
  self.finish=finish
  add(self.open,astar:create(start.x,start.y,0,start:distance(finish)))
  if self:_check_open() then
   return self.path
  end
 end,
 _check_open=function(self)
  local current=self:_get_next()
  if current==nil then
   return false
  else
   if current.x==self.finish.x and current.y==self.finish.y then
    local cell=current
    while cell.parent do
     add(self.path,vec2:create(cell.x,cell.y))
     cell=cell.parent
    end
    --add(self.path,vec2:create(cell.x,cell.y))
    return true
   end
   add(self.closed,current)
   self:_add_neighbours(current)
   del(self.open,current)
   self:_check_open()
   return true
  end
 end,
 _get_next=function(self)
  local best={0,32727}
  for i,vec in pairs(self.open) do
   if vec.f<best[2] then
    best={i,vec.f}
   end
  end
  return best[1]==0 and nil or self.open[best[1]]
 end,
 _add_neighbour=function(self,current,x,y)
  local tx=current.x+x
  local ty=current.y+y
  local tile=mget(tx,ty)
  if not fget(tile,0) then
   local exists=false
   local g=current.g+sqrt(x^2+y^2)   
   for _,closed in pairs(self.closed) do
    if closed.x==tx and closed.y==ty then
     exists=true
     break
    end
   end
   if not exists then 
    for _,open in pairs(self.open) do
     if open.x==tx and open.y==ty then
      if g<open.g then
       open.g=g
       open.f=open.g+open.h
       open.parent=current
      end     
      exists=true
      break
     end
    end
   end
   if not exists then
    local cell=vec2:create(tx,ty)
    add(
     self.open,
     astar:create(tx,ty,g,cell:distance(self.finish),current)
    )
   end
  end 
 end,
 _add_neighbours=function(self,current)
 --[[
  local offset={{0,-1},{1,0},{0,1},{-1,0}}
  for _,o in pairs(offset) do
   self:_add_neighbour(current,o[1],o[2])
  end
  ]]
  for x=-1,1 do
   for y=-1,1 do
    if not (x==0 and y==0) then
     self:_add_neighbour(current,x,y)
    end
   end
  end
 end
}

local s=vec2:create(5,10)
local f=vec2:create(20,20)
local path=pathfinder:find(s,f)
for _,v in pairs(path) do
  print(v.x..","..v.y)
end

function TIC()

end