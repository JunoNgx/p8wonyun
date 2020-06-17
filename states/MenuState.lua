MenuState = {
	name = "menu",
	page = "middle",
	init = function(self)
		if (G.shipNo<13) then sfx(1) end
		self.page = "main"
		fadeIn()
		saveProgress()
	end,
	update = function(self)

		if (self.page == "main") then
			if (btnp(0)) then self.page = "credits" sfx(2) end
			if (btnp(1)) then self.page = "manual" sfx(2) end
			if (G.shipNo<13 and btnp(C.KEY_A)) then
				transit(CaptionState)
				sfx(3)
			end
		elseif (self.page == "credits") then
			if (btnp(1) or btnp(C.KEY_B)) then self.page = "main" sfx(2) end
		elseif (self.page == "manual") then
			if (btnp(0) or btnp(C.KEY_B)) then self.page = "main" sfx(2) end
		end

	end,
	draw = function(self)

		if (self.page == "main") then
			
			print("wonyun trench run", 16, 16, 8)
			print("a game by juno nguyen", 16, 24, 10)

			local shipno = (G.shipNo<13) and G.shipNo or "no ship left"
			if G.shipNo == 100 then shipno = "mothership is lost" end
			print("ship no: "..shipno, 16, 40, 6)

			-- grey dots representing lost ships
			for j=1,2 do
				for i=1,6 do
					circfill(8+16*i, 48+10*j, 3, 5)
				end
			end

			-- blue dots representing available ships
			local sn = 13 - G.shipNo -- number of ships left

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

			if (G.shipNo<13) then
				print("press ❎ to send", 64-#"press ❎ to send"*2, 104, 12)
				print("another ship", 64-#"another ship"*2, 112, 12)
			else
				printm("all is lost", 96, 12)
				printm("erase your savedata", 104, 8)
				printm("to play again", 112, 12)
				printm("press p to access pause menu", 120, 7)
			end
			
		elseif (self.page == "credits") then

			print("wonyun trench run", 64-#"wonyun trench run"*2, 16, 8)
			print("june 2020", 64-#"June 2020"*2, 24, 7)

			printm("programming", 40, 7)
			printm("art, and audio by", 48, 7)
			printm("juno nguyen", 64, 8)
			printm("@junongx", 72, 12)
			printm("very special thanks", 88, 7)
			printm("rgcddev", 96, 12)
			printm("for the inspiration", 104, 7)

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