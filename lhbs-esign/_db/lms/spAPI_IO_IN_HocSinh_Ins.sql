CREATE PROC [dbo].[spAPI_IO_IN_HocSinh_Ins]
@HocSinhObjArr NVARCHAR(MAX),
@SYS_UserID VARCHAR(9)
AS
BEGIN
    BEGIN TRANSACTION;
        MERGE INTO [dbo].[tblHocSinh] AS target
        USING(
            SELECT
                    JSON_VALUE(value, '$.HocSinhID') AS HocSinhID,
                    JSON_VALUE(value, '$.Ho') AS Ho,
                    JSON_VALUE(value, '$.Ten') AS Ten,
                    JSON_VALUE(value, '$.NgaySinh') AS NgaySinh,
                    JSON_VALUE(value, '$.Nu') AS Nu,
					JSON_VALUE(value, '$.TinhTrang') AS TinhTrang,
					JSON_VALUE(value, '$.TenTinhTrang') AS TenTinhTrang
                FROM OPENJSON(@HocSinhObjArr)
        ) AS source
        ON target.HocSinhID = source.HocSinhID
        WHEN MATCHED THEN
            UPDATE SET 
                target.Ho = source.Ho,
                target.Ten = source.Ten,
                target.NgaySinh = source.NgaySinh,
                target.Nu = source.Nu,
				target.TinhTrang = source.TinhTrang,
				target.TenTinhTrang = source.TenTinhTrang
        WHEN NOT MATCHED THEN
            INSERT ([HocSinhID], [Ho], [Ten], [NgaySinh], [Nu], [TinhTrang], [TenTinhTrang])
            VALUES (source.[HocSinhID], source.[Ho], source.[Ten], source.[NgaySinh], source.[Nu], source.[TinhTrang], source.[TenTinhTrang]);

        -- Call your additional function here
        -- EXEC YourFunctionName;

    COMMIT TRANSACTION;
END

