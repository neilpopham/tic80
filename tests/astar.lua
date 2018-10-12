-- title:  
-- author: Neil Popham
-- desc:   
-- script: lua
-- input:  gamepad
-- saveid: 

add=table.insert
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
 --x=0,
 --y=0,
 create=function(self,x,y)
  local o={x=x,y=y}
  setmetatable(o,self)
  self.__index=self
  return o
 end,
 d2=function(self,cell)
  local dx=cell.x-self.x
  local dy=cell.y-self.y
  return dx^2+dy^2
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
 open={},
 closed={},
 ds=0,
 find=function(self,start,finish)
  self.start=start
  self.finish=finish
  add(self.open,astar:create(start.x,start.y,0,start:d2(finish)))
  self:_check_open()
 end,
 _check_open=function(self)
  local current=self:_get_next()
  if current==nil then
   return false
  else
   if current.x==self.finish.x and current.y==self.finish.y then
    local cell=current
    repeat
     cell=cell.parent
     print(cell.x..","..cell.y)
    until cell.parent==nil
    return
   end
   add(self.closed,current)
   self:_add_neighbours(current)
   del(self.open,current)
   self:_check_open()
  end
 end,
 _get_next=function(self)
  local best={0,32727}
  for i,vec in pairs(self.open) do
   if vec.h<best[2] then
    best={i,vec.h}
   end
  end
  return self.open[best[1]]
 end,
 _add_neighbours=function(self,current)
  local n={}
  for x=-1,1 do
   for y=-1,1 do
    if x~=0 and y~=0 then
     local tx=current.x+x
     local ty=current.y+y
     local tile=mget(tx,ty)
     if not fget(tile,0) then
      local exists=false
      for i,open in pairs(self.open) do
       if open.x==tx and open.y==ty then
        if current.g+1<open.g then
         open.g=current.g+1
         open.f=open.g+open.h
         open.parent=current
        end
        exists=true
        break
       end
      end
      if not exists then
       local cell=vec2:create(tx,ty)
       add(
        self.open,
        astar:create(tx,ty,current.g+1,cell:d2(self.finish),current)
       )
      end
     end
    end
   end
  end
 end
}

local s=vec2:create(10,10)
local f=vec2:create(20,20)
pathfinder:find(s,f)

function TIC()

end