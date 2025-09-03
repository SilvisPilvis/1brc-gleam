-module(stream_binary).
-export([open/1, read/2, close/1]).

%% open(Path :: string()) -> {ok, IoDevice} | {error, Reason}
open(Path) -> file:open(Path, [read, binary]).

%% read(IoDevice, Size :: non_neg_integer()) -> {ok, Data :: binary()} | {error, Reason}
read(IoDevice, Size) -> file:read(IoDevice, Size).

%% close(IoDevice) -> ok | {error, Reason}
close(IoDevice) -> 
    case file:close(IoDevice) of
        ok -> {ok, nil};
        {error, Reason} -> {error, Reason}
    end.
