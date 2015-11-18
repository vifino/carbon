-- Tags
local html_escape = {
	["<"]="&lt;",
	[">"]="&gt;",
	["&"]="&amp;"
}

local function uri_escape(a)
	return ("%%%02x"):format(a:byte())
end

local function uri_unescape(a)
	return string.char(tonumber(a,16))
end

escape = {
	html = function(str)
		return (str:gsub("[<>&]", html_escape))
	end,
	url = function(str)
		return (str:gsub("[^a-zA-Z0-9_.~-]", uri_escape))
	end,
	shell = function(str)
		return (str:gsub("[%s`~!#$&*()|\\'\";<>?{}[%]^]", "\\%1"))
	end
}

unescape = {
	url = function(str)
		return (str:gsub("+", " "):gsub("%%(%x%x)", uri_unescape))
	end
}

-- tag metatable
local tagmeth = {
	render = function(self)
		local content
		if self.content then
			content = {}
			for i, v in ipairs(self.content) do
				if type(v) == "string" then
					content[i] = v
				elseif type(v) == "number" then
					content[i] = tostring(v)
				else
					content[i] = v:render()
				end
			end
		end
		local options
		if self.options and next(self.options) then
			options = {}
			for k, v in pairs(self.options) do
				if type(k) == "number" then
					table.insert(options, tostring(v))
				else
					table.insert(options,k .. "=\"" .. tostring(v):gsub("\"", "&quot;") .. "\"")
				end
			end
		end
		if self.fclose then
			if content then
				return table.concat(content) .. "</" .. self.name .. ">"
			end
			return "</" .. self.name .. ">"
		elseif self.fopen then
			local result
			if options then
				result = "<" .. self.name .. " " .. table.concat(options, " ") .. ">"
			else
				result = "<" .. self.name .. ">"
			end
			if content then
				return result .. table.concat(content)
			end
			return result
		else
			local result
			if options then
				result = "<" .. self.name .. " " .. table.concat(options, " ")
			else
				result = "<" .. self.name
			end
			if content then
				return result .. ">" .. table.concat(content) .. "</" .. self.name .. ">"
			end
			return result .. " />"
		end
	end,
	add_content = function(self, ...)
		if not self.content then
			self.content = {}
		end
		for i = 1, select('#', ...) do
			local value = select(i, ...)
			if type(value) == "string" then
				if #value ~= 0 then
					table.insert(self.content, escape.html(value))
				end
			else
				table.insert(self.content, value)
			end
		end
		return self
	end,
	force_content = function(self, ...)
		if not self.content then
			self.content = {}
		end
		for i = 1, select('#', ...) do
			local value = select(i, ...)
			if type(value) == "string" then
				if #value ~= 0 then
					table.insert(self.content, value)
				end
			else
				table.insert(self.content, value)
			end
		end
		return self
	end,
	add_options = function(self, tbl)
		if not self.options then
			self.options = {}
		end
		for k, v in pairs(tbl) do
			if type(k) == "number" then
				table.insert(self.options, v)
			else
				self.options[k] = v
			end
		end
		return self
	end,
	clear_content = function(self)
		self.content = nil
		return self
	end,
	clear_options = function(self)
		self.options = nil
		return self
	end,
	set_content = function(self, ...)
		self:clear_content()
		return self:add_content(...)
	end,
	set_options = function(self, tbl)
		self:clear_options()
		return self:add_options(tbl)
	end,
	force_open = function(self)
		self.fopen = true
		return self
	end,
	force_close = function(self)
		self.fclose = true
		return true
	end
}

local tagmt = {
	__index = function(self, k)
		if type(k) == "table" then
			return self:add_options(k)
		else
			return tagmeth[k]
		end
	end,
	__call = tagmeth.add_content
}

function tag(name)
	return setmetatable({name = name}, tagmt)
end