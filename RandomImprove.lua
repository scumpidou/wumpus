-- optimize random number generator
math.randomseed(os.time());
local oldrandom = math.random;
local randomtable;
math.random = function (k, j)
	if randomtable == nil then
		randomtable = {}
		for i = 1, 97 do
			randomtable[i] = oldrandom()
		end
	end
	local x = oldrandom();
	local i = 1 + math.floor(97*x);
	x, randomtable[i] = randomtable[i], x
	if (k == nil or j == nil) then
		return x;
	else
		return math.floor(k+(x*(j-k+1)));
	end
end
for i=0,100 do
	math.randomseed(math.random());
end
