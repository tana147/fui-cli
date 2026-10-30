CREATE PROCEDURE spAPI_AUTH_TKB_Lich_Del_Mutiple
    @JsonIDs NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH IDs AS (
        SELECT DISTINCT
            TRY_CONVERT(INT,
                CASE
                    WHEN LEFT(LTRIM([value]), 1) = '{'
                        THEN JSON_VALUE([value], '$.TKBLichID')
                    ELSE [value]
                END
            ) AS TKBLichID
        FROM OPENJSON(ISNULL(@JsonIDs, N'[]'))
    )
    DELETE L
    FROM dbo.tblTKB_Lich AS L
    INNER JOIN IDs AS I ON I.TKBLichID = L.TKBLichID
    WHERE I.TKBLichID IS NOT NULL;

    SELECT @@ROWCOUNT AS DeletedCount;
END
