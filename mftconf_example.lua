-- mftconf lib example

-- require mftconf library
mftconf = require("mftconf/lib/mftconf")

function init()
  -- connect your midi fighter twister in your script:
  -- mft = midi.connect(your_midi_figther_twister)
  
  -- call this function to load midi fighter twister configuration file
  -- params: midi device, config file with path:
  -- mftconf.load_conf(mft,"PATH/mft_config_file.mfs")
  
  redraw()
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.move(0,11)
  screen.text("check source code")
  screen.move(0,18)
  screen.text("for instructions")
  screen.update()
end
