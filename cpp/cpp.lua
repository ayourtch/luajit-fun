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

tokentypes = {
  { "0x[0-9A-F]+", "number" },
  { "[a-zA-Z$_][a-zA-Z_$0-9]*", "ident" },
  { "[+][+]", "plus plus" },
  { "[-][-]", "minus minus" },
  { "[(]", "open paren" },
  { "[)]", "close paren" },
  { "[,]", "comma" },
  { "[#]", "hash" },
  { "%%:", "hash" }, -- digraph
  { "[;]", "semicolon" },
  { "$", "eol" },
  { "[+-/*]", "operator" },
  { "'[^']*'", "char literal" },
  { '"[^"]*"', "string literal" },
}


-- see http://www.lua.org/pil/20.4.html
function bs_encode (s)
  return (string.gsub(s, "\\(.)", function (x)
          return string.format("\\%03d", string.byte(x))
          end))
end

function bs_decode (s)
  return (string.gsub(s, "\\(%d%d%d)", function (d)
          return "\\" .. string.char(d)
          end))
end

function next_token(xline, start)
  local t, p
  local tokentype = "unknown"
  if not start then start = 1 end
  if type(start) == "table" then
    -- use the supplied token to figure where to start
    start = start[4]
  end
  local eline = bs_encode(xline:sub(start))

  for i,v in ipairs(tokentypes) do 
    local ms, mf
    local ws, wf = eline:find("%s*", 1)
    local space = ""
    if ws then
      space = eline:sub(ws, wf)
    else
      wf = 0
    end
    ms, mf = eline:find(v[1], wf+1)
    -- print("NEXT_T:", ms, v[1], wf+1, string.sub(eline, wf+1))
    if ms and ms == wf+1 then
      -- print("NEXT_R", v[2], bs_decode(eline:sub(ms, mf)), space)
      local tok = bs_decode(eline:sub(ms, mf))
      return v[2], tok, space, start + #tok + #space
    end
  end
  return "unknown", "", "", start
end

function tok_type(t) return t[1] end
function tok_str(t) return t[2] end
function tok_indent_str(t) return t[3] end
function tok_start_next(t) return t[4] end


local same = function (t1, t2)
  for i,v in pairs(t1) do
    if not (v == t2[i]) then
      print("key " .. tostring(i) .. " mismatch: result |" .. 
          tostring(v) .. "|, expected |" .. tostring(t2[i]) .. "|")
      return false
    end
  end
  return true
end

function tt(val, start, ret) 
  local rret = { next_token(val, start) }
  if not same(rret, ret) then
    print("Failure", "#", "got", "expected")
    for i,v in ipairs(rret) do
      print("", i,v, ret[i])
    end
    return false
  end
  return true
end

function ttt(val, ...)
  local a = {...}
  local s = 1
  local t 
  for i,v in ipairs(a) do
    t = { next_token(val, s) }
    if not same(t, v) then
      return nil, "Token #".. i .. " while parsing " .. val .. " from pos " .. 
                          s .. "; substr: '" .. string.sub(val, s) .. "'"
    end
    -- print("Token:", t[1], t[2], t[3])
    -- print("Increment pos:", s, #(t[2]), #(t[3]))
    s = s + #(t[2]) + #(t[3])  
  end
  return true
end

assert(tt("0x123",       1, { "number", "0x123", "", 6 }))
assert(tt("abcd",        1, { "ident", "abcd", "", 5 }))
assert(tt(" abcd",        1, { "ident", "abcd", " ", 6 }))
assert(tt("abcd()",      1, { "ident", "abcd", "", 5 }))
assert(tt("abcd()",      5, { "open paren", "(", "", 6 }))
assert(tt("abcd()",      6, { "close paren", ")", "", 7 }))
assert(tt("abcd",        3, { "ident", "cd", "", 5 }))
assert(tt("  ,",         1, { "comma", ",", "  ", 4 }))
assert(tt(", c  );",     1, { "comma", ",", "", 2 }))
assert(tt("  abcd",      1, { "ident", "abcd", "  ", 7 }))
assert(tt("  test(a,b)", 9, { "comma", ",", "", 10 }))
assert(tt("  test(a  ,b)", 9, { "comma", ",", "  ", 12 }))

assert(tt("  'test(a  ,b)'",        1, { "char literal", "'test(a  ,b)'", "  ", 16 }))
assert(tt("  'test(a\\'  ,b)';a;b",        1, { "char literal", "'test(a\\'  ,b)'", "  ", 18 }))
assert(tt('  "test(a\\"  ,b)";a;b',        1, { "string literal", '"test(a\\"  ,b)"', "  ", 18 }))
assert(tt('  *"test(a\\"  ,b)";a;b',       1, { "operator", '*', "  ", 4 }))

assert(tt( " a+b;",       1, { "ident", 'a', " ", 3 }))
assert(ttt(" a+b;", 
           { "ident",       "a", " ", 3 },
           { "operator",    "+", "", 4 },
           { "ident",       "b", "", 5 },
           { "semicolon",   ";", "", 6 },
           { "eol",   "", "", 6 }
))

assert(ttt(" a+b  ( 'Tes;ting\\'', c  );", 
           { "ident",         "a", " ", 3 },
           { "operator",      "+", "", 4 },
           { "ident",         "b", "", 5 },
           { "open paren",    "(", "  ", 8 },
           { "char literal",  "'Tes;ting\\''", " ", 21 },
           { "comma",         ",", "", 22 },
           { "ident",         "c", " ", 24 },
           { "close paren",   ")", "  ", 27 },
           { "semicolon",     ";", "", 28 },
           { "eol",   "", "", 28 }
))

assert(ttt(" # define A(X) X+X", 
           { "hash",       "#", " ", 3 },
           { "ident",      "define", " ", 10 },
           { "ident",       "A", " ", 12 },
           { "open paren",  "(", "", 13  },
           { "ident",       "X", "", 14 },
           { "close paren", ")", "", 15 },
           { "ident",       "X", " ", 17 },
           { "operator",    "+", "", 18 },
           { "ident",       "X", "", 19 },
           { "eol",   "", "", 19 }
))


function cpp_process(astate, aline)
  local out = {}
  -- print("PROCESS", aline)
  local t_first = { next_token(aline, 1) }
  if tok_type(t_first) == "hash" then
    local t_direc = { next_token(aline, t_first) }
    assert(tok_type(t_direc) == "ident", "Expecting cpp directive")
    -- print("CPP", tok_type(t_direc), tok_str(t_direc))
    if tok_str(t_direc) == "define" then
      t_macro = { next_token(aline, t_direc) }
      print ("DEFINE", tok_str(t_macro))
    end 
  else
    -- ordinary line
    -- out = cpp_expand_macros(astate, aline, 1)
  end
end

function cpp(astate, fname)
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
        cpp_process(astate, line)
      end
    end
  end
  f:close()
end

local cpp_global_state = {
}
-- cpp("stdio.h")
cpp(cpp_global_state, "bla.h")
