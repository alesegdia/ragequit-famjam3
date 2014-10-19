--
--
--  Created by Tilmann Hars
--  Copyright (c) 2014 Headchant. All rights reserved.
--

-- Set Library Folders
LIBRARYPATH = "libs"
LIBRARYPATH = LIBRARYPATH .. "."

vol = { v = 0.5 }


-- Get the libs manually
local strict    = require( LIBRARYPATH.."strict"            )
local slam      = require( LIBRARYPATH.."slam"              )
local Gamestate = require( LIBRARYPATH.."hump.gamestate"    )

RQDEBUG = false

shaderpost = love.graphics.newShader( [[
		const float blurSizeH = 1.0 / 300.0;
		const float blurSizeV = 1.0 / 200.0;
		vec3 blur(Image texture, vec2 texture_coords)
		{
			vec4 sum = vec4(0.0);
			for (int x = -4; x <= 4; x++)
				for (int y = -4; y <= 4; y++)
					sum += Texel( texture, vec2(texture_coords.x + x * blurSizeH, texture_coords.y + y * blurSizeV) ) / 81.0;
			return sum.xyz;
		}
		extern number intensity;
		extern number alfa;
		extern number scans;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
		{
		  vec4 c = Texel(texture, texture_coords);
		  vec3 original = Texel(texture, texture_coords).xyz;
		  vec3 final = (original * 2 + blur(texture,texture_coords))/3.0;
		  if( scans > 0 && mod( texture_coords.y, 0.005 ) < 0.003 ) return mix( vec4(original,1), vec4(0,0,0,1), 0.2 * (1-scans) );
		  	// es el final / algo lo que cambia
		  return vec4(mix( final/intensity , original, 0.5 ),alfa);
		  //return outcolor;
		  //return vec4(blur(texture, texture_coords),1);
		  if( mod(texture_coords.y, 0.005) < 0.004 ) return c * 0.9;
		  else return c;
		  return vec4(texture_coords.x, texture_coords.y,0,alfa);//c; //vec4(vec3(1.0, 0, 1.0) * (max(c.r, max(c.g, c.b))), 1.0);
		}
]])
theme = love.audio.newSource("music/asesinando.ogg", "stream")
theme:setLooping(true)

themefinal = love.audio.newSource("music/final.ogg", "stream")
themefinal:setLooping(true)

local modes = love.window.getFullscreenModes()



-- Handle some global variables that strict.lua may (incorrectly, ofcourse) complain about:
class_commons = nil
common = nil
no_game_code = nil
NO_WIDGET   = nil
TILED_LOADER_PATH = nil

SCALE = 2
TILEWIDTH = 32
TILEHEIGHT = 32

-- Creates a proxy via rawset.
-- Credit goes to vrld: https://github.com/vrld/Princess/blob/master/main.lua
-- easier, faster access and caching of resources like images and sound
-- or on demand resource loading
local function Proxy(f)
	return setmetatable({}, {__index = function(self, k)
		local v = f(k)
		rawset(self, k, v)
		return v
	end})
end

-- some standard proxies
Image   = Proxy(function(k) return love.graphics.newImage('img/' .. k .. '.png') end)
Sfx     = Proxy(function(k) return love.audio.newSource('sfx/' .. k .. '.ogg', 'static') end)
MusicOGG = Proxy(function(k) return love.audio.newSource('music/' .. k .. '.ogg', 'stream') end)
MusicMP3 = Proxy(function(k) return love.audio.newSource('music/' .. k .. '.mp3', 'stream') end)

bigFont   =   love.graphics.newFont(32)
smallFont =   love.graphics.newFont(16)
render_text = function( text, x, y, color, font )
  color = color or { 255, 0, 255, 255 }
  font = font or smallFont
  love.graphics.setColor( color )
  love.graphics.setFont( font )
  love.graphics.print( text, x, y )
end

--[[ usage:
    love.graphics.draw(Image.background)
-- or
    Sfx.explosion:play()
--]]

-- require all files in a folder and its subfolders, this way we do not have to require every new file
local function recursiveRequire(folder, tree)
    local tree = tree or {}
    for i,file in ipairs(love.filesystem.getDirectoryItems(folder)) do
        local filename = folder.."/"..file
        if love.filesystem.isDirectory(filename) then
            recursiveRequire(filename)
        elseif file ~= ".DS_Store" then
            require(filename:gsub(".lua",""))
        end
    end
    return tree
end


local function extractFileName(str)
	return string.match(str, "(.-)([^\\/]-%.?([^%.\\/]*))$")
end

-- Initialization
function love.load(arg)

  theme:setVolume(0.5)
  theme:play()
	math.randomseed(os.time())
	love.graphics.setDefaultFilter("nearest", "nearest")
	-- love.mouse.setVisible(false)
    -- print "Require Sources:"
	recursiveRequire("src")
	Gamestate.registerEvents()
	Gamestate.switch(Menu)
end

-- Logic
function love.update( dt )
	
end

-- Rendering
function love.draw()

end

-- Input
function love.keypressed()
	
end

function love.keyreleased()
	
end

function love.mousepressed()
	
end

function love.mousereleased()
	
end

function love.joystickpressed()
	
end

function love.joystickreleased()
	
end

io.stdout:setvbuf("no")
