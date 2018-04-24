dofile("TableToString.lua");
dofile("RandomImprove.lua");
state = "started"
Sensorsequenz = {}
Sensorsequenz.Stench=false
Sensorsequenz.Breeze=false
Sensorsequenz.Glitter=false
Sensorsequenz.Bump=false
Sensorsequenz.Scream=false



cellwidth = 3

function new_cave(xmax,ymax,sx,sy,sd,holes,wx,wy,gx,gy)
	local hoele = {}
	for x=1,xmax do
		hoele[x] = {}

		for y=1,ymax do
			hoele[x][y] = "_"

			if (wx == x and wy == y)then
				hoele[x][y] = "W"
			end
			if (sx == x and sy == y)then
				hoele[x][y] = "S"
			end
			if (gx == x and gy == y)then
				hoele[x][y] = "G"
			end
		end

	end

	for i,v in  pairs(holes) do
		--print(v[1],v[2])
		if hoele[v[1]][v[2]] == "_" then
			hoele[v[1]][v[2]] = "P"
		end
	end

	return {sx=sx, sy=sy, sd=sd, xmax=xmax, ymax=ymax, fixfeld=hoele}
end


function new_player(sx,sy,d,xmax,ymax)
	local pl={x=1,y=1,d="^",feld=nil,arrow="vorhanden",gold=0,xmax=xmax,ymax=ymax,hatGold=false}

	if x~=nil then
		pl.x=sx
	end
	if y~=nil then
		pl.y=sy
	end
	if d~=nil and (d=="<" or d==">" or d=="v" or d=="^") then
		pl.d=d
	end

	local lfeld = {}
	for x=1,xmax do
		lfeld[x] = {}
		for y=1,ymax do
			lfeld[x][y] = ""
			--set Position
			--print(sx,sy,x,y)
			if (sx == x and sy == y)then
				lfeld[x][y] = "P"
			end
		end
	end
	pl.feld=lfeld

	return pl;
end

function new_game(player, cave)
	player.x    = cave.sx
	player.y	= cave.sy
	player.d	= cave.sd
	player.xmax = cave.xmax
	player.ymax = cave.ymax
	return {player=player,cave=cave};
end

function new_randomgame(player, wloch)
	--mit Wahrscheinlichkeit wloch kann jedes feld ein Loch sein, aber nicht auf Startfeld oder den belegten feldern (wird von der new_cave()-Routine beachtet)
	local holes = {}
	for x=1, player.xmax do
		for y=1, player.ymax do
			if math.random() < wloch then
				table.insert(holes,{x,y})
			end
		end
	end
	--print(TableToString(holes))


	--Wumpus und Gold sind gleichverteilt, aber nicht auf Startfeld
	local wx = math.random(1,player.xmax)
	local wy = math.random(1,player.ymax)
	while wx==player.x and wy==player.y do
		wx = math.random(1,player.xmax)
		wy = math.random(1,player.ymax)
	end
	local gx = math.random(1,player.xmax)
	local gy = math.random(1,player.ymax)
	while (wx==gx and wy==gy) or (gx==player.x and gy==player.y) do
		gx = math.random(1,player.xmax)
		gy = math.random(1,player.ymax)
	end

	return new_game(player,new_cave(player.xmax,player.ymax,player.x,player.y,player.d,holes,wx,wy,gx,gy))
end

function GetCellString(value, col)
   local mid = col / 2 + 0.5 * (col % 2)

   if value == nil then value = "" end

   local val  = tostring(value)
   local len = #val
   local offset = len/2 - 0.5*(len % 2)
   local lpad = mid - offset - 1
   local rpad = col - len - lpad

   local string = ""

   for i=1,lpad do string = string .. " " end
   string = string .. val
   for i=1,rpad do string = string .. " " end
   return string
end

-- Abfragefunktionen
-- game.
--      player.
--			   x
--			   y
--			   d
--			   feld[x][y]
--      cave.
--			 xmax
--			 ymax
--			 fixfeld[x][y]

function near(x,y,game,what)
	local xmax=game.cave.xmax
	local ymax=game.cave.ymax
	local returnval = false


	if discover == true or (game.player.feld[x][y] ~= "") then
		if x>0 and y>0 then
			if x<xmax then
				if game.cave.fixfeld[x+1][y] == what then
					returnval = true
				end
			end
			if y<ymax then
				if game.cave.fixfeld[x][y+1] == what then
					returnval = true
				end
			end
		end
		if x<xmax+1 and y<ymax+1 then
			if x>1 then
				if game.cave.fixfeld[x-1][y] == what then
					returnval = true
				end
			end
			if y>1 then
				if game.cave.fixfeld[x][y-1] == what then
					returnval = true
				end
			end
		end
		if game.cave.fixfeld[x][y] == what then
			returnval = true
		end
	end

	if game.player.feld[x][y] == "P" then
		if what=="P" then
			Sensorsequenz.Breeze=returnval
		end
		if what=="W" then
			Sensorsequenz.Stench=returnval
		end

		if game.cave.fixfeld[x][y] == "G" then
			Sensorsequenz.Glitter=true
		else
			Sensorsequenz.Glitter=false
		end
	end

	if what=="G" and game.cave.fixfeld[x][y] ~= "G" then
		returnval=false
	end
	return returnval
end

function gold(x,y,game)
	if near(x,y,game,"G") then
		return "G"
	end
	return ""
end
function stench(x,y,game)
	if near(x,y,game,"W") then
		return "S"
	end
	return ""
end
function breeze(x,y,game)
	if near(x,y,game,"P") then
		return "B"
	end
	return ""
end
function visited(x,y,game)
	if game.player.feld[x][y] ~= "" then
		return "V"
	end
	return ""
end
function feld(x,y,game)
	if game.player.feld[x][y] == "P" then
		--game.cave.fixfeld
		--print(TableToString(game.player))
		return game.player.d
	end
	return game.cave.fixfeld[x][y]
end
function position(x,y,game)
	if game.player.feld[x][y] == "P" then
		--print(TableToString(game.player))
		return game.player.d
	end
	return ""
end

function print_game(game)
	discover = nil

	local trennline = ""

	for  y = game.cave.ymax, 1, -1 do
		local oline = GetCellString(" ",cellwidth) .. "|"
		local mline = GetCellString(y,cellwidth) .. "|"
		local uline = GetCellString(" ",cellwidth) .. "|"
		trennline = "----"
		for x=1, game.cave.xmax do
			oline = oline .. GetCellString(" ",cellwidth) .. string.lower(GetCellString(gold(x,y,game),cellwidth)) .. GetCellString(" ",cellwidth) .. "|"
			mline = mline .. string.lower(GetCellString(stench(x,y,game),cellwidth)) .. GetCellString(position(x,y,game),cellwidth) .. string.lower(GetCellString(breeze(x,y,game),cellwidth)) .. "|"
			uline = uline .. GetCellString(" ",cellwidth) .. string.lower(GetCellString(visited(x,y,game),cellwidth)) .. GetCellString(" ",cellwidth) .. "|"
			trennline = trennline .. "----------"
		end
		print(trennline)
		print(oline)
		print(mline)
		print(uline)
	end

	print(trennline)

	local numline = GetCellString(" ",cellwidth) .. "|"
	for  x = 1, game.cave.xmax do
		numline = numline .. GetCellString(x,cellwidth*3) .. "|"
	end
	print(numline)
	print("")

end

function print_discovered(game)
	discover = true
	local trennline = ""

	for  y = game.cave.ymax, 1, -1 do
		local oline = GetCellString(" ",cellwidth) .. "|"
		local mline = GetCellString(y,cellwidth) .. "|"
		local uline = GetCellString(" ",cellwidth) .. "|"
		trennline = "----"
		for x=1, game.cave.xmax do
			oline = oline .. GetCellString(" ",cellwidth) .. string.lower(GetCellString(gold(x,y,game),cellwidth)) .. GetCellString(" ",cellwidth) .. "|"
			mline = mline .. string.lower(GetCellString(stench(x,y,game),cellwidth)) .. GetCellString(feld(x,y,game),cellwidth) .. string.lower(GetCellString(breeze(x,y,game),cellwidth)) .. "|"
			uline = uline .. GetCellString(" ",cellwidth) .. string.lower(GetCellString(visited(x,y,game),cellwidth)) .. GetCellString(" ",cellwidth) .. "|"
			trennline = trennline .. "----------"
		end
		print(trennline)
		print(oline)
		print(mline)
		print(uline)
	end

	print(trennline)

	local numline = GetCellString(" ",cellwidth) .. "|"
	for  x = 1, game.cave.xmax do
		numline = numline .. GetCellString(x,cellwidth*3) .. "|"
	end
	print(numline)
	print("")
end

function print_toInput(game)
	local holes = {}
	local wx = 0
	local wy = 0
	local gx = 0
	local gy = 0


	for x=1, game.cave.xmax do
		for y=1, game.cave.ymax do
			if game.cave.fixfeld[x][y] == "W" or  game.cave.fixfeld[x][y] == "w" then
				wx=x
				wy=y
			end
			if game.cave.fixfeld[x][y] == "G" or  game.cave.fixfeld[x][y] == "g" then
				gx=x
				gy=y
			end
			if game.cave.fixfeld[x][y] == "P" then
				table.insert(holes,{x,y})
			end
		end
	end

	local ausgabe="new_game(new_player(" .. game.cave.sx .. "," .. game.cave.sy .. ",\"" .. game.cave.sd .. "\"," .. game.cave.xmax .. "," .. game.cave.ymax .. "),new_cave(" .. game.cave.xmax .. "," .. game.cave.ymax .. "," .. game.cave.sx .. "," .. game.cave.sy .. ",\"" .. game.cave.sd .. "\"," .. TableToString(holes) .. "," .. wx .. "," .. wy .. "," .. gx .. "," .. gy .. "))"
	print(ausgabe)
end

-- Aktionen

function Forward(game)
	local moved = 0
	game.player.feld[game.player.x][game.player.y]="V"

	if game.player.d == "<" then
		if game.player.x > 1 then
			game.player.x = game.player.x-1
			moved = -1
		end
	else
		if game.player.d == ">" then
			if game.player.x < game.cave.xmax then
				game.player.x = game.player.x+1
				moved = -1
			end
		else
			if game.player.d == "^" then
				if game.player.y < game.cave.ymax then
					game.player.y = game.player.y+1
					moved = -1
				end
			else
				if game.player.d == "v" then
					if game.player.y > 1 then
						game.player.y = game.player.y-1
						moved = -1
					end
				end
			end
		end
	end
	if game.cave.fixfeld[game.player.x][game.player.y]=="W" or game.cave.fixfeld[game.player.x][game.player.y]=="P" then
		--verloren
		state = "lost"
		moved = -1000
	end
	if moved<0 then
		Sensorsequenz.Bump=false
	else
		Sensorsequenz.Bump=true
	end
	game.player.gold=game.player.gold+moved
	game.player.feld[game.player.x][game.player.y]="P"
end

function oldToNewDir(direction,LeftOrRight) --LeftOrRight=true für left
	if LeftOrRight then
		if direction == "<" then
			return "v"
		else
			if direction == ">" then
				return "^"
			else
				if direction == "^" then
					return "<"
				else
					if direction == "v" then
						return ">"
					end
				end
			end
		end
	else
		if direction == "<" then
			return "^"
		else
			if direction == ">" then
				return "v"
			else
				if direction == "^" then
					return ">"
				else
					if direction == "v" then
						return "<"
					end
				end
			end
		end
	end
end

function TurnLeft(game)
	Sensorsequenz.Bump = false
	game.player.gold = game.player.gold - 1
	game.player.d = oldToNewDir(game.player.d,true)
end

function TurnRight(game)
	Sensorsequenz.Bump = false
	game.player.gold = game.player.gold - 1
	game.player.d = oldToNewDir(game.player.d,false)
end

function Grab(game)
	if game.cave.fixfeld[game.player.x][game.player.y] == "G" then
		game.cave.fixfeld[game.player.x][game.player.y] = "g"
		game.player.gold=game.player.gold+1000
		game.player.hatGold=true
	else
		game.player.gold=game.player.gold-1
	end
end

function Shoot(game)
	if game.player.arrow ~= nil then
		game.player.gold=game.player.gold-10
		game.player.arrow=nil

		--shoot,
		local hit = false
		local direction = -1
		local ende = 1
		if game.player.d == "<" or  game.player.d == ">" then
			--horizontale Richtung
			if  game.player.d == ">" then
				direction = 1
				ende = game.cave.xmax
			end
			--print("horizontaler schuss", direction, ende)
			for i=game.player.x, ende, direction do
				--print(i, game.cave.fixfeld[i][game.player.y])
				if game.cave.fixfeld[i][game.player.y]=="W" then
					hit = true
					game.cave.fixfeld[i][game.player.y]="w"
				end
			end
		else
			--vertikale Richtung
			if  game.player.d == "^" then
				direction = 1
				ende = game.cave.ymax
			end
			--print("vertikaler schuss", direction, ende)
			for i=game.player.y, ende, direction do
				if game.cave.fixfeld[game.player.x][i]=="W" then
					hit = true
					game.cave.fixfeld[game.player.x][i]="w"
				end
			end
		end
		--
		if hit then
			--print("treffer")
			Sensorsequenz.Scream=true
		else
			state = "lost"
			--print("daneben")
		end
		--]]
	end
end
function Climb(game)
	--print(game.player.x, game.cave.sx , game.player.y , game.cave.sy , game.player.hatGold , Sensorsequenz.Scream)
	if game.player.x == game.cave.sx and game.player.y == game.cave.sy and game.player.hatGold and Sensorsequenz.Scream then
		state = "win"
	end
end

function Move(action, game)
	action=string.lower(action)
	if state ~= "lost" and state ~= "win" then
		if action=="s" then
			Shoot(game)
		end
		if action=="l" then
			TurnLeft(game)
		end
		if action=="r" then
			TurnRight(game)
		end
		if action=="g" then
			Grab(game)
		end
		if action=="f" then
			Forward(game)
		end
		if action=="c" then
			Climb(game)
		end
	end
	near(game.player.x,game.player.y,game,"P")
	near(game.player.x,game.player.y,game,"W")
	near(game.player.x,game.player.y,game,"G")
end

function MultiMove(actions, game)
	for i,v in pairs(actions) do
		print_game(game)
		print(TableToString(Sensorsequenz))
		Move(v,game)
	end
	print_game(game)
	print(TableToString(Sensorsequenz))
	print(state, "Gold=", game.player.gold)
end

function getInputs(game)
	local decision = nil
	repeat
		repeat
			print_game(game)
			print(TableToString(Sensorsequenz))
			print("Action (F, L, R, G, S or C)?");
			io.flush();
			decision = io.read();
		until (decision ~= nil)

		-- game step
		Move(decision,game)

		print(state, "Gold=", game.player.gold)
	until(state == "lost" or state == "win")

	print_game(game)
	print(TableToString(Sensorsequenz))
	print(state, "Gold=", game.player.gold)
end

--[[Spielerstartposition
local sx=1
local sy=1
local xmax=4
local ymax=4
local direction = ">"

--		        new_game(new_player( x, y,direction,xmax,ymax),new_cave(xmax,ymax,sx,sy,direction,{{l1x,l1y},{l2x,l2y}},wx,wy,gx,gy))
local spiel  = new_game(new_player(sx,sy,direction,xmax,ymax),new_cave(xmax,ymax,sx,sy,direction,{{2  ,2  },{3  ,4  }},3 ,1 ,2 ,4 ))
local spiel2 = new_game(new_player(1,1,">",4,4),new_cave(4,4,1,1,">",{{1,2},{4,2}},2,2,3,3))

local rspiel = new_randomgame(new_player(sx,sy,direction,xmax,ymax),0.1)
getInputs(rspiel)
--]]
--print_toInput(rspiel)
--print_discovered(rspiel)

--loose
--MultiMove({"F","F","F","L","F","F","F","L","F","F","F","L","F","L","F","F","R","F","R","F","F"}, spiel)
--MultiMove({"F","F","F"}, spiel)
--MultiMove({"F","L","F","F"}, spiel)
--win:
--MultiMove({"F","L","L","F","R","F","F","F","R","F","G","R","F","L","F","R","S","R","F","F","L","F","F","C"}, spiel)
--MultiMove({"F","F","F","L","L","F","R","F","F","G","L","F","L","S","F","F","R","F","C"}, spiel2)



--Shift+F5 zum löschen der Ausgabe
