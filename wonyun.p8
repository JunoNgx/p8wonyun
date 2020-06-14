pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- wonyun trench run
-- a game by juno nguyen
-- @junongx

-- huge table of constants for game design tuning
c = {
	draw_hitbox_debug = false,

	-- destination_distance = 9000, -- in ticks, 9000 ticks = 5 mins
	destination_distance = 5400,

	shadow_offset = 2,
	bounds_offset_sides = 8,
	bounds_offset_top = 64, -- a lot more things happen on top of the screen
	bounds_offset_bottom = 8,
	bounds_safe = 16,
	spawn_bound_lf = 16,
	spawn_bound_rt = 127 - 16 *2,

	layer1_scroll_speed = 2,
	layer2_scroll_speed = 3,
	layer3_scroll_speed = 6,

	player_firerate = 5, -- firerates are all in ticks
	player_speed_fast = 4,
	player_speed_slow = 1,

	player_hp_start = 4,

	player_ammo_start = 4,
	player_ammo_max = 8,

	harvest_distance_small = 12,
	harvest_distance_medium = 15,
	harvest_distance_large = 20,
	harvest_complete = 60, -- 2 seconds

	fbullet_speed = -8,

	spawnrate_enemy_min = 60,
	spawnrate_enemy_range = 30,
	spawnrate_asteroid_min = 45,
	spawnrate_asteroid_max = 45,

	riley_move_vy = 1,
	riley_firerate = 45,
	riley_bullet_vel = 1.5,

	dulce_move_vy = 6,
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
	
	spark_increment_rate = 2,	
	spark_color_1 = 8,
	spark_color_2 = 10,

	fragment_move_vel_min  = 1,
	fragment_move_vel_range = 1.5,
	fragment_amt_min = 5,
	fragment_amt_range = 5,
}

-- sfx note

-- 00 
-- 01 intro audio
-- 02 menu click
-- 03 start game
-- 04 gameplay start audio

-- 05 player fire
-- 06 player hit
-- 07 player harvesting
-- 08 ammo up
-- 09 fbullet hit

-- 10 enemy fire -- unused
-- 11 ebullet hit
-- 12 dulce indicator warning
-- 13 dulce screaming
-- 14 riley shot -- unused
-- 15 hammerhead shot
-- 16 augustus shot -- unused
-- 17 koltar screaming
-- 18 koltar shot

-- 20 explosion 1 -- unused
-- 21 explosion 2 -- unused
-- 22 explosion 3
-- 23 explosion 4 -- unused
-- 24 explosion 5 -- unused

-- 25 victory
-- 26 outro caption audio

-- 27 player's death

-- progress storage
g = {
	ship_no = 1,
	travelled_distance = 0,
	-- this is where the positions of the
	-- player's past failed attempts are kept
	carcasses = {}, 
}

-- 12 messages for caption state
-- corresponding to 12 lives
m = {
	"wonyun base is under siege\nthe kaedeni are invading\n\na runner ship must be sent\nfor help\n\nmothership must be alerted\nfor reinforcement", --1
	"if they want war\nlet's give them war\n\ngo out there\nand kill them all", -- 2
	"sometimes, it's necessary\nto slown down\n\nhold 🅾️ while moving\nto slowdown", -- 3
	"there are so many of them\n\nbut we have no choice\n\nwe must take flight\n\nmothership depends on us", -- 4
	"use the asteroids\nto your advantages\n\nstay behind them for cover\nand replenish ammunition\nby staying nearby\n\nbeware of\nasteroid fragments", -- 5
	"watch out for\nthe bomber dulce\nthey can be dangerous\n\nlook for\nthe warning indicator\n\ngodspeed and safe flight", -- 6
	"after all these times\nthe kaedeni have finally\nsought vengeance\n\nmaybe we deserve it", -- 7
	"i miss home\n\nbut there won't be a home\nto come back to\n\nif we fail", --8
	"it's such a long way\n\nsuch a long long way", -- 9
	"someone has just\ntaken their own life\n\nfalling into the hands\nof the kaedeni\nwon't be pleasant\n\nmaybe we should do the same", -- 10
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
	if (fader.time < fader.projected_time_taken) then
		fader.time +=1
		fader.pos += fader.projected_velocity
	end
end

function fade_draw(_position)
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
		if (g.ship_no<13) then sfx(1) end
		self.page = "main"
		fadein()
		saveprogress()
	end,
	update = function(self)

		if (self.page == "main") then
			if (btnp(0)) then self.page = "credits" sfx(2) end
			if (btnp(1)) then self.page = "manual" sfx(2) end
			if (g.ship_no<13 and btnp(4)) then
				transit(captionstate)
				sfx(3)
			end
		elseif (self.page == "credits") then
			if (btnp(1) or btnp(5)) then self.page = "main" sfx(2) end
		elseif (self.page == "manual") then
			if (btnp(0) or btnp(5)) then self.page = "main" sfx(2) end
		end

	end,
	draw = function(self)

		if (self.page == "main") then
			
			print("wonyun trench run", 16, 16, 8)
			print("a game by juno nguyen", 16, 24, 10)

			local shipno = (g.ship_no<13) and g.ship_no or "no ship left"
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

			-- looping through the quotient rows
			for j=1,flr(sn/6) do
				for i=1,6 do
					circfill(8+16*i, 48+10*j, 3, 12)
				end
			end
			-- looping the remainder
			for i=1,sn % 6 do
				circfill(8+16*i, 48+10*(flr(sn/6)+1), 3, 12)
			end

			spr(134, 0, 80, 1, 2)
			print("credits", 10, 86, 6)
			spr(135, 127-8, 80, 1, 2)
			print("manual", 94, 86, 6)

			if (g.ship_no<13) then
				print("press ❎ to send", 64-#"press ❎ to send"*2, 104, 12)
				print("another ship", 64-#"another ship"*2, 112, 12)
			else
				print("all is lost", 64-#"press ❎ to send"*2, 96, 12)
				print("erase your savedata", 64-#"erase your savedata"*2, 104, 8)
				print("to play again", 64-#"to play again"*2, 112, 12)
				print("press p to access pause menu", 64-#"press p to access pause menu"*2, 120, 7)
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
			
		end
	end
}

-- This state displays a message for exposition
-- prior to transiting into gameplay state
captionstate = {
	name = "caption",
	init = function()
		if (g.ship_no == 100) then sfx(26) end
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
				"we have reached\n\nbut oh no\n\nthe mothership has fallen\n\n\nwe are too late\n\n\nall have been lost"
		end

		print(message, 16, 32, 7)
	end
}

gameplaystate = {
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
	isrunning = true, 

	init = function(self)
		fadein()
		self.isrunning = true
		world = {}
		spawner_init()
		g.travelled_distance = 0
		player(64, 96)

		sfx(4)

		-- unused materials
		-- codes allowed to remain for educational purpose
		-- creating stars on the background and foreground

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

		if (g.travelled_distance >= c.destination_distance and getplayer() and not self.won) then
			exitgameplay("win")

			p = getplayer()
			p.playercontrol = false
			p.keepinscreen = false
			p.vel.x=0
			p.vel.y-=7

			self.won = true
			sfx(25)
		end

		spawner_update()
		screenshake_update()

		-- the bulk of the game logic
		-- iterating through systems
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

		-- for debug
		-- color()
		-- print(spawn.cooldown_enemy)
	end
}

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
	gameplaystate.isrunning = false
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

-- custom menu item in the pause menu
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

	gamestate = splashstate
	-- gamestate = menustate
	-- gamestate = gameplaystate
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
	),
	collisionsys = system({"id", "pos", "box"},
		function(e1)

			-- player 
			if (e1.id.class == "player") then

				-- player vs ebullet
				local ebullets = getentitiesbysubclass("ebullet", world)
				for e2 in all(ebullets) do
					if coll(e1, e2) then
						sfx(6)
						e1.hp -=1
						rectspark(gecx(e1), gecy(e1), 6, 6, 11)

						spawn_fragments(gecx(e2), gecy(e2))
						del(world, e2)
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

			-- friendly bullet vs enemy
			elseif (e1.id.subclass == "fbullet") then
				local enemies = getentitiesbyclass("enemy", world)

				for e2 in all(enemies) do
					if coll(e1, e2) then
						sfx(9)
						spawn_fragments(gecx(e1), gecy(e1))
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
						sfx(11)
						spawn_fragments(gecx(e1), gecy(e1))
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

				-- explosion sfx is called from spawn_explosion()
				if (e.id.class == "enemy") then

					if (e.id.size == "small") then
						spawn_explosion("small", gecx(e), gecy(e))
						screenshake(5, 0.3)

					elseif (e.id.size == "medium") then
						spawn_explosion("medium", gecx(e), gecy(e))
						screenshake(7, 0.5)

						if (e.id.subclass == "asteroid") then
							spawn_from_asteroid("medium", gecx(e), gecy(e))
						end
					elseif (e.id.size == "large") then
						spawn_explosion("large", gecx(e), gecy(e))
						screenshake(8, 0.5)

						if (e.id.subclass == "asteroid") then
							spawn_from_asteroid("large", gecx(e), gecy(e))
						end
					end

					sfx(16)
					
				elseif (e.id.class == "player") then
					spawn_explosion("large", gecx(e), gecy(e))
					screenshake(8, 0.5)
					sfx(27)
					 
					add(g.carcasses, {x=e.pos.x, y=g.travelled_distance-e.pos.y})
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

			if (e.pos.x > 127 + c.bounds_offset_sides)
				or (e.pos.x < 0 - c.bounds_offset_sides)
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
	sparkupdatesystem = system({"spark"},
		function(e)
			e.spark.radius += c.spark_increment_rate
		end
	),
	fragmentupdatesystem = system({"fragment"},
		function(e)
			e.fragment.radius *= e.fragment.radius_rate
			e.vel.x *= e.fragment.vel_rate
			e.vel.y *= e.fragment.vel_rate
			if e.fragment.radius <= 0.1 then del(world, e) end
			if (abs(e.vel.x) < 0.01 and abs(e.vel.y) < 0.01) then del(world, e) end
		end
	),
	smokeupdatesystem = system({"smoke"},
		function(e)
			e.smoke.radius -= c.smoke_decrement_rate
		end
	),
	loopingstarsystem = system({"loopingstar"},
		function(e)
			if (e.pos.y > 128+c.bounds_offset_sides) then
				e.pos.x = rnd(128)
				e.pos.y = -8
				e.vel.y = rnd(1.5)
			end
		end
	),

	-- harvesting system
	harvesteesystem = system({"harvestee"},
		function(e)
			if (e.harvestee.beingharvested) then

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
						sfx(7)
					else
						e.harvester.progress = 0
						if (e.playerweapon.ammo < c.player_ammo_max) then
							e.playerweapon.ammo += 1
							sfx(8)
						end
					end

				else 
					a.harvestee.beingharvested = false
				end
			end
		end
	),

	-- enemy weapon system
	-- enemy firing and attacking behaviour
	enemyweaponsystem = system({"eweapon"},
		function(e)
			if (e.eweapon.cooldown > 0) then
				e.eweapon.cooldown -= 1;
			else 

				-- riley
				-- fires one shot aiming at the player
				if (e.eweapon.type == "riley") then

					if gameplaystate.isrunning then sfx(15) end

					local p = getplayer(world)
					if p then -- making sure that player exists
						local angle, vx, vy
						angle = atan2(gecx(p)-gecx(e), gecy(p)- gecy(e))
						vx = c.riley_bullet_vel * cos(angle)
						vy = c.riley_bullet_vel * sin(angle)

						ebullet(gecx(e), gecy(e), vx, vy)
						e.eweapon.cooldown = c.riley_firerate
					end

				-- dulce
				-- "carpeting bombing" and leaves a line of bullets
				elseif (e.eweapon.type == "dulce") then

					ebullet(gecx(e), gecy(e), 0, c.dulce_bullet_vy)
					e.eweapon.cooldown = c.dulce_firerate

				-- hammerhead
				-- fires two lateral shot on each side
				elseif (e.eweapon.type == "hammerhead") then

					if gameplaystate.isrunning then sfx(15) end

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

				-- augustus
				-- fires three shot in an arc
				elseif (e.eweapon.type == "augustus") then

					if gameplaystate.isrunning then sfx(15) end

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

				-- koltar
				-- fires four shot in alternative modes
				-- axis aligned and diagonally
				elseif (e.eweapon.type == "koltar") then

					if gameplaystate.isrunning then sfx(18) end
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

			-- alternate implementation
			-- codes allowed to remain
			-- for documentation and educational purpose

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

			-- diagonal movement etiquette
			if (e.vel.x * e.vel.y ~= 0) then
				e.vel.x *= cos(0.125)
				e.vel.y *= -sin(0.125) -- y axis is inverted
			end


			if (btnp(4)) then
				if (e.playerweapon.cooldown <=0
					and e.playerweapon.ammo > 0) then
					sfx(5)
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

	system({"id", "draw", "drawtag"},
		function(e)
			if (e.drawtag == "actor") then

				-- flashing white color when entity is damaged
				if (e.hitframe) then
					palforhitframe(e)
				end

				e:draw()

				if (e.hitframe) then 
					e.hitframe = false
					pal()
				end

			end
		end
	),

	system({"id", "draw", "drawtag"},
		function(e)
			if (e.drawtag == "projectile") then
					e:draw()
			end
		end
	),

	-- draw particles
	system({"id", "draw", "drawtag"},
		function(e)
			if (e.drawtag == "particle") then
					e:draw()
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

			end
		end
	),

	-- draw collision boxes, for debug purpose when enabled
	system({"pos", "box"},
		function(e)
			if (c.draw_hitbox_debug) then
				rect(e.pos.x, e.pos.y, e.pos.x + e.box.w, e.pos.y+ e.box.h, 8)
			end
		end
	),
}

-->8
-- spawning functions
spawn = {
	cooldown_enemy,
	cooldown_asteroid,
	last = {
		difficulty,
		unit
	}
}

function spawner_init()
	spawn.cooldown_enemy = 90 +rnd(60)
	spawn.cooldown_asteroid = 60 + rnd(60)
	spawn.last = {difficulty, unit}
end

function spawner_update()

	-- spawning player's remains in the previous attempts
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

-- utility functions
-- random x spawn and y spawn
function rndxspawn()
	return c.bounds_safe + rnd(127 - c.bounds_safe*2)
end

function rndyspawn()
 	return -c.bounds_safe-rnd(c.bounds_offset_top-c.bounds_safe)
end

function spawn_enemy()

	local _difficulty, _die
	_die = rnd()

	if (_die<0.5) then _difficulty = "low" end
	if (0.5<=_die and _die<=0.85) then _difficulty = "medium" end
	if (0.85<_die) then _difficulty = "high" end

	if spawn.last.difficulty == "high" then
		_difficulty = rnd_one_among({"low", "medium"})
	end

	-- low difficulty
	if (_difficulty == "low") then

		local _formation = rnd_one_among({"riley", "hammerhead", "augustus"})

		-- one riley
		if (_formation == "riley") then
			riley(rndxspawn(), rndyspawn())

		-- one hammerhead
		elseif (_formation == "hammerhead") then
			hammerhead(rndxspawn(), rndyspawn())

		-- one augustus
		elseif (_formation == "augustus") then
			augustus(rndxspawn(), rndyspawn())

		end

		spawn.last.unit = _formation

	-- medium difficulty
	elseif (_difficulty == "medium") then

		local _die, _formation
		_die = rnd()
		
		if (_die<0.3) then _formation = "riley" end
		if (0.3<=_die and _die<0.6) then _formation = "dulce" end
		if (0.6<=_die and _die<=0.9) then _formation = "hammerhead" end
		if (0.9<_die) then _formation = "koltar" end

		-- extra conditions for koltar
		if ((_formation == "koltar") and
			-- only spawns from 25% of the progress
			-- not spawning twice in a row
			(g.travelled_distance/c.destination_distance < 0.25
			or spawn.last.unit == "koltar")) then

			_formation = rnd_one_among({"riley", "dulce", "hammerhead"})
		end

		-- two rileys, aligned
		if (_formation == "riley") then
			local _y = rndyspawn()
			riley(127 * 1/3 - 5, _y)
			riley(127 * 2/3 - 5, _y)

		-- one dulce, no formation
		elseif (_formation == "dulce") then
			dulce(rndxspawn(), rndyspawn())

		-- two hammerheads
		elseif (_formation == "hammerhead") then
			hammerhead(127 * 1/3 - 5, rndyspawn())
			hammerhead(127 * 2/3 - 5, rndyspawn())

		-- one koltar, middle
		elseif (_formation == "koltar") then
			koltar(127/2 -16, -24)

		end

		spawn.last.unit = _formation

	-- HIGH DIFFICULTY
	elseif (_difficulty == "high") then

		local _die, _formation
		_die = rnd()

		if (_die<0.1) then _formation = "riley" end
		if (0.1<=_die and _die<0.4) then _formation = "dulce" end
		if (0.4<=_die and _die<=0.9) then _formation = "augustus" end
		if (0.9<_die) then _formation = "koltar" end

		-- extra conditions for koltar
		if (_formation == "koltar"
			-- only spawns from 50% of the progress
			-- not spawning twice in a row
			and (g.travelled_distance/c.destination_distance < 0.5
			or spawn.last.unit == "koltar")) then
				
			_formation = rnd_one_among({"riley", "dulce", "augustus"})
		end

		-- three rileys
		if (_formation == "riley") then
			local _y = rndyspawn()
			riley(127 * 1/4 - 5, _y+8)
			riley(127 * 2/4 - 5, _y)
			riley(127 * 3/4 - 5, _y+8)

		-- two dulces
		elseif (_formation == "dulce") then
			dulce(rndxspawn(), rndyspawn())
			dulce(rndxspawn(), rndyspawn())

		-- two augustus
		elseif (_formation == "augustus") then
			local _y = rndyspawn()
			augustus(127 * 1/3 - 8, _y)
			augustus(127 * 2/3 - 8, _y)

		-- two koltar
		elseif (_formation == "koltar") then
			koltar(127 * 1/3 - 16, -24)
			koltar(127 * 2/3 - 16, -24)

		end

		spawn.last.unit = _formation

	end

	spawn.last.difficulty = _difficulty

end

function spawn_asteroid()
	local _type, _die, _x, _y, _vx, _vy
	_die = rnd()
	
	_type = (_die<0.5) and "large" or _type
	_type = (0.5<=_die and _die<=0.75) and "medium" or _type
	_type = (0.75<_die) and "small" or _type

	_x = rnd(128)
	_y = rndyspawn()
	_vx = rnd(0.3)
	_vy = rnd(2)

	-- set asteroids to always move towards the center from sides, horizontally
	_vx = (_x < 64) and _vx or -_vx 

	asteroid(_type, _x, _y, _vx, _vy)
end

function spawn_from_asteroid(_type, _x, _y)
	local die = ceil(rnd(3))
	local chance_for_medium = (_type=="large") and 0.3 or 0

	for i=1,die do
		local _type = rnd()<chance_for_medium and "medium" or "small"
		asteroid(_type, _x, _y, rnd(3)-1.5, rnd(3)-1.5)
	end
end

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

function spawn_explosion(_size, _x, _y)
	-- consists of spark and smokes

	-- sfx(rnd_one_among({20, 21, 22, 23, 24}))
	sfx(22)

	if _size == "small" then
		rectspark(_x, _y, 6, 8, 8, c.spark_color_1)
		spawn_smokes(
			c.explosion_small_amt + rnd(c.explosion_small_amt_range),
			_x, _y
		)

	elseif _size == "medium" then
		rectspark(_x, _y, 10, 10, c.spark_color_1)
		spawn_smokes(
			c.explosion_medium_amt + rnd(c.explosion_medium_amt_range),
			_x, _y
		)
	elseif _size == "large" then
		rectspark(_x, _y, 15, 12, c.spark_color_1)
		spawn_smokes(
			c.explosion_large_amt + rnd(c.explosion_large_amt_range),
			_x, _y
		)
	end
end

function spawn_smokes(_maxamt, _x, _y)

	for i=1, _maxamt do
		smoke(
			_x + rnd(32) - 16,
			_y + rnd(32) - 16,
			0,
			-rnd(1)
		)
	end

end

function spawn_fragments(_x, _y)
	_amt = c.fragment_amt_min + ceil(rnd(c.fragment_amt_range))
	for i=1, _amt do 
		fragment(_x, _y, rnd())
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
		hp = c.player_hp_start,
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
		end
	})
end

function hammerhead(_x, _y)

	-- sfx(15)
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

	-- sfx(14)
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
	-- show warning indicator
	indicator(_x)
	
	-- delay spawning by one second
	timer(1, function()
		sfx(13)
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
			hp = 2,
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
	end)
    
end

function augustus(_x, _y)
	
	-- sfx(16)
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

	-- miniboss, will play sfx once spawned
	sfx(17)
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
		end
	})
end

-- friendly bullet
function fbullet(_x, _y)

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
		outofboundsdestroy = true,
		drawtag = "projectile",
		draw = function(self)
			spr(19, self.pos.x, self.pos.y, 1, 1)
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

function rectspark(_x, _y, _initradius, _lifetime_max, _color)
	
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
		drawtag = "particle",
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

function smoke (_x, _y, _vx, _vy)
	add(world,{
		id = {
			class = "particle",
			subclass = "smoke"
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

-- impact particles, spawned when bullets hit
function fragment(_x, _y, _angle)

	local vel = c.fragment_move_vel_min + rnd(c.fragment_move_vel_range)
	local _vx, _vy = vel * cos(_angle), vel * sin(_angle)

	add(world,{
		id = {
			class = "particle",
			subclass = "fragment"
        },
        pos = {
            x = _x,
            y = _y
		},
		vel = {
			x = _vx,
			y = _vy
		},
		fragment = {
			radius = 1+rnd(1),
			radius_rate = 0.8 + rnd(2)/10,
			vel_rate = 0.8 + rnd(2)/10
		},
		drawtag = "particle",
		draw = function(self)
			circfill(self.pos.x, self.pos.y, self.fragment.radius, 10)
		end
	})
end

-- warning for dulce
function indicator(_x)

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
		drawtag = "particle",
		draw = function(self)
			pal(13, 14)
			spr(135, self.pos.x, self.pos.y, 1, 1)
			pal()
		end
	})
end

-- most likely unused
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
__label__
555555511111111111111111111111111111111111111111111111d111111d11111111111111111111111111d111d111d111d111111111111111666666666600
655555551111111111111111111111111111111111111111111111d111111d111111111111111111111111111d1d11111d1d1111111111111116666666666600
665555555111111111111111111111111111111111111111111111d111111d1111111111111111111111111111d1111111d11111111111111166666666666600
66655555551111111111111111111111111111111111111111111ddddddddd111111111111111111111111111d1111111d111111111111111666666666666600
6666555555511111111111111111111111111111111111111111d1111111ad11111111111111111111111111d1d11111d1d11111111111116666666666666600
666665555555111111111111111111111111111111111111111d1111111aaa1111111111111111111111111d111d111d111d1111111111166666666666666600
66666655555551111111111111111111111111111111111111d1111111aa1aa11111111111111111111111d11111d1d11111d111111111666666666666666600
6666666666666611111111111111111111111111111a11111d111111111aaa0011111111111111111111111d11111d1d11111d11111111111116666666666600
666666666666661111111111111111111111111111aaa111d111111a1111a010011111111111111111111111d111d111d111d111111111111166666666666600
66666666666666111111111111111111111111111aa1aa1d111111aaa11110001111111111111111111111111d1d11111d1d1111111111116666666666666600
666666666666661111111111111111111111111111aaa00111111aa1aa111d0111111111111111111111111111d1111111d11111111111116666666666666600
6666666666666611111111111111111111111111111a0100111111aaa0011d111111111111111111111111111111111111111111111111111116666666666600
6666666666666611111111111111111111111111111100011111111a0100d1111111111111111111111111111111111111111111111111111116666666666600
6666666666666611111111111111111111111111111110d111111111000d11111111111111111111111111111111111111111111111111111666666666666600
6666666666666611111111111111111111111111111111d11111111110d111111111111111111111111111111111111111111111111111111116666666666600
6666666666111111111111111111111111111111111111d1111111111d1111111111111111111111111111111111111111111111111111111111116666666600
6666666666111111111111111111111111111111111111d111111111d11111111111111111111111111111111111111111111111111111111111115666666600
6666666666611111111111111111111111111111111111d11111111d111111111111111111111111111111111111111111111111111111111111115566666600
6666666666111111111111111111111111111111111111ddddddddd1111111111111111111111111111111111111111111111111111111111111115556666600
6666666666611111111111111111111111111111111111111111111111111111111111111111111111111111111111dddddddd11111111111111115555666600
666666666666111dddddd11dddddd11111111111111111111111111111111111111111111111111111111111111111d111111d11111111111111115555566600
666666666661111d111dd11d111dd11111111111111111111111111111111111a11111111111111111111111111111d111111d11111111111111115555556600
666666666611111d1111d11d1111d1111111111111111111111111111111111aaa1111111111111111111111111111d111111d11111111111111115551111600
666666111111111d1111d11d1111d111111111111111111111111111111111aa1aa111111111111111111111111111d111111d11111111111111111111666600
666665555555551d1111d11d1111d1111111111111111111111111111111111aaa0011111111111111111111111111d111111d11111111111111111115666600
666655555555511dddddd11dddddd11111111111111111111111111111111111a01001111111111111111111111111d111111d11111111111111111116666600
6665555555551111111111111111111111111111111111111111111111111111100011111111111111111111111111d111111d11111111111111111111666600
66555555555111111111111111111111111111111111111111111111111111dddd0dddddddddddddddddddddddddddddddddddddddddddddddddddddd6666600
655555555511111dddddd11dddddd1111111111111111111111111111111a1d11111111111111111111111111111111111111111111111111111111166666600
555555555111111d111dd11d111dd111111111111111111111111111111aaad11111111111111111111111111111111111111111111111111111115556666600
511115551111111d1111d11d1111d11111111111111111111111111111aa1aa11111111111111111111111111111111111111111111111111111111115666600
666115511111111d1111d11d1111d11111111111111a111111111111111aaa001111111111111111111111111111111111111111111111666666666666666600
666111111111111d1111d11d1111d1111111111111aaa111111111111111a0d00111111111111111111111111111111111111111111111166666666666666600
555111111111111dddddd15555555555511111111aa1aa1111111111111110001111111111111111111111111111111111111111111111116666666666666600
611111111111111111111555ddd55dd55111111111aaa00111111111111111011111111111111111111111111111111111111111111111111666666666666600
666ddd11111111111111155ddddd5ddd55011111111a010011111111111111d11111111111111111111111111111111111111111111111111166666666666600
66611d11111111111111155ddddd5ddd550111111111000111111111111111d11111111111111111111111111111111111111111111111111116666666666600
66511d1111111111111115ddddd55dddd50011111111101111111111111111d11111111111111111111111111111111111111111111111111111666666666600
66111d1111111111111115ddddd5ddddd50011111111111111111111111111d11111111111111111111111111111111111111111111111111111166666666600
6666666666111111111115dddd5555ddd50011111111111111111111111111d11111111111111111111111111111111111111111111111111111116666666600
66666666661111111111155dd555d5ddd50011111111111111111111888111d11111111111111111111111111111111111111111111111111111111666666600
66666666666111111111555555ddd55d550011111111111111111118888811d11111111111111111111111111111111111111111111111111111111166666600
6666666666111111111155ddddddd555550011111115555555551188888881ddddddddddd888ddddddddddddddddddddddddddddddddddddddddddddd6666600
666666666661111111155ddddddd55dd5500111111555dd55dd55188888881111111111188888111111111111111111111111111111111111111111111666600
66666666666611111115ddddddd55ddd50001111155dddd5ddd55088888881111111111888888811111111111111111111111111111111111111111115566600
65551666666111111115dddddd55ddd550001111155dddd5dddd5008888811111111111888888811111111111111111111111111111111111111111115556600
555116666611111111155ddddd5dddd50001111155ddda55dddd5001888111111111111888888811111111111111111111111111111111111111111111555600
5511111111111111111155ddd55dddd50001111155daad55ddd55001111111111111111188888111111111111111111111111111111111111666666666666600
55555551111111111111155555555555001111a115aaa555dd555001111111118111111118881a11111111111111111111111111111111111666666666666600
5555555511111111111111000000000000111aaa155a55d5a5550001111111188811111111111111111111111111111111111111111111111111666666666600
55555555511111111111111000000000001111aaa1555ddaaa888801111111118111111111111111111111111111111111111111111111111116666666666600
55555555551111111111111111111111111111ddddd555d5a8888881111111111111111111111111111111111111111111111111111111111666666666666600
55555555555111111111111111111111111111d1a1110558888888881111a1111111111111111111111111111111111111111111111111111666666666666600
55555555555511111111111111111111111111daaa11108888888888811aaa888111111111111111111111111111111111111111111111111166666666666600
55555555555551111111111111111111111111d1a1111d888888888881aa88888881111111111111111111111111111111111111111111111166666666666600
66655555555556111111111111111111111111d111111d8888888888811a88888881111888111111111111111111111111111111111111666666666666666600
66611111111166111111111111111111111111d111111d8888888888811888888888188888881111111111111111111111111111111111166666666666666500
55111111111666111111111111111111111111d111111d8888888888811888888888188888881111111111111111111111111111111111116666666666665500
65511111116666111111111111111111111111d111111d8888888888a11888888888888888888111111111111111111111111111111111111666666666655500
666111111666661111111111111111ddddddddddddddd8888888888adddd8888888d888888888111111111111111111111111111111111111166666666555500
666111116666661111111111111111d1111111111111888888888811111188888881888888888111111111111111111dddddd11dddddd1111116666665555500
665511166666661111111111111111d1111111111118888888888811111111888661088888881111111111111111111d111dd11d111dd1111111666655555500
665111666666661111111111111111d111611111111888888888886111111116666808888888111111111111c111111d1111d11d1111d1111111166555555500
666111111111111111111111111111d1116611111118888888888866115a116666888d18881111111111111ccc11111d1111d11d1111d1111111115555666600
666111111111111111111111111111d11166611111188888888888666655666666080d11111111111111111ccc01111d1111d11d1111d1111111111115666600
551111111111111111111111111111d11166661111188888888888886555566668000d11111111111111111ccc00111dddddd11dddddd1111111111116666600
655511111111111111111111111111d11166666115518888888888888855566688001d1111111111111111ccccc0111111111111111111111111111111666600
666511111111111111111111111111d11116666665566888888888888888566888001d11111111111111116ccc60111111111111111111111111111116666600
666111111111111111111111111111d111186666555566888888888888888688800888888811111111111166c660011dddddd11dddddd1111111111166666600
661111111111111111111111111111d1111886665555668888888888888888880888888888881111111116666666011d111dd11d111dd1111111115556666600
665111111111111111111111111111d111188866555568888888888888888880888888888888811111111c66566c011c1111d11d1111d1111111111115666600
51d111111111111111111111111111d111118886555568888888888888888888888888888888888111111c65556c001d1111d11d1111d1111111116666666600
551d11111111111111111111111111d11111188855558888888888888888888888888888888888811111cc65556cc01c1111d11d1111d1111111115666666600
5511d1111111111111111111111111d11111118885588888888888888888888888888888888888881111cc65556cc01dddddd11dddddd1111111111566666600
55511d111111111111111111111111ddddddddd888888888888888888888888888888888888888888b1111055500000c11111111111111111111111156666600
551111d1111111111111111111111111111111118888888888888888888888888888888888888888811111000000000111111111111111111111111115666600
5551111d1111111111111111111111111111111118808888888888888888888888888888888888888b1111111000111c11111111111111111111111111566600
55551111d11111111111111111111111111111111100088888888888888888888888888888888888881111111111111111111111111111111111111111156600
555111111d1111111111111111111111111511155110588888888888888888888888888888888888881111111111111111111111111111111111111111115600
66666666666666111111111111111111115551655615558888888888888888888888888888888888888111111111111111111111111111111111111111111500
66666666666661111111111111111111111555666655518888888888888888888888888888888888888111111111111111111111111111111111111111111100
666666666666d1111111111111118888888888888888888888888888888888888888888888888888888888811111111111111111111111111111111111111100
6666666666601d11111111111111811111111556655000011888888888d888888888888888888888888811811111111111111111111111111111111111111100
66666666665001d11111111111118111111116566560001111188888111888888888888888888888888811811111111111111111111111111111111111111100
666666666555551d111111111111811111111166660001111111118111a888888888888888888888888811811111111111111111111111111111111111111100
6666666655511111d111111111118111111111866800011111111181111888888888888888888888888811811111111111111111111111111111111111111100
66666665511111111d1111111111811111111886688011111111118111a888888888888888888888888811811111111111111111111111111111111111111100
666666551111166111d1111111118111111118866880111111111181111888888888888888888888888888811111111111111111111111111111111111111600
6666665555116666111d111111118111111111866800011111111181111188888888888888888888888888811111111111111111111111511111111111116600
66666655551666666111d1111111811111111166660001111888888811a188888888888888888888888888811111111111111111111111551111111111166600
666666555566666666111d11111181111111155665501118888888888aaa18888888888888888888888888881111111111111111111111555111111111666600
666666555666666666611d1111118111111666655666618888888888a8a118888888888888888888888888881111111111111ddddddddd555511111116666600
66666655666666666666d1111111811111866665566688888888888aaa88aa88888888888888888888888888811111111111d111111111555551111166666600
66666656666666666666611111118111118666888888888888888888a888888888888888888888888888888881111111111d1111111111555555111666666600
66666666666666666666661111118111111100088888888888888888888888888888888888888888888888888111111111d11111111111555555516666666600
66666666650111111d1111111111811111110888888888888888888888888888888888888888888888888888811111111d111111111111555556666666666600
6666666666111111d1111111111181111111888888888888888888888888888888888888888888888888888881111111d1111111111111555566666666666600
666666666666111d1111111111118111111888888888888888888888888888888888888888888888888888888111111d11111111111111156666666666666600
66666666666611d1111111111111811111188888888888888888888888888888888888888888888888888888811111d111111111111111116666666666666600
6666666661111d1111111111111181dddd888888888888888888888888888888888888888888888888888888111111d111111111111111111556666666666600
6666666661111d1111111111111181d111888888888888888888888888888888888888888888888888888888111111d111111111111111111156666666666600
6666666666611d1111111111111181d111888888888888888888888888888888888888888888888888888881111111d111111111111111111666666666666600
6666666661111d1111111111111181d111888888888888888888888888888888888888888888888888888881111111d111111111111111111116666666666600
6666666111111d1111111111111181d111888888888888888888888888888888888888888888888888888881111111d111111111111111111111155555666600
6666666611111d1111111111111181d111188888888888888888888888888888888888888888888888881181111111d1111111111111111111111d1115666600
6666666661111d1111111111111181d111188888888888888888888888888888888888888888888888811181111111d1111111111111111111111d1116666600
6666666666dddd1111111111111181d111118888888888888888888888888888888888888888888881111181111111d1111111111111111111111d1111666600
666666666661111111111111111181d111111888888888888888888888888888888888888888111111111181111111d1111111111111111111111d1116666600
6666666666661111111111111111811d111118888888888888888888888888888888888888811111111111811111111d11111111111111111111d11166666600
66666666666661111111111111118111d111118888888888888888888888888888888888888d11111111118111111111d111111111111111111d115556666600
666666666666661111111111111181111d111111888888888888888888888888888888888811d11111111181111111111d1111111111111111d1111115666600
6666666661111111111111111111811111d111111188888888888888888888888888888888811d11111111811111111111d11111111111111d11111115555500
66666666666611111111111111118111111d111111111d888888888888888888888888888881d1111111118111111111111d111111111111d111111115555500
666666666666611111111111111181111111d11111111d888888888888888888888888888888111111111181111111111111d1111111111d1111111115555500
6666666666666111111111111111811111111ddddddddd8888888888888888888888888888881111111111811111111111111dddddddddd11111111111555500
66666666661111111111111111118111111111111111118888888888888888888888888888881111111111811111111111111111111111111111111115555500
66666666111111111111111111118111111111111111118888888888888888888888888888881511155111811111111111111111111111111111111155555500
66666666611111111111111111118111111111111111188888888888888888888888888888885551655615851111111111111111111111a11111115555555500
6666666666111111111111111111811111111111111118888888888888888888888888888881155566665581011111111111111111111aaa1111111115555500
666666111111111111111111111181111111111111118888888888888888888888888888888111555665558000111111111111111111aa1aa111111115566600
666661111111111111111111111181111111111111118888888888888888888888888888881a111556655080011111111111111111111aaa0011111111666600
66661111111111111111111111118111111111111111888888888888888888888888888888aaa116566560801111111111111111111111a01001111166666600
666111111111111111111111111181111111111111118888888888888888888888888888881a1111666600811111111111111111111111100011111166666600
66111111111111111111111111118111111111111111888888888888888888888888888888111111866800811111111111111111111111110111111155566600
65511111111111111111111111118111111111111111888888888888888888888888888888111118866880811111111111111111111111111111111111166600
55551111111111111111111111118111111111111111888888888888888888888888888888111118866880811111111111111111111111111111111116666600
55555111111111111111111111118111111111111111188888888888888888888888888881111111866800811111111111111111111111111111111115566600
55555511111111111111111111118111111111111111188888888888888888888888888881111111666600811111111111111111111111a11111166666666600

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
010100000c0010c0010c0010c0010c0010c0010c0013a0013900134001320012d001250011f0011d0011d0011f001210010000125001260012200100001000010000100001000010000100001000010000100001
010f0000105551c552285553455234552285421c5321052234507285071c507105071c507105071c5071050700507005070050700507005070050700507005070050700507005070050700507005070050700507
01020000210571d057240572905729057150470f0372d1002c1062710623106271062a10600106001060010600106001060010600106001060010600106001060010600000000000000000000000000000000000
01100000133551f3552b3551f45500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000d55213502135020e55218552115021150211502105021355210502105020e5020e5020e5020e5020c5020c5020c5020c50200502005020c5020c5020050200502005020050200502005020050200502
01030000130631f0632b0633706318005190050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000000000000000
010500003177625776197760d77600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006
010300000c74718727007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707
010700000e122261221a1223212200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302
010200000c7521b7522c752137521a7522e7520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002005223052270520000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
01030000187530f703307530070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500000000000000000000
00050000120511e051120511e051120511e051120511e0510f0511b0511b051000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000900000a0210a0210a0210a0310a0310a0310a0310a0310a0310a0310a0310a0310a0210a0210a0210a0210a0110a0110a01108011070110501103011010510000100001130010000113001000011300100001
010300001205215052140521800218002000020000218002180020000200002180021800200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
010400001855511555195550050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
010400001415615156121560010600106001060010600106001060010600106001060010600106001060010600106001060010600106001060010600106001060010600106001060010600106001060010600106
010a00000d0441970019745197050d0441970519745197050d0441970025745197050d0441970525745197050d0441970031745197050d04419705317451970519044197000d7351970519024197050d71519705
01050000347521c756307003475700700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000105521b55214552215521a55221552195521d55213552175520d5521255208552135520e552185520c5020c5020c5020c502005020050200502005020050200502005020050200502005020050200502
0002000017550125501b550115501a550105501c55016550205501c55025550215502655022550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000300000e5551c5551555526550205501f550245501a55024550145500f5500a550135500e5501e5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000175551b5551e5551b55612550155501d5501c550165501455015550185500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000195501c5501f55021550235502355023550225501e5501a55017550185501455011550125100000011500000000000000000000000000000000000000000000000000000000000000000000000000000
0011000007750097500c7500f7501175012750147500f750117501375015750177501a7501c7501e7501f75012750147501575017750197501b7501d7501f75021750237502575026730287102a7100070000700
011400000355203552035520355206552055520555206552055520355203552035520355203552035520555205552065520355203552035520355202552025520255201552015520055200552005520055200552
011400001357313573135731357311563115631156311563105531055310553105530e5430e5430e5330e5330c5230c5230c5130c513005130051300000000000000000000000000000000000000000000000000
011000001805500005180550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001d75500705207550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00424344

