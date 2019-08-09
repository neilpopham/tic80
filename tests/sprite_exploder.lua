-- title:  sprite_exploder
-- author: Neil Popham
-- desc:   Particle system test exploding food with accurate colours
-- script: lua
-- input:  gamepad

--[[ core ]]

local screen={width=240,height=136}
local pad={left=2,right=3,up=0,down=1,btn1=4,btn2=5,btn3=6,btn4=7}

function round(x) return flr(x+0.5) end

--[[ pico-8 functions ]]

add=table.insert
sqrt=math.sqrt
abs=math.abs
min=math.min
max=math.max
flr=math.floor
function rnd(a) a=a or 1 return math.random()*a end
function cos(x) return math.cos((x or 0)*(math.pi*2)) end
function sin(x) return math.sin(-(x or 0)*(math.pi*2)) end
function atan2(x,y) return (0.75 + math.atan2(x,y) / (math.pi * 2)) % 1.0 end
function pset(x,y,c) pix(x,y,c) end
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

--[[ sprite data functions ]]

-- returns the position of the specified sprite in the sprite sheet
-- s is the sprite index
function get_sprite_origin(s)
 local x=(s*8) % 128
 local y=flr(s/16)*8
 return {x,y}
end

-- returns a multi-dimensional array
-- with the colour for each pixel in the sprite
-- cols[x][y]=colour
-- s is the sprite index
function get_sprite_cols(s)
 local pos=get_sprite_origin(s)
 local cols={}
 for dx=0,7 do
   cols[dx+1]={}
  for dy=0,7 do
   cols[dx+1][dy+1]=sget(pos[1]+dx,pos[2]+dy)
  end
 end
 return cols
end

-- retuns an array with the pixel count and overall percentage
-- for each colour in the sprite
-- s is the sprite index
-- ignore is the colour index to ignore (e.g.: 0) when calculating values
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

-- returns an array of colours in the correct proportion
-- s is the sprite index
-- count is the number of values to return*
-- ignore is the colour index to ignore (e.g.: 0) when calculating values
-- * may return more than asked for
--   but as long as we loop through this array to add the particles
--   we don't care if we have a few too many
function get_colour_array(s,count,ignore)
 local cols=get_sprite_col_spread(s,ignore)
 local array={}
 for i,col in pairs(cols) do
  local p=round(count*col.percent)
  for c=1,p do
   add(array,i-1)
  end
 end
 return array
end

-- don't want to use get_sprite_origin(), get_sprite_cols() or get_sprite_col_spread() elsewhere?
-- this function does the same as get_colour_array() but is self-contained
-- so you can delete the previous four
-- same disclaimer applies
function get_colour_array_simple(s,count,ignore)
 local x=(s*8) % 128
 local y=flr(s/16)*8
 local col={}
 local list={}
 local total=0
 for dx=0,7 do
  for dy=0,7 do
   local c=sget(x+dx,y+dy)
   if c~=ignore then
    if col[c+1]==nil then col[c+1]=0 end
    col[c+1]=col[c+1]+1
    total=total+1
   end
  end
 end
 local r=count/total
 for c,t in pairs(col) do
  for i=1,round(r*t) do
   add(list,c-1)
  end
 end
 return list
end

--[[ particle system functions ]]

--[[ particles ]]

particle_types={}
particle_types.core=function(self,params)
 local t=params
 t.rand=function(min,max,floor)
  if floor==nil then floor=true end
  local v=(rnd()*(max-min))+min
  return floor and flr(v) or v
 end
 params.dx=params.dx or {min=0,max=7}
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
particle_types.spark=function(self,params)
 params=params or {}
 local t=particle_types:core(params)
 t.draw=function(self)
  if self.lifespan==0 then return true end
  pset(self.x,self.y,self.col)
  self.lifespan=self.lifespan-1
  return self.lifespan==0
 end
 return t
end

--[[ emitters ]]

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

--[[ affectors ]]

particle_affectors={}

particle_affectors.decay=function(self,params)
 local a=params or {}
 a.decay=a.decay or 0.6
 a.update=function(self,ps)
  for _,p in pairs(ps.particles) do
   local dx=cos(p.angle)*p.force
   local dy=-sin(p.angle)*p.force
   if round(dx)==0 and round(dy)==0 then
    p.lifespan=flr(p.lifespan*self.decay)
   end
  end
 end
 return a
end
particle_affectors.bounce=function(self,params)
 local a=params or {}
 a.force=a.force or 0.8
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
   p.force=sqrt((dx^2)+(dy^2))
  end
 end
 return a
end
particle_affectors.heat=function(self,params)
 local a=params or {}
 a.cycle=a.cycle or {0.9,0.6,0.4,0.25}
 a.particles={}
 a.col={
  {1,1,1,1,2,1,5,6,2,4,9,3,13,5,4,9},
  {1,1,1,1,1,1,1,1,5,13,1,2,4,1,5,1,2,2}
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

--[[ system ]]

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
  if self.complete then return false end
  local done=true
  for i,p in pairs(self.particles) do
   p.dx=cos(p.angle)*p.force
   p.dy=-sin(p.angle)*p.force
   p.x=p.x+p.dx
   p.y=p.y+p.dy
   local dead=self.particles[i]:draw()
   done=done and dead
  end
  if done then self.complete=true end
  return true
 end
 return s
end

function create_sprite_exploder(sprite,x,y,count)
 local s=create_particle_system({x=x,y=y,count=count,sprite=sprite})
 add(s.emitters,particle_emitters:stationary({x=x,y=y,force={min=4,max=7},angle={min=240,max=320}}))
 add(s.affectors,particle_affectors:gravity({force=force.g}))
 add(s.affectors,particle_affectors:bounce({force=force.b}))
 add(s.affectors,particle_affectors:decay())
 if use_heat then
  add(s.affectors,particle_affectors:heat())
 end
 local cols=get_colour_array_simple(sprite,count,0)
 for _,c in pairs(cols) do
  s:add_particle(particle_types:spark({x=x,y=y,col=c,lifespan={min=160,max=480}}))
 end
 s:emit()
 return s
end

function reset()
 sprite={
  x=screen.width/2-4, --flr((rnd()*(48))+40),
  y=80, --flr((rnd()*(48))+40),
  index=flr((rnd()*(95))+1),
  bits=false
 }
 cols=get_colour_array_simple(sprite.index,screen.width,0)
end

function _init()
 reset()
 force={g=0.3,b=0.6}
 use_heat=false
end

function _update60()
 if btnp(pad.left) then force.g=round((force.g-0.05)*100)/100 end
 if btnp(pad.right) then force.g=round((force.g+0.05)*100)/100 end
 if btnp(pad.up) then force.b=round((force.b+0.05)*100)/100 end
 if btnp(pad.down) then force.b=round((force.b-0.05)*100)/100 end
 if btnp(pad.btn2) then use_heat=not use_heat end
 if btnp(pad.btn1) and not sprite.bits then
  sprite.bits=true
  parts=create_sprite_exploder(sprite.index,sprite.x,sprite.y,flr(rnd(63)+64))
 end
 if sprite.bits then parts:update() end
 _draw()
end

function _draw()
 cls()
 -- draw colour spread
 for i=1,#cols do
  pset(i-1,0,cols[i])
 end
 -- draw sprite or explosion
 if not sprite.bits then
  spr(sprite.index,sprite.x,sprite.y)
 else
  if not parts:draw() then reset() end
 end
 -- hud
 print("gravity: "..force.g,0,3,7)
 print("bounce:  "..force.b,0,10,7)
 print("heat:    "..(use_heat and "on" or "off"),0,17,10)
end

function TIC() _update60() end

_init()

-- <TILES>
-- 001:000043b0000bb03b00babb0000babb000babbb300babbb3003bbb33000333300
-- 002:00000aa00000009a00000949aaaaaa4a9aaaa4aa49944aaa9aaaaaa009aaaa00
-- 003:0b0b0b0000bbb000093b40009494940049494400949494004949440004444000
-- 004:00fffe000fffffe0fffffffefffffffeefeffffe0eeeffe0bbeeeeeb0000bbb0
-- 005:00000b000888b88087e888888e88888888888888888888880888888000888800
-- 006:0000000000000000780888877888808778808887b788887b3b7777b303bbbb30
-- 007:0000bbb0000b0b0000b00b0000b0088008808878887808888888088008800000
-- 008:0088bb0009993b809aa999889aa99988999999889a9999880999988000888800
-- 009:0f4444f0f24ffffff4ff444ff24fff2f7f2222f7f777777f9ffffff909999990
-- 010:0000004000000f490000f7f90ff77fa9f77ffa90f7ffa9009faa990009999000
-- 011:000000000000000004444ff04244fe8f4442f87f2444f88f2222f8ef02222ff0
-- 012:0bb0bbb0b0bbb0bb000b00000eeeee00effeffe0777f77700777770000070000
-- 013:999900004449990098944990888aa490989aa499aaaa8849a88a8849a88aa949
-- 014:0000033000099aa30b9994a3ba444ab3baaaab333bbbb3300333330000333000
-- 015:087883b00788bb3b2988bb8b8889888888888888898888802888200000088800
-- 016:0eeee000eeeeeeeeee788888eeeeeeee7eeee667d6776ddddddddddd0dddd000
-- 017:0777770077777a707a77799079a799770799aa0707aaaa070aaaaa7004999400
-- 018:00077770000cccc0ccdccccc0cdccccc0077777700cccccc00cccccc00777777
-- 019:0000000077777700777777777777770777777770d7777d000d66d00077777700
-- 020:7777770077777d7777777607777776077777760777777d7067776600d6666d00
-- 021:7222222778788887787888877888888707222270007227000007700000777700
-- 022:070009900070977907cc9c790799997007999970007777000007700000777700
-- 023:0000aaa00009a99a0008a89a098aaaaaaaaa88aa889822898899889999999999
-- 024:000bb00000b3133b0b31bb300b37bb1bb3fbb13b3bbb33b00bb3bb00003b0000
-- 025:070000700779997007a99970079999700779997007999970079999700d7777d0
-- 026:009919000c199990911a911999a9911949999994044444400949494002494920
-- 027:00008880007728880c7c7888cc17772801cc7c70044c1770ff41cc00ff00c000
-- 028:00000000030bb030083333808383383887e888888e8888888888888808888880
-- 029:000887700078877707777777777777774ff44ff4f44ff44f44444444f777777f
-- 030:0bbbbbb0b303303bb3b77b0bb033033b2bbbbbb2222222222244444202244420
-- 031:0000e8800800028008e088020882e28000880e820000202800000088008eee00
-- 032:029220002429f22042442942244244f924244f7f0224f7790024ff9000024400
-- 033:9aaaaaa9a99a99a9a94a94a9aaaaaaaaa99a99a9a94a94a9aaaaaaaaa99a99a9
-- 034:0224000092274000f9227400ff9227400ff9227400ff9222000ff9220000ff90
-- 035:0004499000fff49904499f49fff49999999f4999999999944999994004444400
-- 036:004444000499494094a4a994a000a944000004a4000009a900000aa000000a00
-- 037:000ffff0000999ff00ffff9f0fffff94fff9888f8882282f8822fff0ffff0000
-- 038:044aa440444aa444f444444f4f2ffff4f424444f4f4ffff4f444444f0f4ffff0
-- 039:000000000ff00ff0f99ff99f9009900990099009499449940040040009000090
-- 040:0000033b0003ab3b0033bb3b03ab33bb33bb3bb0ab33bb00bb3bb00033bb0000
-- 041:00000000000000d076666d670768b67000733700000770000007700000777700
-- 042:0004990009490040900909949009900977777777d777777d067777600d7777d0
-- 043:009999000999999099bbbb999b4b88b9b444888b4aaaaaa8aaaaaaaa99999999
-- 044:00fffff007fee8ef7eefeeef7e8effef7e88eef7477777744444444404888840
-- 045:048e8400048e84000048f8400048f840048f8400048f84000048e8400048e840
-- 046:0000000b00cc0c7000111cc00c1c71100c1cc1c7011111ccc1c71110c1cc0cc0
-- 047:07f8efe0077f8ee80077228e80008eef8800288888e8eef000ee8e00000000b3
-- 048:0007000000077070000f2077002442f002444240042444404424244044244200
-- 049:0424424024444442242442422444444262222226677777764777777422222222
-- 050:0048e8400484848428e828888484848488288828228484822222222202444420
-- 051:00000bb000000bb300007bb3000bbb3000bbb3003bbb3b003bb3300003330000
-- 052:00bb00bb00bbb0bb00003b30000030b30088b0bb088880000e888000fee80000
-- 053:000bb0bb0000b3bb00009b30000999bb009f990b09a990000999000099000000
-- 054:0000000000000066000006600079440007794420d77a922d6dddddd606666660
-- 055:0f4444f0ffffffffffffffff04444440077aa770f999999fffffffff0ffffff0
-- 056:0cc00cc0cc7ccc7ccccdcc7dcccdcccdcccdcccdcccccccc044004400ff00ff0
-- 057:00d76d00088888800888887008e777e00e777e80078888800888888000d6dd00
-- 058:000000000000000000888900088977a0228977aa08899aaa08899aab0088aab0
-- 059:000099f0000fff9f00ffff4f0444ff494ff94499f388f990f44499000ff99000
-- 060:088800008788e0008888e200888e28000ee28200002827000000007000000007
-- 061:07000bb00078867b007ee67b07eeee6007eeee70007ee7000007700000777700
-- 062:0008b000008bbb0003bbbbb003333bb00bbbb3b088bbbb0088bbb30003333000
-- 063:0007773300777760077777600777766067776600677660006660000000090900
-- 064:0004bbb0000403bb02e0223b2fe208202e220820222282202222222002222200
-- 065:0000b00b00003bb30002e2b00227223b2ef22220222222202222220002222000
-- 066:0007700000777700077774400774444004444440099999900044440000999900
-- 067:00004406044aa466049a9a600aa9a99099a8a897789898877799997707777770
-- 068:0b7777b0b788aa7bb7ff887b0b7777b030000003333333333333333303333330
-- 069:00ffff000ffffff0ffffffffffffffff00044400000fff0000ffff0000fff000
-- 070:4992499244424442222022204992499244424442222022204992499244424442
-- 071:00ffff000ff4fff0fffff44ff24ff42ff22fffffffff44ff0f4f42f000ffff00
-- 072:0004044000994900099f9490947f994994fa994992a999290929929000044000
-- 073:000dd000000770000024420000444400004bb400007bb700004bb40000244200
-- 074:00777700077777700777777077a99a77779999777799997707a99a7000777700
-- 075:000000000979997097999799f999f999999f999f949444494f7777f007777770
-- 076:00b33b000737b3b0b37bbb3bb3bbb3b7bb333b7b3bb3bbb3b33b33330bb33330
-- 077:00444400042442400424424004244240042442400444444000022000000ff000
-- 078:0033330033ffff3337777ff3bff7ff77377f77f33f7f773bb3fff3bb0b333bb0
-- 079:9049090994494949494949940999999007777770067777600d7777d000bb03b3
-- 080:00ff00ff0094499f000fff900ff9f440f99f4ff09aa409909aa4000009400000
-- 081:0999999099999999888888883aaaaaa3444aa444444444449999999909999990
-- 082:000f80000ee88ee0e8ee8ee8ee8ee8ee8888888807f7f7f00f9f9f900f9f9f90
-- 083:0bb009a900bb9a9a33b9a9a90b9a9a900ba9a9b00bba9bbbb3bbb30bbb000300
-- 084:0000040077fff4f90877ffff088877ff77bb887700778888000077bb00000077
-- 085:0000000000000000099999909a88aa8988aa88a8888888889999999909999990
-- 086:00000000003333000303b33033333b333b3333330bbb33300bab3333babbb333
-- 087:0000077000000777099977779999970099999400949994004999440004444000
-- 088:0006060000066000000dd0000067660006776760767767677677676700000000
-- 089:0000f9f0000f9f9f0009f4f90f9f4f99f9f9f9909f4f9000f4f9900000000000
-- 090:077b33007aa7bb307a27b7b37aa7bbb372a7b3337aa7bbb37a27bb3000000000
-- 091:02222220222222222400004222f4442242222224944444499f4ffff900000000
-- 092:00aaaaa00aaaaa99aaaaaaa9aaaaaaa9aa9aaaa9aaa9a999bba9999000000000
-- 093:000b000000033000099449909a9999999a9aa9a99a9aa9a99a4aa9a900000000
-- 094:0000000000004440004f4442044444f244444442494444202444420000000000
-- 095:0bb33bbb0b33bb330b3bb33006363bbb077bbbb3777633307700000000000000
-- 096:000000000000004000000f490000f7f90ff77fa9f77ffa90f7ffa9009faa9900
-- 097:00000000000000000000000004444ff04244fe8f4442f87f2444f88f2222f8ef
-- 098:000000000bb0bbb0b0bbb0bb000b00000eeeee00effeffe0777f777007777700
-- 099:00000000999900004449990098944990888aa490989aa499aaaa8849a88a8849
-- 100:000000000000033000099aa30b9994a3ba444ab3baaaab333bbbb33003333300
-- 101:0000000000777700077777700777777077a99a77779999777799997707a99a70
-- 102:bb003330000000000979997097999799f999f999999f999f949444494f7777f0
-- 103:0000000000b33b000737b3b0b37bbb3bb3bbb3b7bb333b7b3bb3bbb3b33b3333
-- 104:09999000009919000c199990911a911999a99119499999940444444009494940
-- 105:02222ff000008880007728880c7c7888cc17772801cc7c70044c1770ff41cc00
-- 106:0007000000000000030bb030083333808383383887e888888e88888888888888
-- 107:a88aa949000887700078877707777777777777774ff44ff4f44ff44f44444444
-- 108:003330000bbbbbb0b303303bb3b77b0bb033033b2bbbbbb22222222222444442
-- 109:00777700077b33007aa7bb307a27b7b37aa7bbb372a7b3337aa7bbb37a27bb30
-- 110:0777777002222220222222222400004222f4442242222224944444499f4ffff9
-- 111:0bb3333000aaaaa00aaaaa99aaaaaaa9aaaaaaa9aa9aaaa9aaa9a999bba99990
-- </TILES>

-- <PALETTE>
-- 000:0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77abffccaa
-- </PALETTE>

-- <COVER>
-- 000:295000007494648393160f00880077000012ffb0e45445353414055423e2033010000000129f40402000ff00c2000000000f00880078ff00d4ff3a00ffce72004e63007815000000ff1f8e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080ff001080c1840b0a1c388031a2c58c03083c780132a4c9841b2a5cb88133a6cd820a3a7cf8023467c1042b4a943940256ac20c2b5abc790336acc9943b6adcb98337aecd9c3b7afcf90438a0d1a44b8a1d3a8439ac430608523d99f4f523d6ae27a6455a853ba6dda053aa5d69f5db65d0be4b9e5d2b50ec285aac5bdabd7b249ae351b27dcacd4b571c2ad89353d2c45b0730b0e1cf73c2b5fb87bc6ed4cb67ee166c67113062c49b2bb57c25bfa3d5bd87c23e1bb853b5e1d4a1ba8e2a7ab4bae5dcab5bbe7d0b93b9e7c99967ae8d8bd5f755cb7dee5ddda9723ad3b2c37b1f2d47fe62fdc2a137dceb7877f1f9e8c59b576e6d9d637ad2b32b85ae0eb2b4fffde1a517dd5cb4dbe9f0fcebdbbf7f0f3ebcf9ff3b3ee4bfc21f705f8d29f3dfff44d74df9e720284508e7939f770a00e212800e385f13870e2841a488f9387f958b02f760248e12f471e68df5e761a4841ae412e9842e78c26689f19862a0803aa890218622d8d26e8a3ee8c36f8e3ef80460924e094461964e1984629a4e29c4639e4e390564925e494565965e5985669a5e69c5679e5e790668926e894669966e99866a9a6ea9c66b9e6eb9076c927ec9476d967ed9876e9a7ee9c76f9e7ef90860a28e0a4861a68e1a8862aa8e2ac863ae8e3a0964a29e4a4965a69e5a8966aa9e6ac967ae9e7a06a044218a59d3440c000009a38500d1d34209aa181bc5a208ba9a2caf6944faadae61ba015eaab6b5db6dafbab540d0b6ce1b8c62bace2bcc63bece3b0d64b2de4b4d65b6de5b8d66bade6bcd67bede7b0e68b2ee8b4e69b6ee9b8e6abaeeabce6bbeeebb0f6cb2fecb4f6db6fedb8f24a10100b3
-- </COVER>

