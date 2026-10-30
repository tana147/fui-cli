Create PROC [dbo].[spAPI_IO_IN_GiaoVien_Ins]
@GiaoVienObjArr NVARCHAR(MAX),
@SYS_UserID VARCHAR(9)
AS
BEGIN
    BEGIN TRANSACTION;
        MERGE INTO [dbo].[tblGiaoVien] AS target
        USING(
            SELECT
                    JSON_VALUE(value, '$.GiaoVienID') AS GiaoVienID,
                    JSON_VALUE(value, '$.HoGV') AS HoGV,
                    JSON_VALUE(value, '$.TenGV') AS TenGV
                FROM OPENJSON(@GiaoVienObjArr)
        ) AS source
        ON target.GiaoVienID = source.GiaoVienID
        WHEN MATCHED THEN
            UPDATE SET 
                target.HoGV = source.HoGV,
                target.TenGV = source.TenGV,
                target.UpdateUser = @SYS_UserID,
                target.UpdateTime = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT ([GiaoVienID], [HoGV], [TenGV], [CreateUser], [CreateTime])
            VALUES (source.[GiaoVienID], source.[HoGV], source.[TenGV], @SYS_UserID, GETDATE());

        -- Call your additional function here
        -- EXEC YourFunctionName;

    COMMIT TRANSACTION;
END