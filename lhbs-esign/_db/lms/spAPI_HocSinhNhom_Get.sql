CREATE PROC [dbo].[spAPI_HocSinhNhom_Get]
    @NienKhoa INT
  , @KhoiID   INT
AS
BEGIN
    SELECT hsn.HSNhomID
         , hsn.HocSinhID
         , hsn.LopID
         , hsn.NhomID
         , hsn.NhomID_HK1
         , hsn.SoDanhBo
         , hsn.SoTT
         , hs.Ho
         , hs.Ten
         , hs.Ho + ' ' + hs.Ten AS HoTen
         , n.NhomID
		 , n.MonHocID
    FROM
           dbo.tblHocSinhNhom        AS hsn
           INNER JOIN dbo.tblNhom    AS n ON n.NhomID      = hsn.NhomID
                                         AND n.Enable      = 1
                                         AND n.NienKhoa    = @NienKhoa
           LEFT JOIN dbo.tblLop      AS l ON l.LopID       = hsn.LopID
                                         AND l.Enable      = 1
                                         AND l.NienKhoa    = @NienKhoa
                                         AND l.KhoiID      = @KhoiID
           INNER JOIN dbo.tblHocSinh AS hs ON hs.HocSinhID = hsn.HocSinhID
                                          AND hs.TinhTrang = 0
    WHERE
           hsn.Enable = 1
	ORDER BY hsn.SoTT
END;