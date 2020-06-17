updateSystems = {
	timerSystem = System ({"timer"},
		function(e)
			if (e.timer.lifetime > 0) then
				e.timer.lifetime -= 1
			else
				e.timer.trigger()
				del(world, e)
			end
		end
	),
	motionSystem = System({"pos", "vel"},
		function(e) 
			e.pos.x += e.vel.x
			e.pos.y += e.vel.y
		end
	),
	animationSystem = System({"ani"},
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
	collisionSystem = System({"id", "pos", "box"},
		function(e1)

			-- player 
			if (e1.id.class == "player") then

				-- player vs ebullet
				local ebullets = getEntitiesBySubclass("ebullet", world)
				for e2 in all(ebullets) do
					if coll(e1, e2) then
						sfx(6)
						e1.hp -=1
						RectSpark(gecx(e1), gecy(e1), 6, 6, 11)

						spawnFragments(gecx(e2), gecy(e2))
						del(world, e2)
					end
				end

				-- player vs asteroid/enemy
				local enemies = getEntitiesByClass("enemy", world)
				for e2 in all(enemies) do
					if coll(e1, e2) then
						e2.hp = 0
						e1.hp -= 1
					end
				end

			-- friendly bullet vs enemy
			elseif (e1.id.subclass == "fbullet") then
				local enemies = getEntitiesByClass("enemy", world)

				for e2 in all(enemies) do
					if coll(e1, e2) then
						sfx(9)
						spawnFragments(gecx(e1), gecy(e1))
						del(world, e1)

						e2.hp -= 1
						e2.hitframe = true
					end
				end

			-- hostile bullet vs asteroid
			elseif (e1.id.subclass == "ebullet") then
				local asteroids = getEntitiesBySubclass("asteroid", world)

				for e2 in all(asteroids) do
					if coll(e1, e2) then
						sfx(11)
						spawnFragments(gecx(e1), gecy(e1))
						del(world, e1)

						e2.hp -= 1
						e2.hitframe = true
					end
				end
			end
		end
	),
	healthSystem = System({"id", "hp"},
		function(e)
			if e.hp <= 0 then

				-- explosion sfx is called from spawnExplosion()
				if (e.id.class == "enemy") then

					if (e.id.size == "small") then
						spawnExplosion("small", gecx(e), gecy(e))
						screenshake(5, 0.3)

					elseif (e.id.size == "medium") then
						spawnExplosion("medium", gecx(e), gecy(e))
						screenshake(7, 0.5)

						if (e.id.subclass == "asteroid") then
							spawn_from_asteroid("medium", gecx(e), gecy(e))
						end
					elseif (e.id.size == "large") then
						spawnExplosion("large", gecx(e), gecy(e))
						screenshake(8, 0.5)

						if (e.id.subclass == "asteroid") then
							spawn_from_asteroid("large", gecx(e), gecy(e))
						end
					end

					sfx(16)
					
				elseif (e.id.class == "player") then
					spawnExplosion("large", gecx(e), gecy(e))
					screenshake(8, 0.5)
					sfx(27)
					 
					add(G.carcasses, {x=e.pos.x, y=G.travelledDistance-e.pos.y})
					exitGameplay("lose")
				end

			del(world, e)

			end
		end
	),
	keepInScreenSystem = System({"keepInScreen"},
		function(e)

			-- alternative implementation
			-- e.pos.x = min(e.pos.x, 115)
			-- e.pos.x = max(e.pos.x, 12)
			-- e.pos.y = min(e.pos.y, 115)
			-- e.pos.y = max(e.pos.y, 12)

			if (e.pos.x > 115) then e.pos.x = 115 end
			if (e.pos.x < 12) then e.pos.x = 12 end
			if (e.pos.y > 115) then e.pos.y = 115 end
			if (e.pos.y < 0) then e.pos.y = 0 end
		end
	),
	outOfBoundsDestroySystem = System({"outOfBoundsDestroy"},
		function(e)

			if (e.pos.x > 127 + C.BOUNDS_OFFSET_SIDES)
				or (e.pos.x < 0 - C.BOUNDS_OFFSET_SIDES)
				or (e.pos.y > 127 + C.BOUNDS_OFFSET_BOTTOM)
				or (e.pos.y < 0 - C.BOUNDS_OFFSET_TOP) then
				
				del(world, e)
			end
		end
	),
	particleSystem = System({"particle"},
		function(e)
			if (e.particle.lifetime < e.particle.lifetime_max) then
				e.particle.lifetime += 1
			else
				del(world, e)
			end
		end
	),
	sparkUpdateSystem = System({"spark"},
		function(e)
			e.spark.radius += C.SPARK_INCREMENT_RATE
		end
	),
	fragmentUpdateSystem = System({"fragment"},
		function(e)
			e.fragment.radius *= e.fragment.radius_rate
			e.vel.x *= e.fragment.vel_rate
			e.vel.y *= e.fragment.vel_rate
			if e.fragment.radius <= 0.1 then del(world, e) end
			if (abs(e.vel.x) < 0.01 and abs(e.vel.y) < 0.01) then del(world, e) end
		end
	),
	smokeUpdateSystem = System({"smoke"},
		function(e)
			e.smoke.radius -= C.SMOKE_DECREMENT_RATE
		end
	),
	loopingStarSystem = System({"loopingStar"},
		function(e)
			if (e.pos.y > 128+C.BOUNDS_OFFSET_SIDES) then
				e.pos.x = rnd(128)
				e.pos.y = -8
				e.vel.y = rnd(1.5)
			end
		end
	),

	-- harvesting system
	harvesteeSystem = System({"harvestee"},
		function(e)
			if (e.harvestee.beingHarvested) then

				if (e.harvestee.indicatorRadius > 2) then
					e.harvestee.indicatorRadius -= 1
				else
					e.harvestee.indicatorRadius += 1
				end
			end

			-- reset beingHarvested status when player is dead
			if (not getPlayer(world)) then
				e.harvestee.beingHarvested = false
			end
		end
	),
	harvesterSystem = System({"harvester"},
		function(e)
			asteroids = getEntitiesBySubclass("asteroid", world)

			for a in all(asteroids) do

				local harvest_distance

				if (a.id.size == "large") then
					harvest_distance = C.HARVEST_DISTANCE_LARGE
				elseif (a.id.size == "medium") then
					harvest_distance = C.HARVEST_DISTANCE_MEDIUM
				elseif (a.id.size == "small") then
					harvest_distance = C.HARVEST_DISTANCE_SMALL
				end

				if (measureDistance(gecx(e),gecy(e), gecx(a), gecy(a))
					<= harvest_distance) then

					a.harvestee.beingHarvested = true
					if (e.harvester.progress < C.HARVEST_COMPLETE) then
						e.harvester.progress +=1
						sfx(7)
					else
						e.harvester.progress = 0
						if (e.playerWeapon.ammo < C.PLAYER_AMMO_MAX) then
							e.playerWeapon.ammo += 1
							sfx(8)
						end
					end

				else 
					a.harvestee.beingHarvested = false
				end
			end
		end
	),

	-- enemy weapon system
	-- enemy firing and attacking behaviour
	enemyWeaponSystem = System({"enemyWeapon"},
		function(e)
			if (e.enemyWeapon.cooldown > 0) then
				e.enemyWeapon.cooldown -= 1;
			else 

				-- riley
				-- fires one shot aiming at the player
				if (e.enemyWeapon.type == "riley") then

					if GameplayState.isRunning then sfx(15) end

					local p = getPlayer(world)
					if p then -- making sure that player exists
						local angle, vx, vy
						angle = atan2(gecx(p)-gecx(e), gecy(p)- gecy(e))
						vx = C.RILEY_BULLET_VEL * cos(angle)
						vy = C.RILEY_BULLET_VEL * sin(angle)

						EBullet(gecx(e), gecy(e), vx, vy)
						e.enemyWeapon.cooldown = C.RILEY_FIRERATE
					end

				-- dulce
				-- "carpeting bombing" and leaves a line of bullets
				elseif (e.enemyWeapon.type == "dulce") then

					EBullet(gecx(e), gecy(e), 0, C.DULCE_BULLET_VY)
					e.enemyWeapon.cooldown = C.DULCE_FIRERATE

				-- hammerhead
				-- fires two lateral shot on each side
				elseif (e.enemyWeapon.type == "hammerhead") then

					if GameplayState.isRunning then sfx(15) end

					-- going clockwise from top right
					-- right firing
					EBullet(e.pos.x+6, e.pos.y+2, 
						C.HAMMERHEAD_BULLET_VX,
						C.HAMMERHEAD_BULLET_VY
					)
					EBullet(e.pos.x+6, e.pos.y+12,
						C.HAMMERHEAD_BULLET_VX,
						C.HAMMERHEAD_BULLET_VY
					)

					-- left firing
					EBullet(e.pos.x-2, e.pos.y+2,
						-C.HAMMERHEAD_BULLET_VX,
						C.HAMMERHEAD_BULLET_VY
					)
					EBullet(e.pos.x-2, e.pos.y+12,
						-C.HAMMERHEAD_BULLET_VX,
						C.HAMMERHEAD_BULLET_VY
					)

					e.enemyWeapon.cooldown = C.HAMMERHEAD_FIRERATE

				-- augustus
				-- fires three shot in an arc
				elseif (e.enemyWeapon.type == "augustus") then

					if GameplayState.isRunning then sfx(15) end

					-- medial bullet
					EBullet(e.pos.x+6, e.pos.y+16, 0, C.AUGUSTUS_BULLET_MEDIAL_VY)

					-- lateral bullets
					EBullet(e.pos.x+5, e.pos.y+16,
						-C.AUGUSTUS_BULLET_LATERAL_VX, 
						C.AUGUSTUS_BULLET_LATERAL_VY
					)
					EBullet(e.pos.x+7, e.pos.y+16,
						C.AUGUSTUS_BULLET_LATERAL_VX, 
						C.AUGUSTUS_BULLET_LATERAL_VY
					)

					e.enemyWeapon.cooldown = C.AUGUSTUS_FIRERATE

				-- koltar
				-- fires four shot in alternative modes
				-- axis aligned and diagonally
				elseif (e.enemyWeapon.type == "koltar") then

					if GameplayState.isRunning then sfx(18) end
					local offset_x, offset_y = 15, 6

					-- going clockwise from top
					if (e.enemyWeapon.firemode == 0) then
						
						EBullet(e.pos.x+offset_x, e.pos.y+offset_y,
							0,
							-C.KOLTAR_BULLET_VEL
						)
						EBullet(e.pos.x+offset_x, e.pos.y+offset_y,
							C.KOLTAR_BULLET_VEL,
							0
						)
						EBullet(e.pos.x+offset_x, e.pos.y+offset_y,
							0,
							C.KOLTAR_BULLET_VEL
						)
						EBullet(e.pos.x+offset_x, e.pos.y+offset_y,
							-C.KOLTAR_BULLET_VEL,
							0
						)

						e.enemyWeapon.firemode = 1

					elseif (e.enemyWeapon.firemode == 1) then

						local magnitude = C.KOLTAR_BULLET_VEL * 0.707

						EBullet(e.pos.x+offset_x, e.pos.y+offset_y,
							magnitude, -magnitude
						)

						EBullet(e.pos.x+offset_x, e.pos.y+offset_y,
							magnitude, magnitude
						)

						EBullet(e.pos.x+offset_x, e.pos.y+offset_y,
							-magnitude, magnitude
						)

						EBullet(e.pos.x+offset_x, e.pos.y+offset_y,
							-magnitude, -magnitude
						)

						e.enemyWeapon.firemode = 0
					end

					e.enemyWeapon.cooldown = C.KOLTAR_FIRERATE

				end
			end
		end
	),

	-- player-related systems
	playerWeaponSystem = System({"playerWeapon"},
	function(e)
		if (e.playerWeapon.cooldown >0) then
			e.playerWeapon.cooldown -= 1
		end
	end
	),
	controlSystem = System({"playerControl"},
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

			local speed = (btn(C.KEY_B))
				and C.PLAYER_SPEED_SLOW
				or C.PLAYER_SPEED_FAST

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


			if (btnp(C.KEY_A)) then
				if (e.playerWeapon.cooldown <=0
					and e.playerWeapon.ammo > 0) then
					sfx(5)
					FBullet(e.pos.x, e.pos.y-5)
					e.playerWeapon.cooldown = C.PLAYER_FIRERATE
					e.playerWeapon.ammo -= 1
				end
			end
			
		end
	)
}