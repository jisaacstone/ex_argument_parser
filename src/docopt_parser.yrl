Header "%% Parser for docopt style options"
"%% http://docopt.org/"
"".


Nonterminals docopt usage_block usage_line usage_lines
elements element
option_blocks option_block option_lines option_line opt_start words
flagopts short long argname.


Terminals usage_start option_start
'[' ']' '(' ')' '|' '=' ellipses eol
description long_flag short_flag word argument long_dash short_dash.


Rootsymbol docopt.


Nonassoc 100 '='.
Right 200 '|'.
Unary 300 ellipses.


docopt -> usage_block : {'$1', []}.
docopt -> usage_block option_blocks : {'$1', '$2'}.

usage_block -> usage_start usage_lines : '$2'.
usage_block -> usage_start eol usage_lines : '$3'.

usage_lines -> usage_line : ['$1'].
usage_lines -> usage_line usage_lines : ['$1'|'$2'].

usage_line -> word elements eol : ['$1'|'$2'].

elements -> element : ['$1'].
elements -> element elements : ['$1'|'$2'].

element -> short_flag       : '$1'.
element -> long_flag        : '$1'.
element -> argname          : '$1'.
element -> short_dash       : '$1'.
element -> long_dash        : '$1'.
element -> '(' elements ')' : {required, '$2'}.
element -> '[' elements ']' : {optional, '$2'}.
element -> element '|' element  : {choice, ['$1'|'$3']}.
element -> element ellipses : {ellipses, '$1'}.

option_blocks -> option_block : ['$1'].
option_blocks -> option_block option_blocks : ['$1'|'$2'].

option_block -> opt_start option_lines : '$2'.
option_lines -> option_line : ['$1'].
option_lines -> option_line option_lines : ['$1'|'$2'].

option_line -> flagopts : {'$1', nil, nil}.
option_line -> flagopts description : {'$1', '$2', parse_default('$2')}.

opt_start -> option_start : nil.
opt_start -> option_start eol : nil.
opt_start -> words option_start : nil.
opt_start -> words option_start eol : nil.

words -> word : nil.
words -> word words : nil.

flagopts -> short      : {'$1', nil}.
flagopts -> long       : {nil, '$1'}.
flagopts -> short long : {'$1', '$2'}.

short -> short_flag         : '$1'.
short -> short_flag argname : {'$1', '$2'}.

long -> long_flag           : '$1'.
long -> long_flag argname   : {'$1', '$2'}.

argname -> word         : to_atom('$1').
argname -> argument     : to_atom('$1').
argname -> '=' word     : to_atom('$2').
argname -> '=' argument : to_atom('$2').


Erlang code.

to_atom({_, _, Chars}) when is_list(Chars) -> list_to_atom(Chars);
to_atom(Other) -> io:fwrite("~p~n", [Other]), Other.

parse_default(String) ->
  case re:run(String, "\\[default: ([^\\]]+)\\]", [{capture, [1], list}]) of
    {match, M} -> M;
    nomatch    -> nil
  end.
