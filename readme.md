# Wonyun Trench Run

* **Genre**: Shump/Bullet-hell
* **Platform**: [PICO-8](https://www.lexaloffle.com/pico-8.php)
* **Language/Framework**: Lua (Pico-8 subset)
* **Release date**: 16 June 2020

## Releases

* **[Itch.io](https://junongx.itch.io/wonyun-trench-run)**
* **[PICO-8 Cartridge Page](https://www.lexaloffle.com/bbs/?pid=78124)**

## Overview 

**Wonyun Trench Run** focuses on a group of pilot stationed at the titular Wonyun outpost, who encountered an invasion and decided to one by one make the run through the siege to alert the mothership.

The game takes a more defensive on the genre of bullet hell genre, in which ammunition and offenses are limited and evasive maneuvres are paramount.

## The original project

This is the re-interpreted and completed version of [Project Wonyun](https://github.com/JunoNgx/Project-Wonyun), which was in turned heavily inspired by [RGCD.DEV's r0x EP](https://rgcddev.itch.io/r0x-extended-play) and made with [LÖVE](https://love2d.org/). **Project Wonyun** was close to feature-complete, but was abandoned at some point of time in 2014.

The game was meant to be part of a much larger universe spanning across multiple titles, but like most fantasies in life, they were never made.

Besides gamedev as what I absolutely loved and another project to hone my skills, this game was a satisfying closure to one of my old incomplete works.

## Lives and reset savedata

The game allows only a limited number of attempts to reach the objective destination. Gameplay will no longer be accessible once the player has used up all ships, and the main menu will prompt the player **reset savedata** to try again.

**This can be performed from the pause menu** (default keybinding on Pico-8 is `P`).

## Technicalities

### State machine

The game is powered by a simple **finite state machine**, including `SplashState`, `MenuState`, `CaptionState` (handles the message screen prior to gameplay as well as the final outro), `GameplayState` and a special transitory state `TransitState`, which handles the fading transition using [kometbomb's color fade generaator](https://www.lexaloffle.com/bbs/?tid=28552).

### Entity component system

The game implments a simply **ecs** [inspired by a post by selfsame](https://www.lexaloffle.com/bbs/?pid=44917).

These two functions drive the bulk of the  game:

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

Each **entity** is comprised of multiple **components**, each represented as a sub-table with the *key* as the component's identifier. An example is the `fbullet` (for "friendly bullet") entity object:

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
                y=C.FBULLET_SPEED -- a constant for game design
            },
            box = {
                w = 5,
                h = 6
            },
            outOfBoundsDestroy = true, -- destroyed when out of screen
            drawTag = "projectile", -- draw layer
            draw = function(self)
                spr(19, self.pos.x, self.pos.y, 1, 1)
            end
        })
    end

An example of a system is the `motionsys` (for "motion system"):

	motionSystem = System({"pos", "vel"},
		function(e) 
			e.pos.x += e.vel.x
			e.pos.y += e.vel.y
		end
	)

Entities are stored in a global table `world = {}`, which is iterated over by multiple systems.

### Global constant table

Most of the important values that affect gameplay are declared in the separated file `C.lua` (Lua does not have `const`, but you get the idea), which facilitates game design tuning and iterations.

### Hitbox debug mode

To view the actual hitboxes of entities, change `C.DRAW_HITBOX_DEBUG` (the same file mentioned above) to `true`.

## Feedback

Do feel free to open an issue to this repository for feedback and suggestion. Code critiques are especially welcomed.
