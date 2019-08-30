particle={
 create=function(self,params)
  params=params or {}
  params.life=params.life or {60,120}
  params.angle=mrnd(params.angle,false)
  params.force=mrnd(params.force,false)
  local o=params
  o=extend(o,{x=params.x,y=params.y,life=mrnd(params.life),complete=false})
  setmetatable(o,self)
  self.__index=self
  return o
 end,
 draw=function(self,fn)
  self:_draw()
  self.life=self.life-1
  if self.life==0 then self.complete=true end
 end
}

spark={
 _draw=function(self)
  pset(self.x,round(self.y),self.col)
 end
} setmetatable(spark,{__index=particle})

circle={
 _draw=function(self)
  circfill(self.x,self.y,self.size,self.col)
 end
} setmetatable(circle,{__index=particle})

affector={

 gravity=function(self)
  local dx=cos(self.angle)*self.force
  local dy=-sin(self.angle)*self.force
  dy=dy+self.g
  self.angle=atan2(dx,-dy)
  self.force=sqrt(dx^2+dy^2)
  self.dx=cos(self.angle)*self.force
  self.dy=-sin(self.angle)*self.force
 end,

 bounce=function(self)
  local x,y=self.x+self.dx,self.y
  local tile=mget(flr(x/8),flr(y/8))
  if fget(tile,0) then
   self.force=self.force*self.b
   self.angle=(0.5-self.angle)%1
  end
  x,y=self.x,self.y+self.dy
  tile=mget(flr(x/8),flr(y/8))
  if fget(tile,0) then
   self.force=self.force*self.b
   self.angle=(1-self.angle)%1
  end
  self.dx=cos(self.angle)*self.force
  self.dy=-sin(self.angle)*self.force
 end,

 size=function(self)
  self.size=self.size*self.shrink
  if self.size<0.5 then self.complete=true end
 end,

 shells=function(self)
  affector.gravity(self)
  affector.bounce(self)
  affector.update(self)
 end,

 smoke=function(self)
  self.dx=cos(self.angle)*self.force
  self.dy=-sin(self.angle)*self.force
  affector.size(self)
  affector.update(self)
 end,

 update=function(self)
  self.x=self.x+self.dx
  self.y=self.y+self.dy
 end
}

shells={
 create=function(self,x,y,count,params)
  for i=1,count do
   local s=spark:create(
    extend(
     {
      x=x,
      y=y,
      life={30,50},
      force={1,2},
      g=0.2,
      b=0.7,
      angle={0.6,0.9}
     },
     params
    )
   )
   s.update=affector.shells
   particles:add(s)
  end
 end
}

smoke={
 create=function(self,x,y,count,params)
  for i=1,count do
   local s=circle:create(
    extend(
     {
      x=x,
      y=y,
      delay=0,
      col=7,
      life={10,20},
      force={0.3,1.2},
      angle={0,1},
      size={4,6},
      shrink=0.8
     },
     params
    )
   )
   if params.size then s.size=mrnd(params.size) end
   s.update=affector.smoke
   particles:add(s)
  end
 end
}

function doublesmoke(x,y,count,params)
 smoke:create(x,y,count[1],params[1])
 smoke:create(x+rnd(3),y-rnd(3),count[2],params[2])
 shells:create(x,y,count[3],params[3])
end
