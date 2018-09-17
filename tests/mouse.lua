-- title:  mouse
-- author: Neil Popham
-- desc:   
-- script: lua
-- input:  mouse
-- saveid: 

--[[

click on names at side to select group and then top button to split
left move
crosshair at mouse point
right fire
hold left and right down to grenade
if the lead member of a group hits another groups member they merge
group not controlled will use ai to fire and grenade

]]

local screen={width=240,height=136}

local moose={x=0,y=0,left=false,middle=false,right=false}

function TIC()

 cls()

 mx,my,mlb,mmb,mrb=mouse()

 if mx>screen.width then return end
 if my>screen.height then return end

 print(mx,0,0)
 print(my,0,10)
 print(mlb and "left" or "",0,20)
 print(mmb and "middle" or "",0,30)
 print(mrb and "right" or "",0,40)

 if mlb then 
  if not moose.left then
   trace("lmb down")
  end 
 else
  if moose.left then 
   trace("lmb released")
  end
 end

 if mrb then
  if not moose.right then
   trace("rmb down")
  end 
 else
  if moose.right then 
   trace("rmb released")
  end
 end 

 rectb(mx,my,7,7,2) 

 moose.x=mx
 moose.y=my
 moose.left=mlb
 moose.right=mrb

end

-- <TILES>
-- 001:0000000000222000020002002000002020020020200000200200020000222000
-- </TILES>

-- <PALETTE>
-- 000:0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77abffccaa
-- </PALETTE>

