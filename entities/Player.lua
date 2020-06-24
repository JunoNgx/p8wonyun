function Player(_x, _y)

    add(world, {
        id = {
			class = "player",
			subclass = "wonyun"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=0
        },
        box = {
            w = 2,
            h = 6
		},
		hp = C.PLAYER_HP_START,
		playerWeapon = {
			ammo = C.PLAYER_AMMO_START,
			cooldown = 0
		},
		playerControl = true,
		ani = {
			frame = 0, -- when working with table indexes, do not ever let it go zero
			framerate = 0.5,
			framecount = 4,
			loop = true
		},
		keepInScreen = true,
		harvester = {
			progress = 0
		},
		shadow = true,
		drawTag = "actor",
		draw = function(self, _offset)
			_offset = _offset or 0
			spr(0, self.pos.x-3+_offset, self.pos.y-4+_offset, 1.2, 2)

			spr(28+flr(self.ani.frame), self.pos.x-1, self.pos.y+9, 1, 1)
		end
	})
end