-- EXEC [dbo].[spAPI_BaoCao_Cambridge_C2] 6, 2025,'GK_HK1'

-- EXEC [dbo].[spAPI_BaoCao_Cambridge_C2] 6, 2025,'CK_HK1'
CREATE PROCEDURE [dbo].[spAPI_BaoCao_Cambridge_C2]
    @KhoiID int,
	@NienKhoa INT ,
    @HocKi varchar(10) = 'GK_HK1'
as
begin
  DECLARE @Semester VARCHAR(20) = 'GK_HK1'
--DECLARE @NienKhoa INT = 2025
--DECLARE @KhoiID INT = 6

IF(@HocKi  = 'GK_HK1') SET @Semester = 'S1_Mid'
IF(@HocKi  = 'CK_HK1') SET @Semester = 'S1_Final'
IF(@HocKi  = 'GK_HK2') SET @Semester = 'S2_Mid'
IF(@HocKi  = 'CK_HK2') SET @Semester = 'S2_Final'

DECLARE @Table_x TABLE (
	TenLop NVARCHAR(50),
	TongSoHocSinh INT,
	KhoiID INT,
	SL_Doc_CD	INT,
	SL_Doc_D	INT,
	SL_Doc_VYC	INT,
	TL_Doc_CD	FLOAT,
	TL_Doc_D	FLOAT,
	TL_Doc_VYC	FLOAT,

	SL_Nghe_CD	INT,
	SL_Nghe_D	INT,
	SL_Nghe_VYC	INT,
	TL_Nghe_CD	FLOAT,
	TL_Nghe_D	FLOAT,
	TL_Nghe_VYC	FLOAT,

	SL_Noi_CD	INT,
	SL_Noi_D	INT,
	SL_Noi_VYC	INT,
	TL_Noi_CD	FLOAT,
	TL_Noi_D	FLOAT,
	TL_Noi_VYC	FLOAT,

	SL_Viet_CD	INT,
	SL_Viet_D	INT,
	SL_Viet_VYC	INT,
	TL_Viet_CD	FLOAT,
	TL_Viet_D	FLOAT,
	TL_Viet_VYC	FLOAT,

	SL_DanhGiaChung_CD	INT,
	SL_DanhGiaChung_D	INT,
	SL_DanhGiaChung_VYC	INT,
	TL_DanhGiaChung_CD	FLOAT,
	TL_DanhGiaChung_D	FLOAT,
	TL_DanhGiaChung_VYC	FLOAT
)


INSERT INTO @Table_x 
 SELECT 
	l.TenLop,
	COUNT(DISTINCT hsl.HocSinhID) AS TongSoHocSinh,
	l.KhoiID,

	/* ================= ĐỌC ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_Doc_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_Doc_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_Doc_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Doc_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Doc_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Doc_VYC,

	/* ================= NGHE ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_Nghe_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_Nghe_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_Nghe_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Nghe_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Nghe_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Nghe_VYC,

	/* ================= NÓI ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_Noi_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_Noi_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_Noi_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Noi_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Noi_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Noi_VYC,

	/* ================= VIẾT ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_Viet_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_Viet_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_Viet_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Viet_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Viet_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Viet_VYC,

	/* ================= ĐÁNH GIÁ CHUNG ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_DanhGiaChung_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_DanhGiaChung_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_DanhGiaChung_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_DanhGiaChung_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_DanhGiaChung_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_DanhGiaChung_VYC

FROM tblKetQuaHocTap kqht
JOIN TemplateBangDiemChiTiet bdct 
	ON bdct.CotDiemID = kqht.CotDiemID 
	AND bdct.Enable = 1
JOIN tblMonHocLop mhl 
	ON mhl.MonHocLopID = kqht.MonHocLopID 
	AND mhl.MonHocID = 46 
	AND mhl.Enable = 1
JOIN tblHocSinhLop hsl 
	ON hsl.LopID = mhl.LopNhomID 
	AND hsl.HocSinhID = kqht.HocSinhID
JOIN tblLop l 
	ON l.LopID = mhl.LopNhomID 
	AND l.Enable = 1 
	AND l.NienKhoa = @NienKhoa
WHERE
	kqht.NienKhoa = @NienKhoa
	AND kqht.Enable = 1
	AND bdct.MaCotDiem LIKE @Semester + '%_CB_%'
GROUP BY
	l.TenLop,
	l.KhoiID

 UNION
     SELECT 
	 N'Khối ' + CAST(l.KhoiID as varchar(2)) AS TenLop,
	COUNT(DISTINCT hsl.HocSinhID) AS TongSoHocSinh,
	l.KhoiID,
	/* ================= ĐỌC ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_Doc_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_Doc_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_Doc_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Doc_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Doc_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Reading_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Doc_VYC,

	/* ================= NGHE ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_Nghe_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_Nghe_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_Nghe_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Nghe_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Nghe_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Listening_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Nghe_VYC,

	/* ================= NÓI ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_Noi_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_Noi_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_Noi_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Noi_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Noi_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Speaking_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Noi_VYC,

	/* ================= VIẾT ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_Viet_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_Viet_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_Viet_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Viet_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Viet_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Writing_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_Viet_VYC,

	/* ================= ĐÁNH GIÁ CHUNG ================= */
	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS SL_DanhGiaChung_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS SL_DanhGiaChung_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS SL_DanhGiaChung_VYC,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_DanhGiaChung_CD,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_DanhGiaChung_D,

	SUM(CASE WHEN bdct.MaCotDiem = @Semester+'_CB_Avg_Conv'
		AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END)
		* 100.0 / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) AS TL_DanhGiaChung_VYC

FROM tblKetQuaHocTap kqht
JOIN TemplateBangDiemChiTiet bdct 
	ON bdct.CotDiemID = kqht.CotDiemID 
	AND bdct.Enable = 1
JOIN tblMonHocLop mhl 
	ON mhl.MonHocLopID = kqht.MonHocLopID 
	AND mhl.MonHocID = 46 
	AND mhl.Enable = 1
JOIN tblHocSinhLop hsl 
	ON hsl.LopID = mhl.LopNhomID 
	AND hsl.HocSinhID = kqht.HocSinhID
JOIN tblLop l 
	ON l.LopID = mhl.LopNhomID 
	AND l.Enable = 1 
	AND l.NienKhoa = @NienKhoa
WHERE
	kqht.NienKhoa = @NienKhoa
	AND kqht.Enable = 1
	AND bdct.MaCotDiem LIKE @Semester + '%_CB_%'
GROUP BY 
	l.KhoiID;
UPDATE @Table_x
SET
	-- ĐỌC
	TL_Doc_CD  = ROUND(SL_Doc_CD  * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_Doc_D   = ROUND(SL_Doc_D   * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_Doc_VYC = ROUND(SL_Doc_VYC * 100.0 / NULLIF(TongSoHocSinh,0), 2),

	-- NGHE
	TL_Nghe_CD  = ROUND(SL_Nghe_CD  * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_Nghe_D   = ROUND(SL_Nghe_D   * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_Nghe_VYC = ROUND(SL_Nghe_VYC * 100.0 / NULLIF(TongSoHocSinh,0), 2),

	-- NÓI
	TL_Noi_CD  = ROUND(SL_Noi_CD  * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_Noi_D   = ROUND(SL_Noi_D   * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_Noi_VYC = ROUND(SL_Noi_VYC * 100.0 / NULLIF(TongSoHocSinh,0), 2),

	-- VIẾT
	TL_Viet_CD  = ROUND(SL_Viet_CD  * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_Viet_D   = ROUND(SL_Viet_D   * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_Viet_VYC = ROUND(SL_Viet_VYC * 100.0 / NULLIF(TongSoHocSinh,0), 2),

	-- ĐÁNH GIÁ CHUNG
	TL_DanhGiaChung_CD  = ROUND(SL_DanhGiaChung_CD  * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_DanhGiaChung_D   = ROUND(SL_DanhGiaChung_D   * 100.0 / NULLIF(TongSoHocSinh,0), 2),
	TL_DanhGiaChung_VYC = ROUND(SL_DanhGiaChung_VYC * 100.0 / NULLIF(TongSoHocSinh,0), 2);

SELECT * FROM @Table_x
--WHERE KhoiID = @KhoiID
 
end
