bit = require "bit"
local S = require "syscall"
local ffi = require("ffi")
local sokt = require "sokt"
local ht = require "httparse"
local prof = require "profiler"

local profiler = nil
-- local profile = true
local parse_http = true

-- Eventloop test bench

local HTTP_REPLY = [[HTTP/1.0 200 OK
Content-Type: text/plain
]]

local in_loop = true

local my_accept_cb = function(fds, s)
  local cb = {}
  if not profiler and profile then
    print("Start profiling")
    profiler = newProfiler()
    profiler:start()
  end
  cb.read = function(fds, s, data, len)
    local reply = {}
    local headers = {}
    local out = HTTP_REPLY
    if parse_http then
      local d = ht.parse(S.string(data, len), nil)
      table.insert(headers, HTTP_REPLY)
      table.insert(reply, d.method)
      table.insert(reply, " ")
      table.insert(reply, d.uri)
      table.insert(reply, "\n")
      for i,v in pairs(d.hdr) do
	table.insert(reply, "'" .. i .. "'")
	table.insert(reply, ":")
	table.insert(reply, v)
	table.insert(reply, "\n")
      end
      local content = table.concat(reply)
      table.insert(headers, "Content-Length: " .. #content .. "\r\n" )
      out = table.concat(headers) .. "\r\n" .. content
    end
    s:send(out, #out)
    fds.close(s)
  end
  cb.close = function(fds, s)
     -- print("Closed socket", s.fileno)
  end
  return cb
end

local my_udp_cb = function(fds, i)
  local cb = {}
  cb.read = function(fds, s, data, len, sa, sport)
    print("Received UDP packet:", S.string(data, len))
    in_loop = false
    if profiler then
      profiler:stop()
      local outfile = io.open( "profile.txt", "w+" )
      profiler:report( outfile )
      outfile:close()
    end
    -- fds.sendto(i, data, len, sa, sa_len)
  end
  return cb
end

print("signal", S.SIGPIPE, S.SIG_IGN)
S.signal(S.SIGPIPE, S.SIG_IGN)

ss = sokt.sokt()
-- ss.add_listener("stream", 12345)

while not ss.add_tcp_listener(12345, my_accept_cb) do
  S.sleep(1)
  print("Retrying TCP listener..")
end

while not ss.add_udp_listener(12345, my_udp_cb) do
  S.sleep(1)
  print("Retrying UDP listener..")
end

print("Added listener, please run the test")


while true and in_loop do
  local n = ss.poll(1000)
end

