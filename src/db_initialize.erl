-module(db_initialize).
-export([db_init/0, db_reset/0]).
-define(DSN, "db").
-define(UID, "postgres").
-define(PWD, "postgres").


db_init() ->
  rental_init(),
  reading_init().

db_reset() ->
  odbc:start(),
  {ok, Ref} = odbc:connect("DSN=" ++ ?DSN ++ ";" ++ "UID=" ++ ?UID ++ ";" ++ "PWD=" ++ ?PWD, []),
  odbc:sql_query(Ref, "UPDATE library.books_to_rent_rental SET date_to_return =null , " ++ "is_rent ='false' ").


rental_init() ->
  odbc:start(),
  {ok, Ref} = odbc:connect("DSN=" ++ ?DSN ++ ";" ++ "UID=" ++ ?UID ++ ";" ++ "PWD=" ++ ?PWD, []),
  odbc:sql_query(Ref, "CREATE schema library;"),
  odbc:sql_query(Ref, "CREATE TABLE library.books_to_rent_rental (
    ID serial primary key,
    Title varchar(100) not null,
    Author varchar(60) not null,
    is_rent boolean,
    date_to_return date,
	prolongation integer
);"),
  odbc:sql_query(Ref, "INSERT INTO library.books_to_rent_rental
(Title, Author, is_rent,date_to_return,prolongation) values
( 'Harry Potter and the Philosophers Stone', 'J. K. Rowling', false, null, 0),
( 'Harry Potter and the Chamber of Secrets', 'J. K. Rowling', false, null,0),
( 'Harry Potter and the Prisoner of Azkaban', 'J. K. Rowling', false, null,0),
( 'Harry Potter and the Goblet of Fire', 'J. K. Rowling', false, null,0),
( 'Harry Potter and the Order of the Phoenix', 'J. K. Rowling', false, null,0),
( 'Harry Potter and the Half-Blood Prince', 'J. K. Rowling', false, null,0),
( 'Harry Potter and the Deathly Hallows', 'J. K. Rowling', false, null,0),
( 'Prince Caspian: The Return to Narnia', 'C. S. Lewis', false, null,0),
( 'The Silver Chair', 'C. S. Lewis', false, null,0),
( 'The Last Battle', 'C. S. Lewis', false, null,0);").


reading_init() ->
  odbc:start(),
  {ok, Ref} = odbc:connect("DSN=" ++ ?DSN ++ ";" ++ "UID=" ++ ?UID ++ ";" ++ "PWD=" ++ ?PWD, []),
  odbc:sql_query(Ref, "CREATE TABLE library.books_to_rent_reading (
    ID serial primary key,
    Title varchar(100) not null,
    Author varchar(60) not null,
    is_rent boolean
);"),
  odbc:sql_query(Ref, "INSERT INTO library.books_to_rent_reading
(Title, Author, is_rent) values
( 'Harry Potter and the Philosophers Stone', 'J. K. Rowling', false),
( 'Harry Potter and the Chamber of Secrets', 'J. K. Rowling', false),
( 'Harry Potter and the Prisoner of Azkaban', 'J. K. Rowling', false),
( 'Harry Potter and the Goblet of Fire', 'J. K. Rowling', false),
( 'Harry Potter and the Order of the Phoenix', 'J. K. Rowling', false),
( 'Harry Potter and the Half-Blood Prince', 'J. K. Rowling', false),
( 'Harry Potter and the Deathly Hallows', 'J. K. Rowling', false),
( 'Prince Caspian: The Return to Narnia', 'C. S. Lewis', false),
( 'The Silver Chair', 'C. S. Lewis', false),
( 'The Last Battle', 'C. S. Lewis', false);").