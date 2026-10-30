CREATE PROCEDURE [dbo].[spAPI_GiayKhenTapTheCert_GetLop]
    @NienKhoa INT,
    @KhoiID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT LopID
         , MaDonVi
         , TenLop
         , KhoiID
         , CASE 
             WHEN MaDonVi = 1 THEN TenLop + N' - [Biên Hòa]'
             WHEN MaDonVi = 2 THEN TenLop + N' - [Long Khánh]'
             ELSE TenLop
           END AS TenLopHienThi
    FROM dbo.tblLop
    WHERE Enable = 1
      AND NienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR KhoiID = @KhoiID)
    ORDER BY MaDonVi, KhoiID, TenLop;
END