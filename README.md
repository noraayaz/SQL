# SQL Function: dbo.KontrollSiffra

This function takes a Swedish personal identity number (personnummer) as input and returns a boolean value indicating whether it is valid based on its checksum. 

The function is designed for SQL Server and checks the format and calculates the checksum using the Luhn algorithm (also known as the "modulus 10" method).

*  The function first removes any dashes or plus signs from the input to standardize the format.
*  It checks that the length of the cleaned number is either 10 or 12 characters, aligning with common formats (YYMMDD-XXXX or YYYYMMDDXXXX).
*  If the number is 12 characters long, the first two digits (century part) are removed to simplify the following checksum calculation.
*  The function implements the Luhn algorithm to compute the checksum. This involves iterating over each digit of the number, except the last one, and:
      *  Doubling the value of digits in odd positions.
      *  Keeping the value of digits in even positions as is.
      *  If doubling a digit results in a number greater than 9, the digits of the resulting number are summed (e.g., 16 becomes 1 + 6 = 7).
*  The sum of these modified values is computed.
*  To check the validity, the function calculates what the last digit should be so that the total sum including this digit is a multiple of 10.
*  The actual last digit of the personnummer is then compared against this calculated checksum digit.
*  The function returns 1 if the last digit matches the calculated checksum, indicating a valid personal number, and 0 otherwise.

# WWI_DW Database Management
Project Description

This SQL script is designed to establish a data warehouse named WWI_DW, specifically structured to manage historical sales data of the WorldWide Importers (WWI). The script creates dimension and fact tables using a star schema approach to facilitate efficient queries and reporting. Additionally, it includes stored procedures for updating these tables from the WWI operational database.

Schema Details

Dimension Tables
* DimCustomer: Stores customer details. Includes fields like CustomerID, CustomerName, and CustomerCategoryName.
* DimSalesPerson: Contains sales personnel data, combining first and last names into a full name using a persisted computed column.
* DimProduct: Manages product information such as SKUNumber and ProductName.
* DimDate: Holds detailed date information enabling time-based data analysis.
  
Fact Table

* FactSales: Captures sales transactions linking all dimensions, with fields such as OrderLineID, CustomerID, SalespersonPersonID, ProductID, OrderDateID, Quantity, and UnitPrice.
  
Stored Procedures

* UpdateTablesSP: A comprehensive procedure to refresh the dimension and fact tables from the source operational database (WideWorldImporters). It handles data transformation and loading with considerations for historical data tracking through INSERT_DATE.

Key Features

* Data Integrity: Enforced by primary and foreign keys, ensuring reliable data storage.
* Performance Optimization: Use of persisted computed columns to minimize runtime calculations.
* Historical Data Management: The INSERT_DATE column in each table allows for tracking changes and analyzing historical data.

Setup and Usage

1. Database Creation: Run the initial block to create the WWI_DW database and set it as the current database.
2. Table Creation: Execute the commands to create dimension and fact tables.
3. Stored Procedure Initialization: Implement the stored procedure for data updates.
4. Data Management: Use the EXEC dbo.UpdateTablesSP command to populate and refresh the tables.

SQL Scripts

* The repository includes scripts for creating the database, tables, and stored procedures.
* Additional queries for testing and validating data integrity.

Notes

* The setup assumes the existence of a source database (WideWorldImporters) from which it pulls data.
* Future enhancements could include more detailed customer dimensions or transaction tables to further enrich the data warehouse.
