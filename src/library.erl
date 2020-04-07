-module(library).


-export([start_library/0,library/3]).
-import(rental, [rental/0]).
-import(reading_room, [reading_room/0]).
-define(AMOUNT_FOR_1_DAY_DELAY, 0.2).



start_library() ->
  Rental = spawn_link(rental, rental, []),
  Reading = spawn_link(reading_room, reading_room, []),
  spawn(library, library, [0, Reading, Rental]).

library(Account_state, Reading, Rental) ->
  receive
    {From, show_balance} ->
      From ! {balance, Account_state},
      library(Account_state, Reading, Rental);
    {From, return, Id_book, Date_of_return} ->
      Rental ! {self(), From, return, Id_book, Date_of_return},
      library(Account_state, Reading, Rental);
    {From, borrow, Id_book, Date_of_borrow} ->
      Rental ! {self(), From, borrow, Id_book, Date_of_borrow},
      library(Account_state, Reading, Rental);
    {From, borrow_read, Id_book} ->
      Reading ! {self(), From, borrow_reading, Id_book}, 
      library(Account_state, Reading, Rental);
    {From, prolongate, Id} ->
	io:fwrite("server"),
      Rental ! {self(), From, prolongate, Id},
      library(Account_state, Reading, Rental);
    {From, return_read, Id_book} ->
      Reading ! {self(), From, return_reading, Id_book},
      library(Account_state, Reading, Rental);
    {From, pay, Amount} ->
      From ! {pay_ok},
      library(Account_state + Amount, Reading, Rental);
    {From, add, Book} ->
      Rental ! {self(), From, add, Book},
      library(Account_state, Reading, Rental);
    {From, delete, Id} ->
      Rental ! {self(), From, delete, Id},
      library(Account_state, Reading, Rental);


    {too_late, Ref, Number_of_days} ->
      Amount = Number_of_days * ?AMOUNT_FOR_1_DAY_DELAY,
      Ref ! {to_pay, Amount},
      library(Account_state, Reading, Rental);
    {return_ok, Ref} ->
      Ref ! {return_rental_ok},
      library(Account_state, Reading, Rental);
    {borrow_ok, Ref, Date_of_return} ->
      Ref ! {borrow_ok, Date_of_return},
      library(Account_state, Reading, Rental);
    {not_in_db, Ref} ->
      Ref ! {not_in_rental_db},
      library(Account_state, Reading, Rental);
    {prolongate_ok, Ref} ->
      Ref ! {prolongate_ok},
	  library(Account_state, Reading, Rental);
    {prolongate_too_many_times, Ref} ->
      Ref ! {prolongate_too_many_times},
	  library(Account_state, Reading, Rental);

    {ok_borrow_reading, Ref} ->
      Ref ! {borrow_reading_ok},
      library(Account_state, Reading, Rental);
    {not_in_db_reading, Ref} ->
      Ref ! {book_not_in_reading_db},
      library(Account_state, Reading, Rental);
    {ok_return_reading, Ref} ->
      Ref ! {return_reading_ok},
      library(Account_state, Reading, Rental);

    {adding_ok, Ref} ->
      Ref ! {adding_ok},
	  library(Account_state, Reading, Rental);
    {deleting_ok, Ref} ->
      Ref ! {deleting_ok},
	  library(Account_state, Reading, Rental)

  end.