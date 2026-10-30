CREATE PROCEDURE dbo.spAPI_TKB_Lich_Delete
    @NienKhoa VARCHAR(20),
    @MaDonVi INT,
    @HocKy INT,
    @TuanID INT,
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'Bạn không có quyền xóa thời khóa biểu.', 16, 1);
        RETURN;
    END;

    DELETE FROM dbo.tblTKB_Lich
    WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
      AND ISNULL(HocKy, 0) = ISNULL(@HocKy, 0) AND TuanID = @TuanID
      AND ISNULL(CapHoc, 0) = 0;

    SELECT @@ROWCOUNT AS DeletedCount;
END
