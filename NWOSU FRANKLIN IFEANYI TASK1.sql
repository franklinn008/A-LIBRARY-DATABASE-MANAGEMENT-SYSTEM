--CREATING THE DATABASE

create database SalfordLibrary;

use SalfordLibrary;

--CREATING SCHEMA FOR DATABASE SECURITY
--SCHEMA FOR MEMBER RELATED TABLES, ITEMS RELATED TABLES AND LOANS RELATED TABLES WERE CREATED
--schema for members related tables
CREATE SCHEMA MEM;

--schema for items related tables
CREATE SCHEMA ITEMS;

--schema for loans related tables
CREATE SCHEMA LOANS

--QUESTION 1
--CREATING THE TABLES 
CREATE TABLE MEM.MEMBERS (
MemberID int IDENTITY(1,1) PRIMARY KEY ,
FirstName nvarchar(50) NOT NULL,
MiddleName nvarchar(50) NULL,
LastName nvarchar(50) NOT NULL,
DateOfBirth date NOT NULL,
EmailAddress nvarchar(100) UNIQUE NOT NULL CHECK 
(EmailAddress LIKE '%_@_%._%'),
TelephoneNumber nvarchar(20) NOT NULL,
DateJoined date NOT NULL,
DateLeft date NULL,
Mem_AddressID int NOT NULL) 


CREATE TABLE MEM.MEMBERS_ACCOUNT(
MemberAccountID int IDENTITY(1,1) PRIMARY KEY,
MemberID int  NOT NULL FOREIGN KEY REFERENCES MEM.MEMBERS(MemberID),
Username nvarchar(20) UNIQUE NOT NULL,
PasswordHash nvarchar(40)  NOT NULL CHECK (PasswordHash like '%[^a-zA-Z0-9]%'  and  PasswordHash like '%[!@#$%^&*()-_+=.,;:~]%' and len(PasswordHash) >= 8))


CREATE TABLE MEM.MEMBERS_ADDRESS(
AddressID int IDENTITY (1,1) PRIMARY KEY,
Address1 nvarchar(50) NOT NULL,
Address2 nvarchar(50) NULL,
City nvarchar(50) NULL,
Postcode nvarchar(10) NOT NULL)


CREATE TABLE ITEMS.CATALOGUE (
ItemID int IDENTITY(1,1) PRIMARY KEY ,
ItemTitle nvarchar(50) NOT NULL,
ItemTypeID int NOT NULL,
Author nvarchar(50) NOT NULL,
YearPublished date NOT NULL,
ISBN nvarchar(40) UNIQUE NOT NULL ,
DateAdded date NOT NULL,
Quantity int NOT NULL,
DateRemoved date NULL,
CurrentStatus nvarchar(20) NOT NULL)


CREATE TABLE ITEMS.ITEM_TYPES(
ItemTypeID int IDENTITY(1,1) PRIMARY KEY ,
ItemType nvarchar(50) NOT NULL)



CREATE TABLE LOANS.LOAN_DETAILS (
    LoanID int IDENTITY(1,1) PRIMARY KEY,
    MemberID int NOT NULL,
    ItemID int NOT NULL,
    DateLoaned date NOT NULL,
    DueDateCalc AS DATEADD(day, 21, DateLoaned),
    AmountPaid money NULL,
    DaysOverDue int NULL,
    TotalFine money NULL,
    Balance AS CASE
        -- if AmountPaid is not null, then it calculates Balance as TotalFine - AmountPaid
        WHEN AmountPaid IS NOT NULL
            THEN TotalFine - AmountPaid
        -- if AmountPaid is null and loan is not overdue, then it sets Balance to TotalFine
        WHEN DaysOverDue <= 0 AND AmountPaid IS NULL
            THEN TotalFine
        -- if AmountPaid is null and loan is overdue, then set Balance to TotalFine
        WHEN DaysOverDue > 0 AND AmountPaid IS NULL
            THEN TotalFine 
        ELSE 0
    END
);
--USE OF CTE TO COMPUTE COLUMNS IN THE LOAN DETAILS
WITH CTE_LoanDetails AS (
    SELECT 
        LoanID,
        MemberID,
        ItemID,
        DateLoaned,
        DueDateCalc,
        AmountPaid,
        CASE
            -- computing the number of days overdue
            WHEN DueDateCalc < GETDATE()
                THEN DATEDIFF(day, DueDateCalc, GETDATE())
            ELSE 0
        END AS DaysOverDue,
        CASE
            -- computing the total fine, based on the number of days overdue
            WHEN DueDateCalc < GETDATE()
                THEN DATEDIFF(day, DueDateCalc, GETDATE()) * 10
            ELSE 0
        END AS TotalFine
    FROM LOANS.LOAN_DETAILS
)
UPDATE LD
SET LD.DaysOverDue = CTE_LoanDetails.DaysOverDue,
    LD.TotalFine = CTE_LoanDetails.TotalFine
FROM LOANS.LOAN_DETAILS LD
JOIN CTE_LoanDetails ON LD.LoanID = CTE_LoanDetails.LoanID;



CREATE TABLE LOANS.PAYMENT_METHOD(
PaymentID int IDENTITY(1,1) PRIMARY KEY ,
LoanID int NOT NULL,
Repayment_Method nvarchar(20) NOT NULL,
Date_Of_Payment date NOT NULL,
Time_Of_Payment time NOT NULL)

--ADDING FOREIGN KEY CONSTRAINTS ON THE TABLE THEREBY ESTABLISHING RELATIONSHIP
ALTER TABLE MEM.MEMBERS
ADD FOREIGN KEY (Mem_AddressID) REFERENCES MEM.MEMBERS_ADDRESS(AddressID);

ALTER TABLE ITEMS.CATALOGUE
ADD FOREIGN KEY (ItemTypeID) REFERENCES ITEMS.ITEM_TYPES(ItemTypeID);

ALTER TABLE LOANS.LOAN_DETAILS
ADD FOREIGN KEY (MemberID) REFERENCES MEM.MEMBERS(MemberID);

ALTER TABLE LOANS.LOAN_DETAILS
ADD FOREIGN KEY (ItemID) REFERENCES ITEMS.CATALOGUE(ItemID);

ALTER TABLE LOANS.PAYMENT_METHOD
ADD FOREIGN KEY (LoanID) REFERENCES LOANS.LOAN_DETAILS(LoanID);



--POPULATING THE TABLES SO AS TO QUERY THE DATABASE

-- Inserting values into the MEMBERS_ADDRESS table
INSERT INTO MEM.MEMBERS_ADDRESS (Address1, Address2, City, Postcode)
VALUES ('84  Woodland St', 'Ground Floor', 'Bolton', 'BL1 0DF'),
('22 Westdrive St', 'Apt 3', 'Altricham', 'SK5 3GH'),
('35 Lesley St', NULL, 'Salford', 'M5 6WT'),
('87 Harrow St', 'First Floor', 'Oldham', 'OL4 8TF'),
('45 Hullock St', 'Room A2', 'Moston', 'MN4 3ED'),
('12 Queens Drive', 'Flat 2', 'Manchester', 'M1 7LK'),
('64 Landey St', 'Apt 7', 'Denton', 'M35 3UJ'),
 ('88  Tadland St', 'Ground Floor', 'Bolton', 'BL2 0DF'),
('2 Nortdrive St', 'Apt 8', 'Altricham', 'SK5 3FH'),
('5 Bandey St', NULL, 'Salford', 'M5 6JT'),
('14 Harok St', 'Ground Floor', 'Oldham', 'OL4 4TF'),
('67 Andrey St', 'Room 5', 'Moston', 'MN4 9XD'),
('72 Queens Way', 'Flat 8', 'Manchester', 'M1 3DE'),
('64 Opray St', 'Wing B', 'Blackley', 'M9 3UJ');

SELECT * FROM MEM.MEMBERS_ADDRESS;

-- Inserting values into the MEMBERS table
INSERT INTO MEM.MEMBERS (FirstName, MiddleName, LastName, DateOfBirth, EmailAddress, TelephoneNumber, DateJoined, DateLeft, Mem_AddressID)
VALUES ('Kelvin', 'Jackson', 'Hoe', '1998-03-01', 'kelvin.hoe@salfordlibrary.com', '01612345190', '2021-01-13', NULL, 1),
('Adams', NULL, 'Mathew', '2000-02-11', 'adams.mathew@salfordlibrary.com', '01612345290', '2021-01-14', NULL, 2),
('Samuel', 'Jackson', 'Leon', '1999-03-11', 'samuel.leon@salfordlibrary.com', '01612345390', '2020-11-07', NULL, 3),
('David', NULL, 'Jonathan', '2001-05-01', 'david.jonathan@salfordlibrary.com', '01612345490', '2019-06-03', NULL, 4),
('Adaobi', 'Cynthia', 'Obi', '2002-03-21', 'adaobi.cynthia@salfordlibrary.com', '01612345590', '2018-01-13', '2022-12-31', 5),
('Rajah', NULL, 'Sumanth', '2004-04-08', 'rajah.sumanth@salfordlibrary.com', '01612345690', '2017-08-19', '2021-09-24', 6),
('Leonard', 'Gucci', 'Vinci', '1999-06-27', 'leonard.vinci@salfordlibrary.com', '01612345790', '2021-02-15', '2023-02-28', 7),
 ('Ken', 'Jacson', 'Hop', '1998-12-01', 'ken.hop@salfordlibrary.com', '01612345890', '2021-01-13', NULL, 8),
('Ada', NULL, 'Oji', '2000-02-15', 'ada.oji@salfordlibrary.com', '01612345990', '2021-01-14', NULL, 9),
('Samal', 'Srikan', 'Lun', '1999-03-13', 'samal.lun@salfordlibrary.com', '01612345100', '2020-11-07', NULL, 10),
('Wavid', NULL, 'Jad', '2001-05-17', 'wavid.jad@salfordlibrary.com', '01612345110', '2019-06-03', NULL, 11),
('Obi', 'Cajan', 'Okeke', '2002-03-27', 'obi.okeke@salfordlibrary.com', '01612345120', '2018-01-13', '2022-12-30', 12),
('Sajah', NULL, 'Simanth', '2004-04-08', 'sajah.simanth@salfordlibrary.com', '01612345130', '2017-08-29', '2021-09-24', 13),
('Fonard', 'Gacci', 'Vanci', '1999-07-27', 'fonard.vanci@salfordlibrary.com', '01612345140', '2021-02-25', '2023-02-19', 14);

SELECT * FROM MEM.MEMBERS;


-- Inserting values into the ITEM_TYPES table
INSERT INTO ITEMS.ITEM_TYPES (ItemType)
VALUES ('Book'),('Journal'),('Magazine'),('Book'), ('DVD'),('CD'),('Journal'),
('Book'),('Journal'),('Magazine'),('Book'), ('DVD'),('CD'),('Journal');

SELECT * FROM ITEMS.ITEM_TYPES;

-- Inserting values into the CATALOGUE table
INSERT INTO ITEMS.CATALOGUE (ItemTitle, ItemTypeID, Author, YearPublished, ISBN, DateAdded, Quantity, DateRemoved, CurrentStatus)
VALUES ('Lost', 1, 'James Patterson', '2019-01-01', '9781787461932', '2021-05-01', 20, NULL, 'Available'),
('Sustainabilty Map', 2, 'EVM Department', '2015-08-13', '9780446310564', '2015-09-12', 50, NULL, 'Available'),
('Salford Eagle', 3, 'Salford Library', '2000-07-11', '0001', '2000-07-12', 100, NULL, 'Available'),
('Zero Negativity', 4, 'Ant Middleton', '2020-01-31', '9780008336516', '2021-11-01', 150, NULL, 'Available'),
('Excel For Beginners', 5, 'Salford Library', '2021-12-01', '0002', '2021-12-05', 5, NULL, 'On Loan'),
('Adelphi Project', 6, 'Salford Projects Dept', '2019-06-01', '0003', '2019-07-11', 3, '2021-08-06', 'Removed'),
('Data Track', 7, 'Data Department', '2021-11-01', '9780446310324', '2021-12-19', 40, NULL, 'On Loan'),
('Red Riding', 8, 'David Peace', '2002-01-01', '9781787461082', '2023-04-11', 20, NULL, 'Available'),
('Health & Wealth', 9, 'Health Sciences', '2023-02-13', '97804463105794', '2023-04-12', 50, NULL, 'Available'),
('Salford Hawk', 10, 'Salford Library', '2002-07-11', '0004', '2002-08-12', 100, NULL, 'Available'),
('Wake Up', 11, 'Piers Morgan', '2020-04-30', '9780008336604', '2023-01-01', 150, NULL, 'Available'),
('Robotics', 12, 'Salford Library', '2021-12-11', '0005', '2021-12-15', 5, NULL, 'On Loan'),
('Avengers', 13, 'Salford Movies', '2019-06-11', '0006', '2019-07-21', 3, '2021-08-06', 'On Loan'),
('Business Analytics', 14, 'Business School', '2022-12-31', '9780446310367', '2023-04-19', 40, NULL, 'On Loan');

SELECT * FROM ITEMS.CATALOGUE

-- Inserting values into the MEMBERS_ACCOUNT table
INSERT INTO MEM.MEMBERS_ACCOUNT (MemberID, Username, PasswordHash)
VALUES (29, 'kelvinhoe', 'kP@ssw0rd!'),
(30, 'adamat', 'aP@ssw0rd!'),
(31, 'samueljl', 'sP@ssw0rd!'),
(32, 'davidj', 'dP@ssw0rd!'),
(33, 'adao', 'a!P@ssw0rd!'),
(34, 'rajas', 'rP@ssw0rd!'),
(35, 'leovin', 'lvP@ssw0rd!'),
(36, 'kehop', 'kh@ssw0rd!'),
(37, 'adaoj', 'ao@ssw0rd!'),
(38, 'samsril', 'ss@ssw0rd!'),
(39, 'wavja', 'wj@ssw0rd!'),
(40, 'obok', 'ok@ssw0rd!'),
(41, 'sasi', 'ssi@ssw0rd!'),
(42, 'fonvan', 'fv@ssw0rd!');

SELECT * FROM MEM.MEMBERS_ACCOUNT;

-- Inserting values into the LOAN_DETAILS table
INSERT INTO LOANS.LOAN_DETAILS (MemberID, ItemID, DateLoaned, AmountPaid)
VALUES (29,32, '2022-01-01', 4500.00),
(33,36, '2023-04-04', 0.00),
(42,41, '2023-02-01',560.00 ),
(41,42, '2023-03-18',100.00),
(34,40, '2022-12-01', 1180.00),
(33,43, '2023-04-02', 0.00),
(40,33, '2023-02-21', 360.00),
(38,33, '2022-01-01', 4520.00),
(33,38, '2023-04-04', 0.00),
(42,44, '2023-04-03', 0.00),
(39,41,  '2023-03-18', 100.00),
(29,32, '2022-12-01', 1100.00),
(35,45,'2023-04-02', 0.00),
(40,35, '2023-03-21', 70.50);

--creating a common table expression (CTE) called "CTE_LoanDetails" that contains the loan details from the "LOAN_DETAILS"
WITH CTE_LoanDetails AS (
    SELECT 
        LoanID,
        MemberID,
        ItemID,
        DateLoaned,
        DueDateCalc,
        AmountPaid,
        CASE
            -- computing the number of days overdue
            WHEN DueDateCalc < GETDATE()
                THEN DATEDIFF(day, DueDateCalc, GETDATE())
            ELSE 0
        END AS DaysOverDue,
        CASE
            -- computing the total fine, based on the number of days overdue
            WHEN DueDateCalc < GETDATE()
                THEN DATEDIFF(day, DueDateCalc, GETDATE()) * 10
            ELSE 0
        END AS TotalFine
    FROM LOANS.LOAN_DETAILS
)
UPDATE LD
SET LD.DaysOverDue = CTE_LoanDetails.DaysOverDue,
    LD.TotalFine = CTE_LoanDetails.TotalFine
FROM LOANS.LOAN_DETAILS LD
JOIN CTE_LoanDetails ON LD.LoanID = CTE_LoanDetails.LoanID;

SELECT * FROM LOANS.LOAN_DETAILS;


-- Inserting values into the PAYMENT_METHOD table
INSERT INTO LOANS.PAYMENT_METHOD (LoanID, Repayment_Method, Date_Of_Payment, Time_Of_Payment)
VALUES (35, 'Credit Card', '2023-04-19', '08:00:00'),
(37, 'Cash Deposit', '2023-03-28', '10:30:00'),
(38, 'Bank Transfer', '2023-04-11', '12:30:00'),
(39, 'Credit Card', '2023-04-19', '01:00:00'),
(41, 'Credit Card', '2023-04-05', '09:00:00'),
(42, 'Credit Card', '2023-04-19', '08:00:00'),
(45, 'Bank Transfer', '2023-04-11', '12:30:00'),
(46, 'Credit Card', '2023-04-19', '01:00:00'),
(48, 'Credit Card', '2023-04-11', '09:00:00');

SELECT * FROM LOANS.PAYMENT_METHOD;



--QUESTION 2
--QUERYING THE DATABASE FOR THE TASK
--a) Here is an example stored procedure to search the catalogue for matching character strings by title, sorted by most recent publication date:
CREATE PROCEDURE SearchCatalogueByTitle
    @searchTitle nvarchar(50)
AS
BEGIN
    SELECT *
    FROM ITEMS.CATALOGUE
    WHERE ItemTitle LIKE '%' + @searchTitle + '%'
    ORDER BY YearPublished DESC;
END

--EXECUTING
EXEC SearchCatalogueByTitle @searchTitle = 'Sal'


--b) Here is an example stored procedure to return a full list of all items currently on loan which have a due date of less than five days from the current date:
CREATE PROCEDURE ItemsOnLoan
AS
BEGIN
    SELECT LD.*, C.ItemTitle,C.CurrentStatus,C.Author
    FROM LOANS.LOAN_DETAILS LD
    JOIN ITEMS.CATALOGUE C ON LD.ItemID = C.ItemID
    WHERE LD.DueDateCalc <= DATEADD(day, 5, GETDATE()) and  C.CurrentStatus = 'On Loan'
    ORDER BY LD.DueDateCalc;
END

--EXECUTING
EXEC ItemsOnLoan;


--c) Here is an example stored procedure to insert a new member into the database:
CREATE PROCEDURE InsertNewMember
    @firstName nvarchar(50),
    @middleName nvarchar(50),
    @lastName nvarchar(50),
    @dateOfBirth date,
    @emailAddress nvarchar(100),
    @telephoneNumber nvarchar(20),
    @dateJoined date,
	@memAddressID nvarchar(50),
	@address1 nvarchar(50),
	@city nvarchar(50),
	@postcode nvarchar(10)
    
AS
BEGIN
--variable connecting the two tables based on foreign key constraint
DECLARE @address_id int;
    --inserting values firstly into member address table
	INSERT INTO MEM.MEMBERS_ADDRESS(Address1,City,Postcode)
	VALUES(@address1,@city,@postcode)
	--this identifies the new address_id inserted using specified function
	SET @address_id = SCOPE_IDENTITY();
	--then inserts values into member table
    INSERT INTO MEM.MEMBERS (FirstName, MiddleName, LastName, DateOfBirth, EmailAddress, TelephoneNumber, DateJoined,Mem_AddressID)
    VALUES (@firstName, @middleName, @lastName, @dateOfBirth, @emailAddress, @telephoneNumber, @dateJoined,@memAddressID);

END

--EXECUTING
EXEC InsertNewMember 
	@firstName = 'Williams',
	@middleName = 'Harod',
	@lastName = 'Fork',
	@dateOfBirth = '1990-12-11',
	@emailAddress = 'williams.fork@salfordlibrary.com',
	@telephoneNumber = '01612345890',
	@dateJoined = '2023-03-21',
	@memAddressID = 15,
	@address1 = '78 Bradford Road' ,
	@city = 'Manchester',
	@postcode = 'M38 3JK';

	select * from MEM.MEMBERS;

--d) Here is an example stored procedure to update the details for an existing member:
CREATE PROCEDURE UpdateMemberDetails
    @memberID int,
    @firstName nvarchar(50),
    @middleName nvarchar(50),
    @lastName nvarchar(50),
    @dateOfBirth date,
    @emailAddress nvarchar(100),
    @telephoneNumber nvarchar(20),
    @dateJoined date,
    @dateLeft date,
    @memAddressID int
AS
BEGIN
    UPDATE MEM.MEMBERS
    SET FirstName = @firstName,
        MiddleName = @middleName,
        LastName = @lastName,
        DateOfBirth = @dateOfBirth,
        EmailAddress = @emailAddress,
        TelephoneNumber = @telephoneNumber,
        DateJoined = @dateJoined,
        DateLeft = @dateLeft,
        Mem_AddressID = @memAddressID
    WHERE MemberID = @memberID;
END

--EXECUTING
DECLARE @memberID int = 44;
DECLARE @firstName nvarchar(50) = 'Williams';
DECLARE @middleName nvarchar(50) = 'Harod';
DECLARE @lastName nvarchar(50) = 'White';
DECLARE @dateOfBirth date = '2000-01-12';
DECLARE @emailAddress nvarchar(100) = 'williams.white@salfordlibrary.com';
DECLARE @telephoneNumber nvarchar(20) = '01612345890';
DECLARE @dateJoined date = '2023-03-21';
DECLARE @dateLeft date = NULL;
DECLARE @memAddressID int = 15;

EXEC UpdateMemberDetails 
    @memberID, 
    @firstName, 
    @middleName, 
    @lastName, 
    @dateOfBirth, 
    @emailAddress, 
    @telephoneNumber, 
    @dateJoined, 
    @dateLeft, 
    @memAddressID;

SELECT * FROM MEM.MEMBERS

--QUESTION 3
--The library wants be able to view the loan history, showing all previous and current loans, and including details of the item borrowed, borrowed date, due date and any 
--associated fines for each loan. You should create a view containing all the required information.

CREATE VIEW LOAN_HISTORY 
AS
SELECT LD.LoanID, LD.ItemID, C.ItemTitle,C.CurrentStatus, IT.ItemType,M.MemberID, M.FirstName, M.LastName, LD.DateLoaned, 
LD.DueDateCalc, LD.DaysOverDue, LD.TotalFine
FROM LOANS.LOAN_DETAILS LD
JOIN ITEMS.CATALOGUE C ON LD.ItemID = C.ItemID
JOIN MEM.MEMBERS M ON LD.MemberID = M.MemberID
JOIN ITEMS.ITEM_TYPES IT ON C.ItemTypeID = IT.ItemTypeID;

--EXECUTING VIEW
SELECT * FROM LOAN_HISTORY;

--QUESTION 4
--Create a trigger so that the current status of an item automatically updates to Available when the book is returned.
CREATE TRIGGER update_item_status
ON LOANS.LOAN_DETAILS
AFTER UPDATE
AS
BEGIN
    IF UPDATE(DaysOverDue)
    BEGIN
        UPDATE ITEMS.CATALOGUE
        SET CurrentStatus = 'Available'
        FROM ITEMS.CATALOGUE
        JOIN inserted ON ITEMS.CATALOGUE.ItemID = inserted.ItemID
        WHERE inserted.DaysOverDue IS NULL;
    END
END


-- Updating the DueDateCalc column of a loan to NULL
UPDATE LOANS.LOAN_DETAILS
SET DaysOverDue = NULL
WHERE LoanID = 47;

-- Verifying  that the trigger updated the CurrentStatus column of the corresponding item
SELECT CurrentStatus FROM ITEMS.CATALOGUE
WHERE ItemID = (SELECT ItemID FROM LOANS.LOAN_DETAILS WHERE LoanID = 47);



--QUESTION 5
--You should provide a function, view, or SELECT query which allows the library to identify the total number of loans made on a specified date
SELECT COUNT(*) AS TotalLoans
FROM LOANS.LOAN_DETAILS L
JOIN ITEMS.CATALOGUE C ON L.ItemID = C.ItemID
WHERE CONVERT(date, L.DateLoaned) = '2023-04-02';

--ANOTHER METHOD
DECLARE @loanDate date = '2023-04-02'

SELECT COUNT(*) AS TotalLoans
FROM LOANS.LOAN_DETAILS
WHERE CONVERT(date, DateLoaned) = @loanDate

--QUESTION 7 EXTRA QUERIES
--• Views
-- Example view: All current loans with borrower and item details
CREATE VIEW CurrentLoans AS
SELECT LD.LoanID, LD.DateLoaned, LD.DueDateCalc, M.FirstName + ' ' + M.LastName AS BorrowerName, C.ItemTitle, C.Author, IT.ItemType
FROM LOANS.LOAN_DETAILS LD
JOIN MEM.MEMBERS M ON LD.MemberID = M.MemberID
JOIN ITEMS.CATALOGUE C ON LD.ItemID = C.ItemID
JOIN ITEMS.ITEM_TYPES IT ON C.ItemTypeID = IT.ItemTypeID
WHERE C.CurrentStatus = 'On Loan';

-- Querying the view
SELECT * FROM CurrentLoans;

--• Stored procedures
-- Example stored procedure: Search catalogue by author
CREATE PROCEDURE SearchCatalogueByAuthor
    @searchAuthor nvarchar(50)
AS
BEGIN
    SELECT *
    FROM ITEMS.CATALOGUE
    WHERE Author LIKE '%' + @searchAuthor + '%'
    ORDER BY ItemTitle ASC;
END

-- Execute the stored procedure
EXEC SearchCatalogueByAuthor 'Sal';

--• System functions and user defined functions
-- Example user-defined function: to calculate the age of a member given their date of birth
CREATE FUNCTION MEM.fnCalculateAge
(
@DOB date)
RETURNS int
AS
BEGIN
    DECLARE @Age int
    SET @Age = DATEDIFF(year, @DOB, GETDATE())
    IF (MONTH(@DOB) > MONTH(GETDATE()))
        SET @Age = @Age - 1
    ELSE IF (MONTH(@DOB) = MONTH(GETDATE()) AND DAY(@DOB) > DAY(GETDATE()))
        SET @Age = @Age - 1
    RETURN @Age
END

-- Calling the function to calculate age from the current date using the date of birth 
DECLARE @DOB date = '1998-12-01'
SELECT MEM.fnCalculateAge(@DOB) AS 'Age'


--• Triggers
-- Example trigger:Create a trigger that automatically updates the CurrentStatus field in the CATALOGUE table whenever the Quantity field is updated. 
--If the Quantity becomes zero, the CurrentStatus should be set to "Out of stock". 
--If the Quantity becomes greater than zero, the CurrentStatus should be set to "In stock"
CREATE TRIGGER update_catalogue_status
ON ITEMS.CATALOGUE
AFTER UPDATE
AS
BEGIN
    IF EXISTS(SELECT * FROM INSERTED WHERE Quantity = 0)
    BEGIN
        UPDATE ITEMS.CATALOGUE SET CurrentStatus = 'Out of stock' WHERE ItemID IN (SELECT ItemID FROM INSERTED WHERE Quantity = 0)
    END
    ELSE IF EXISTS(SELECT * FROM INSERTED WHERE Quantity > 0)
    BEGIN
        UPDATE ITEMS.CATALOGUE SET CurrentStatus = 'In stock' WHERE ItemID IN (SELECT ItemID FROM INSERTED WHERE Quantity > 0)
    END
END

--updating and testing the trigger
UPDATE ITEMS.CATALOGUE SET Quantity = 0 WHERE ItemID = 37;

SELECT * FROM ITEMS.CATALOGUE




--• SELECT queries which make use of joins and sub-queries
-- Example query: Find all item types authored by 'Salford' which are Available as the status and are not removed from the catalogue
SELECT C.ItemTitle, C.Author, IT.ItemType
FROM ITEMS.CATALOGUE C
LEFT JOIN ITEMS.ITEM_TYPES IT ON C.ItemTypeID = IT.ItemTypeID AND C.CurrentStatus = 'Available'
WHERE C.Author = 'Salford Library' AND C.DateRemoved IS NULL;

--Assuming we want to get a list of all members who have overdue books, we can use a sub-query to first get a list of all loan IDs
--that are overdue, and then join it with the LOAN_DETAILS and MEMBERS tables as follows
SELECT M.FirstName, M.LastName, LD.ItemID, LD.LoanID, LD.DateLoaned, LD.DueDateCalc
FROM MEM.MEMBERS M
INNER JOIN LOANS.LOAN_DETAILS LD ON M.MemberID = LD.MemberID
WHERE LD.LoanID IN (
    SELECT LoanID
    FROM LOANS.LOAN_DETAILS
    WHERE DueDateCalc < GETDATE()
)


