CREATE PROC [dbo].[spAPI_CGCN_Submit]
    @CGCNID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ChuyenGiaoCongNghe
    SET 
        TrangThai = 2, -- Chờ duyệt
        ThoiGianSubmit = GETDATE(),
        LyDoReject = '', -- Xóa lý do từ chối cũ
        NhanVienCapNhat = ISNULL(@sys_UserID, NhanVienCapNhat),
        ThoiGianCapNhat = GETDATE()
    WHERE CGCNID = @CGCNID;
END;
