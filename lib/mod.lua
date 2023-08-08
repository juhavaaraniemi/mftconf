-- mftconf mod

-- libraries
local mod = require "core/mods"
local mftconf = require("mftconf/lib/mftconf")

-- variables
local selected_file = "none"
local PATH = _path.data.."mftconf/"
local selected_device = "none"
local midi_device = {}
local conf_files = {}
local file_index = 1
local device_index = 1

-- mod menu
local m = {}

m.key = function(n, z)
  if n == 2 and z == 1 then
    mod.menu.exit()
  elseif n == 3 and z == 1 then
    mftconf.load_conf(midi_device[device_index],PATH..selected_file)
  end
  mod.menu.redraw()
end

m.enc = function(n, d)
  if n == 3 then
    file_index = util.clamp(file_index+d,1,#conf_files)
    selected_file = conf_files[file_index]
  end
  mod.menu.redraw()
end

m.redraw = function()
  screen.clear()
  screen.move(5,10)
  screen.text("mft conf file:")
  screen.move(5,20)
  screen.text(selected_file)
  screen.move(5,40)
  screen.text("e3 to select file")
  screen.move(5,50)
  screen.text("k3 to load conf")
  screen.update()
end

m.init = function()
  -- read midi devices
  for i = 1,#midi.vports do -- query all ports
    midi_device[i] = midi.connect(i) -- connect each device
    if midi_device[i].name == "Midi Fighter Twister" then
      selected_device = i.." ".. midi_device[i].name
      device_index = i
    end
  end
  
  -- read conf files
  conf_files = util.scandir(PATH)
end

m.deinit = function() end

mod.menu.register(mod.this_name, m)
