-- midi fighter twister
-- config loader lib
-- v0.5 @JulesV

-- SYSEX BYTES FOR ENCODERS
-- 0x00   start byte
-- 0x01   encoder number
-- 0x01   ?
-- 0x00   ?
-- 0x1E   # of bytes in conf 
-- 0x0A   tag: detent
-- 0x0B   tag: encoder movement mode
-- 0x0C   tag: switch action type
-- 0x0D   tag: switch midi channel
-- 0x0E   tag: switch midi number
-- 0x0F   tag: switch midi type
-- 0x10   tag: encoder midi channel
-- 0x11   tag: encoder midi number
-- 0x12   tag: encoder midi type
-- 0x13   tag: active color
-- 0x14   tag: inactive color
-- 0x15   tag: detent color
-- 0x16   tag: indicator display type
-- 0x17   tag: is super knob
-- 0x18   tag: encoder shift midi channel 
--
-- SYSEX BYTES FOR GLOBAL
-- 0x00   start byte
-- 0x36   # of bytes in conf 
-- 0x00   tag: system midi channel
-- 0x01   tag: bank side buttons
-- 0x02   tag: left button 1 function
-- 0x03   tag: left button 2 function
-- 0x04   tag: left button 3 function
-- 0x05   tag: right button 1 function
-- 0x06   tag: right button 2 function
-- 0x07   tag: right button 3 function
-- 0x08   tag: global super knob start point
-- 0x09   tag: global super knob end point
-- 0x1F   tag: global rgb brightness
-- 0x20   tag: global indicator brightness


local mftconf = {}

local conf = {}
local packet0 = {}
local packet1 = {}
local packet2 = {}
local data1 = {}
local data2 = {}

--
-- FILE READ
--
local function read_file(filename)
  local hex_table = {}
  local f = io.open(filename, "r")
  local block = 10
  local command = 1
  while true do
    local bytes = f:read(block)
    if not bytes then break end
    for b in string.gmatch(bytes, ".") do
      hex = "0x"..string.format("%02X", string.byte(b))
      table.insert(hex_table,hex)
    end
  end
  print(filename.." midi fighter twister conf file read succesfully!")
  return hex_table
end


--
-- CONFIG PARSE
--
local function parse_mft_conf(sysex_table)
  local cur_byte = ""
  local prev1_byte = ""
  local prev2_byte = ""
  local prev3_byte = ""
  local enc = 1
  
  for i,v in ipairs(sysex_table) do
    cur_byte = sysex_table[i]
    if cur_byte == "0x36" and prev1_byte == "0x00" and prev2_byte == ""  then
      table.remove(sysex_table,i)
      table.remove(sysex_table,i-1)
      table.insert(sysex_table,i-1,"global")      
    elseif cur_byte == "0x00" and prev1_byte == "0x01" and prev2_byte == ("0x"..string.format("%02X",enc)) and prev3_byte == "0x00" then
      table.remove(sysex_table,i)
      table.remove(sysex_table,i-1)
      table.remove(sysex_table,i-2)
      table.remove(sysex_table,i-3)
      table.insert(sysex_table,i-3,"encoder")
      table.remove(sysex_table,i-2)
      enc = enc + 1
    end
    prev3_byte = prev2_byte
    prev2_byte = prev1_byte
    prev1_byte = cur_byte
  end

  local id = 1 --id 0 for global settings, 1-64 for encoder settings
  
  for i,v in ipairs(sysex_table) do
    cur_byte = sysex_table[i]
    if cur_byte == "global" then
      conf[0] = {}
    elseif cur_byte == "encoder" then
      conf[id] = {}
      id = id + 1
    else
      table.insert(conf[id-1],cur_byte)
    end
  end
end


--
-- HELPER FUNCTIONS
--
local function table_concat(t1,t2)
   for i=1,#t2 do
      t1[#t1+1] = t2[i]
   end
   return t1
end

--
-- BUILD SYSEX PACKETS FOR LOADER
--
local function build_enc_sysex_packet(enc)
  data1 = {}
  data2 = {}
  packet1 = {}
  packet2 = {}
  local count1 = 0
  local count2 = 0
  for i,v in ipairs(conf[enc]) do
    if i < 25 then
      table.insert(data1,v)
      count1 = count1 + 1
    else
      table.insert(data2,v)
      count2 = count2 + 1
    end
  end

  packet1 = {"0xF0","0x00","0x01","0x79","0x04","0x00"}
  table.insert(packet1,("0x"..string.format("%02X",enc)))
  table.insert(packet1,"0x01")
  table.insert(packet1,"0x02")
  table.insert(packet1,("0x"..string.format("%02X",count1)))
  table_concat(packet1,data1)
  table.insert(packet1,"0xF7")
  
  packet2 = {"0xF0","0x00","0x01","0x79","0x04","0x00"}
  table.insert(packet2,("0x"..string.format("%02X",enc)))
  table.insert(packet2,"0x02")
  table.insert(packet2,"0x02")
  table.insert(packet2,("0x"..string.format("%02X",count2)))
  table_concat(packet2,data2)
  table.insert(packet2,"0xF7")
end

local function build_global_sysex_packet()
  packet0 = {}
  packet0 = {"0xF0","0x00","0x01","0x79","0x01"}
  table_concat(packet0,conf[0])
  table.insert(packet0,"0xF7")
end


--
-- SYSEX SEND
--
local function send_sysex(m, d)
  for i,v in ipairs(d) do
    m:send{d[i]}
  end
end


--
-- EXEC FUNCTION
--
function mftconf.load_conf(midi_dev,filename)
  parse_mft_conf(read_file(filename))
  for i=1,64 do
    build_enc_sysex_packet(i)
    send_sysex(midi_dev,packet1)
    send_sysex(midi_dev,packet2)
  end
  print("encoder conf pushed")
  build_global_sysex_packet()
  send_sysex(midi_dev,packet0)
  print("global conf pushed")
end


--
-- READ PARAMS FROM HOST SCRIPT
--
local param_values = {}

local function init_param_values()
  for i=1,params.count do
    local p = params:lookup_param(i)
    param_values[p.id] = {}
  end
end
  
local function read_param_values()
  for i=1,params.count do
    local p = params:lookup_param(i)
    if p.t == 3 or p.t == 5 then
      param_values[p.id].value = params:get_raw(p.id)
      param_values[p.id].min = 0
      param_values[p.id].max = 1
      param_values[p.id].cc_value = util.round(util.linlin(param_values[p.id].min,param_values[p.id].max,0,127,param_values[p.id].value))
    elseif p.t == 1 or p.t == 2 or p.t == 9 then
      param_values[p.id].value = params:get(p.id)
      param_values[p.id].min = params:get_range(p.id)[1]
      param_values[p.id].max = params:get_range(p.id)[2]
      param_values[p.id].cc_value = util.round(util.linlin(param_values[p.id].min,param_values[p.id].max,0,127,param_values[p.id].value))
    end
  end
end


--
-- READ MIDI MAPPINGS FROM HOST SCRIPT
--
local function read_midi_mappings()
  local function unquote(s)
    return s:gsub('^"', ''):gsub('"$', ''):gsub('\\"', '"')
  end
  local filename = norns.state.data..norns.state.shortname..".pmap"
  local fd = io.open(filename, "r")
  if fd then
    io.close(fd)
    for line in io.lines(filename) do
      local name, value = string.match(line, "(\".-\")%s*:%s*(.*)")
      if name and value and tonumber(value)==nil then
        local param_id = unquote(name)
        local s = unquote(value)
        local s = string.gsub(s,"{","")
        local s = string.gsub(s,"}","")
        for key, val in string.gmatch(s, "(%S-)=(%d+)") do
          if key == "dev" then
            param_values[param_id].dev = val
          elseif key == "ch" then
            param_values[param_id].ch = val
          elseif key == "cc" then
            param_values[param_id].cc = val
          end
        end
      end
    end
    print(filename.." midi mapping file read succesfully!")
  else
    print("m.read: "..filename.." not read, using defaults.")
  end
end


--
-- CLEAR MFT CC VALUES
--
local function clear_values(midi_dev)
  for i=0,127 do
    midi_dev:cc(i, 0, 1)
  end
end


--
-- SEND MAPPED PARAM VALUES TO MFT
--
local function send_values(midi_dev)
  for i=1,params.count do
    local p = params:lookup_param(i)
    if param_values[p.id].cc ~= nil then
      midi_dev:cc(param_values[p.id].cc, param_values[p.id].cc_value, param_values[p.id].ch)
    end
  end
end


--
-- EXEC FUNCTION
--
function mftconf.refresh_values(midi_dev)
  init_param_values()
  read_param_values()
  read_midi_mappings()
  clear_values(midi_dev)
  send_values(midi_dev)
  print("param values pushed")
end

function mftconf.mft_redraw(midi_dev,param_id)
  read_param_values()
  if param_values[param_id].cc ~= nil then
    midi_dev:cc(param_values[param_id].cc, param_values[param_id].cc_value, param_values[param_id].ch)
  end
end

return mftconf
