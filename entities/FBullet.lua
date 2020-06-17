-- friendly bullet
function FBullet(_x, _y)

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
            y=C.FBULLET_SPEED
        },
        box = {
            w = 5,
            h = 6
		},
		outOfBoundsDestroy = true,
		drawTag = "projectile",
		draw = function(self)
			spr(19, self.pos.x, self.pos.y, 1, 1)
		end
    })
end