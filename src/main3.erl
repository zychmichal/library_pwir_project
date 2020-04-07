-module(main3).
-import(compile, [file/1]).
-import(cli, [main_cli/0, main_cli_client/0, main_cli_worker/0]).
-import(worker, [handle_adding_book/1, handle_deleting_book/1]).
-import(client, [handle_prolongate_rental/1, handle_borrow_reading/1, handle_borrow_rental/1, handle_return_reading/1, handle_return_rental/1, show_library_account_balance/1]).
-import(library, [start_library/0]).
-import(db_initialize, [db_reset/0, db_init/0]).
-export([prepare_database/0, compile_all/0, main/0]).


prepare_database() ->
  file(db_initialize),
  db_init(),
  db_reset().

compile_all() ->
  file(cli),
  file(client),
  file(library),
  file(reading_room),
  file(rental),
  file(worker).



loop_main(Server_pid) ->
  Choice = main_cli(),
  case Choice of
    1 -> loop_worker(Server_pid);
    2 -> loop_client(Server_pid);
    _ -> io:fwrite("Plese tell number between 1-2. ~n")
  end.

loop_worker(Server_pid)->
  Choice = main_cli_worker(),
  case Choice of
    1 -> handle_adding_book(Server_pid);
    2 -> handle_deleting_book(Server_pid);
    3 -> halt();
    _ -> io:fwrite("Plese tell number between 1-3. ~n")
  end,
  loop_worker(Server_pid).



loop_client(Server_pid) ->
  Choice = main_cli_client(),
  case Choice of
    1 -> handle_borrow_rental(Server_pid);
    2 -> handle_return_rental(Server_pid);
    3 -> handle_prolongate_rental(Server_pid);
    4 -> handle_borrow_reading(Server_pid);
    5 -> handle_return_reading(Server_pid);
    6 -> show_library_account_balance(Server_pid);
    7 -> halt();
    _ -> io:fwrite("Plese tell number between 1-6. ~n")
  end,
  loop_client(Server_pid).

main() ->
  odbc:start(),
  PID = start_library(),
  loop_main(PID).
