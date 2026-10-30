CREATE PROCEDURE [dbo].[spAPI_FP_NoiDung_GetDetail]
    @NoiDungID INT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Tự động lưu log xem học liệu nếu người dùng là Học sinh
    IF (@sys_UserID IS NOT NULL AND @sys_UserID <> '' AND ISNUMERIC(@sys_UserID) = 1)
    BEGIN
        DECLARE @MonHocID INT, @HocLieuID INT;

        SELECT @HocLieuID = HocLieuID 
        FROM dbo.tblNoiDungHocLieu_FP 
        WHERE NoiDungID = @NoiDungID;

        SELECT @MonHocID = MonHocID 
        FROM dbo.tblHocLieu_FP 
        WHERE HocLieuID = @HocLieuID;

        INSERT INTO dbo.tblEL_Log_XemHocLieu (HocSinhID, MonHocID, HocLieuID, NoiDungID, ViewTime, CreateTime)
        VALUES (@sys_UserID, @MonHocID, @HocLieuID, @NoiDungID, GETDATE(), GETDATE());
    END;

    SELECT
        NoiDungID,
        HocLieuID,
        TenNoiDung,
        LoaiNoiDung,
        DataJson
    FROM
        dbo.tblNoiDungHocLieu_FP
    WHERE
        NoiDungID = @NoiDungID
        AND Is_Xoa = 0;
END
