-- converts a table to a string. Good for debugging purposes
function TableToString(array)
	if (array == nil or type(array) ~= "table") then
		return nil;
	end
	local str = "{";
	for index,value in pairs(array) do
		-- handle indices
		if (type(index) == "number") then
			index = "";
		else
			if (type(index) == "boolean") then
				if (index) then
					index = "true"
				else
					index = "false"
				end
			end
			index = index.."=";
		end
		-- add quotation marks if value is a string
		if (type(value) == "string") then
			value = "\""..value.."\"";
		--elseif (type(value) == "boolean") then
		--	value =
		end
		-- add seperator if needed
		if (str ~= "" and string.sub(str, -1) ~= "{") then
			str = str..",";
		end
		-- handle subtables and append value to string
		if (type(value) == "table") then
			str = str..index..TableToString(value);
		else
			str = str..index..tostring(value);
		end
	end
	return str.."}";
end
