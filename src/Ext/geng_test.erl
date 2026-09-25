%% `Test.Runner.runThunkWith` on the BEAM (geng-lang `m2-beam-toptier.md`
%% D459, D460): a test's thunk, run so that what it raises is answered rather
%% than ending the runner.
%%
%% The thunk runs in a process of its own, spawned with `max_heap_size`, since
%% a BEAM process has no stack limit: its stack is in its heap, and a recursion
%% that does not end grows it until the node cannot allocate (§TT30.2, where it
%% reached 54 GB). The limit is 256 MB unless the runner has set another under
%% `geng_test_heap_limit` in `persistent_term`, a number of megabytes, which
%% `test-runner-beam` does from its options. A process past its limit is
%% killed, and the test fails saying so. A process per test cost `core`'s 806
%% tests 0.64 -> 0.72 s (§TT30.2).
-module(geng_test).
-export([run_thunk_with/4]).

-define(DEFAULT_LIMIT_MB, 256).

run_thunk_with(Ok, Err, Thunk, Arg) ->
    Mb = persistent_term:get(geng_test_heap_limit, ?DEFAULT_LIMIT_MB),
    Words = Mb * 1024 * 1024 div erlang:system_info(wordsize),
    {Pid, Ref} = spawn_opt(fun() -> exit({geng_test_done, run(Thunk, Arg)}) end,
                           [monitor, {max_heap_size, #{size => Words, kill => true, error_logger => false}}]),
    receive
        {'DOWN', Ref, process, Pid, {geng_test_done, {ok, Value}}} ->
            Ok(Value);
        {'DOWN', Ref, process, Pid, {geng_test_done, {err, Message}}} ->
            Err(Message);
        {'DOWN', Ref, process, Pid, killed} ->
            Err(<<"the test's process passed its heap limit of ", (integer_to_binary(Mb))/binary, " MB">>);
        {'DOWN', Ref, process, Pid, Other} ->
            Err(unicode:characters_to_binary(io_lib:format("~0tp", [Other])))
    end.

%% `Debug.todo` raises `{geng_todo, Place, Message}`; it is answered as the
%% JavaScript row answers the error it throws, the place and then the message.
run(Thunk, Arg) ->
    try Thunk(Arg) of
        Value -> {ok, Value}
    catch
        error:{geng_todo, Place, Message} when is_binary(Place), is_binary(Message) ->
            {err, <<"Error: ", Place/binary, "\n\n", Message/binary>>};
        Class:Reason ->
            {err, unicode:characters_to_binary(io_lib:format("~0tp:~0tp", [Class, Reason]))}
    end.
