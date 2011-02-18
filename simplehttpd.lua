-- (c) Andrew Yourtchenko (ayourtch@gmail.com) 2011

local ffi = require("ffi")

-- try to use FFI when no lua symbol found...
setmetatable(_G, { __index = ffi.C } )

ffi.cdef [[
 typedef uint32_t socklen_t;
 typedef uint32_t in_addr_t;

 typedef struct {
    uint16_t sin_family;
    char d[128];
  } sock_stor;

 typedef struct pollfd {
    int fd;                     /* File descriptor to poll.  */
    short int events;           /* Types of events poller cares about.  */
    short int revents;          /* Types of events that actually occurred.  */
  } poll_fd;

typedef unsigned long int nfds_t;


 int bind(int sockfd, sock_stor *addr, socklen_t addrlen);
 int socket(int domain, int type, int protocol);
 int listen(int sockfd, int backlog);
 int poll(struct pollfd *fds, nfds_t nfds, int timeout);
 int accept(int sockfd, sock_stor *addr, socklen_t *addrlen);
 int send(int sockfd, const void *buf, int len, int flags);
 int recv(int sockfd, void *buf, int len, int flags);
 int close(int fd);

 typedef struct { char *pc; } sighandler_t;

 sighandler_t signal(int signum, sighandler_t handler);

  
 int printf(const char *fmt, ...);
 unsigned int sleep(unsigned int seconds);

]]

local AF_INET = 2
local AF_INET6 = 10
local SOCK_STREAM = 1
local SOCK_DGRAM = 2

local POLLIN = 1
local POLLOUT = 4
local POLLERR = 8

local HTTP_REPLY = [[HTTP/1.0 200 OK
Content-Type: text/plain

This is test
]]



function socket_set(maxfds)
  -- ignore SIGPIPE
  sig_ign = ffi.new("sighandler_t")
  sig_ign.pc = sig_ign.pc + 1
  signal(13, sig_ign)

  local fds = {}
  fds.BUF_LEN = 8192
  fds.buf = ffi.new("char[?]", fds.BUF_LEN)
  fds.MAX_FD = maxfds
  fds.pfds = ffi.new("poll_fd[?]", fds.MAX_FD)
  fds.nfds = 0
  fds.cb = {}
  fds.listeners = {}

  fds.poll = function(timeout)
    local n = poll(fds.pfds, fds.nfds, timeout)
    for i=fds.nfds-1,0,-1 do
      if fds.cb[i].is_listener and fds.pfds[i].revents == POLLIN then
        if fds.cb[i].read then
          fds.cb[i].read(fds, i)
          collectgarbage("step")
        end
      end
    end
    for i=fds.nfds-1,0,-1 do
      if not fds.cb[i].is_listener and fds.pfds[i].revents == POLLIN then
        if fds.cb[i].read then
          fds.cb[i].read(fds, i)
          collectgarbage("step")
        end
      end
    end
    return n
  end

  fds.close = function(i)
    if fds.cb[i].close then
      fds.cb[i].close(fds, i)
    end
    close(fds.pfds[i].fd)
    for j=i,fds.nfds-2 do
      fds.pfds[j].fd = fds.pfds[j+1].fd
      fds.pfds[j].events = fds.pfds[j+1].events
      fds.cb[j] = fds.cb[j+1]
    end
    fds.nfds = fds.nfds - 1
  end

  fds.add = function(fd, cb)
    fds.pfds[fds.nfds].fd = fd
    fds.pfds[fds.nfds].events = POLLIN
    if not cb then cb = {} end
    fds.cb[fds.nfds] = cb
    fds.nfds = fds.nfds + 1
  end

  fds.socket = function()
    local s = socket(AF_INET6, SOCK_STREAM, 0)
    return s
  end

  fds.get_sa_any = function(port)
    local sa = ffi.new("sock_stor[1]")
    sa[0].sin_family = AF_INET6
    sa[0].d[1] = port % 256
    sa[0].d[0] = (port - sa[0].d[1]) / 256
    return sa;
  end

  fds.listener_socket = function(port)
    local s = fds.socket()
    if bind(s, fds.get_sa_any(port), 128) == 0 and listen(s, 10) then
      return s
    else
      close(s)
      return nil
    end 
  end

  fds.send = function(i, data, len)
    send(fds.pfds[i].fd, data, len, 0)
  end

  fds.add_listener = function(port, callback)
    if not callback then callback = function() return {} end end

    local f = function(fds, i)
      local sa = ffi.new("sock_stor[1]") 
      local sa_len = ffi.new("int[1]")
      local fdn = accept(fds.pfds[i].fd, sa, sa_len)
      local handles = callback(fds, i, sa, sa_len, fdn)
      if handles then
        local h = {}
        h.read = function(fds, i)
          local n = recv(fds.pfds[i].fd, fds.buf, fds.BUF_LEN, 0)
          if n > 0 then
            handles.read(fds, i, fds.buf, n)
          else
            fds.close(i)
          end
        end
        h.close = handles.close
        h.is_listener = true

        fds.add(fdn, h)
      else
        close(fdn)
      end
    end

    local fd = fds.listener_socket(port)
    if fd then
      fds.add(fd, { read = f })
      return true
    else
      print("Could not add listener")
      return nil
    end
  end

  return fds
end

local MAX_FD = 2560

local ss = socket_set(MAX_FD)

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


while not ss.add_listener(12345, my_accept_cb) do
  sleep(1)
end
print("Added listener, please run the test")
while true do
  local n = ss.poll(1000)
end


