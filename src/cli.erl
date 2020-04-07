-module(cli).
-export([main_cli/0, main_cli_client/0, main_cli_worker/0]).

main_cli() ->
  io:fwrite("Welcome to library.~n"),
  io:fwrite("Select:~n"),
  io:fwrite("1 - worker.~n"),
  io:fwrite("2 - client.~n"),
  {ok, [X]} = io:fread("Client choice: ", "~d"),
  X.


main_cli_client() ->
  io:fwrite("1 - borrow book from rental.~n"),
  io:fwrite("2 - return a book to rental.~n"),
  io:fwrite("3 - prolongate book.~n"),
  io:fwrite("4 - borrow and read book in reading room.~n"),
  io:fwrite("5 - return book to the reading room.~n"),
  io:fwrite("6 - show balance library account.~n"),
  io:fwrite("7 - exit.~n"),
  {ok, [X]} = io:fread("Client choice: ", "~d"),
  X.


main_cli_worker() ->
  io:fwrite("Welcome to library.~n"),
  io:fwrite("Select:~n"),
  io:fwrite("1 - add book.~n"),
  io:fwrite("2 - delete book.~n"),
  io:fwrite("3 - exit.~n"),
  {ok, [X]} = io:fread("Client choice: ", "~d"),
  X.