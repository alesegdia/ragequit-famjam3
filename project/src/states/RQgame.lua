
local Gamestate     = require (LIBRARYPATH.."hump.gamestate")
local gui       = require( LIBRARYPATH.."Quickie"           )
local timer = require (LIBRARYPATH.."hump.timer")
local camera = require (LIBRARYPATH.."hump.camera")
local tween         = timer.tween
local vector = require (LIBRARYPATH.."hump.vector")
local util = require(LIBRARYPATH.."util")

require "src.entities.Stage"
require "src.entities.GameEntity"
require "src.entities.PhysicWorld"


RQgame = Gamestate.new()

local hp_counters = {
  counters = {},
  add_hp_counter = function( self, _x, _y, _n )
  	local obj = { x = _x, y = _y, n = _n, t = 1, a = 0 }
	table.insert(self.counters, obj)
	return obj
  end
}

local shake_current = 0

local rects = {}
local spawns = {}
local points = {}
local themevols = { v = 1, f = 0 }

local center = {
  x = love.graphics.getWidth() / 2,
  y = love.graphics.getHeight() / 2
}

local m2pix = 		32
local world =		PhysicWorld( 0, 0, m2pix )
local stage = 		Stage(world)

local beginContact = function(a,b,coll) end
local endContact = function(a,b,coll) end
local preSolve = function(a,b,coll) end
local postSolve = function(a,b,coll,normalimpulse1,tangentimpulse1,normalimpulse2,tangentimpulse2) end

world.w:setCallbacks( beginContact, endContact, preSolve, postSolve )

local map_layer = 0x0001
local enemy_layer = 0x0002

local MakeRect = function(x,y,w,h)
  local phb = world:createBody(x,y,0,"static")
  world:addRectFixture( phb, 0, 0, w, h, 0 )
  local ent = GameEntity( stage, x, y, nil, phb, nil  )
  ent.collayer = map_layer
  for k,v in pairs(phb:getFixtureList()) do
	v:setUserData(ent)
  end
end

local keyinput
local mapimg = newAnimation(Image.Germany3,2000,1250,1,1)
mapimg:addFrame(0,0,2000,1250,1)


local cam = camera.new(0,0,1,0)
--[[
local gameparms = {
  player_speed = 500, --
  player_attack_cooldown = 0.25, --
  player_initial_anger = 1000,
  player_initial_combatmult = 1, --
  player_decay_combatmult = 0.003, --
  player_decay_anger = 1, --
  player_kill_add_anger = 50,
  player_kill_add_multiplier = 0.25,
  player_kill_add_shake = 10, --
  player_base_dmg = 1, --
  enemy_speed = 300, --
  enemy_health = 3,
  enemy_vision_dist = 1000 --
}
]]--

local gameparms = {
  player_speed = 500, --
  player_attack_cooldown = 0.10, --
  player_initial_anger = 1000,
  player_initial_combatmult = 1, --
  player_decay_combatmult = 0.01, --
  player_speedmult_factor = 10,
  player_decay_anger = 1, --
  player_kill_add_anger = 10,
  player_kill_add_multiplier = 0.5,
  player_kill_add_shake = 10, --
  player_base_dmg = 1, --
  enemy_speed = 300, --
  enemy_health = 3,
  enemy_vision_dist = 500, --
  enemy_spawn_rate = 1, --
  enemy_spawn_max = 300, -- 300
  enemy_spawn_decay = 0.1
}


local visionshader = love.graphics.newShader( [[
	extern number time;
	extern number shadparam;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
		{
		  vec4 col;
		number p = (screen_coords.x) / 100;
		  vec4 c = Texel(texture, texture_coords);
		  if( c == vec4(0,1,0,1) ) col = vec4(0,0,0,0);
		  //else col =  vec4(0.5+0.5*sin(time/10),0,0.1* cos(time),1); //vec4(0,0,0,1);
		  else col =  vec4(min(max(abs(time*0.1),0),1),0,0,1); //0.5+0.5*sin(time/10),0,0.1* cos(time),1); //vec4(0,0,0,1);
		  	if( shadparam > 0 ) col.w = 0;
		  	return col;
		}
]])

local omgshader = love.graphics.newShader( [[
	extern number time;
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
	{
		number p = (screen_coords.x) / 100;
		//return vec4(1,0.10,0.20,1) * vec4(1.5+sin(p+time),2+sin(p+time),1+sin(p+time),1.0) * vec4(screen_coords.y+150)/600 * vec4((1.0+sin(time))/2.0, abs(cos(time*3)), abs(sin(time*2)), 1.0);
		return vec4(0.8,0,0.2,1) * vec4(1.5+sin(p+time),2+sin(p+time),1+sin(p+time),1.0) * vec4(screen_coords.y+150)/600 * vec4((1.0+sin(time))/2.0, abs(cos(time*3)), abs(sin(time*2)), 1.0);
	}
]])

local EDITMAP = false
local EDITSPAWN = false
local mousepos = {x = 0, y = 0}
local rayhit = { x=0,y=0,xn=0,yn=0,fix=nil }
local rayhitL = { x=0,y=0,xn=0,yn=0,fix=nil }
local rayhitR = { x=0,y=0,xn=0,yn=0,fix=nil }

require (LIBRARYPATH..'slam')
local keymiss = love.audio.newSource("sfx/misskeyboard.wav", "static")
local keyhit = love.audio.newSource("sfx/hitkeyboard.wav", "static")

local RC_nearest = function( rh )
  return function( fixture, x, y, xn, yn, fraction )
  	local userdata = fixture:getUserData()
  	if userdata.collayer == map_layer then return -1 end
	rh.fix = fixture
	rh.x, rh.y, rh.xn, rh.yn = x, y, xn, yn
	return fraction
  end
end

local RC_nearest2 = function( rh )
  return function( fixture, x, y, xn, yn, fraction )
  	local userdata = fixture:getUserData()
  	if userdata.collayer ~= map_layer then return -1 end
	rh.x, rh.y, rh.xn, rh.yn = x, y, xn, yn
	return fraction
  end
end

local Raycast = function( base, dir, angle )
  angle = angle or 0
  local v = dir:rotated(angle)
  local rayhit = { x=0,y=0,xn=0,yn=0,fix=nil }
  --print("vx: " .. angle) -- base.x)
  --print("vy: " .. base.y)
  stage.physicworld.w:rayCast(base.x, base.y, base.x+v.x*2000,base.y+v.y*2000,RC_nearest2(rayhit))
  return rayhit
end

local vision = {}
local tris = {}
local computeVision = function(debug)
  debug = debug or false
  if #vision > 0 then
	local poly = {}
	--print("==========")
	for k,v in pairs(vision) do
	  if v.x ~= v.y and v.y ~= 0 then
		table.insert(poly,v.x)
		table.insert(poly,v.y)
		--print(v.x)
		--print(v.y)
		--print("")
	  end
	  if debug then love.graphics.line(player.pos.x, player.pos.y, v.x, v.y) end
	end
	if #poly >= 3*2 then
	  tris = love.math.triangulate(unpack(poly))
	end
  end
  vision = {}
end

local MakePlayer = function(x,y)
  local fw, fh
  fw, fh = 636, 674
  local anim = newAnimation(Image.attackDEF,fw, fh,1,2)
  local piesanim = newAnimation(Image.runDEF, fw, fh, 0.05, 8)
  for i=0,7 do
	piesanim:addFrame(fw*i,0,fw,fh,0.05)
  end
  local pies = GameEntity( stage, x, y, piesanim, nil )
  pies.s = 0.17
  anim:seek(2)
  anim:addFrame(0,0,fw,fh,1)
  anim:addFrame(fw,0,fw,fh,1)
  local ent = GameEntity( stage, x, y, anim, world:createSphereBody(x,y,20,20) )
  for k,v in pairs(ent.physicbody:getFixtureList()) do
	v:setUserData(ent)
  end
  ent.anger = gameparms.player_initial_anger
  ent.combatmultiplier = gameparms.player_initial_combatmult
  ent.s = 0.17
  ent.currentframe = 1
  ent.piesent = pies
  ent.ataque = {
	cooldown = gameparms.player_attack_cooldown,
	cooldown_t = 0,
	step = function(self, dt)
	  if self.cooldown_t > 0 then
		self.cooldown_t = self.cooldown_t - dt
	  end
	end,
	try_attack = function(self)
	  if self.cooldown_t <= 0 then
	  	if ent.currentframe == 2 then ent.currentframe = 1
		else ent.currentframe = 2 end
	  	self.cooldown_t = self.cooldown
	  	return true
	  else
	  	return false
	  end
	end
  }
  ent.controller = function (self) -- pasar dt!! arreglar en el stage!
	self.anim:seek(self.currentframe)
	self.piesent.pos.x = self.pos.x
	self.piesent.pos.y = self.pos.y
  	if self.combatmultiplier > 1 then
	  self.combatmultiplier = self.combatmultiplier - gameparms.player_decay_combatmult
	else
	  self.combatmultiplier = 1
	end
  	if not EDITMAP and not EDITSPAWN then self.anger = self.anger - gameparms.player_decay_anger end
  	--print(self.anger)
  	local x, y = cam:worldCoords(mousepos.x, mousepos.y)
  	self.lookat.x = self.pos.x - rayhit.x
  	self.lookat.y = self.pos.y - rayhit.y
  	self.lookat:normalize_inplace()
  	self.lookat.x = -self.lookat.x
  	self.lookat.y = -self.lookat.y
	local h, v
	h = 0
	v = 0
	if keyinput["w"] then v = -1
	elseif keyinput["s"] then v = 1 end
	if keyinput["a"] then h = -1
	elseif keyinput["d"] then h = 1 end
	self.piesent.lookat.x = h
	self.piesent.lookat.y = v
	if h == v and v == 0 then
	  self.piesent.anim:seek(4)
	end
	local combatspeed = math.floor(self.combatmultiplier * gameparms.player_speedmult_factor)
	self.physicbody:setLinearVelocity( combatspeed * h + h * gameparms.player_speed, combatspeed * v + v * gameparms.player_speed)
	cam:place(self.physicbody:getX(),self.physicbody:getY())
  end
  return ent
end

local total_enemies = 0
local player
local combatscale = { v = 1, x = 150, y = 100 }
local blood = {}

local MakeBlood = function( x, y )
  local obj = {
  	x = x + math.random(5,60),
  	y = y + math.random(5,60),
  	r = math.random(2,15),
  	t = love.timer.getTime()
  }
  table.insert(blood, obj)
end

local MakeEnemy = function(x,y)
  local tehimg = Image.enemy
  local r = math.random(1,3)
  if r == 2 then tehimg = Image.enemy2
  elseif r == 3 then tehimg = Image.enemy3 end

  local anim = newAnimation(tehimg,300,342,1,1)
  anim:addFrame(0,0,300,342,1)
  local phb = world:createSphereBody(x,y,20,20)
  local ent = GameEntity( stage, x, y, anim, phb )
  total_enemies = total_enemies + 1
  ent.lookat=vector.new(0,1)
  ent.attacked = 0
  ent.collayer = enemy_layer
  ent.health = gameparms.enemy_health
  ent.pain = false
  ent.s = 0.15
  ent.nextwalk = 0
  ent.controller = function(self, dt)
	local mob2pl = vector.new(self.pos.x - player.pos.x, self.pos.y - player.pos.y)
	local dist = mob2pl:len()
	mob2pl:normalize_inplace()
	self.lookat = player.pos - self.pos
	self.lookat:rotate_inplace(math.pi/2)
	if self.pain then
	  --keyhit:rewind()

	  keyhit:setPitch(math.random(0.8,1.2))
	  keyhit:play()
	  shake_current = math.abs(shake_current + gameparms.player_kill_add_shake) * util.sign(shake_current)
	  local dmg = gameparms.player_base_dmg * player.combatmultiplier
	  local counter = hp_counters:add_hp_counter( self.pos.x, self.pos.y, dmg )
	  timer.tween(0.5, counter, {a = 0.9, y = counter.y - 75 }, 'linear')
	  self.health = self.health - dmg
	  if self.health <= 0 then
	  	combatscale.v = 3
	  	combatscale.x = 30
	  	combatscale.y = 30
		timer.tween( 0.75, combatscale, { v = 1, x = 150, y = 100} , 'quint' )

	  	self.dead = true
	  	local n = math.random(2,4)
	  	for i=1,n do
		  MakeBlood(self.pos.x, self.pos.y)
		end
	  	total_enemies = total_enemies - 1
	  	player.anger = player.anger + gameparms.player_kill_add_anger
	  	player.combatmultiplier = player.combatmultiplier + gameparms.player_kill_add_multiplier
	  end
	end
	if self.attacked > 0 then
	  self.color = { 255, 0, 0, 255 }
	  self.attacked = self.attacked - dt
	else
	  self.color = {0, 255, 0, 255 }
	end
  	self.pain = false
	if dist < gameparms.enemy_vision_dist then
	  self.physicbody:setLinearVelocity(mob2pl.x*gameparms.enemy_speed, mob2pl.y*gameparms.enemy_speed)
	else
	  self.physicbody:setLinearVelocity(0,0)
	end
  end
  for k,v in pairs(phb:getFixtureList()) do
	v:setUserData(ent)
  end
end

local current_max_enemy_spawn = gameparms.enemy_spawn_max

local MakeSpawn = function(x,y)

  local ent = GameEntity( stage, x, y, nil, nil )
  ent.nextspawn = 0
  ent.controller = function(self, dt)
  	if total_enemies < current_max_enemy_spawn and love.timer.getTime() > self.nextspawn then
  	  self.nextspawn = gameparms.enemy_spawn_rate + love.timer.getTime()
  	  MakeEnemy(self.pos.x+math.random(1,5), self.pos.y+math.random(1,5))
	end
  end

end

local plain_reset = function(self)
  for k in pairs (self.points) do
	self.points [k] = nil
  end
end


--[[
local RC_nearest
local mtrc = {
	__call = function( fixture, x, y, xn, yn, fraction )
	  rayhit.fix = fixture
	  rayhit.x, rayhit.y, rayhit.xn, rayhit.yn = x, y, xn, yn
	  return fraction
	end
}
]]--


function RQgame:keypressed(key)
  if key == " " then
  	if EDITMAP then util.table2json("cajitas.json", rects)
	elseif EDITSPAWN then util.table2json("spawns.json", spawns) end
  end
  keyinput[key] = true
end

function RQgame:keyreleased(key)
  keyinput[key] = false
end


local mousepress = false

local gameparms_file = {}

function RQgame:leave()
  --util.table2json("gameparms.json", gameparms)
end

local timer_vol = 0
function RQgame:enter()
  tris = {}
  vision = {}
  blood = {}
  timer_vol = love.timer.getTime() + 5
  total_enemies = 0
  current_max_enemy_spawn = gameparms.enemy_spawn_max
  --util.json2table("gameparms.json",gameparms_file)
  gameparms_file = {}
  if #gameparms_file > 0 then gameparms = gameparms_file end
  keyinput = {
  ["up"] = false,
  ["down"] = false,
  ["right"] = false,
  ["left"] = false,
  ["w"] = false,
  ["a"] = false,
  ["s"] = false,
  ["d"] = false
}

  timer.tween(0.5, vol, { v = 1 }, 'linear')
  love.mouse.setVisible(false)
  cam:attach()
  --cam:zoom(1.5)
  for k,v in pairs(stage.objects) do
	v.dead = true
  end
  rects = util.json2table("cajitas.json")
  if rects ~= nil then
	for k,v in pairs(rects) do
	  MakeRect( v.x, v.y, v.w, v.h )
	end
  else
  	rects = {}
  end

  spawns = util.json2table("spawns.json")
  if spawns ~= nil then
  	points = spawns
  	for k,v in pairs(spawns) do
	  MakeSpawn( v.x, v.y )
	end
  else
  	spawns = {}
  end
  for i=1,10 do
	MakeEnemy(math.random(0,2000),math.random(0,1250))
  end
  player = MakePlayer(200,200)

end

function RQgame:mousepressed(x,y,button)
  mousepress = true
  --mousepos.x = x
  --mousepos.y = y
end

local shadparam = { v = 0 }
function RQgame:mousereleased(x,y,button)
  mousepress = false
end
local rainshad = love.graphics.newShader([[
	// helper function, please ignore
	number _hue(number s, number t, number h)
	{
	h = mod(h, 1.);
	number six_h = 6.0 * h;
	if (six_h < 1.) return (t-s) * six_h + s;
	if (six_h < 3.) return t;
	if (six_h < 4.) return (t-s) * (4.-six_h) + s;
	return s;
	}

	// input: vec4(h,s,l,a), with h,s,l,a = 0..1
	// output: vec4(r,g,b,a), with r,g,b,a = 0..1
	vec4 hsl_to_rgb(vec4 c)
	{
	if (c.y == 0)
		return vec4(vec3(c.z), c.a);

	number t = (c.z < .5) ? c.y*c.z + c.z : -c.y*c.z + (c.y+c.z);
	number s = 2.0 * c.z - t;
	return vec4(_hue(s,t,c.x + 1./3.), _hue(s,t,c.x), _hue(s,t,c.x - 1./3.), c.w);
	}

	extern number time;
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
	{
		number p1 = (screen_coords.x-400) / 300 + time / 50;
		number p2 = (screen_coords.y-300) / 300 + time / 50;
		number p3 = p1 * p2;
		//return hsl_to_rgb(vec4(sin(time/2),sin(time/1),sin(time/4),1) *
		//		vec4(sin(p3), sin(p3), sin(p3), 1));
		return hsl_to_rgb(vec4(p1, 1, 0.5,1));
		//vec4 texcolor = Texel(texture, texture_coords);
		//return texcolor * color * vec4( 0.8, 0.8, 0.8, 1);
	}
]])



local tehrl = { x = 0, y = 0 }
local tehrr = { x = 0, y = 0 }
local slider = { value = 1, max = 4, min = 0.125, pos = {120000, 12000} }
local khvol = 0.6
local kmvol = 0.6
local click = true
function RQgame:update( dt )

  if timer_vol < love.timer.getTime() then
	theme:setVolume(themevols.v)
  else
	theme:setVolume(vol.v)
  end

  themefinal:setVolume(themevols.f)
  --print(current_max_enemy_spawn)
  current_max_enemy_spawn = current_max_enemy_spawn - gameparms.enemy_spawn_decay
  keyhit:setVolume(khvol)
  keymiss:setVolume(kmvol)
  --theme:setPitch( 1 + player.combatmultiplier * 0.001 )
  --theme:setVelocity( 1 + player.combatmultiplier * 0.001 )
  --cam:zoomTo(slider.value)




  timer.update(dt)
  if current_max_enemy_spawn > 0 then
	player.ataque:step(dt)
	stage:update(dt)
  	for i=1,360,5 do
	  local obj = Raycast(player.pos, player.lookat, math.rad(i))
	  table.insert(vision, obj)
	end
	computeVision()
	if player.anger <= 0 then Gamestate.switch(Controls) end
	--[[
	if gui.Button{text = "Go back", pos = {5,5}} then
	  timer.clear()
	  Gamestate.switch(RQgame)
	end
	]]--
  -- {info = {value = v, min = 0, max = 1, step = (max-min)/20}, vertical = boolean, pos = {x, y}, size={w, h}, widgetHit=widgetHit, draw=draw}
	--local slider2d = {value = {.5,.5}}gui.Slider{value = 1, min = 0.125, max = 4, step = (4-0.125)/20, vertical = true, pos = {5,5}}
	--gui.Slider{ info = slider }

	local x, y = cam:worldCoords(love.mouse.getX(),love.mouse.getY())
	local px, py = player.pos.x, player.pos.y
	rayhit.fix = nil
	rayhitL.fix = nil
	rayhitR.fix = nil
	if mousepress then
	  print("PRESSS")
	  if EDITMAP or EDITSPAWN then
		table.insert(points, { x = rayhit.x, y = rayhit.y })
		table.insert(spawns, { x = x, y = y})
	  end
	  if player.ataque:try_attack() then
		--keymiss:rewind()
		keymiss:setPitch(math.random(1.8,2.2))
		keymiss:play()
		stage.physicworld.w:rayCast(px, py, px + player.lookat.x*100,py + player.lookat.y*100,RC_nearest(rayhit))
		local r, l
		r = player.lookat:rotated((math.pi / 2) * 0.4)
		l = player.lookat:rotated(-(math.pi / 2) * 0.4)
		r.x = r.x * 100 + px
		r.y = r.y * 100 + py
		tehrr.x = r.x
		tehrr.y = r.y
		l.x = l.x * 100 + px
		l.y = l.y * 100 + py
		tehrl.x = l.x
		tehrl.y = l.y
	stage.physicworld.w:rayCast(px, py, r.x , r.y ,RC_nearest(rayhitL))
	stage.physicworld.w:rayCast(px, py, l.x , l.y ,RC_nearest(rayhitR))

	if rayhit.fix ~= nil then
	  rayhit.fix:getUserData().attacked = 0.1
	  rayhit.fix:getUserData().pain = true
	end
	if rayhitL.fix ~= nil then
	  rayhitL.fix:getUserData().attacked = 0.1
	  rayhitL.fix:getUserData().pain = true
	end
	if rayhitR.fix ~= nil then
	  rayhitR.fix:getUserData().attacked = 0.1
	  rayhitR.fix:getUserData().pain = true
	end
	  end
	end
	--stage.physicworld.w:rayCast(player.pos.x,player.pos.y,x,y,RC_nearest(rayhit))
	if rayhit.fix == nil then
	  local x, y = cam:worldCoords(love.mouse.getX(),love.mouse.getY())
	  rayhit.x, rayhit.y = x, y
	  mousepos.x = love.mouse.getX() + player.pos.x
	  mousepos.y = love.mouse.getY() + player.pos.y
	else
	  mousepos.x = rayhit.x
	  mousepos.y = rayhit.y
	end

	if EDITMAP then

	  if #points == 2 then
		local w = points[2].x - points[1].x
		local h = points[2].y - points[1].y
		local x, y = points[1].x + w/2, points[1].y + h/2
		points = {}
		table.insert(rects, { x = x, y = y, w = w, h = h })
		MakeRect( x, y, w, h )
	  end
	elseif EDITSPAWN then
	  --local x, y = points[#points-1].x, points[#points-1].y
	  
	end
	mousepress = false

	shake_current = (math.abs(shake_current) - 0.4) * util.sign(shake_current)
	--print(shake_current)
	if math.abs(shake_current) > 10 + player.combatmultiplier * 0.2 then shake_current = 10 * util.sign(shake_current) end

	local todel = {}
	local del = true
	while del == true do
	  todel = nil
	  del = false
	  for k,v in pairs(hp_counters.counters) do
		v.t = v.t - dt
		if v.t <= 0 then
		  todel = k
		  del = true
		  break
		end
	  end
	  if del == true then table.remove(hp_counters.counters,todel) end
	end
  else
  	if click then
  	  click = false
	  timer.tween(5,shadparam, {v = 1}, "linear", function() shadparam.v = 1 end )
	  themefinal:play()
	  timer.tween(5,themevols, {v = 0, f = 1}, "linear")
	end
	shake_current = 0
	--print(shadparam)
  end

  omgshader:send("time", love.timer.getTime()*10)
  shaderpost:send("intensity", 0.7)
  shaderpost:send("alfa", 1)
  shaderpost:send("scans", 1)
  rainshad:send("time", love.timer.getTime()*10)
  visionshader:send("time", shake_current) --love.timer.getTime()*10)
  visionshader:send("shadparam", shadparam.v)
  --visionshader:send("time", love.timer.getTime()*10)
  --[[
  shader_bg:send( "time", 		shader_time )
  shader_bg:send( "factor",	shader_shake_current )
  shader_bg:send( "angle", 	shader_pixel_rotation )
  ]]--

end




local rttcanvas = love.graphics.newCanvas(love.window.getWidth(),love.window.getHeight())
local raincanvas = love.graphics.newCanvas(love.window.getWidth(),love.window.getHeight())
local finalcanvas = love.graphics.newCanvas(love.window.getWidth(),love.window.getHeight())
local visioncanvas = love.graphics.newCanvas(love.window.getWidth(),love.window.getHeight())
local postcanvas = love.graphics.newCanvas(love.window.getWidth(),love.window.getHeight())


local drawVision = function(debug)
  for k,v in pairs(tris) do
	love.graphics.polygon("fill",unpack(v))
  end
  tris = {}
end

local draw_blood = function()
  for k,v in pairs(blood) do
	love.graphics.setColor(255,0,0,255)
	love.graphics.circle("fill",v.x,v.y,v.r)
  end
end
function RQgame:draw()


  love.graphics.setCanvas(rttcanvas)
  cam:place( player.pos.x, player.pos.y )
  local cam_random_shake_x = math.random()
  local cam_random_shake_y = math.random()
  if math.random() > 0.5 then cam:move( shake_current, shake_current )
  else cam:move( shake_current * cam_random_shake_y, -shake_current * cam_random_shake_x ) end
  shake_current = shake_current * (-1)
	love.graphics.setColor(255,0,0,255)
	love.graphics.setShader(omgshader)
	love.graphics.rectangle("fill",0,0,love.window.getWidth(),love.window.getHeight())
	love.graphics.setShader()
	love.graphics.setColor({255,255,255,255})
  cam:draw( function ()
	mapimg:draw(0,0)
	draw_blood()
  	stage:draw()
  	if RQDEBUG then
	  local x, y = cam:worldCoords(love.mouse.getX(),love.mouse.getY())
	  local px, py = player.pos.x, player.pos.y
	  love.graphics.line(px, py,rayhit.x,rayhit.y)
	  love.graphics.setColor({0,255,0,255})
	  --[[
	  love.graphics.line(px, py,rayhitR.x,rayhitR.y)
	  love.graphics.setColor({255,0,0,255})
	  love.graphics.line(px, py,rayhitL.x,rayhitL.y)
	  love.graphics.setColor({255,255,255,255})
	  ]]--da
	  love.graphics.setLineWidth(3)
	  love.graphics.line(px, py,px+player.lookat.x*40, py+player.lookat.y*40)
	  love.graphics.setLineWidth(1)
	  love.graphics.setColor({0,255,0,255})
	  love.graphics.setPointSize(10)
	  love.graphics.point(rayhit.x, rayhit.y)
	end
	if EDITMAP or EDITSPAWN then
	  for k,v in pairs(points) do
		love.graphics.setPointSize(10)
		love.graphics.point(v.x, v.y)
	  end
	end
	for k,v in pairs(hp_counters.counters) do
	  local str
	  if v.n == 1 then str = 1
	  else str = string.format("%.2f",v.n) end
	  render_text( str .. "", v.x,v.y, {0,255,255,v.a*255}, bigFont)
	end

  end )
  love.graphics.setCanvas()

  --love.graphics.setShader(omgshader)
  love.graphics.setShader()


  -- FALLO FEO: https://dl.dropboxusercontent.com/u/19190625/fallofeo.png
  -- 	se arreglaría estableciendo las cajas de los límites del mapa en otra capa de colisión
  love.graphics.setCanvas(raincanvas)
  love.graphics.setShader(rainshad)
  love.graphics.rectangle("fill",0,0,love.window.getWidth(),love.window.getHeight())
  love.graphics.setShader()
  cam:draw( function () player:draw() end )
  love.graphics.setCanvas()

  -- pintamos la visión en un canvas aparte para sobreponerlo luego
  love.graphics.setCanvas(visioncanvas)
  love.graphics.setColor(0,255,0,255)
  love.graphics.rectangle("fill",0,0,800,600)
  cam:draw( function ()
  	love.graphics.setColor(255,0,0,255)
  	love.graphics.rectangle("fill",10,10,1980,1230)
  	love.graphics.setColor(0,255,0,255)
  	drawVision()
  	love.graphics.setShader()
  end )
  love.graphics.setShader()
  love.graphics.setCanvas()


  -- activamos blending para fundir capas
  love.graphics.setBlendMode('alpha')

  -- creamos el canvas final combinando
  love.graphics.setCanvas(finalcanvas)
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(raincanvas)
  love.graphics.setColor(255, 255, 255, (1-shadparam.v) * 255)
  love.graphics.draw(rttcanvas)
  --love.graphics.draw(visioncanvas)
  love.graphics.setShader()
  love.graphics.setCanvas()

  -- volcamos el canvas final con los scanlines
  love.graphics.setColor(255, 255, 255, 0)
  love.graphics.setShader(shaderpost)
  love.graphics.draw(finalcanvas)
  love.graphics.setShader(visionshader)
  love.graphics.draw(visioncanvas)
  love.graphics.setShader()


  gui.core.draw()

  if shadparam.v == 0 then
	--render_text( "Current FPS: " .. tostring(love.timer.getFPS()), 10, 100 )
	--render_text( "ZOOM: " .. slider.value, 10, 50, {255,0,0}, bigFont )
	love.graphics.push()
	love.graphics.scale(combatscale.v, combatscale.v)
	render_text( "x" .. string.format("%.3f", player.combatmultiplier), combatscale.x, combatscale.y, {255,0,0}, bigFont )
	love.graphics.pop()
	love.graphics.setColor(255,255,255,255)
	love.graphics.draw(Image.anger,0,0)
	love.graphics.setColor(64+player.anger*192/1000,0,0,255)
	love.graphics.rectangle("fill", 250, 30, player.anger/2 , 20)
	love.graphics.setColor({255,255,255,255})
	love.graphics.setPointSize(30)
	love.graphics.draw(Image.cursor,love.mouse.getX(), love.mouse.getY())
  end
end


