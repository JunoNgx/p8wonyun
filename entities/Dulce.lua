function Dulce(_x, _y)
	-- show warning indicator
	Indicator(_x)
	
	-- delay spawning by one second
	Timer(1, function()
		sfx(13)
		add(world, {
			id = {
				class = "enemy",
				subclass = "dulce",
				size = "medium"
			},
			pos = {
				x=_x,
				y=_y
			},
			vel = {
				x=0,
				y=C.DULCE_MOVE_VY
			},
			box = {
				w = 15,
				h = 13
			},
			hitframe = false,
			hp = 2,
			enemyWeapon = {
				type = "dulce",
				cooldown = 0
			},
			outOfBoundsDestroy = true,
			shadow = true,
			drawTag = "actor",
			draw = function(self, _offset)
				_offset = (_offset) and _offset or 0
				spr(36, self.pos.x+_offset, self.pos.y+_offset, 2, 2)
			end
		})
	end)
    
end