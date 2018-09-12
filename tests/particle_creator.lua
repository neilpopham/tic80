--[[ standard ]]

local screen={width=240,height=136}

function round(x) return flr(x+0.5) end

add=table.insert
sqrt=math.sqrt
abs=math.abs
min=math.min
max=math.max
flr=math.floor
pi=math.pi
function rnd(a) a=a or 1 return math.random()*a end
--function cos(a) return math.cos(2*pi*a) end
--function sin(a) return -math.sin(2*pi*a) end
--function atan2(a,b) b=b or 1 return math.atan(a,b)/(2*pi) end
function cos(x) return math.cos((x or 0)*(math.pi*2)) end
function sin(x) return math.sin(-(x or 0)*(math.pi*2)) end
function atan2(x,y) return (0.75 + math.atan2(x,y) / (math.pi * 2)) % 1.0 end

__p8_camera_x=0
__p8_camera_y=0
function __p8_coord(x,y)
 return flr(x+__p8_camera_x),
         flr(y+__p8_camera_y)
end
function pset(x,y,c)
 c=c or __p8_color
  c=peek4(0x7FE0+c)
  x,y=__p8_coord(x,y)
 poke4(y*240+x,c)   
end
function sget(x,y)
 x,y=flr(x),flr(y)
 local addr=0x8000+64*(flr(x/8)+flr(y/8)*16)
  return peek4(addr+(y%8)*8+x%8)
end

-- __gff__ data
local sprf={0,1}

-- http://pico-8.wikia.com/wiki/Fget
function fget(s,i)
  if sprf[s+1]==nil then sprf[s+1]=0 end
  if i==nil then
    return math.floor(sprf[s+1])
  else
    local b=2^i
    return sprf[s+1] % (2*b) >= b
  end
end

-- http://pico-8.wikia.com/wiki/Fset
function fset(s,i,b)
  if b==nil then
    sprf[s+1]=i
  else
    local e
    if sprf[s+1]==nil then
      sprf[s+1]=0
      e=false
    else
      e=fget(s,i)
    end
    if (e and not b) or (not e and b) then 
      sprf[s+1]=sprf[s+1]+(b and 2^i or -2^i)
    end
  end
end

--[[ local ]]

function get_sprite_origin(s)
 local x=s*8 % 16
 local y=flr((s*8)/16)
 return {x,y}
end

function get_sprite_cols(s)
 local pos=get_sprite_origin(s)
 cols={}
 for dx=0,7 do
   cols[dx+1]={}
  for dy=0,7 do
   cols[dx+1][dy+1]=sget(pos[1]+dx,pos[2]+dy)
  end
 end
 return cols
end

function get_sprite_col_spread(s,ignore)
 ignore=ignore or 16
 local data=get_sprite_cols(s)
 local cols={}
 local total=0
 for dx=1,8 do
  for dy=1,8 do
   col=data[dx][dy]
   if col~=ignore then
    col=col+1
    if cols[col]==nil then cols[col]={count=0,percent=0} end
    cols[col].count=cols[col].count+1
    total=total+1
   end
  end
 end
 for i,_ in pairs(cols) do
  cols[i].percent=cols[i].count/total
 end
 return cols
end

function get_colour_array(s,count)
 local cols=get_sprite_col_spread(s)
 local array={}
 for i,col in pairs(cols) do
  local p=count*col.percent
  for c=1,p do
   add(array,i-1)
  end
 end
 return array
end

particle_types={}
particle_types.core=function(self,params)
 local t=params
 t.rand=function(min,max,floor)
  if floor==nil then floor=true end
  local v=(rnd()*(max-min))+min
  return floor and flr(v) or v
 end
 params.dx=params.dx or {min=6,max=12}
 params.dy=params.dy or t.dx
 t.x=t.x+t.rand(params.dx.min,params.dx.max)
 t.y=t.y+t.rand(params.dy.min,params.dy.max)
 t.dx=0
 t.dy=0
 params.lifespan=params.lifespan or {min=10,max=30}
 t.lifespan=t.rand(params.lifespan.min,params.lifespan.max)
 params.col=params.col or {min=1,max=15}
 if type(params.col)=="number" then
  t.col=params.col
 else
  t.col=t.rand(params.col.min,params.col.max)
 end

 return t
end
particle_types.smoke=function(self,params)
 params=params or {}
 local t=particle_types:core(params)
 params.max=params.max or {min=6,max=16}
 t.max=t.rand(params.max.min,params.max.max)
 params.min=params.min or {min=2,max=5}
 t.size=t.rand(params.min.min,params.min.max)
 t.step=(t.max-t.size)/t.lifespan
 t.draw=function(self)
  if self.lifespan==0 then return true end
  circfill(self.x,self.y,self.size,1)
  if self.size>1 then
   circfill(self.x,self.y,self.size-1,5)
   if self.size>2 then
    circfill(self.x,self.y,self.size-2,6)
    if self.size>3 then
     --circfill(self.x,self.y,self.size-3,7)
     --circfill(self.x,self.y,max(ceil(rnd(self.size-3)),self.size-(self.size/2)),7)
     --circfill(self.x+(self.size/6),self.y-(self.size/6),self.size/2,7)
     circfill(self.x+(self.size/12),self.y-(self.size/12),self.size/1.6,7)
    end
   end
  end
  self.size=self.size+self.step
  self.lifespan=self.lifespan-1
  return (self.lifespan==0)
 end
 return t
end
particle_types.spark=function(self,params)
 params=params or {}
 local t=particle_types:core(params)
 t.draw=function(self)
  if self.lifespan==0 then return true end
  --pset(self.x,self.y,self.col)
  rectb(self.x,self.y,1,1,self.col)
  self.lifespan=self.lifespan-1
  return (self.lifespan==0)
 end
 return t
end

particle_types.rect=function(self,params)
 params=params or {}
 local t=particle_types:core(params)
 params.size = params.size or {min=3,max=12}
 t.size=t.rand(params.size.min,params.size.max)
 t.draw=function(self)
  if self.lifespan==0 then return true end
  rect(self.x,self.y,self.size,self.size,self.col)
  self.lifespan=self.lifespan-1
  return (self.lifespan==0)
 end
 return t
end

particle_types.line=function(self,params)
 params=params or {}
 local t=particle_types:core(params)
 params.size = params.size or {min=3,max=12}
 t.size=t.rand(params.size.min,params.size.max)
 t.draw=function(self)
  if self.lifespan==0 then return true end
  line(self.x,self.y,self.x+(cos(self.angle)*self.size),self.y-(sin(self.angle)*self.size),self.col)
  self.lifespan=self.lifespan-1
  return (self.lifespan==0)
 end
 return t
end

--emitters
particle_emitters={}
particle_emitters.stationary=function(self,params)
 local e=params or {}
 e.angle=e.angle or {min=1,max=360}
 e.force=e.force or {min=1,max=3}
 e.emit=function(self,ps)
  for _,p in pairs(ps.particles) do
   p.angle=p.rand(self.angle.min,self.angle.max)/360
   p.force=p.rand(self.force.min,self.force.max,false)
  end
 end
 e.update=function(self,ps)
  -- do nothing
 end
 return e
end

-- affectors
particle_affectors={}

particle_affectors.force=function(self,params)
 local a=params or {}
 a.update=function(self,ps)
  for _,p in pairs(ps.particles) do
   if self.force then
    p.force=p.rand(self.force.min,self.force.max,false)
   elseif self.dforce then  
    p.force=p.force+p.rand(self.dforce.min,self.dforce.max,false)
   end
  end
 end
 return a
end


particle_affectors.randomise=function(self,params)
 local a=params or {}
 a.angle=a.angle or {min=1,max=360}
 a.update=function(self,ps)
  for _,p in pairs(ps.particles) do
   p.angle=(p.angle+(p.rand(a.angle.min,a.angle.max)/360)) % 1
  end
 end
 return a
end

particle_affectors.bounce=function(self,params)
 local a=params or {}
 a.force=a.force or 0.8
 a.halflife=a.halflife or 0.6
 a.update=function(self,ps)
  for _,p in pairs(ps.particles) do
   local h=false
   local x=p.x+p.dx y=p.y
   if x<0 or x>screen.width then
    h=true
   else
    tile=mget(flr(x/8),flr(y/8))
    if fget(tile,0) then h=true end
   end
   if h then
    p.force=p.force*self.force
    p.angle=(0.5-p.angle) % 1
   end
   local v=false
   local x=p.x y=p.y+p.dy
   if y<0 or y>screen.height then
    v=true
   else
    tile=mget(flr(x/8),flr(y/8))
    if fget(tile,0) then v=true end
   end
   if v then
    p.force=p.force*self.force
    p.angle=(1-p.angle) % 1
   end
   local dx=cos(p.angle)*p.force
   local dy=-sin(p.angle)*p.force
   if round(dx)==0 and round(dy)==0 then
    p.lifespan=flr(p.lifespan*self.halflife)
   end
  end
 end
 return a
end

particle_affectors.drag=function(self,params)
 local a=params or {}
 a.force=a.force or 0.98
 a.update=function(self,ps)
  for _,p in pairs(ps.particles) do
   p.force=p.force*a.force
  end
 end
 return a
end

particle_affectors.gravity=function(self,params)
 local a=params or {}
 a.force=a.force or 0.25
 a.update=function(self,ps)
  for _,p in pairs(ps.particles) do
   local dx=cos(p.angle)*p.force
   local dy=-sin(p.angle)*p.force
   dy=dy+self.force
   p.angle=atan2(dx,-dy)
   p.force=sqrt((dx*dx)+(dy*dy))
   --p.force=sqrt((dx^2)+(dy^2))
  end
 end
 return a
end

particle_affectors.heat=function(self,params)
 local a=params or {}
 a.cycle=a.cycle or {0.9,0.6,0.4,0.25}
 a.particles={}
 a.col={
  {0,0,1,1,2,1,5,6,2,4,9,3,13,5,4,9},
  {0,0,0,0,1,1,1,1,5,13,1,2,4,1,5,1,2,2}
 }
 a.update=function(self,ps)
  for i,p in pairs(ps.particles) do
   if self.particles[i]==nil then
    self.particles[i]={col=p.col,lifespan=p.lifespan}
   end
   local life=p.lifespan/self.particles[i].lifespan
   if life>self.cycle[1] then
    if i % 3==0 then p.col=10 else p.col=7 end
   elseif life>self.cycle[2] then
    p.col=self.particles[i].col
   elseif life>self.cycle[3] then
    p.col=self.col[1][self.particles[i].col+1]
   elseif life>self.cycle[4] then
    p.col=self.col[2][self.particles[i].col+1]
   else
    p.col=1
   end
  end
 end
 return a
end

particle_affectors.gravity_old=function(self,params)
 local a=params or {}
 a.force=a.force or 0.015
 a.update=function(self,ps)
  for _,p in pairs(ps.particles) do
   if p.angle>0.75 then
    p.angle=(p.angle+a.force) % 1
   elseif p.angle>0.25 then
    p.angle=p.angle-a.force
   elseif p.angle<0.25 then
    p.angle=p.angle+a.force
   end
   --]]
  end
 end
 return a
end

function create_particle_system(params)
 local s={
  particles={},
  emitters={},
  affectors={},
  complete=false
 }
 s.params=params or {}
 s.reset=function(self)
  self.complete=false
  self.particles={}
  self.params.count=0
 end
 s.add_particle=function(self,p)
  add(self.particles,p)
 end
 s.emit=function(self)
  self.params.count=#self.particles
  for _,e in pairs(self.emitters) do
   e:emit(self)
  end
 end
 s.update=function(self)
  if self.complete then return end
  for _,e in pairs(self.emitters) do
   e:update(self)
  end
  for _,a in pairs(self.affectors) do
   a:update(self)
  end
 end
 s.draw=function(self)
  if self.complete then return end
  local done=true
  for i,p in pairs(self.particles) do
   p.dx=cos(p.angle)*p.force
   p.dy=-sin(p.angle)*p.force
   p.x=p.x+p.dx
   p.y=p.y+p.dy
   local dead=self.particles[i]:draw()
   done=done and dead
  end
  --[[
  for i=1,self.params.count do
   local dead=self.particles[i]:draw()
   if dead then
    ----local oldp=self.particles[i]
    --self.particles[i]=self.particles[self.params.count]
    ----self.particles[self.params.count]=oldp
    --self.params.count=self.params.count-1
   end
   done=done and dead
  end
  ]]
  if done then self.complete=true end
 end
 return s
end

function create_smoke(x,y,count)
 local s=create_particle_system()
 s.params={x=x,y=y,count=count}
 s.emitters[1]=particle_emitters:stationary({x=x,y=y,force={min=0.2,max=0.6}})
 s.affectors[1]=particle_affectors:randomise({angle={min=-5,max=5}})
 --s.affectors[2]=particle_affectors:force({force=0.5})
 for i=1,count do
  s.particles[i]=particle_types:smoke({x=x,y=y,lifespan={min=10,max=50},dx={min=-16,max=16},dy={min=-16,max=16}})
  --s.particles[i]=particle_types:spark({x=x,y=y,lifespan={min=10,max=30},col={min=10,max=14}})
  --s.particles[i]=particle_types:rect({x=x,y=y,lifespan={min=10,max=30}})
 end
 s:emit()
 return s
end

function create_rect(x,y,count)
 local s=create_particle_system()
 s.params={x=x,y=y,count=count}
 s.emitters[1]=particle_emitters:stationary({x=x,y=y})
 s.affectors[1]=particle_affectors:randomise({angle={min=2,max=10}})
 s.affectors[2]=particle_affectors:force({force={min=1,max=3}})
 for i=1,count do
  s.particles[i]=particle_types:rect({x=x,y=y,lifespan={min=2,max=20}})
 end
 s:emit()
 return s
end

function create_spark(x,y,count)
 local s=create_particle_system({x=x,y=y,count=count})
 add(s.emitters,particle_emitters:stationary({x=x,y=y,force={min=2,max=6},angle={min=200,max=340}}))
 add(s.affectors,particle_affectors:gravity_old({force=0.02}))
 add(s.affectors,particle_affectors:bounce({force=0.6}))
 for i=1,count do
  s:add_particle(particle_types:spark({x=x,y=y,col={min=1,max=15},lifespan={min=100,max=240}}))
 end
 s:emit()
 return s
end

function create_spark_2(x,y,count)
 local s=create_particle_system({x=x,y=y,count=count})
 add(s.emitters,particle_emitters:stationary({x=x,y=y,force={min=4,max=10},angle={min=240,max=300}}))
 add(s.affectors,particle_affectors:gravity({force=0.3}))
 add(s.affectors,particle_affectors:bounce({force=0.6}))
 for i=1,count do
  s:add_particle(particle_types:spark({x=x,y=y,col={min=1,max=15},lifespan={min=160,max=480}}))
 end
 s:emit()
 return s
end

function create_line(x,y,count)
 local s=create_particle_system({x=x,y=y,count=count})
 add(s.emitters,particle_emitters:stationary({x=x,y=y,force={min=2,max=3},angle={min=1,max=360}}))
 --add(s.affectors,particle_affectors:bounce({force=0.9}))
	add(s.affectors,particle_affectors:drag({force=0.97}))
 for i=1,count do
  s:add_particle(particle_types:line({x=x,y=y,col={min=1,max=15},lifespan={min=20,max=100}}))
 end
 s:emit()
 return s
end

function create_sprite_exploder(sprite,x,y,count)
 local s=create_particle_system({x=x,y=y,count=count,sprite=sprite})
 add(s.emitters,particle_emitters:stationary({x=x,y=y,force={min=2,max=6},angle={min=240,max=300}}))
 add(s.affectors,particle_affectors:gravity({force=0.25}))
 add(s.affectors,particle_affectors:bounce({force=0.5}))
 add(s.affectors,particle_affectors:heat())
 local cols=get_colour_array(sprite,count)
 for i=1,count do
  s:add_particle(particle_types:spark({x=x,y=y,col=cols[i],lifespan={min=160,max=480}}))
 end
 s:emit()
 return s
end

function _init()
 p=create_spark_2(40+rnd(160),40+rnd(48),flr(rnd(20)+20))
end

function _update60()
 if btnp(4) then
  p=create_smoke(40+rnd(160),40+rnd(48),flr(rnd(20)+10))
 end
 if btnp(5) then
  p=create_rect(40+rnd(160),40+rnd(48),flr(rnd(200)+200))
 end
 if btnp(0) then
  p=create_spark(40+rnd(160),40+rnd(48),flr(rnd(50)+50))
 end
 if btnp(1) then
  p=create_line(40+rnd(160),40+rnd(48),flr(rnd(50)+50))
 end
 if btnp(2) then
  p=create_spark_2(40+rnd(160),40+rnd(48),flr(rnd(150)+250))
 end
 if btnp(3) then
  p=create_sprite_exploder(1,40+rnd(48),40+rnd(48),flr(rnd(150)+150))
 end
 p:update()
 _draw()
end

function _draw()
 cls()
 map(0,0)
 p:draw()
end

function TIC() _update60() end

_init()

-- <TILES>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- </TILES>

-- <PALETTE>
-- 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

