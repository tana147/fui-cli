-- [dbo].[spAPI_ThongKe_TiLeDat_TA2_GET] 12 , 0, 76, 2024, 'S1', 0
CREATE PROCEDURE [dbo].[spAPI_ThongKe_TiLeDat_TA2_GET] 
	@KhoiID INT
,	@List_LopID NVARCHAR(200)
,	@MonHocID INT
,	@NienKhoa NVARCHAR(50)
,	@HocKi NVARCHAR(50)
,	@LoaiSiSo INT = 1  -- 0: Sĩ số toàn lớp | 1: Sĩ số trừ học sinh có IELTS (chỉ áp dụng nếu lớp có IELTS)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Table_LopID TABLE(LopID NVARCHAR(20))
	INSERT INTO @Table_LopID 
	SELECT [value] as LopID FROM string_split(@List_LopID, ',') as [value]

	-- Tạo bảng tạm
	CREATE TABLE #KetQuaGoc ( LopID            VARCHAR(20)
	,                         TenLop           VARCHAR(9)
	,                         MaCotDiem        VARCHAR(50)
	,                         KetQuaDanhGia_VI NVARCHAR(100)
	,                         SoLuong          INT DEFAULT 0
	,                         TyLe             DECIMAL(5, 2) DEFAULT 0
	,                         ThuTuNhom        INT DEFAULT 99
	,                         SiSo             INT);

	CREATE TABLE #DuLieuMacDinh ( MaCotDiem        VARCHAR(50)
	,                             KetQuaDanhGia_VI NVARCHAR(100)
	,                             ThuTuNhom        INT );

	INSERT INTO #DuLieuMacDinh ( MaCotDiem, KetQuaDanhGia_VI, ThuTuNhom )
	VALUES                    
		  ( 'S1_Mid_TA2_Speaking_Conv',   N'Exceeding Requirements/Vượt yêu cầu', 1)
		, ( 'S1_Mid_TA2_Speaking_Conv',   N'Meeting Requirements/Đạt yêu cầu',2)
		, ( 'S1_Mid_TA2_Speaking_Conv',   N'Not Meeting Requirements/Chưa đạt',3)
		, ( 'S1_Mid_TA2_Writing_Conv',    N'Exceeding Requirements/Vượt yêu cầu', 4)
		, ( 'S1_Mid_TA2_Writing_Conv',    N'Meeting Requirements/Đạt yêu cầu',5)
		, ( 'S1_Mid_TA2_Writing_Conv',    N'Not Meeting Requirements/Chưa đạt',6)
		, ( 'S1_Mid_TA2_Listening_Conv',  N'Exceeding Requirements/Vượt yêu cầu', 7)
		, ( 'S1_Mid_TA2_Listening_Conv',  N'Meeting Requirements/Đạt yêu cầu',8)
		, ( 'S1_Mid_TA2_Listening_Conv',  N'Not Meeting Requirements/Chưa đạt',9)
		, ( 'S1_Mid_TA2_Reading_Conv',    N'Exceeding Requirements/Vượt yêu cầu', 10)
		, ( 'S1_Mid_TA2_Reading_Conv',    N'Meeting Requirements/Đạt yêu cầu',11)
		, ( 'S1_Mid_TA2_Reading_Conv',    N'Not Meeting Requirements/Chưa đạt',12)
		, ( 'S1_Mid_TA2_Avg_Conv',        N'Exceeding Requirements/Vượt yêu cầu', 13)
		, ( 'S1_Mid_TA2_Avg_Conv',        N'Meeting Requirements/Đạt yêu cầu',14)
		, ( 'S1_Mid_TA2_Avg_Conv',        N'Not Meeting Requirements/Chưa đạt',15)
		, ( 'S2_Mid_TA2_Speaking_Conv',   N'Exceeding Requirements/Vượt yêu cầu', 16)
		, ( 'S2_Mid_TA2_Speaking_Conv',   N'Meeting Requirements/Đạt yêu cầu',17)
		, ( 'S2_Mid_TA2_Speaking_Conv',   N'Not Meeting Requirements/Chưa đạt',18)
		, ( 'S2_Mid_TA2_Writing_Conv',    N'Exceeding Requirements/Vượt yêu cầu', 19)
		, ( 'S2_Mid_TA2_Writing_Conv',    N'Meeting Requirements/Đạt yêu cầu',20)
		, ( 'S2_Mid_TA2_Writing_Conv',    N'Not Meeting Requirements/Chưa đạt',21)
		, ( 'S2_Mid_TA2_Listening_Conv',  N'Exceeding Requirements/Vượt yêu cầu', 22)
		, ( 'S2_Mid_TA2_Listening_Conv',  N'Meeting Requirements/Đạt yêu cầu',23)
		, ( 'S2_Mid_TA2_Listening_Conv',  N'Not Meeting Requirements/Chưa đạt',24)
		, ( 'S2_Mid_TA2_Reading_Conv',    N'Exceeding Requirements/Vượt yêu cầu', 25)
		, ( 'S2_Mid_TA2_Reading_Conv',    N'Meeting Requirements/Đạt yêu cầu',26)
		, ( 'S2_Mid_TA2_Reading_Conv',    N'Not Meeting Requirements/Chưa đạt',27)
		, ( 'S2_Mid_TA2_Avg_Conv',        N'Exceeding Requirements/Vượt yêu cầu', 28)
		, ( 'S2_Mid_TA2_Avg_Conv',        N'Meeting Requirements/Đạt yêu cầu',29)
		, ( 'S2_Mid_TA2_Avg_Conv',        N'Not Meeting Requirements/Chưa đạt',30);

	-- Truy vấn dữ liệu thực tế
	INSERT INTO #KetQuaGoc ( LopID, TenLop, MaCotDiem, KetQuaDanhGia_VI, SoLuong, ThuTuNhom, SiSo )
	SELECT tkqht.LopID                                                                                                        
	,      tl.TenNhom                                                                                                         
	,      tbdct.MaCotDiem                                                                                                    
	,      CASE WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%exceeding requirements%'   THEN N'Exceeding Requirements/Vượt yêu cầu'
	            WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'not meeting requirements%'  THEN N'Not Meeting Requirements/Chưa đạt'
	            WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%meeting requirements%'     THEN N'Meeting Requirements/Đạt yêu cầu'
	                                                                                                 ELSE N'Không có điểm quy đổi' END AS KetQuaDanhGia_VI
	,      COUNT(*) AS SoLuong
	,      ISNULL(tbdct.ThuTuNhom, 99) AS ThuTuNhom
	,      CASE 
				-- Lớp có học sinh IELTS VÀ user chọn trừ => tính sĩ số trừ HS IELTS
				WHEN @LoaiSiSo = 1
				     AND EXISTS (
				         SELECT 1 
				         FROM dbo.tblDanhSachHocSinh_CoIELTS ielts
				         INNER JOIN dbo.tblHocSinhNhom hsn ON hsn.HocSinhID = ielts.HocSinhID
				         WHERE hsn.NhomID     = tkqht.LopID
				           AND ielts.NienKhoa = tkqht.NienKhoa
				           AND ielts.Enable   = 1
				           AND ielts.HocKi    = @HocKi
				     )
				THEN
				     (
				         SELECT COUNT(*) 
				         FROM dbo.tblHocSinhNhom hsn
				         WHERE hsn.NhomID = tkqht.LopID 
				           AND hsn.Enable  = 1
				           AND NOT EXISTS (
				               SELECT 1 
				               FROM dbo.tblDanhSachHocSinh_CoIELTS ielts
				               WHERE ielts.HocSinhID = hsn.HocSinhID
				                 AND ielts.NienKhoa  = tkqht.NienKhoa
				                 AND ielts.Enable    = 1
				                 AND ielts.HocKi     = @HocKi
				           )
				     )
				-- Lớp không có IELTS HOẶC user chọn toàn lớp => sĩ số bình thường
				ELSE
				     (SELECT COUNT(*) FROM dbo.tblHocSinhNhom WHERE NhomID = tkqht.LopID AND Enable = 1)
		   END AS SiSo
		
	FROM dbo.tblKetQuaHocTap				tkqht 
		INNER JOIN dbo.tblHocSinh				hs    ON tkqht.HocSinhID = hs.HocSinhID AND hs.TinhTrang = 0
		INNER JOIN dbo.TemplateBangDiemChiTiet	tbdct ON tkqht.CotDiemID = tbdct.CotDiemID AND tbdct.Enable = 1
		INNER JOIN dbo.tblMonHocLop				tmhl  ON tmhl.MonHocLopID = tkqht.MonHocLopID AND tmhl.Enable = 1
		INNER JOIN dbo.tblMonHoc				tmh   ON tmh.MonHocID = tmhl.MonHocID AND tmh.Enable = 1
		INNER JOIN dbo.tblNhom					tl    ON tl.NhomID = tkqht.LopID AND tl.Enable = 1 AND tl.IsNhomLMS_GiaoBai = 0
	WHERE tbdct.MaCotDiem IN (
			  'S1_Mid_TA2_Listening_Conv'
			, 'S1_Mid_TA2_Reading_Conv'
			, 'S1_Mid_TA2_Speaking_Conv'
			, 'S1_Mid_TA2_Writing_Conv'
			, 'S1_Mid_TA2_Avg_Conv'
			, 'S2_Mid_TA2_Listening_Conv'
			, 'S2_Mid_TA2_Reading_Conv'
			, 'S2_Mid_TA2_Speaking_Conv'
			, 'S2_Mid_TA2_Writing_Conv'
			, 'S2_Mid_TA2_Avg_Conv'
			, 'S1_Final_TA2_Listening_Conv'
			, 'S1_Final_TA2_Reading_Conv'
			, 'S1_Final_TA2_Speaking_Conv'
			, 'S1_Final_TA2_Writing_Conv'
			, 'S1_Final_TA2_Avg_Conv'
			, 'S2_Final_TA2_Listening_Conv'
			, 'S2_Final_TA2_Reading_Conv'
			, 'S2_Final_TA2_Speaking_Conv'
			, 'S2_Final_TA2_Writing_Conv'
			, 'S2_Final_TA2_Avg_Conv'
		)
		AND tmh.MonHocID  = @MonHocID
		AND tkqht.NienKhoa = @NienKhoa
		AND tl.KhoiID     = @KhoiID
		AND tkqht.LopID   IN (SELECT LopID FROM @Table_LopID)
		AND tkqht.Enable  = 1
		-- Loại học sinh đã có IELTS sẵn khỏi phần đếm điểm
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.tblDanhSachHocSinh_CoIELTS ielts
			WHERE ielts.HocSinhID = tkqht.HocSinhID
			  AND ielts.NienKhoa  = tkqht.NienKhoa
			  AND ielts.Enable    = 1
			  AND ielts.HocKi     = @HocKi
		)
		
	GROUP BY tkqht.LopID
	,        tl.TenNhom
	,        tbdct.MaCotDiem
	,        CASE WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%exceeding requirements%'   THEN N'Exceeding Requirements/Vượt yêu cầu'
	             WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'not meeting requirements%'   THEN N'Not Meeting Requirements/Chưa đạt'
	             WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%meeting requirements%'      THEN N'Meeting Requirements/Đạt yêu cầu'
	                                                                                                  ELSE N'Không có điểm quy đổi' END  
	,        tbdct.ThuTuNhom
	,        tkqht.NienKhoa;

	-- Bổ sung dữ liệu mặc định nếu thiếu
	INSERT INTO #KetQuaGoc ( LopID, TenLop, MaCotDiem, KetQuaDanhGia_VI, ThuTuNhom, SiSo )
	SELECT DISTINCT g.LopID
	,               g.TenLop
	,               d.MaCotDiem
	,               d.KetQuaDanhGia_VI
	,               d.ThuTuNhom
	,               g.SiSo
	FROM       #KetQuaGoc     g
	CROSS JOIN #DuLieuMacDinh d
	WHERE NOT EXISTS (
		SELECT 1
		FROM #KetQuaGoc
		WHERE LopID            = g.LopID
		  AND MaCotDiem        = d.MaCotDiem
		  AND KetQuaDanhGia_VI = d.KetQuaDanhGia_VI
		);

	-- Tính tỷ lệ
	DECLARE @TongSoLuong INT;

	SELECT @TongSoLuong = SUM(SoLuong)
	FROM #KetQuaGoc;

	IF @TongSoLuong > 0
	BEGIN
		UPDATE KG
		SET TyLe = CASE WHEN T.TongSoLuongTheoNhom > 0 
		                THEN ROUND(CAST(KG.SoLuong AS DECIMAL(10, 2)) * 100.0 / T.TongSoLuongTheoNhom, 2)
		                ELSE 0 END
		FROM        #KetQuaGoc    KG
		CROSS APPLY (
			SELECT SUM(SoLuong) AS TongSoLuongTheoNhom
			FROM #KetQuaGoc
			WHERE LopID     = KG.LopID
			  AND MaCotDiem = KG.MaCotDiem
		) AS T;
	END;

	-- Trả kết quả
	SELECT DISTINCT 
		LopID,
		TenLop,
		MaCotDiem,
		KetQuaDanhGia_VI,
		SoLuong,
		TyLe,
		ThuTuNhom,
		SiSo,
		CASE 
			WHEN KetQuaDanhGia_VI LIKE N'%Exceeding%'   THEN 1
			WHEN KetQuaDanhGia_VI LIKE N'%Not Meeting%' THEN 3
			WHEN KetQuaDanhGia_VI LIKE N'%Meeting%'     THEN 2
			ELSE 4
		END AS SortOrder
	FROM #KetQuaGoc
	ORDER BY 
		TenLop,
		MaCotDiem,
		SortOrder,
		ThuTuNhom;

	-- Xoá bảng tạm
	DROP TABLE #KetQuaGoc;
	DROP TABLE #DuLieuMacDinh;
END;