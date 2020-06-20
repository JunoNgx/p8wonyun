-- This state displays a message for exposition
-- prior to transiting into gameplay state
CaptionState = {
	name = "caption",
	init = function()
		if (G.shipNo == 100) then sfx(26) end
		fadeModule:fade("in", 30)
	end,
	update = function()
		if (btnp(C.KEY_A)) then 
			if (G.shipNo == 100) then
				transit(MenuState)
			else
				transit(GameplayState)
			end
		end
	end,
	draw = function()
	
		local message = CAPTIONS[G.shipNo]
		if (G.shipNo == 100) then
			message = 
				"we have reached\n\nbut oh no\n\nthe mothership has fallen\n\n\nwe are too late\n\n\nall have been lost"
		end

		print(message, 16, 32, 7)
	end
}