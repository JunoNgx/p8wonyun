-- impact particles, spawned when bullets hit
function Fragment(_x, _y, _angle)

	local vel = C.FRAGMENT_MOVE_VEL_MIN + rnd(C.FRAGMENT_MOVE_VEL_RANGE)
	local _vx, _vy = vel * cos(_angle), vel * sin(_angle)

	add(world,{
		id = {
			class = "particle",
			subclass = "fragment"
        },
        pos = {
            x = _x,
            y = _y
		},
		vel = {
			x = _vx,
			y = _vy
		},
		fragment = {
			radius = 1+rnd(1),
			radius_rate = 0.8 + rnd(2)/10,
			vel_rate = 0.8 + rnd(2)/10
		},
		drawTag = "particle",
		draw = function(self)
			circfill(self.pos.x, self.pos.y, self.fragment.radius, 10)
		end
	})
end