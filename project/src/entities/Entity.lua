--
-- Thing Class
--
-- 2014 Heachant, Tilmann Hars <headchant@headchant.com>
--
--

--------------------------------------------------------------------------------
-- Imports
--------------------------------------------------------------------------------

local Gamestate     = require (LIBRARYPATH.."hump.gamestate")
local gui       	= require (LIBRARYPATH.."Quickie"		)
local Class         = require (LIBRARYPATH.."hump.class"	)
local Vector        = require (LIBRARYPATH.."hump.vector"	)

require "src.entities.Thing"

--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------

Entity = Class{
	init = function(self, stage, x, y)
		self = Thing.init(self, x, y)
		stage:register(self)
		self.stage = stage
		return self
	end
}

--------------------------------------------------------------------------------
-- Inheritance
--------------------------------------------------------------------------------

Entity:include(Thing)
