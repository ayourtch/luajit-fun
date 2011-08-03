--[[
Very simple timer implementation. 

usage:

tm = require 'timr'

-- create a timergroup object with 0.25 granularity and
-- maximum interval of 128 seconds (NB: second 
-- must be times a power of two of the first)

tg = tm.timergroup(0.25, 128) 
t1 = tm.timer(tm.now() + 1.0, function(t) print("Timer fired") end)
t2 = tm.timer(tm.now() + 2.0, 
         function(t) 
           print("Timer 2 fired - periodic")
           t.when = tm.now() + 2.0 
           tg.wind(t)
         end)

tg.wind(t1)
tg.wind(t2)

local idle = 0.01
local idx
while idle do
  collectgarbage("step")
  idle, idx = tg.idletime()
  if idle and idle > 0 then
    tm.xsleep(idle)
  end
  tg.firenext()
end


]]

local S = require "syscall"
local ffi = require("ffi")
local bit = require "bit"
local print = print
local math = math

module "timr"

function timer(when, callback)
  local t = {}
  t.active = true
  t.when = when
  t.cb = callback 
  return t
end

function now()
  return S.gettimeofday():tonumber()
end

function xsleep(n)
  local rem = math.mod(n,1)
  local int = n - rem
  S.nanosleep(S.t.timespec(int, 1000000000*rem))
end

function timerticker(interval)
  -- "ticker": a set of timers that were wound up to fire within the same interval
  -- helps to avoid sorting, since at any given moment in time, the insertion would need to fire at
  --  "now + interval", so will be monotonously increasing.
  local tt = {}
  tt.timers = {}
  tt.last_timer = nil
  tt.first_timer = nil
  tt.interval = interval

  tt.wind = function (t)
    t.when_wind = now() + tt.interval
    tt.timers[t] = t
    if tt.last_timer then
      tt.last_timer.next_timer = t
    end
    tt.last_timer = t
    if not tt.first_timer then
      tt.first_timer = t
    end
  end

  tt.idletime = function(t)
    if tt.first_timer then
      return tt.first_timer.when_wind - now()
    else
      return nil
    end 
  end

  tt.firenext = function(cb)
    local t = tt.first_timer
    if t then
      tt.first_timer = t.next_timer
      if t == tt.last_timer then
        tt.last_timer = nil
      end
      t.next_timer = nil
      cb(t)
    end
  end

  return tt
end

function timergroup(resolution, max)
  local tg = {}
  tg.res = resolution
  tg.max = max
  tg.pwr = max/resolution
  tg.tickers = {}
  local mult = tg.pwr
  if bit.band(mult, mult-1) ~= 0 then
    print("MAX of " .. max .. " is not a power of 2 of " .. resolution)
    return nil
  end

  local pwr = 1
  while pwr <= mult do
    -- print("Set up timer level ", pwr, " max ", mult)
    tg.tickers[pwr] = timerticker(pwr * resolution)
    
    pwr = pwr * 2
  end

  tg.wind = function(t)
    local interval = t.when - now() 
    if interval > tg.max then
      print (interval .. " is bigger than " .. tg.max .. ", can not schedule")
      return nil
    end
    local pwr = tg.pwr
    local intvl = tg.max
    while pwr >= 1 and intvl > interval do
      intvl = intvl/2
      pwr = pwr / 2
    end
    if pwr < 1 then
      pwr = 1
    end
    -- print("Scheduling interval " .. interval .. " into basket of " .. pwr)
    tg.tickers[pwr].wind(t)
    return pwr
  end

  tg.idletime = function()
    local pwr = 1
    local intvl = tg.res
    local low_idle = 2*tg.max
    local low_index = nil
   
    while pwr <= tg.pwr do
      local idle = tg.tickers[pwr].idletime()
      if idle and idle < low_idle then
        low_idle = idle
        low_index = pwr
      end 
      pwr = pwr * 2
      intvl = intvl * 2
    end
    if low_index == nil then
      return nil, nil
    end
    return low_idle, low_index
  end

  tg.firenext = function()
    local idle, index = tg.idletime()
    if index then
      if index == 1 then
        local idletime =  tg.tickers[index].idletime()
        return tg.tickers[index].firenext(
                    function (t) 
                      local i = t.when - now();  
                      if i > tg.res/2 then 
                        tg.wind(t) 
                      else 
                        t.cb(t) 
                      end 
                    end)
      else
        return tg.tickers[index].firenext(tg.wind)
      end
    end
  end 

  return tg
end
  


