function Asteroid(_type, _x, _y, _vx, _vy)

	local _w, _h, _hp, _spr, _sprSize

	if (_type == "large") then
		_w, _h = 14, 14
		_hp = 3
		_spr = randomOneAmong({64, 66, 68, 70, 72})
		_sprSize = 2
	elseif  (_type == "medium") then
		_w, _h = 10, 10
		_hp = 2
		_spr = randomOneAmong({96, 98, 100})
		_sprSize = 2
	elseif  (_type == "small") then
		_w, _h = 7, 7
		_hp = 1
		_spr = randomOneAmong({102, 103, 104, 105})
		_sprSize = 1
	end

	add(world, {
		id = {
			class = "enemy",
			subclass = "asteroid",
			size = _type
		},
		pos = {
			x = _x,
			y = _y
		},
		vel = {
			x = _vx,
			y = _vy
		},
		box = {
			w = _w,
			h = _h
		},
		asteroid = {
			sprite = _spr,
			spriteSize = _sprSize
		},
		harvestee = {
			beingHarvested = false,
			indicatorRadius = 0
		},
		hitframe = false,
		hp = _hp,
		outOfBoundsDestroy = true,
		shadow = true,
		drawTag = "actor",
		draw = function(self, _offset)
			_offset = _offset or 0
			spr(self.asteroid.sprite, self.pos.x+_offset, self.pos.y+_offset,
				self.asteroid.spriteSize, self.asteroid.spriteSize)

			if (self.harvestee.beingHarvested) then
				circfill(gecx(self), gecy(self),
					self.harvestee.indicatorRadius, 11)
			end
		end
	})
end