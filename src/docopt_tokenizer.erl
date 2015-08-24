-module(docopt_tokenizer).
-export([tokenize/1]).

tokenize(String) when is_list(String) -> tokenize(list_to_binary(String));
tokenize(Bin) when is_binary(Bin) ->
    {UStart, Line0} = skipto(Bin, comp("^(usage:\\s*)"), 0),
    {Tokens, Rest, Line1} = extract_usage(UStart, Line0),
    Tokens ++ extract_options(Rest, Line1).

comp(S) -> comp(S, []).
comp(S, Opts) ->
    {ok, R} = re:compile(S,
        [unicode, caseless, multiline, {newline, any}] ++ Opts),
    R.

newline() -> "$.?.?^".

skipto(String, Pattern, Line) ->
    case re:run(String, Pattern) of
        nomatch ->
            {"", Line};
        {match, [{_,End}|_]} ->
            {binary_part(String,End,byte_size(String)-End),
             Line + numlines(binary_part(String,0,End))}
    end.

numlines(S) ->
    case re:run(S, comp(newline(), [dotall])) of
        {match, TL} -> length(TL);
        nomatch     -> 0
    end.

extract_usage(String, Line) ->
    {W, _} = next_word(String),
    extract_usage(String,Line,W).

next_word(S) ->
    case re:split(S, "\\s+", [{parts, 2}]) of
        [_] -> {error, eof};
        [Word, Rest] -> {Word, Rest}
    end.

extract_usage(String, Line, Word) ->
    R = comp("^\\s*" ++ binary_to_list(Word) ++ "\\s*"),
    tokenize_usage(tl(re:split(String, R)), [], Line, Word).

tokenize_usage([Rest], Usage, Line, _Word) ->
    {Usage, Rest, Line};
tokenize_usage([H|T], Usage, Line, Word) ->
    Tokens = Usage ++ tokenize_usage_line(H, Line, Word),
    tokenize_usage(T, Tokens, Line + 1, Word).

tokenize_usage_line(String, Line, Word) ->
    [{usage, Line, Word}|tokenize_line(String, Line)].

extract_options(String, Line) ->
    extract_options(re:split(String, comp(newline(), [dotall])), [], Line).

extract_options([<<>>|T], Tokens, Line) ->
    extract_options(T, Tokens, Line);
extract_options([], Tokens, _) ->
    Tokens;
extract_options([<<$-,_/binary>>=H|T], Tokens, Line) ->
    extract_options(T, Tokens ++ extract_option_line(H, Line), Line + 1);
extract_options([H|T], Tokens, Line) ->
    case re:run(H, "^\\s+") of
        {match, [{0,E}]} when E == byte_size(H) ->
            extract_options(T, Tokens, Line + numlines(H));
        {match, [{0,E}]} ->
            extract_options([binary_part(H,E,byte_size(H)-E)|T], Tokens, Line);
        nomatch ->
            case re:split(H, comp("options:"), [{parts, 2}]) of
                [_,R] -> extract_options([R|T], Tokens, Line);
                _     -> Tokens
            end
    end.

extract_option_line(Bin, Line) ->
    case re:split(Bin, comp("\\s\\s+"), [{parts, 2}]) of
        [Bin]     -> tokenize_line(Bin, Line);
        [B, Desc] -> tokenize_line(B, Line) ++ maybe_default(Desc, Line)
    end.

maybe_default(Desc, Line) ->
  case re:run(Desc, "\\[default: ([^\\]]+)\\]", [{capture, [1], list}]) of
      {match, M} -> [{default, Line, M}];
      nomatch    -> []
  end.

tokenize_line(String, Line) ->
    {ok, R} = re:compile("\\s+|([()[\\]|]|\\.\\.\\.)"),
    lists:foldr(fun(P, T) -> token(P, Line) ++ T end,
                [{eol, Line}],
                re:split(String, R, [{return, binary}])).

token(<<>>, _) -> [];
token(T, L) when T==<<"(">>; T==<<")">>; T==<<"[">>; T==<<"]">>;
                 T==<<"|">>; T==<<"...">> -> 
    [{binary_to_atom(T, utf8), L}];
token(<<$<,_/binary>>=B, L) ->
    case binary:last(B) of
        $> -> [{argument,L,B}];
        _  -> {error, {B,L}}
    end;
token(<<$-,$-,Rest/binary>>, L) ->
    flag_maybe_arg(long_flag, L, Rest);
token(<<$-,Rest/binary>>, L) ->
    flag_maybe_arg(short_flag, L, Rest);
token(B, L) ->
    case re:run(B, "^[^a-z]*[A-Z][^a-z]*$") of
        {match, _} -> [{argument,L,B}];
        nomatch    -> [{word,L,B}]
    end.

flag_maybe_arg(FlagName, L, Bin) ->
    case re:split(Bin, "=", [{return, binary}]) of
        [Flg, Arg] -> [{FlagName,L,binary_to_atom(Flg,utf8)},
                       {argument,L,Arg}];
        [Bin]      -> [{FlagName,L,binary_to_atom(Bin,utf8)}];
        _          -> {error,{Bin,L}}
    end.
