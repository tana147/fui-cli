CREATE   PROC spAPI_EL_Log_XemHocLieu_Save
    @HocSinhID VARCHAR(20),
    @MonHocID INT,
    @HocLieuID INT,
    @NoiDungID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.tblEL_Log_XemHocLieu (HocSinhID, MonHocID, HocLieuID, NoiDungID, ViewTime, CreateTime)
    VALUES (@HocSinhID, @MonHocID, @HocLieuID, @NoiDungID, GETDATE(), GETDATE());

    SELECT 1 AS Status, N'Lưu log thành công' AS Message;
END
