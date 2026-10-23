CREATE PROC [dbo].[spAPI_CGCN_Del]
    @CGCNID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ChuyenGiaoCongNghe
    SET 
        Is_Xoa = 1,
        NhanVienCapNhat = ISNULL(@sys_UserID, NhanVienCapNhat),
        ThoiGianCapNhat = GETDATE()
    WHERE CGCNID = @CGCNID;
END;
