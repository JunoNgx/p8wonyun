pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- Project Wonyun
-- by Juno Nguyen

-- component entity system and utility functions

c = {
	player_firerate = 5
}

world = {}

function _has(e, ks)
	for c in all(ks) do
        if (not e[c]) then 
            return false
        end
    end
    return true
end

function system(ks, f)
    return function(system)
        for e in all(system) do
            if _has(e, ks) then
                f(e)
            end
        end
    end
end

function getid(_id)
    t = {}
    for e in all(world) do
		if (e.id) then
			if (e.id.class == _id) then
				add(t, e)
			end
        end
    end
    return t
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

fader = {
	time = 0,
	pos = 0, -- full black, according to the table
	projected_time_taken = 0,
	projected_velocity = 0,
	table= {
		-- position 15 is all black
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
	-- print(fader.pos)
	-- print(fader.projected_time_taken)
	-- print(fader.projected_velocity)
	-- print(fader.time)
	-- pal()
	for c=0,15 do
		if flr(_position+1)>=16 then
			pal(c,0)
		else
			pal(c,fader.table[c+1][flr(_position+1)],1)
		end
	end
end

function fadesettrigger(_trigger)
	if _trigger then
		fader.trigger = _trigger
		fader.triggerperformed = false
	end
end

-->8
-- primary game loops

gamestate = {}

-- each state is an object with loop functions

splashstate = {
	name = "splash",
	init = function()
		fadein()
		splashtimer =45
	end,
	update = function()
		if (splashtimer > 0) then
			splashtimer -= 1
		else
			transit(menustate)
		end
	end,
	draw = function()
		-- draw logo at sprite number 64
		spr(64, 32, 48, 64, 32)
	end
}

menustate = {
	name = "menu",
	init = function()
		fadein()
	end,
	update = function()
		if (btn(5)) then 
			transit(gameplaystate)
		end
	end,
	draw = function()
		print("project wonyun", 16, 16, 8)
		print("lives left: 47", 16, 32, 7)
		print("weapon level: 2", 16, 64, 7)
		print("armor level: 4", 16, 72, 7)
		print("press x to send another ship", 16, 120, 7)
		spr(1, 12, 12)
	end
}

gameplaystate = {
	name = "gameplay",
	init = function()
		fadein()
		world = {}
		player(64, 64)

		enemy(64, 32, 0, 0.1)
		enemy(32, 32, 0, -1)
		enemy(96, 32, 1, 0)
	
		timer(1, function()
			enemy(12, 12, 1, 1)
		end)
	end,
	update = function()
		for key,system in pairs(updatesystems) do
			system(world)
		end

	end,
	draw = function()
		print(count(world))
		for system in all(drawsys) do
			system(world)
		end
	end
}

transitor = {
	timer = 0,
	destination_state,
}


transitstate = {
	name = "transit",
	init = function()

	end,
	update = function()
		if (transitor.timer > 0) then
			transitor.timer -=1
		else 
			gamestate = transitor.destination_state
			gamestate.init()
		end
	end,
	draw = function()

	end
}

function transit(_state)
	fadeout()
	gamestate = transitstate
	transitor.destination_state = _state
	transitor.timer = 28
end

function _init()
	gamestate = gameplaystate
	gamestate.init()
end

function _update()
	gamestate.update()
	fade_update()
end

function _draw()
	-- due to interference with fading
	if (gamestate.name ~= "transit") cls()

	gamestate.draw()
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
	collisionsys = system({"id", "pos", "box"},
		function(e1)
			if (e1.id.class == "fbullet") then
				enemies = getid("enemy")
				for e2 in all(enemies) do
					if coll(e1, e2) then
						del(world, e1)
						e2.hp -= 1
					end
				end
			end
		end
	),
	healthsys = system({"hp"},
		function(e)
			if e.hp == 0 then
				-- explosion(e.pos.x, e.pos.y)
				del(world, e)
			end
		end
	),
	playerweaponsystem = system({"playerweapon"},
		function(e)
			if (e.playerweapon.cooldown >0) then
				e.playerweapon.cooldown -= 1
			end
		end
	),
	keepinboundssys = system({"keepsinbounds"},
		function(e)
			e.pos.x = min(e.pos.x, 128)
			e.pos.x = max(e.pos.x, 0)
			e.pos.y = min(e.pos.y, 128)
			e.pos.y = max(e.pos.y, 0)
		end
	),
	outofboundsdestroysys = system({"outofboundsdestroy"},
		function(e)
			local bounds_offset = 10
			if (e.pos.x > 128 + bounds_offset)
				or (e.pos.x < 0 - bounds_offset)
				or (e.pos.y > 128 + bounds_offset)
				or (e.pos.y < 0 - bounds_offset) then
				
				del(world, e)
			end
		end
	),
	controlsys = system({"playercontrol"},
		function(e)
			local speed = 3
			-- sign = (x < 0) ? "negative" : "non-negative";
			-- e.vel.x = (btn(0)) and -speed or 0;
			-- e.vel.x = (btn(1)) and speed or 0;
			-- e.vel.y = (btn(2)) and -speed or 0;
			-- e.vel.y = (btn(3)) and speed or 0;

			if (btn(0)) then
				e.vel.x = -speed
			elseif (btn(1)) then
				e.vel.x = speed
			else
				e.vel.x = 0
			end
			
			if (btn(2)) then
				e.vel.y = -speed
			elseif (btn(3)) then
				e.vel.y = speed
			else
				e.vel.y = 0
			end

			if (btn(5)) then
				if (e.playerweapon.cooldown <=0) then
					fbullet(e.pos.x+1, e.pos.y)
					e.playerweapon.cooldown = c.player_firerate
					-- e.playerweapon.ammo -= 1
				end
			end
		end
	)
}
-->8
-- draw systems
drawsys = {
	-- draw shadow system
	system({"id", "pos", "shadow"},
		function(e)
			
			-- distance from object to shadow
			local offset = 2

			for color=1, 15 do 
				pal(color, 1)
			end
			if (e.id.class == "enemy") then
				if (e.id.subclass == "hammerhead") then
					spr(32, e.pos.x-3+offset, e.pos.y+offset, 2, 2)
					-- rect(0, 0, 10, 10)
				end
			elseif (e.id.class == "player") then
				spr(0, e.pos.x+offset, e.pos.y+offset, 1.2, 2)
			end
		end
	),
	-- draw sprites system
	system({"id", "pos"},
		function(e)
			
			if (e.id.class == "player") then
				pal()
				-- draw main body
				spr(0, e.pos.x-2, e.pos.y, 1.2, 2)
				
				-- right gauge, hp
				for i=1,(e.hp) do
					circ(e.pos.x-5, e.pos.y + 14 - i*2, 0, 11)
				end

				-- draw ammunition
				-- for i=0,(e.hp) do
				-- 	circ(e.pos.x+9, e.pos.y + 12 - i*2, 0, 8)
				-- end


			elseif (e.id.class == "enemy") then
				if (e.id.subclass == "hammerhead") then
					pal()
					spr(32, e.pos.x-3, e.pos.y, 2, 2)
					-- right gauge, hp
					for i=1,(e.hp) do
						circ(e.pos.x-5, e.pos.y + 14 - i*2, 0, 11)
					end
				end

			elseif (e.id.class == "fbullet") then
				pal()
				spr(18, e.pos.x, e.pos.y, 1, 1)
			end
		end
	),
	-- draw collision boxes, for debug purposes
	system({"pos", "box"},
		function(e)
			pal()
			rect(e.pos.x, e.pos.y, e.pos.x + e.box.w, e.pos.y+ e.box.h, 8)
		end
	),
}

-->8
-- entity constructors

function player(_x, _y)

    add(world, {
        id = {
            class = "player"
        },
        pos = {
            x=_x,
            y=_y,
        },
        vel = {
            x=0,
            y=0,
        },
        box = {
            w = 4,
            h = 12,
		},
		hp = 4,
		playerweapon = {
			ammo = 4,
			cooldown = 0
		},
		playercontrol = true,
		keepsinbounds = true,
		shadow = true,
	})
end

function enemy(_x, _y, _vx, _vy)

    add(world, {
        id = {
            class = "enemy",
            subclass = "hammerhead"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=_vx,
            y=_vy
        },
        box = {
            w = 9,
            h = 16
		},
		hp = 3,
		weapon = true,
		shadow = true,
		outofboundsdestroy = true,
    })
end

-- friendly bullet
function fbullet(_x, _y)

	local speed = -12

    add(world, {
        id = {
            class = "fbullet"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=speed
        },
        box = {
            w = 2,
            h = 6
		},
		ani = {

		},
		outofboundsdestroy = true,
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
0000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccc6ccc000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc666cc00000000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc666ccc0000000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc666ccc0000000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006660000000000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050005500050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555065560555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055566665550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005556655500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000556655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000656656000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000086680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000886688000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000886688000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000086680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000556655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066665566660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00866665566668000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00866688886668000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000077777770077777077777077777007777707777707077077777770000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707700070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007777707000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070077707070007077707007000007770707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000000000000000000003000035000380003a0003900034000320002d000250001f0001d0001d0001f000210000000025000260002200000000000000000000000000000000000000000000000000000
