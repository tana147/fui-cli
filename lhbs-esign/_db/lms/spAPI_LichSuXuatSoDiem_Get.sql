CREATE PROCEDURE [dbo].[spAPI_LichSuXuatSoDiem_Get]
    @NienKhoa INT,
    @HocKy INT,
    @GiaoVienID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ID,
        GiaoVienID,
        TenGiaoVien,
        LopID,
        NhomID,
        TenLop,
        MonHocID,
        TenMonHoc,
        HocKy,
        NienKhoa,
        ThoiGianXuat,
        NguoiXuatID,
        TenNguoiXuat
    FROM dbo.tblLichSuXuatSoDiem
    WHERE NienKhoa = @NienKhoa
      AND (ISNULL(@HocKy, 0) = 0 OR HocKy = @HocKy)
      AND (ISNULL(@GiaoVienID, '') = '' OR GiaoVienID = @GiaoVienID)
    ORDER BY ThoiGianXuat DESC;
END