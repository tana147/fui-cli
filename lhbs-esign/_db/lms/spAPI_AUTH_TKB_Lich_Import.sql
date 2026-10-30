CREATE PROCEDURE dbo.spAPI_AUTH_TKB_Lich_Import
    @NienKhoa VARCHAR(20), @MaDonVi INT, @Rows NVARCHAR(MAX), @SYS_USERID VARCHAR(50) = NULL,
    @MaxTuan INT = 52, @TuanID INT = 0, @CapHoc INT = 0, @HocKy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SelectedTuanID INT = @TuanID;
    IF @SelectedTuanID = 0
        SELECT TOP 1 @SelectedTuanID = COALESCE(TRY_CONVERT(INT, JSON_VALUE([value], '$.TuanID')), 0)
        FROM OPENJSON(@Rows);
    IF @SelectedTuanID = 0
        SELECT TOP 1 @SelectedTuanID = COALESCE(TRY_CONVERT(INT, JSON_VALUE([value], '$.Tuan')), 0)
        FROM OPENJSON(@Rows);
    IF @SelectedTuanID = 0 RETURN;

    DECLARE @TempTKB TABLE (
        NienKhoa VARCHAR(20), HocKy INT, CapHoc INT, LopHocID INT, Lop NVARCHAR(200), Thu INT, BuoiID INT, Tiet INT,
        MonHocID INT, MaMon VARCHAR(50), TenMonHoc NVARCHAR(200), GiaoVienID VARCHAR(50), GhiChu NVARCHAR(MAX),
        MaDonVi INT, TuanID INT, ThoiKhoaBieu_CalenID VARCHAR(50)
    );

    INSERT INTO @TempTKB
    SELECT @NienKhoa, COALESCE(j.HocKy, @HocKy), COALESCE(NULLIF(j.CapHoc, 0), @CapHoc),
        COALESCE(NULLIF(j.LopHocID, 0), lopMap.LopHocID, 0), j.Lop, j.Thu, j.BuoiID, j.Tiet,
        j.MonHocID, j.MaMon, j.TenMonHoc, COALESCE(j.GiaoVienID, ''), COALESCE(j.GhiChu, ''), @MaDonVi,
        @SelectedTuanID, COALESCE(j.ThoiKhoaBieu_CalenID, '')
    FROM OPENJSON(@Rows) WITH (
        HocKy INT '$.HocKy', CapHoc INT '$.CapHoc', LopHocID INT '$.LopHocID', Lop NVARCHAR(200) '$.Lop', Thu INT '$.Thu',
        BuoiID INT '$.BuoiID', Tiet INT '$.Tiet', MonHocID INT '$.MonHocID', MaMon VARCHAR(50) '$.MaMon',
        TenMonHoc NVARCHAR(200) '$.TenMonHoc', GiaoVienID VARCHAR(50) '$.GiaoVienID', GhiChu NVARCHAR(MAX) '$.GhiChu',
        ThoiKhoaBieu_CalenID VARCHAR(50) '$.ThoiKhoaBieu_CalenID'
    ) j
    OUTER APPLY (
        SELECT TOP 1 H.LopHocID
        FROM dbo.tblTKB_LopHoc H
        WHERE H.NamHoc = @NienKhoa
          AND LOWER(LTRIM(RTRIM(H.TenLop))) = LOWER(LTRIM(RTRIM(j.Lop)))
        ORDER BY H.LopHocID
    ) lopMap;

    DELETE FROM dbo.tblTKB_Lich
    WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi AND CapHoc = @CapHoc AND TuanID = @SelectedTuanID;

    INSERT INTO dbo.tblTKB_Lich
        (NienKhoa, HocKy, CapHoc, MaDonVi, TuanID, LopHocID, Lop, Thu, BuoiID, Tiet,
         MonHocID, MaMon, TenMonHoc, GiaoVienID, GhiChu, ThoiKhoaBieu_CalenID, NgayTao, NguoiTao)
    SELECT NienKhoa, HocKy, CapHoc, MaDonVi, TuanID, LopHocID, Lop, Thu, BuoiID, Tiet,
        MonHocID, MaMon, TenMonHoc, GiaoVienID, GhiChu, ThoiKhoaBieu_CalenID, GETDATE(), @SYS_USERID
    FROM @TempTKB;

    SELECT L.TKBLichID, L.NienKhoa, L.HocKy, L.CapHoc, L.MaDonVi, L.TuanID,
        L.LopHocID, L.Lop, L.Thu, L.BuoiID, L.Tiet,
        L.MonHocID, L.MaMon, L.TenMonHoc, L.GiaoVienID, L.GhiChu,
        L.ThoiKhoaBieu_CalenID, L.NgayTao
    FROM dbo.tblTKB_Lich L WITH (NOLOCK)
    WHERE L.NienKhoa = @NienKhoa AND L.MaDonVi = @MaDonVi AND L.CapHoc = @CapHoc AND L.TuanID = @SelectedTuanID
    ORDER BY L.Thu, L.BuoiID, L.Tiet, L.Lop;
END
