sok = require 'sokt'


local HTTP_REPLY = [[HTTP/1.0 200 OK
Content-Type: text/plain

This is test
]]


local MAX_FD = 2560

local ss = sok.socket_set(MAX_FD)

local my_accept_cb = function(fds, i)
  local cb = {}
  cb.read = function(fds, i, data, len)
    fds.send(i, HTTP_REPLY, #HTTP_REPLY)
    fds.close(i)
  end
  cb.close = function(fds, i)
    -- print("Closed socket")
  end
  return cb
end

local my_udp_cb = function(fds, i)
  local cb = {}
  cb.read = function(fds, i, data, len, sa, sa_len)
    fds.sendto(i, data, len, sa, sa_len)
  end
  return cb
end


while not ss.add_tcp_listener(12345, my_accept_cb) do
  sok.sleep(1)
  print("Retrying TCP listener..")
end

while not ss.add_udp_listener(12345, my_udp_cb) do
  sok.sleep(1)
  print("Retrying UDP listener..")
end

print("Added listener, please run the test")
while true do
  local n = ss.poll(1000)
end


