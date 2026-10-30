CREATE PROC [dbo].[spAPI_GiaoVienLop_Get_ByLopID]
    @LopID NVARCHAR(200),
    @NienKhoa INT,
    @HocKi INT,             
    @ToGiangDayID INT,
    @GiaoVienID Nvarchar(50),
    @VaiTro INT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
    BEGIN
        RAISERROR(N'NienKhoa là bắt buộc khi tra phân công theo LopID.', 16, 1);
        RETURN;
    END;

    DECLARE @MaDonVi INT;
    DECLARE @KhoiID INT;

    -- Lấy thông tin MaDonVi và KhoiID của lớp hoặc lớp nhóm theo Niên khóa
    SELECT TOP 1
        @MaDonVi = MaDonVi, 
        @KhoiID = KhoiID
    FROM tblLop L 
    WHERE L.LopID = @LopID
      AND L.NienKhoa = @NienKhoa
      AND L.Enable = 1;

    -- Lớp nhóm dùng NhomID và không có dòng tương ứng trong tblLop.
    IF @KhoiID IS NULL
    BEGIN
        SELECT TOP 1
            @MaDonVi = MaDonVi,
            @KhoiID = KhoiID
        FROM tblNhom
        WHERE NhomID = @LopID
          AND NienKhoa = @NienKhoa
          AND Enable = 1;
    END;

    -- Sử dụng DISTINCT để loại bỏ dữ liệu trùng lặp
    SELECT DISTINCT
        GVL.GVLopID,
        GVL.[GiaoVienID],
        GV.HoGV + N' ' + GV.TenGV AS HoTenGV,
        GVL.[KhoiID],
        GVL.[LopID],
        GVL.[MonHocID],
        mh.MonHocName,
        GVL.[VaiTro],
        GVL.MaDonVi,
        GVL.ToGiangDayID
    FROM tblGiaoVienLop GVL
    INNER JOIN tblGiaoVien GV ON GVL.GiaoVienID = GV.GiaoVienID
    LEFT JOIN tblMonHoc mh ON mh.MonHocID = GVL.MonHocID
    WHERE 
        (GVL.LopID = @LopID OR 
        (GVL.VaiTro = @VaiTro AND GVL.MaDonVi = @MaDonVi AND GVL.KhoiID = @KhoiID))
        AND GVL.Enable = 1
        AND GVL.KhoiID = @KhoiID
        AND GVL.NienKhoa = @NienKhoa
        AND GVL.HocKy = @HocKi
        AND (@ToGiangDayID IS NULL OR GVL.ToGiangDayID = @ToGiangDayID)
        AND (@GiaoVienID IS NULL OR GVL.GiaoVienID = @GiaoVienID)

    UNION

    -- Nếu lớp này chưa được phân công GVCN trong tblGiaoVienLop cho học kỳ này, lấy từ tblLop.GVCN
    SELECT 
        0 AS GVLopID,
        L.GVCN AS GiaoVienID,
        GV.HoGV + N' ' + GV.TenGV AS HoTenGV,
        L.KhoiID,
        L.LopID,
        0 AS MonHocID,
        N'' AS MonHocName,
        1 AS VaiTro,
        L.MaDonVi,
        0 AS ToGiangDayID
    FROM tblLop L
    INNER JOIN tblGiaoVien GV ON L.GVCN = GV.GiaoVienID
    WHERE L.LopID = @LopID 
      AND L.Enable = 1 
      AND L.NienKhoa = @NienKhoa
      AND L.GVCN IS NOT NULL 
      AND L.GVCN <> ''
      AND NOT EXISTS (
          SELECT 1 
          FROM tblGiaoVienLop GVL2 
          WHERE GVL2.LopID = @LopID 
            AND GVL2.VaiTro = 1 
            AND GVL2.Enable = 1 
            AND GVL2.NienKhoa = @NienKhoa 
            AND GVL2.HocKy = @HocKi
      )

    UNION

    -- Tương tự cho lớp nhóm: GVCN được lưu tại tblNhom.
    SELECT
        0 AS GVLopID,
        N.GVCN AS GiaoVienID,
        GV.HoGV + N' ' + GV.TenGV AS HoTenGV,
        N.KhoiID,
        N.NhomID AS LopID,
        0 AS MonHocID,
        N'' AS MonHocName,
        1 AS VaiTro,
        N.MaDonVi,
        0 AS ToGiangDayID
    FROM tblNhom N
    INNER JOIN tblGiaoVien GV ON N.GVCN = GV.GiaoVienID
    WHERE N.NhomID = @LopID
      AND N.Enable = 1
      AND N.NienKhoa = @NienKhoa
      AND N.GVCN IS NOT NULL
      AND N.GVCN <> ''
      AND NOT EXISTS (
          SELECT 1
          FROM tblGiaoVienLop GVL2
          WHERE GVL2.LopID = @LopID
            AND GVL2.VaiTro = 1
            AND GVL2.Enable = 1
            AND GVL2.NienKhoa = @NienKhoa
            AND GVL2.HocKy = @HocKi
      )
    ORDER BY 
        VaiTro;
END;