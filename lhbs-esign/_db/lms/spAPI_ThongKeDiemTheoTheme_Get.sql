
  --[dbo].[spAPI_ThongKeDiemTheoTheme_Get]  18100063, 2024 ,7
CREATE PROCEDURE [dbo].[spAPI_ThongKeDiemTheoTheme_Get]
    @HocSinhID INT,
    @NienKhoa INT,
    @KhoiID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @KhoiID BETWEEN 1 AND 9
    BEGIN
        -- Dành cho khối 1 đến 9 (bậc tiểu học / THCS), dùng tblLop
        SELECT 
            hs.Ho + ' ' + hs.Ten AS HoTen,
            hs.HocSinhID,
			tbdct.MaNhomCotDiem,
			tbdct.TenNhomCotDiem_VI,
            tbdct.MaCotDiem,
			tbdct.TenCotDiem_VI,
            kqht.KetQuaDanhGia_VI
        FROM 
            tblKetQuaHocTap kqht
        INNER JOIN TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = kqht.CotDiemID
        INNER JOIN tblHocSinh hs ON hs.HocSinhID = kqht.HocSinhID
        INNER JOIN tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID
        INNER JOIN tblLop l ON l.LopID = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
        WHERE 
            tbdct.MaCotDiem IN (
                'Theme1_Total', 'Theme2_Total', 'Theme3_Total', 'Theme4_Total',
                'Theme5_Total', 'Theme6_Total', 'Theme7_Total', 'Theme8_Total'
            )
            AND hs.HocSinhID = @HocSinhID
            AND tbdct.Enable = 1
            AND hs.TinhTrang = 0
            AND kqht.NienKhoa = @NienKhoa
            AND l.KhoiID = @KhoiID
			AND kqht.Enable = 1
        ORDER BY 
            tbdct.MaCotDiem
    END
    ELSE IF @KhoiID IN (10, 11, 12)
    BEGIN
        -- Dành cho khối 10 đến 12 (THPT), dùng tblNhom
        SELECT 
            hs.Ho + ' ' + hs.Ten AS HoTen,
            hs.HocSinhID,
			tbdct.MaNhomCotDiem,
			tbdct.TenNhomCotDiem_VI,
            tbdct.MaCotDiem,
			tbdct.TenCotDiem_VI,
            kqht.KetQuaDanhGia_VI
        FROM 
            tblKetQuaHocTap kqht
        INNER JOIN TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = kqht.CotDiemID
        INNER JOIN tblHocSinh hs ON hs.HocSinhID = kqht.HocSinhID
        INNER JOIN tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID
        INNER JOIN tblNhom n ON n.NhomID = mhl.LopNhomID and n.IsNhomLMS_GiaoBai = 0 
        WHERE 
            tbdct.MaCotDiem IN (
                'Theme1_Total', 'Theme2_Total', 'Theme3_Total', 'Theme4_Total',
                'Theme5_Total', 'Theme6_Total', 'Theme7_Total', 'Theme8_Total'
            )
            AND hs.HocSinhID = @HocSinhID
            AND tbdct.Enable = 1
            AND hs.TinhTrang = 0
            AND kqht.NienKhoa = @NienKhoa
            AND n.KhoiID = @KhoiID
			AND kqht.Enable = 1
        ORDER BY 
            tbdct.MaCotDiem
    END
END
