local S = require "syscall"
local ffi = require("ffi")
local assert, print, ipairs = assert, print, ipairs

module "sokt"

function sokt()
  local ss = {}
  ss.s = {}
  ss.maxfds = 1000
  ss.pfds = ffi.new("struct pollfd[?]", ss.maxfds)
  ss.sfds = {}
  ss.nfds = 0
  ss.byfileno = {}
  ss.idxof = {}
  ss.cb = {}
  ss.bufsz = 32768
  ss.buf = S.t.buffer(ss.bufsz)

  ss.delfd = function(s)
    local idx = ss.idxof[s]
    assert(idx)
    ss.idxof[s] = nil
    ss.byfileno[s.fileno] = nil
    ss.cb[s] = nil
    for i=idx,ss.nfds-2 do
      ss.pfds[i] = ss.pfds[i+1]
      ss.sfds[i] = ss.sfds[i+1]
      ss.idxof[ss.sfds[i]] = i
    end 
    ss.nfds = ss.nfds - 1
  end

  ss.addfd = function(s, callbacks)
    if ss.nfds >= ss.maxfds then
      print("Can not add fd!")
      return nil
    end

    ss.pfds[ss.nfds].fd = s.fileno
    ss.pfds[ss.nfds].events = S.POLLIN
    ss.pfds[ss.nfds].revents = 0
    ss.sfds[ss.nfds] = s
    ss.idxof[s] = ss.nfds
    ss.nfds = ss.nfds + 1
    -- print("Adding fileno:", s.fileno)

    ss.byfileno[s.fileno] = s
    ss.cb[s] = callbacks
    
  end

  ss.close = function(s)
    if ss.cb[s].close then
      ss.cb[s].close(ss, s)
    end
    ss.delfd(s)
    s:close()
  end

  ss.add_listener = function(typ, port, callback) 
    if not callback then callback = function() return {} end end
    local handles_dgram
    local s, err = S.socket("AF_INET6", typ) 
    local handles_dgram 

    if typ == "dgram" then
      handles_dgram = callback(ss)
      if not handles_dgram then handles_dgram = {} end
    end

    local f = function(ss, s)
      if typ == "stream" then
        -- stream socket, read == accept
        local a = s:accept()
        local handles = callback(ss, a)
        if handles then
          local h = {}
          h.read = function(fds, s)
            local n = s:recv(fds.buf, fds.bufsz)
            if n > 0 then 
              handles.read(fds, s, fds.buf, n)
            else
              fds.close(s)
            end
          end
          h.close = handles.close
          h.is_listener = true
          ss.addfd(a.fd, h) 
        else
          a.fd:close()
        end
        -- for k,v in pairs(a) do print(k,v) end
        -- print("Accepted")
      else
        local a =  s:recvfrom(ss.buf, ss.bufsz)
        print("Received data!")
        if handles_dgram.read then
          handles_dgram.read(ss, s, ss.buf, a.count, a.addr, a.port)
        end
        -- dgram socket
      end
    end

 
    if s then
      assert(s:setsockopt(S.SOL_SOCKET, S.SO_REUSEADDR, true))
      local sa = assert(S.sockaddr_in6(port, S.in6addr_any))
      local bindres = s:bind(sa)
      if bindres then
        print("Bind ok!")
        s:listen()
        ss.addfd(s, { read = f } ) 
      else 
        s:close()
        s = nil
      end
    end
 
    return s
  end 

  ss.add_tcp_listener = function(port, callback) 
    return ss.add_listener("stream", port, callback)
  end
  ss.add_udp_listener = function(port, callback) 
    return ss.add_listener("dgram", port, callback)
  end

  
  ss.poll = function(timeout)
    -- print("ss.nfds:", ss.nfds)
    local res = S.poll(ss.pfds, ss.nfds, timeout)
    for i,v in ipairs(res)  do
      local v = res[i]
      local s = ss.byfileno[v.fileno]
      if not s then 
        print("sock nil, fd", v.fileno)
        for i=0,ss.nfds do print(i, "fd", ss.pfds[i].fd) end
      end
      assert(s)
      local cb = ss.cb[s]
      -- print("poll fd", s.fileno)
      if v.POLLIN and cb.read then
        cb.read(ss, s)
      end
    end
    return res
  end

  return ss
end

