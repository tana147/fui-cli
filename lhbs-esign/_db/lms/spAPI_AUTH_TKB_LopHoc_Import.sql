CREATE PROCEDURE spAPI_AUTH_TKB_LopHoc_Import
    @SYS_USERID VARCHAR(50),
    @NamHoc VARCHAR(20),
    @Rows NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        LopHocID,
        NamHoc,
        KhoiID,
        TenLop,
        GVCN,
        GVCN_HoTro,
        HinhThucLop,
        LoaiLop
    INTO #TempLopHoc
    FROM OPENJSON(@Rows)
    WITH (
        LopHocID INT '$.LopHocID',
        NamHoc VARCHAR(20) '$.NamHoc',
        KhoiID INT '$.KhoiID',
        TenLop NVARCHAR(200) '$.TenLop',
        GVCN NVARCHAR(200) '$.GVCN',
        GVCN_HoTro NVARCHAR(200) '$.GVCN_HoTro',
        HinhThucLop INT '$.HinhThucLop',
        LoaiLop INT '$.LoaiLop'
    );
    
    -- 1. Cập nhật những lớp đã có trong DB LMS nếu thông tin thay đổi.
    -- Không xóa lớp còn lại vì bảng này chưa có DonViID; đồng bộ từng cơ sở
    -- không đủ thông tin để kết luận lớp của cơ sở khác đã bị xóa.
    UPDATE t
    SET t.KhoiID = s.KhoiID,
        t.TenLop = s.TenLop,
        t.GVCN = s.GVCN,
        t.GVCN_HoTro = s.GVCN_HoTro,
        t.HinhThucLop = s.HinhThucLop,
        t.NgayDongBo = GETDATE()
    FROM tblTKB_LopHoc t
    INNER JOIN #TempLopHoc s ON t.NamHoc = s.NamHoc AND t.LopHocID = s.LopHocID
    WHERE ISNULL(t.TenLop, '') <> ISNULL(s.TenLop, '')
       OR ISNULL(t.GVCN, '') <> ISNULL(s.GVCN, '')
       OR ISNULL(t.GVCN_HoTro, '') <> ISNULL(s.GVCN_HoTro, '')
       OR ISNULL(t.KhoiID, 0) <> ISNULL(s.KhoiID, 0)
       OR ISNULL(t.HinhThucLop, 0) <> ISNULL(s.HinhThucLop, 0);

    -- 2. Thêm mới những lớp chưa có trong DB LMS.
    INSERT INTO tblTKB_LopHoc (LopHocID, NamHoc, KhoiID, TenLop, GVCN, GVCN_HoTro, HinhThucLop, NgayDongBo, Nguon)
    SELECT s.LopHocID, s.NamHoc, s.KhoiID, s.TenLop, s.GVCN, s.GVCN_HoTro, s.HinhThucLop, GETDATE(), 'Calen'
    FROM #TempLopHoc s
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_LopHoc t 
        WHERE t.NamHoc = s.NamHoc AND t.LopHocID = s.LopHocID
    );
    
    SELECT 1 AS Result, 'Upsert LopHoc success' AS Message;
END;
