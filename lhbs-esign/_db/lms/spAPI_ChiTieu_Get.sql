CREATE PROC [dbo].[spAPI_ChiTieu_Get]
	@CapID int,
	@NienKhoa int
AS
BEGIN
	DECLARE @tempTable Table(
			TenLop Nvarchar(50),
			LopID int,
			CapID int,
			NienKhoa int,
			KhoiID int,
			NhomID varchar(10)
	)
	IF(@CapID = 2)
	BEGIN 
		INSERT INTO @tempTable 
		VALUES
		(N'Khối 9',-0925,2,2025,9,null),
		(N'Khối 8',-0825,2,2025,8,null),
		(N'Khối 7',-0725,2,2025,7,null),
		(N'Khối 6',-0625,2,2025,6,null)
	END
	ELSE IF (@CapID = 3)
	BEGIN 
		INSERT INTO @tempTable 
		VALUES
		(N'Khối 10',null,3,2025,10,'-1025'),
		(N'Khối 11',null,3,2025,11,'-1125'),
		(N'Khối 12',null,3,2025,12,'-1225')
	END
	ELSE IF (@CapID = 1)
	BEGIN 
		INSERT INTO @tempTable 
		VALUES
		(N'Khối 1',-0125,1,2025,1,null),
		(N'Khối 2',-0225,1,2025,2,null),
		(N'Khối 3',-0325,1,2025,3,null),
		(N'Khối 4',-0425,1,2025,4,null),
		(N'Khối 5',-0525,1,2025,5,null)
	END
	-- TABLE 1: Lấy danh sách các mức độ
	SELECT MucDo_ID, TenMucDo  FROM tbl_MucDo
	WHERE CapID= @CapID AND NienKhoa = @NienKhoa AND Is_TA2 = 0 AND Enable = 1
	-- TABLE 2: Lấy danh sách lớp và chỉ tiêu mỗi mức độ
	IF(@CapID <> 3)
	BEGIN
	SELECT 
		l.TenLop,
		ct.ChiTieu_ID,
		l.LopID, 
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
	FROM (SELECT * FROM tblLop where  NienKhoa = @NienKhoa and CapID = @CapID ) l
		cross join (SELECT * FROM tbl_MucDo where CapID= @CapID and NienKhoa = @NienKhoa AND Is_TA2 = 0) as md
		left join tbl_ChiTieu ct ON l.LopID = ct.LopID and md.MucDo_ID = ct.MucDo_ID
		WHERE l.LopID <> '2459'
	UNION -- Lấy Khối
	SELECT l.TenLop,
			ct.ChiTieu_ID,
			l.LopID, 
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
	FROM  (SELECT * FROM @tempTable where  NienKhoa = @NienKhoa and CapID = @CapID) l
			cross join (SELECT * FROM tbl_MucDo where CapID= @CapID and NienKhoa = @NienKhoa AND Is_TA2 = 0) as md
			left join tbl_ChiTieu ct ON l.LopID = ct.LopID and md.MucDo_ID = ct.MucDo_ID
			WHERE l.LopID <> '2459'
	END
	ELSE
	BEGIN 
		SELECT 
		l.TenNhom,
		ct.ChiTieu_ID,
		l.NhomID, 
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
	FROM (SELECT * FROM tblNhom where  NienKhoa = @NienKhoa and CapID = @CapID and MonHocID = 76 and IsNhomLMS_GiaoBai = 0) l
		cross join (SELECT * FROM tbl_MucDo where CapID= @CapID and NienKhoa = @NienKhoa AND Is_TA2 = 0) as md
		left join tbl_ChiTieu ct ON l.NhomID = ct.NhomID and md.MucDo_ID = ct.MucDo_ID
	WHERE l.NhomID <> 'N251106'
	UNION -- Lấy Khối
	SELECT l.TenLop as TenNhom,
			ct.ChiTieu_ID,
			l.NhomID, 
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
	FROM  (SELECT * FROM @tempTable where  NienKhoa = @NienKhoa and CapID = @CapID) l
			cross join (SELECT * FROM tbl_MucDo where CapID= @CapID and NienKhoa = @NienKhoa AND Is_TA2 = 0) as md
			left join tbl_ChiTieu ct ON l.NhomID = ct.NhomID and md.MucDo_ID = ct.MucDo_ID
	WHERE l.NhomID <> 'N251106'
	END 
	
END