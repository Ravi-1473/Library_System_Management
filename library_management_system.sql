-- PROJECT TASK

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books
(isbn, book_title, category, rental_price, status, author, publisher)
values
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update an Existing Member's Address
update members 
set member_address = '125 Main St'
where member_id = 'C101';

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
Delete from issued_status
where issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
select * from issued_status
where issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_emp_id, count(issued_book_name) as total_book_count from issued_status
group by issued_emp_id order by issued_emp_id;

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_issue_summary AS
SELECT 
    b.isbn AS isbn, 
    b.book_title AS book_title, 
    COUNT(ist.issued_id) AS no_issued
FROM books AS b
JOIN issued_status AS ist
    ON b.isbn = ist.issued_book_isbn
GROUP BY b.isbn, b.book_title
ORDER BY no_issued DESC;

-- Task 7. Retrieve All Books in a Specific Category:
select * from books
where category = 'Classic';

-- Task 8: Find Total Rental Income by Category: 
-- ( So we need to find here each category and their total rentral income so we can do a group by category then we can do a sum on this rental 
-- price okay but thing is that this is just the book records is the book is issued two times or three times  so there we will have a incorrect result)

-- Task 8.1 Find Total Rental Income by Category (with Book Names)
select books.category, sum(books.rental_price) as total_rent, count(issued_status.issued_id) as no_of_issued, 
group_concat(books.book_title separator ',') as books_name
from books join issued_status
on books.isbn = issued_status.issued_book_isbn
group by 1 order by total_rent desc;


-- Task 9: List Members Who Registered in the Last 180 Days:
select * from members
where reg_date >= curdate() - interval 180 day;


-- Task 10: List Employees with Their Branch Manager's Name and their branch details:
select e1.emp_id, e1.emp_name, e1.position, e1.salary, e2.emp_name as manager from employees as e1
join branch as b 
on e1.branch_id = b.branch_id
join employees as e2
on b.manager_id = e2.emp_id;



-- Task 11: Create a Table of Books with Rental Price Above a Certain 7 USD:
CREATE table rental_price_greater_then_seven as
select * from books 
where rental_price >= 7;

-- Task 12: Retrieve the List of Books Not Yet Returned
select distinct issued_book_name from issued_status
left join return_status 
on issued_status.issued_id = return_status.issued_id
where return_status.issued_id is null;




-- Advanced SQL Operations:

-- Task 13: Identify Members with Overdue Books

-- Write a query to identify members who have overdue books (assume a 30-day return period). 
  -- Display the member's_id, member's name, book title, issue date, and days overdue.
  
select m.member_id, m.member_name, b.book_title, ist.issued_date, round(DATEDIFF(CURDATE(), ist.issued_date)/365,2) as over_dues_years
from members as m join issued_status as ist
on m.member_id = ist.issued_member_id
join books as b
on ist.issued_book_isbn = b.isbn
left join return_status as rst
on ist.issued_id = rst.issued_id
where rst.return_id is null
and round(DATEDIFF(CURDATE(), ist.issued_date)/365,2) > 1.2;



 -- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

Delimiter $$
CREATE PROCEDURE add_return_records (
    IN p_return_id VARCHAR(10), 
    IN p_issued_id VARCHAR(10), 
    IN p_return_date VARCHAR(10)
)

Begin
declare v_isbn varchar(50);
declare v_book_name varchar(80);

 -- Insert into return_status table
insert into return_status
(return_id, issued_id, return_date)
values
(p_return_id, p_issued_id, curdate());

-- Get the  isbn, book name from issued_status
select issued_book_isbn, issued_book_name 
into v_isbn, v_book_name
where issued_id = p_issued_id;

-- Update status into book table
update books
set status = 'yes'
where isbn = v_isbn;

-- Optional: display message (MySQL does not support RAISE NOTICE, so use SELECT):
select concat("Thank you for returning the book.", v_book_name);
END$$

DELIMITER ;


-- calling function 
Call add_return_records('RS130', 'IS135',curdate());
Call add_return_records('RS131', 'IS134', curdate());





Drop procedure add_return_records;


DELIMITER $$

CREATE PROCEDURE add_return_records (
    IN p_return_id VARCHAR(10), 
    IN p_issued_id VARCHAR(10), 
    IN p_return_date VARCHAR(10)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    -- Insert into return_status table
    INSERT INTO return_status (return_id, issued_id, return_date)
    VALUES (p_return_id, p_issued_id, CURDATE());

    -- Get the isbn, book name from issued_status
    SELECT issued_book_isbn, issued_book_name 
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Update status into book table
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    -- Display message
    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;
END$$

DELIMITER ;



-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, 
-- the number of books returned, and the total revenue generated from book rentals.
 Create table branch_reports as
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) AS count_of_issued_books,
    COUNT(rst.return_id) AS count_of_return_books,
    SUM(bk.rental_price)
FROM
    employees AS e
        JOIN
    issued_status AS ist ON ist.issued_emp_id = e.emp_id
        JOIN
    branch AS b ON e.branch_id = b.branch_id
        LEFT JOIN
    return_status AS rst ON ist.issued_id = rst.issued_id
        JOIN
    books AS bk ON ist.issued_book_isbn = bk.isbn
GROUP BY 1 , 2;



-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
SELECT  distinct m.*
FROM members m
JOIN issued_status as ist ON m.member_id = ist.issued_member_id
where issued_date >= curdate() - interval 15 Month
order by member_id;

-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

with b as (select *,
dense_rank() over(ORDER BY no_book_issued desc) as rnk from
(SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2) as a )

select * from b
where rnk<=3;


-- ******* END OF THE PROJECT ********




