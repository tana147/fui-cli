CREATE PROCEDURE [dbo].[spAPI_FILE_FileDeleteMulti]
    @FileIDs VARCHAR(MAX)
AS
    BEGIN
        DECLARE @Table_File_Ids AS TABLE(FileID CHAR(32) NOT NULL);
        INSERT INTO @Table_File_Ids(FileID)
        SELECT DISTINCT
            TRY_CAST(LTRIM(RTRIM(value)) AS CHAR(32))
        FROM STRING_SPLIT(@FileIDs, ',')
        WHERE TRY_CAST(LTRIM(RTRIM(value)) AS CHAR(32)) IS NOT NULL;
        DELETE f
        FROM dbo.FileData f
             JOIN @Table_File_Ids tb ON tb.FileID = f.FileID;
    END;
