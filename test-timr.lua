-- test program for timers

tm = require "timr"
local S = require "syscall"
local ffi = require("ffi")


tg = tm.timergroup(1/128,1024)

local now = tm.now

start = now()

t1 = tm.timer(now()+5, function(t) print("timer1 - 5", now() - start); t.when = now() + 1/3; tg.wind(t); end)
t11 = tm.timer(now()+5, function(t) print("timer11 - 5", now() - start); end)
t12 = tm.timer(now()+600, function(t) print("timer12 - 600", now() - start); end)
t13 = tm.timer(now()+300, function(t) print("timer13 - 300", now() - start); end)
t2 = tm.timer(now()+3, function(t) print("timer2 - 3", now() - start) end)
t3 = tm.timer(now()+1.5, function(t) print("timer3 - 1.5", now() - start) end)


tg.wind(t1)
tg.wind(t2)
tg.wind(t11)
tg.wind(t12)
tg.wind(t13)
tg.wind(t3)

local idle = 0.01
local idx
while idle do
  collectgarbage("step")
  idle, idx = tg.idletime()
--  print("Idle time: ", idle, idx)
  if idle and idle > 0 then
    tm.xsleep(idle)
  end
  tg.firenext()
end

