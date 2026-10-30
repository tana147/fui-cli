--   spAPI_AUTH_LMS_KetQuaHocTap_Lop '2466', 'HK1'
CREATE PROC [dbo].[spAPI_AUTH_LMS_KetQuaHocTap_Lop]
    --  @LoaiDiem NVARCHAR(50) --TX, DiemGK, DiemCK, DiemTB
    --, @CapHoc   INT
    --, 
    @LopID NVARCHAR(20)
  , @HocKy VARCHAR(10)
  , @NienKhoa INT
AS
BEGIN
    DECLARE @CapID INT;

    -- Không suy đoán niên khóa từ LopID vì mã lớp có thể được dùng lại.
    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
    BEGIN
        RAISERROR(N'NienKhoa là bắt buộc khi lấy kết quả theo LopID.', 16, 1);
        RETURN;
    END;

    SELECT @CapID = CapID
    FROM
           dbo.tblLop
    WHERE
           LopID = @LopID
      AND  NienKhoa = @NienKhoa
      AND  Enable = 1;

    IF (@CapID = 1)
    BEGIN
        EXEC fn_GetKetQuaHocTapTheoLop_C1 @LopID = @LopID
                                        , @NienKhoa = @NienKhoa
                                        , @HocKy = @HocKy;
    END;
    ELSE IF (@CapID = 2)
    BEGIN
        EXEC fn_GetKetQuaHocTapTheoLop_C2 @LopID = @LopID
                                        , @NienKhoa = @NienKhoa
                                        , @HocKy = @HocKy;
    END;
    ELSE IF (@CapID = 3)
    BEGIN
        EXEC fn_GetKetQuaHocTapTheoLop_C3 @LopID = @LopID
                                        , @NienKhoa = @NienKhoa
                                        , @HocKy = @HocKy;
    END;

END;
