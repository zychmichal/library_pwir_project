-module(client).
-export([handle_prolongate_rental/1, handle_borrow_reading/1, handle_borrow_rental/1, handle_return_reading/1, handle_return_rental/1, show_library_account_balance/1]).


return_book_from_rental(Server_pid, Id_book, Date_of_return) ->
  Server_pid ! {self(), return, Id_book, Date_of_return},
  receive
    {return_rental_ok} -> io:fwrite("Thanks for return book.~n");
    {to_pay, Amount} ->
      io:fwrite("You return it to late and you should pay ~w.~n", [Amount]),
      pay_for_delay(Server_pid, Amount)
  end.

pay_for_delay(Server_pid, Amount) ->
  Server_pid ! {self(), pay, Amount},
  receive
    {pay_ok} -> io:fwrite("Thanks for paying. Next time try to return book earlier.~n")
  end.

borrow_book_from_rental(Server_pid, Id_book, Date_of_borrow) ->
  Server_pid ! {self(), borrow, Id_book, Date_of_borrow},
  receive
    {borrow_ok, _} -> io:fwrite("Here you are.~n");
    {not_in_rental_db} -> io:fwrite("This book is not available.~n")
  end.

return_book_from_reading(Server_pid, Id_book) ->
  Server_pid ! {self(), return_read, Id_book},
  receive
    {return_reading_ok} -> io:fwrite("Thanks for return.~n")
  end.

borrow_book_from_reading(Server_pid, Id_book) ->
  Server_pid ! {self(), borrow_read, Id_book},
  receive
    {borrow_reading_ok} -> io:fwrite("Here you are.~n");
    {book_not_in_reading_db} -> io:fwrite("This book is not available.~n")
  end.

prolongate_book(Server_pid, Id_book) ->
  Server_pid ! {self(), prolongate, Id_book},
  receive
    {prolongate_ok} -> io:fwrite("Here you are.~n");
    {prolongate_too_many_times} -> io:fwrite("You cannot prolongate this book because you prolongate it 2 times.~n")
  end.

handle_borrow_rental(Server_pid) ->
  {Id, Date} = get_id_and_date(),
  borrow_book_from_rental(Server_pid, Id, Date).

handle_return_rental(Server_pid) ->
  {Id, Date} = get_id_and_date(),
  return_book_from_rental(Server_pid, Id, Date).

handle_borrow_reading(Server_pid) ->
  Id = get_id(),
  borrow_book_from_reading(Server_pid, Id).

handle_return_reading(Server_pid) ->
  Id = get_id(),
  return_book_from_reading(Server_pid, Id).

handle_prolongate_rental(Server_pid) ->

  Id = get_id(),
  prolongate_book(Server_pid, Id).

show_library_account_balance(Server_pid) ->
  Server_pid ! {self(), show_balance},
  receive
    {balance, Amount} -> io:fwrite("Account balance library is: ~w.~n", [Amount])
  end.

get_id() ->
  {ok, [Id]} = io:fread("Please tell id of book: ", "~d"),
  Id.

get_id_and_date() ->
  io:fwrite("Welcome to the rental.~n"),
  {ok, [Id]} = io:fread("Please tell id of book: ", "~d"),
  {ok, [Day]} = io:fread("Please tell day: ", "~d"),
  {ok, [Month]} = io:fread("Please tell month: ", "~d"),
  {ok, [Year]} = io:fread("Please tell year: ", "~d"),
  Date = {Year, Month, Day},
  {Id, Date}.