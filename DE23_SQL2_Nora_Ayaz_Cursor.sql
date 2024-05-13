CREATE PROC usp_indexera
AS
BEGIN
    -- Denna procedur ombygger index för alla användartabeller i den aktuella databasen.
    SET NOCOUNT ON; -- Undvik att visa antal påverkade rader för varje SQL-kommando.

    -- Deklaration av variabler
    DECLARE @TableName NVARCHAR(255); -- Namnet på tabellen som ska indexeras.
    DECLARE @SQLCommand NVARCHAR(MAX); -- Variabel för det dynamiska SQL-kommandot.
    DECLARE @starttid DATETIME2 = GETDATE(); -- Starttiden för ombyggnadsprocessen.

    -- Definiera en cursor för att iterera över alla användartabeller.
    DECLARE table_cursor CURSOR FOR
    SELECT name 
    FROM sys.tables 
    WHERE name != 'sysdiagrams' -- Undantag sysdiagrams-tabellen.
    ORDER BY name; -- Sortera tabellnamnen i bokstavsordning.

    -- Öppna cursorn
    OPEN table_cursor;

    -- Börja iterera över tabellerna med cursorn.
    FETCH NEXT FROM table_cursor INTO @TableName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Skapa det dynamiska SQL-kommandot för ombyggnad av index.
        SET @SQLCommand = 'ALTER INDEX ALL ON ' + QUOTENAME(@TableName) + ' REBUILD;';
        /* ALTER INDEX ALL ON återuppbygger alla index på den angivna tabellen.
           REBUILD-alternativet återskapar indexet från grunden, vilket kan förbättra prestandan genom att minska fragmentering. 
           QUOTENAME-funktionen säkerställer korrekt hantering av tabellnamnet och minskar risken för SQL-injektion. */
        
        -- Försök att utföra det dynamiska SQL-kommandot.
        BEGIN TRY
            EXEC sp_executesql @SQLCommand;
            PRINT 'Index ombyggda för tabellen ' + @TableName; -- Lyckat meddelande
        END TRY
        BEGIN CATCH
            PRINT 'Fel vid ombyggnad av index för tabellen ' + @TableName + ': ' + ERROR_MESSAGE(); -- Felmeddelande
        END CATCH;

        -- Hämta nästa tabellnamn.
        FETCH NEXT FROM table_cursor INTO @TableName;
    END;

    -- Stäng och deallokera cursorn.
    CLOSE table_cursor;
    DEALLOCATE table_cursor;

    -- Visa tiden för processens start och slut, samt beräkna den totala tiden för processen.
    SELECT @starttid AS 'Starttid', GETDATE() AS 'Sluttid', DATEDIFF(SECOND, @starttid, GETDATE()) AS 'Total Tid (sekunder)';

    -- Återaktivera meddelanden om antal påverkade rader.
    SET NOCOUNT OFF;
END;
GO

-- Exekvera den lagrade proceduren för att ombygga index.
EXEC usp_indexera;
