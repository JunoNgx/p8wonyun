function Hammerhead(_x, _y)

	-- sfx(15)
    add(world, {
        id = {
            class = "enemy",
			subclass = "hammerhead",
			size = "medium"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=C.HAMMERHEAD_MOVE_VY
        },
        box = {
            w = 9,
            h = 16
		},
		hitframe = false,
		hp = 2,
		enemyWeapon = {
			type = "hammerhead",
			cooldown = C.HAMMERHEAD_FIRERATE
		},
		outOfBoundsDestroy = true,
		shadow = true,
		drawTag = "actor",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(32, self.pos.x-3+_offset, self.pos.y+_offset, 2, 2)
		end
    })
end