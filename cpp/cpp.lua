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
  { "[0-9]+L?", "number" },
  { "[a-zA-Z$_][a-zA-Z_$0-9]*", "ident" },
  { "[+][+]", "plus plus" },
  { "[-][-]", "minus minus" },
  { "[|][|]", "infix-op" },
  { "[=][=]", "infix-op" },
  { "[|][=]", "infix-op" },
  { "[&][=]", "infix-op" },
  { "[+][=]", "infix-op" },
  { "[-][=]", "infix-op" },
  { "[*][=]", "infix-op" },
  { "[(]", "open paren" },
  { "[)]", "close paren" },
  { "[%[]", "open bracket" },
  { "[%]]", "close bracket" },
  { "[{]", "open brace" },
  { "[}]", "close brace" },
  { "[<][=]", "infix-op" },
  { "[>][=]", "infix-op" },
  { "[<]", "infix-op" },
  { "[>]", "infix-op" },
  { "[,]", "comma" },
  { "[#]", "hash" },
  { "%%:", "hash" }, -- digraph
  { "[;]", "semicolon" },
  { "$", "eol" },
  { "[!]", "prefix-op" },
  { "[~]", "prefix-op" },
  { "[%%]", "infix-op" },
  { "[&][&]", "infix-op" },
  { "[+-/*&|=^]", "infix-op" },
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
  -- print("NEXT_U", "|"..xline:sub(start).."|")

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
assert(tt('  *"test(a\\"  ,b)";a;b',       1, { "infix-op", '*', "  ", 4 }))

assert(tt( " a+b;",       1, { "ident", 'a', " ", 3 }))
assert(ttt(" a+b;", 
           { "ident",       "a", " ", 3 },
           { "infix-op",    "+", "", 4 },
           { "ident",       "b", "", 5 },
           { "semicolon",   ";", "", 6 },
           { "eol",   "", "", 6 }
))

assert(ttt(" a+b  ( 'Tes;ting\\'', c  );", 
           { "ident",         "a", " ", 3 },
           { "infix-op",      "+", "", 4 },
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
           { "infix-op",    "+", "", 18 },
           { "ident",       "X", "", 19 },
           { "eol",   "", "", 19 }
))


function tokens2str(tokens)
  local out = {}
  for i,t in ipairs(tokens) do
    table.insert(out, tok_indent_str(t))
    table.insert(out, tok_str(t))
  end
  return table.concat(out, "") 
end

-- process and expand a single token if needed
-- do the necessary walk-ahead too (function args, etc.)
-- return the next unprocessed token #

local process_token

function process_token_real(astate, out_tokens, in_tokens, i, indent, is_inner, level)
  local tok = in_tokens[i]
  local typ = tok_type(tok)
  if not level then level = 0 end
  -- print("ProcessToken", tok_str(tok), typ, i, level)
  -- if we are processing the arguments, exit immediately upon hitting the comma
  if typ == "comma" and is_inner then
    return i
  end
  -- the token is an argument of the macro - expand according to the current
  -- macro that is being executed
  if typ == "macro_arg" then
    local get_arg_value
    local get_arg_value_real = function(astate, level, nam)
      local margs = astate.margs[level]
      local mname = astate.mcall[level]
      local m = astate.macros[mname]
      -- print("ARGVALUE: Getting arg value for level", level, " arg name ", nam, res, mname)
      local res = margs[m.iarg[nam]]  
      if not res and level > 1 then 
        res = get_arg_value(astate, level-1, nam)
      end
      return res
    end
    get_arg_value = get_arg_value_real
    local ix = 1
    local nam = tok_str(tok)
    -- print("SUBST0:", nam, is_inner)
    local ichain = get_arg_value(astate, #(astate.margs), nam) -- margs[m.iarg[nam]]
    -- pre-expand the arg based on the upper level macros
    if is_inner then
      ichain = get_arg_value(astate, #(astate.margs)-1, nam)
    end
    -- print("SUBST:", i, ichain)
    -- print("====>", tokens2str({ tok }), tokens2str(ichain), i)
    ichain[1][3] = tok[3]

    while ix <= #ichain do
      ix = process_token(astate, out_tokens, ichain, ix, tok_indent_str(tok), false, level+1)
    end
    return i+1 
  elseif typ == "ident" then
    local m = astate.macros[tok_str(tok)]
    if m and ((not m.nargs) or (m.nargs and tok_type(in_tokens[i+1]) == "open paren")) then
      -- print("MACRO", m.name, tokens2str(m.body))
      if not m.nargs then
        -- non-parametrized macro
        local ib = 1
        while ib <= #m.body do
          ib = process_token(astate, out_tokens, m.body, ib, false, level+1)
        end
        return i+1
      else
        -- parametrized macro
        local out = {}
        local margs = { }
        local marg = {}
        i = i+2 -- skip the open paren
        astate.margs[1+#(astate.margs)] = margs
        astate.mcall[1+#(astate.mcall)] = m.name
        -- collect the arguments for the macro
        while in_tokens[i] and not (tok_type(in_tokens[i]) == "close paren") do
          -- print("Get argument", 1+#margs)
          i = process_token(astate, marg, in_tokens, i, 0, true, level+1)
          margs[1+#margs] = marg
          -- print("Argument ", #margs, tokens2str(marg), level)
          marg = {}
          if not (tok_type(in_tokens[i]) == "close paren") then
            i = i + 1
          end
        end
        -- print("Collected args, i=", i, "#marg", #marg)
        if #marg > 0 then
          margs[1+#margs] = marg
        end
        
        local ib = 1
        -- print("Expanding", tokens2str(m.body), m.name)
        while ib <= #m.body do
          ib = process_token(astate, out_tokens, m.body, ib, 0, false, level+1)
        end
        -- print("CANCEL ", #(astate.margs), astate.mcall[#(astate.mcall)])
        astate.margs[#(astate.margs)] = nil
        astate.mcall[#(astate.mcall)] = nil
        return i+1
      end
    else
      table.insert(out_tokens, tok)
      return i+1
    end
  else
    table.insert(out_tokens, tok)
    return i+1
  end
end


-- process_token fixes up the indentation
process_token = function(astate, out_tokens, in_tokens, i, indent, inner, level)
  local old_indent = tok_indent_str(in_tokens[i])
  local old_i = i
  local old_j = #out_tokens + 1
  local ret = process_token_real(astate, out_tokens, in_tokens, i, indent, inner, level)
  out_tokens[old_j][3] = old_indent
  return ret
end

-- walk all the tokens, expanding as needed, from state
function process_tokens(astate, out_tokens, in_tokens, start) 
  local i = 1
  while i <= #in_tokens do
    i = process_token(astate, out_tokens, in_tokens, i)
  end
  return i
end

function string2tokens(aline, astart)
  local tokens = {}
  local t = astart
  local gettoken = function() 
    t = { next_token(aline, t) }
    -- print("T:", t[1], t[2], t[3], t[4])
    return (not (tok_type(t) == "eol"))
  end
  while gettoken() do
    table.insert(tokens, t)
  end
  table.insert(tokens, t) -- insert eol token
  return tokens
end

function macro_undef(astate, aname)
  astate.macros[aname] = nil
end

-- defines "function-like" macro
-- the start is the next token after the open paren
function macro_define_func(astate, mname, tokens, start)
  local m = { name = mname, nargs = 0, iarg = {}, body = {} }
  local arg_n = 1
  local token_idx = start
  local arg_start = start

  -- assign the numbers for the symbolic arguments
  while not ( tok_type(tokens[token_idx]) == "close paren" ) do
    -- print("ARG:", token_idx)
    assert(tok_type(tokens[token_idx]) == "ident", tok_type(tokens[token_idx]) .. " unexpected")
    m.nargs = m.nargs + 1
    m.iarg[tok_str(tokens[token_idx])] = m.nargs
    token_idx = token_idx + 1
    if not ( tok_type(tokens[token_idx]) == "close paren" ) then
      assert(tok_type(tokens[token_idx]) == "comma", tok_type(tokens[token_idx]))
      token_idx = token_idx + 1
    end
  end

  -- move past closing paren
  token_idx = token_idx + 1

  -- write the body
  while not ( tok_type(tokens[token_idx]) == "eol" ) do
    local tok = tokens[token_idx]
    local aname = tok_str(tok)
    local t = { tok_type(tok), aname, tok_indent_str(tok), 0 }
    if tok_type(tok) == "ident" then
      if m.iarg[aname] then
        -- make a magic token that will grab the argument
        t[1] = "macro_arg" 
        table.insert(m.body, t)
      else
        table.insert(m.body, t)
      end
    else
      table.insert(m.body, t)
    end
    token_idx = token_idx + 1
  end
  -- insert EOL too
  table.insert(m.body, tokens[token_idx])
  
  astate.macros[mname] = m
end

-- defines "argument-less" macro
-- if there is no expansion (eol) - create empty expansion.
function macro_define_macro(astate, mname, tokens, start)
  local m = { name = mname, nargs = nil, body = {} }
  local token_idx = start

  -- write the body
  local first_token = true
  while not ( tok_type(tokens[token_idx]) == "eol" ) do
    local tok = tokens[token_idx]
    local t = { tok_type(tok), tok_str(tok), tok_indent_str(tok), 0 }
    table.insert(m.body, t)
    token_idx = token_idx + 1
  end
  -- insert EOL too
  table.insert(m.body, tokens[token_idx])

  astate.macros[mname] = m
end


function cpp_try_fire(astate, cond)
  if not astate.mmute[#astate.mmute] then
    astate.memit[#astate.memit] = false
    if not astate.mfired[#astate.mfired] then
      astate.memit[#astate.memit] = cond
      astate.mfired[#astate.mfired] = cond
    end
  end
end

function cpp_push(astate)
  -- if it was muted, stay muted
  astate.mmute[1+#astate.mmute] = astate.mmute[#astate.mmute]
  -- nothing fired at this level yet
  astate.mfired[1+#astate.mfired] = false
  -- emit by default
  astate.memit[1+#astate.memit] = true
end

function cpp_pop(astate)
  assert(#astate.mmute > 1)
  astate.mmute[#astate.mmute] = nil
  astate.mfired[#astate.mfired] = nil
  astate.memit[#astate.memit] = nil
end

function cpp_push_try_fire(astate, cond)
  cpp_push(astate)
  cpp_try_fire(astate, cond)
end

function is_macro_defined(astate, name)
  local cond = not (astate.macros[name] == nil)
  -- print("COND", name, cond)
  return cond
end

-- FIXME FIXME FIXME FIXME

function evaluate_expr(astate, all_tokens, start)
  -- a shunting yard algorithm 
  local res = 0
  local ops = {}
  local vals = {}

  -- boolean to number
  local b2n = function(x) if x then return 1 else return 0 end end

  local prec = {
    ["*"] = { 100, function(a,b) return a*b end },
    ["%"] = { 100, function(a,b) return a%b end },
    ["/"] = { 100, function(a,b) return a/b end },

    ["-"] = { 90, function(a,b) return a-b end },
    ["+"] = { 90, function(a,b) return a+b end },

    [">>"] = { 80, function(a,b) return bit.rshift(a,b) end },
    ["<<"] = { 80, function(a,b) return bit.lshift(a,b) end },

    ["<"] = { 70, function(a,b) return b2n(a<b) end },
    [">"] = { 70, function(a,b) return b2n((a) and (a>b)) end },
    ["<="] = { 70, function(a,b) return b2n(a<=b) end },
    [">="] = { 70, function(a,b) return b2n((a) or (not b) and (a>=b)) end },

    ["=="] = { 60, function(a,b) return b2n(a == b) end },
    ["!="] = { 60, function(a,b) return b2n(not (a == b)) end },

    ["&"] = { 50, function(a,b) return bit.band(a,b) end },
    ["^"] = { 40, function(a,b) return bit.bxor(a,b) end },
    ["|"] = { 30, function(a,b) return bit.bor(a,b) end },
    ["&&"] = { 20, function(a,b) return b2n(a and b) end },
    ["||"] = { 10, function(a,b) return b2n(a or b) end },
    ["("] = { 0, nil }
  }

  local getprec = function(v)
    if v then
      -- print("GETPREC", tok_str(v), tok_type(v))
      if tok_type(v) == "infix-op" then
        if not prec[v[2]] then print(tok_str(v)) end
        assert(prec[v[2]])
        return prec[v[2]][1]
      elseif tok_str(v) == "defined" then
        return 120
      elseif prec[v[2]] then
        return prec[v[2]][1]
      end
    else
      return 0
    end
  end

  local infix_op = function(v, a, b)
    -- a_r and b_r are the 'real' values to operate with.
    -- because we store tokens on stack. For better or worse
    local a_r, b_r, res
    local tonum = function(n)
      if string.match(n, "[0-9]+L") then
        n = string.sub(n, 1, -2)
        print("TADA", n)
      end
      n = tonumber(n)
      if not n then n = 0 end
      return n
    end
    a_r = tonum(tok_str(a))
    b_r = tonum(tok_str(b))
    assert(v)
    assert(prec[v[2]])
    res = prec[v[2]][2](a_r,b_r)
    return res
  end

  local d = function(msg, v)
    if false then
      if type(v) == "table" then
        print(msg, v[1], v[2], v[3], v[4])
      else
        print(msg, v)
      end
    end
  end

  local is_value = function(t)
    local typ = tok_type(t)
    local is_val = false
    if typ == "number" then
      is_val = true
    elseif tok_type(t) == "ident" and (not (tok_str(t) == "defined")) then
      is_val = true
    end
    return is_val
  end

  local push_value = function(t)
    vals[1+#vals] = t
  end

  local pop_value = function()
    local v = vals[#vals]
    vals[#vals] = nil
    return v
  end

  local opstackpush = function(t)
    ops[1+#ops] = t
  end

  local opstackpop = function()
    local t = ops[#ops]
    ops[#ops] = nil
    return t
  end

  local opstacktop = function()
    return ops[#ops]
  end

  local is_infix = function(t)
    local typ = tok_type(t)
    return typ == "infix-op"
  end

  local make_num = function(n)
    local v = { "number", tostring(n), -1 }
    return v
  end

  local calc = function(v)
    local v1, v2, v3
    if tok_type(v) == "infix-op" then
      v1 = pop_value()
      v2 = pop_value()
      push_value(make_num(infix_op(v, v2, v1)))
    elseif tok_str(v) == "defined" then
      local res
      v1 = pop_value()
      -- print("Checking", v1)
      if is_macro_defined(astate, tok_str(v1)) then
        res = 1
      else
        res = 0 
      end
      push_value(make_num(res))
    end
  end

  for i = start, #all_tokens do
    local v = all_tokens[i]
    -- print(i, v[1], v[2], v[3], v[4])
    if is_value(v) then
      push_value(v)
    elseif tok_str(v) == "defined" then
      -- unary 'defined' predicate
      -- print("DEFINED")
      opstackpush(v)
    elseif tok_type(v) == "open paren" then
      -- don't do any calculations on stack - 
      -- first calculate the stuff in parens
      opstackpush(v)
    elseif tok_type(v) == "close paren" then
      -- do the pending calculations from stack
      while not ("open paren" == tok_type(opstacktop())) do
        calc(opstackpop())
      end
      opstackpop(astate) -- pop the open paren
    elseif is_infix(v) then
      local currprec = getprec(v)
      while currprec <= getprec(opstacktop()) do
        calc(opstackpop(astate))
      end
      opstackpush(v)
    end
  end
  while(opstacktop()) do
    calc(opstackpop(astate))
  end
  print("VALS:", #vals)
  if #vals > 1 then
    for i,v in ipairs(vals) do
      print(i,tok_str(v))
    end
  end
  assert(#vals == 1)
  res = vals[#vals]
  -- print("EVAL result:", res) 
  res = not (tonumber(tok_str(res)) == 0)
  return res
end

local cpp_helper 

function cpp_process(astate, aline)
  local out = {}
  print("PROCESS", aline)
  local all_tokens = string2tokens(aline, 1)
  local t_first = all_tokens[1]
  if tok_type(t_first) == "hash" then
    local t_direc = all_tokens[2]
    local t_mname = all_tokens[3]
    assert(tok_type(t_direc) == "ident", "Expecting cpp directive")
    -- print("CPP", tok_type(t_direc), tok_str(t_direc))
    if tok_str(t_direc) == "define" then
      local t_mstart = all_tokens[4]
      if t_mstart and tok_type(t_mstart) == "open paren" and tok_indent_str(t_mstart) == "" then
        -- print ("DEFINE_FUNC", tok_str(t_mname), aline)
        macro_define_func(astate, tok_str(t_mname), all_tokens, 5)
      else
        -- print ("DEFINE_MACRO", tok_str(t_mname), aline)
        macro_define_macro(astate, tok_str(t_mname), all_tokens, 4)
      end
      
    elseif tok_str(t_direc) == "undef" then
      local t_mname = { next_token(aline, t_direc) }
      assert(tok_type(t_mname) == "ident", "Expected name to undef")
      macro_undef(astate, tok_str(t_mname))
    elseif tok_str(t_direc) == "if" then
      cond = evaluate_expr(astate, all_tokens, 3) 
      cpp_push_try_fire(astate, cond)
    elseif tok_str(t_direc) == "else" then
      assert(#astate.memit > 1, "stray else")
      cpp_try_fire(astate, true)
    elseif tok_str(t_direc) == "elif" then
      assert(#astate.memit > 1, "stray elif")
      cond = evaluate_expr(astate, all_tokens, 3) 
      cpp_try_fire(astate, cond)
    elseif tok_str(t_direc) == "endif" then
      cpp_pop(astate)
    elseif tok_str(t_direc) == "ifdef" then
      cond = not (astate.macros[tok_str(t_mname)] == nil)
      cpp_push_try_fire(astate, cond)
      assert(#astate.memit > 1, "ifdef: internal error")
    elseif tok_str(t_direc) == "ifndef" then
      cond = (astate.macros[tok_str(t_mname)] == nil)
      cpp_push_try_fire(astate, cond)
    elseif tok_str(t_direc) == "include" then
      local t_paren = { next_token(aline, t_direc) }
      local t_fname = { next_token(aline, t_paren) }
      local fname = tok_str(t_fname)
      if tok_str(t_paren) == "<" then
        while true do
          t_fname = { next_token(aline, t_fname) }
          if tok_str(t_fname) == ">" then break end
          fname = fname .. tok_str(t_fname)
        end
        fname = fname_expand(fname)
      end  
      print("INCLUDE:", fname)
      cpp(astate, fname)
    else 
      print("ERR:", tok_str(t_direc))
    end 
  else
    -- ordinary line 
    if astate.memit[#astate.memit] and not astate.mmute[#astate.mmute] then
      local out_tokens = {}
      process_tokens(astate, out_tokens, all_tokens, 1) 
      astate.print(tokens2str(out_tokens))
    end
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

cpp_helper = cpp

local cpp_global_state = {
  print = print,
  macros = {},
  margs = {},
  mcall = {},
  memit = { true }, --  stack of booleans that talk whether to pass the input to output or not (memit = condition of if/ifdef)
  mmute = { false }, -- whether the output is muted by upper-layer conditionals ( mute = mute(parent) or not memit(parent) )
  mfired = { false }, -- whether the #if/else like conditional has fired previously
}

-- cpp("stdio.h")
-- cpp(cpp_global_state, "bla.h")
-- cpp(cpp_global_state, "bla1.h")
cpp(cpp_global_state, "/usr/include/stdio.h")
-- cpp(cpp_global_state, "/usr/include/sys/stat.h")
-- cpp(cpp_global_state, "/usr/include/unistd.h")
