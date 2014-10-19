--
--  Menu
--

local Gamestate = require( LIBRARYPATH.."hump.gamestate"    )
local gui       = require( LIBRARYPATH.."Quickie"           )
local timer = require (LIBRARYPATH.."hump.timer")
local camera = require (LIBRARYPATH.."hump.camera")
local util = require(LIBRARYPATH.."util")

local cam = camera.new(400,300,1,0)

Menu = Gamestate.new()
local center = {
        x = love.graphics.getWidth()/2,
        y = love.graphics.getHeight()/2,
    }

local s = { v = 255, sent = -1 }

local t = 0
function Menu:enter()
  cam:attach()
  t = love.timer.getTime()
  --timer.tween(0.5, vol, { v = 0.5 }, 'linear')
  timer.tween(0.5, vol, { v = 0.5 }, 'linear')
end

local rotation = 0
local shake_current = 0
local alfa = { v=255 }

function Menu:update(dt)

  shaderpost:send("intensity", 0.3)
  if RQDEBUG then Gamestate.switch(RQgame) end
  shake_current = (math.abs(shake_current) - 0.2) * util.sign(shake_current)
  if math.abs(shake_current) > 10 then shake_current = 10 * util.sign(shake_current) end

  cam:place( 400, 300 )
  local cam_random_shake_x = math.random()
  local cam_random_shake_y = math.random()
  if math.random() > 0.5 then cam:move( shake_current, shake_current )
  else cam:move( shake_current * cam_random_shake_y, -shake_current * cam_random_shake_x ) end
  shake_current = shake_current * (-1)

  timer.update(dt)
  shaderpost:send("alfa", alfa.v/255)
  local pt = love.timer.getTime()
  if pt > t+9 then
	shaderpost:send("scans", math.random(0.4,0.6))
  else
	shaderpost:send("scans", 0)
  end

	theme:setVolume(vol.v)

  rotation = math.deg(360)*math.sin(love.timer.getTime())/20000000
  --rotation = 0

	--[[
	love.graphics.setFont(smallFont)
    if gui.Button{text = "Start Game"} then
    end


    if gui.Button{text = "Options"} then
        Gamestate.switch(Options)
    end
    gui.Button{text = "Credits"}
    if gui.Button{text = "Exit"} then
        love.event.push("quit")
    end
    ]]--

end

local fontH =   love.graphics.newFont(80)
local fontB =   love.graphics.newFont(32)
local fontS =   love.graphics.newFont(20)

local click = true

local scene = 0

function Menu:draw()
  love.graphics.setShader(shaderpost)
  cam:draw(function()
	love.graphics.setColor(255,255,255,alfa.v)
	local pt = love.timer.getTime()
	if pt < t+2 then
	  cam:rotate(rotation)
	  love.graphics.draw(Image.titleSet1)
	  if click then
		click = false
		alfa.v = 255
		timer.tween(2, alfa, {v=0}, "quint", function()click=true end)
	  end
	elseif pt < t+5 then
	  cam:rotate(rotation)
	  love.graphics.draw(Image.titleSet2)
	  if click then
		click = false
		alfa.v = 255
		timer.tween(3, alfa, {v=0}, "quint", function()click=true end)
	  end
	elseif pt < t+7 then
	elseif pt < t+9 then
	  cam:rotate(rotation)
	  alfa.v = 255
	  love.graphics.draw(Image.titleSet4)
	else
	  cam:rotate(-cam.rot)
	  if click then shake_current = 300 click = false end
	  alfa.v = 255
	  love.graphics.draw(Image.pressSpaceBar)
	  love.graphics.draw(Image.titleFull)
	  if love.keyboard.isDown(" ") then Gamestate.switch(Controls) end
	end
  end)
  --[[
	render_text("RAGEQUIT", 200, 50, {255,0,0,255},fontH)

	render_text("YOU LOSE ANGER IN TIME!! KILL TO FEED AND KILL MORE!!", 20, 400, {255,0,0,s.v}, fontS )

	render_text("You have lost another Unreal match because you're a noob, you get mad ", 20, 450, {255,0,0,s.v},fontS)
	render_text("and start to feel the need for stealing some human souls...", 20, 480, {255,0,0,s.v},fontS)
	render_text("...which weapon could be better than your keyboard?", 200, 510, {255,0,0,s.v},fontS)
	]]--
end

--[[
function Menu:update()

end
--]]

function Menu:keypressed(key, code)
end
