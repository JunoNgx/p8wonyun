function Smoke(_x, _y, _vx, _vy)
	add(world,{
		id = {
			class = "particle",
			subclass = "smoke"
        },
        pos = {
            x = _x,
            y = _y
		},
		vel = {
			x = _vx,
			y = _vy
		},
		particle = {
			lifetime = 0,
			lifetime_max = 30
		},
		smoke = {
			radius = C.SMOKE_RADIUS_INIT + rnd(C.SMOKE_RADIUS_RANGE)
		},
		drawTag = "particle",
		draw = function(self)
			circfill(self.pos.x, self.pos.y, self.smoke.radius, 8)
		end
	})
end