-- hostile/enemy bullet
function EBullet(_x, _y, _vx, _vy)

	add(world, {
		id = {
			class = "bullet",
			subclass = "ebullet"
		},
		pos = {
			x = _x,
			y = _y,
		},
		vel = {
			x = _vx,
			y = _vy,
		},
		box = {
			w = 2,
			h = 2
		},
		outOfBoundsDestroy = true,
		shadow = true,
		drawTag = "projectile",
		draw = function(self, _offset)
			_offset = _offset or 0
			spr(20, self.pos.x-1+_offset, self.pos.y-1+_offset, 1, 1)
		end
	})
end	