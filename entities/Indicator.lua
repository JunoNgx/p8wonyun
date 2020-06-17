-- warning for dulce
function Indicator(_x)

	sfx(12)
	add(world,{
		id = {
			class = "particle",
			subclass = "indicator"
        },
		pos = {
			x = _x,
			y = 0
		},
		particle = {
			lifetime = 0,
			lifetime_max = 30
		},
		drawTag = "particle",
		draw = function(self)
			pal(13, 14)
			spr(135, self.pos.x, self.pos.y, 1, 1)
			pal()
		end
	})
end