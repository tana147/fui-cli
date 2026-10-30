
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_Node_Save]
    @NoiDungID INT = 0,
    @HocLieuID INT,
    @ParentID INT = NULL,
    @TenNoiDung NVARCHAR(500),
    @LoaiNoiDung VARCHAR(50),
    @ThuTu INT = 0,
    @DataJson NVARCHAR(MAX) = NULL,
    @NguonTaiNguyenCode VARCHAR(50) = NULL,
    @NguonResourceType VARCHAR(50) = NULL,
    @NguonResourceID INT = NULL,
    @sys_UserID VARCHAR(50),
    @sys_SystemRight INT = 0,
    @sys_FunctionRight VARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    
    
    IF dbo.fn_CheckUserPermission(
           @sys_SystemRight,
           @sys_FunctionRight,
           '[1][2][3][5][9]',
           NULL
       ) = 0
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền thực hiện chức năng quản lý tài nguyên này.', 16, 1);
        RETURN;
    END;
IF NOT EXISTS (
        SELECT 1 FROM dbo.tblHocLieu_FP
        WHERE HocLieuID = @HocLieuID AND Loai = 'TAI_NGUYEN'
          AND (@sys_SystemRight IN (3, 9) OR CreateUser = @sys_UserID) AND Is_Xoa = 0
    )
        THROW 50105, N'Không tìm thấy bộ tài nguyên hoặc bạn không có quyền cập nhật.', 1;

    IF ISNULL(@ParentID, 0) = 0 SET @ParentID = NULL;
    IF ISNULL(@DataJson, '') <> '' AND ISJSON(@DataJson) = 0
        THROW 50106, N'Metadata tài nguyên không phải JSON hợp lệ.', 1;

    IF ISNULL(@NguonTaiNguyenCode, '') = '' AND @LoaiNoiDung <> 'THU_MUC'
        SET @NguonTaiNguyenCode = 'QUAN_LY_TAI_NGUYEN';

    IF ISNULL(@NoiDungID, 0) > 0
    BEGIN
        UPDATE dbo.tblNoiDungHocLieu_FP
        SET ParentID = @ParentID, TenNoiDung = @TenNoiDung, LoaiNoiDung = @LoaiNoiDung,
            ThuTu = @ThuTu, DataJson = @DataJson,
            NguonTaiNguyenCode = COALESCE(@NguonTaiNguyenCode, NguonTaiNguyenCode),
            NguonResourceType = COALESCE(@NguonResourceType, NguonResourceType),
            NguonResourceID = COALESCE(@NguonResourceID, NguonResourceID),
            UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE NoiDungID = @NoiDungID AND HocLieuID = @HocLieuID AND Is_Xoa = 0;
        IF @@ROWCOUNT = 0 THROW 50107, N'Không tìm thấy mục tài nguyên.', 1;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblNoiDungHocLieu_FP
            (HocLieuID, ParentID, TenNoiDung, LoaiNoiDung, ThuTu, DataJson,
             NguonTaiNguyenCode, NguonResourceType, NguonResourceID,
             Is_Xoa, CreateUser, CreateTime)
        VALUES
            (@HocLieuID, @ParentID, @TenNoiDung, @LoaiNoiDung, @ThuTu, @DataJson,
             @NguonTaiNguyenCode, @NguonResourceType, @NguonResourceID,
             0, @sys_UserID, GETDATE());
        SET @NoiDungID = SCOPE_IDENTITY();
    END;

    SELECT * FROM dbo.tblNoiDungHocLieu_FP WHERE NoiDungID = @NoiDungID;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Node_Save] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Node_Save] FROM [public];
