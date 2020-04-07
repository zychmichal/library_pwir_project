-module(reading_room).

-export([reading_room/0]).
-define(DSN, "db").
-define(UID, "postgres").
-define(PWD, "postgres").

	
is_rent_reading(Id_book, Ref) ->
  {selected, _, Rows} = odbc:sql_query(Ref, "SELECT is_rent FROM library.books_to_rent_reading WHERE ID=" ++ str(Id_book)),
  if Rows /= [] ->
    {Out} = lists:nth(1, Rows),
    Out;
    true ->
      io:fwrite("No book with this id in data base.~n"),
      halt()
  end.

book_from_reading_repository(From, Ref, Connection, Id_book, Is_return) ->
  if Is_return == 0 ->
    %pozyczana
    Is_rent = is_rent_reading(Id_book, Connection),
    if Is_rent == false ->
      %wolna
      odbc:sql_query(Connection, "UPDATE library.books_to_rent_reading SET is_rent ='true' " ++ "WHERE ID=" ++ str(Id_book)),
      From ! {ok_borrow_reading, Ref};
      true ->
        %zajeta
        From ! {not_in_db_reading, Ref}
    end;
    true ->
      odbc:sql_query(Connection, "UPDATE library.books_to_rent_reading SET is_rent=false WHERE ID=" ++ str(Id_book)),
      From ! {ok_return_reading, Ref}
  end.

reading_room() ->
  {ok, Connection} = odbc:connect("DSN=" ++ ?DSN ++ ";" ++ "UID=" ++ ?UID ++ ";" ++ "PWD=" ++ ?PWD, []),
  reading_room(Connection).

reading_room(Connection) ->
  receive
    {From, Ref, borrow_reading, Id_book} ->
      book_from_reading_repository(From, Ref, Connection, Id_book, 0);
    {From, Ref, return_reading, Id_book} ->
      book_from_reading_repository(From, Ref, Connection, Id_book, 1)
  end,
  reading_room(Connection).

str(Int) ->
  lists:flatten(io_lib:format("~p", [Int])).