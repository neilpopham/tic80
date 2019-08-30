stage_intro={
 init=function(self)
 end,
 update=function(self)
  if btnp(pad.btn1) or btnp(pad.btn2) then
   stage=stage_main
   stage:init()
  end
 end,
 draw=function(self)
  print("press \142 or \151 to start",18,60,6)
 end
}
