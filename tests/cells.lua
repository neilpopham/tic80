-- title:  cells
-- author: Neil Popham
-- desc:   collision mget test
-- script: lua
-- input:  gamepad

function _init()
 x=1
 y=1
end

function _update()

 for nx=0,16,1 do for ny=0,16,1 do 
  tile=mget(nx,ny)
  if tile>9 then mset(nx,ny,tile-10) end
 end end  

 dx=x
 dy=y
 b=true

 if btn(0) then dx=x-1 end
 if btn(1) then dx=x+1 end
 if btn(2) then dy=y-1 end
 if btn(3) then dy=y+1 end

 px={dx,dx+7}
 py={dy,dy+7}

 for _,ax in pairs(px) do
  for _,ay in pairs(py) do
   tx=flr(ax/8)
   ty=flr(ay/8)
   tile=mget(tx,ty)
   if tile<10 then mset(tx,ty,tile+10) end
   if fget(tile,0) then sfx(0) b=false end
   if fget(tile,1) then sfx(1) end
  end
 end

 if b then
  x=dx
  y=dy
 end

 _draw()

end

function _draw()
 cls()
 map(0,0)
 spr(8,x,y) 
 print("maybe we should use hitboxes",0,120)
end

function TIC() _update60() end

_init()