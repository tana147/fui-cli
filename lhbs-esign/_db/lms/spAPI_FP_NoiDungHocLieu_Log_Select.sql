CREATE   PROCEDURE dbo.spAPI_FP_NoiDungHocLieu_Log_Select
    @TuNgay DATE,
    @DenNgay DATE,
    @Search NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Keyword NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Search)), N'');

    SELECT TOP (1000)
          L.LogID
        , L.EventID
        , L.AuditTime
        , L.AuditAction
        , CASE UPPER(L.AuditAction)
              WHEN 'I' THEN N'Thêm mới'
              WHEN 'U' THEN N'Cập nhật'
              WHEN 'D' THEN N'Xóa'
              ELSE N'Khác'
          END AS ActionLabel
        , L.AuditEvent
        , L.OperationName
        , NULLIF(LTRIM(RTRIM(CONCAT(GV.HoGV, N' ', GV.TenGV))), N'') AS NguoiThucHienHoTen
        , L.AuditUser AS NguoiThucHienMa
        , COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(GV.HoGV, N' ', GV.TenGV))), N''), NULLIF(LTRIM(RTRIM(L.AuditUserName)), N''), NULLIF(LTRIM(RTRIM(L.AuditUser)), '')) AS NguoiThucHien
        , L.SourceModule
        , L.HocLieuID
        , COALESCE(HL.TenHocLieu, N'') AS TenHocLieu
        , L.NoiDungID
        , L.TenNoiDung
        , L.LoaiNoiDung
        , L.KhoiID
        , L.MonHocID
        , COALESCE(MH.TenMonHoc_HienThi, MH.MonHocName, N'') AS TenMonHoc
        , L.BoSachID
        , L.NguonResourceType
        , L.NguonResourceID
    FROM dbo.tblNoiDungHocLieu_FP_Log L
    INNER JOIN dbo.tblHocLieu_FP HL
        ON HL.HocLieuID = L.HocLieuID
    LEFT JOIN dbo.tblMonHoc MH
        ON MH.MonHocID = COALESCE(L.MonHocID, HL.MonHocID)
    LEFT JOIN dbo.tblGiaoVien GV
        ON LTRIM(RTRIM(GV.GiaoVienID)) = LTRIM(RTRIM(L.AuditUser))
    WHERE (@TuNgay IS NULL OR L.AuditTime >= @TuNgay)
      AND (@DenNgay IS NULL OR L.AuditTime < DATEADD(DAY, 1, @DenNgay))
      -- Chỉ lấy học liệu số trực tiếp; bỏ các bản ghi mang nguồn Hồ sơ hoặc Tài nguyên.
      AND NULLIF(LTRIM(RTRIM(L.NguonResourceType)), '') IS NULL
      AND NULLIF(LTRIM(RTRIM(L.NguonTaiNguyenCode)), '') IS NULL
      AND L.NguonResourceID IS NULL
      AND ISNULL(HL.TenHocLieu, N'') NOT IN (N'Hồ sơ của tôi', N'Tài nguyên đã tải lên')
      AND (
            @Keyword IS NULL
            OR L.TenNoiDung LIKE N'%' + @Keyword + N'%'
            OR ISNULL(HL.TenHocLieu, N'') LIKE N'%' + @Keyword + N'%'
            OR ISNULL(MH.TenMonHoc_HienThi, MH.MonHocName) LIKE N'%' + @Keyword + N'%'
            OR ISNULL(LTRIM(RTRIM(CONCAT(GV.HoGV, N' ', GV.TenGV))), N'') LIKE N'%' + @Keyword + N'%'
            OR ISNULL(L.AuditUserName, N'') LIKE N'%' + @Keyword + N'%'
            OR ISNULL(L.AuditUser, '') LIKE '%' + @Keyword + '%'
            OR ISNULL(L.AuditEvent, '') LIKE '%' + @Keyword + '%'
            OR ISNULL(L.OperationName, N'') LIKE N'%' + @Keyword + N'%'
            OR ISNULL(L.SourceModule, '') LIKE '%' + @Keyword + '%'
            OR CONVERT(NVARCHAR(20), L.HocLieuID) LIKE N'%' + @Keyword + N'%'
            OR CONVERT(NVARCHAR(20), L.NoiDungID) LIKE N'%' + @Keyword + N'%'
          )
    ORDER BY L.AuditTime DESC, L.LogID DESC;
END;
