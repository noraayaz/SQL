CREATE PROC usp_indexera
AS
BEGIN
    -- Denna procedur ombygger index f�r alla anv�ndartabeller i den aktuella databasen.
    SET NOCOUNT ON; -- Undvik att visa antal p�verkade rader f�r varje SQL-kommando.

    -- Deklaration av variabler
    DECLARE @TableName NVARCHAR(255); -- Namnet p� tabellen som ska indexeras.
    DECLARE @SQLCommand NVARCHAR(MAX); -- Variabel f�r det dynamiska SQL-kommandot.
    DECLARE @starttid DATETIME2 = GETDATE(); -- Starttiden f�r ombyggnadsprocessen.

    -- Definiera en cursor f�r att iterera �ver alla anv�ndartabeller.
    DECLARE table_cursor CURSOR FOR
    SELECT name 
    FROM sys.tables 
    WHERE name != 'sysdiagrams' -- Undantag sysdiagrams-tabellen.
    ORDER BY name; -- Sortera tabellnamnen i bokstavsordning.

    -- �ppna cursorn
    OPEN table_cursor;

    -- B�rja iterera �ver tabellerna med cursorn.
    FETCH NEXT FROM table_cursor INTO @TableName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Skapa det dynamiska SQL-kommandot f�r ombyggnad av index.
        SET @SQLCommand = 'ALTER INDEX ALL ON ' + QUOTENAME(@TableName) + ' REBUILD;';
        /* ALTER INDEX ALL ON �teruppbygger alla index p� den angivna tabellen.
           REBUILD-alternativet �terskapar indexet fr�n grunden, vilket kan f�rb�ttra prestandan genom att minska fragmentering. 
           QUOTENAME-funktionen s�kerst�ller korrekt hantering av tabellnamnet och minskar risken f�r SQL-injektion. */
        
        -- F�rs�k att utf�ra det dynamiska SQL-kommandot.
        BEGIN TRY
            EXEC sp_executesql @SQLCommand;
            PRINT 'Index ombyggda f�r tabellen ' + @TableName; -- Lyckat meddelande
        END TRY
        BEGIN CATCH
            PRINT 'Fel vid ombyggnad av index f�r tabellen ' + @TableName + ': ' + ERROR_MESSAGE(); -- Felmeddelande
        END CATCH;

        -- H�mta n�sta tabellnamn.
        FETCH NEXT FROM table_cursor INTO @TableName;
    END;

    -- St�ng och deallokera cursorn.
    CLOSE table_cursor;
    DEALLOCATE table_cursor;

    -- Visa tiden f�r processens start och slut, samt ber�kna den totala tiden f�r processen.
    SELECT @starttid AS 'Starttid', GETDATE() AS 'Sluttid', DATEDIFF(SECOND, @starttid, GETDATE()) AS 'Total Tid (sekunder)';

    -- �teraktivera meddelanden om antal p�verkade rader.
    SET NOCOUNT OFF;
END;
GO

-- Exekvera den lagrade proceduren f�r att ombygga index.
EXEC usp_indexera;
