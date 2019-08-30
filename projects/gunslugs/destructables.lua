destructable_types={
 nil,
 {sprite=2,health=10,col=9,size={6,12}},
 {sprite=3,health=10,col=8,size={10,16},range=15,shake=2},
 {sprite=4,health=10,col=11,size={14,20},range=20,shake=3}
}

destructable={
 create=function(self,x,y,type)
  local ttype=destructable_types[type]
  local o=movable.create(self,x,y,0,0,0,3)
  o.type=ttype
  o.health=ttype.health
  o.t=0
  return o
 end,
 destroy=function(self,health)
  self.complete=true
  self.visible=false
  doublesmoke(
   (flr(self.x/8)*8)+4,
   (flr(self.y/8)*8)+4,
   {10,5,5},
   {
    {col=self.type.col,size=self.type.size},
    {col=7,size=self.type.size},
    {col=self.type.col,life={20,50}}
   }
  )
  if self.type.range then
   p.camera:shake(self.type.shake)
   self:collateral(self.type.range,abs(self.health))
   sfx(4)
  else
   sfx(2)
  end
 end,
 foobar=function(self,strength,health,dir)
  self.fb={strength,health,dir}
  local t=round(20/strength)
  if self.t>0 then
   self.t=min(self.t,t)
  else
   self.t=t
  end
 end,
 update=function(self)
  if not self.visible then return end
  if self.t>0 then
   self.t=self.t-1
   if self.t==0 then
    object.foobar(self,self.fb[1],self.fb[2],self.fb[3])
   end
  end
  self.dy=self.dy+0.25
  self.dy=mid(-self.max.dy,self.dy,self.max.dy)
  move=self:can_move_y()
  if move.ok then
   move=self:collide_destructable()
  end
  if move.ok then
   self.y=self.y+round(self.dy)
  else
   if self.dy>1 then
    particles:add(
     smoke:create(self.x+4,self.y+7,10,{size={4,8}})
    )
    sfx(2)
   end
   self.dy=0
  end
 end,
 draw=function(self)
  if not self.visible then return end
  spr(self.type.sprite,self.x,self.y)
 end
} setmetatable(destructable,{__index=movable})
