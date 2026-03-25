-- ================================================================
-- CREDIT CARD FRAUD DETECTION DATABASE - COMPLETE SETUP
-- Single file with step-by-step explanations
-- Perfect for beginners who know: SELECT, INSERT, UPDATE, DELETE, DROP
-- ================================================================


/*
	New Concepts We'll Learn:
	1. Declare: Create variables to store temporary values 
	2. IF EXIXTS: Checck if something exists before doing an action 
	3. IDENTITY: Auto-incrementing numberss (like 1,2,3...)
	4. FOREIGN KEY: Link tables together with relationships
	5. DEFAULT: Sets automatic values if you don't provide one
	6. WHILE: Repeats code until a condition is met (like a loop)
	7. CHECKSUM/NEWID: Generate random Numbers
	8. WITH (CTE): Create temporary result sets for complex queries
	9. DATETIME Function: Works with dates and times 
*/




-- ================================================================
-- STEP 1: CREATE THE DATABASE
-- ================================================================

-- Check if database already exits, if yes, delete it
-- This ensure we start fresh every time 

	IF EXISTS (
	SELECT * FROM SYS.DATABASES 
	WHERE NAME = 'FraudDetectionDB')
	BEGIN 

	-- SWITCH TO MASTER DATABASE BEFORE DELETING 
	USE master;
	-- DELETE THE OLD DATABASE
	DROP DATABASE FraudDetectionDB
	END;
	GO

	-- CREATE NEW DATABASE 
	CREATE DATABASE FraudDetetctionDB;
	GO 

	-- SWITCH TO OUR NEW DATABSE (ALL COOMOND WILL RUN HERE)
	USE FraudDetetctionDB;
	GO 

	PRINT 'Database Created Succefully';
	Print'';




-- ================================================================
-- STEP 2: CREATE TABLES
-- ================================================================

/*
	 WHAT IS IDENTITY(1,1)
	-- Auto-Generate numbers starting from 1, Incrementing by 1
	-- First Row gets 1, Second gets 2, Third gets 3, etc.
	-- You Don't need to provide these values when inserting!

	 WHAT IS DEFAULT?
	-- Automatic value if you don't provide one
	-- Like DEFAULT GETDATE() means "use today's date if not specified"
*/



-- Table 1: Geographic Locations (Cities Where Transactions happen)
    CREATE TABLE geo_location (
	-- Identity (1,1) means: Start at 1, add 1 each time
	-- So first city ID = 1, Second gets ID = 2 etc.
	Location_ID INT PRIMARY KEY IDENTITY(1,1),
	City NVARCHAR(100) NOT NULL,
	State NVARCHAR(100)NOT NULL,
	Country NVARCHAR(100) NOT NULL,
	-- DECIMAL (10,7) means: Total 10 digits, 7 after the decimal point (for precise coordinates)
	Latitude DECIMAL(10,7) NOT NULL,
	Longitude DECIMAL(10,7) NOT NULL
	);
	GO

	PRINT 'Table Created Successfully: geo_location';
	


-- Table 2: Marchats (Stores/Websites where purchse happen)
	CREATE TABLE Merchants (
	merchant_ID INT PRIMARY KEY IDENTITY(1,1),
	merchant_Name NVARCHAR(255) NOT NULL,
	category NVARCHAR(100) NOT NULL,
	-- Check ensure value is one these three options only 
	risk_rating NVARCHAR(20) CHECK (risk_rating IN ('Low', 'Medium', 'High')), 
	fraud_history_count INT DEFAULT 0, -- Default 0 means start at zero 

	-- GETDATE() returns current date/time
	CREATED_AT DATETIME DEFAULT GETDATE() 
	);
	GO

PRINT 'Table Created Successfully: Merchants';



-- Table 3: Customers (People who make purchases)
	CREATE TABLE Customers (
	Customer_ID INT PRIMARY KEY IDENTITY(1,1),
	Customer_Name NVARCHAR(255) NOT NULL,
	Email NVARCHAR(255) NOT NULL UNIQUE, -- Unique means no two customers can have same email
	Phone NVARCHAR(20) NOT NULL,

	-- Foreign Key links to geo_location table, ensures valid location
	-- Link Customer to their home city 
	Home_location_id INT,
	FOREIGN KEY (Home_location_id) REFERENCES geo_location(Location_ID),
	registration_date DATETIME DEFAULT GETDATE(), -- When customer created

	-- DECIMAL (12,2) means: Total 12 digits, 2 after decimal (for money amounts)
	avg_trancation_amount DECIMAL (12,2) DEFAULT 0,
	Total_trancation INT DEFAULT 0,
	risk_profile nvarchar(20) CHECK (risk_profile IN ('Low', 'Medium', 'High')) 
	);
	GO 

	PRINT 'TABLE CREATED SUCCESFULLY: Customers';



-- Table 4: Transaction (Every Credit Card Purchase)
	CREATE TABLE Transactions (
	Transaction_ID INT PRIMARY KEY IDENTITY(1,1),

	-- Links to Customers who made this purchase 
	Customer_ID INT NOT NULL,
	FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),

	-- Links to Merchants where purchase were made 
	Merchant_id INT NOT NULL,
	FOREIGN KEY (Merchant_id) REFERENCES Merchants(Merchant_ID),

	AMOUNT DECIMAL(12,2) NOT NULL, -- HOW MUCH MONEY SPENT 

	-- DATETIME stores data AND time: 
	Order_Date DATETIME DEFAULT GETDATE(), -- WHEN PURCHASE HAPPENED

	-- Links to City Where Transaction HAPPENED
	Location_id INT NOT NULL,
	FOREIGN KEY (Location_id) REFERENCES geo_location(Location_ID),

	devide_id VARCHAR(100), -- Phone/Computer_id
	ip_address VARCHAR(50), -- IP address of device used for purchase
	card_last_four Varchar(4), -- Last 4 digits of cards used

	-- BIT is True/False (1/0)
	shipping_address_changes BIT DEFAULT 0, -- Did customer change shipping address? (1 = Yes, 0 = No)

	-- Risk Score from 0 (Safe) to 100 (High Risk)
	RiskScore INT DEFAULT 0 CHECK(RiskScore >= 0 AND RiskScore <= 100) 
	);
	GO

	PRINT 'TABLE CREATED SUCCESFULLY:  Transaction';



-- Table 5:Fraud Flag (Warnning When Suspicious Transaction Detected)
	CREATE TABLE Fraud_Flag (
	Flag_ID INT PRIMARY KEY IDENTITY(1,1),

	Transaction_id INT NOT NULL,
	FOREIGN KEY (Transaction_id) REFERENCES Transactions(Transaction_ID),

	flag_type nvarchar(100) NOT NULL, -- what trigger the alert 
	Severity nvarchar(20) CHECK (Severity IN ('Low', 'Medium', 'High')), -- How serious is the alert

	-- Text Allows very long descriptions (like a paragraph)
	Description Text,
	flagged_at DATETIME DEFAULT GETDATE() -- When the alert was created
	);
	GO 

	PRINT 'TABLE CREATED SUCCESSFULLY: Fraud_Flag';



-- Table 6: Risk Scores (Detailed Breakdown of why transaction is risky)
	CREATE TABLE Risk_scores (
	Score_id INT PRIMARY KEY IDENTITY(1,1),

	-- UNIQUE means: Each transaction can only have one risk score entry
	Transaction_id INT NOT NULL UNIQUE,
	FOREIGN KEY (Transaction_id) REFERENCES Transactions(Transaction_ID),

	-- Individual Risk Componenets 
	Velocity_score INT DEFAULT 0,     -- Too many Transaction too fast?
	Amount_score INT DEFAULT 0,       -- Amount too high or to low?
	geo_score INT DEFAULT 0,          -- Wrong Location?
	Merchant_score INT DEFAULT 0,     -- Risky Merchant?
	Behavior_score INT DEFAULT 0,     -- Unsual Behavior?
	Total_score INT DEFAULT 0,        -- Sum of all above.

	Calculated_at datetime default getdate()
	);
	GO 

	PRINT 'TABLE CREATED SUCCESSFULLY: Risk Scores';



-- Table 7: Fraud Case (Confirmed fraud after investigation)
	CREATE OR ALTER Fraud_Cases (
	Case_ID INT PRIMARY KEY IDENTITY(1,1),
	Transaction_id INT NOT NULL UNIQUE,
	FOREIGN KEY (Transaction_id) REFERENCES Transactions(Transaction_ID),

	Confirmed_Fraud BIT NOT NULL,              -- Bit( 1 = yes, 0 = no) means was it actually fruad or not?
	reported_by nvarchar(100),                 -- Who reported this case? 
	reported_data DATETIME default getdate(),  -- When was this case Resolved?
	detetction_time_seconds INT,               -- How fast did we detect it
	Recovered_Amount DECIMAL(12,2),            -- How much money Recovered
	notes NVARCHAR(MAX)                        -- TO STORE LARGE TEXT DATA
	);
	GO

	--ALTER TABLE Fraud_Cases
	--ADD Recovered_Amount DECIMAL(12,2);
	--GO
	--ALTER TABLE Fraud_Cases
	--ADD notes NVARCHAR(MAX);
	--GO

	PRINT 'TABLE CREATED SUCCESSFULLY: Fraud Case;'
	PRINT '';
	PRINT '===============================================';
	PRINT 'ALL 7 TABLES CREATED SUCCESSFULLY!';
	PRINT '===============================================';
	PRINT '';

	

	
-- ================================================================
-- STEP 3: INSERT SAMPLE DATA
-- ================================================================

--  WHAT IS DECLARE?
-- DECLARE creates a variable -a container that stores a value temporarily 
-- Think of it like: "let x = 5" in math.

-- EXAMPLE: DECLARE @name Varchar(50) = 'Jhon';
-- @age.@Pricee, @count, ETC.

	PRINT 'STARTING DATA INSERTION...';
	PRINT '';




-- ============================================================
-- 3.1: INSERT CITIES geo_Location (15 locations)
-- ============================================================

	PRINT'INSERTING Cities...';

	INSERT INTO geo_location (city, state, country, latitude, longitude)
	VALUES
	('Mumbai', 'Maharashtra', 'India', 19.0760, 72.8777),
	('Delhi', 'Delhi', 'India', 28.7041, 77.1025),
	('Bangalore', 'Karnataka', 'India', 12.9716, 77.5946),
	('Hyderabad', 'Telangana', 'India', 17.3850, 78.4867),
	('Pune', 'Maharashtra', 'India', 18.5204, 73.8567),
	('Chennai', 'Tamil Nadu', 'India', 13.0827, 80.2707),
	('Kolkata', 'West Bengal', 'India', 22.5726, 88.3639),
	('Ahmedabad', 'Gujarat', 'India', 23.0225, 72.5714),
	('Jaipur', 'Rajasthan', 'India', 26.9124, 75.7873),
	('Surat', 'Gujarat', 'India', 21.1702, 72.8311),
	('Singapore', NULL, 'Singapore', 1.3521, 103.8198),
	('Dubai', NULL, 'UAE', 25.2048, 55.2708),
	('New York', 'NY', 'USA', 40.7128, -74.0060),
	('London', NULL, 'UK', 51.5074, -0.1278),
	('Hong Kong', NULL, 'Hong Kong', 22.3193, 114.1694);
	GO

-- ALTER TABLE geo_location
-- ALTER COLUMN State NVARCHAR(100) NULL;

PRINT 'Inserted 15 cities'




-- ============================================================
-- 3.2: INSERT MERCHANTS (16 merchants)
-- ============================================================

	PRINT 'INSERTING MERCHANTS...';

	INSERT INTO Merchants (merchant_Name, category, risk_rating, fraud_history_count)
	Values
	('Amazon India', 'E-commerce', 'Low', 2),
	('Flipkart', 'E-commerce', 'Low', 1),
	('Myntra', 'E-commerce', 'Low', 0),
	('ShopClues', 'E-commerce', 'Medium', 5),
	('BetWay Online', 'Gambling', 'High', 45),
	('Poker365', 'Gambling', 'High', 38),
	('CasinoMax', 'Gambling', 'High', 52),
	('CoinBase India', 'Cryptocurrency', 'High', 28),
	('BinanceIndia', 'Cryptocurrency', 'High', 31),
	('MakeMyTrip', 'Travel', 'Medium', 8),
	('Goibibo', 'Travel', 'Medium', 6),
	('Yatra', 'Travel', 'Medium', 4),
	('Croma', 'Electronics', 'Low', 1),
	('Reliance Digital', 'Electronics', 'Low', 0),
	('Swiggy', 'Food Delivery', 'Low', 0),
	('Zomato', 'Food Delivery', 'Low', 1);

	Print 'Inserted 16 Merhchants';

--  select * from Merchants;




-- ============================================================
-- 3.3: INSERT CUSTOMERS (10,000 customers)
-- ============================================================

/*
	WHAT IS WHILE LOOP?
	-- WHILE LOOP REPEATS A BLOCK OF CODE AS LONG AS A CONDITION IS TRUE
   
	   WHILE (condition is true)
	   BEGIN
		-- Do Something
		-- Change the condition 
		END

	Example:
		DECLARE @COUNT INT = 1;
		WHILE @COUNT <= 5
		BEGIN 
		PRINT @COUNT;            -- Prints 1, then 2, then 3, etc.
		SET @COUNT = @COUNT + 1; -- Increments count by 1 each time
		END
*/


	PRINT 'Inserting 10,000 Customers...(this takes ~5 Seconds)...';

	-- DECLARE Creates a variable called @i (like a counter)
	-- INT means its a whole number
	-- = 1 mean it starts at 1 

	DECLARE @i INT = 1;
	DECLARE @RandomLocationID INT;

	while @i <= 10000      -- While means: keep doing this as long as @i is less than or equal to 10,000
	BEGIN
		SELECT TOP 1 @RandomLocationID = Location_ID
		FROM geo_location
		ORDER BY NEWID();

/*
	WHAT IS CHECKSUM(NEWID())?
	NewID() = Creates a random unique ID (like: a7a7f3b2c9-1234-5678-9abc-def012345678)

	CHECKSUM() = Converts that ID into a number
	ABS() = Makes it positive (remove minus sign if any)
	% = Modulo (Reminder after division)

	Example: 157 % 10 = 7 (Because 157 ÷ 10 = 15 Reminder 7)

	So: (ABS(CHECKSUM(NEWID())) % 10) + 1
	Gives us a random number between 1 and 10!

	Why? 
	-- ABS(CHECKSUM(NEWID())) might be : 482619
	-- 482169 % 10 = 9 (remainder)
	-- 9 + 1= 10

	Another Example:
	-- Random number: 753891
	753891 % 10 = 1
	1 + 1= 2
*/

	INSERT INTO Customers 
	(
	Customer_Name, 
	email, 
	Phone, 
	Home_location_id,
	avg_trancation_amount,
	Total_trancation, 
	risk_profile
	)
	VALUES 
	(
	-- CONCAT joins text together
	-- CONCAT('Customer_', 123) = 'Customer_123'
	CONCAT('Customer_', @i),
	CONCAT('Customer', @i, '@email.com'), -- Customer@email.com

	-- Generate random 10-Digit phone number
	-- CAST() converts number to Stings 
	CONCAT('+91', RIGHT('0000000000' + CAST(ABS(CHECKSUM(NEWID())) % 10000000000 as varchar(10)), 10)),
	@RandomLocationID,

	-- Random average amount between ₹1,000 and ₹51,000
	(ABS(CHECKSUM(NEWID())) % 50000) + 1000,

	--  Random number of transaction between 1 - 100
	(ABS(CHECKSUM(NEWID())) % 100) + 1,

	-- Risk Profile Based on Random Percentage
	CASE 
	WHEN (ABS(CHECKSUM(NEWID())) % 100) < 15 THEN 'HIGH'   -- 15% CHANCE
	WHEN (ABS(CHECKSUM(NEWID())) % 100) < 45 THEN 'MEDIUM' -- 30% CHANCE
	ELSE 'LOW' -- 55% CHANCE
	END
	)

	-- Increase Counter by 1 
	-- After First loop: @i = 2
	-- After Second loop: @i =3
	-- etc. 

	SET @i = @i + 1;
	END

	PRINT 'INSERTED 10,000 Customers';

 -- select * from Customers;




-- ============================================================
-- 3.4: INSERT TRANSACTIONS (100,000 transactions - FAST METHOD!)
-- ============================================================

/*
	WHAT IS A CTE (Common Table Expression)
	Its a temporary result set that you can
	reference within a SELECT, INSERT, UPDATE, or DELETE statement,
	Think of it like creating a temporary mini-table.

	WITH Name AS (
		SELECT ...
		)
	-- Now you can use "Name" as if it were a table 
*/


	PRINT 'Inserting 100,000 Transaction (Ultra Fast Method)...';
	PRINT 'This will take about 5 - 10 Seconds...';
	PRINT '';

	-- Record Start time to show how fast it is
	DECLARE @StartTime DATETIME = GETDATE();

	BEGIN TRY

/*
	- How THIS WORKS:
	1. Create a list of numbers from 0 to 99,999 (that;s 1,00,000 numbers)
	2.For EACH number, generate ONE Random Transaction
	3. Insert ALL 100,000 at once (not one bt one!)

	This is much faster than a loop!
*/


	-- WITH creates a temporary table called "Numbers"
	WITH Numbers AS (
					  -- Top 100,000 Means: Give me only the first 100,000 rows
	SELECT TOP 100000 -- ROW_NUMBER() generates a unique number for each row (starting at 1)
					  -- OVER (ORDER BY (SELECT NULL)) is Required syntax (ignore it for now)

	-- We subtract 1 to get: 0, 1, 2, 3,...99,999
	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS Num
	FROM 
	-- master..spt_values is a built-in SQL Server table with ~2,500 Rows 
	-- We cross join it with itself to get 2,500 * 2,500 = 6,250,000 rows 
	-- Ex: Table A = 3 rows, Table B = 4 rows 👉 Result = 3 × 4 = 12 rows
	-- Then we take only first 100,000 Rows 

	master..spt_values a
	CROSS JOIN master..spt_values b
	)

	-- Now Inserting all 100,000 Transactions at once using the Numbers CTE
	INSERT INTO Transactions
	(
	Customer_ID,
	Merchant_id,
	AMOUNT,
	Order_Date,
	Location_id,
	device_id, 
	ip_address,
	card_last_four,
	shipping_address_changes,
	RiskScore
	)

	SELECT 
	C.Customer_ID,     -- Random VALID Customer_ID from Customers table
	M.Merchant_id,     -- Random VALID Merchant_ID from Merchants table

/*
	WHAT IS CAST?
	CAST changes one data type to another 
	CAST('123' AS VARCHAR) = '123' (Number to Text)
	CAST('456' AS INT) = 456 (Text to Number)
	CAST(789 AS DECIMAL(12,2)) = 789.00 (Number to Decimal with 2 decimal places)
*/

	CAST(ABS(CHECKSUM(NEWID())) % 99000 + 100 AS DECIMAL(12,2)), -- Random Amount between ₹100 and ₹99,099

/*
	WHAT IS DATEADD
	adds or subtracts time from a date
	DATEADD(MINUTE, 60, GETDATE()) = 60 minutes from now 
	DATEADD(DAY, -7, GETDATE()) = 7 days ago
	DATEADD(MONTH, 3, GETDATE()) = 3 months from now

	365 Days = 525,600 Minutes
	so, we subtract a random number of minutes (0 to 525,600) from today
	This gives us random dates in the past year!
*/

	-- Random date in the last 365 days
	DATEADD(
	MINUTE, 
	-(ABS(CHECKSUM(NEWID())) % 525600),  -- Random Minutes to Subtract 
	GETDATE()) AS order_date,            -- From Today

	G.Location_ID AS location_id,        -- Random VALID Location_ID from geo_location table

/*
	WHAT IS RIGHT?
	RIGHT(text, number) = Take the rightmost N characters
	RIGHT('Hello', 2) = 'lo'
	RIGHT('12345', 3) = '345'
 
	We use it to pad numbers with zeros:
	RIGHT('000000' + '123', 6) = RIGHT('000000123', 6) = '000123'
*/

	-- Device ID like: DEVICE_000001, DEVICE_000002, etc.
	CONCAT('DEVICE_', RIGHT('000000' + CAST(Num AS VARCHAR), 6)) AS device_id,
 
	-- Random IP Address (4 Numbers separated by dots)
	CONCAT(
	(ABS(CHECKSUM(NEWID())) % 256), '.',
	(ABS(CHECKSUM(NEWID())) % 256), '.',	
	(ABS(CHECKSUM(NEWID())) % 256), '.',
	(ABS(CHECKSUM(NEWID())) % 256)
	) AS ip_address,

	-- Last 4 digits of card (0000 to 9999)
	RIGHT('0000' + CAST((ABS(CHECKSUM(NEWID())) % 10000) AS VARCHAR), 4) AS card_last_four,

	-- 5% Chance address was changed (1= true, 0 = false)
	CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 5 THEN 1 ELSE 0 END AS shipping_address_changes,

/*
	Realistic risk score distribution:
	- 72% Transactions are low risk (0-39)
	- 18% are medium risk (40-69)
	- 10% are high risk (70-100)

	We use the "Num" from our Numbers table:
	- If Num ends in 0-9 (10%): High Risk
	- If Num ends in 10-27 (18%): Medium Risk
	- Otherwise (72%): Low Risk
*/

	CASE        
	-- Num % 100 gives us the last 2 digits (0-99)
	WHEN (Num % 100) < 10 THEN (ABS(CHECKSUM(NEWID())) % 31) + 70   -- High Risk (70-100)
	WHEN (Num % 100) < 28 THEN (ABS(CHECKSUM(NEWID())) % 30) + 40   -- Medium Risk (40-69)
	ELSE (ABS(CHECKSUM(NEWID())) % 40)                              -- Low Risk (0-39)
	END AS RiskScore

	FROM Numbers

	-- Pick ONE random valid Customer_ID for each row
	CROSS APPLY (
		SELECT TOP 1 Customer_ID
		FROM Customers
		ORDER BY NEWID()
	) C

	-- Pick ONE random valid Merchant_ID for each row
	CROSS APPLY (
		SELECT TOP 1 Merchant_id
		FROM Merchants
		ORDER BY NEWID()
	) M

	-- Pick ONE random valid Location_ID for each row
	CROSS APPLY (
		SELECT TOP 1 Location_ID
		FROM geo_location
		ORDER BY NEWID()
	) G;

	-- Calculate how long it took 
	DECLARE @END_TIME DATETIME = GETDATE();
	DECLARE @DurationSeconds INT = DATEDIFF(SECOND, @StartTime, @END_TIME);
 
	PRINT 'INSERTED 100,000 Transactions!';
	PRINT 'TIME TAKEN: ' + CAST(@DurationSeconds AS VARCHAR) + ' Seconds';
	PRINT 'Speed: ' + CAST(100000 / NULLIF(@DurationSeconds, 0) AS VARCHAR) + ' records/second';

	PRINT '';

	END TRY
	BEGIN CATCH
		PRINT 'INSERT FAILED!';
		PRINT ERROR_MESSAGE();
	END CATCH	

-- select count(*) from Transactions; -- Should show 100,000




-- ============================================================
-- 3.5: INSERT RISK SCORES (for each transaction)
-- ============================================================

	PRINT 'Calculating Risk Score for all Transaction'

/*
	Applying Join here
*/

	INSERT INTO Risk_scores
	(
		Transaction_id,
		Velocity_score,
		Amount_score,
		geo_score,
		Merchant_score,
		Behavior_score,
		total_score
	)
	SELECT 
	t.Transaction_ID,

	-- velocity score: 25 points if transaction between 11 PM and 4 AM
	CASE WHEN DATEPART(HOUR, t.Order_Date) >= 23 
	OR
	DATEPART(HOUR, t.Order_Date) < 4 
	THEN 25  
	ELSE 0
	END AS Velocity_score,

	-- Amount Score: 30 points if> ₹50,000 or 25 points if < ₹10 (card testing)
	CASE WHEN t.AMOUNT > 50000 THEN 30
	WHEN t.AMOUNT < 10 THEN 25
	ELSE 0
	END AS Amount_score,

	-- Georaphic Score: 20 points if outside india
	CASE WHEN l.country <> 'India' 
	THEN 20 
	ELSE 0 
	END AS geo_score,

	--MERCHANT SCORE: 15 points if high-rsik merchant
	CASE WHEN m.risk_rating = 'High' 
	THEN 15 
	ELSE 0 
	END AS Merchant_score,

	--Behavioral Score: 10 points if address changed 
	CASE WHEN t.shipping_address_changes = 1 
	THEN 10 
	ELSE 0 
	END AS Behavior_score,

	--Total is already calculated in transactions table
	t.RiskScore as total_score

	From Transactions t
	-- Join with geo_location to get country
	JOIN geo_location l ON t.Location_id = l.Location_ID
	-- Join with Merchants to get risk rating
	JOIN Merchants m ON t.Merchant_id = m.merchant_ID;

	PRINT'Risk Score calculated for all transcations';

	-- SELECT * FROM Risk_scores; -- Should show 100,000 rows with risk scores for each transaction




-- ============================================================
-- 3.6: INSERT FRAUD FLAGS (for risky transactions)
-- ============================================================

	PRINT'Flagging suspicious transactions...';

	-- Flag all transaction with risk score >= 40
	INSERT INTO Fraud_Flag
	(
		Transaction_id,
		flag_type,
		Severity,
		Description
	)

	SELECT 
	transaction_id,

	--Flag type based on risk score
	CASE 
		WHEN Riskscore  >= 70 THEN 'High Risk Transaction'
		WHEN Riskscore >= 40 THEN 'Medium Risk Transaction'
		ELSE 'Low Risk Transaction'
	END AS flag_type,

	-- Severity based on risk score
	CASE 
		WHEN Riskscore >= 70 THEN 'High'
		WHEN Riskscore >= 40 THEN 'Medium'
		ELSE 'Low'
	END AS Severity,

	-- Description
	CONCAT('Risk Score: ', Riskscore, ' .Multiple fraud indicators detected.') 
	AS Description

	FROM Transactions 
	Where Riskscore >= 40; -- Only flag medium and high risk transactions
	
	-- Immediately store rowcount
	DECLARE @InsertedRows INT = @@ROWCOUNT;

	PRINT 'Flagged ' + CAST(@InsertedRows AS VARCHAR) + ' Suspicious Transactions!';
/*
	WHAT IS @@ROWCOUNT?
	@@ROWCOUNT is a special variable that contains the number of rows affected by the last query.
	After INSERT: How many rows were inserted
	After UPDATE: How many rows were updated
	After DELETE: How many rows were deleted
*/

-- SELECT * FROM Fraud_Flag; -- Should show all flagged transactions with their risk scores and descriptions




-- ============================================================
-- 3.7: INSERT FRAUD CASES (confirmed fraud - about 300 cases)
-- ============================================================
	
	PRINT'Recording Confirmed Fraud Cases..';

	-- Take 300 Random High-Risk transactions and mark them as confirmed fraud 
	INSERT INTO Fraud_Cases
	(
		Transaction_id,
		Confirmed_Fraud,
		detetction_time_seconds,
		reported_by 
	)

	SELECT TOP 300 
	Transaction_id,
	1 AS confirmed_fraud, -- 1 = true (this is confirmed fraud)

	-- Random detection time between 10 -190 seconds 
	(ABS(CHECKSUM(NEWID())) % 180) + 10 AS detetction_time_seconds,

	'Automated System' AS reported_by

	FROM Transactions
	WHERE RiskScore >= 70    -- Only take high-risk transactions
	ORDER BY NEWID();        -- Random order (NEWID() makes each row get a random sort value)
	
	PRINT'Recorded 300 Confirmed Fraud Cases!';
	PRINT' '; 

	--Select * from Fraud_Cases; -- Should show 300 rows of confirmed fraud cases with detection times and reported by info




-- ================================================================
-- STEP 4: CREATE INDEXES FOR BETTER PERFORMANCE
-- ================================================================
/*
	 WHAT IS AN INDEX?
	An index is like the index at the back of a book - it helps find things faster!

	Without index: SQL has to check EVERY row (slow)
	With index: SQL can jump directly to the right rows (fast)

	Example:
	Looking for all transactions from customer #5000:
	- Without index: Check all 100,000 rows (slow!)
	- With index: Jump directly to customer #5000's transactions (fast!)
*/

	PRINT 'Creating indexes for faster queries...';

	-- Index on order date (helps with filtering by date)
	CREATE INDEX IX_TRANSCATION_DATE ON Transactions(Order_Date);

	-- Index on customer_id (helps when looking up specific customers)
	CREATE INDEX IX_TRANSACTON_CUSTOMER ON Transactions(Customer_id);

	--Index on RiskScore (helps when filtering by risk level)
	CREATE INDEX IX_TRANSACTION_RiskScore on Transactions(RiskScore);

	-- Index on risk_profile (helps customer segmentation)
	CREATE INDEX IX_CUSTOMER_RiskProfile ON Customers(risk_profile);

	PRINT 'CREATED 5 INDEXES FOR FASTER QURIES';
	PRINT '';




-- ================================================================
-- STEP 5: VERIFICATION - CHECK EVERYTHING WORKED!
-- ================================================================

	PRINT '================================================';
	PRINT '           DATABASE SETUP COMPLETE!             ';
	PRINT '================================================';
	PRINT '';
	PRINT 'Summary of inserted data:';
	PRINT '';

/*
	How it works:
	SELECT ... COUNT(*) --> Counts all rows in a table
	UNION ALL --> Combines multiple SELECT results into one list
	Each line adds a label and count for one table
*/

	-- Show count of records in each table
	SELECT 'Locations' as table_name, count(*) as row_count from geo_location
	UNION ALL 
	SELECT 'Merchants', COUNT(*) From Merchants
	UNION ALL
	SELECT 'Customers', Count(*) From Customers
	UNION ALL
	SELECT 'Transactions', Count(*) From Transactions
	UNION ALL
	SELECT 'Fraud Flags', Count(*) From Fraud_Flag
	UNION ALL
	SELECT 'Risk Score', Count(*) From Risk_scores
	UNION ALL
	Select 'Fraud Cases', Count(*) From Fraud_Cases;

	PRINT '';
	PRINT '================================================';
	PRINT '';
	PRINT 'Quick Stats:';
	PRINT '';


	-- Show Risk Distribution
	SELECT
	CASE
		WHEN RiskScore >= 70 Then 'High Risk (70-100)'
		WHEN RiskScore >= 40 Then 'Medium Risk (40-69)'
		ELSE 'Low Risk (0-39)'
	END AS Risk_Category,
		COUNT(*) As Transaction_Count,
		CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) From Transactions) AS DECIMAL(5,2)) AS Percentage
	FROM Transactions
	GROUP BY 
	CASE
		WHEN RiskScore >= 70 Then 'High Risk (70-100)'
		WHEN RiskScore >= 40 Then 'Medium Risk (40-69)'
		ELSE 'Low Risk (0-39)'
	END
	ORDER BY Percentage DESC;

	PRINT '';
	PRINT '================================================';
	PRINT 'You are ready to connect to Power BI!';
	PRINT '================================================';
	PRINT '';
	PRINT 'Database Name: FraudDetectionDB';
	PRINT 'Server: localhost (or your SQL Server name)';
	PRINT '';
	PRINT 'Next step: Open Power BI Desktop and connect!';
	


/* 
--👉 What Have been Created:
		✓ 7 tables created
		✓ 15 cities
		✓ 16 merchants
		✓ 10,000 customers
		✓ 100,000 transactions
		✓ All risk scores calculated
		✓ Fraud flags for suspicious transactions
		✓ 300 confirmed fraud cases
		✓ Indexes for fast queries

=====================================================================

--👉 WHAT WE LEARN 
		1.  DECLARE : Create Variables
		2.  WHILE LOOP: Repeat ACtions
		3.  IDENTITY: Auto Incrementing IDs
		4.  FOREIGN KEY: Link Tables Together
		5.  DEFAULT: Automatic Values
		6.  NewID() = Creates a random unique ID (like: a7a7f3b2c9-1234-5678-9abc-def012345678)
		7.  CHECKSUM() = Converts that ID into a number
		8.  ABS() = Makes it positive (remove minus sign if any)
		9.  DATEADD/ DATEPART: Work with dates and times
		10. CAST: Change data types
		11. CONCAT: Join text together
		12. CTE (WITH): Create temporary result sets for complex queries
		13. @@ROWCOUNT: Get number of rows affected by last query
		14. Indexes: Speed up queries by creating indexes on important columns
		15. JOINs: Combine data from multiple tables based on relationships
		16. CASE: Create conditional logic in queries (like IF statements)
		17. UNION ALL: Combine results from multiple SELECT statements into one list
		18. CHECK Constraints: Ensure data meets certain conditions (like risk_rating must be 'Low', 'Medium', or 'High')
*/

