CREATE   PROCEDURE dbo.spAPI_FP_NoiDungHocLieu_Log_GetDetail
    @LogID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
          L.LogID
        , L.EventID
        , L.NoiDungID
        , L.HocLieuID
        , COALESCE(HL.TenHocLieu, N'') AS TenHocLieu
        , L.ParentID
        , L.TenNoiDung
        , L.LoaiNoiDung
        , L.ThuTu
        , L.DataJson
        , L.Is_Xoa
        , L.CreateTime
        , L.CreateUser
        , L.UpdateTime
        , L.UpdateUser
        , L.NguonTaiNguyenCode
        , L.NguonResourceType
        , L.NguonResourceID
        , L.AuditAction
        , CASE UPPER(L.AuditAction)
              WHEN 'I' THEN N'Thêm mới'
              WHEN 'U' THEN N'Cập nhật'
              WHEN 'D' THEN N'Xóa'
              ELSE N'Khác'
          END AS ActionLabel
        , L.AuditEvent
        , L.AuditTime
        , L.AuditUser
        , L.AuditUserName
        , NULLIF(LTRIM(RTRIM(CONCAT(GV.HoGV, N' ', GV.TenGV))), N'') AS NguoiThucHienHoTen
        , L.AuditUser AS NguoiThucHienMa
        , COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(GV.HoGV, N' ', GV.TenGV))), N''), NULLIF(LTRIM(RTRIM(L.AuditUserName)), N''), NULLIF(LTRIM(RTRIM(L.AuditUser)), '')) AS NguoiThucHien
        , L.SourceModule
        , L.BeforeData
        , L.AfterData
        , L.BoSachID
        , L.KhoiID
        , L.MonHocID
        , COALESCE(MH.TenMonHoc_HienThi, MH.MonHocName, N'') AS TenMonHoc
        , L.OperationID
        , L.OperationName
    FROM dbo.tblNoiDungHocLieu_FP_Log L
    INNER JOIN dbo.tblHocLieu_FP HL
        ON HL.HocLieuID = L.HocLieuID
    LEFT JOIN dbo.tblMonHoc MH
        ON MH.MonHocID = COALESCE(L.MonHocID, HL.MonHocID)
    LEFT JOIN dbo.tblGiaoVien GV
        ON LTRIM(RTRIM(GV.GiaoVienID)) = LTRIM(RTRIM(L.AuditUser))
    WHERE L.LogID = @LogID
      -- Áp dụng cùng phạm vi với danh sách, không trả chi tiết Hồ sơ/Tài nguyên.
      AND NULLIF(LTRIM(RTRIM(L.NguonResourceType)), '') IS NULL
      AND NULLIF(LTRIM(RTRIM(L.NguonTaiNguyenCode)), '') IS NULL
      AND L.NguonResourceID IS NULL
      AND ISNULL(HL.TenHocLieu, N'') NOT IN (N'Hồ sơ của tôi', N'Tài nguyên đã tải lên');
END;
