local S = require "syscall"
local ffi = require("ffi")
local sokt = require "sokt"
local ht = require "httparse"

-- Eventloop test bench

local HTTP_REPLY = [[HTTP/1.0 200 OK
Content-Type: text/plain

This is test
]]

local in_loop = true

local my_accept_cb = function(fds, s)
  local cb = {}
  cb.read = function(fds, s, data, len)
    local d = ht.parse(S.string(data, len), nil)
    s:send(HTTP_REPLY, #HTTP_REPLY)
    s:send(d.method, #d.method)
    s:send(d.uri, #d.uri)
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
    -- fds.sendto(i, data, len, sa, sa_len)
  end
  return cb
end




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

