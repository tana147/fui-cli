CREATE PROCEDURE spAPI_AUTH_TKB_LopHoc_Get
    @SYS_USERID VARCHAR(50),
    @NamHoc VARCHAR(20),
    @KhoiID INT,
    @CapHoc INT,
    @MaDonVi INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        l.LopHocID,
        l.NamHoc,
        l.KhoiID,
        l.TenLop,
        l.GVCN,
        l.GVCN_HoTro,
        l.HinhThucLop,
        l.NgayDongBo
    FROM tblTKB_LopHoc l
    LEFT JOIN tblTKB_Khoi k ON l.NamHoc = k.NamHoc AND l.KhoiID = k.KhoiID
    WHERE (@NamHoc IS NULL OR l.NamHoc = @NamHoc)
      AND (ISNULL(@KhoiID, 0) = 0 OR l.KhoiID = @KhoiID)
      AND (ISNULL(@MaDonVi, 0) = 0 OR k.DonViID = @MaDonVi)
      AND (
            @CapHoc IS NULL 
            OR (@CapHoc = 0 AND (l.KhoiID <= 5 OR l.KhoiID >= 19 OR l.KhoiID < 0 OR k.TenKhoi LIKE N'%Tháng%' OR k.TenKhoi LIKE N'%Mầm%' OR k.TenKhoi LIKE N'%Chồi%' OR k.TenKhoi LIKE N'%Lá%' OR k.TenKhoi LIKE N'%Nhà trẻ%')) -- Cấp 0: Mầm non
            OR (@CapHoc = 1 AND (l.KhoiID >= 6 AND l.KhoiID <= 10)) -- Cấp 1: Tiểu học
            OR (@CapHoc = 2 AND (l.KhoiID >= 11 AND l.KhoiID <= 14)) -- Cấp 2: THCS
            OR (@CapHoc = 3 AND (l.KhoiID >= 15 AND l.KhoiID <= 17)) -- Cấp 3: THPT
          )
    ORDER BY l.HinhThucLop, l.TenLop;
END;
