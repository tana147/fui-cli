

--spAPI_FileData_GetByID  'GV0000611' ,  'B148416B9E5D40CF84A5861F5DBAF63B'
CREATE PROCEDURE [dbo].[spAPI_FileData_GetByID]
(
    @sys_UserID NVARCHAR(50),
    @FileID VARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tham số đầu vào
    IF @FileID IS NULL
    BEGIN
        RAISERROR(N'FileID không được để trống.', 16, 1);
        RETURN;
    END

    -- Truy vấn dữ liệu file
    SELECT 
        f.FileID,
        f.FileName,
        f.BinaryContent
    FROM 
        [eSignature_File].[dbo].[tblFileData] f
    WHERE 
        f.FileID = @FileID;
END;