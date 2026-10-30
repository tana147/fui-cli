CREATE PROCEDURE dbo.spAPI_AUTH_TKB_QuyTac_Get
    @NienKhoa VARCHAR(20),
    @MaDonVi INT,
    @LopHocID INT,
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Giữ API rule cùng phạm vi quyền admin đang được các trang TKB trong KQHT kiểm tra.
    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền xem quy tắc thời khóa biểu.', 16, 1);
        RETURN;
    END;

    SELECT QuyTacID, NienKhoa, MaDonVi, LopHocID, Lop, Thu, BuoiID, Tiet,
           LoaiQuyTac, MaMon, TenMonHoc, MucDo, MucUuTien, HieuLucTuNgay, HieuLucDenNgay,
           GhiChu, CreateUser, CreateTime, UpdateUser, UpdateTime
    FROM dbo.tblTKB_QuyTac WITH (NOLOCK)
    WHERE Enable = 1
      AND NienKhoa = @NienKhoa
      AND MaDonVi = @MaDonVi
      AND (@LopHocID = 0 OR LopHocID = @LopHocID)
    ORDER BY CASE WHEN MucDo = 'CUNG' THEN 0 ELSE 1 END,
             MucUuTien, Lop, Thu, BuoiID, Tiet, QuyTacID;
END
