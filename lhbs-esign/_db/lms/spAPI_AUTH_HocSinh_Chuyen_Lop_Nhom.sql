CREATE   PROC [dbo].[spAPI_AUTH_HocSinh_Chuyen_Lop_Nhom]
    @TenLop_Chuyen NVARCHAR(100)
  , @HocSinhID     INT
  , @NienKhoa      INT
  , @SYS_USERID    VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LopID            NVARCHAR(20)  = N'';
    DECLARE @MonHocID         INT           = 0;
    DECLARE @ListNhomID_Child NVARCHAR(500) = N'';
    DECLARE @Msg              NVARCHAR(500) = N'';

    -- ============================================================
    -- Lấy thông tin nhóm cần chuyển tới
    -- ============================================================
    SELECT @MonHocID         = MonHocID
         , @LopID            = NhomID
         , @ListNhomID_Child = ISNULL(ListNhomID_Child, N'')
    FROM   dbo.tblNhom
    WHERE  TenNhom  = @TenLop_Chuyen
      AND  Enable   = 1
      AND  NienKhoa = @NienKhoa;

    -- Validate: không tìm thấy nhóm
    IF @LopID = N''
    BEGIN
        SET @Msg = N'LMS - Không tìm thấy nhóm: [' + @TenLop_Chuyen + N']';
        RAISERROR(@Msg, 16, 1);
        RETURN;
    END;

    -- Validate: tìm thấy nhưng không phải nhóm AV
    IF @MonHocID <> 76
    BEGIN
        SET @Msg = N'LMS - Nhóm [' + @TenLop_Chuyen + N'] không phải nhóm AV (MonHocID=' + CAST(@MonHocID AS NVARCHAR) + N'), chỉ chấp nhận nhóm AV';
        RAISERROR(@Msg, 16, 1);
        RETURN;
    END;

    -- ============================================================
    -- Lấy NhomID lớp TH từ ListNhomID_Child
    -- ============================================================
    DECLARE @LopID_TH    NVARCHAR(20) = N'';
    DECLARE @HSNhomID_AV INT          = 0;
    DECLARE @HSNhomID_TH INT          = 0;

    SELECT TOP 1 @LopID_TH = n.NhomID
    FROM   dbo.tblNhom                                     n
           INNER JOIN STRING_SPLIT(@ListNhomID_Child, ',') s ON TRIM(s.value) = n.NhomID
    WHERE  n.MonHocID = 102
      AND  n.Enable   = 1;

    -- Lấy HSNhomID AV (MonHocID = 76)
    SELECT TOP 1 @HSNhomID_AV = HSN.HSNhomID
    FROM   dbo.tblHocSinhNhom HSN
           INNER JOIN dbo.tblNhom n ON n.NhomID   = HSN.NhomID
                                   AND n.Enable   = 1
                                   AND n.NienKhoa = @NienKhoa
                                   AND n.MonHocID = 76
    WHERE  HSN.HocSinhID = @HocSinhID
      AND  HSN.Enable    = 1
      AND  HSN.NhomID   <> @LopID   -- loại trừ nếu đã ở nhóm đích
    ORDER BY HSN.HSNhomID DESC;

    -- Lấy HSNhomID TH (MonHocID = 102)
    SELECT TOP 1 @HSNhomID_TH = HSN.HSNhomID
    FROM   dbo.tblHocSinhNhom HSN
           INNER JOIN dbo.tblNhom n ON n.NhomID   = HSN.NhomID
                                   AND n.Enable   = 1
                                   AND n.NienKhoa = @NienKhoa
                                   AND n.MonHocID = 102
    WHERE  HSN.HocSinhID = @HocSinhID
      AND  HSN.Enable    = 1
      AND  HSN.NhomID   <> @LopID_TH  -- loại trừ nếu đã ở nhóm đích
    ORDER BY HSN.HSNhomID DESC;

    -- Validate: học sinh không có nhóm AV
    IF @HSNhomID_AV = 0
    BEGIN
        SET @Msg = N'LMS - Học sinh [' + CAST(@HocSinhID AS NVARCHAR) + N'] không thuộc nhóm AV nào trong niên khóa ' + CAST(@NienKhoa AS NVARCHAR);
        RAISERROR(@Msg, 16, 1);
        RETURN;
    END;

    -- ============================================================
    -- AV: Chuyển điểm TRƯỚC → rồi chuyển lớp
    -- ============================================================
    EXEC [dbo].[spAPI_XepBangDiem_ChuyenLop_ByHocSinhID]
          @HocSinhID     = @HocSinhID
        , @NhomID_Chuyen = @LopID
        , @NienKhoa      = @NienKhoa
        , @MonHocID      = 76
        , @SYS_USERID    = @SYS_USERID;

    EXEC [dbo].[spAPI_HocSinhNhom_Upd_NhomID]
          @HSNhomID   = @HSNhomID_AV
        , @NhomID     = @LopID
        , @SYS_USERID = @SYS_USERID;

    -- ============================================================
    -- TH: Chỉ chuyển lớp, không chuyển điểm
    -- ============================================================
    IF (@HSNhomID_TH > 0 AND @LopID_TH <> N'')
    BEGIN
        EXEC [dbo].[spAPI_HocSinhNhom_Upd_NhomID]
              @HSNhomID   = @HSNhomID_TH
            , @NhomID     = @LopID_TH
            , @SYS_USERID = @SYS_USERID;
    END
    ELSE IF (@HSNhomID_TH > 0 AND @LopID_TH = N'')
    BEGIN
        SET @Msg = N'LMS - Không tìm thấy lớp TH trong ListNhomID_Child của nhóm [' + @LopID + N'] — bỏ qua TH';
        RAISERROR(@Msg, 10, 1); -- Warning, không dừng
    END;

END;