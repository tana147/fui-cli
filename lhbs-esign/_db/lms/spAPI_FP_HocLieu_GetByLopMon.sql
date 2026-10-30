
/* Chỉ trả học liệu số; tài nguyên TAI_NGUYEN không được dùng làm mục lục. */
CREATE   PROCEDURE dbo.spAPI_FP_HocLieu_GetByLopMon
    @KhoiID INT,
    @MonHocID INT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT hl.HocLieuID, hl.TenHocLieu, hl.ThumbnailURL, hl.HocKy,
           bs.TenBoSach, bs.MoTa AS MoTaBoSach, hl.TinhTrang
    FROM dbo.tblHocLieu_FP hl
    INNER JOIN dbo.tblBoSach_FP bs ON hl.BoSachID = bs.BoSachID
    WHERE hl.KhoiID = @KhoiID
      AND hl.MonHocID = @MonHocID
      AND hl.Loai = 'HOC_LIEU'
      AND hl.Is_Xoa = 0
      AND bs.Is_Xoa = 0
      AND hl.TinhTrang = 'Public'
    ORDER BY hl.HocKy, hl.TenHocLieu;
END;
