CREATE PROC [dbo].[spAPI_NhanXetThang_Get]
    @LopID              INT
  , @Lop_NhanXetThangID INT
  , @NienKhoa           INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NienKhoaID INT = @NienKhoa;
    IF (@NienKhoaID IS NULL OR @NienKhoaID = 0)
    BEGIN
        SELECT TOP 1 @NienKhoaID = NienKhoa FROM dbo.tblNhanXetThang_Lop WHERE Lop_NhanXetThangID = @Lop_NhanXetThangID;
    END;

    IF (@NienKhoaID IS NULL OR @NienKhoaID = 0)
    BEGIN
        RAISERROR(N'NienKhoa là bắt buộc khi lấy nhận xét theo LopID.', 16, 1);
        RETURN;
    END;

    SELECT ISNULL(nxt.NhanXetThangID, 0) AS NhanXetThangID
		 ,  nxt_l.Lop_NhanXetThangID
         , hsl.HocSinhID
         , hsl.HSLopID
         , hs.Ho + ' ' + hs.Ten          AS HoTen
         , hsl.SoDanhBo
         , hs.NgaySinh
         , hs.Nu
         , nxt.NhanXetCuoiNam_HTML
         , nxt.DiemToan
         , nxt.SoSao_Toan
         , nxt.NhanXetToan_HTML
         , nxt.DiemTiengViet
         , nxt.SoSao_TiengViet
         , nxt.NhanXetTiengViet_HTML
         , nxt.NhanXetMonHocKhac_HTML
         , nxt.HoatDongGiaoDucKhac_HTML
         , nxt.PhamChatNangLuc_HTML
         , nxt.NoiDungKienThuc_HTML
         , nxt.NoiDungNangLuc_HTML
         , nxt.NoiDungHoatDongKhac_HTML
		, nxt.PhoiHopCMHS
		, nxt.NhanXetGVCN_VePhuHuynh_HTML
		, nxt.NhanXetGVCN_VeHocSinh_HTML
		, nxt.PhanLoai_TuyenThang
		, nxt.Flyers
		, nxt.DiemTA
		, nxt.DKHocTiep
		, nxt.DeXuat_NDCamKet
		, nxt.UuDiem		 
		,	nxt.NhuocDiem	 
		,	nxt.DeXuat		 
		, nxt.NhanXetGVCN
		, nxt.NhanXet_ChuanBiNienKhoaSau
	,(
    SELECT DISTINCT hsn.NhomID, n.TenNhom, hsn.HocSinhID
    FROM dbo.tblHocSinhNhom hsn 
        INNER JOIN tblNhom n ON n.NienKhoa = @NienKhoaID
                             AND n.Enable = 1 
                             AND n.NhomID = hsn.NhomID
    WHERE hsn.HocSinhID = hsl.HocSinhID
    FOR JSON PATH
) AS DSNhom
    FROM
           dbo.tblHocSinhLop                 AS hsl
           INNER JOIN dbo.tblLop             AS l ON l.LopID = hsl.LopID
                                                 AND l.NienKhoa = hsl.NienKhoa
                                                 AND l.Enable = 1
                                                 AND l.NienKhoa = @NienKhoaID
           LEFT JOIN dbo.tblNhanXetThang     AS nxt ON nxt.HSLopID                = hsl.HSLopID
                                                   AND nxt.Lop_NhanXetThangID     = @Lop_NhanXetThangID
                                                   AND nxt.Enable                 = 1
           LEFT JOIN dbo.tblNhanXetThang_Lop AS nxt_l ON nxt_l.Lop_NhanXetThangID = nxt.Lop_NhanXetThangID
                                                     AND nxt_l.Enable             = 1
           INNER JOIN dbo.tblHocSinh         AS hs ON hs.HocSinhID                = hsl.HocSinhID
                                                  AND hs.TinhTrang                = 0
    WHERE
           hsl.LopID = @LopID
		-- Một học sinh chỉ thuộc tập kết quả khi đúng cả lớp và niên khóa đang chọn.
		AND hsl.NienKhoa = @NienKhoaID
		AND hsl.Enable = 1
	ORDER BY
		hsl.SoDanhBo,
		hs.Ten;
END;
