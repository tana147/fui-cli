--[spAPI_ThongKeDiemTA2_ByHocSinh] 15100164, 2024, 10
CREATE PROCEDURE [dbo].[spAPI_ThongKeDiemTA2_ByHocSinh]
    @HocSinhID INT,
    @NienKhoa INT,
    @KhoiID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra KhoiID hợp lệ
    IF @KhoiID NOT IN (10, 11, 12)
    BEGIN
        RAISERROR(N'Chỉ cho phép KhoiID là 10, 11 hoặc 12.', 16, 1);
        RETURN;
    END

    SELECT 
        hs.Ho + ' ' + hs.Ten AS HoTen,
        hs.HocSinhID,
        n.KhoiID,
        kqht.KetQuaDanhGia_VI,
        tbdct.MaNhomCotDiem,
        tbdct.MaCotDiem
    FROM tblKetQuaHocTap kqht
    INNER JOIN TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = kqht.CotDiemID
    INNER JOIN tblHocSinh hs ON hs.HocSinhID = kqht.HocSinhID
    INNER JOIN tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID
    INNER JOIN tblNhom n ON n.NhomID = kqht.LopID and n.IsNhomLMS_GiaoBai = 0
    WHERE 
        tbdct.MaCotDiem IN (
            'S1_Mid_TA2_Avg_Point',
            'S2_Mid_TA2_Avg_Point',
            'S1_Final_TA2_Avg_Point',
            'S2_Final_TA2_Avg_Point',
			'TA2_Avg_Point' 
        )
        AND hs.HocSinhID = @HocSinhID
        AND tbdct.Enable = 1
        AND hs.TinhTrang = 0
        AND kqht.NienKhoa = @NienKhoa
        AND n.KhoiID = @KhoiID
        AND kqht.Enable = 1
	ORDER BY MaNhomCotDiem, MaCotDiem

     SELECT 
        hs.Ho + ' ' + hs.Ten AS HoTen,
        hs.HocSinhID,
        n.KhoiID,
        kqht.KetQuaDanhGia_VI,
        tbdct.MaNhomCotDiem,
        tbdct.MaCotDiem
    FROM tblKetQuaHocTap kqht
    INNER JOIN TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = kqht.CotDiemID
    INNER JOIN tblHocSinh hs ON hs.HocSinhID = kqht.HocSinhID
    INNER JOIN tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID
    INNER JOIN tblNhom n ON n.NhomID = kqht.LopID and n.IsNhomLMS_GiaoBai = 0
    WHERE 
        tbdct.MaCotDiem IN (
            'S1_Mid_IELTS_Band_Conv',
            'S1_Final_IELTS_Band_Conv',
            'S2_Mid_IELTS_Band_Conv',
            'S2_Final_IELTS_Band_Conv'
        )
        AND hs.HocSinhID = @HocSinhID
        AND tbdct.Enable = 1
        AND hs.TinhTrang = 0
        AND kqht.NienKhoa = @NienKhoa
        AND n.KhoiID = @KhoiID
        AND kqht.Enable = 1
	ORDER BY MaNhomCotDiem, MaCotDiem
END
