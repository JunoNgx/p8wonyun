fadeModule = {
	timer = 0,
	projectedTimeTaken = 0,
	position = 0, -- full black
	velocity = 0,
	table = {
		-- position 15 is black
		-- position 0 is the original color
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{1,1,1,1,1,1,1,0,0,0,0,0,0,0,0},
		{2,2,2,2,2,2,1,1,1,0,0,0,0,0,0},
		{3,3,3,3,3,3,1,1,1,0,0,0,0,0,0},
		{4,4,4,2,2,2,2,2,1,1,0,0,0,0,0},
		{5,5,5,5,5,1,1,1,1,1,0,0,0,0,0},
		{6,6,13,13,13,13,5,5,5,5,1,1,1,0,0},
		{7,6,6,6,6,13,13,13,5,5,5,1,1,0,0},
		{8,8,8,8,2,2,2,2,2,2,0,0,0,0,0},
		{9,9,9,4,4,4,4,4,4,5,5,0,0,0,0},
		{10,10,9,9,9,4,4,4,5,5,5,5,0,0,0},
		{11,11,11,3,3,3,3,3,3,3,0,0,0,0,0},
		{12,12,12,12,12,3,3,1,1,1,1,1,1,0,0},
		{13,13,13,5,5,5,5,1,1,1,1,1,0,0,0},
		{14,14,14,13,4,4,2,2,2,2,2,1,1,0,0},
		{15,15,6,13,13,13,5,5,5,5,5,1,1,0,0}
	},
	fade = function(self, _mode, _durationInTicks)

		self.timer = 0
		self.projectedTimeTaken = _durationInTicks

		local _beginPos, _finalPos
		if (_mode == "in") then
			_beginPos = 15
			_finalPos = 1
		elseif (_mode == "out") then
			_beginPos = 1
			_finalPos = 15
		end

		self.position = _beginPos
		self.velocity = (_finalPos - _beginPos)/_durationInTicks
	end,
	update = function(self)
    	if self.timer >= self.projectedTimeTaken then return end
		self.timer += 1
		self.position += self.velocity
	end,
	draw = function(self)
		for c=0, 15 do
			pal(c, self.table[c+1][flr(self.position+1)], 1)
		end
	end
}
