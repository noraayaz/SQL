use AdventureWorksDW2019

set statistics io on
set statistics time on

CREATE NONCLUSTERED INDEX idx_DimCustomer_CustomerKey_Incl_FirstName_LastName
ON DimCustomer (CustomerKey)
INCLUDE (FirstName, LastName);


CREATE INDEX idx_FactInternetSales_CustomerKey_SalesAmount ON FactInternetSales(CustomerKey) 
INCLUDE (SalesAmount);


-- Query 1/a: Using JOIN and GROUP BY
/* This version includes an additional column in the SELECT list, 
which slightly increases the data processing and memory overhead because 
it needs to handle and format the additional data for the output.*/

SELECT TOP 1
    DC.FirstName,
    DC.LastName,
	SUM(FIS.SalesAmount) AS TotalSpent
FROM
    FactInternetSales AS FIS
INNER JOIN
    DimCustomer AS DC ON FIS.CustomerKey = DC.CustomerKey
GROUP BY
    DC.CustomerKey, DC.FirstName, DC.LastName
ORDER BY
    TotalSpent DESC;

-- Query 1/b: Using JOIN and GROUP BY
-- Only the identification of the customer is required, Query 1/b would be more streamlined.

SELECT TOP 1
    DC.FirstName,
    DC.LastName
FROM
    FactInternetSales AS FIS
INNER JOIN
    DimCustomer AS DC ON FIS.CustomerKey = DC.CustomerKey
GROUP BY
    DC.CustomerKey, DC.FirstName, DC.LastName
ORDER BY
    SUM(FIS.SalesAmount) DESC;


-- Query 2: Using a Subquery

SELECT TOP 1
    DC.FirstName,
    DC.LastName
FROM
    DimCustomer AS DC
JOIN (
    SELECT
        CustomerKey,
        SUM(SalesAmount) AS TotalSpent
    FROM
        FactInternetSales
    GROUP BY
        CustomerKey
) AS FIS ON DC.CustomerKey = FIS.CustomerKey
ORDER BY
    FIS.TotalSpent DESC;


-- Query 3: Using CTE (Common Table Expressions)

WITH CustomerSales AS (
    SELECT
        CustomerKey,
        SUM(SalesAmount) AS TotalSpent
    FROM
        FactInternetSales
    GROUP BY
        CustomerKey
),
RankedCustomers AS (
    SELECT
        DC.CustomerKey,
        DC.FirstName,
        DC.LastName,
        RANK() OVER (ORDER BY CS.TotalSpent DESC) AS 'Rank'
    FROM
        DimCustomer AS DC
    JOIN
        CustomerSales CS ON DC.CustomerKey = CS.CustomerKey
)
SELECT TOP 1
    FirstName,
    LastName
FROM
    RankedCustomers
WHERE
    Rank = 1;



-- Query 4: Using a Subquery in the WHERE clause
SELECT
    FirstName,
    LastName
FROM
    DimCustomer AS DC
WHERE
    DC.CustomerKey = (
        SELECT TOP 1 CustomerKey
        FROM FactInternetSales
        GROUP BY CustomerKey
        ORDER BY SUM(SalesAmount) DESC);




