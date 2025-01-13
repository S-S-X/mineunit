-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit formspec", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	sourcefile("core")
	sourcefile("server")
	sourcefile("player")
	sourcefile("formspec")

	local SX = Player("SX")

	describe("register_on_player_receive_fields", function()

		local test_called = 0
		local test_formname = "test:formname"
		function test_callback(player, formname, fields)
			assert.is_Player(player)
			assert.not_nil(formname)
			assert.equals(formname, test_formname)
			assert.same({a = 1, b = 2}, fields)
			test_called = test_called + 1
		end

		before_each(function() test_called = 0 end)

		it("registers callback", function()
			core.register_on_player_receive_fields(test_callback)
			assert.in_array(test_callback, core.registered_on_player_receive_fields)
		end)

		it("executes callback", function()
			--core.register_on_player_receive_fields(test_callback)
			assert.equals(0, test_called)
			mineunit:execute_on_player_receive_fields(SX, test_formname, { a = 1, b = 2 })
			assert.equals(1, test_called)
		end)

	end)

	describe("Mineunit:Form", function()

		local test_formspec = ([[formspec_version[3]size[8.000,11.500;]
			bgcolor[#FFC00F;both;]
			style_type[*;textcolor=#101010;font_size=*1]
			style_type[table;textcolor=#101010;font_size=*1;font=mono]
			style_type[label;textcolor=#101010;font_size=*2]
			background9[0,0;8.000,11.500;technic_multimeter_bg.png;false;3]
			image[0.3,0.3;5.75,1;technic_multimeter_logo.png]
			label[0.6,1.5;Network 1DVYWBCXKX]
			field[2.733,2.5;2.533,0.8;net;Network ID:;1DVYWBCXKX]
			image_button[5.367,2.5;2.533,0.8;technic_multimeter_button.png^\[colorize:#10E010:125;
				rs;Remote start;false;false;technic_multimeter_button_pressed.png^\[colorize:#10E010:125]
			image_button_exit[0.100,10.600;2.533,0.8;technic_multimeter_button.png;
				wp;Waypoint;false;false;technic_multimeter_button_pressed.png]
			image_button[2.733,10.600;2.533,0.8;technic_multimeter_button.png;
				up;Update;false;false;technic_multimeter_button_pressed.png]
			image_button_exit[5.367,10.600;2.533,0.8;technic_multimeter_button.png;
				exit;Exit;false;false;technic_multimeter_button_pressed.png]
			tableoptions[border=false;background=#4B8E66;highlight=#5CAA77;color=#101010]
			tablecolumns[indent,width=0.2;text,width=13;text,width=13;text,align=center]
			table[0.1,3.4;7.800,7.100;items;
				1,Property,Value,Unit,
				1,Ref. point,1\,50\,0,coord,
				1,Activated,yes,active,
				1,Timeout,1800.0,s,
				1,Lag,0.30,ms,
				1,Skip,0,cycles,
				1,-,-,-,
				1,Supply,45000,EU,
				1,Demand,0,EU,
				1,Battery charge,1000000,EU,
				1,Battery charge,100,%,
				1,Battery capacity,1000000,EU,
				1,-,-,-,
				1,Nodes,21,count,
				1,Cables,11,count,
				1,Generators,9,count,
				1,Consumers,0,count,
				1,Batteries,
				1,count]
		]]):gsub("[\r\n]\t\t\t*", "")

		it("parses formspecs", function()
			local form = mineunit:Form("test:formname", test_formspec)
			assert.is_Form(form)

			assert.equals(form:name(), "test:formname")
			assert.is_table(form:data())

			local btn_exit = form:one("ex", "image_button_exit")
			local btn_wp = form:one("w", "image_button_exit")

			assert.equals(btn_exit:name(), "exit")
			assert.same({5.367,10.600}, btn_exit:pos())

			assert.equals(btn_wp:name(), "wp")
			assert.same({0.100,10.600}, btn_wp:pos())

			assert.equals(4, #form:all(nil, "image_button"))
			assert.equals(2, #form:all(nil, "image_button$"))
			assert.equals(0, #form:all(nil, "^button_exit"))

			assert.equals(2, #form:all("p", nil))
		end)

		it("provides fields table", function()
			local form = mineunit:Form("test:formname", test_formspec)
			assert.is_table(form:fields())
		end)

	end)

end)
