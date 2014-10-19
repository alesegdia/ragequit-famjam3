--
--  Controls
--

local Gamestate = require( LIBRARYPATH.."hump.gamestate"    )
local gui       = require( LIBRARYPATH.."Quickie"           )
local timer = require (LIBRARYPATH.."hump.timer")

Controls = Gamestate.new()

local center = {
        x = love.graphics.getWidth()/2,
        y = love.graphics.getHeight()/2,
    }

local s = { v = 255, sent = -1 }

local anim

function Controls:enter()
  anim = newAnimation(Image.instrucciones,800,600,1,2)
  anim:addFrame(0,0,800,600,1)
  anim:addFrame(800,0,800,600,0.2)
  timer.tween(0.5, vol, { v = 0.5 }, 'linear')
end

function Controls:keypressed(key)
  if key == " " then Gamestate.switch(RQgame) end
end


function Controls:update(dt)
  timer.update(dt)
  anim:update(dt)
  shaderpost:send("scans", math.random(0.4,0.6))
  theme:setVolume(vol.v)
end


function Controls:draw()
  love.graphics.setColor(255,255,255,255)
  anim:draw()
end

--[[
function Controls:update()

end
--]]

