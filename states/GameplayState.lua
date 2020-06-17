GameplayState = {
	name = "gameplay",
	layer11_y = 0,
	layer12_y = -256,
	layer2_y = 0,
	layer3_y = 0,
	won = false,

	-- the sole purpose of the existence of this variable
	-- is to fix a bug in which enemy fire sfx plays
	-- perpetually as the game fades when their fire rate
	-- is cooled down
	isRunning = true, 

	init = function(self)
		fadeIn()
		self.isRunning = true
		world = {}
		spawnerInit()
		G.travelledDistance = 0
		Player(64, 96)

		sfx(4)

		-- unused materials
		-- codes allowed to remain for educational purpose
		-- creating stars on the background and foreground

		-- for i=1,20 do
		-- 	Star(
		-- 		rnd(128), rnd(128),
		-- 		c.star_radius_min+rnd(c.star_radius_range),
		-- 		"background"
		-- 	)
		-- end

		-- for i=1,10 do
		-- 	Star(
		-- 		rnd(128), rnd(128),
		-- 		c.star_radius_min+rnd(c.star_radius_range)+2,
		-- 		"foreground"
		-- 	)
		-- end
	end,
	update = function(self)

		self.layer11_y += C.LAYER1_SCROLL_SPEED
		self.layer12_y += C.LAYER1_SCROLL_SPEED
		self.layer2_y += C.LAYER2_SCROLL_SPEED
		self.layer3_y += C.LAYER3_SCROLL_SPEED

		if (self.layer11_y > 255) then self.layer11_y = -256 end
		if (self.layer12_y > 255) then self.layer12_y = -256 end
		if (self.layer2_y > 128) then self.layer2_y = 0 end
		if (self.layer3_y > 128) then self.layer3_y = 0 end

		G.travelledDistance += 1;

		if (G.travelledDistance >= C.DESTINATION_DISTANCE and getPlayer() and not self.won) then
			exitGameplay("win")

			p = getPlayer()
			p.playerControl = false
			p.keepInScreen = false
			p.vel.x=0
			p.vel.y-=7

			self.won = true
			sfx(25)
		end

		spawnerUpdate()
		screenshakeUpdate()

		-- the bulk of the game logic
		-- iterating through systems
		for _, system in pairs(updateSystems) do
			system(world)
		end
	end,
	draw = function(self)

		-- background draw, floor
		map(0, 0, 0, self.layer11_y, 16, 32)
		map(16, 0, 0, self.layer12_y, 16, 32)

		-- main game draw
		-- for _, system in pairs(drawsystems) do
		-- 	system(world)
		-- end
		for system in all(drawSystems) do
			system(world)
		end

		-- layer 2, foreground, lower side rails
		pal(13, 5)

		map(32, 0, 0, self.layer2_y, 3, 16)
		map(32, 0, 0, self.layer2_y-128, 3, 16)

		map(35, 0, 104, self.layer2_y, 3, 16)
		map(35, 0, 104, self.layer2_y-128, 3, 16)

		pal(13, 6)

		-- layer 3, foreground, upper side rails
		pal(13, 6)

		map(32, 16, 0, self.layer3_y, 3, 16)
		map(32, 16, 0, self.layer3_y-128, 3, 16)
		
		map(35, 16, 104, self.layer3_y, 3, 16)
		map(35, 16, 104, self.layer3_y-128, 3, 16)

		pal()
		
		local progress = 128*(G.travelledDistance/C.DESTINATION_DISTANCE)
		line(0, 128, 0, 128 - progress, 14)

		-- for debug
		-- color()
		-- print(spawn.cooldownEnemy)
	end
}

function exitGameplay(_outcome)
	GameplayState.isRunning = false
	if _outcome == "lose" then
		G.shipNo += 1
		Timer(3, function()
			transit(MenuState)
		end)
	elseif _outcome == "win" then
		G.shipNo = 100
		Timer(4, function()
			transit(CaptionState)
		end)
	end
end