-- midi fighter twister
-- config loader lib

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
  print(filename.." read succesfully!")
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

return mftconf
