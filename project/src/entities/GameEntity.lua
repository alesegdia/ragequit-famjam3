
local Class         = require (LIBRARYPATH.."hump.class"	)
local vector         = require (LIBRARYPATH.."hump.vector"	)

require "src.entities.Entity"
require (LIBRARYPATH.."AnAL")

GameEntity = Class {
  init = function(self, stage, x, y, anim, phbody, controller)
  	self = Entity.init(self, stage, x, y)
  	self.controller = controller or nil
  	self.selected = false
  	self.anim = anim
  	self.physicbody = phbody
  	self.lookat = vector.new(-1,0)
  	return self
  end,
  update = function(self,dt)
	if self.anim ~= nil then self.anim:update(dt) end
	if self.controller ~= nil then self.controller(self,dt) end
	if self.physicbody ~= nil then 
	  self.pos.x = self.physicbody:getX()
	  self.pos.y = self.physicbody:getY()
	end
  end,
  draw = function(self)
  	if self.physicbody ~= nil then
	  local color = {}
	  if self.selected then color = {255, 255, 255, 255}
	  elseif self.physicbody:getType() == "static" then color = {255,0,255,255}
	  elseif self.physicbody:getType() == "dynamic" then color = { 255, 255, 0, 255 }
	  elseif self.physicbody:getType() == "kinematic" then color = { 0, 255, 255, 255 }
	  end
	  if self.color ~= nil then color = self.color end
	  if RQDEBUG then
		love.graphics.setPointSize(5)
		love.graphics.setColor(color)
		love.graphics.point(self.physicbody:getX(), self.physicbody:getY())
		for k,fix in pairs(self.physicbody:getFixtureList()) do
		  if fix:getType() == "polygon" then
			love.graphics.polygon("line", self.physicbody:getWorldPoints(fix:getShape():getPoints()))
		  elseif fix:getType() == "edge" or fix:getType() == "chain" then
			local x1, y1, x2, y2
			x1,y1,x2,y2 = fix:getShape():getPoints()
			love.graphics.push()
			love.graphics.rotate(self.physicbody:getAngle())
			love.graphics.line(self.pos.x+x1,self.pos.y+y1,self.pos.x+x2,self.pos.y+y2)
			love.graphics.pop()
		  else
			love.graphics.circle("line", self.pos.x, self.pos.y, fix:getShape():getRadius(), 20)
		  end
		end
	  end
	end
	love.graphics.setColor({255,255,255,255})
	if self.anim ~= nil then
	  local s = self.s -- = 0.08
	  local v1, v2
	  v1 = vector.new(1,0)
	  local v2 = v1:angleTo(self.lookat)
	  self.anim:draw(self.pos.x,self.pos.y, -v2, s, s, self.anim.fw/2, self.anim.fh/2)
	end
  end
}

GameEntity:include(Entity)
