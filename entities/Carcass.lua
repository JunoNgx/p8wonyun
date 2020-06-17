-- dead bodies of the player from previous attempts
function Carcass(_x, _y)
	add(world, {
		id = {
			class = "carcass"
		},
		pos = {
			x = _x,
			y = _y
		},
		vel = {
			x = 0,
			y = C.CARCASS_MOVE_VY
		},
		-- shadow = true,
		drawTag = "background",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(40, self.pos.x-3+_offset, self.pos.y-4+_offset, 2, 2)
		end,
	})
end