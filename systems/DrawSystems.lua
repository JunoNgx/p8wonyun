-- draw systems are not named to facilitate the usage of `item in all(items)`
-- which allows access in sequence, which is necessary for layer drawing
drawSystems = {

	System({"draw", "drawTag"},
		function(e)
			if (e.drawTag == "background") then
				e:draw()
			end
		end
	),

	-- draw shadow
	System({"draw", "shadow"},
		function(e)
			palAll(0)
			e:draw(C.SHADOW_OFFSET)
			pal()
		end
	),

	System({"id", "draw", "drawTag"},
		function(e)
			if (e.drawTag == "actor") then

				-- flashing white color when entity is damaged
				if (e.hitframe) then
					changePalForHitframe(e)
				end

				e:draw()

				if (e.hitframe) then 
					e.hitframe = false
					pal()
				end

			end
		end
	),

	System({"id", "draw", "drawTag"},
		function(e)
			if (e.drawTag == "projectile") then
					e:draw()
			end
		end
	),

	-- draw particles
	System({"id", "draw", "drawTag"},
		function(e)
			if (e.drawTag == "particle") then
					e:draw()
			end
		end
	),

	System({"draw", "drawTag"},
		function(e)
			if (e.drawTag == "foreground") then
				e:draw()
			end
		end
	),

	-- diegetic ui draw
	System({"id", "draw"},
		function(e)

			-- 
			if (e.id.class == "player") then
				-- left gauge, hp
				for i=1,(e.hp) do
					circ(gecx(e)-7, gecy(e)+9-i*2, 0, 11)
				end

				-- right gauge, ammo
				for i=1,(e.playerWeapon.ammo) do
					circ(gecx(e)+7, gecy(e)+9-i*2, 0, 12)
				end

				-- draw harvesting indicator, a green line
				asteroids = getEntitiesBySubclass("asteroid", world)
				for a in all(asteroids) do
					if a.harvestee.beingHarvested then
						line(gecx(e), gecy(e), gecx(a), gecy(a), 11)
					end
				end

			end
		end
	),

	-- draw collision boxes, for debug purpose when enabled
	System({"pos", "box"},
		function(e)
			if (C.DRAW_HITBOX_DEBUG) then
				rect(e.pos.x, e.pos.y, e.pos.x + e.box.w, e.pos.y+ e.box.h, 8)
			end
		end
	),
}