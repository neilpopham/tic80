-- if we don't have the abs() function then we're not in pico-8 land anymore
if type(abs)==nil then

  sprf={}

  -- http://pico-8.wikia.com/wiki/Mid
  function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end

  -- http://pico-8.wikia.com/wiki/Flr
  flr=math.floor

  -- http://pico-8.wikia.com/wiki/Abs
  abs=math.abs

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

end