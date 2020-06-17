function RectSpark(_x, _y, _initradius, _lifetime_max, _color)
	
	add(world,{
		id = {
			class = "particle",
			subclass = "explosion"
        },
        pos = {
            x=_x,
            y=_y
		},
		particle = {
			lifetime = 0,
			lifetime_max = _lifetime_max,
		},
		spark = {
			radius = _initradius,
			color = _color
		},
		drawTag = "particle",
		draw = function(self)
			rect(
				self.pos.x - self.spark.radius,
				self.pos.y - self.spark.radius,
				self.pos.x + self.spark.radius,
				self.pos.y + self.spark.radius,
				self.spark.color
			)
		end
	})
end