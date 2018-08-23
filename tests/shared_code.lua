-- title:  shared_code
-- author: Neil Popham
-- desc:   This should run without change on both pico-8 and tic-80
-- script: lua
-- input:  gamepad

p8=type(camera)=="function"

if p8 then
 pad={l=0,r=1,u=2,d=3,b1=4,b2=5}
else
 pad={l=2,r=3,u=0,d=1,b1=4,b2=5,b3=6,b4=7}
end

function _init()
 x=0
end

function _update60()
 x=x+1
 if p8==false then _draw() end
end

function _draw()
 cls()
 print("hello world!",0,0)
 print(mid(7,3,9),0,10) -- do we have a mid() function now? 
 print(x,0,20)          -- did _init() and _update60() work ok?
 print(pad.r,0,30)      -- 1 on pico-8, 3 on tic-80
 print(p8 and "pico-8" or "tic-80",0,40)
end 

if p8==false then 

 -- declare missing functions
 function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end
 flr=math.floor
 abs=math.abs 

 -- set game loop and initialise manually
 function TIC() _update60() end
 _init()

end