CREATE PROCEDURE [dbo].[spAPI_WF_InstanceData_GetList]
    @sys_UserID VARCHAR(9),
    @InstanceID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    WITH ActiveFieldMapping AS (
        SELECT 
            DefinitionID,
            FieldName,
            FieldLabel,
            FieldType,
            ROW_NUMBER() OVER (PARTITION BY DefinitionID, FieldName ORDER BY MappingID DESC) as RowNum
        FROM dbo.tblWF_FieldMapping
        WHERE [Enable] = 1
    ),
    LatestInstanceData AS (
        SELECT 
            InstanceID,
            FieldName,
            FieldValue,
            ROW_NUMBER() OVER (PARTITION BY InstanceID, FieldName ORDER BY InstanceDataID DESC) as RowNum
        FROM dbo.tblWF_InstanceData
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1
    )
    SELECT
        D.InstanceID,
        D.FieldName,
        D.FieldValue,
        M.FieldLabel,
        M.FieldType
    FROM LatestInstanceData AS D
    INNER JOIN dbo.tblWF_Instance AS I ON I.InstanceID = D.InstanceID
    LEFT JOIN ActiveFieldMapping AS M ON M.DefinitionID = I.DefinitionID AND M.FieldName = D.FieldName AND M.RowNum = 1
    WHERE D.RowNum = 1;
END
