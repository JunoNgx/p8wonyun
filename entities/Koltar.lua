function Koltar(_x, _y)

	-- miniboss, will play sfx once spawned
	sfx(17)
	add(world, {
		id = {
			class = "enemy",
			subclass = "koltar",
			size = "large"
		},
		pos = {
			x = _x,
			y = _y
		},
		vel = {
			x = 0,
			y = 0.5
		},
		box = {
			w = 32,
			h = 14
		},
		hitframe = false,
		hp = 3,
		enemyWeapon = {
			type = "koltar",
			cooldown = C.KOLTAR_FIRERATE,
			firemode = 0,
		},
		outOfBoundsDestroy = true,
		shadow = true,
		drawTag = "actor",
		draw = function(self, _offset)
			_offset = _offset or 0
			spr(5, self.pos.x+_offset, self.pos.y+_offset, 4, 2)
		end
	})
end