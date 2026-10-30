-- Dán vào SQL Server Management Studio và chạy
CREATE PROCEDURE [dbo].[spAPI_HocLieu_Save]
    @HocLieuID INT,
    @TenHocLieu NVARCHAR(500),
    @LoaiHocLieu VARCHAR(50),
    @ParentID INT,
    @MonHocLopID INT,
    @ThuTu INT,
    @NoiDung NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Nếu không có ParentID, set là NULL
    IF @ParentID = 0 SET @ParentID = NULL;

    IF ISNULL(@HocLieuID, 0) > 0
    BEGIN
        -- CẬP NHẬT
        UPDATE dbo.tblHocLieu
        SET 
            TenHocLieu = @TenHocLieu,
            LoaiHocLieu = @LoaiHocLieu,
            ParentID = @ParentID,
            MonHocLopID = @MonHocLopID,
            ThuTu = @ThuTu,
            NoiDung = @NoiDung,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE HocLieuID = @HocLieuID;

        -- Trả về dữ liệu vừa cập nhật
        SELECT * FROM dbo.tblHocLieu WHERE HocLieuID = @HocLieuID;
    END
    ELSE
    BEGIN
        -- TẠO MỚI
        INSERT INTO dbo.tblHocLieu (TenHocLieu, LoaiHocLieu, ParentID, MonHocLopID, ThuTu, NoiDung, CreateUser, CreateTime)
        VALUES (@TenHocLieu, @LoaiHocLieu, @ParentID, @MonHocLopID, @ThuTu, @NoiDung, @sys_UserID, GETDATE());

        -- Trả về dữ liệu vừa tạo (bao gồm ID mới)
        DECLARE @NewID INT = SCOPE_IDENTITY();
        SELECT * FROM dbo.tblHocLieu WHERE HocLieuID = @NewID;
    END
END
