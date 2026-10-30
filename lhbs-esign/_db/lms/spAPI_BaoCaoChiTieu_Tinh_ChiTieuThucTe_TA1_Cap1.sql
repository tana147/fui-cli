CREATE PROCEDURE spAPI_BaoCaoChiTieu_Tinh_ChiTieuThucTe_TA1_Cap1
		@Semester varchar(20) = '1',
		@NienKhoa INT,
		@LopID VARCHAR(20)
	AS
	BEGIN
		DECLARE @ResultScore TABLE(HocSinhID varchar(10), Diem varchar(10))
		INSERT INTO @ResultScore(HocSinhID, Diem)
		SELECT kqht.HocSinhID, kqht.KetQuaDanhGia_VI FROM TemplateBangDiemChiTiet bdct 
					INNER JOIN TemplateBangDiem bd on bd.TemplateBangDiemID = bdct.TemplateBangDiemID
					INNER JOIN tblMonHocLop mhl on mhl.TemplateBangDiemID = bd.TemplateBangDiemID AND mhl.NienKhoa = @NienKhoa and mhl.MonHocID = 5
					LEFT JOIN tblKetQuaHocTap kqht on kqht.CotDiemID = bdct.CotDiemID and kqht.Enable = 1 and kqht.MonHocLopID = mhl.MonHocLopID
		WHERE mhl.LopNhomID =@LopID and bdct.MaCotDiem like 'DanhHieu_HK'+@Semester
		UPDATE ct
			SET ChiTieuThucTe = CASE WHEN ct.MucDo_ID = 7 THEN CAST((SELECT COUNT(*) FROM @ResultScore WHERE Diem = 'H')*100.0/ (SELECT COUNT(*) FROM @ResultScore) AS Decimal(18,2)) 
									WHEN ct.MucDo_ID = 8 THEN  CAST((SELECT COUNT(*) FROM @ResultScore WHERE Diem = 'C')*100.0/ (SELECT COUNT(*) FROM @ResultScore) AS Decimal(18,2))
									WHEN ct.MucDo_ID = 9 THEN CAST((SELECT COUNT(*) FROM @ResultScore WHERE Diem = 'T')*100.0/ (SELECT COUNT(*) FROM @ResultScore) AS Decimal(18,2))
									ELSE 0  END
		FROM tbl_ChiTieu ct 
			INNER JOIN tbl_MucDo md on md.MucDo_ID = ct.MucDo_ID and md.NienKhoa = @NienKhoa
		WHERE LopID = @LopID and HocKi = @Semester
	END