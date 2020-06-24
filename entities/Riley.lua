function Riley(_x, _y)

	-- sfx(14)
    add(world, {
        id = {
            class = "enemy",
			subclass = "riley",
			size = "small"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=C.RILEY_MOVE_VY
        },
        box = {
            w = 10,
            h = 10
		},
		hitframe = false,
		hp = 1,
		enemyWeapon = {
			type = "riley",
			cooldown = C.RILEY_FIRERATE
		},
		outOfBoundsDestroy = true,
		shadow = true,
		drawTag = "actor",
		draw = function(self, _offset)
			_offset = _offset or 0
			spr(34, self.pos.x+_offset, self.pos.y+_offset, 2, 2)
		end
    })
end