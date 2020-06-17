SplashState = {
	name = "splash",
	splashTimer,
	init = function(self)
		fadeIn()
		self.splashTimer = 45
	end,
	update = function(self)
		if (self.splashTimer > 0) then
			self.splashTimer -= 1
		else
			transit(MenuState)
		end
	end,
	draw = function()
		spr(136, 32, 48, 64, 32)
	end
}