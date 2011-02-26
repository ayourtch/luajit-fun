-- inspired by https://github.com/mkottman/ffi_fun/blob/master/ffmpeg_audio.lua
-- Andrew Yourtchenko 2011, MIT license

local FILENAME = arg[1] or 'song.mp3'
local SECTION = print

-- A more flexible include function example - but requires patch to luajit to 
-- not barf on redefinitions
local ffi = require "ffi"
local C = ffi.C


ffi.include = function(fname)
  local f
  if type(fname) == "string" then
    print("Including " .. fname)
    f = io.popen("echo '#include <" .. fname .. ">' | gcc -E -")
  elseif type(fname) == "table" then
    f = io.popen("cat " .. fname[1] .. " | gcc -E -")
  else
    assert(nil, "Need either string or array[1] as argument")
  end
  local t = {}
  while true do
    local line = f:read()
    if line then
      if not line:match("^#") then
        table.insert(t, line)
      end
    else
      break
    end
  end
  -- print(table.concat(t, "\n"))
  ffi.cdef(table.concat(t, "\n"))
  f:close()
end

ffi.loadlib = function(t)
  local lib
  for i,f in ipairs(t) do
    if i == 1 then
      lib = ffi.load(f)
    else
      ffi.include(f)
    end
  end
  return lib
end

ffi.include "stdio.h" 
ffi.include "time.h" 
ffi.include "unistd.h"

avutil = ffi.loadlib { "avutil", "libavutil/avstring.h" }
avcodec = ffi.loadlib { "avcodec", "libavcodec/avcodec.h" }
avformat = ffi.loadlib { "avformat", "libavformat/avformat.h" }


function avAssert(err)
	if err < 0 then
		local errbuf = ffi.new("uint8_t[256]")
		-- local ret = avutil.av_strerror(err, errbuf, 256)
                local ret = -1
		if ret ~= -1 then
			error(ffi.string(errbuf), 2)
		else
			error('Unknown AV error: '..tostring(ret), 2)
		end
	end
	return err
end

SECTION "Initializing the avcodec and avformat libraries"

avcodec.avcodec_init()
avcodec.avcodec_register_all()
avformat.av_register_all()

SECTION "Opening file"

local pinputContext = ffi.new("AVFormatContext*[1]")
avAssert(avformat.av_open_input_file(pinputContext, FILENAME, nil, 0, nil))
local inputContext = pinputContext[0]

avAssert(avformat.av_find_stream_info(inputContext))

SECTION "Finding audio stream"

local audioCtx
local nStreams = tonumber(inputContext.nb_streams)
for i=1,nStreams do
	local stream = inputContext.streams[i-1]
	local ctx = stream.codec
        print("Codec:",  ctx.codec_type)
	-- if ctx.codec_type == C.AVMEDIA_TYPE_AUDIO then
		local codec = avcodec.avcodec_find_decoder(ctx.codec_id)
		avAssert(avcodec.avcodec_open(ctx, codec))
		audioCtx = ctx
	-- end
end
if not audioCtx then error('Unable to find audio stream') end

print("Bitrate:", tonumber(audioCtx.bit_rate))
print("Channels:", tonumber(audioCtx.channels))
print("Sample rate:", tonumber(audioCtx.sample_rate))
print("Sample type:", ({[0]="u8", "s16", "s32", "flt", "dbl"})[audioCtx.sample_fmt])

SECTION "Decoding"

local AVCODEC_MAX_AUDIO_FRAME_SIZE = 192000

local packet = ffi.new("AVPacket")
local temp_frame = ffi.new("int16_t[?]", AVCODEC_MAX_AUDIO_FRAME_SIZE)
local frame_size = ffi.new("int[1]")

local all_samples = {}
local total_samples = 0

while tonumber(avformat.url_feof(inputContext.pb)) == 0 do
	local ret = avAssert(avformat.av_read_frame(inputContext, packet))

	frame_size[0] = AVCODEC_MAX_AUDIO_FRAME_SIZE
	local n = avcodec.avcodec_decode_audio2(audioCtx, temp_frame, frame_size, packet.data, packet.size)
	if n == -1 then break
	elseif n < 0 then avAssert(n) end

	local size = tonumber(frame_size[0])/2 -- frame_size is in bytes
	local frame = ffi.new("int16_t[?]", size)
	ffi.copy(frame, temp_frame, size*2)
	all_samples[#all_samples + 1] = frame
	total_samples = total_samples + size
end

SECTION "Merging samples"

local samples = ffi.new("int16_t[?]", total_samples)
local offset = 0
for _,s in ipairs(all_samples) do
	local size = ffi.sizeof(s)
	ffi.copy(samples + offset, s, size)
	offset = offset + size/2
end

SECTION "Processing"

-- The `samples` array is now ready for some processing! :)

-- ... like writing it raw to a file

local out = assert(io.open('samples.raw', 'wb'))
local size = ffi.sizeof(samples)
out:write(ffi.string(samples, size))
out:close()

