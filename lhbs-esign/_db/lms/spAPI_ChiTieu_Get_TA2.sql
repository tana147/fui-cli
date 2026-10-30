CREATE PROC [dbo].[spAPI_ChiTieu_Get_TA2]
	@NienKhoa int
AS
BEGIN
	DECLARE @tempTable Table(
			TenLop Nvarchar(50),
			LopID varchar(20),
			CapID int,
			NienKhoa int,
			KhoiID int
	)
	
		INSERT INTO @tempTable 
		VALUES
		(N'Khối 10','N100000',3,@NienKhoa,10),
		(N'Khối 11','N110000',3,@NienKhoa,11),
		(N'Khối 12','N120000',3,@NienKhoa,12)
	
	-- TABLE 1: Lấy danh sách các mức độ
	SELECT MucDo_ID, TenMucDo  FROM tbl_MucDo
	WHERE  NienKhoa = @NienKhoa AND Is_TA2 = 1  AND Enable = 1
	-- TABLE 2: Lấy danh sách lớp và chỉ tiêu mỗi mức độ
	SELECT 
		l.TenNhom as TenLop,
		ct.ChiTieu_ID,
		l.NhomID as LopID, 
		ct.TrinhDo,
		ct.ChiTieuDatRa,
		ct.ChiTieuThucTe,
		ct.SoVoiThucTe,
		ct.DiemMin,
		ct.DiemMax,
		ct.Suffix,
		ct.Prefix,
		md.TenMucDo,
		md.MucDo_ID,
		l.KhoiID
	FROM (SELECT * FROM tblNhom where  NienKhoa = @NienKhoa and MonHocID = 76 and IsNhomLMS_GiaoBai = 0 and Enable = 1) l
		cross join (SELECT * FROM tbl_MucDo where  NienKhoa = @NienKhoa AND Is_TA2 = 1) as md
		left join tbl_ChiTieu ct ON l.NhomID = ct.NhomID and md.MucDo_ID = ct.MucDo_ID

	UNION 
	SELECT l.TenLop ,
			ct.ChiTieu_ID,
			l.LopID, 
			ct.TrinhDo,
			ct.ChiTieuDatRa,
			ct.ChiTieuThucTe,
			ct.SoVoiThucTe,
			ct.DiemMin,
			ct.DiemMax,
			ct.Suffix,
			ct.Prefix,
			md.TenMucDo,
			md.MucDo_ID,
			l.KhoiID
	FROM  (SELECT * FROM @tempTable where  NienKhoa = @NienKhoa) l
			cross join (SELECT * FROM tbl_MucDo where NienKhoa = @NienKhoa AND Is_TA2 = 1) as md
			left join tbl_ChiTieu ct ON l.LopID = ct.NhomID and md.MucDo_ID = ct.MucDo_ID
END

