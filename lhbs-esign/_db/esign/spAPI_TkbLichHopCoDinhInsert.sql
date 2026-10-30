CREATE PROCEDURE spAPI_TkbLichHopCoDinhInsert
    @LoaiNhom VARCHAR(20),
    @MaNhom VARCHAR(20),
    @TenNhom NVARCHAR(150),
    @Thu INT,
    @Buoi VARCHAR(10),
    @TietList VARCHAR(50),
    @GhiChu NVARCHAR(300) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO tblTKB_LichHopCoDinh (LoaiNhom, MaNhom, TenNhom, Thu, Buoi, TietList, GhiChu, Enable)
    VALUES (@LoaiNhom, @MaNhom, @TenNhom, @Thu, @Buoi, @TietList, @GhiChu, 1)
    SELECT mess = N'Đã thêm'
END