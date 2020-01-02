-module(main).

%% API
-compile([export_all]).
-define(AMOUNT_FOR_1_DAY_DELAY, 0.2).

%% connection -> polaczenie z db
%% is_return -> integer czy zwracana ksiazka(1) czy pozyczana(0) (nie ma typowego boola w erlangu chyba)
%% funkcja wrzuca do bazy danych rzeczy i zwraca date do kiedy ma zwrocic ksiazke
book_to_rent_repository(Connection, Id_book, Is_return) -> ok.
  %% TO DO

book_from_reading_repository(Connection, Id_book, Is_return) -> ok.



%inicjalizacja serwerow
start_library() ->
  %% tu trzeba ogarnac do bazy danych polaczenie -> tu bedzie troche jebania z dockerem zeby db zrobic bo tak najlatwiej chyba bedzie
  %%odbc:start(),
  %%{ok, Ref} =,
  %% tu beda wysylane connection na razie wysylam 0 do sprawdzen czy dziala komunikacja w porzadku
  Rental = spawn_link(?MODULE,rental,[0]),
  Reading = spawn_link(?MODULE,reading_room,[0]),
  %% tu inicjujemy reading room -> przekazujac connection, poprzez spawn_link (po co ma nam to dzialac gdy padnie serwer)
  %% tu inicjujemy rental -> przekazujac connection
  spawn(?MODULE,library,[0, Reading, Rental]). %% zaczynamy ze biblioteka nie ma nic hajsu xD  + przesylamy PIDy do reading roomu i rental


library(Account_state, Reading, Rental) ->
  receive
    {From, show_balance} ->
      From ! {balance, Account_state},
      library(Account_state, Reading, Rental);
    {From, return, Id_book, Date_of_return} ->
      %% wysylamy info do rental -> czekamy na odpowiedz
      Rental ! {self(), From, return, Id_book, Date_of_return},
      library(Account_state, Reading, Rental);
    {From, borrow, Id_book, Date_of_borrow} ->
      %% wysylamy info do rental, czekamy na odpowiedz czy ok czy nie (czy ksiazka jest dostepna) -> wysylamy wiadomosc do clienta (ok, data zwrotu)
      %% error data niedostepna
      Rental ! {self(), From, borrow, Id_book, Date_of_borrow},
      library(Account_state, Reading, Rental);
    {From, borrow_read, Id_book} ->
      Reading ! {self(), From, borrow_reading, Id_book},  %% check w db czy jest dostepna
      library(Account_state, Reading, Rental);
      %% wysylamy info do reading room, czekamy na odpowiedz czy ok czy nie (czy ksiazka jest dostepna) -> wysylamy wiadomosc do clienta (ok, data zwrotu)
      %% error data niedostepna
    {From, return_read, Id_book} ->
      Reading ! {self(), From, return_reading, Id_book},  %% check w db czy jest dostepna
      library(Account_state, Reading, Rental);
    {From, pay, Amount} ->
      From ! {pay_ok},
      library(Account_state + Amount, Reading, Rental);

    %% sygnaly pochodzace od serverow:
    %% wypozyczalnia
    {to_late, Ref, Number_of_days} ->
      Amount = Number_of_days * ?AMOUNT_FOR_1_DAY_DELAY,
      %% wysylamy do clienta ze ma zaplacic
      Ref ! {to_pay, Amount},
      library(Account_state, Reading, Rental);
    {return_ok, Ref} ->
      Ref ! {return_rental_ok},
      library(Account_state, Reading, Rental);
    {borrow_ok, Ref, Date_of_return} ->
      %%tutaj mozemy juz wysylac stringa przerobic na podstawie daty ale to do zrobienia
      Ref ! {borrow_ok, Date_of_return},
      library(Account_state, Reading, Rental);
    {not_in_db, Ref} ->
      Ref ! {not_in_rental_db},
      library(Account_state, Reading, Rental);

    %% czytelnia:
    {ok_borrow_reading, Ref} ->
      Ref ! {borrow_reading_ok},
      library(Account_state, Reading, Rental);
    {not_in_db_reading, Ref} ->
      Ref ! {book_not_in_reading_db},
      library(Account_state, Reading, Rental);
    {ok_return_reading, Ref} ->
      Ref ! {return_reading_ok},
      library(Account_state, Reading, Rental)
  end.


%% TO DO OBSLUGI DATABASE i reading room i rental
%% Funkcje do sprawdzenia tylko (normalnie bedzie szukanie w bazie danych a teraz case 0/1 wyrzuca inne wyniki)
rental(Connection) ->
  case Connection of
    0 ->
      receive
        {From, Ref, return, Id_book, Date_of_return} ->
          io:fwrite("This test case show when to late return.~n"),
          From ! {to_late, Ref, 10};
        {From, Ref, borrow, Id_book, Date_of_borrow} ->
          io:fwrite("This test case show when book isn't in db rental.~n"),
          From ! {not_in_db, Ref}
      end,
      rental(1);
    1 ->
      receive
        {From, Ref, return, Id_book, Date_of_return} ->
          io:fwrite("This test case show when OK return rental.~n"),
          From ! {return_ok, Ref};
        {From, Ref, borrow, Id_book, Date_of_borrow} ->
          io:fwrite("This test case show when OK borrow rental.~n"),
          From ! {borrow_ok, Ref, 10}
      end,
      rental(0)
  end.


reading_room(Connection) ->
  case Connection of
    0 ->
      receive
        {From, Ref, borrow_reading, Id_book} ->
          io:fwrite("This test case show when book isn't in reading room.~n"),
          From ! {not_in_db_reading, Ref};
        {From, Ref, return_reading, Id_book} ->
          io:fwrite("This test case show when OK return reading room.~n"),
          From ! {ok_return_reading, Ref}
      end,
      reading_room(1);
    1 ->
      receive
        {From, Ref, return_reading, Id_book} ->
          io:fwrite("This test case show when OK return reading room.~n"),
          From ! {ok_return_reading, Ref};
        {From, Ref, borrow_reading, Id_book} ->
          io:fwrite("This test case show when OK borrow reading room.~n"),
          From ! {ok_borrow_reading, Ref}
      end,
      reading_room(0)
  end.



%% Funkcje ktorymi klient bedzie wysylal polecenia do biblioteki
return_book_from_rental(Server_pid, Id_book, Date_of_return) ->
  Server_pid ! {self(), return, Id_book, Date_of_return},
  receive
    {return_rental_ok} -> io:fwrite("Thanks for return book.~n");
    {to_pay, Amount} ->
      io:fwrite("You return it to late and you should pay ~w.~n",[Amount]),
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
    {borrow_ok, Date_of_return} -> io:fwrite("Here you are.~n");
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


main_cli() ->
  io:fwrite("Welcome to library.~n"),
  io:fwrite("Select:~n"),
  io:fwrite("1 - borrow book from rental.~n"),
  io:fwrite("2 - return a book to rental.~n"),
  io:fwrite("3 - borrow and read book in reading room.~n"),
  io:fwrite("4 - return book to the reading room.~n"),
  io:fwrite("5 - show balance library account.~n"),
  io:fwrite("6 - exit.~n"),
  {ok, [X]} = io:fread("Client choice: ", "~d"),
  X.

get_id_and_date() ->
  io:fwrite("Welcome to the rental.~n"),
  {ok, [Id]} = io:fread("Please tell id of book: ", "~d"),
  {ok, [Day]} = io:fread("Please tell day: ", "~d"),
  {ok, [Month]} = io:fread("Please tell month: ", "~d"),
  {ok, [Year]} = io:fread("Please tell year: ", "~d"),
  Date = {Year, Month, Day},
  {Id, Date}.

handle_borrow_rental(Server_pid) ->
  {Id, Date} = get_id_and_date(),
  borrow_book_from_rental(Server_pid, Id, Date).

handle_return_rental(Server_pid) ->
  {Id, Date} = get_id_and_date(),
  return_book_from_rental(Server_pid, Id, Date).

handle_borrow_reading(Server_pid) ->
  {ok, [Id]} = io:fread("Please tell id of book: ", "~d"),
  borrow_book_from_reading(Server_pid, Id).

handle_return_reading(Server_pid) ->
  {ok, [Id]} = io:fread("Please tell id of book: ", "~d"),
  return_book_from_reading(Server_pid, Id).

show_library_account_balance(Server_pid) ->
  Server_pid ! {self(), show_balance},
  receive
    {balance, Amount} -> io:fwrite("Account balance library is: ~w.~n",[Amount])
  end.


loop_main(Server_pid) ->
  Choice = main_cli(),
  case Choice of
    1 -> handle_borrow_rental(Server_pid);
    2 -> handle_return_rental(Server_pid);
    3 -> handle_borrow_reading(Server_pid);
    4 -> handle_return_reading(Server_pid);
    5 -> show_library_account_balance(Server_pid);
    6 -> halt()
  end,
  loop_main(Server_pid).

main() ->
  PID = start_library(),
  loop_main(PID).