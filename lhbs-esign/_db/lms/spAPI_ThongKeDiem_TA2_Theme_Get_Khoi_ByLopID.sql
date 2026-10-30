-- [dbo].[spAPI_ThongKeDiem_TA2_Theme_Get_All_Khoi] 2024, 10
CREATE PROC [dbo].[spAPI_ThongKeDiem_TA2_Theme_Get_Khoi_ByLopID] 
    @NienKhoa INT,
	@LopID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Tạo bảng tạm học sinh hợp lệ
    SELECT HocSinhID, Ho + ' ' + Ten AS HoTen
    INTO #Temp_HocSinh
    FROM dbo.tblHocSinh
    WHERE TinhTrang = 0;

    -- Tạo bảng tạm kết quả học tập hợp lệ, đã join sẵn các bảng liên quan
    SELECT 
        kqht.*,
        mhl.MonHocID,
        mhl.LopNhomID,
        n.KhoiID,
        n.TenNhom
    INTO #Temp_KQHT
    FROM dbo.tblKetQuaHocTap kqht
		INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID AND mhl.Enable = 1
		INNER JOIN dbo.tblNhom n ON n.NhomID = mhl.LopNhomID AND n.Enable = 1 and n.IsNhomLMS_GiaoBai = 0
    WHERE kqht.Enable = 1 AND kqht.NienKhoa = @NienKhoa AND kqht.LopID = @LopID;

    -- Tạo bảng tạm Template bảng điểm chi tiết hợp lệ
    SELECT ct.*
    INTO #Temp_Template
    FROM dbo.TemplateBangDiemChiTiet ct
    INNER JOIN dbo.TemplateBangDiem t ON t.TemplateBangDiemID = ct.TemplateBangDiemID
    WHERE ct.Enable = 1 AND t.Enable = 1 AND t.CapID = 3;

    -- Truy vấn 1: Dữ liệu điểm theo Theme1 -> Theme8
    SELECT 
        hs.HoTen,
        kq.HocSinhID,
        tmp.MaNhomCotDiem,
        tmp.TenNhomCotDiem_VI,
        tmp.MaCotDiem,
        tmp.TenCotDiem_VI,
        kq.KetQuaDanhGia_VI,
		kq.KhoiID
    FROM #Temp_KQHT kq
    INNER JOIN #Temp_Template tmp ON tmp.CotDiemID = kq.CotDiemID
        AND tmp.MaCotDiem IN (
            'Theme1_Total', 'Theme2_Total', 'Theme3_Total', 'Theme4_Total',
            'Theme5_Total', 'Theme6_Total', 'Theme7_Total', 'Theme8_Total'
        )
    INNER JOIN #Temp_HocSinh hs ON hs.HocSinhID = kq.HocSinhID
    ORDER BY tmp.MaCotDiem;

    ---- Truy vấn 2: Dữ liệu điểm giữa kỳ, cuối kỳ TA2
    --SELECT 
    --    hs.HoTen,
    --    kq.HocSinhID,
    --    kq.KhoiID,
    --    kq.KetQuaDanhGia_VI,
    --    tmp.MaNhomCotDiem,
    --    tmp.MaCotDiem
    --FROM #Temp_KQHT kq
    --INNER JOIN #Temp_Template tmp ON tmp.CotDiemID = kq.CotDiemID
    --    AND tmp.MaCotDiem IN (
    --        'S1_Mid_TA2_Avg_Point', 'S2_Mid_TA2_Avg_Point',
    --        'S1_Final_TA2_Avg_Point', 'S2_Final_TA2_Avg_Point', 'TA2_Avg_Point'
    --    )
    --INNER JOIN #Temp_HocSinh hs ON hs.HocSinhID = kq.HocSinhID
    --ORDER BY tmp.MaNhomCotDiem, tmp.MaCotDiem;

    -- Truy vấn 3: Dashboard điểm trung bình theo TA2
    SELECT 
        hs.HoTen,
        tmp.MaNhomCotDiem,
        tmp.TenNhomCotDiem_EN,
        tmp.MaCotDiem,
        tmp.TenCotDiem_EN,
        kq.KetQuaDanhGia_VI,
        kq.LopNhomID AS LopID,
        kq.TenNhom AS TenLop,
        tmp.Semester,
		kq.KhoiID
    FROM #Temp_KQHT kq
    INNER JOIN #Temp_HocSinh hs ON hs.HocSinhID = kq.HocSinhID
    INNER JOIN #Temp_Template tmp ON tmp.CotDiemID = kq.CotDiemID
    INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = kq.MonHocID AND mh.MonHocID = 76 AND mh.Enable = 1
    WHERE tmp.Semester IN ('HK1', 'HK2')
        AND tmp.GiaTriCotDiem = 'number'
        AND tmp.MaCotDiem IN (
			'S1_Mid_TA2_Listening_Point',
			'S1_Mid_TA2_Reading_Point',
			'S1_Mid_TA2_Writing_Point',
			'S1_Mid_TA2_Speaking_Point',
			'S1_Mid_TA2_Avg_Point',
			'S1_Final_TA2_Listening_Point',
			'S1_Final_TA2_Reading_Point',
			'S1_Final_TA2_Writing_Point',
			'S1_Final_TA2_Speaking_Point',
			'S1_Final_TA2_Avg_Point',
			'S2_Mid_TA2_Listening_Point',
			'S2_Mid_TA2_Reading_Point',
			'S2_Mid_TA2_Writing_Point',
			'S2_Mid_TA2_Speaking_Point',
			'S2_Mid_TA2_Avg_Point',
			'S2_Final_TA2_Listening_Point',
			'S2_Final_TA2_Reading_Point',
			'S2_Final_TA2_Writing_Point',
			'S2_Final_TA2_Speaking_Point',
			'S2_Final_TA2_Avg_Point'
		)
    ORDER BY tmp.ThuTuNhom, tmp.ThuTuCotDiem, tmp.MaNhomCotDiem, tmp.MaCotDiem;

    -- Xóa bảng tạm
    DROP TABLE IF EXISTS #Temp_HocSinh;
    DROP TABLE IF EXISTS #Temp_KQHT;
    DROP TABLE IF EXISTS #Temp_Template;
END;  