-module(worker).
-export([handle_adding_book/1, handle_deleting_book/1,get_book/0]).


get_id() ->
  io:fwrite("Welcome to the rental.~n"),
  {ok, [Id]} = io:fread("Please tell id of book: ", "~d"),
  Id.

get_book() ->
  io:fwrite("Welcome to the rental.~n"),
  {ok, [Title]} = io:fread("Please tell title of book: ", "~s"),
  {ok, [Author]} = io:fread("Please tell author of book: ", "~s"),
  {Title, Author}.

add_book(Server_pid, Book) ->
  Server_pid ! {self(), add, Book},
  receive
    {adding_ok} -> io:fwrite("Here you are~n")
  end.

delete_book(Server_pid, Id_book) ->
  Server_pid ! {self(), delete, Id_book},
  receive
    {deleting_ok} -> io:fwrite("Here you are~n")
  end.

handle_deleting_book(Server_pid) ->
  Id = get_id(),
  delete_book(Server_pid, Id).

handle_adding_book(Server_pid) ->
  Book = get_book(),
  add_book(Server_pid, Book).