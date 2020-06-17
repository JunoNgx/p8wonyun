-- most likely unused
function Star(_x, _y, _radius, _drawTag) 

	add(world, {
		id = {
			class = "star"
		},
		pos = {
			x = _x,
			y = _y
		},
		vel = {
			x = 0,
			y = rnd(1.5)
		},
		star = {
			radius = _radius
		},
		loopingStar = true,
		drawTag = _drawTag,
		draw = function(self)
			ngon(
				self.pos.x,
				self.pos.y,
				flr(self.star.radius),
				4,
				13
			)
		end
	})
end