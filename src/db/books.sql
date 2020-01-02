CREATE schema library;


CREATE TABLE library.books_to_rent (
    ID serial primary key,
    Title varchar(100) not null,
    Author varchar(60) not null,
    is_rent boolean,
    date_to_return date
);



INSERT INTO library.books_to_rent values
(1, 'Harry Potter and the Philosophers Stone', 'J. K. Rowling', false, null),
(2, 'Harry Potter and the Chamber of Secrets', 'J. K. Rowling', false, null),
(3, 'Harry Potter and the Prisoner of Azkaban', 'J. K. Rowling', false, null),
(4, 'Harry Potter and the Goblet of Fire', 'J. K. Rowling', false, null),
(5, 'Harry Potter and the Order of the Phoenix', 'J. K. Rowling', false, null),
(6, 'Harry Potter and the Half-Blood Prince', 'J. K. Rowling', false, null),
(7, 'Harry Potter and the Deathly Hallows', 'J. K. Rowling', false, null),
(8, 'Prince Caspian: The Return to Narnia', 'C. S. Lewis', false, null),
(9, 'The Silver Chair', 'C. S. Lewis', false, null)
(10, 'The Last Battle', 'C. S. Lewis', false, null);
