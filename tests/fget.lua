-- title:  fget
-- author: Neil Popham
-- desc:   Implementation of PICO-8's fset and fget functions
-- script: lua
-- input:  gamepad
-- saveid: ntp_fget

local sprf={}

function xor(a,b)
 a=a and 1 or 0
 b=b and 1 or 0
 return a~b
end

function fget(s,i)
 if i==nil then
  return math.floor(sprf[s+1] or 0)
 else
  b=2^i
  return sprf[s+1] % (2*b) >= b 
 end
end

function fset(s,i,b)
  if b==nil then
   sprf[s+1]=i
  else
   if sprf[s+1]==nil then sprf[s+1]=0 end
   e=fget(s,i)
   if (e and not b) or (not e and b) then 
    sprf[s+1]=sprf[s+1]+(b and 2^i or -2^i)
   end
  end
end

function init()
 fset(0,0,true)
 fset(0,3,true)

 fset(0,4,true)
 fset(0,4,false)
 --fset(0,3,false)

 fset(1,134)
 --fset(1,1,true)
 --fset(1,2,true)
 --fset(1,7,true) 
 fset(1,7,false)
 fset(1,1,false)


 fset(0,0)
 fset(1,0)

 fset(0,0,true)
 fset(0,1,true)
 fset(0,2,true)
 fset(0,2,false)
 fset(0,3,true)

 fset(1,0,true)
 fset(1,1,true)
 fset(1,4,true)

 fset(0, 56)
 fset(1, 73)

end

init()

function TIC()
 cls()

 for s=0,1 do
  for i=0,7 do
   print(fget(s,i),s*40,i*9,s+1)
  end
 end

 print(fget(0),0,100,1) 
 print(fget(1),40,100,2)
 print(fget(2),80,100,3)
 
end

