-- http://sunsite.ualberta.ca/Documentation/Gnu/gcc-3.0.2/html_chapter/cpp_1.html

function fname_expand(fname)
  return "/usr/include/" .. fname
end


local parse_state = "default"

function get_next_state(i_c, i_sq, i_dq)
  local max = 0
  local min = 9999
  local states = { "comment", "single quotes", "double quotes", "default" }
  local indices = { i_c, i_sq, i_dq }
  local idx = 4
  for i = 1,3 do
    if indices[i] and indices[i] < min then 
      min = indices[i]
      idx = i
    end
  end
  return states[idx]
end

function find_unescaped(haystack, needle, start)
  local i = nil
  local npos, spos
  while true do
    npos = haystack:find(needle, start, true)
    spos = haystack:find("\\", start, true)
    if spos and npos == spos + 1 then
      start = npos + 1
    else
      break
    end 
  end
  return npos
end

function eat_comments(line)
  local start = 1
  local parts = {}
  -- print("PROCESS:", line, parse_state)
  while true do
    if start > #line then
      break
    end
    if parse_state == "comment" then
      local i = line:find("*/", start, true)
      if i then
        table.insert(parts, string.rep(" ", 1))
        start = i+2
        parse_state = "default"
      else
        break
      end
    elseif parse_state == "single quotes" then
      local i = find_unescaped(line, "'", start)
      assert(i, "missing terminating \' character") 
      table.insert(parts, line:sub(start, i))
      start = i+1
      -- print("State:", parse_state, "=>", next_state, start)
      parse_state = "default"
    elseif parse_state == "double quotes" then
      local i = find_unescaped(line, '"', start)
      assert(i, "missing terminating \" character") 
      table.insert(parts, line:sub(start, i))
      start = i+1
      parse_state = "default"
    elseif parse_state == "default" then
      local i_c = line:find("/*", start, true)
      local i_sq = line:find("'", start, true)
      local i_dq = line:find('"', start, true)
      local next_state = get_next_state(i_c, i_sq, i_dq)
      if next_state == "default" then
        table.insert(parts, (line:sub(start):gsub("//.*", " ")))   
        break
      elseif next_state == "single quotes" then
        table.insert(parts, line:sub(start, i_sq))
        start = i_sq+1
      elseif next_state == "double quotes" then
        table.insert(parts, line:sub(start, i_dq))
        start = i_dq+1
      elseif next_state == "comment" then
        table.insert(parts, line:sub(start, i_c-1))
        start = i_c+2
      end
      -- print("State:", parse_state, "=>", next_state, start)
      parse_state = next_state
    end
  end
  local res = table.concat(parts, "")
  -- print("eat_comments: |" .. line .. "|=|" .. res .. "|")
  return res
end

assert(eat_comments("asd") == "asd")
assert(eat_comments("asd// foobar") == "asd ")
assert(eat_comments("'a'") == "'a'")
assert(eat_comments('"foo bar baz"') == '"foo bar baz"')
assert(eat_comments('"foo \\\"bar baz"') == '"foo \\\"bar baz"')
assert(eat_comments("\"/* blah */\"") == "\"/* blah */\"")
assert(eat_comments("/* blah */") == " ")
assert(eat_comments("/* \"a asd aasd  */") == " ")

-- assert(nil, "All tests passed")

function cpp(fname)
  -- local realfname = fname_expand(fname)
  local realfname = fname
  local f = io.open(realfname)
  local t = {}
  local def = {}
  local line_accum = {}
  local comment_accum = {}
  local linenum = 0
  while true do
    local line = f:read()
    linenum = linenum + 1
    if not line then
      break
    end
    if line:sub(#line) == "\\" then
      table.insert(line_accum, line:sub(1, #line-1))
    else
      line = eat_comments(table.concat(line_accum, "") .. line)
      if parse_state == "comment" then
        table.insert(comment_accum, line)
        line_accum = {} 
      else
        line = table.concat(comment_accum, "") .. line
        comment_accum = {}
        line_accum = {} 
        local m0 = line:match("^%s*#")
        if m0 then
          local m1, m2 = line:match("^%s*#%s*([^%s]+)%s*(.*)$")
          if m1 then
            print(m1, m2)
          else
            print("====", m0, line)
          end
        end
      end
    end
  end
  f:close()
end

-- cpp("stdio.h")
cpp("bla.h")
