CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_MienGiam_Save]
    @MienGiamID BIGINT = 0,
    @NhanVienID VARCHAR(9),
    @NamHoc INT,
    @SoGioMienGiam DECIMAL(10, 2),
    @LyDo NVARCHAR(500) = NULL,
    @SoQuyetDinh VARCHAR(100) = NULL,
    @FileID CHAR(32) = NULL,
    @sys_UserID VARCHAR(9)
AS
    BEGIN
        SET NOCOUNT ON;
        -- Kiểm tra dữ liệu bắt buộc
        IF ISNULL(@NhanVienID, '') = ''
           OR @NamHoc IS NULL
           OR @SoGioMienGiam IS NULL
            BEGIN
                RAISERROR(N'Nhân viên, Năm học và Số giờ miễn giảm là bắt buộc.', 16, 1);
                RETURN 0;
            END;
        MERGE dbo.tblHDKH_MienGiam AS T
        USING(SELECT @MienGiamID AS MienGiamID) AS S
        ON(T.MienGiamID = S.MienGiamID AND S.MienGiamID > 0)
        WHEN MATCHED THEN UPDATE SET
                              NhanVienID = @NhanVienID,
                              NamHoc = @NamHoc,
                              SoGioMienGiam = @SoGioMienGiam,
                              LyDo = @LyDo,
                              SoQuyetDinh = @SoQuyetDinh,
                              FileID = NULLIF(LTRIM(RTRIM(@FileID)),''),
                              UpdateTime = GETDATE(),
                              UpdateUser = @sys_UserID
        WHEN NOT MATCHED BY TARGET THEN INSERT(NhanVienID, NamHoc, SoGioMienGiam, LyDo, SoQuyetDinh, FileID, CreateUser)
                                        VALUES
                                             (
                                             @NhanVienID,
                                             @NamHoc,
                                             @SoGioMienGiam,
                                             @LyDo,
                                             @SoQuyetDinh,
                                             NULLIF(LTRIM(RTRIM(@FileID)),''),
                                             @sys_UserID
                                             );
        SELECT Message = N'Lưu thông tin miễn giảm thành công.';
    END;
