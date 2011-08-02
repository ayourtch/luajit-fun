
local math,string = math,string
local print=print
local bit = require 'bit'

module "httparse"






	local to_even = function(x) return x - bit.band(x,1) end
	local shr = function(x) return bit.rshift(x,1) end
	local shl = function(x) return bit.lshift(x,1) end
function init__http_actions_0()
	return {
		[0] =     0,    1,    0,    1,    1,    1,    2,    1,    3,    1,    4,    1,
	    5,    1,    6,    1,    7,    1,    8
	};
end

local _http_actions = init__http_actions_0();


function init__http_key_offsets_0()
	return {
		[0] =     0,    0,    5,    6,    7,    8,    9,   10,   11,   20,   21,   22,
	   23,   24,   25,   26,   28,   31,   33,   36,   53,   69,   85,   88,
	   90,   93,  103,  112,  118,  124,  136,  148,  154,  160,  171,  172,
	  173,  174,  175,  176,  177,  178,  179,  180,  181,  182,  184,  185,
	  186
	};
end

local _http_key_offsets = init__http_key_offsets_0();


function init__http_trans_keys_0()
	return {
		[0] =    68,   71,   72,   79,   80,   69,   76,   69,   84,   69,   32,   42,
	   43,   47,   45,   57,   65,   90,   97,  122,   32,   72,   84,   84,
	   80,   47,   48,   57,   46,   48,   57,   48,   57,   13,   48,   57,
	   10,   13,   33,  124,  126,   35,   39,   42,   43,   45,   46,   48,
	   57,   65,   90,   94,  122,   13,   33,  124,  126,   35,   39,   42,
	   43,   45,   46,   48,   57,   65,   90,   94,  122,   33,   58,  124,
	  126,   35,   39,   42,   43,   45,   46,   48,   57,   65,   90,   94,
	  122,   10,   13,   32,   10,   13,   10,   13,   32,   43,   58,   45,
	   46,   48,   57,   65,   90,   97,  122,   32,   37,   60,   62,  127,
	    0,   31,   34,   35,   48,   57,   65,   70,   97,  102,   48,   57,
	   65,   70,   97,  102,   32,   37,   47,   59,   60,   62,   63,  127,
	    0,   31,   34,   35,   32,   37,   47,   59,   60,   62,   63,  127,
	    0,   31,   34,   35,   48,   57,   65,   70,   97,  102,   48,   57,
	   65,   70,   97,  102,   37,   47,  127,    0,   32,   34,   35,   59,
	   60,   62,   63,   69,   84,   69,   65,   68,   80,   84,   73,   79,
	   78,   83,   79,   85,   83,   10,    0
	};
end

local _http_trans_keys = init__http_trans_keys_0();


function init__http_single_lengths_0()
	return {
		[0] =     0,    5,    1,    1,    1,    1,    1,    1,    3,    1,    1,    1,
	    1,    1,    1,    0,    1,    0,    1,    5,    4,    4,    3,    2,
	    3,    2,    5,    0,    0,    8,    8,    0,    0,    3,    1,    1,
	    1,    1,    1,    1,    1,    1,    1,    1,    1,    2,    1,    1,
	    0
	};
end

local _http_single_lengths = init__http_single_lengths_0();


function init__http_range_lengths_0()
	return {
		[0] =     0,    0,    0,    0,    0,    0,    0,    0,    3,    0,    0,    0,
	    0,    0,    0,    1,    1,    1,    1,    6,    6,    6,    0,    0,
	    0,    4,    2,    3,    3,    2,    2,    3,    3,    4,    0,    0,
	    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
	    0
	};
end

local _http_range_lengths = init__http_range_lengths_0();


function init__http_index_offsets_0()
	return {
		[0] =     0,    0,    6,    8,   10,   12,   14,   16,   18,   25,   27,   29,
	   31,   33,   35,   37,   39,   42,   44,   47,   59,   70,   81,   85,
	   88,   92,   99,  107,  111,  115,  126,  137,  141,  145,  153,  155,
	  157,  159,  161,  163,  165,  167,  169,  171,  173,  175,  178,  180,
	  182
	};
end

local _http_index_offsets = init__http_index_offsets_0();


function init__http_indicies_0()
	return {
		[0] =     0,    2,    3,    4,    5,    1,    6,    1,    7,    1,    8,    1,
	    9,    1,   10,    1,   11,    1,   12,   13,   14,   13,   13,   13,
	    1,   15,    1,   16,    1,   17,    1,   18,    1,   19,    1,   20,
	    1,   21,    1,   22,   23,    1,   24,    1,   25,   26,    1,   27,
	   28,   29,   29,   29,   29,   29,   29,   29,   29,   29,    1,   28,
	   29,   29,   29,   29,   29,   29,   29,   29,   29,    1,   30,   31,
	   30,   30,   30,   30,   30,   30,   30,   30,    1,    1,    1,   33,
	   32,    1,   35,   34,    1,   35,   33,   32,   36,   37,   36,   36,
	   36,   36,    1,   15,   38,    1,    1,    1,    1,    1,   37,   39,
	   39,   39,    1,   37,   37,   37,    1,   15,   41,    1,   37,    1,
	    1,   37,    1,    1,    1,   40,   15,   41,   42,   37,    1,    1,
	   37,    1,    1,    1,   40,   43,   43,   43,    1,   40,   40,   40,
	    1,   41,    1,    1,    1,    1,    1,    1,   40,   44,    1,   10,
	    1,   45,    1,   46,    1,   10,    1,   47,    1,   48,    1,   49,
	    1,   50,    1,   51,    1,   10,    1,   52,   44,    1,   44,    1,
	   53,    1,    1,    0
	};
end

local _http_indicies = init__http_indicies_0();


function init__http_trans_targs_0()
	return {
		[0] =     2,    0,   34,   36,   39,   45,    3,    4,    5,    6,    7,    8,
	    9,   25,   29,   10,   11,   12,   13,   14,   15,   16,   17,   16,
	   18,   19,   18,   20,   47,   21,   21,   22,   23,   24,   23,   19,
	   25,   26,   27,   28,   30,   31,   33,   32,   35,   37,   38,   40,
	   41,   42,   43,   44,   46,   48
	};
end

local _http_trans_targs = init__http_trans_targs_0();


function init__http_trans_actions_0()
	return {
		[0] =     1,    0,    1,    1,    1,    1,    0,    0,    0,    0,    0,    7,
	    1,    1,    1,    9,    0,    0,    0,    0,    0,    1,    3,    0,
	    1,    5,    0,    0,   17,    1,    0,   11,   13,   13,    0,   15,
	    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
	    0,    0,    0,    0,    0,   17
	};
end

local _http_trans_actions = init__http_trans_actions_0();


local --[[ static ]] http_start = 1;
local --[[ static ]] http_first_final = 47;
local --[[ static ]] http_error = 0;

local --[[ static ]] http_en_main = 1;



function parse(data, d) 
    local p
    local pe
    local hname
    -- local data = "GET / HTTP/1.0\r\nTest: foo\r\n\r\n"
    local mark = nil
    local mark_value = nil
    p = 1
    pe = p + #data

    d = d or {}
    d.hdr = d.hdr or {}

    
    if true then -- Init code
	cs = http_start
     end -- Init code end

    
    if true then -- Exec code start
	local _klen
	local _trans = 0
	local _acts
	local _nacts
	local _keys
	local _goto_targ = 0
	local _goto_loop = true

	while _goto_loop do -- _goto
	local _continue_goto = false
if _goto_targ == 0 then
	if p == pe then
		_goto_targ = 4
		_continue_goto = true
	end
	if cs == 0 then
		_goto_targ = 5
		_continue_goto = true
	end
end -- goto_targ == 0
_goto_targ = 1 -- fallthrough emulation
if not _continue_goto and _goto_targ == 1 then -- resume
	local _break_match = false
	repeat
	_keys = _http_key_offsets[cs]
	_trans = _http_index_offsets[cs]
	_klen = _http_single_lengths[cs]
	if _klen > 0 then
		local _lower = _keys
		local _mid
		local _upper = _keys + _klen - 1
		while _upper >= _lower do
			_mid = _lower + shr(_upper-_lower)
			if string.byte(data, p, p) < _http_trans_keys[_mid] then
				_upper = _mid - 1
			elseif string.byte(data, p, p) > _http_trans_keys[_mid] then
				_lower = _mid + 1
			else
				_trans = _trans + (_mid - _keys)
				_break_match = true
				break
			end -- if/else
		end -- while _upper >= _lower
		if _break_match then break end
		_keys = _keys + _klen;
		_trans = _trans + _klen;
	end -- if _klen > 0

	_klen = _http_range_lengths[cs]
	if _klen > 0 then
		local _lower = _keys
		local _mid
		local _upper = _keys + shl(_klen) - 2
		while _upper >= _lower do
			_mid = _lower + to_even(shr(_upper-_lower))
			if string.byte(data, p, p) < _http_trans_keys[_mid] then
				_upper = _mid - 2
			elseif string.byte(data, p, p) > _http_trans_keys[_mid+1] then
				_lower = _mid + 2
			else
				_trans = _trans + shr(_mid - _keys)
				_break_match = true
				break
			end -- if-then
		end -- while _upper >= _lower
		if _break_match then break end
		_trans = _trans + _klen
	end -- if _klen > 0
	until true

	_trans = _http_indicies[_trans]
	cs = _http_trans_targs[_trans]

	if _http_trans_actions[_trans] ~= 0 then
		_acts = _http_trans_actions[_trans]
		_nacts = _http_actions[_acts]
		_acts = _acts + 1
		while _nacts > 0 do
			_nacts = _nacts - 1
			local _curr_act = _http_actions[_acts]
			_acts = _acts + 1
			if false then -- action switch
			elseif _curr_act == 0 then
--# line 11 "httparse.rl"
			if true then --[[ action ]]  mark = p 	end -- [[ action ]] 
			elseif _curr_act == 1 then
--# line 12 "httparse.rl"
			if true then --[[ action ]]  	end -- [[ action ]] 
			elseif _curr_act == 2 then
--# line 13 "httparse.rl"
			if true then --[[ action ]]  	end -- [[ action ]] 
			elseif _curr_act == 3 then
--# line 14 "httparse.rl"
			if true then --[[ action ]]  d.method = string.sub(data, mark, p-1) 	end -- [[ action ]] 
			elseif _curr_act == 4 then
--# line 15 "httparse.rl"
			if true then --[[ action ]]  d.uri = string.sub(data, mark, p-1) 	end -- [[ action ]] 
			elseif _curr_act == 5 then
--# line 16 "httparse.rl"
			if true then --[[ action ]]  hname = string.sub(data, mark, p-1) 	end -- [[ action ]] 
			elseif _curr_act == 6 then
--# line 17 "httparse.rl"
			if true then --[[ action ]]  mark_value = p 	end -- [[ action ]] 
			elseif _curr_act == 7 then
--# line 18 "httparse.rl"
			if true then --[[ action ]]  
  if not d.hdr[hname] then 
    d.hdr[hname] = string.sub(data, mark_value, p-1) 
  else
    d.hdr[hname] = { d.hdr[hname], string.sub(data, mark_value, p-1) }
  end
	end -- [[ action ]] 
			elseif _curr_act == 8 then
--# line 129 "httparse.rl"
			if true then --[[ action ]]  parser_done = true 	end -- [[ action ]] 
--# line 296 "httparse.lua"
			end -- action switch
		end -- while _nacts > 0
		_nacts = _nacts - 1 -- artifact
	end -- if ta[_trans] != 0

    _goto_targ = 2 -- fallthrough emulation
    if not _continue_goto and _goto_targ == 2 then --again
	if cs == 0 then
		_goto_targ = 5
		_continue_goto = true
	end
	p = p + 1
	if p ~= pe then
		_goto_targ = 1
		_continue_goto = true
	end
    end
    _goto_targ = 4 -- fallthrough imitation
    if not _continue_goto and _goto_targ == 4 then -- test_eof
    end
    _goto_targ = 5 -- fallthrough simulation
    if not _continue_goto and _goto_targ == 5 then -- out
    end
	end -- if-then-else for _goto_targ
        if not _continue_goto then
	    _goto_loop = false
        end -- reset goto-loop
        end -- while-goto
	end -- execute block end


    return d
end

