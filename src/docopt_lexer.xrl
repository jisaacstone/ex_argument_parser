Definitions.
W  = [a-zA-Z0-9_](([a-zA-Z0-9_][a-zA-Z0-9_.-]*)?[a-zA-Z0-9_?!-])?
S  = [\s\t]
%% DL = ^[^\s\t:-]+[^:].*$

Rules.

Usage:           : {token,{usage_start,TokenLine}}.
Options:         : {token,{options_start,TokenLine}}.
%% {DL}             : {token,{docline,TokenLine,TokenChars}}.
{S}*[\r\n]+{S}*  : {token,{eol,TokenLine}}.
[()[\]|=.]       : {token,{list_to_atom(TokenChars),TokenLine}}.
\.\.\.           : {token,{ellipses,TokenLine}}.
<{W}+>           : {token,{argument,TokenLine,mid(TokenChars,TokenLen)}}.
--{W}            : {token,{long_flag,TokenLine,tl(tl(TokenChars))}}.
-{W}             : {token,{short_flag,TokenLine,tl(TokenChars)}}.
{S}--{S}         : {token,{long_dash,TokenLine}}.
{S}-{S}          : {token,{short_dash,TokenLine}}.
{W}              : {token,{word,TokenLine,TokenChars}}.
{S}{S}+[^\r\n]+  : {token,{description,TokenLine,lstrip(TokenChars)}}.
,?{S}            : skip_token.

Erlang code.

mid(TokenChars,TokenLen) -> 
    lists:sublist(TokenChars, 2, TokenLen - 2).

lstrip([$\s|T]) -> lstrip(T);
lstrip([$\t|T]) -> lstrip(T);
lstrip(L) -> L.
