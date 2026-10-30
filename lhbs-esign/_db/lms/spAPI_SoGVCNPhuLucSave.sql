CREATE   PROCEDURE dbo.spAPI_SoGVCNPhuLucSave
    @SoGVCNID varchar(10),
    @JsonSiSo nvarchar(max),
    @JsonGiaoVienBoMon nvarchar(max),
    @JsonBanDaiDienCMHS nvarchar(max),
    @JsonCanBoLop nvarchar(max),
    @JsonHuongNghiep nvarchar(max),
    @sys_UserID varchar(10),
    @sys_SystemRight varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ID int = ISNULL(TRY_CONVERT(int, @SoGVCNID), 0);
    DECLARE @UserID int = ISNULL(TRY_CONVERT(int, @sys_UserID), 0);

    UPDATE dbo.tblSoGVCNSiSo SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
    INSERT INTO dbo.tblSoGVCNSiSo (SoGVCNID, Moc, SiSo, Nam, ChuyenDi, ChuyenDen, CreateUser, UpdateUser)
    SELECT @ID, Moc, TRY_CONVERT(int, SiSo), TRY_CONVERT(int, Nam), TRY_CONVERT(int, ChuyenDi), TRY_CONVERT(int, ChuyenDen), @UserID, @UserID
    FROM OPENJSON(ISNULL(@JsonSiSo, N'[]'))
    WITH (Moc nvarchar(50) '$.Moc', SiSo nvarchar(50) '$.SiSo', Nam nvarchar(50) '$.Nam', ChuyenDi nvarchar(50) '$.ChuyenDi', ChuyenDen nvarchar(50) '$.ChuyenDen')
    WHERE NULLIF(LTRIM(RTRIM(ISNULL(Moc, N''))), N'') IS NOT NULL;

    UPDATE dbo.tblSoGVCNGiaoVienBoMon SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
    INSERT INTO dbo.tblSoGVCNGiaoVienBoMon (SoGVCNID, BoMon, HocKy, GiaoVienID, GiaoVien, ThayDoi, RowIndex, CreateUser, UpdateUser)
    SELECT @ID, BoMon, HocKy, GiaoVienID, GiaoVien, ThayDoi, RowIndex, @UserID, @UserID
    FROM OPENJSON(ISNULL(@JsonGiaoVienBoMon, N'[]'))
    WITH (BoMon nvarchar(200) '$.BoMon', HocKy int '$.HocKy', GiaoVienID int '$.GiaoVienID', GiaoVien nvarchar(300) '$.GiaoVien', ThayDoi nvarchar(max) '$.ThayDoi', RowIndex int '$.RowIndex')
    WHERE NULLIF(LTRIM(RTRIM(CONCAT(BoMon, HocKy, GiaoVien, ThayDoi))), N'') IS NOT NULL;

    UPDATE dbo.tblSoGVCNBanDaiDienCMHS SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
    INSERT INTO dbo.tblSoGVCNBanDaiDienCMHS (SoGVCNID, STT, HSLopID, HocSinhID, MaHocSinh, HocSinh, ChaMe, NgheNghiep, DienThoai, NhiemVu, RowIndex, CreateUser, UpdateUser)
    SELECT @ID, STT, HSLopID, HocSinhID, MaHocSinh, HocSinh, ChaMe, NgheNghiep, DienThoai, NhiemVu, RowIndex, @UserID, @UserID
    FROM OPENJSON(ISNULL(@JsonBanDaiDienCMHS, N'[]'))
    WITH (STT int '$.STT', HSLopID int '$.HSLopID', HocSinhID int '$.HocSinhID', MaHocSinh varchar(30) '$.MaHocSinh', HocSinh nvarchar(200) '$.HocSinh', ChaMe nvarchar(max) '$.ChaMe', NgheNghiep nvarchar(max) '$.NgheNghiep', DienThoai nvarchar(200) '$.DienThoai', NhiemVu nvarchar(200) '$.NhiemVu', RowIndex int '$.RowIndex')
    WHERE NULLIF(LTRIM(RTRIM(CONCAT(HocSinh, ChaMe, NgheNghiep, DienThoai, NhiemVu))), N'') IS NOT NULL;

    UPDATE dbo.tblSoGVCNCanBoLop SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
    INSERT INTO dbo.tblSoGVCNCanBoLop (SoGVCNID, STT, HSLopID, HocSinhID, MaHocSinh, HocSinh, ChucVu, GhiChu, RowIndex, CreateUser, UpdateUser)
    SELECT @ID, STT, HSLopID, HocSinhID, MaHocSinh, HocSinh, ChucVu, GhiChu, RowIndex, @UserID, @UserID
    FROM OPENJSON(ISNULL(@JsonCanBoLop, N'[]'))
    WITH (STT int '$.STT', HSLopID int '$.HSLopID', HocSinhID int '$.HocSinhID', MaHocSinh varchar(30) '$.MaHocSinh', HocSinh nvarchar(200) '$.HocSinh', ChucVu nvarchar(200) '$.ChucVu', GhiChu nvarchar(max) '$.GhiChu', RowIndex int '$.RowIndex')
    WHERE NULLIF(LTRIM(RTRIM(CONCAT(HocSinh, ChucVu, GhiChu))), N'') IS NOT NULL;

    UPDATE dbo.tblSoGVCNHuongNghiep SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
    INSERT INTO dbo.tblSoGVCNHuongNghiep (SoGVCNID, STT, HSLopID, HocSinhID, MaHocSinh, HoTen, MonThiTN, KQTracNghiem, RowIndex, CreateUser, UpdateUser)
    SELECT @ID, STT, HSLopID, HocSinhID, MaHocSinh, HoTen, MonThiTN, KQTracNghiem, RowIndex, @UserID, @UserID
    FROM OPENJSON(ISNULL(@JsonHuongNghiep, N'[]'))
    WITH (STT int '$.STT', HSLopID int '$.HSLopID', HocSinhID int '$.HocSinhID', MaHocSinh varchar(30) '$.MaHocSinh', HoTen nvarchar(200) '$.HoTen', MonThiTN nvarchar(500) '$.MonThiTN', KQTracNghiem nvarchar(max) '$.KQTracNghiem', RowIndex int '$.RowIndex')
    WHERE NULLIF(LTRIM(RTRIM(CONCAT(HoTen, MonThiTN, KQTracNghiem))), N'') IS NOT NULL;

    UPDATE dbo.tblSoGVCN
    SET TrangThai = CASE WHEN TrangThai = 'NEW' THEN 'DRAFT' ELSE TrangThai END,
        UpdateUser = @UserID,
        UpdateTime = GETDATE()
    WHERE SoGVCNID = @ID
      AND Enable = 1;

    SELECT mess = N'Đã lưu phụ lục sổ GVCN', SoGVCNID = @ID;
END
