local Form = {}

-- Split but with iterator and handle backslash escapes
local function esplit(s, c)
	local i = 1;
	return function()
		local b = i
		local e = s:find(c, i, true)
		while e do
			if s:sub(e - 1, e - 1) ~= "\\" then
				i = e + 1
				return s:sub(b, e - 1)
			end
			i = i + e
			e = s:find(c, i, true)
		end
		if i < #s then
			b, i = i, #s
			return s:sub(b)
		end
	end
end

-- Process certain well known element definition values
local function process_value(index, value)
	if index < 3 then
		local num = esplit(value, ",")
		return {tonumber(num() or nil), tonumber(num() or nil)}
	elseif  index > 5 then
		-- FIXME: Also process not so well known values... probably very wrong
		return value:split(",")
	end
	return value
end

-- Like ipairs but just value without index
local function ivalues(t)
	local index, max = 0, #t
	return function()
		index = index + 1
		if index <= max then
			return t[index]
		end
	end
end

-- Swap and process things, see fs_elements below
local function swapper(...)
	local args = {...}
	return function(input)
		local iterator, result
		if type(input) == "string" then
			-- create new table when input is string
			iterator, result = esplit(input, ";"), {}
		else
			-- process in place when input is table
			iterator, result = ivalues(input), input
		end
		local i = 1
		for value in iterator do
			while args[i] == 0 do
				table.insert(result, false)
				i = i + 1
			end
			local index = args[i] or i
			result[index] = process_value(index, value)
			i = i + 1
		end
		return result
	end
end

-- Elements to parse, for unlisted/commented only type names will be added and parameters are completely skipped.
-- Output fields: x/y, w/h, name, value, tbd
-- After exhausting arguments, swapper continues in order. This means that contiguous indexes can be omitted.
-- TODO: Allow negative (backwards) indices for swapper.
local fs_elements = {
	--container = 1,
	--container_end = 1,
	--list = 1,
	--listring = 1,
	checkbox = swapper(1, 0, 2, 4, 3),
	--image = 1,
	--animated_image = 1,
	--item_image = 1,
	button = swapper(),
	button_exit = swapper(),
	button_url = swapper(),
	button_url_exit = swapper(),
	--background = 1,
	--background9 = 1,
	--tableoptions = 1,
	--tablecolumns = 1,
	--table = 1,
	textlist = swapper(),
	dropdown = swapper(),
	--field_enter_after_edit = 1,
	--field_close_on_enter = 1,
	pwdfield = swapper(),
	field = (function()
		local s1 = swapper(1, 2, 3, 5, 4)
		local s2 = swapper(0, 0, 1, 3, 2)
		return function(s)
			local t = s:split(";")
			return #t > 3 and s1(t) or s2(t)
		end
	end)(),
	textarea = swapper(1, 2, 3, 5, 4),
	--hypertext = 1,
	--label = 1,
	--vertlabel = 1,
	item_image_button = swapper(1, 2, 5, 3, 4),
	image_button = swapper(1, 2, 5, 3, 4),
	image_button_exit = swapper(1, 2, 5, 3, 4),
	--tabheader = 1,
	--box = 1,
	--bgcolor = 1,
	--listcolors = 1,
	--tooltip = 1,
	--scrollbar = 1,
	--real_coordinates = 1,
	--style = 1,
	--style_type = 1,
	--scrollbaroptions = 1,
	--scroll_container = 1,
	--scroll_container_end = 1,
	--set_focus = 1,
	--model = 1,
}

local Element = {}
Element.__index = Element

function Element:type()
	return assert(self._type)
end

function Element:pos()
	return self._data[1] or {}
end

function Element:size()
	return  self._data[2] or {}
end

function Element:name()
	return self._data[3] or ""
end

function Element:value(data)
	if data ~= nil then
		assert.is_string(data, "Form: Element:value(data) unexpected data, expected string but got "..type(data))
		self._data[4] = data
	end
	return self._data[4] or ""
end

function Element:__tostring()
	return ("Element<%s>(%s, %s)"):format(self:type(), self:name(), self:value())
end

-- Parse formspec and return parsed form elements.
local function parse(formspec)
	local results = {}
	for es in esplit(formspec, "]") do
		local i = es:find("[", 1, true)
		local element = setmetatable({ _type = es:sub(1, i - 1) }, Element)
		if fs_elements[element._type] then
			table.insert(results, element)
			results[#results]._data = fs_elements[element._type](es:sub(i + 1))
		--else
		--	results[#results]._data = es:sub(i + 1):trim()
		end
	end
	return results
end

-- Find form elements based on name and/or type patterns. Returns iterator.
function Form:find(namepattern, typepattern)
	local index = 0
	if namepattern and typepattern then
		-- Match both typepattern and namepattern
		return function()
			while index < #self._data do
				index = index + 1
				local e = self._data[index]
				if e:type():find(typepattern) and e:name():find(namepattern) then
					return e
				end
			end
		end
	elseif namepattern then
		-- Match only namepattern
		return function()
			while index < #self._data do
				index = index + 1
				local e = self._data[index]
				if e:name():find(namepattern) then
					return e
				end
			end
		end
	elseif typepattern then
		-- Match only typepattern
		return function()
			while index < #self._data do
				index = index + 1
				local e = self._data[index]
				if e:type():find(typepattern) then
					return e
				end
			end
		end
	else
		error("Invalid arguments Form:find(<falsy>, <falsy>)")
	end
end

-- Get first matching form element
function Form:one(namepattern, typepattern)
	return self:find(namepattern, typepattern)()
end

-- Get all matching form elements
function Form:all(namepattern, typepattern)
	local results = {}
	for e in self:find(namepattern, typepattern) do
		table.insert(results, e)
	end
	return results
end

local submit_fields = {
	animated_image = 1, -- Returns the index of the current frame.
	button = 1, -- button and variants contains the button text as value. If not pressed, is `nil`.
	image_button = 1,
	image_button = 1,
	item_image_button = 1,
	button_exit = 1,
	image_button_exit = 1,
	button_url = 1,
	button_url_exit = 1,

	pwdfield = 1, -- field, textarea and variants contains text in the field.
	field = 1,
	--field_enter_after_edit = 1, -- Experimental
	--field_close_on_enter = 1, -- If false, pressing Enter in field submits form without closing. Default true.
	textarea = 1,
	--hypertext = 1, -- Unstable + check spec

	dropdown = 1, -- Either the index or value, depending on the `index event` dropdown argument.
	tabheader = 1, -- Tab index, starting with `"1"` (only if tab changed).
	checkbox = 1, -- "true" if checked, "false" if unchecked.
	textlist = 1, -- See `core.explode_textlist_event`.
	table = 1, -- See `core.explode_table_event`.
	scrollbar = 1, -- See `core.explode_scrollbar_event`.
	-- quit = "true" if user closed the form by mouse click, keypress or through a button_exit[] element.
	-- key_enter = "true"` if user pressed Enter and focus was nowhere (formspec closed) or on a button.
	--   If text field was focused, `key_enter_field` contains the name of the field. See: `field_close_on_enter`
}

-- Get fields that would be submitted with any of the basic submit actions.
-- TODO: Allow specifying trigger, like button or scrollbar for example, and return fields based on action.
-- FIXME: Currently results will be wrong: includes everything like buttons that shouldn't be there.
function Form:fields()
	mineunit:error("Form:fields() is experimental and UNSTABLE. Its behavior and interface WILL BE CHANGED.")
	local results = {}
	for e in ivalues(self._data) do
		if submit_fields[e:type()] and e:name() ~= "" then
			results[e:name()] = e:value()
		end
	end
	return results
end

-- Get or set form field value by field name, will not edit formspec text content
function Form:value(name, data)
	local e = self:one("^"..name.."$", nil)
	mineunit:debugf("Form:value(%s, %s) Field: %s", name, data, e)
	if e then
		return e:value(data)
	end
	mineunit:errorf("Form<%s>:value(%s, %s) failed, could nto find valid element.", self._name, name, data)
end

function Form:data()
	return self._data
end

function Form:text()
	return self._textcontent
end

function Form:name()
	return self._name
end

function Form:version()
	error("Not implemented: Form:version()")
end

function Form:__tostring()
	return self._textcontent
end

mineunit.export_object(Form, {
	name = "Form",
	private = true,
	constructor = function(self, formname, formspec)
		mineunit:debugf("Form(%s, ...) -> new form.", formname)
		local obj = {
			_name = formname,
			_version = nil,
			-- TODO: determine if deferred parse makes any sense
			_data = parse(formspec),
			_textcontent = formspec,
		}
		setmetatable(obj, Form)
		return obj
	end,
})

function mineunit:Form(formname, formspec)
	return Form(formname, formspec)
end