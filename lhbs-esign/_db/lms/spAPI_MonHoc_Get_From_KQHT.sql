CREATE PROC spAPI_MonHoc_Get_From_KQHT
	@NienKhoa				INT			
 ,	@CapID					INT			
AS
BEGIN
    SELECT DISTINCT mhl.MonHocID, mh.TenMonHoc_HienThi
	FROM dbo.tblKetQuaHocTap kqht
		INNER JOIN dbo.TemplateBangDiemChiTiet ct ON ct.CotDiemID = kqht.CotDiemID AND ct.Enable = 1
		INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID AND mhl.Enable = 1 AND mhl.NienKhoa = @NienKhoa 
		--INNER JOIN dbo.tblLop l ON l.LopID = kqht.LopID AND l.LopID = mhl.LopNhomID AND l.NienKhoa = @NienKhoa AND l.Enable = 1 AND l.CapID =@CapID
		INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID AND mh.CapID = @CapID AND mh.Enable = 1
	WHERE kqht.NienKhoa= @NienKhoa  AND kqht.Enable = 1
END