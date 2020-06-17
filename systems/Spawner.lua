spawn = {
	cooldownEnemy,
	cooldownAsteroid,
	last = {
		difficulty,
		unit
	}
}

function spawnerInit()
	spawn.cooldownEnemy = 90 +rnd(60)
	spawn.cooldownAsteroid = 60 + rnd(60)
	spawn.last = {difficulty, unit}
end

function spawnerUpdate()

	-- spawning player's remains in the previous attempts
	for c in all(G.carcasses) do
		if G.travelledDistance == c.y then
			Carcass(c.x, -16)
		end
	end

	if spawn.cooldownEnemy > 0 then
		spawn.cooldownEnemy -= 1
	else 
		spawn_enemy()
		spawn.cooldownEnemy = 
			C.SPAWNRATE_ENEMY_MIN + rnd(C.SPAWNRATE_ENEMY_RANGE)
	end
	
	if spawn.cooldownAsteroid > 0 then
		spawn.cooldownAsteroid -= 1
	else 
		spawnAsteroid()
		spawn.cooldownAsteroid = 
			C.SPAWNRATE_ASTEROID_MIN + rnd(C.SPAWNRATE_ASTEROID_RANGE)
	end
end

-- utility functions
-- random x spawn and y spawn
function getRandomSpawnX()
	return C.BOUNDS_SAFE + rnd(127 - C.BOUNDS_SAFE*2)
end

function getRandomSpawnY()
 	return -C.BOUNDS_SAFE-rnd(C.BOUNDS_OFFSET_TOP-C.BOUNDS_SAFE)
end

function spawn_enemy()

	local _difficulty, _die
	_die = rnd()

	if (_die<0.5) then _difficulty = "low" end
	if (0.5<=_die and _die<=0.85) then _difficulty = "medium" end
	if (0.85<_die) then _difficulty = "high" end

	if spawn.last.difficulty == "high" then
		_difficulty = randomOneAmong({"low", "medium"})
	end

	-- low difficulty
	if (_difficulty == "low") then

		local _formation = randomOneAmong({"riley", "hammerhead", "augustus"})

		-- one riley
		if (_formation == "riley") then
			Riley(getRandomSpawnX(), getRandomSpawnY())

		-- one hammerhead
		elseif (_formation == "hammerhead") then
			Hammerhead(getRandomSpawnX(), getRandomSpawnY())

		-- one augustus
		elseif (_formation == "augustus") then
			Augustus(getRandomSpawnX(), getRandomSpawnY())

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
			(G.travelledDistance/C.DESTINATION_DISTANCE < 0.25
			or spawn.last.unit == "koltar")) then

			_formation = randomOneAmong({"riley", "dulce", "hammerhead"})
		end

		-- two rileys, aligned
		if (_formation == "riley") then
			local _y = getRandomSpawnY()
			Riley(127 * 1/3 - 5, _y)
			Riley(127 * 2/3 - 5, _y)

		-- one dulce, no formation
		elseif (_formation == "dulce") then
			Dulce(getRandomSpawnX(), getRandomSpawnY())

		-- two hammerheads
		elseif (_formation == "hammerhead") then
			Hammerhead(127 * 1/3 - 5, getRandomSpawnY())
			Hammerhead(127 * 2/3 - 5, getRandomSpawnY())

		-- one koltar, middle
		elseif (_formation == "koltar") then
			Koltar(127/2 -16, -24)

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
			and (G.travelledDistance/C.DESTINATION_DISTANCE < 0.5
			or spawn.last.unit == "koltar")) then
				
			_formation = randomOneAmong({"riley", "dulce", "augustus"})
		end

		-- three rileys
		if (_formation == "riley") then
			local _y = getRandomSpawnY()
			Riley(127 * 1/4 - 5, _y+8)
			Riley(127 * 2/4 - 5, _y)
			Riley(127 * 3/4 - 5, _y+8)

		-- two dulces
		elseif (_formation == "dulce") then
			Dulce(getRandomSpawnX(), getRandomSpawnY())
			Dulce(getRandomSpawnX(), getRandomSpawnY())

		-- two augustus
		elseif (_formation == "augustus") then
			local _y = getRandomSpawnY()
			Augustus(127 * 1/3 - 8, _y)
			Augustus(127 * 2/3 - 8, _y)

		-- two koltar
		elseif (_formation == "koltar") then
			Koltar(127 * 1/3 - 16, -24)
			Koltar(127 * 2/3 - 16, -24)

		end

		spawn.last.unit = _formation

	end

	spawn.last.difficulty = _difficulty

end

function spawnAsteroid()
	local _type, _die, _x, _y, _vx, _vy
	_die = rnd()
	
	_type = (_die<0.5) and "large" or _type
	_type = (0.5<=_die and _die<=0.75) and "medium" or _type
	_type = (0.75<_die) and "small" or _type

	_x = getRandomSpawnX()
	_y = getRandomSpawnY()
	_vx = rnd(0.3)
	_vy = rnd(2)

	-- set asteroids to always move towards the center from sides, horizontally
	_vx = (_x < 64) and _vx or -_vx 

	Asteroid(_type, _x, _y, _vx, _vy)
end

function spawn_from_asteroid(_type, _x, _y)
	local die = ceil(rnd(3))
	local chance_for_medium = (_type=="large") and 0.3 or 0

	for i=1,die do
		local _type = rnd()<chance_for_medium and "medium" or "small"
		Asteroid(_type, _x, _y, rnd(3)-1.5, rnd(3)-1.5)
	end
end

screenshakeTimer = 0
screenshakeMagnitude = 0

function screenshake(_magnitude, _lengthinseconds)

	if (_lengthinseconds > screenshakeTimer) then
		screenshakeTimer = _lengthinseconds * 30
	end

	if (_magnitude > screenshakeMagnitude) then
		screenshakeMagnitude = _magnitude
	end
end

function screenshakeUpdate()
	if (screenshakeTimer>0) then
		screenshakeTimer -= 1
		camera(rnd(screenshakeMagnitude),rnd(screenshakeMagnitude))
	else
		camera()
		screenshakeMagnitude = 0
	end
end

function spawnExplosion(_size, _x, _y)
	-- consists of spark and smokes

	-- sfx(randomOneAmong({20, 21, 22, 23, 24}))
	sfx(22)

	if _size == "small" then
		RectSpark(_x, _y, 6, 8, 8, C.SPARK_COLOR_1)
		spawnSmokes(
			C.EXPLOSION_SMALL_AMT + rnd(C.EXPLOSION_SMALL_AMT_RANGE),
			_x, _y
		)

	elseif _size == "medium" then
		RectSpark(_x, _y, 10, 10, C.SPARK_COLOR_1)
		spawnSmokes(
			C.EXPLOSION_MEDIUM_AMT + rnd(C.EXPLOSION_MEDIUM_AMT_RANGE),
			_x, _y
		)
	elseif _size == "large" then
		RectSpark(_x, _y, 15, 12, C.SPARK_COLOR_1)
		spawnSmokes(
			C.EXPLOSION_LARGE_AMT + rnd(C.EXPLOSION_LARGE_AMT_RANGE),
			_x, _y
		)
	end
end

function spawnSmokes(_maxamt, _x, _y)

	for i=1, _maxamt do
		Smoke(
			_x + rnd(32) - 16,
			_y + rnd(32) - 16,
			0,
			-rnd(1)
		)
	end

end

function spawnFragments(_x, _y)
	_amt = C.FRAGMENT_AMT_MIN + ceil(rnd(C.FRAGMENT_AMT_RANGE))
	for i=1, _amt do 
		Fragment(_x, _y, rnd())
	end
end