-module(rental).

-export([rental/0]).
-define(DSN, "db").
-define(UID, "postgres").
-define(PWD, "postgres").


rental() ->
  {ok, Connection} = odbc:connect("DSN=" ++ ?DSN ++ ";" ++ "UID=" ++ ?UID ++ ";" ++ "PWD=" ++ ?PWD, []),
  rental(Connection).

rental(Connection) ->
  receive
    {From, Ref, return, Id_book, Date_of_return} ->
      book_from_rental_repository(From, Ref, Connection, Id_book, 1, Date_of_return);
    {From, Ref, borrow, Id_book, Date_of_borrow} ->
      book_from_rental_repository(From, Ref, Connection, Id_book, 0, Date_of_borrow);
    {From, Ref, add, Book} ->
      add_book_to_database(From, Ref, Connection, Book);
    {From, Ref, delete, Id_book} ->
      delete_book_from_database(From, Ref, Connection, Id_book);
    {From, Ref, prolongate, Id_book} ->
	  io:fwrite("rental"),
      prolongate_book(From, Ref, Connection, Id_book)
  end,
  rental(Connection).


add_book_to_database(From, Ref, Connection, Book) ->
  {Author, Title} = Book,
   odbc:sql_query(Connection, "INSERT INTO library.books_to_rent_reading
(title, author, is_rent) values
( '  " ++ Title ++ "' ,"  ++ "'" ++ Author ++ "' ,false);"),
odbc:sql_query(Connection, "INSERT INTO library.books_to_rent_rental
(title, author, is_rent,date_to_return,prolongation) values
( '  " ++ Title ++ "' ,"  ++ "'" ++ Author ++ "' ,false,null,0);"),
  From ! {adding_ok, Ref}.
delete_book_from_database(From, Ref, Connection, Id_book) ->
  odbc:sql_query(Connection, "DELETE FROM library.books_to_rent_reading WHERE ID=" ++ str(Id_book)),
  odbc:sql_query(Connection, "DELETE FROM library.books_to_rent_rental WHERE ID=" ++ str(Id_book)),
  From ! {deleting_ok, Ref}.

get_amount_prolongate(Connection, Id_book) ->
  {selected, _, Rows} = odbc:sql_query(Connection, "SELECT prolongation FROM library.books_to_rent_rental WHERE ID=" ++ str(Id_book)),
  if Rows /= [] ->
    {Out} = lists:nth(1, Rows),
    I = Out + 1,
	I;
    true ->
      io:fwrite("No book with this id in data base.~n"),
      halt()
  end.
  

prolongate_book(From, Ref, Connection, Id_book) ->
  Prolongate = get_amount_prolongate(Connection, Id_book),
  if Prolongate < 3 ->
  	odbc:sql_query(Connection, "UPDATE library.books_to_rent_rental SET prolongation =" ++ str(Prolongate) ++ " " ++ "WHERE ID=" ++ str(Id_book)),
	odbc:sql_query(Connection, "UPDATE library.books_to_rent_rental SET date_to_return =date_to_return + interval '1 month'"   ++ "WHERE ID=" ++ str(Id_book)),
    From ! {prolongate_ok, Ref};
    true ->
      From ! {prolongate_too_many_times, Ref}
  end.

book_from_rental_repository(From, Ref, Connection, Id_book, Is_return, Date) ->
  if Is_return == 0 ->
    %pozyczana
    Is_rent = is_rent_rental(Id_book, Connection),
    if Is_rent == false ->
      %wolna
      odbc:sql_query(Connection, "UPDATE library.books_to_rent_rental SET date_to_return =" ++ make_string_from_date(Date) ++ ", is_rent ='true' " ++ "WHERE ID=" ++ str(Id_book)),
      From ! {borrow_ok, Ref, Date};
      true ->
        %zajeta
        From ! {not_in_db, Ref}
    end;
    true ->
      D = get_date_from_db(Id_book, Connection),
      Diff = count_days_between_dates(Date, D),
      odbc:sql_query(Connection, "UPDATE library.books_to_rent_rental SET date_to_return =" ++ "null , " ++ "is_rent=false, prolongation=0 " ++ "WHERE ID=" ++ str(Id_book)),
      if Diff =< 0 ->
        From ! {return_ok, Ref};
        true ->
          From ! {too_late, Ref, Diff}
      end
  end.

is_rent_rental(Id_book, Ref) ->
  {selected, _, Rows} = odbc:sql_query(Ref, "SELECT is_rent FROM library.books_to_rent_rental WHERE ID=" ++ str(Id_book)),
  if Rows /= [] ->
    {Out} = lists:nth(1, Rows),
    Out;
    true ->
      io:fwrite("No book with this id in data base.~n"),
      halt()
  end.

get_date_from_db(Id_book, Ref) ->
  {selected, _, Rows} = odbc:sql_query(Ref, "SELECT date_to_return FROM library.books_to_rent_rental WHERE ID=" ++ str(Id_book)),
  if Rows /= [{null}] ->
    {Out} = lists:nth(1, Rows),
    string_to_date(Out);
    true ->
      io:fwrite("You can't return book which is available.~n"),
      halt()
  end.

make_string_from_date(Date) ->
  Tmp = calendar:gregorian_days_to_date(calendar:date_to_gregorian_days(Date) + 30),
  {Year, Month, Day} = Tmp,
  Out = "'" ++ str(Year) ++ "-" ++ str(Month) ++ "-" ++ str(Day) ++ "'",
  Out.

count_days_between_dates(Date1, Date2) ->
  Diff = calendar:date_to_gregorian_days(Date1) -
    calendar:date_to_gregorian_days(Date2),
  Diff.

str(Int) ->
  lists:flatten(io_lib:format("~p", [Int])).

string_to_date(String) ->
  [Year, Month, Day] =
    case string:tokens(String, "-/") of
      [Y, M, D] when length(Y) =:= 4 -> [Y, M, D];
      [M, D, Y] when length(Y) =:= 4 -> [Y, M, D]
    end,
  Date = list_to_tuple([list_to_integer(X) || X <- [Year, Month, Day]]),
  true = calendar:valid_date(Date),
  Date.