dofile("Class.lua");

Queue = {};
local Queue_mt = Class(Queue);


--[[function Queue:new(_, init)
	-- check whether init would be a valid Queue_mt


	return setmetatable(init or {}, Queue_mt);
end
--]]

function Queue:push(value)
	assert((getmetatable(self) == Queue), "object is no member of Queue");
	assert((value ~= nil), "cannot add nil value to queue");

	table.insert(self, value);
end

function Queue:pop()
	assert((getmetatable(self) == Queue), "object is no member of Queue");
	if (#self == 0) then
		return nil;
	else
		return table.remove(self, 1);
	end
end

--[[ testing
local p = Queue.new();

p:push("Alice");
p:push("Bob");
p:push("Eve");
print (p:pop());
print (p:pop());
p:push("Karl");
print (p:pop());
print (p:pop());
print (p:pop());
--]]
