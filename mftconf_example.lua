-- mftconf example

package.loaded["mftconf/lib/mftconf"] = nil
mftconf = require("mftconf/lib/mftconf")
PATH = _path.data.."mft_config/"

function init()
  mft = midi.connect(2)
end

function key(n,z)
  if z == 1 and n == 2 then
    mftconf.load_conf(mft,PATH.."mft_passersby.mfs")
  end
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.move(0,11)
  screen.text("give midi device &")
  screen.move(0,18)
  screen.text("filename as params")
  screen.move(0,32)
  screen.text("press k2 to load config")
  screen.update()
end
