CREATE FUNCTION dbo.KontrollSiffra (@personnummer VARCHAR(20)) 
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT = 0

	-- Om personnumret innehåller bindestreck eller plus-tecken, ta bort dem.   
    SET @personnummer = REPLACE(@personnummer, '-', '')
    SET @personnummer = REPLACE(@personnummer, '+', '')

	-- Kontrollera längden.   
    IF (LEN(@personnummer) = 10 OR LEN(@personnummer) = 12) 
    BEGIN

		-- Enligt regeln ska sekeldelen av födelseåret, som är en av siffrorna som utgör personnumret, inte tas.
		SET @personnummer = RIGHT(@personnummer, 10)
	
        DECLARE @total INT = 0
        DECLARE @index INT = 1
       
		-- Ta alla index på personnumret utom det sista indexet ett efter ett.
        WHILE @index < 10
        BEGIN
            DECLARE @digit INT = CAST(SUBSTRING(@personnummer, @index, 1) AS INT)
            DECLARE @result INT

			-- Enligt regeln, multiplicera udda index med 2 och jämna index med 1.
            IF @index % 2 = 1
                SET @result = @digit * 2 
            ELSE
                SET @result = @digit

            -- Enligt regeln, om resultatet är större än 9, summera de numeriska värdena för resultatet.
            IF @result > 9
                SET @total = @total + (@result / 10) + (@result % 10)
            ELSE
                SET @total = @total + @result

            SET @index = @index + 1
        END

		-- Enligt regeln, ta mod10 av summan och subtrahera den från talet 10.
        DECLARE @calculatedLastDigit INT = (10 - (@total % 10)) % 10
        DECLARE @lastDigit INT = CAST(RIGHT(@personnummer, 1) AS INT)

		-- Jämför beräknad och faktisk kontrollsiffra.       
        IF @lastDigit = @calculatedLastDigit
            SET @isValid = 1
   END

    RETURN @isValid
	
END
