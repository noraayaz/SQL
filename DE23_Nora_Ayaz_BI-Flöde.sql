-- Skapa en ny databas WWI_DW
CREATE DATABASE WWI_DW;
GO

-- Anv�nd den skapade databasen
USE WWI_DW;
GO

-- Skapa dimensionstabeller
CREATE TABLE DimCustomer (
    CustomerID INT PRIMARY KEY NOT NULL,
    CustomerName VARCHAR(50),
    CustomerCategoryName VARCHAR(50),
	INSERT_DATE DATE --Tack vare INSERT_DATE-variabeln deklarerad som en infogningsvariabel f�r varje tabell kan vi veta 
					 --n�r data infogas och det �r m�jligt att filtrera historiska data mellan vilket intervall som helst.
);

CREATE TABLE DimSalesPerson (
    SalespersonPersonID INT PRIMARY KEY NOT NULL,
    Lastname VARCHAR(50),
	Firstname VARCHAR(50),
    Fullname AS COALESCE(Firstname + ' ', '') + Lastname PERSISTED, -- en ber�knad kolumnens v�rde kan sparas fysiskt p� disken med 'PERSISTED', inte beh�ver ber�knas varje g�ng det beh�vs. 
	INSERT_DATE DATE  											    -- 'COALESCE' anv�nds f�r att s�kerst�lla att f�r- och efternamnen inte �r tomma.
);

CREATE TABLE DimProduct (
    ProductID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    SKUNumber INT UNIQUE,
    ProductName VARCHAR(255), 
	INSERT_DATE DATE
);

CREATE TABLE DimDate (
    DateID INT PRIMARY KEY NOT NULL,
    Date DATE,
    Year INT,
    Month INT,
    MonthName VARCHAR(20),
    Weekday INT,
    WeekdayName VARCHAR(20),
    Week INT,
    Day INT,
    Quarter INT,
    QuarterName VARCHAR(10), 
	INSERT_DATE DATE
);

-- Skapa faktatabell
CREATE TABLE FactSales (
	OrderLineID INT PRIMARY KEY NOT NULL,-- Eftersom jag beh�vde prim�rnyckeln i faktatabellen lade jag till orderLine-kolumnen fr�n sales.orderLines, d�r jag �ven fick kvantitet och enhetspris.
	CustomerID INT,
    SalespersonPersonID INT,
    ProductID INT,
	OrderDateID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18, 2) NOT NULL,
    Sales AS (Quantity * UnitPrice) PERSISTED,
	FOREIGN KEY (SalespersonPersonID) REFERENCES DimSalesPerson(SalespersonPersonID),
	FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID),
    FOREIGN KEY (OrderDateID) REFERENCES DimDate(DateID), 
	INSERT_DATE DATE
);

	
-- Fasen f�r att skapa Stored Procedures
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Detta skript h�mtar all data i WorldWide Importers Warehouse till WWI_DW-databasen. 
-- Tack vare de begr�nsningar som anv�nds vid skapandet av tabellerna h�mtas data utan dubbletter.
-- Eftersom det finns begr�nsningar som prim�rnyckel, fr�mmande nyckel i tabellerna, kommer inga data att dupliceras i databasen.
-- =============================================

CREATE PROCEDURE UpdateTablesSP
AS
BEGIN 
--Tack vare INSERT_DATE-variabeln deklarerad som en infogningsvariabel f�r varje tabell kan vi veta 
--n�r data infogas och det �r m�jligt att filtrera historiska data mellan vilket intervall som helst.
DECLARE @INSERT_DATE DATE = GETDATE();
	
	-- Fyll DimCustomer med data som kommer fr�n [WideWorldImporters]
	INSERT INTO DimCustomer (CustomerID, CustomerName, CustomerCategoryName, INSERT_DATE)
	SELECT 
		SC.CustomerID, 
		SC.CustomerName, 
		SCC.CustomerCategoryName,
		@INSERT_DATE
	FROM 
		WideWorldImporters.Sales.Customers SC
	JOIN 
		WideWorldImporters.Sales.CustomerCategories SCC ON SC.CustomerCategoryID = SCC.CustomerCategoryID;


	-- Fyll DimSalesPerson med data som kommer fr�n [WideWorldImporters]
	-- Jag tar f�rnamnet och efternamnet fr�n det fullst�ndiga namnet i Application.People och v�rdena d�r IsSalesperson = 1 som SalesPerson.
	INSERT INTO DimSalesPerson (salespersonPersonID, Lastname, Firstname, INSERT_DATE)
	SELECT 
		PersonID, 
		SUBSTRING(FullName, CHARINDEX(' ', FullName) + 1, LEN(FullName) - CHARINDEX(' ', FullName)), 
		LEFT(FullName, CHARINDEX(' ', FullName) - 1),
		@INSERT_DATE
	FROM 
		WideWorldImporters.Application.People where IsSalesperson = 1


	-- Fyll DimProduct med data som kommer fr�n [WideWorldImporters]
	INSERT INTO DimProduct (SKUNumber, ProductName, INSERT_DATE)
	SELECT
		StockItemID, 
		StockItemName,
		@INSERT_DATE
	FROM   
		WideWorldImporters.Warehouse.StockItems


-- Generera datum f�r att fylla DimDate
DECLARE @startDate DATE;
SELECT @startDate = ISNULL(DATEADD(DAY, 1, MAX(Date)), '2010-01-01') FROM DimDate

IF @startDate < @INSERT_DATE
BEGIN
	WITH DateRange AS (
		SELECT @startDate AS Date
		UNION ALL
		SELECT DATEADD(DAY, 1, Date)
		FROM DateRange
		WHERE Date < @INSERT_DATE
	)

	-- Fyll DimDate 
	INSERT INTO DimDate (DateID, Date, Year, Month, MonthName, Weekday, WeekdayName, Week, Day, Quarter, QuarterName, INSERT_DATE)
	SELECT
		CAST(CONVERT(VARCHAR, Date, 112) AS INT) AS DateID,
		Date,
		YEAR(Date) AS Year,
		MONTH(Date) AS Month,
		CASE 
			WHEN MONTH(Date) = 1 THEN 'Januari'
			WHEN MONTH(Date) = 2 THEN 'Februari'
			WHEN MONTH(Date) = 3 THEN 'Mars'
			WHEN MONTH(Date) = 4 THEN 'April'
			WHEN MONTH(Date) = 5 THEN 'Maj'
			WHEN MONTH(Date) = 6 THEN 'Juni'
			WHEN MONTH(Date) = 7 THEN 'Juli'
			WHEN MONTH(Date) = 8 THEN 'Augusti'
			WHEN MONTH(Date) = 9 THEN 'September'
			WHEN MONTH(Date) = 10 THEN 'Oktober'
			WHEN MONTH(Date) = 11 THEN 'November'
			WHEN MONTH(Date) = 12 THEN 'December'
		END AS MonthName,
		DATEPART(WEEKDAY, Date) AS Weekday,
		CASE 
			WHEN DATEPART(WEEKDAY, Date) = 1 THEN 'S�ndag'
			WHEN DATEPART(WEEKDAY, Date) = 2 THEN 'M�ndag'
			WHEN DATEPART(WEEKDAY, Date) = 3 THEN 'Tisdag'
			WHEN DATEPART(WEEKDAY, Date) = 4 THEN 'Onsdag'
			WHEN DATEPART(WEEKDAY, Date) = 5 THEN 'Torsdag'
			WHEN DATEPART(WEEKDAY, Date) = 6 THEN 'Fredag'
			WHEN DATEPART(WEEKDAY, Date) = 7 THEN 'L�rdag'
		END AS WeekdayName,
		DATEPART(WEEK, Date) AS Week,
		DAY(Date) AS Day,
		DATEPART(QUARTER, Date) AS Quarter,
		'Q' + CAST(DATEPART(QUARTER, Date) AS VARCHAR) AS QuarterName,
		@INSERT_DATE
	FROM DateRange
	-- Genom att l�gga till 'OPTION (MAXRECURSION 0)' kan vi st�lla in det maximala antalet rekursiva samtal till noll.
	OPTION (MAXRECURSION 0);
END

	
	    -- Fyll FactSales med data som kommer fr�n [WideWorldImporters]
		INSERT INTO FactSales (OrderLineID, CustomerID, SalespersonPersonID, ProductID, OrderDateID, Quantity, UnitPrice, INSERT_DATE)
		SELECT
			SOL.OrderLineID,
			DC.CustomerID,
			DS.SalespersonPersonID,
			DP.ProductID,
			DD.DateID,
			SOL.Quantity,
			SOL.UnitPrice,
			@INSERT_DATE
		FROM 
				WideWorldImporters.Sales.Orders SO 
			JOIN
				WideWorldImporters.Sales.OrderLines SOL ON SOL.OrderID = SO.OrderID
			JOIN
				DimCustomer DC ON SO.CustomerID = DC.CustomerID
			JOIN 
				DimSalesPerson DS ON DS.SalespersonPersonID = SO.SalespersonPersonID
			JOIN 
				DimDate DD ON SO.OrderDate = DD.Date
			JOIN
				DimProduct DP ON DP.SKUNumber = SOL.StockItemID
	
END

-- Vi kan k�ra processen n�r vi vill med f�ljande kommando;
EXEC dbo.UpdateTablesSP

-- 
Select * from FactSales
Select * from DimCustomer
Select * from DimDate
Select * from DimSalesPerson
Select * from DimProduct


/****** Under normala omst�ndigheter borde databasen vi skapade vara mycket mer omfattande. 
Till exempel kan ordertabell och transaktionstabell l�ggas till. Mer detaljerade tabeller beh�vs f�r att utv�rdera data korrekt. 
Dessutom kan tabeller med dimensioner ocks� ha dimensioner. 
Till exempel kan personlig information om kunder inkluderas i dimensionstabellen i kundtabellen. */


