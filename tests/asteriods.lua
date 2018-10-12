-- title:  asteriods
-- author: Neil Popham
-- desc:   
-- script: lua
-- input:  gamepad


screen={width=240,height=136,x2=239,y2=135}
local pad={left=2,right=3,up=0,down=1,btn1=4,btn2=5,btn3=6,btn4=7}

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
function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end
function pset(x,y,c) rectb(x,y,1,1,c) end

stars={}
p={}
drag=0.95

function _init()
 local depths={1,0.7,0.5,0.3}
 local colours={7,13,5,1}
 local fades={13,1,0,0}
 for x=0,79 do
  local i=1+flr(x/20)
  add(
   stars,
   {
    x=rnd(screen.x2),
    y=rnd(screen.y2),
    col=colours[i],
    depth=depths[i],
    col2=fades[i]
   }
  )
 end
 p={x=flr(screen.width/2),y=flr(screen.height/2),angle=0,force=0,dx=0,dy=0,da=0.01,df=0,af=0.02}
end

function _update60()
 -- rotation
 if btn(pad.left) then
  p.angle=p.angle-p.da
 elseif btn(pad.right) then
  p.angle=p.angle+p.da
 end
 p.angle=p.angle%1
 -- thrust
 if btn(pad.btn1) or btn(pad.up) then
   p.df=p.df+p.af
 elseif btn(pad.btn2) or btn(pad.down) then
   p.df=p.df-p.af
 else
  p.df=0
  p.force=p.force*drag
 end
 p.force=p.force+p.df
 if abs(p.force)<0.04 then p.force=0 end
 p.force=mid(-6,p.force,6)
 -- set ship movement
 p.dx=cos(p.angle)*p.force
 p.dy=-sin(p.angle)*p.force
 --move stars according to ship speed and their depth
 for _,star in pairs(stars) do
  star.x=star.x-p.dx*star.depth
  if star.x<0 then
   star.x=screen.x2+star.x
  end
  if star.x>screen.x2 then
   star.x=star.x-screen.x2
  end
  star.y=star.y-p.dy*star.depth
  if star.y<0 then
   star.y=screen.y2+star.y
  end
  if star.y>screen.y2 then
   star.y=star.y-screen.y2
  end
 end
end

function _draw()
 cls()
 -- if we're going fast draw a trail
 if abs(p.force)>3 then
  local i=1
  while stars[i].depth>0.5
    line(
    star.x,
    star.y,
    star.x+p.dx*abs(p.force)/3*star.depth,
    star.y+p.dy*abs(p.force)/3*star.depth,
    star.col2
   )
   i=i+1
  end
 end
 -- draw the stars
 for _,star in pairs(stars) do
  pset(star.x,star.y,star.col)
 end
 -- draw the ship trail
 line(p.x,p.y,p.x-p.dx,p.y-p.dy,9)
 pset(p.x,p.y,8)
 -- draw the ship
 local len=5
 local ang=0.37
 local col=2
 local tx=p.x+cos(p.angle)*len
 local ty=p.y-sin(p.angle)*len
 local lx=p.x+cos(p.angle-ang)*len
 local ly=p.y-sin(p.angle-ang)*len
 local rx=p.x+cos(p.angle+ang)*len
 local ry=p.y-sin(p.angle+ang)*len
 line(tx,ty,lx,ly,col)
 line(tx,ty,rx,ry,col)
 line(rx,ry,lx,ly,col)
end

function TIC() _update60() _draw() end

_init()

-- <PALETTE>
-- 000:0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77abffccaa
-- </PALETTE>