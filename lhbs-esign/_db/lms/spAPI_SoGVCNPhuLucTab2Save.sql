CREATE   PROCEDURE dbo.spAPI_SoGVCNPhuLucTab2Save
    @SoGVCNID varchar(10),
    @JsonSiSo nvarchar(max),
    @JsonGiaoVienBoMon nvarchar(max),
    @JsonBanDaiDienCMHS nvarchar(max),
    @JsonCanBoLop nvarchar(max),
    @JsonToNhomHocSinh nvarchar(max),
    @sys_UserID varchar(10),
    @sys_SystemRight varchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    -- FUI supplies a string user identity; audit triggers read it from SESSION_CONTEXT.
    DECLARE @AuditUser varchar(20) = COALESCE(NULLIF(LTRIM(RTRIM(@sys_UserID)), ''), 'unknown/unavailable');
    EXEC sys.sp_set_session_context
        @key = N'SoGVCN_UserID',
        @value = @AuditUser;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ID int = ISNULL(TRY_CONVERT(int, @SoGVCNID), 0);
        DECLARE @UserID int = ISNULL(TRY_CONVERT(int, @sys_UserID), 0);

        UPDATE dbo.tblSoGVCNSiSo SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
        INSERT INTO dbo.tblSoGVCNSiSo (SoGVCNID, Moc, MocDanhMucID, SiSo, Nam, ChuyenDi, ChuyenDen, CreateUser, UpdateUser)
        SELECT @ID, source.Moc, dm.DanhMucID, TRY_CONVERT(int, source.SiSo), TRY_CONVERT(int, source.Nam), TRY_CONVERT(int, source.ChuyenDi), TRY_CONVERT(int, source.ChuyenDen), @UserID, @UserID
        FROM OPENJSON(ISNULL(@JsonSiSo, N'[]'))
        WITH (Moc nvarchar(50) '$.Moc', SiSo nvarchar(50) '$.SiSo', Nam nvarchar(50) '$.Nam', ChuyenDi nvarchar(50) '$.ChuyenDi', ChuyenDen nvarchar(50) '$.ChuyenDen')
        source
        LEFT JOIN dbo.tblSoGVCNDanhMuc dm ON dm.Loai = 'MOC_SI_SO' AND dm.Ten = source.Moc AND dm.Enable = 1
        WHERE NULLIF(LTRIM(RTRIM(ISNULL(source.Moc, N''))), N'') IS NOT NULL;

        UPDATE dbo.tblSoGVCNGiaoVienBoMon SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
        INSERT INTO dbo.tblSoGVCNGiaoVienBoMon (SoGVCNID, MonHocID, BoMon, HocKy, GiaoVienID, GiaoVien, ThayDoi, RowIndex, CreateUser, UpdateUser)
        SELECT @ID, mh.MonHocID, source.BoMon, source.HocKy,
            COALESCE(source.GiaoVienID, gv.GiaoVienID), source.GiaoVien, source.ThayDoi, source.RowIndex, @UserID, @UserID
        FROM OPENJSON(ISNULL(@JsonGiaoVienBoMon, N'[]'))
        WITH (MonHocID int '$.MonHocID', BoMon nvarchar(200) '$.BoMon', HocKy int '$.HocKy', GiaoVienID varchar(10) '$.GiaoVienID', GiaoVien nvarchar(300) '$.GiaoVien', ThayDoi nvarchar(max) '$.ThayDoi', RowIndex int '$.RowIndex') source
        OUTER APPLY
        (
            SELECT TOP (1) mh.MonHocID
            FROM dbo.tblMonHoc mh
            WHERE mh.Enable = 1
              AND (
                    mh.MonHocID = source.MonHocID
                    OR (
                        (source.MonHocID IS NULL OR source.MonHocID <= 0)
                        AND NULLIF(LTRIM(RTRIM(ISNULL(source.BoMon, N''))), N'') IS NOT NULL
                        AND mh.MonHocName = source.BoMon
                    )
                  )
            ORDER BY CASE WHEN mh.MonHocID = source.MonHocID THEN 0 ELSE 1 END, mh.MonHocID
        ) mh
        OUTER APPLY
        (
            SELECT TOP (1) gv.GiaoVienID
            FROM dbo.tblGiaoVien gv
            WHERE LTRIM(RTRIM(CONCAT(gv.HoGV, N' ', gv.TenGV))) = LTRIM(RTRIM(source.GiaoVien))
              AND gv.Enable = 1
            ORDER BY gv.GiaoVienID
        ) gv
        WHERE NULLIF(LTRIM(RTRIM(CONCAT(source.BoMon, source.HocKy, source.GiaoVien, source.ThayDoi))), N'') IS NOT NULL
          AND mh.MonHocID IS NOT NULL;

        UPDATE dbo.tblSoGVCNBanDaiDienCMHS SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
        INSERT INTO dbo.tblSoGVCNBanDaiDienCMHS (SoGVCNID, STT, HSLopID, HocSinhID, MaHocSinh, HocSinh, ChaMe, NgheNghiep, DienThoai, NhiemVuDanhMucID, NhiemVu, GhiChu, RowIndex, CreateUser, UpdateUser)
        SELECT @ID, source.STT,
            TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(source.HSLopID)), N'')),
            TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(source.HocSinhID)), N'')),
            source.MaHocSinh, source.HocSinh, source.ChaMe, source.NgheNghiep, source.DienThoai,
            dm.DanhMucID, source.NhiemVu, source.GhiChu, source.RowIndex, @UserID, @UserID
        FROM OPENJSON(ISNULL(@JsonBanDaiDienCMHS, N'[]'))
        WITH (STT int '$.STT', HSLopID nvarchar(30) '$.HSLopID', HocSinhID nvarchar(30) '$.HocSinhID', MaHocSinh varchar(30) '$.MaHocSinh', HocSinh nvarchar(200) '$.HocSinh', ChaMe nvarchar(max) '$.ChaMe', NgheNghiep nvarchar(max) '$.NgheNghiep', DienThoai nvarchar(200) '$.DienThoai', NhiemVu nvarchar(200) '$.NhiemVu', GhiChu nvarchar(max) '$.GhiChu', RowIndex int '$.RowIndex') source
        LEFT JOIN dbo.tblSoGVCNDanhMuc dm ON dm.Loai = 'NHIEM_VU_CMHS' AND dm.Ten = source.NhiemVu AND dm.Enable = 1
        WHERE NULLIF(LTRIM(RTRIM(CONCAT(source.HocSinh, source.ChaMe, source.NgheNghiep, source.DienThoai, source.NhiemVu, source.GhiChu))), N'') IS NOT NULL;

        UPDATE dbo.tblSoGVCNCanBoLop SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE() WHERE SoGVCNID = @ID;
        INSERT INTO dbo.tblSoGVCNCanBoLop (SoGVCNID, STT, HSLopID, HocSinhID, MaHocSinh, HocSinh, ChucVuDanhMucID, ChucVu, GhiChu, RowIndex, CreateUser, UpdateUser)
        SELECT @ID, source.STT,
            TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(source.HSLopID)), N'')),
            TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(source.HocSinhID)), N'')),
            source.MaHocSinh, source.HocSinh, dm.DanhMucID, source.ChucVu, source.GhiChu,
            source.RowIndex, @UserID, @UserID
        FROM OPENJSON(ISNULL(@JsonCanBoLop, N'[]'))
        WITH (STT int '$.STT', HSLopID nvarchar(30) '$.HSLopID', HocSinhID nvarchar(30) '$.HocSinhID', MaHocSinh varchar(30) '$.MaHocSinh', HocSinh nvarchar(200) '$.HocSinh', ChucVu nvarchar(200) '$.ChucVu', GhiChu nvarchar(max) '$.GhiChu', RowIndex int '$.RowIndex') source
        LEFT JOIN dbo.tblSoGVCNDanhMuc dm ON dm.Loai = 'CHUC_VU_LOP' AND dm.Ten = source.ChucVu AND dm.Enable = 1
        WHERE NULLIF(LTRIM(RTRIM(CONCAT(source.HocSinh, source.ChucVu, source.GhiChu))), N'') IS NOT NULL;

    -- NULL nghĩa là client cũ không gửi trường này: giữ nguyên dữ liệu hiện có.
        IF @JsonToNhomHocSinh IS NOT NULL
        BEGIN
            UPDATE dbo.tblSoGVCNToNhomHocSinh
            SET Enable = 0, UpdateUser = @UserID, UpdateTime = GETDATE()
            WHERE SoGVCNID = @ID;

            INSERT INTO dbo.tblSoGVCNToNhomHocSinh
                (SoGVCNID, HSLopID, HocSinhID, MaHocSinh, HocSinh, ToNhom, NhiemVu, Ban, RowIndex, CreateUser, UpdateUser)
            SELECT
                @ID,
                TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(source.HSLopID)), N'')),
                TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(source.HocSinhID)), N'')),
                source.MaHocSinh, source.HocSinh,
                source.ToNhom, source.NhiemVu, source.Ban, source.RowIndex, @UserID, @UserID
            FROM OPENJSON(@JsonToNhomHocSinh)
            WITH (
                HSLopID nvarchar(30) '$.HSLopID',
                HocSinhID nvarchar(30) '$.HocSinhID',
                MaHocSinh varchar(30) '$.MaHocSinh',
                HocSinh nvarchar(200) '$.HocSinh',
                ToNhom nvarchar(100) '$.ToNhom',
                NhiemVu nvarchar(200) '$.NhiemVu',
                Ban nvarchar(200) '$.Ban',
                RowIndex int '$.RowIndex'
            ) source
            WHERE NULLIF(LTRIM(RTRIM(CONCAT(source.ToNhom, source.NhiemVu, source.Ban))), N'') IS NOT NULL;
        END;

        UPDATE dbo.tblSoGVCN
        SET TrangThai = CASE WHEN TrangThai = 'NEW' THEN 'DRAFT' ELSE TrangThai END,
            UpdateUser = @UserID,
            UpdateTime = GETDATE()
        WHERE SoGVCNID = @ID
          AND Enable = 1;

        COMMIT TRANSACTION;
        SELECT mess = N'Đã lưu phụ lục tab chỉ tiêu', SoGVCNID = @ID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
