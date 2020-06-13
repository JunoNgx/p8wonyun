pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- wonyun trench run
-- by juno nguyen
-- @junongx

-- huge table of constants for game design tuning
c = {
	draw_hitbox_debug = false,

	destination_distance = 2000, -- in ticks, 9000 ticks = 5 mins

	shadow_offset = 2,
	bounds_offset = 32,
	bounds_offset_top = 64, -- a lot more things happen on top of the screen
	bounds_offset_bottom = 8,
	bounds_safe = 16,
	spawn_bound_lf = 16,
	spawn_bound_rt = 127 - 16 *2,

	layer1_scroll_speed = 2,
	layer2_scroll_speed = 3,
	layer3_scroll_speed = 6,

	player_firerate = 5, -- firerates are all in ticks
	player_speed_fast = 5,
	player_speed_slow = 1,

	player_starting_hp = 1,

	player_ammo_start = 8,
	player_ammo_max = 8,

	harvest_distance_small = 12,
	harvest_distance_medium = 15,
	harvest_distance_large = 20,
	harvest_complete = 60, -- 2 seconds

	fbullet_speed = -12,

	spawnrate_enemy_min = 60,
	spawnrate_enemy_range = 45,
	spawnrate_asteroid_min = 45,
	spawnrate_asteroid_max = 45,

	riley_move_vy = 1,
	riley_firerate = 45,
	riley_bullet_vel = 1.5,

	dulce_move_vy = 5,
	dulce_firerate = 7,
	dulce_bullet_vy = 2,

	augustus_move_vy = 1,
	augustus_firerate = 30,
	augustus_bullet_medial_vy = 2,
	augustus_bullet_lateral_vx = 1,
	augustus_bullet_lateral_vy = 1.5,

	hammerhead_move_vy = 1,
	hammerhead_firerate = 30,
	hammerhead_bullet_vx = 2,
	hammerhead_bullet_vy = 1,

	koltar_firerate = 30,
	koltar_bullet_vel = 2,

	asteroid_large_vel_max = 1.5,

	explosion_increment_rate = 2,	
	explosion_small_amt = 4,
	explosion_small_amt_range = 3,
	explosion_medium_amt = 6,
	explosion_medium_amt_range = 4,
	explosion_large_amt = 8,
	explosion_large_amt_range = 5,

	star_radius_min = 1,
	star_radius_range = 3,

	smoke_radius_init = 10,
	smoke_radius_range = 5,
	smoke_decrement_rate = 0.5,

	carcass_move_vy = 2,

	-- explosion_offset_range = 0,
}

-- sfx note
-- 00 player fire
-- 01 small explosion
-- 02 medium explosion

-- table for sprite position of explosion table
--   	each position of the table will provide
-- 	  	the corresponding sprite number (in the sprite sheet)
--    	and the width/height to display the sprite appropriately
--     	e.g. frame 5 will display sprite 010 with the range of 2
-- 		spr no, offsets, spr width/height range
--		offset is needed as not all sprites are of equal sizes
-- explosion_animation_table = {
-- 	{15,  0, 1},
-- 	{14,  0, 1},
-- 	{13,  0, 1},
-- 	{12,  0, 1},
-- 	{10, -4, 2},
-- 	{42, -4, 2},
-- 	{44, -4, 2},
-- }

-- fade table from color 8 to 0 in 16 steps
f820t = {8,8,8,8,8,8,8,2,2,2,2,2,2,0,0}
f720t = {7,6,6,6,6,13,13,13,5,5,5,1,1,0,0}

g = {
	ship_no = 1,
	travelled_distance = 0,
	carcasses = {},
}

-- 24 messages for caption state
-- corresponding to 24 lives
m = {
	"wonyun base is under siege\nthe kaedeni are invading\n\na runner ship must be sent\nfor help\n\nmothership must be alerted\nfor reinforcement", --1
	"if they want war\nlet's give them war\n\ngo out there\nand kill them all", -- 2
	"sometimes, it's necessary to\nslown down\n\nhold 🅾️ while moving\nto slowdown", -- 3
	"there are so many of them\n\nbut we have no choice\n\nwe must take flight\n\nmothership depends on us", -- 4
	"use the asteroids\nto your advantages\n\nstay behind them for cover\nand replenish ammunition\nby staying nearby\n\nbeware of\nasteroid fragments", -- 5
	"watch out for\nthe bomber dulce\nthey can be dangerous\n\nlook for\nthe warning indicator\n\ngodspeed and safe flight", -- 6
	"after all these times\nthe kaedeni have finally\nsought vengeance\n\nmaybe we deserve it", -- 7
	"i miss home\n\nbut there won't be a home\nto come back to\n\nif we fail", --8
	"it's such a long way\n\nsuch a long long way", -- 9
	"someone has just\ntaken their own life\n\nfalling into the hands\nof the Kaedeni\nwon't be pleasant\n\nmaybe we should do the same", -- 10
	"if you make it back\nplease tell my family that\n\ni love them\n\nif you ever make it back\nthat is", --11
	"this is\nour last chance\n\nelse all is lost\n\nnot just for us", --12
}

-->8
-- component entity system and utility functions

-- these two functions are responsible for the entire ces
-- check if entity has all the components
function _has(e, ks)
	for c in all(ks) do
        if not e[c] then return false end
    end
    return true
end

-- iterate through entire table of entities (world)
-- run a custom function via the second parameter
function system(ks, f)
    return function(system)
        for e in all(system) do
            if _has(e, ks) then f(e) end
        end
    end
end

-- return of list with entity owning the corresponding id class
function getentitiesbyclass(_class, _world)
    local filtered_entities = {}
    for e in all(_world) do
		if not e.id then return end
		if (e.id.class == _class) then
			add(filtered_entities, e)
		end
    end
    return filtered_entities
end

function getentitiesbysubclass(_subclass, _world)
    local filtered_entities = {}
	for e in all(_world) do
		if not (e.id) then return end
		-- if not (e.id.subclass) then return end
		if (e.id.subclass == _subclass) then
			add(filtered_entities, e)
		end
    end
    return filtered_entities
end

-- function getentitiesbysubclass(_subclass, _world)
--     local filtered_entities = {}
-- 	for e in all(_world) do
-- 		if (e.id and e.id.subclass) then
-- 			-- if (e.id.subclass) then
-- 				if (e.id.subclass == _subclass) then
-- 					add(filtered_entities, e)
-- 				end
-- 			-- end
-- 		end
--     end
--     return filtered_entities
-- end

-- basic AABB collision detection using pos and box components
function coll(e1, e2)
    if e1.pos.x < e2.pos.x + e2.box.w and
        e1.pos.x + e1.box.w > e2.pos.x and
        e1.pos.y < e2.pos.y + e2.box.h and
        e1.pos.y + e1.box.h > e2.pos.y then

        return true
    end
    return false
end

-- function sortedbydrawlayeradd(_system, _e)
-- 	add(_system, _e)
-- 	-- printh(#_system)
-- 	-- if (_e.drawlayer) then printh(_e.id.class) end
-- 	if _e.drawlayer then
-- 		-- printh(_e.id.class.._e.drawlayer)
		
-- 	-- 	-- local debuglog = ""
-- 	-- 	-- for i=1, #world do
-- 	-- 	-- 	debuglog = debuglog..world[i].id.class
-- 	-- 	-- end
		

-- 		for i=1,#_system do
-- 			if _system[i].drawlayer then
-- 				if _e.drawlayer < _system[i].drawlayer then 
-- 					-- printh(_system[i].drawlayer)
-- 					-- shift all remaining entities by one index
-- 					-- for j=#_system-1, i do
-- 					-- 	_system[j+1] = _system[j]
-- 					-- end
-- 					-- _system[i] = _e
-- 				end
-- 			end
-- 		end
-- 	end

-- end

function palall(_color) -- switch all colors to target color
	for color=1, 15 do 
		pal(color, _color)
	end
end

-- switch all color to white (7) for a flashing effect when entity is damaged
function palforhitframe(_entity) 
	if (_entity.hitframe) then palall(7) end
end

fader = {
	time = 0,
	pos = 0, -- full black, according to the table
	projected_time_taken = 0,
	projected_velocity = 0,
	table= {
		-- position 15 is all blackju
		-- position 0 is all bright colors
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
	}
}

function fadein()
	fade(15, 0, 1)
end

function fadeout()
	fade(0, 15, 1)
end

function fade(_begin, _final, _durationinsecs)
	-- 30 ticks equal one second
	fader.projected_time_taken = _durationinsecs * 30
	-- elementary math of v = d/t
	fader.projected_velocity = (_final - _begin) / fader.projected_time_taken
	fader.pos = _begin
	fader.time = 0
	fader.status = "working"

end

function fade_update()
	-- TODO clean up and write something more optimal
	if (fader.time < fader.projected_time_taken) then
		fader.time +=1
		fader.pos += fader.projected_velocity
	end
end

function fade_draw(_position)
	-- for debug
	for c=0,15 do
		if flr(_position+1)>=16 then
			pal(c,0)
		else
			pal(
				c,
				fader.table[c+1][flr(_position+1)],
				1
			)
		end
	end
end

function fadesettrigger(_trigger)
	if _trigger then
		fader.trigger = _trigger
		fader.triggerperformed = false
	end
end

-- polygon draw, taken from wiki
function ngon(x, y, r, n, color)
	line(color)
	for i=0,n do
		local angle = i/n
		line(x + r*cos(angle), y + r*sin(angle))
	end
end

-- get entity's centralised x or y point
function gecx(entity)
	return entity.pos.x + entity.box.w/2
end

function gecy(entity)
	return entity.pos.y + entity.box.h/2
end
 
-- utility random method
function rnd_one_among(object)
	local die = ceil(rnd(#object))

	return object[die]
end

function distance(x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	return sqrt(dx*dx + dy*dy)
end

function getplayer(_world)
	for e in all(world) do
		if not e.id then break end
		if (e.id.class == "player") then return e end
	end
	return nil
end

-->8
-- primary game loops

-- each state is an object with loop functions

splashstate = {
	name = "splash",
	splashtimer,
	init = function(self)
		fadein()
		self.splashtimer = 45
	end,
	update = function(self)
		if (self.splashtimer > 0) then
			self.splashtimer -= 1
		else
			transit(menustate)
		end
	end,
	draw = function()
		-- draw logo at sprite number 64
		spr(136, 32, 48, 64, 32)
	end
}

menustate = {
	name = "menu",
	page = "middle",
	init = function(self)
		self.page = "main"
		fadein()
		saveprogress()
	end,
	update = function(self)

		if (self.page == "main") then
			if (btnp(0)) then self.page = "credits" end
			if (btnp(1)) then self.page = "manual" end
			if (g.ship_no<12 and btnp(4)) then
				transit(captionstate)
			end
		elseif (self.page == "credits") then
			if (btnp(1) or btnp(5)) then self.page = "main" end
		elseif (self.page == "manual") then
			if (btnp(0) or btnp(5)) then self.page = "main" end
		end

	end,
	draw = function(self)
		-- rectfill(0,0,127,127,1)
		if (self.page == "main") then
			
			print("wonyun trench run", 16, 16, 8)
			print("a game by juno nguyen", 16, 24, 10)

			local shipno = (g.ship_no<12) and g.ship_no or "no ship left"
			if g.ship_no == 100 then shipno = "mothership is lost" end
			print("ship no: "..shipno, 16, 40, 6)

			-- grey dots representing lost ships
			for j=1,2 do
				for i=1,6 do
					circfill(8+16*i, 48+10*j, 3, 5)
				end
			end

			-- blue dots representing available ships
			local sn = 13 - g.ship_no -- number of ships left

			-- looping the loopable portion/quotient
			for j=1,flr(sn/6) do
				for i=1,6 do
					circfill(8+16*i, 48+10*j, 3, 12)
				end
			end
			-- looping the remainder
			for i=1,sn % 6 do
				circfill(8+16*i, 48+10*(flr(sn/6)+1), 3, 12)
			end
			-- print("lives left: 47", 16, 32, 7)
			-- print("weapon level: 2", 16, 64, 7)
			-- print("armor level: 4", 16, 72, 7)
			-- print("press x to send another ship", 16, 120, 7)
			-- spr(1, 12, 12)

			spr(134, 0, 80, 1, 2)
			print("credits", 10, 86, 6)
			spr(135, 127-8, 80, 1, 2)
			print("manual", 94, 86, 6)

			if (g.ship_no<12) then
				print("press ❎ to send", 64-#"press ❎ to send"*2, 104, 12)
				print("another ship", 64-#"another ship"*2, 112, 12)
			else
				print("all is lost", 64-#"press ❎ to send"*2, 96, 12)
				print("erase your savedata", 64-#"erase your savedata"*2, 104, 8)
				print("to try again", 64-#"to try again"*2, 112, 12)
			end
			
		elseif (self.page == "credits") then

			print("wonyun trench run", 64-#"wonyun trench run"*2, 16, 8)
			print("june 2020", 64-#"June 2020"*2, 24, 7)

			print("programming",
				64-#"programming"*2,
				40, 7
			)
			print("art, and audio by",
				64-#"art, and audio by"*2,
				48, 7
			)
			print("juno nguyen",
				64-#"juno nguyen"*2,
				64, 8
			)
			print("@junongx",
				64-#"@junongx"*2,
				72, 12
			)
			print("very special thanks",
				64-#"very special thanks"*2,
				88, 7
			)
			print("rgcddev",
				64-#"rgcddev"*2,
				96, 12
			)
			print("for the inspiration",
				64-#"for the inspiration"*2,
				104, 7
			)

			-- spr(135, 127-8, 80, 1, 2)
			-- print("back", 112, 100, 7)

		elseif (self.page == "manual") then
			
			spr(0, 60, 12, 2, 2)

			for i=1,4 do
				circ(64-7, 16+9-i*2, 0, 11)
			end

			for i=1,4 do
				circ(64+7, 16+9-i*2, 0, 12)
			end

			print("hp\nindicator", 16, 12, 11)
			print("ammo\nindicator\n(max: 8)", 76, 12, 12)
			print("use ⬅️⬇️⬆️➡️ to move", 16, 32, 7)
			print("use ⬅️⬇️⬆️➡️\nwhile holding 🅾️\nto move slowly\n(you'll need it)", 16, 40, 7)
			print("press ❎ to fire\n(consumes ammo)", 16, 72, 7)
			print("enclose asteroids\nto harvest ammo", 16, 88, 7)

			spr(64, 88, 70, 2, 2)
			spr(0, 104, 88, 2, 2)
			line(96, 80, 108, 94, 11)

			line(0, 127, 0, 32, 14)
			print("your progress\nis displayed\non the left", 12, 106, 14)
			

			print("good luck!", 72, 112, 7)
			

			-- spr(134, 0, 104, 1, 2)
			-- print("back", 12, 110, 7)
		end
	end
}

-- This state displays a message for exposition
-- prior to transiting into gameplay state
captionstate = {
	name = "caption",
	init = function()
		-- load progress
		-- self.message = m[g.ship_no]
		fadein()
	end,
	update = function()
		if (btnp(4)) then 
			if (g.ship_no == 100) then
				transit(menustate)
			else
				transit(gameplaystate)
			end
		end
	end,
	draw = function()
	
		local message = m[g.ship_no]
		if (g.ship_no == 100) then
			message = 
				"we have reached\n\nbut oh no\n\nthe mothership has fallen\n\n\nwe are too late\n\n\nall has been lost"
		end

		print(message, 16, 32, 7)
	end
}

-- outrostate = {
-- 	init = function()
-- 		fadein()
-- 		g.ship_no = 100
-- 	end,
-- 	update = function()
-- 		if (btnp(4)) then 
-- 			transit(menustate)
-- 		end
-- 	end,
-- 	draw = function()
-- 		color(7)
-- 		local message = "we have reached\n\nbut oh no\n\nthe mothership has fallen\n\n\nwe are too late\n\n\nall has been lost"
-- 		print(message, 16, 32)
-- 	end
-- }

gameplaystate = {
	name = "gameplay",
	layer11_y = 0,
	layer12_y = -256,
	layer2_y = 0,
	layer3_y = 0,
	won = false,
	init = function(self)
		fadein()
		world = {}
		spawner_init()
		g.travelled_distance = 0
		player(64, 96)

		carcass(64,24)

		-- -- hammerhead(64, 32)
		-- -- hammerhead(32, 32)
		-- -- hammerhead(96, 32)

		-- -- augustus(64, 64)
	
		-- timer(1, function()
		-- 	hammerhead(12, 12)
		-- end)

		-- for i=1,20 do
		-- 	star(
		-- 		rnd(128), rnd(128),
		-- 		c.star_radius_min+rnd(c.star_radius_range),
		-- 		"background"
		-- 	)
		-- end

		-- for i=1,10 do
		-- 	star(
		-- 		rnd(128), rnd(128),
		-- 		c.star_radius_min+rnd(c.star_radius_range)+2,
		-- 		"foreground"
		-- 	)
		-- end
	end,
	update = function(self)
		self.layer11_y += c.layer1_scroll_speed
		self.layer12_y += c.layer1_scroll_speed
		self.layer2_y += c.layer2_scroll_speed
		self.layer3_y += c.layer3_scroll_speed

		if (self.layer11_y > 255) then self.layer11_y = -256 end
		if (self.layer12_y > 255) then self.layer12_y = -256 end
		if (self.layer2_y > 128) then self.layer2_y = 0 end
		if (self.layer3_y > 128) then self.layer3_y = 0 end

		g.travelled_distance += 1;

		if (g.travelled_distance >= c.destination_distance and not self.won) then
			exitgameplay("win")
			-- TODO removes keepsinbounds, playercontrol, collision
			-- TODO mark game is won
			self.won = true
		end

		spawner_update()
		screenshake_update()
		for key,system in pairs(updatesystems) do
			system(world)
		end
	end,
	draw = function(self)

		-- background draw, floor
		map(0, 0, 0, self.layer11_y, 16, 32)
		map(16, 0, 0, self.layer12_y, 16, 32)

		-- main game draw
		for system in all(drawsys) do
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
		
		local progress = 128*(g.travelled_distance/c.destination_distance)
		line(0, 128, 0, 128 - progress, 14)

		-- debug
		print(#world)
		print(spawn.last_spawn)
		-- print(self.layer11_y)
		-- print(self.layer12_y)
	end
}

-- transitor = {
-- 	timer = 0,
-- 	destination_state,
-- }


transitstate = {
	name = "transit",
	timer = 0,
	destination_state,
	init = function()

	end,
	update = function(self)
		if (self.timer > 0) then
			self.timer -=1
		else 
			gamestate = self.destination_state
			gamestate:init()
		end
	end,
	draw = function(self)

	end
}

function transit(_state)
	fadeout()
	gamestate = transitstate
	transitstate.destination_state = _state
	transitstate.timer = 28
end

function exitgameplay(_outcome)
	if _outcome == "lose" then
		g.ship_no += 1
		timer(3, function()
			transit(menustate)
		end)
	elseif _outcome == "win" then
		g.ship_no = 100
		timer(4, function()
			transit(captionstate)
		end)
	end
end

-- -- spawning carcasses of previous dead spots
-- function carcass_diary_gameplay_update()
-- 	-- TODO for carcass in all(g.carcasses) do
-- 		-- if g.travel_distance == carcass then
-- 			-- carcass()
-- 		-- end
-- end

menuitem(3, "erase savedata", function()
	dset("carcasses", nil)
	dset("ship_no", 1)
	run()
end)


function loadprogress()
	g.ship_no = dget("ship_no") == 0 and 1 or dget("ship_no")
end

function saveprogress()
	dset("ship_no", g.ship_no)
end

function _init()
	cartdata("wonyun-junongx")
	loadprogress()
	-- gamestate = splashstate
	gamestate = gameplaystate
	-- gamestate = menustate
	-- gamestate = outrostate
	gamestate:init()
end

function _update()
	gamestate:update()
	fade_update()
end

function _draw()
	-- due to interference with fading
	if (gamestate.name ~= "transit") then cls() end

	gamestate:draw()
	fade_draw(fader.pos)
end

-->8
-- update system

updatesystems = {
	timersys = system ({"timer"},
		function(e)
			if (e.timer.lifetime > 0) then
				e.timer.lifetime -= 1
			else
				e.timer.trigger()
				del(world, e)
			end
		end
	),
	motionsys = system({"pos", "vel"},
		function(e) 
			e.pos.x += e.vel.x
			e.pos.y += e.vel.y
		end
	),
	animationsys = system({"ani"},
		function(e)
			if (e.ani.loop) then
				e.ani.frame += e.ani.framerate
				if (e.ani.frame >= e.ani.framecount) then
					e.ani.frame = 0
				end
			else
				if (e.ani.frame < e.ani.framecount-1) then
					e.ani.frame += e.ani.framerate
				end
			end
			
		end
		-- function(e)
		-- 	if (e.ani.loop) then
		-- 		if (e.ani.frame < e.ani.framecount) then -- so hacky
		-- 			e.ani.frame += e.ani.framerate
		-- 		else
		-- 			e.ani.frame = 0
		-- 		end
		-- 	else
		-- 		if (e.ani.frame < e.ani.framecount-1) then
		-- 			e.ani.frame += e.ani.framerate
		-- 		end
		-- 	end
			
		-- end
	),
	collisionsys = system({"id", "pos", "box"},
		function(e1)

			-- player 
			if (e1.id.class == "player") then

				-- player vs ebullet
				local ebullets = getentitiesbysubclass("ebullet", world)
				for e2 in all(ebullets) do
					if coll(e1, e2) then
						e1.hp -=1
						del(world, e2)
						-- sfx hit
					end
				end

				-- player vs asteroid/enemy
				local enemies = getentitiesbyclass("enemy", world)
				for e2 in all(enemies) do
					if coll(e1, e2) then
						e2.hp = 0
						e1.hp -= 1
					end
				end

			-- -- asteroid vs asteroid
			-- feature cancelled due to mechanical complications
			-- elseif (e1.id.class == "enemy") then
			-- 	if (e1.id.subclass == "asteroid") then
			-- 		asteroids = getentitiesbysubclass("asteroid", world)
			-- 		del(asteroids, e1)

			-- 		for e2 in all(asteroids) do
			-- 			if coll(e1, e2) then
			-- 				-- e1.hp -= 1
			-- 				e1.hitframe = true
			-- 				-- e2.hp -= 1
			-- 				-- e2.hitframe = true
			-- 			end
			-- 		end
			-- 	end

			-- friendly bullet vs enemy
			elseif (e1.id.subclass == "fbullet") then
				local enemies = getentitiesbyclass("enemy", world)

				for e2 in all(enemies) do
					if coll(e1, e2) then
						del(world, e1)
						e2.hp -= 1
						e2.hitframe = true
					end
				end

			-- hostile bullet vs asteroid
			elseif (e1.id.subclass == "ebullet") then
				local asteroids = getentitiesbysubclass("asteroid", world)

				for e2 in all(asteroids) do
					if coll(e1, e2) then
						del(world, e1)
						e2.hp -= 1
						e2.hitframe = true
					end
				end
			end
		end
	),
	healthsys = system({"id", "hp"},
		function(e)
			if e.hp <= 0 then

				if (e.id.class == "enemy") then

					if (e.id.size == "small") then
						spawnexplosion("small", gecx(e), gecy(e))
						screenshake(5, 0.3)
						-- sfx(1)

					elseif (e.id.size == "medium") then
						spawnexplosion("medium", gecx(e), gecy(e))
						screenshake(7, 0.5)
						-- sfx(2)

						if (e.id.subclass == "asteroid") then
							spawn_from_asteroid("medium", gecx(e), gecy(e))
						end
					elseif (e.id.size == "large") then
						spawnexplosion("large", gecx(e), gecy(e))
						screenshake(8, 0.5)
						-- sfx(2)

						if (e.id.subclass == "asteroid") then
							spawn_from_asteroid("large", gecx(e), gecy(e))
						end
					end
					
				elseif (e.id.class == "player") then
					spawnexplosion("large", gecx(e), gecy(e))
					screenshake(8, 0.5)
					-- sfx(2)
					exitgameplay("lose")
				end

			del(world, e)

			end
		end
	),
	keepinscreenssys = system({"keepinscreen"},
		function(e)
			e.pos.x = min(e.pos.x, 115)
			e.pos.x = max(e.pos.x, 12)
			e.pos.y = min(e.pos.y, 115)
			e.pos.y = max(e.pos.y, 12)
		end
	),
	outofboundsdestroysys = system({"outofboundsdestroy"},
		function(e)

			if (e.pos.x > 127 + c.bounds_offset)
				or (e.pos.x < 0 - c.bounds_offset)
				or (e.pos.y > 127 + c.bounds_offset_bottom)
				or (e.pos.y < 0 - c.bounds_offset_top) then
				
				del(world, e)
			end
		end
	),
	particlesystem = system({"particle"},
		function(e)
			if (e.particle.lifetime < e.particle.lifetime_max) then
				e.particle.lifetime += 1
			else
				del(world, e)
			end
		end
	),
	explosionupdatesystem = system({"explosion"},
		function(e)
			e.explosion.radius += c.explosion_increment_rate
		end
	),
	smokeupdatesystem = system({"smoke"},
		function(e)
			e.smoke.radius -= c.smoke_decrement_rate
		end
	),
	loopingstarsystem = system({"loopingstar"},
		function(e)
			if (e.pos.y > 128+c.bounds_offset) then
				e.pos.x = rnd(128)
				e.pos.y = -c.bounds_offset
				e.vel.y = rnd(1.5)
			end
		end
	),

	-- harvesting system

	harvesteesystem = system({"harvestee"},
		function(e)
			if (e.harvestee.beingharvested) then
				-- local dr = 1

				-- e.harvestee.indicator_radius += dr
				
				-- if e.harvestee.indicator_radius < 1 
				-- 	or e.harvestee.indicator_radius > 3 then
					
				-- 	-- e.harvestee.indicator_radius -= 1
				-- 	dr = -dr
				-- end

				if (e.harvestee.indicator_radius > 2) then
					e.harvestee.indicator_radius -= 1
				else
					e.harvestee.indicator_radius += 1
				end
			end

			-- reset beingharvested status when player is dead
			if (not getplayer(world)) then
				e.harvestee.beingharvested = false
			end
		end
	),
	harvestersystem = system({"harvester"},
		function(e)
			asteroids = getentitiesbysubclass("asteroid", world)

			for a in all(asteroids) do
				-- local harvest_distance =
				-- 	(a.id.size == "large")
				-- 	and c.harvest_distance_large
				-- 	or c.harvest_distance_small

				-- a.harvestee.beingharvested = 
				-- 	distance(e.pos.x, e.pos.y, a.pos.x, a.pos.y) <= harvest_distance
				-- 	and true
				-- 	or false

				local harvest_distance

				if (a.id.size == "large") then
					harvest_distance = c.harvest_distance_large
				elseif (a.id.size == "medium") then
					harvest_distance = c.harvest_distance_medium
				elseif (a.id.size == "small") then
					harvest_distance = c.harvest_distance_small
				end

				if (distance(gecx(e),gecy(e), gecx(a), gecy(a))
					<= harvest_distance) then

					a.harvestee.beingharvested = true
					if (e.harvester.progress < c.harvest_complete) then
						e.harvester.progress +=1
					else
						e.harvester.progress = 0
						e.playerweapon.ammo = min(
							e.playerweapon.ammo + 1,
							c.player_ammo_max
						)
					end

				else 
					a.harvestee.beingharvested = false
				end
			end
		end
	),

	-- enemy weapon system
	enemyweaponsystem = system({"eweapon"},
		function(e)
			if (e.eweapon.cooldown > 0) then
				e.eweapon.cooldown -= 1;
			else 
				if (e.eweapon.type == "riley") then

					local p = getplayer(world)
					if p then -- making sure that player exists
						local angle, vx, vy
						angle = atan2(gecx(p)-gecx(e), gecy(p)- gecy(e))
						vx = c.riley_bullet_vel * cos(angle)
						vy = c.riley_bullet_vel * sin(angle)

						ebullet(gecx(e), gecy(e), vx, vy)
						e.eweapon.cooldown = c.riley_firerate
					end

				elseif (e.eweapon.type == "dulce") then
					ebullet(gecx(e), gecy(e), 0, c.dulce_bullet_vy)
					e.eweapon.cooldown = c.dulce_firerate
				elseif (e.eweapon.type == "hammerhead") then

					-- going clockwise from top right
					-- right firing
					ebullet(e.pos.x+6, e.pos.y+2, 
						c.hammerhead_bullet_vx,
						c.hammerhead_bullet_vy
					)
					ebullet(e.pos.x+6, e.pos.y+12,
						c.hammerhead_bullet_vx,
						c.hammerhead_bullet_vy
					)

					-- left firing
					ebullet(e.pos.x-2, e.pos.y+2,
						-c.hammerhead_bullet_vx,
						c.hammerhead_bullet_vy
					)
					ebullet(e.pos.x-2, e.pos.y+12,
						-c.hammerhead_bullet_vx,
						c.hammerhead_bullet_vy
					)

					e.eweapon.cooldown = c.hammerhead_firerate
				elseif (e.eweapon.type == "augustus") then

					-- medial bullet
					ebullet(e.pos.x+6, e.pos.y+16, 0, c.augustus_bullet_medial_vy)

					-- lateral bullets
					ebullet(e.pos.x+5, e.pos.y+16,
						-c.augustus_bullet_lateral_vx, 
						c.augustus_bullet_lateral_vy
					)
					ebullet(e.pos.x+7, e.pos.y+16,
						c.augustus_bullet_lateral_vx, 
						c.augustus_bullet_lateral_vy
					)

					e.eweapon.cooldown = c.augustus_firerate
				elseif (e.eweapon.type == "koltar") then

					local offset_x, offset_y = 15, 6

					-- going clockwise from top
					if (e.eweapon.firemode == 0) then
						
						ebullet(e.pos.x+offset_x, e.pos.y+offset_y,
							0,
							-c.koltar_bullet_vel
						)
						ebullet(e.pos.x+offset_x, e.pos.y+offset_y,
							c.koltar_bullet_vel,
							0
						)
						ebullet(e.pos.x+offset_x, e.pos.y+offset_y,
							0,
							c.koltar_bullet_vel
						)
						ebullet(e.pos.x+offset_x, e.pos.y+offset_y,
							-c.koltar_bullet_vel,
							0
						)

						e.eweapon.firemode = 1

					elseif (e.eweapon.firemode == 1) then

						local magnitude = c.koltar_bullet_vel * 0.707

						ebullet(e.pos.x+offset_x, e.pos.y+offset_y,
							magnitude, -magnitude
						)

						ebullet(e.pos.x+offset_x, e.pos.y+offset_y,
							magnitude, magnitude
						)

						ebullet(e.pos.x+offset_x, e.pos.y+offset_y,
							-magnitude, magnitude
						)

						ebullet(e.pos.x+offset_x, e.pos.y+offset_y,
							-magnitude, -magnitude
						)

						e.eweapon.firemode = 0
					end

					e.eweapon.cooldown = c.koltar_firerate

				end
			end
		end
	),

	-- player-related systems
	playerweaponsystem = system({"playerweapon"},
	function(e)
		if (e.playerweapon.cooldown >0) then
			e.playerweapon.cooldown -= 1
		end
	end
	),
	controlsys = system({"playercontrol"},
		function(e)

			-- local speed_value = (btn(4)) and c.player_speed_slow or c.player_speed_fast
			-- local angle, speed

			-- if (btn(0) or btn(1) or btn(2) or btn (3)) then
			-- 	speed = speed_value
			-- else 
			-- 	speed = 0
			-- end

			-- if (btn(0)) then 
			-- 	if (btn(2)) then
			-- 		angle = 0.625
			-- 	elseif (btn(3)) then
			-- 		angle = 0.325
			-- 	else 
			-- 		angle = 0.5
			-- 	end
			-- elseif (btn(1)) then
			-- 	if (btn(2)) then
			-- 		angle = 0.825
			-- 	elseif (btn(3)) then
			-- 		angle = 0.125
			-- 	else 
			-- 		angle = 0.0
			-- 	end
			-- elseif (btn(2)) then
			-- 	angle = 0.75
			-- elseif (btn(3)) then
			-- 	angle = 0.25
			-- end

			-- e.vel.x = speed * cos(angle)
			-- e.vel.y = speed * -sin(angle) -- y axis is inverted

			local speed = (btn(5)) and c.player_speed_slow or c.player_speed_fast

			e.vel.x, e.vel.y = 0, 0

			if (btn(0)) e.vel.x = -speed
			if (btn(1)) e.vel.x = speed
			if (btn(2)) e.vel.y = -speed
			if (btn(3)) e.vel.y = speed

			-- diagonal etiquette
			if (e.vel.x * e.vel.y ~= 0) then
				e.vel.x *= cos(0.125) -- 45 degrees
				e.vel.y *= -sin(0.125) -- y axis is inverted
			end


			if (btnp(4)) then
				if (e.playerweapon.cooldown <=0
					and e.playerweapon.ammo > 0) then
					-- screenshake(2, 0.1)
					sfx(0)
					fbullet(e.pos.x, e.pos.y-5)
					e.playerweapon.cooldown = c.player_firerate
					e.playerweapon.ammo -= 1
				end
			end
			
		end
	)
}

-->8
-- draw systems

drawsys = {

	system({"draw", "drawtag"},
		function(e)
			if (e.drawtag == "background") then
				e:draw()
			end
		end
	),

	-- draw shadow
	system({"draw", "shadow"},
		function(e)
			palall(0)
			e:draw(c.shadow_offset)
			pal()
		end
	),

	-- draw actors
	system({"id", "draw", "drawtag"},
		function(e)
			if (e.drawtag == "actor") then

				-- flashing white color when entity is damaged
				if (e.hitframe) then
					palforhitframe(e)
				end

				e:draw() -- the important line

				if (e.hitframe) then 
					e.hitframe = false
					pal()
				end

			end
		end
	),

	-- draw projectiles
	system({"id", "draw", "drawtag"},
		function(e)
			if (e.drawtag == "projectile") then
					e:draw() -- the important line
			end
		end
	),

	-- draw particles
	system({"id", "draw", "drawtag"},
		function(e)
			if (e.drawtag == "particle") then
					e:draw() -- the important line
			end
		end
	),

	system({"draw", "drawtag"},
		function(e)
			if (e.drawtag == "foreground") then
				e:draw()
			end
		end
	),

	-- diegetic ui draw
	system({"id", "draw"},
		function(e)

			-- 
			if (e.id.class == "player") then
				-- left gauge, hp
				for i=1,(e.hp) do
					circ(gecx(e)-7, gecy(e)+9-i*2, 0, 11)
				end

				-- right gauge, ammo
				for i=1,(e.playerweapon.ammo) do
					circ(gecx(e)+7, gecy(e)+9-i*2, 0, 12)
				end

				-- draw harvesting indicator, a green line
				asteroids = getentitiesbysubclass("asteroid", world)
				for a in all(asteroids) do
					if a.harvestee.beingharvested then
						line(gecx(e), gecy(e), gecx(a), gecy(a), 11)
					end
				end

			-- elseif (e.id.class == "enemy") then
			-- 	-- if (e.id.subclass == "hammerhead") then
			-- 		-- left gauge, hp
			-- 		for i=1,(e.hp) do
			-- 			circ(e.pos.x-5, e.pos.y + 16 - i*2, 0, 11)
			-- 		end
			-- 	-- end
			end
		end
	),

	-- draw collision boxes, for debug purposes
	system({"pos", "box"},
		function(e)
			if (c.draw_hitbox_debug) then
				rect(e.pos.x, e.pos.y, e.pos.x + e.box.w, e.pos.y+ e.box.h, 8)
			end
		end
	),
}

-->8
-- spawner functions
spawn = {
	cooldown_enemy,
	cooldown_asteroid,
	last_spawn
}

function spawner_init()
	spawn.cooldown_enemy = 90 +rnd(60)
	spawn.cooldown_asteroid = 60 + rnd(60)
	spawn.last_spawn = ""
end

function spawner_update()

	for c in all(g.carcasses) do
		if g.travelled_distance == c.y then
			carcass(c.x, -16)
		end
	end


	if spawn.cooldown_enemy > 0 then
		spawn.cooldown_enemy -= 1
	else 
		spawn_enemy()
		spawn.cooldown_enemy = 
			c.spawnrate_enemy_min + rnd(c.spawnrate_enemy_range)
	end
	
	if spawn.cooldown_asteroid > 0 then
		spawn.cooldown_asteroid -= 1
	else 
		spawn_asteroid()
		spawn.cooldown_asteroid = 
			c.spawnrate_asteroid_min + rnd(c.spawnrate_asteroid_range)
	end
end

function rndyspawn()
 	return -c.bounds_safe-rnd(c.bounds_offset_top-c.bounds_safe)
end

function rndxspawn()
	return c.bounds_safe + rnd(127 - c.bounds_safe*2)
end

function spawn_enemy()
	-- local _difficulty = rnd_one_among({"low", "medium", "high"})
	
	local _difficulty, die
	die = rnd()
	if (die >= 0.5 and die < 0.75) then _difficulty = "medium"
	elseif (die >= 0.75) then _difficulty = "high"
	else _difficulty = "low" end

	if (_difficulty == "low") then

		local die = rnd_one_among({"riley", "hammerhead", "augustus"})

		-- one riley
		if (die == "riley") then
			riley(rndxspawn(), rndyspawn())
			spawn.last_spawn = "riley-easy"

		-- -- one dulce
		-- elseif (die == "dulce") then
		-- 	dulce(2+ceil(rnd(125)), -rnd(c.bounds_offset))

		-- one hammerhead
		elseif (die == "hammerhead") then
			hammerhead(rndxspawn(), rndyspawn())
			spawn.last_spawn = "hammerhead-easy"

		-- one augustus
		elseif (die == "augustus") then
			augustus(rndxspawn(), rndyspawn())
			spawn.last_spawn = "augustus-easy"

		end

	elseif (_difficulty == "medium") then

		local die = rnd_one_among({"riley", "dulce", "hammerhead", "koltar"})

		-- extra condition for koltar
		if (formation == "koltar" and
			-- only spawns from 25% of the progress
			-- not spawning twice in a row
			(g.travelled_distance/c.destination_distance < 0.25
			or spawn.last_spawn == "koltar")) then

			die = rnd_one_among({"riley", "dulce", "hammerhead"})
		end

		-- two rileys, aligned
		if (die == "riley") then

			local _y = rndyspawn()

			riley(127 * 1/3 - 5, _y)
			riley(127 * 2/3 - 5, _y)
			spawn.last_spawn = "riley-medium"

		-- one dulce, no formation
		elseif (die == "dulce") then
			dulce(rndxspawn(), rndyspawn())
			spawn.last_spawn = "dulce-medium"
			-- sfx for dulce

		-- two hammerheads
		elseif (die == "hammerhead") then

			hammerhead(127 * 1/3 - 5, rndyspawn())
			hammerhead(127 * 2/3 - 5, rndyspawn())
			spawn.last_spawn = "hammerhead-medium"

		-- -- two augustus, aligned
		-- elseif (die == "augustus") then

		-- 	local _y = -rnd(c.bounds_offset)

		-- 	augustus(127 * 1/3 - 5, _y)
		-- 	augustus(127 * 2/3 - 5, _y)

		-- one koltar, middle
		elseif (die == "koltar") then

			koltar(127/2 -16, -24)
			spawn.last_spawn = "koltar"
			-- sfx for koltar?

		end

	elseif (_difficulty == "high") then

		-- local die = rnd_one_among({1, 2, 3})
		local die, formation

		die = rnd()
		if (die >= 0.45) then
			formation = "riley"
		elseif (die >= 0.9) then
			formation = "augustus"
		else
			formation = "koltar"
		end

		-- extra condition for koltar
		if (formation == "koltar" and
			(g.travelled_distance/c.destination_distance < 0.5
			or spawn.last_spawn == "koltar")) then
			formation = rnd_one_among({"riley", "augustus"})
		end


		-- three rileys
		if (formation == "riley") then
			local _y = rndyspawn()

			riley(127 * 1/4 - 5, _y+8)
			riley(127 * 2/4 - 5, _y)
			riley(127 * 3/4 - 5, _y+8)
			spawn.last_spawn = "riley-hard"

		-- two augustus
		elseif (formation == "augustus") then

			local _y = rndyspawn()

			augustus(127 * 1/3 - 8, _y)
			augustus(127 * 2/3 - 8, _y)
			spawn.last_spawn = "augustus-hard"
			-- augustus(127 * 3/4 - 8, _y)

		-- two koltar
		elseif (formation == "koltar") then

			koltar(127 * 1/3 - 16, -24)
			koltar(127 * 2/3 - 16, -24)
			spawn.last_spawn = "koltar"

		end

	end
end

function spawn_asteroid()
	local _type, die
	die = rnd()
	
	if (die >= 0.75) then
		_type = "small"
	elseif (die >= 0.5) then
		_type = "medium"
	else
		_type = "large"
	end

	-- rnd_one_among({"small", "medium", "large"})
	asteroid(_type, rnd(128), rndyspawn(), 0, rnd(2))
end

-- function spawn_cooldown_reset()
-- 	spawncooldown = c.spawnrate_min + flr(rnd(c.spawnrate_range))
-- end

-- function spawn()
-- 	local die = ceil(rnd(6))
-- 	-- local die = 1

-- 	if (die == 2) then
-- 		hammerhead(rnd(128), -rnd(60))
-- 	elseif (die == 1) then
-- 		riley(rnd(128), -rnd(60))
-- 	elseif (die == 3) then
-- 		dulce(rnd(128), -rnd(60))	
-- 	elseif (die == 4) then
-- 		augustus(rnd(128), -rnd(60))
-- 	elseif (die == 5) then
-- 		koltar(rnd(128), -rnd(60))
-- 	elseif (die == 6) then
-- 		local _type = rnd_one_among({"small", "medium", "large"})
-- 		asteroid(_type, rnd(128), rnd(128), 0, rnd(2))
-- 	end
-- 	spawn_cooldown_reset()
-- end

screenshake_timer = 0
screenshake_mag = 0

function screenshake(_magnitude, _lengthinseconds)

	if (_lengthinseconds > screenshake_timer) then
		screenshake_timer = _lengthinseconds * 30
	end

	if (_magnitude > screenshake_mag) then
		screenshake_mag = _magnitude
	end
end

function screenshake_update()
	if (screenshake_timer>0) then
		screenshake_timer -= 1
		camera(rnd(screenshake_mag),rnd(screenshake_mag))
	else
		camera()
		screenshake_mag = 0
	end
end

function spawnexplosion(_size, _x, _y)

	if _size == "small" then
		explosion(_x, _y, 6)
		puffsofsmoke(
			c.explosion_small_amt + rnd(c.explosion_small_amt_range),
			_x, _y
		)

	elseif _size == "medium" then
		explosion(_x, _y, 10)
		puffsofsmoke(
			c.explosion_medium_amt + rnd(c.explosion_medium_amt_range),
			_x, _y
		)
	elseif _size == "large" then
		explosion(_x, _y, 15)
		puffsofsmoke(
			c.explosion_large_amt + rnd(c.explosion_large_amt_range),
			_x, _y
		)
	end

	
end

function spawn_from_asteroid(_type, _x, _y)
	local die = ceil(rnd(3))
	local chance_for_medium = (_type=="large") and 0.3 or 0

	for i=1,die do
		local _type = rnd()<chance_for_medium and "medium" or "small"
		asteroid(_type, _x, _y, rnd(3)-1.5, rnd(3)-1.5)
	end
end

function puffsofsmoke(_maxamt, _x, _y)

	-- local smoke_offset = 16

	-- for i=1, _maxamt do	
	-- 	smoke(
	-- 		_x + rnd(smoke_offset) - 8,
	-- 		_y + rnd(smoke_offset) - 8,
	-- 		-- (rnd()-1)/5,
	-- 		-- (rnd()-1)/5
	-- 		0,
	-- 		0
	-- 	)
	-- end

	-- for i=1, 10 do	
	-- 	smoke(
	-- 		_x + rnd(32) - 20,
	-- 		_y + rnd(32) - 20,
	-- 		0,
	-- 		-1
	-- 	)
	-- end

	for i=1, _maxamt do
		smoke(
			_x + rnd(32) - 16,
			_y + rnd(32) - 16,
			0,
			-rnd(1)
		)
	end

end
 
-->8
-- entity constructors

function player(_x, _y)

    add(world, {
        id = {
			class = "player",
			subclass = "wonyun"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=0
        },
        box = {
            w = 2,
            h = 6
		},
		hp = c.player_starting_hp,
		playerweapon = {
			ammo = c.player_ammo_start,
			cooldown = 0
		},
		playercontrol = true,
		ani = {
			frame = 0, -- when working with table indexes, do not ever let it go zero
			framerate = 0.5,
			framecount = 4,
			loop = true
		},
		keepinscreen = true,
		harvester = {
			progress = 0
		},
		shadow = true,
		drawtag = "actor",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(0, self.pos.x-3+_offset, self.pos.y-4+_offset, 1.2, 2)

			spr(28+flr(self.ani.frame), self.pos.x-1, self.pos.y+9, 1, 1)

			-- local center = get_center(self)
			-- circ(gecx(self), gecy(self), 1, 11)
			-- pal()
			-- color(2)
			-- print(self.ani.frame)
			-- print("nd")
		end
	})
end

function hammerhead(_x, _y)

    add(world, {
        id = {
            class = "enemy",
			subclass = "hammerhead",
			size = "medium"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=c.hammerhead_move_vy
        },
        box = {
            w = 9,
            h = 16
		},
		hitframe = false,
		hp = 2,
		eweapon = {
			type = "hammerhead",
			cooldown = c.hammerhead_firerate
		},
		outofboundsdestroy = true,
		shadow = true,
		drawtag = "actor",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(32, self.pos.x-3+_offset, self.pos.y+_offset, 2, 2)
		end
    })
end

function riley(_x, _y)

    add(world, {
        id = {
            class = "enemy",
			subclass = "riley",
			size = "small"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=c.riley_move_vy
        },
        box = {
            w = 10,
            h = 10
		},
		hitframe = false,
		hp = 1,
		eweapon = {
			type = "riley",
			cooldown = c.riley_firerate
		},
		outofboundsdestroy = true,
		shadow = true,
		drawtag = "actor",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(34, self.pos.x+_offset, self.pos.y+_offset, 2, 2)
		end
    })
end

function dulce(_x, _y)

    add(world, {
        id = {
            class = "enemy",
			subclass = "dulce",
			size = "medium"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=c.dulce_move_vy
        },
        box = {
            w = 15,
            h = 13
		},
		hitframe = false,
		hp = 1,
		eweapon = {
			type = "dulce",
			cooldown = 0
		},
		outofboundsdestroy = true,
		shadow = true,
		drawtag = "actor",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(36, self.pos.x+_offset, self.pos.y+_offset, 2, 2)
		end
    })
end

function augustus(_x, _y)
	
	add(world, {
		id = {
			class = "enemy",
			subclass = "augustus",
			size = "medium"
		},
		pos = {
			x = _x,
			y = _y
		},
		vel = {
			x = 0,
			y = c.augustus_move_vy
		},
		box = {
			w = 16,
			h = 14,
		},
		hitframe = false,
		hp = 2,
		eweapon = {
			type = "augustus",
			cooldown = c.augustus_firerate
		},
		outofboundsdestroy = true,
		shadow = true,
		drawtag = "actor",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(38, self.pos.x+_offset, self.pos.y+_offset, 2, 2)
		end
	})
end

function koltar(_x, _y)

	add(world, {
		id = {
			class = "enemy",
			subclass = "koltar",
			size = "large"
		},
		pos = {
			x = _x,
			y = _y
		},
		vel = {
			x = 0,
			y = 0.5
		},
		box = {
			w = 32,
			h = 14
		},
		hitframe = false,
		hp = 3,
		eweapon = {
			type = "koltar",
			cooldown = c.koltar_firerate,
			firemode = 0,
		},
		outofboundsdestroy = true,
		shadow = true,
		drawtag = "actor",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(5, self.pos.x+_offset, self.pos.y+_offset, 4, 2)
		end
	})
end

function asteroid(_type, _x, _y, _vx, _vy)

	local _w, _h, _hp, _spr, _spr_size

	if (_type == "large") then
		_w, _h = 14, 14
		_hp = 3
		_spr = rnd_one_among({64, 66, 68, 70, 72})
		_spr_size = 2
	elseif  (_type == "medium") then
		_w, _h = 10, 10
		_hp = 2
		_spr = rnd_one_among({96, 98, 100})
		_spr_size = 2
	elseif  (_type == "small") then
		_w, _h = 7, 7
		_hp = 1
		_spr = rnd_one_among({102, 103, 104, 105})
		_spr_size = 1
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
			sprite_size = _spr_size
		},
		harvestee = {
			beingharvested = false,
			indicator_radius = 0
		},
		hitframe = false,
		hp = _hp,
		outofboundsdestroy = true,
		shadow = true,
		drawtag = "actor",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(self.asteroid.sprite, self.pos.x+_offset, self.pos.y+_offset,
				self.asteroid.sprite_size, self.asteroid.sprite_size)

			if (self.harvestee.beingharvested) then
				circfill(gecx(self), gecy(self),
					self.harvestee.indicator_radius, 11)
			end
			-- print(self.id.size, self.pos.x, self.pos.y)
			-- print(self.harvestee.beingharvested, self.pos.x, self.pos.y)
		end
	})
end

-- friendly bullet
function fbullet(_x, _y)

	-- local speed = -12
	-- local speed = -3

    add(world, {
        id = {
			class = "bullet",
			subclass = "fbullet"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=c.fbullet_speed
        },
        box = {
            w = 5,
            h = 6
		},
		-- ani = {
		-- 	frame = 0, -- determining which frame of the animation is being displayed
		-- 	framerate = 1, -- how fast the frame rotates, 1 is one frame per one tick
		-- 	framecount = 2, -- the amount of frames in the animation
		-- 	loop = false,
		-- },
		outofboundsdestroy = true,
		drawtag = "projectile",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			-- if (flr(self.ani.frame) == 0) then
			-- 	spr(18, self.pos.x, self.pos.y, 1, 1) -- muzzleflash doesn't have shadow
			-- elseif (flr(self.ani.frame) == 1) then
			-- 	spr(19, self.pos.x+_offset, self.pos.y+_offset, 1, 1)
			-- end
			
			spr(19, self.pos.x+_offset, self.pos.y+_offset, 1, 1)
			-- debug
			-- print(self.ani.frame, self.pos.x, self.pos.y, 7)
		end
    })
end

-- hostile/enemy bullet
function ebullet(_x, _y, _vx, _vy)

	add(world, {
		id = {
			class = "bullet",
			subclass = "ebullet"
		},
		pos = {
			x = _x,
			y = _y,
		},
		vel = {
			x = _vx,
			y = _vy,
		},
		box = {
			w = 2,
			h = 2
		},
		outofboundsdestroy = true,
		shadow = true,
		drawtag = "projectile",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(20, self.pos.x-1+_offset, self.pos.y-1+_offset, 1, 1)
		end
	})
end

function explosion(_x, _y, _initradius)
	
	add(world,{
		id = {
			class = "explosion"
        },
        pos = {
            x=_x,
            y=_y
		},
		particle = {
			lifetime = 0,
			lifetime_max = 10
		},
		ani = {
			frame = 1, -- when working with table indexes, do not ever let it go zero
			framerate = 1,
			framecount = 16,
			loop = false
		},
		explosion = {
			radius = _initradius
		},
		drawtag = "particle",
		draw = function(self)

			local frame = flr(self.ani.frame)
			local halo_offset = -1

			pal(8, f820t[frame])

			rect(
				self.pos.x - self.explosion.radius + halo_offset,
				self.pos.y - self.explosion.radius + halo_offset,
				self.pos.x + self.explosion.radius + halo_offset,
				self.pos.y + self.explosion.radius + halo_offset,
				8
			)
			
			-- spr(64, self.pos.x - 16, self.pos.y - 16, 4, 4)
			pal()

			-- debug
			-- print(f720t[frame], self.pos.x, self.pos.y, explosion_animation_table[1][1])
			-- print(self.explosion.radius, self.pos.x, self.pos.y, explosion_animation_table[1][1])
			-- printh(frame, "log")
		end
	})
end

function smoke (_x, _y, _vx, _vy)
	add(world,{
		id = {
			class = "smoke"
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
			radius = c.smoke_radius_init + rnd(c.smoke_radius_range)
		},
		drawtag = "particle",
		draw = function(self)
			circfill(self.pos.x, self.pos.y, self.smoke.radius, 8)
		end
	})
end

function star(_x, _y, _radius, _drawtag) 

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
		loopingstar = true,
		drawtag = _drawtag,
		draw = function(self)
			ngon(
				self.pos.x,
				self.pos.y,
				flr(self.star.radius),
				4,
				13
			)
			-- color()
			-- print("star", self.pos.x, self.pos.y)
		end
	})
end

-- dead bodies of the player from previous attempts
function carcass(_x, _y)
	add(world, {
		id = {
			class = "carcass"
		},
		pos = {
			x = _x,
			y = _y
		},
		vel = {
			x = 0,
			y = c.carcass_move_vy
		},
		-- shadow = true,
		drawtag = "background",
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0
			spr(40, self.pos.x-3+_offset, self.pos.y-4+_offset, 2, 2)
		end,
	})
end

function timer(_lifetimeinsec, _f) 
    add(world, {
        timer = {
            -- 30 frames take up one second
            lifetime = _lifetimeinsec * 30,
            trigger = _f
        }
    })
end

__gfx__
0000c000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000088000000000000000000000000000
000ccc00000000000000000000000000000000000000000000555555555555000000000000000000000008880000000000888800000880000000000000000000
000ccc00000000000000000000000000000000000000888885555666666555588888000000000000000088888000000008800880008888000008800000000000
000ccc00000000000000000000000000000000000000088888556666666655888880000000000000000888088800000088000088088008800088880000088000
00ccccc0000000000000000000000000000000000000008888888666666888888800000000000000008880008880000088000088088008800088880000088000
006ccc60000000000000000000000000000000000000000888888888888888888000000000000000088800000888000008800880008888000008800000000000
0066c660000000000000000000000000000000000000000588855558855558885000000000000000888000000088800000888800000880000000000000000000
06666666000000000000000000000000000000000000005558855558855558855500000000000000088800000888000000088000000000000000000000000000
0c66566c000000000aaa0000aaaaa00000a0000000000655558855888855885555600000000000000088800088800000aaaaa000077700000aaa000000000000
0c65556c00000000aaaaa000aaaaa0000aaa000000006665555888888888855556660000000000000008880888000000a777a00007a700000070000000000000
cc65556cc0000000aaaaa000aa7aa000aa0aa00000066666555588888888555566666000000000000000888880000000aa7aa000070700000000000000000000
cc65556cc0000000aaaaa000aa7aa0000aaa0000005666666555588888855556666665000000000000000888000000000a7a0000000000000000000000000000
0005550000000000aaaaa000aa7aa00000a000000555666666555588885555666666555000000000000000800000000000700000000000000000000000000000
0000000000000000aaaaa000aaaaa000000000005555566666655550055556666665555500000000000000000000000000000000000000000000000000000000
0000000000000000aaaaa000aaaaa000000000000000000000005500005500000000000000000000000000000000000000000000000000000000000000000000
00000000000000000aaa0000aa0aa000000000000000000000000500005000000000000000000000000000000000000000000000000000000000000000000000
0005000550005000600000000060000060000000000000066000000000000006ccc0000000000000000000080000000000000000800000000000000000000000
00555065560555006600000006600000660000000000006666000000000000660c00000000000000000000888000000000000008080000000000000000000000
00055566665550006660050066600000666000000000066666600000000006660cccc00000000000000008808800000000000080008000000000000000000000
000055566555000006665556660000006666000000006666666600055000666600c66c66cc000000000088000880000000000800000800000000000000000000
0000055665500000006665666000000066666005500666666666605555066666000c666666c00000000880000088000000008000000080000000000000000000
0000065665600000000665660000000006666665566666606666655555566666000c665566c00000008800000008800000080000000008000000000000000000
00000066660000000008656800000000086666555566668066666558855666660c0006555c000000088000000000880000800000000000800000000000000000
00000086680000000088858880000000088666555566688066666558855666660506005555000000880000000000088008000000000000080000000000000000
00000886688000000888555888000000088866555566888006666558855666600000066555000000088000000000880080000000000000800000000000000000
00000886688000000880000088000000008886555568880000666558855666000000c66650000000008800000008800008000000000008000000000000000000
00000086680000000800000008000000000888555588800060066588885660060000cc6c00000000000880000088000000800000000080000000000000000000
00000066660000000000000000000000000088855888000066056585585650660000000000000000000088000880000000080000000800000000000000000000
00000556655000000000000000000000000008888880000006655585585556600000000000000000000008808800000000008000008000000000000000000000
00066665566660000000000000000000000000888800000000665555555566000000000000000000000000888000000000000800080000000000000000000000
00866665566668000000000000000000000000088000000000066558855660000000000000000000000000080000000000000080800000000000000000000000
00866688886668000000000000000000000000000000000000006658856600000000000000000000000000000000000000000008000000000000000000000000
00000055555000000005555555555500000000005555555000005555555000000000555555550000111111111111111dd1111111dddddddddddddddddddddddd
000000555555500000555ddd55dd550000055555555dd555005555dd55555500055555555555555011dddd11111111d11d111111d1111111111111111111111d
00000555dd5550000055ddddd5ddd5500055555dddddd555055555ddd555555055555dddddd55d501d1111d111111d1111d11111d1111111111111111111111d
0000055dddd550000055ddddd5ddd550055555dddddd55d5055d5ddddd5555505555ddddddd55d501d1dd1d11111d111111d1111d1111111111111111111111d
000055ddddd55500005ddddd55dddd5005555ddddddd55d555dd5ddddddd555555ddddddddd5dd501d1dd1d1111d11111111d111d1111111111111111111111d
000555ddddd55550005ddddd5ddddd500555ddddddd55dd55ddd5dddddddd5555ddddddddd55dd501d1111d111d1111111111d11d1111111111111111111111d
00055ddddd555550005dddd5555ddd5005dddddddd555dd55ddd5ddddddddd555ddddddd5555dd5511dddd111d111111111111d1d1111111111111111111111d
00555dddd555dd500055dd555d5ddd5005ddddddd555ddd55ddd55dddddddd555dd555555555ddd511111111d11111111111111dd1111111111111111111111d
05555555555ddd500555555ddd55d550555dddd5555dddd555dd55dddddddd55555555555555ddd5ddddddddd11111111111111dd1111111111111111111111d
555dd555dddddd50055ddddddd555550555555555dddddd0555d555ddddddd55555dddd5ddd55dd5d111111d1d111111111111d1d1111111111111111111111d
55dddd5ddddddd5055ddddddd55dd55055dd55ddddddddd55555555ddddddd505dddddd5ddd55d55d111111d11d1111111111d11d1111111111111111111111d
55dddd5dddddd5505ddddddd55ddd50005d55dddddddddd505ddd555ddddd55055ddddd5ddd55d55d111111d111d11111111d111d1111111111111111111111d
55dddd5dddddd5505dddddd55ddd55000555dddddddddd55055ddd555ddd550005555dd555dd5550d111111d1111d111111d1111d1111111111111111111111d
05dddd5ddddd555055ddddd5dddd5000005dddddddd5555000555dd555d550000000555555555550d111111d11111d1111d11111d1111111111111111111111d
055ddd5555555500055ddd55dddd500000555ddd55555500000555d5555500000000000005555550d111111d111111d11d111111d1111111111111111111111d
00555555555500000055555555555000000555555555550000000555555000000000000000000550d111111d1111111dd1111111d1111111111111111111111d
000555555555000000005555555000005555500000000000055555550055555005055555555555551111111111111111111d1111d1111111111111111111111d
00555dd55dd550000555555ddd5500005dd555555555000055ddd5550555dd555555ddd55dddddd5111111111dddddd111d1d111d1111111111111111111111d
055dddd5ddd55000555555dddd5500005ddddd555dd550005dddd5d5555dddd555ddddd55ddddd551111d1111d111dd11d111d11d1111111111111111111111d
055dddd5dddd5000555dd555555500005ddddd55dddd50005ddd55d55ddddd55055555555ddd5555111d1d111d1111d1d11111d1d1111111111111111111111d
55dddd55dddd500055dddd5555d500005ddddd55dddd500055d55dd55ddddd50055ddd5555d55d5011d111d11d1111d11d11111dd1111111111111111111111d
55dddd55ddd5500055ddddd55dd50000555dd55dddd550000555dd5555dddd5055ddddd50555dd501d1111111d1111d111d111d1d1111111111111111111111d
055dd555dd555000055dddd5ddd50000055555ddddd55000055dd550055dd550555dddd5055dd550111111111dddddd1111d1d11d1111111111111111111111d
055555d5d5550000005dddd5dd55000005d555dddd5500000555550000555550055555550055550011111111111111111111d111dddddddddddddddddddddddd
00555dd5555000000055ddd55555000055d55dddd555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000555d5500000000055ddd5dd5500005dd5ddddd550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000555000000000005dd55d550000055d5dddd5550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005dd555500000005d555dd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005555000000000055555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddd000dddddddddddddddd000ddddddddddddddddddddd0000000dd00000007777777777777777777777777777777777777777777777777777777777777777
ddddd000ddddddd00ddddddd000dddddddddddddd1111ddd000000dddd0000007777777777777777777777777777777777777777777777777777777777777777
dd000000dd00dd0000dd00dd000000ddddddddddd11111dd00000dddddd000007700000000000000000000000000000000000000000000000000000000000077
ddd00000ddd0000000000ddd00000dddddddddddd111111d0000dddddddd00007700000000000000000000000000000000000000000000000000000000000077
ddddd000dd000000000000dd000dddddddddddddd111111d000dddddddddd0007700000000000000000000000000000000000000000000000000000000000077
ddddd000ddd0000000000ddd000ddddddddddddddd1111dd00dddddddddddd007700000000000000000000000000000000000000000000000000000000000077
dddd0000dd000000000000dd0000ddddddd0000dddd1111d0dddddddddddddd07700000000000000000000000000000000000000000000000000000000000077
dddd0000d00000000000000d0000dddd0000000ddddddddddddddddddddddddd7700000000000000000000000000000000000000000000000000000000000077
dddd0000dd000000000000dd0000dddd00000000dddddddddddddddddddddddd7700000000000000000000000000000000000000000000000000000000000077
dddd0000ddd0000000000ddd0000dddd00000000dddd11110dddddddddddddd07700000000000000000000000000000000000000000000000000000000000077
ddddd000dddd00000000dddd000ddddd00000000ddd1111100dddddddddddd007700000000000000000000000000000000000000000000000000000000000077
dddd0000ddddd000000ddddd0000dddd00000000dddd1111000dddddddddd0007700007777777007777707777707777700777770777770707707777777000077
ddddd000dddddddddddddddd000ddddd00000000dd1111110000dddddddd00007700007007007007000707000707000700700000700070770007007007000077
dddddd00ddddd000000ddddd00dddddd00000000dddd111100000dddddd000007700007007007007000707000707000700700000700070700007007007000077
ddddd000ddd0000000000ddd000ddddd00000000ddddd111000000dddd0000007700007007007007000707000707000700700000700070700007007007000077
dddd0000dd000000000000dd0000dddd00000000ddddddd10000000dd00000007700007007007007000707000707000700700000700070700007007007000077
ddddd000ddd0000000000ddd000ddddd0000000011dddddddddddddddd1111dd7700007007007007000707000707000700777770700070700007007007000077
ddddd000dddddd0000dddddd000ddddd00000000111ddddddddddddddd1111dd7700007007007007000707000707000700700000700070700007007007000077
dddd0000ddddddd00ddddddd0000dddd000000001111dddddddddddddd1111dd7700007007007007000707000707000700700000700070700007007007000077
ddddd000ddddddd00ddddddd000ddddd00000000111111ddddddddddd11111dd7700007007007007000707000707000700700000700070700007007007000077
dddddd00dddd00000000dddd00dddddd0000000011111ddddddddddddd1111dd7700007007007007770707000707770700700000777070700007007007000077
dddddddddd000000000000dddddddddd000000001111ddddddddddddddd111dd7700000000000000000000000000000000000000000000000000000000000077
ddddd000ddd0000000000ddd000ddddd000000001111ddddddddddddddd11ddd7700000000000000000000000000000000000000000000000000000000000077
ddddd000dddd00000000dddd000ddddd0000000011dddddddddddddddd1111dd7700000000000000000000000000000000000000000000000000000000000077
ddd00000dd000000000000dd00000ddd00000000dddd11dddddddddddd1111dd7700000000000000000000000000000000000000000000000000000000000077
dddd0000dddd00000000dddd0000dddd00000000ddd1111dddd1dddddd1111dd7700000000000000000000000000000000000000000000000000000000000077
dddddd00dddddd0000dddddd00dddddd00000000dd11111ddd1111dddd1111dd7700000000000000000000000000000000000000000000000000000000000077
dddddd00dddddddddddddddd00dddddd00000000dd1111dddd1111dddd1111dd7700000000000000000000000000000000000000000000000000000000000077
ddd00000ddddddd00ddddddd00000ddd00000000d11111ddddd11dddddd111dd7700000000000000000000000000000000000000000000000000000000000077
ddd00000ddddd000000ddddd00000ddd00000000111111dddd1111dddddd11dd7700000000000000000000000000000000000000000000000000000000000077
ddddd000ddd0000000000ddd000ddddd00000000d1111ddddd1d11dddddd11dd7777777777777777777777777777777777777777777777777777777777777777
ddd00000d00000000000000d00000ddd00000000dddddddddd1111dddddddddd7777777777777777777777777777777777777777777777777777777777777777
__map__
5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e6b6b5e5e5e5e5e5e5e4b4c5e5e80b47f00b493000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e6b6b5e5e5e5e6c6c5e4d4f5e5e6b6b5e5e5e6c6c5e5e6d5c5e5e90b47f000083000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e6b5e5e5e5e5e5e5e5e5d5f5e5e5e5e5e5e5e5e5e5e5e5e5e5a5ea6877f000083000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e5e5e5e6b5e5a5e5e6d5c5e5e5e5e5e5e5e4d4f5e5e4d4e4e4e90b47f000086000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e4d4c5e5e5e5e6b5e5a5e5e5e5e5e4b4e4c5e5e5e6d5c5e5e6d6e6e6eb0b4b40000a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e6d6f5e5e5e5e6b5e5e5e5e5e5e5e5d5e5f5e5e5e5e5e5e5e5e5e5e5e90b4b4000096000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5a5e5e5e5e5e5e5e6b5e5e4d4f5e5e5e5b6e5c5e5e5e5e5e4b4c5e5e5e5ea6917f0000b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e6c6c6c6c5e5e5e5e5e6d6f5e5e5e5e5e5e5e5e5e5e5e6d6f5e5e5e5ea690760087b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e6b6b5e5e5e5e6c6c5e5e5e5e5e5e5e5ea0b47f009687000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e6c6c5e5e5e5e5a5e5e5e90b47c0000a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e5e4b4f5e5e5e5e5e5e5e5e5e4d4f5e5e5e5e5e5e5e5e5e5e5eb4b4b40000a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e6b6b5e5e5e6d5c5e5e5e6c6c6b5e5e5e4c6f5e5e5e4b4f5e5e5e6b5e5e87b4b40000b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e6b6b5e5e5e5e5e5e5e5e5e5e6b5e5e5e5e5e5e5e5e6d5c5e5e6b6b5e5ea6877f0000b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5ea6a17e000086000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e5e5e5e5a5e5e5e5e5e5e5e5e5e6c6c6c6c5e5e5e5e5e5e5e5e80b47c000084000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a5e5e5e5e5e5e5e5e4d4e4e4e4f5e5e4a5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e8497b4b4b4a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5a5e5e6c6c5e5e5b5e6b5e5f5e5e5e5e5e5e5e5e5e5a5e5e5e6c6c5e5e5eb4b4b4b483a6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4e4e4e4f5e5e5e5e5e5e5b5e6b5f5e5e5e5e5e5e5e5e4b4f5e5e5e6c6c5e5e5e8086b4b49697000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e6e6e5c5e5e5e5e5e5e5e5b5e5f5e5e5e5e5e5e5e5e6d5c5e5e5e5e5e5e5e5e80b4b4000093000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e5e5e5e5e5e5b6f5e5e5e5e6b6b5e5e5e5e5e5e5e5e5a5e5e5eb4b4b4b40096000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4e4e4e4e4c5e5e5e5e5a5e5e5e5e5e5e5e5e6b6b5e5e5e5e4d4e4e4e4e4e4e4ea697b4b400b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5f5e5e5e5e4d4f5e5e5e5e5e4f5e5e5e5e5e5e5e6d6e6e6e6e6e6e6ea68687b40086000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e6e6e6e5c5e5e5e5e4c6f5e5e5e6c5e4e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5ea6b0b4b4b3a6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e5e5e5e5e5e5e5e6c5e5e5e5e5e5e5a5e5e5e5e5e5e5e5e5e5ea687b4000093000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e6b6b5e5e6c5e5e5e5e5e5e5e5e5e5e4d4e4e4e4f5e5e5e6b6b5e5ea6a1b40000b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e6b6b5e5e6c5e4b4f5e5e5e4c5e5e5e6d6e5e6b5f5e5e5e6b6b5e5e97b4b40000b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e6a5e5e5e5e5e5e5e6d5c5e5e5e5e4c5e5e5e5e5b6e5c5e5e5e5e5e5e5e87b4b40086a6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e6a5e5e5e5e5e5e5e5e5e5e5e5e5e5e4c5e5e5e5e5e5e5e5e5e5e5e5e5ea6a6b400b3a6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e5e5e5e5e5e6b6b5e5e5e5e4d4e4e5e5e5c5e5e5e5e5e5e5e5e5e4b4e4c5ea690b4b40096000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e4d4e4f5e5e5e5e5e5e5e6c6c5b6e6e6e6f5e5e4d4f5e5e6c6c5e5e5d5e5f5e97b4b4b40093000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5b6e5c5e5e5e5e5e5e5e6c6c5e5e5e5e5e5e5e4c6f5e5e6c6c5e5e5b6e5c5e80b4b40096a6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e4a5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e849000000096000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000c0510c0510c0510c0510c0510c0510c0513a0013900134001320012d001250011f0011d0011d0011f001210010000125001260012200100001000010000100001000010000100001000010000100001
0001000024157281572b15731157311572f1572915725157211571c1571b1571b1571b1571b1571e15723157281572f1573915700107001070010700107001070010700107001070010700107001070010700107
010200002115626156281562b156251561e1561f15623156281562b1562715622156271562a1562d1562c1062710623106271062a106001060010600106001060010600106001060010600106001060010600106
