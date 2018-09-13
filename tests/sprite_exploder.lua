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
function pset(x,y,c) rectb(x,y,1,1,c) end
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
 add(s.emitters,particle_emitters:stationary({x=x,y=y,force={min=3,max=6},angle={min=240,max=320}}))
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
 print("gravity: "..force.g,0,3,15)
 print("bounce:  "..force.b,0,10,15)
 print("heat:    "..(use_heat and "on" or "off"),0,17,14)
end


function TIC() _update60() end

_init()


-- <TILES>
-- 001:000045b0000bb05b00bebb0000bebb000bebbb500bebbb5005bbb55000555500
-- 002:00000ee00000009e00000949eeeeee4e9eeee4ee49944eee9eeeeee009eeee00
-- 003:0b0b0b0000bbb000095b40009494940049494400949494004949440004444000
-- 004:00ccc8000ccccc80ccccccc8ccccccc88c8cccc80888cc80bb88888b0000bbb0
-- 005:00000b000666b6606f8666666866666666666666666666660666666000666600
-- 006:0000000000000000f606666ff666606ff660666fbf6666fb5bffffb505bbbb50
-- 007:0000bbb0000b0b0000b00b0000b00660066066f666f606666666066006600000
-- 008:0066bb0009995b609ee999669ee99966999999669e9999660999966000666600
-- 009:0c4444c0c24cccccc4cc444cc24ccc2cfc2222cfcffffffc9cccccc909999990
-- 010:0000004000000c490000cfc90ccffce9cffcce90cfcce9009cee990009999000
-- 011:000000000000000004444cc04244c86c4442c6fc2444c66c2222c68c02222cc0
-- 012:0bb0bbb0b0bbb0bb000b0000088888008cc8cc80fffcfff00fffff00000f0000
-- 013:999900004449990096944990666ee490969ee499eeee6649e66e6649e66ee949
-- 014:0000055000099ee50b9994e5be444eb5beeeeb555bbbb5500555550000555000
-- 015:06f665b00f66bb5b2966bb6b6669666666666666696666602666200000066600
-- 016:088880008888888888f6666688888888f8888aaf3affa3333333333303333000
-- 017:0fffff00fffffef0fefff990f9ef99ff0f99ee0f0feeee0f0eeeeef004999400
-- 018:000ffff0000dddd0dd3ddddd0d3ddddd00ffffff00dddddd00dddddd00ffffff
-- 019:00000000ffffff00ffffffffffffff0ffffffff03ffff30003aa3000ffffff00
-- 020:ffffff00fffff3fffffffa0ffffffa0ffffffa0ffffff3f0afffaa003aaaa300
-- 021:f222222ff6f6666ff6f6666ff666666f0f2222f000f22f00000ff00000ffff00
-- 022:0f00099000f09ff90fdd9df90f9999f00f9999f000ffff00000ff00000ffff00
-- 023:0000eee00009e99e0006e69e096eeeeeeeee66ee669622696699669999999999
-- 024:000bb00000b5155b0b51bb500b5fbb1bb5cbb15b5bbb55b00bb5bb00005b0000
-- 025:0f0000f00ff999f00fe999f00f9999f00ff999f00f9999f00f9999f003ffff30
-- 026:009919000d199990911e911999e9911949999994044444400949494002494920
-- 027:0000666000ff26660dfdf666dd1fff2601ddfdf0044d1ff0cc41dd00cc00d000
-- 028:00000000050bb05006555560656556566f866666686666666666666606666660
-- 029:00066ff000f66fff0fffffffffffffff4cc44cc4c44cc44c44444444cffffffc
-- 030:0bbbbbb0b505505bb5bffb0bb055055b2bbbbbb2222222222244444202244420
-- 031:0000866006000260068066020662826000660862000020260000006600688800
-- 032:029220002429c22042442942244244c924244cfc0224cff90024cc9000024400
-- 033:9eeeeee9e99e99e9e94e94e9eeeeeeeee99e99e9e94e94e9eeeeeeeee99e99e9
-- 034:02240000922f4000c922f400cc922f400cc922f400cc9222000cc9220000cc90
-- 035:0004499000ccc49904499c49ccc49999999c4999999999944999994004444400
-- 036:004444000499494094e4e994e000e944000004e4000009e900000ee000000e00
-- 037:000cccc0000999cc00cccc9c0ccccc94ccc9666c6662262c6622ccc0cccc0000
-- 038:044ee440444ee444c444444c4c2cccc4c424444c4c4cccc4c444444c0c4cccc0
-- 039:000000000cc00cc0c99cc99c9009900990099009499449940040040009000090
-- 040:0000055b0005eb5b0055bb5b05eb55bb55bb5bb0eb55bb00bb5bb00055bb0000
-- 041:0000000000000030faaaa3af0fa6baf000f55f00000ff000000ff00000ffff00
-- 042:00049900094900409009099490099009ffffffff3ffffff30affffa003ffff30
-- 043:009999000999999099bbbb999b4b66b9b444666b4eeeeee6eeeeeeee99999999
-- 044:00ccccc00fc8868cf88c888cf868cc8cf86688cf4ffffff44444444404666640
-- 045:04686400046864000046c6400046c640046c6400046c64000046864000468640
-- 046:0000000b00dd0df000111dd00d1df1100d1dd1df011111ddd1df1110d1dd0dd0
-- 047:0fc68c800ffc688600ff22686000688c66002666668688c000886800000000b5
-- 048:000f0000000ff0f0000c20ff002442c002444240042444404424244044244200
-- 049:04244240244444422424424224444442a222222aaffffffa4ffffff422222222
-- 050:0046864004646464268626666464646466266626226464622222222202444420
-- 051:00000bb000000bb50000fbb5000bbb5000bbb5005bbb5b005bb5500005550000
-- 052:00bb00bb00bbb0bb00005b50000050b50066b0bb0666600008666000c8860000
-- 053:000bb0bb0000b5bb00009b50000999bb009c990b09e990000999000099000000
-- 054:00000000000000aa00000aa000f944000ff944203ffe9223a333333a0aaaaaa0
-- 055:0c4444c0cccccccccccccccc044444400ffeeff0c999999ccccccccc0cccccc0
-- 056:0dd00dd0ddfdddfdddd3ddf3ddd3ddd3ddd3ddd3dddddddd044004400cc00cc0
-- 057:003fa30006666660066666f0068fff8008fff8600f66666006666660003a3300
-- 058:0000000000000000006669000669ffe02269ffee06699eee06699eeb0066eeb0
-- 059:000099c0000ccc9c00cccc4c0444cc494cc94499c566c990c44499000cc99000
-- 060:066600006f66800066668200666826000882620000262f00000000f00000000f
-- 061:0f000bb000f66afb00f88afb0f8888a00f8888f000f88f00000ff00000ffff00
-- 062:0006b000006bbb0005bbbbb005555bb00bbbb5b066bbbb0066bbb50005555000
-- 063:000fff5500ffffa00fffffa00ffffaa0afffaa00affaa000aaa0000000090900
-- 064:0004bbb0000405bb0280225b2c82062028220620222262202222222002222200
-- 065:0000b00b00005bb5000282b0022f225b28c22220222222202222220002222000
-- 066:000ff00000ffff000ffff4400ff4444004444440099999900044440000999900
-- 067:0000440a044ee4aa049e9ea00ee9e99099e6e69ff696966fff9999ff0ffffff0
-- 068:0bffffb0bf66eefbbfcc66fb0bffffb050000005555555555555555505555550
-- 069:00cccc000cccccc0cccccccccccccccc00044400000ccc0000cccc0000ccc000
-- 070:4992499244424442222022204992499244424442222022204992499244424442
-- 071:00cccc000cc4ccc0ccccc44cc24cc42cc22ccccccccc44cc0c4c42c000cccc00
-- 072:0004044000994900099c949094fc994994ce994992e999290929929000044000
-- 073:00033000000ff0000024420000444400004bb40000fbbf00004bb40000244200
-- 074:00ffff000ffffff00ffffff0ffe99effff9999ffff9999ff0fe99ef000ffff00
-- 075:0000000009f999f09f999f99c999c999999c999c949444494cffffc00ffffff0
-- 076:00b55b000f5fb5b0b5fbbb5bb5bbb5bfbb555bfb5bb5bbb5b55b55550bb55550
-- 077:00444400042442400424424004244240042442400444444000022000000cc000
-- 078:0055550055cccc555ffffcc5bccfccff5ffcffc55cfcff5bb5ccc5bb0b555bb0
-- 079:904909099449494949494994099999900ffffff00affffa003ffff3000bb05b5
-- 080:00cc00cc0094499c000ccc900cc9c440c99c4cc09ee409909ee4000009400000
-- 081:0999999099999999666666665eeeeee5444ee444444444449999999909999990
-- 082:000c6000088668808688688688688688666666660fcfcfc00c9c9c900c9c9c90
-- 083:0bb009e900bb9e9e55b9e9e90b9e9e900be9e9b00bbe9bbbb5bbb50bbb000500
-- 084:00000400ffccc4c906ffcccc0666ffccffbb66ff00ff66660000ffbb000000ff
-- 085:0000000000000000099999909e66ee6966ee66e6666666669999999909999990
-- 086:00000000005555000505b55055555b555b5555550bbb55500beb5555bebbb555
-- 087:00000ff000000fff0999ffff99999f0099999400949994004999440004444000
-- 088:000a0a00000aa0000003300000afaa000affafa0faffafaffaffafaf00000000
-- 089:0000c9c0000c9c9c0009c4c90c9c4c99c9c9c9909c4c9000c4c9900000000000
-- 090:0ffb5500feefbb50fe2fbfb5feefbbb5f2efb555feefbbb5fe2fbb5000000000
-- 091:02222220222222222400004222c4442242222224944444499c4cccc900000000
-- 092:00eeeee00eeeee99eeeeeee9eeeeeee9ee9eeee9eee9e999bbe9999000000000
-- 093:000b000000055000099449909e9999999e9ee9e99e9ee9e99e4ee9e900000000
-- 094:0000000000004440004c4442044444c244444442494444202444420000000000
-- 095:0bb55bbb0b55bb550b5bb5500a5a5bbb0ffbbbb5fffa5550ff00000000000000
-- 096:000000000000004000000c490000cfc90ccffce9cffcce90cfcce9009cee9900
-- 097:00000000000000000000000004444cc04244c86c4442c6fc2444c66c2222c68c
-- 098:000000000bb0bbb0b0bbb0bb000b0000088888008cc8cc80fffcfff00fffff00
-- 099:00000000999900004449990096944990666ee490969ee499eeee6649e66e6649
-- 100:000000000000055000099ee50b9994e5be444eb5beeeeb555bbbb55005555500
-- 101:0000000000ffff000ffffff00ffffff0ffe99effff9999ffff9999ff0fe99ef0
-- 102:bb0055500000000009f999f09f999f99c999c999999c999c949444494cffffc0
-- 103:0000000000b55b000f5fb5b0b5fbbb5bb5bbb5bfbb555bfb5bb5bbb5b55b5555
-- 112:09999000009919000d199990911e911999e99119499999940444444009494940
-- 113:02222cc00000666000ff26660dfdf666dd1fff2601ddfdf0044d1ff0cc41dd00
-- 114:000f000000000000050bb05006555560656556566f8666666866666666666666
-- 115:e66ee94900066ff000f66fff0fffffffffffffff4cc44cc4c44cc44c44444444
-- 116:005550000bbbbbb0b505505bb5bffb0bb055055b2bbbbbb22222222222444442
-- 117:00ffff000ffb5500feefbb50fe2fbfb5feefbbb5f2efb555feefbbb5fe2fbb50
-- 118:0ffffff002222220222222222400004222c4442242222224944444499c4cccc9
-- 119:0bb5555000eeeee00eeeee99eeeeeee9eeeeeee9ee9eeee9eee9e999bbe99990
-- 128:0249492000000000000000000000000000000000000000000000000000000000
-- 129:cc00d00000000000000000000000000000000000000000000000000000000000
-- 130:0666666000000000000000000000000000000000000000000000000000000000
-- 131:cffffffc00000000000000000000000000000000000000000000000000000000
-- 132:0224442000000000000000000000000000000000000000000000000000000000
-- 133:0ffb550000000000000000000000000000000000000000000000000000000000
-- 134:0cccccc000000000000000000000000000000000000000000000000000000000
-- 135:bbe9990000000000000000000000000000000000000000000000000000000000
-- </TILES>

-- <PALETTE>
-- 000:0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77abffccaa
-- </PALETTE>

