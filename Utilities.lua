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
function System(ks, f)
    return function(system)
        for e in all(system) do
            if _has(e, ks) then f(e) end
        end
    end
end

-- return of list with entity owning the corresponding id class
function getEntitiesByClass(_class, _world)
    local filteredEntities = {}
    for e in all(_world) do
		if not e.id then return end
		if (e.id.class == _class) then
			add(filteredEntities, e)
		end
    end
    return filteredEntities
end

function getEntitiesBySubclass(_subclass, _world)
    local filteredEntities = {}
	for e in all(_world) do
		if not (e.id) then return end
		if (e.id.subclass == _subclass) then
			add(filteredEntities, e)
		end
    end
    return filteredEntities
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

function palAll(_color) -- switch all colors to target color
	for color=1, 15 do 
		pal(color, _color)
	end
end

-- switch all color to white (7) for a flashing effect when entity is damaged
function changePalForHitframe(_entity) 
	if (_entity.hitframe) then palAll(7) end
end

fader = {
	time = 0,
	pos = 0, -- full black, according to the table
	projectedTimeTaken = 0,
	projectedVelocity = 0,
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

function fadeIn()
	fade(15, 0, 1)
end

function fadeOut()
	fade(0, 15, 1)
end

function fade(_begin, _final, _durationInSecs)
	-- 30 ticks equal one second
	fader.projectedTimeTaken = _durationInSecs * 30
	-- elementary math of v = d/t
	fader.projectedVelocity = (_final - _begin) / fader.projectedTimeTaken
	fader.pos = _begin
	fader.time = 0
	fader.status = "working"
end

function fadeUpdate()
	if (fader.time < fader.projectedTimeTaken) then
		fader.time +=1
		fader.pos += fader.projectedVelocity
	end
end

function fadeDraw(_position)
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

function fadeSetTrigger(_trigger)
	if _trigger then
		fader.trigger = _trigger
		fader.triggerPerformed = false
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
function randomOneAmong(object)
	local die = ceil(rnd(#object))

	return object[die]
end

-- due to the max positive integer value in pico-8 being 32767
-- this function won't be able to handle distances longer than
-- 181 pixels
function measureDistance(x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	return sqrt(dx*dx + dy*dy)
end

function getPlayer(_world)
	for e in all(world) do
		if not e.id then break end
		if (e.id.class == "player") then return e end
	end
	return nil
end

function printm(_content, _y, _color)
    print(_content, 64-#_content*2, _y, _color
)
end