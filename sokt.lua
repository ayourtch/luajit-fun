local require,setmetatable,collectgarbage,tostring = require,setmetatable,collectgarbage,tostring
local print = print

module "sokt"

-- abstracted event loop with sockets, using the FFI of luajit
-- (c) Andrew Yourtchenko (ayourtch@gmail.com) 2011, MIT license

local ffi = require("ffi")

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


 void perror(const char *s);

 int bind(int sockfd, sock_stor *addr, socklen_t addrlen);
 int socket(int domain, int type, int protocol);
 int listen(int sockfd, int backlog);
 int poll(struct pollfd *fds, nfds_t nfds, int timeout);
 int accept(int sockfd, sock_stor *addr, socklen_t *addrlen);
 int send(int sockfd, const void *buf, int len, int flags);
 int sendto(int sockfd, const void *buf, size_t len, int flags, sock_stor *dest_addr, socklen_t addrlen);
 int recv(int sockfd, void *buf, int len, int flags);
 int recvfrom(int sockfd, void *buf, int len, int flags,
                        sock_stor *src_addr, socklen_t *addrlen);
 int connect(int sockfd, sock_stor *addr, socklen_t addrlen);

 int close(int fd);

 typedef struct { char *pc; } sighandler_t;

 sighandler_t signal(int signum, sighandler_t handler);

  
 int printf(const char *fmt, ...);
 unsigned int sleep(unsigned int seconds);
 unsigned int fork(void);

typedef struct addrinfo {
               int              ai_flags;
               int              ai_family;
               int              ai_socktype;
               int              ai_protocol;
               int           ai_addrlen;
               sock_stor        *ai_addr;
               char            *ai_canonname;
               struct addrinfo *ai_next;
} addrinfo_t;

typedef addrinfo_t *p_addrinfo_t;

int getaddrinfo(const char *node, const char *service,
                       const struct addrinfo *hints,
                       struct addrinfo **res);

void freeaddrinfo(struct addrinfo *res);

const char *gai_strerror(int errcode);

void *memset(void *s, int c, size_t n);
void *memcpy(void *dest, const void *src, size_t n);
void perror(const char *s);

/* This all stuff here is horrilifically unportable. 
Anticioating the pleasure of deleting this when I have
the preprocessor ready.
*/

struct cmsghdr {
           long  cmsg_len;    /* data byte count, including header */
           int       cmsg_level;  /* originating protocol */
           int       cmsg_type;   /* protocol-specific type */
       };

typedef struct cmsghdrfd { struct cmsghdr h; int fd; } cmsghdrfd_t;

struct msghdr
  {
    void *msg_name;             /* Address to send to/receive from.  */
    socklen_t msg_namelen;      /* Length of address data.  */

    struct iovec *msg_iov;      /* Vector of data to send/receive into.  */
    size_t msg_iovlen;          /* Number of elements in the vector.  */

    void *msg_control;          /* Ancillary data (eg BSD filedesc passing). */
    size_t msg_controllen;      /* Ancillary data buffer length.
                                   !! The type should be socklen_t but the
                                   definition of the kernel is incompatible
                                   with this.  */

    int msg_flags;              /* Flags on received message.  */
  };

struct iovec
  {
    void *iov_base;     /* Pointer to data.  */
    size_t iov_len;     /* Length of data.  */
  };

int sendmsg(int sockfd, struct msghdr *msg, int flags);
int recvmsg(int sockfd, struct msghdr *msg, int flags);
int socketpair(int domain, int type, int protocol, int sv[2]);

void exit(int status);

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

function sleep(n)
  ffi.C.sleep(n)
end


function socket_set(maxfds)
  -- ignore SIGPIPE

  local fds = {}
  fds.BUF_LEN = 8192
  fds.buf = ffi.new("char[?]", fds.BUF_LEN)
  fds.MAX_FD = maxfds
  fds.pfds = ffi.new("poll_fd[?]", fds.MAX_FD)
  fds.nfds = 0
  fds.cb = {}
  fds.listeners = {}

  fds.sig_ignore = function(signum)
    sig_ign = ffi.new("sighandler_t")
    sig_ign.pc = sig_ign.pc + 1
    ffi.C.signal(signum, sig_ign)
  end
 

  fds.poll = function(timeout)
    local n = ffi.C.poll(fds.pfds, fds.nfds, timeout)
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
    ffi.C.close(fds.pfds[i].fd)
    for j=i,fds.nfds-2 do
      fds.pfds[j].fd = fds.pfds[j+1].fd
      fds.pfds[j].events = fds.pfds[j+1].events
      fds.cb[j] = fds.cb[j+1]
    end
    fds.nfds = fds.nfds - 1
  end

  fds.add = function(fd, cb)
    if(fds.nfds < fds.MAX_FD) then
      local i = fds.nfds
      fds.pfds[i].fd = fd
      fds.pfds[i].events = POLLIN
      if not cb then cb = {} end
      fds.cb[i] = cb
      fds.nfds = fds.nfds + 1
      return i
    else
      return nil
    end
  end

  fds.socket = function(addr_f, socktype)
    local st = socktype or SOCK_STREAM
    local af = addr_f or AF_INET6
    local s = ffi.C.socket(af, st, 0)
    return s
  end

  fds.get_sa_any = function(port)
    local sa = ffi.new("sock_stor[1]")
    sa[0].sin_family = AF_INET6
    sa[0].d[1] = port % 256
    sa[0].d[0] = (port - sa[0].d[1]) / 256
    return sa;
  end

  fds.lookup = function(af, hostname, service, socktype)
    local null = ffi.new("void *")
    local ai = ffi.new("struct addrinfo *[1]", nil)
    local hints = ffi.new("struct addrinfo [1]")
    local sockaddr 
    local addrlen

    hints[0].ai_family = af
    hints[0].ai_socktype = socktype or SOCK_STREAM

    i = ffi.C.getaddrinfo(hostname, tostring(service), hints, ai)
    if i == 0 then
      reply = ai[0]
      -- print(reply.ai_family, reply.ai_addrlen, reply.ai_socktype)
      sockaddr =  ai[0].ai_addr;
      sockaddr = fds.get_sa_any(0)
      ffi.C.memcpy(sockaddr, ai[0].ai_addr, reply.ai_addrlen)
      addrlen = reply.ai_addrlen
    else
      ffi.C.printf("GAI error: %s\n", ffi.C.gai_strerror(i))
    end
    ffi.C.freeaddrinfo(ai[0]);
    return sockaddr, addrlen
  end

  fds.connect_socket = function(af, server, service, socktype)
    local sa, addr_len = fds.lookup(af, server, service, socktype)
    local s
    local res
    local msg = "success"
    if sa then
      s = fds.socket(af, socktype) 
      res = ffi.C.connect(s, sa, addr_len)
      if not (res == 0) then
        ffi.C.close(s)
        s = nil  
        msg = "can not connect"
      end
    else
      msg = "can not resolve"
    end
    return s, msg
  end

  -- Achtung! Returns an IPC socket to do the recv_fd on!

  fds.fork_connect = function(af, hostname, service)
    local sv = fds.socketpair()
    local pid
    local ipc

    pid = ffi.C.fork()
    if pid == 0 then
      ipc = sv[0]
      ffi.C.close(sv[1])
      local fd, err = fds.connect_socket(af, hostname, service)
      if fd then
	fds.send_fd(ipc, fd, 73) -- ham jargon.
      else
	fds.send_fd(ipc, 0, 13)  -- send a lucky number and stdin.
      end
      ffi.C.exit(0)
    else
      ipc = sv[1]
      ffi.C.close(sv[0])
      return ipc
    end
  end


  fds.listener_socket = function(port, socktype)
    local s = fds.socket(socktype)
    if ffi.C.bind(s, fds.get_sa_any(port), 128) == 0 and (socktype == SOCK_DGRAM or ffi.C.listen(s, 10)) then
      return s
    else
      ffi.C.close(s)
      return nil
    end 
  end

  -- make a couple of unix sockets
  fds.socketpair = function()
    local sv = ffi.new("int[2]")
    local res = ffi.C.socketpair(1, 1, 0, sv)
    if res == 0 then
      return sv, res
    else
      return nil, res
    end
  end

  fds.send_fd = function(ipc, fd, code)
    local buf = ffi.new("char [1]")
    buf[0] = code
    local cmsgptr = ffi.new("struct cmsghdrfd[1]")
    local cmsg = cmsgptr[0]
    local iovptr = ffi.new("struct iovec[1]")
    local iov = iovptr[0]
    local msgptr = ffi.new("struct msghdr[1]")
    local msg = msgptr[0]
   
    iov.iov_base = buf
    iov.iov_len = 1

    cmsg.h.cmsg_level = 1;
    cmsg.h.cmsg_type = 1;  
    cmsg.h.cmsg_len = ffi.sizeof(cmsg)
    cmsg.fd = fd
    msg.msg_iov = iovptr;
    msg.msg_iovlen = 1;
    msg.msg_control = cmsgptr; 
    msg.msg_controllen = ffi.sizeof(cmsg)
    return ffi.C.sendmsg(ipc, msgptr, 0)
  end

  fds.recv_fd = function(ipc)
    local buf = ffi.new("char [1]")
    local cmsgptr = ffi.new("struct cmsghdrfd[1]")
    local cmsg = cmsgptr[0]
    local iovptr = ffi.new("struct iovec[1]")
    local iov = iovptr[0]
    local msgptr = ffi.new("struct msghdr[1]")
    local msg = msgptr[0]

    iov.iov_base = buf
    iov.iov_len = 1

    msg.msg_iov = iovptr;
    msg.msg_iovlen = 1;
    msg.msg_control = cmsgptr; 
    msg.msg_controllen = ffi.sizeof(cmsg)
    res = ffi.C.recvmsg(ipc, msgptr, 0)
    if (res > 0) then
      return cmsg.fd, buf[0]
    else
      return nil
    end
  end


  fds.send = function(i, data, len)
    return ffi.C.send(fds.pfds[i].fd, data, len, 0)
  end

  fds.sendto = function(i, data, len, sa, sa_len)
    return ffi.C.sendto(fds.pfds[i].fd, data, len, 0, sa, sa_len)
  end

  fds.add_listener = function(socktype, port, callback)
    if not callback then callback = function() return {} end end
    local handles_dgram 

    if socktype == SOCK_DGRAM then
      handles_dgram = callback(fds)
      if not handles_dgram then
        handles_dgram = {}
      end
    end
    

    local f = function(fds, i)
      local sa = ffi.new("sock_stor[1]") 
      local sa_len = ffi.new("int[1]")
      sa_len[0] = 128
      if socktype == SOCK_STREAM then
        local fdn = ffi.C.accept(fds.pfds[i].fd, sa, sa_len)
        local handles = callback(fds, i, sa, sa_len, fdn)
        if handles then
          local h = {}
          h.read = function(fds, i)
            local n = ffi.C.recv(fds.pfds[i].fd, fds.buf, fds.BUF_LEN, 0)
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
      else
        local n = ffi.C.recvfrom(fds.pfds[i].fd, fds.buf, fds.BUF_LEN, 0,  sa, sa_len)
        if handles_dgram.read then
          handles_dgram.read(fds, i, fds.buf, n, sa, sa_len[0])
        end
      end
    end

    local fd = fds.listener_socket(port, socktype)

    if fd then
      fds.add(fd, { read = f })
      return true
    else
      return nil
    end
  end

  fds.add_tcp_listener = function(port, callback)
    return fds.add_listener(SOCK_STREAM, port, callback)
  end

  fds.add_udp_listener = function(port, callback)
    return fds.add_listener(SOCK_DGRAM, port, callback)
  end

  fds.sig_ignore(13) -- SIGPIPE

  return fds
end

