TransitState = {
	name = "transit",
	timer = 0,
	destinationState,
	init = function()

	end,
	update = function(self)
		if (self.timer > 0) then
			self.timer -=1
		else 
			gameState = self.destinationState
			gameState:init()
		end
	end,
	draw = function(self)

	end
}

function transit(_state)
	fadeModule:fade("out", 30)
	gameState = TransitState
	TransitState.destinationState = _state
	TransitState.timer = 28
end