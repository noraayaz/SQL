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



 
 
