local math,string = math,string
local print=print

module "httparse"


%%{
machine http;

action mark { mark = fpc }
action http_version_major { }
action http_version_minor { }
action http_method { d.method = string.sub(data, mark, fpc) }
action http_uri { d.uri = string.sub(data, mark, fpc) }
action http_header_name { hname = string.sub(data, mark, fpc) }
action mark_value { mark_value = fpc }
action http_header_value { 
  if not d.hdr[hname] then 
    d.hdr[hname] = string.sub(data, mark_value, fpc) 
  else
    d.hdr[hname] = { d.hdr[hname], string.sub(data, mark_value, fpc) }
  end
} 




htp_octet = (any);
htp_char = (ascii);
htp_upalpha = (upper);
htp_loalpha = (lower);
htp_alpha = (htp_loalpha | htp_upalpha);
htp_digit = (digit);
htp_ctl = (cntrl | 127);
htp_cr = ( 13 );
htp_lf = ( 10 );
htp_sp = ( ' ' );
htp_ht = ( 9 );
htp_quote = ( '"' );

htp_crlf = ( htp_cr htp_lf? ); # // Accomodate for unix NLs ?
# htp_crlf = ( htp_cr htp_lf ); # // do NOT accomodate for unix NLs ?

htp_lws = ( htp_crlf? (htp_sp | htp_ht)+ ); 

htp_not_ctl = (htp_octet - htp_ctl);

htp_text = (htp_not_ctl | htp_lws); # (htp_cr | htp_lf | htp_sp | htp_ht));

htp_hex = (xdigit);

htp_tspecials = (
    '(' | ')' | '<' | '>' | '@' |
    ',' | ';' | ':' | '\\' | htp_quote |
    '/' | '[' | ']' | '?' | '=' |
    '{' | '}' | htp_sp | htp_ht);

htp_token_char = ((htp_char - htp_tspecials) - htp_ctl);
htp_token = (htp_token_char+);

# comments not supported yet - they require a sub-machine
# htp_comment_char = htp_text - ('(' | ')');
# htp_comment = ( '(' (htp_comment_char+ | htp_comment) ')' );

htp_quoted_char = (htp_text - '"');
htp_quoted_string = ( '"' htp_quoted_char* '"' );

htp_quoted_pair = '\\' htp_char;

htp_http_ver_major = htp_digit+ >mark %http_version_major;
htp_http_ver_minor = htp_digit+ >mark %http_version_minor;

htp_http_version = ("HTTP" "/" htp_http_ver_major "." htp_http_ver_minor);

htp_escape = ('%' htp_hex htp_hex);
htp_reserved = (';' | '/' | '?' | ':' | '@' | '&' | '=' | '+');
htp_extra = ('!' | '*' | '\'' | '(' | ')' | ',');
htp_safe = ('$' | '-' | '_' | '.');
htp_unsafe = (htp_ctl | htp_sp | htp_quote | '#' | '%' | '<' | '>');
htp_national = (htp_octet - (htp_alpha | htp_digit | htp_reserved | htp_extra | htp_safe | htp_unsafe));

htp_unreserved = (htp_alpha | htp_digit | htp_safe | htp_extra | htp_national);
htp_uchar = (htp_unreserved | htp_escape);
htp_pchar = (htp_uchar | ':' | '@' | '&' | '=' | '+');

htp_fragment = ( (htp_uchar | htp_reserved)* );
htp_query = ( (htp_uchar | htp_reserved)* );

htp_net_loc = ( (htp_pchar | ';' | '?' )* );
htp_scheme = ( (htp_alpha | htp_digit | '+' | '-' | '.')+ );

htp_param = ( (htp_pchar | '/')* );
htp_params = (htp_param (';' htp_param)* ); 

htp_segment = (htp_pchar*);
htp_fsegment = (htp_pchar+);
htp_path = (htp_fsegment ('/' htp_fsegment)*);

htp_rel_path = ( htp_path? (';' htp_params)? ('?' htp_query)? );
htp_abs_path = ('/' htp_rel_path);
htp_net_path = ("//" htp_net_loc htp_abs_path?);

htp_relative_uri = (htp_net_path | htp_abs_path | htp_rel_path);
htp_absolute_uri = (htp_scheme ':' (htp_uchar | htp_reserved)*);
htp_uri = ((htp_absolute_uri | htp_relative_uri) ('#' htp_fragment)?);

htp_host = (htp_alpha);
htp_port = (htp_digit+);

htp_http_url = ("http://" htp_host (':' htp_port)? (htp_abs_path)?);

htp_method = ("OPTIONS" | "GET" | "HEAD" | "POST" | "PUT" | "DELETE") >mark %http_method;


htp_request_uri = ('*' | htp_absolute_uri | htp_abs_path) >mark %http_uri;

htp_request_line = (htp_method htp_sp htp_request_uri htp_sp htp_http_version htp_crlf);

htp_header_name = htp_token+ >mark %http_header_name;
# fixme.
htp_header_value_char = htp_octet - htp_cr - htp_lf;
htp_header_value = htp_header_value_char+ >mark_value %http_header_value;

htp_some_header = (htp_header_name ':' htp_sp* htp_header_value htp_crlf);
htp_last_crlf = htp_crlf; #  >{ printf("Last CRLF!\n"); eof = pe; };
htp_request = htp_request_line (htp_some_header)* htp_last_crlf;

main := (htp_request) @{ parser_done = true };

}%%

%%write data;

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

    %%write init;
    %%write exec;

    return d
end

