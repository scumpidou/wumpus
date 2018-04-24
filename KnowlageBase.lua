dofile("HtW.lua");
dofile("Queue.lua");

xmax=4
ymax=4

KB = {}
KB["i"]={}
KB["f"]={}

function KBAusgabe()
local localKB = copyTable(KB)
	print("")
	print("KBAusgabe")
	print("i", #localKB.i, TableToString(localKB.i))
	print("f", #localKB.f, TableToString(localKB.f))
	localKB.i=nil
	localKB.f=nil
	print(TableToString(localKB))
end

-- Positionen in Groﬂbuchstaben, empfinden in Klinbuchstaben, - ist verneinung
-- in der Form #XY, wobei x und y die Koorsinaten sind und # eine der Folgenden Parameter
-- P=Pit
-- W=Wumpus
-- G=Gold
-- E=Exit			(Wird bei jedem schritt aktualisiert)
-- C=Current Room	(wird bei jedem schritt aktualisiert)

-- b=Breeze			(wird bei jedem schritt aktualisiert)
-- s=Stench			(wird bei jedem schritt aktualisiert)
-- g=Glitter		(wird bei jedem schritt aktualisiert)
-- u=Bump			(wird bei jedem schritt aktualisiert)

-- R=Rule Sonstige aussagenlogische Regeln

HashDelim = "::"

----------------------------------------------------------------------------
-------------------------Allgemeine Funktionen-----------------------------
----------------------------------------------------------------------------

function split_string(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
    	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end
function Dehash(value)
	--print("dehash", value)
    local stringarr = split_string(value, HashDelim)

    return {tonumber(stringarr[1]),tonumber(stringarr[2])}
end

--Wandelt Boolean in vorzeichen um
function trueFalse(value)
	if value then
		return ""
	else
		return "-"
	end
end

--gleichheit der Werte
function equal(aa,bb)
	local a = copyTable(aa)
	local b = copyTable(bb)
	if type(a)=="table" and type(b)=="table" then
		if  #a==#b then
			--inhalte vergleichen
			local anz=#a
			for index=1,#a do
				local buff = table.remove(a)
				for i,v in pairs(b) do
					if equal(buff,v) then
						anz=anz-1
						table.remove(b,i)
						break
					end
				end
			end
			if anz==0 then
				return true
			else
				return false
			end
		end
	elseif type(a)==type(b) then
		return a==b
	else
		return false
	end
end

--Kopiert inhalte in neue Tabelle
function copyTable(t1)
	local newtable = {}
	if type(t1)=="table" then
		for i,v in pairs(t1) do
			newtable[i]=copyTable(v)
		end
	else
		newtable = t1
	end
	return newtable
end

----------------------------------------------------------------------------
----------------------------Mengenfunktionen--------------------------------
----------------------------------------------------------------------------

function teilmengeGleich(teil ,ganzes)
	--print("teilmenge", TableToString(teil) ,TableToString(ganzes))
	local anzahl=#copyTable(teil)
	for _,v1 in pairs(teil) do
		for _,v2 in pairs(copyTable(ganzes)) do

			local anzahl2=#v1
			--print(type(v1))
			if #v1==#v2 and type(v1)=="table" and type(v2)=="table" then
				for _,v11 in pairs(v1) do
					for _,v22 in pairs(v2) do
						if v11==v22 then
							anzahl2 = anzahl2-1
							break
						end
					end
				end
			end

			if anzahl2==0 or v1==v2 then
				anzahl = anzahl-1
				break
			end
		end
	end
	--print("teilmenge anzahl ungleicher Elemente" ,anzahl)
	if anzahl==0 then
		return true
	else
		return false
	end
end

--Vereinigung
function union(t1, t2) --gleichwertige tabellen werden erwartet
	local t = copyTable(t1);
	for _, v2 in ipairs(t2) do
		local found = false;

		for _, v1 in ipairs(t1) do
			if (type(v1) == "table") then
				if (#v1 == #v2 and #union(v1, v2) == #v1) then
					found = true;
				end
			else
				if (v1 == v2) then
					found = true;
				end
			end
		end
		if (found == false) then
			table.insert(t, v2);
		end
	end
	--print("union", TableToString(t1),TableToString(t2),TableToString(t))
	return t;
end

--KB S‰ubern (Doppelte Tabellen rauswerfen)
function clean(tabelle)
	local newtabelle = {}
	for i1,v1 in pairs(tabelle) do
		if type(i1)=="table" then
			local found = false

			for i2,v2 in pairs(tabelle) do
				if i1<i2 and equal(v1,v2) then
					found = true
					break
				end
			end

			if found~=true then
				table.insert(newtabelle,v1)
			end
		else
			newtabelle[i1] = v1
		end
	end
	--print(TableToString(KBnew))
	return newtabelle
end

----------------------------------------------------------------------------
----------------------------Spielspeziefisch--------------------------------
----------------------------------------------------------------------------

function getPosition(action)
	--vorige Position aus KB holen
	local x=-99
	local y=-99

	--alte position
	local buff = Dehash(KB["C"])
	x = buff[1]
	y = buff[2]

	--print("aktuelle Position ", x,y)
	if string.lower(action)=="f" and not Sensorsequenz.Bump then
		--je nach action vorgehen
		if KB["Direction"] == "<" then
			x=x-1
		elseif KB["Direction"] == ">" then
			x=x+1
		elseif KB["Direction"] == "^" then
			y=y+1
		elseif string.lower(KB["Direction"]) == "v" then
			y=y-1
		end
	end

	return tostring(x) .. HashDelim .. tostring(y)
end


function MoveKB(actions, game)
	local action
	if string.len(actions)==1 then
		action=string.lower(actions)
	else
		action=string.sub(string.lower(actions), 1, 1)
	end

	if action=="a" then
		ASK(MakeQuery("P",getPosition("f")))
		if KB["wumpus"]==true then
			ASK(MakeQuery("W",getPosition("f")))
		end
	else
		if action~="0" then
			if action=="l" or action=="r" then
				KB["Direction"]=oldToNewDir(KB["Direction"], action=="l")
			end
			Move(action, game)
			if action=="f" then	--position aktualisieren
				KB["C"] = getPosition(action)
			end
		else
		--taste 0 f¸r hidden cheating^^
			print_game(game)
			print(TableToString(Sensorsequenz))
		end
	end
	TELL(Sensorsequenz,getPosition(""))

	if string.len(actions)>1 then
		MoveKB(string.sub(string.lower(actions), 2, -1), game)
	end
end

function getInputsKB(game)
	local decision = nil
	print("Shift+F5 zum Lˆschen der vorigen Ausgaben.\nActions: Front, Left, Right, Grab, Shoot, Climb, Tell OR Ask");
	print("Action (F, L, R, G, S, C, T OR A)?");
	repeat
		--print("getInputsKB", #KB, TableToString(KB))
		print_game(game)
		repeat
			io.flush();
			decision = io.read();
		until (decision ~= nil)

		-- game step
		KBAusgabe()
		MoveKB(decision, game)

	until(state == "lost" or state == "win")

	print_game(game)
	print(TableToString(Sensorsequenz))
	print(state, "Gold=", game.player.gold)
end

----------------------------------------------------------------------------
-----------------------------Aussagenlogik---------------------------------
----------------------------------------------------------------------------

--Atomare Aussage negieren
function negate(outer_sentence)
local sentence = copyTable(outer_sentence)
	if type(sentence)=="table" and #sentence==1 then
		if type(sentence[1])=="table" then
			if string.sub(sentence[1][1],1,1)=="-" then
				sentence={{string.sub(sentence[1][1],2,-1)}}
			else
				sentence={{"-"..sentence[1][1]}}
			end
		else
			if string.sub(sentence[1],1,1)=="-" then
				sentence={string.sub(sentence[1],2,-1)}
			else
				sentence={"-"..sentence[1]}
			end
		end
	else
		--[[if type(sentence)=="string" then
			if string.sub(sentence,1,1)=="-" then
				sentence=string.sub(sentence,2,-1)
			else
				sentence="-"..sentence
			end
		else]]
			--print("Fehler, negieren klappt nicht", sentence, TableToString(sentence), type(sentence), #sentence)
			return nil
		--end
	end
	return sentence
end

--Formeln als String
--Klauseln als {P11, -G22, W34}	Disjunktion von Literalen
--Hornformeln als {P=>Q},{L=>-P} oder {A}
function MakeQuery(whatQuery,x,y)
	if y then
		return {trueFalse(false)..tostring(whatQuery)..tostring(x)..HashDelim..tostring(y)}	--{{a,b},{c}} = {a or b} and c
	else																								--hier verwenden ich nur {{+-#xy}}
		return {trueFalse(false)..tostring(whatQuery)..tostring(x)}	--falls die Koordinaten als string ¸bergeben wurden
	end
end

function MakePerceptSentence(truepercept,whatpercept,x,y)
	if y then
		return {trueFalse(truepercept)..tostring(whatpercept)..tostring(x)..HashDelim..tostring(y)}	--{{a,b},{c}} = {a or b} and c
	else																								--hier verwenden ich nur {{+-#xy}}
		return {trueFalse(truepercept)..tostring(whatpercept)..tostring(x)}	--falls die Koordinaten als string ¸bergeben wurden
	end
end


















function newKB(pos, dir)
--zust‰nde sind true, false oder nil
	local newInference={}
	local newFC={}
	KB["C"]=pos		--CurrentRoom
	KB["Direction"]=dir	--BlickRichtung
	KB["wumpus"]=true	--existiert Wumpus

	--Regeln ({a,b} entspr‰che (a or b))
	for _,v in pairs({{"b","P"},{"s","W"}}) do
		for x=1,xmax do
			for y=1,ymax do
				--Mitte
				if x~=1 and x~=xmax and y~=1 and y~=ymax then
					table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
					table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
					table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
					table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})

					table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x-1).."::"..y,v[2]..(x+1).."::"..y,v[2]..x.."::"..(y-1),v[2]..x.."::"..(y+1)})
					table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
					table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
					table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
					table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})
				else
					--Ecke
					if x==1 and y==1 then
						table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
						table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})

						table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x+1).."::"..y,v[2]..x.."::"..(y+1)})
						table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
						table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})
					elseif x==xmax and y==ymax then
						table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
						table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})

						table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x-1).."::"..y,v[2]..x.."::"..(y-1)})
						table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
						table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
					elseif x==1 and y==ymax then
						table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
						table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})

						table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x+1).."::"..y,v[2]..x.."::"..(y-1)})
						table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
						table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
					elseif x==xmax and y==1 then
						table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
						table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})

						table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x-1).."::"..y,v[2]..x.."::"..(y+1)})
						table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
						table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})
					else
						--keine Ecke und nicht innen
						if x==1 then
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})

							table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x+1).."::"..y,v[2]..x.."::"..(y-1),v[2]..x.."::"..(y+1)})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})
						end
						if x==xmax then
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})

							table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x-1).."::"..y,v[2]..x.."::"..(y-1),v[2]..x.."::"..(y+1)})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})
						end
						if y==1 then
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})

							table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x-1).."::"..y,v[2]..(x+1).."::"..y,v[2]..x.."::"..(y+1)})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y+1)})
						end
						if y==ymax then
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
							table.insert(newFC, {"-"..v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})

							table.insert(newInference, {"-"..v[1]..x.."::"..y,v[2]..(x-1).."::"..y,v[2]..(x+1).."::"..y,v[2]..x.."::"..(y-1)})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x-1).."::"..y})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..(x+1).."::"..y})
							table.insert(newInference, {v[1]..x.."::"..y,"-"..v[2]..x.."::"..(y-1)})
						end
					end
				end
			end
		end
	end

	KB["i"]=newInference
	KB["f"]=newFC

	insertToKB(MakePerceptSentence(false,"P",pos))	--Pit=Loch
	insertToKB(MakePerceptSentence(false,"W",pos))	--Wumpus
	--newInference=insertToKB(newInference, MakePerceptSentence(false,"G",pos))	--Gold
	--newInference=insertToKB(newInference, MakePerceptSentence(true, "E",pos))	--Exit=Ausgang

	--[[for x=1,xmax do
		for y=1,ymax do
			if pos~=tostring(x)..HashDelim..tostring(y) then
				newInference=insertToKB(newInference, MakePerceptSentence(false,"E",x,y))
			end
		end
	end
	--]]

	return newInference
end

--einf¸gen ohne doppelte und filtern der negierten aussagen aus allen Vorhandenne
function insertToKB(sentence)
	local negsentence = negate(sentence)
	--print("")
	--print(TableToString(sentence), "einzuf¸gen", TableToString(negsentence))
	local KBnew = {}
	KBnew["i"]={}
	KBnew["f"]={}

	--print("a1", TableToString(KB))
	--print("b1", TableToString(KBnew))
	--pr¸fen ob zu lˆschen oder zu ignorieren ist
	for i,v in pairs(KB.i) do
		--gleiches?
		if equal(v,{}) then
			print("oben ist {} enthalten")
		end

		if equal(v,sentence) then
			--print("equal")
		--enth‰lt negiertes wird voriger Inhalt entfernt
		elseif negsentence~=nil and equal(negsentence,v)==true then
			--print("-equal")
		elseif negsentence~=nil and teilmengeGleich(negsentence,v)==true then
			--print("negiert teilmenge")
			--lˆsche negiertes aus v
			for i2,v2 in pairs(v) do
				if equal(v2,negsentence[1]) then
					table.remove(v,i2)
				end
			end
			table.insert(KBnew.i,v)
		elseif teilmengeGleich(sentence,v)==true then
			--print("teilmenge")
			--lˆsche alles Andere aus v
			for i2,v2 in pairs(v) do
				if not equal(v2,sentence[1]) then
					--print("remove",v2,TableToString(v2))
					table.remove(v,i2)
				end
			end
			table.insert(KBnew.i,v)
		else
			table.insert(KBnew.i,v)
		end
	end
--]]
	--print("a2", TableToString(KB))
	--print("b2", TableToString(KBnew))
	for i,v in pairs(KB.f) do
		--table.insert(KBnew.f,v)


		--gleiches?

		if equal(v,{}) then
			print("unten ist {} enthalten")
		end

		if equal(v,sentence) then
			--print("equal")
		elseif negsentence~=nil and equal(praemisse(v),negsentence) then
			--print("-equal")
		elseif equal({v[#v]},sentence) then
			--print("2nd")
		elseif negsentence~=nil and equal({v[#v]},negsentence) then
			--print("-2nd")
		elseif equal(praemisse(v),sentence) then
		--einf¸gen des satzes und der Folgerung
			--print("conclusion")
			--if equal({v[#v]},{}) then
			--	print("o", TableToString(sentence),TableToString(v),TableToString(v[1]),TableToString(v[2]), "leer eingef¸gt")
			--end
			table.insert(KBnew.f,{v[#v]})
		--enth‰lt negiertes wird voriger Inhalt entfernt
		else
			--print("else")
			--if equal(v,{}) then
			--	print("u",TableToString(sentence),TableToString(v),TableToString(v[1]),TableToString(v[2]), "leer eingef¸gt")
			--end
			table.insert(KBnew.f,v)
		end
	end
	--print("a3", TableToString(KB))
	--print("b3", TableToString(KBnew))

	KB.i=nil
	KB.f=nil
	for i,v in pairs(KB) do
		KBnew[i]=v
	end
	table.insert(KBnew.i,copyTable(sentence))
	table.insert(KBnew.f,copyTable(sentence))
	KB=KBnew
end


--Auf t nehme ich alpha wahr
function TELL(alpha,t)
	--tabelle vordefinieren mit allem was in die KB aufgenommen werden kˆnnte
	local buffertable = {}

	if state~="lost" then
		if KB["wumpus"]==true then
			table.insert(buffertable, MakePerceptSentence(false,"W",t))	--Wumpus
			table.insert(buffertable, MakePerceptSentence(alpha.Stench ,"s",t))
		end
		table.insert(buffertable, MakePerceptSentence(false,"P",t))	--Pit

		table.insert(buffertable, MakePerceptSentence(alpha.Breeze ,"b",t))
		--table.insert(buffertable, MakePerceptSentence(alpha.Glitter,"g",t))
		--if alpha.Bump then
		--	table.insert(buffertable, MakePerceptSentence(alpha.Bump   ,"u",t))
		--end
	end

	--Bei Scream wird Wumpus und stench entfernt
	if alpha.Scream and KB["wumpus"]==true then
		KB["wumpus"]=false
		for x=1,xmax do
			for y=1,ymax do
				table.insert(buffertable, MakePerceptSentence(false ,"W",x,y))
				table.insert(buffertable, MakePerceptSentence(false ,"s",x,y))
			end
		end
	end


	for _,v in pairs(buffertable) do
		--print(TableToString(v), #KB, TableToString(KB))
		insertToKB(copyTable(v))
	end
end

--Folgt sentence aus der KB?
function ASK(sentence)
	KB.i = clean(KB.i)
	KB.f = clean(KB.f)
	--print(#KB, TableToString(KB))
	PLResolution(sentence)
	PL_FC_Entails(sentence)
	print("")
end







----------------------------------------------------------------------------
----------------------Forward-Chainingalgorithmus--------------------------
----------------------------------------------------------------------------
function ClauseToString(clause)
	if type(clause)=="table" then
		local string = ""
		for _,v in pairs(clause) do
			string = string .. ClauseToString(v)
		end
		return string
	else
		return clause
	end
end

function praemisse(clause)
	local ret = copyTable(clause)
	ret[#ret]=nil
	return ret
end

function PL_FC_Entails(sentence)
	local q = sentence[1]		--string erzeugen
	local count = {}			--Anzahl der elemente in der Pr‰misse der Hornklausel
	local inferred = {}		--Bitmap ob element schon genutzt wurde
	local agenda = Queue.new()	--Alle Fakten

	for i,v in pairs(KB.f) do
		count[ClauseToString(v)]=#v-1
		inferred[ClauseToString(v)]=false

		if #v==1 then	--Fakten
			agenda:push(copyTable(v[1]))
		end
	end

	--print(TableToString(agenda))

	while #agenda~=0 do
		local p = agenda:pop()
		if equal(p,q) then
			print("FChain", TableToString(sentence), "wurde best‰tigt")
			return true
		end

		if inferred[ClauseToString(p)] == false then
			inferred[ClauseToString(p)] = true
			for _,c in pairs(KB.f) do
				if #c>1 and teilmengeGleich({p},praemisse(c)) then --alle Regeln mit p in der Pr‰misse
					count[ClauseToString(c)]=count[ClauseToString(c)]-1
					if count[ClauseToString(c)]==0 then
						agenda:push(copyTable(c[#c]))
					end
				end
			end
		end
	end

	print("FChain", TableToString(sentence), "konnte nicht best‰tigt werden")
	return false
end

----------------------------------------------------------------------------
-------------------------Resolutionsalgorithmus-----------------------------
----------------------------------------------------------------------------

function PLResolution(alpha)
	--print("PLResolution ",KB,#KB,alpha[1])
	local clauses = copyTable(KB.i)
	table.insert(clauses, negate(alpha))

	local abort=false
	repeat
		local new = {}	--gefundenen neuen s‰tze
		for i1,ci in pairs(clauses) do
			for i2,cj in pairs(clauses) do
				if i1<i2 then
					--print("PLResolution",i1,i2,TableToString(ci),TableToString(cj),#new)
					local resolvent = PLResolve(ci,cj)
					if equal({},resolvent)==true then
						print("PLResolution", TableToString(alpha), "wurde best‰tigt")
						return true
					end
					new=union({resolvent}, new)
				end
			end
		end

		--print("PLResolution", TableToString(new), TableToString(clauses))
		local old=#clauses
		clauses = union(new ,clauses)
		--print("o, #c",old,#clauses)
	until old==#clauses

	print("PLResolution", TableToString(alpha), "konnte nicht best‰tigt werden")
	return false
end

function PLResolve(s1,s2)
--hier sollten die formeln analysiert und mit "und" verkn¸pft werden

-- {"A","B"},{" A","-B"} => {"A"}
-- {"A","B"},{"-A","-B"} => nil
-- {"A"},{"B"} => nil

-- {"A"},{"-A"} => {}
	--print("PLResolve in",TableToString(s1),TableToString(s2))
	local zuruck = {}
	local buff = negate(s1)
	if buff~=nil then
		if equal(s2,buff) then
			--print("PLResolve out",TableToString(s1),TableToString(s2),TableToString(zuruck))
			return zuruck
		end
	end

	--alles vereinigen
	local s3 = union(s1,s2)

	--kreuzprodukt
	local negbeide = false
	local beide = false
	local indexe = {}

	--for i=1,#s3 do

	--	for ii=i+1, #s3 do
	s3=clean(s3)
	for i,v in pairs(s3) do
		for ii,vv in pairs(s3) do
			if i<ii then
				--if equal(v,vv) then
				--	beide = true
				--	indexe[i]=true 		--w¸rde nochmals vorkommen, also wird i ¸bersprungen
				--	break
				--else
				if negate(vv)~=nil then
					if equal(vv,negate(vv)) then
						negbeide=true	--negbeide heiﬂt es kommt negiert nochmal vor. es wird davon ausgegangen, dass die ‹bergabemengen paarweise verschieden sind
						indexe[i]=true
						indexe[ii]=true
					end
				end
			end
		end

		if indexe[i]~=true then
			table.insert(zuruck, copyTable(v))
		end
		--print("PLResolve schritt",i,TableToString(s3),TableToString(zuruck))
	end

	if #zuruck==0 or (negbeide==false and beide==false) then
		zuruck = nil		--tautologie
	end
	--print("PLResolve out",TableToString(s1),TableToString(s2),TableToString(s3),TableToString(zuruck))

	return zuruck
end






----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

--Spielerstartposition
local sx=1
local sy=1
local direction = ">"


local spiel  = new_game(new_player(sx,sy,direction,xmax,ymax),new_cave(xmax,ymax,sx,sy,direction,{{2  ,2  },{3  ,4  }},3 ,1 ,2 ,4 ))
local rspiel = new_randomgame(new_player(sx,sy,direction,xmax,ymax),0.1)

newKB(tostring(sx) .. HashDelim .. tostring(sy), direction)

getInputsKB(spiel)

--fsff lfff llff rfr flfr fglf lffl
