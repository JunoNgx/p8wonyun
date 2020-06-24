function Augustus(_x, _y)
	
	-- sfx(16)
	add(world, {
		id = {
			class = "enemy",
			subclass = "augustus",
			size = "medium"
		},
		pos = {
			x = _x,
			y = _y
		},
		vel = {
			x = 0,
			y = C.AUGUSTUS_MOVE_VY
		},
		box = {
			w = 16,
			h = 14,
		},
		hitframe = false,
		hp = 2,
		enemyWeapon = {
			type = "augustus",
			cooldown = C.AUGUSTUS_FIRERATE
		},
		outOfBoundsDestroy = true,
		shadow = true,
		drawTag = "actor",
		draw = function(self, _offset)
			_offset = _offset or 0
			spr(38, self.pos.x+_offset, self.pos.y+_offset, 2, 2)
		end
	})
end