-- ==========================================================
-- SP LƯU/CẬP NHẬT MỘT MỤC TRONG CÂY NỘI DUNG
-- ==========================================================
CREATE PROCEDURE [dbo].[spAPI_FP_NoiDung_Save]
    @NoiDungID INT,
    @HocLieuID INT,
    @ParentID INT,
    @TenNoiDung NVARCHAR(500),
    @LoaiNoiDung VARCHAR(50),
    @ThuTu INT,
    @DataJson NVARCHAR(MAX),
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF @ParentID = 0 SET @ParentID = NULL;

    IF ISNULL(@NoiDungID, 0) > 0
    BEGIN
        -- CẬP NHẬT
        UPDATE dbo.tblNoiDungHocLieu_FP
        SET TenNoiDung = @TenNoiDung, LoaiNoiDung = @LoaiNoiDung, ParentID = @ParentID,
            ThuTu = @ThuTu, DataJson = @DataJson, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE NoiDungID = @NoiDungID;
        SELECT * FROM dbo.tblNoiDungHocLieu_FP WHERE NoiDungID = @NoiDungID;
    END
    ELSE
    BEGIN
        -- TẠO MỚI
        INSERT INTO dbo.tblNoiDungHocLieu_FP (HocLieuID, ParentID, TenNoiDung, LoaiNoiDung, ThuTu, DataJson, CreateUser, CreateTime)
        VALUES (@HocLieuID, @ParentID, @TenNoiDung, @LoaiNoiDung, @ThuTu, @DataJson, @sys_UserID, GETDATE());
        DECLARE @NewID INT = SCOPE_IDENTITY();
        SELECT * FROM dbo.tblNoiDungHocLieu_FP WHERE NoiDungID = @NewID;
    END
END
