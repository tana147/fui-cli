CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_SaveTeacherPermissions_PerTarget]
    @AssignmentID INT,
    @JsonPermissions NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @MonHocID INT;
    DECLARE @NienKhoa INT;

    SELECT @MonHocID = MonHocID,
           @NienKhoa = NienKhoa
    FROM dbo.tblEL_Assignments
    WHERE AssignmentID = @AssignmentID;

    IF @MonHocID IS NULL
    BEGIN
        SELECT TOP 1 @MonHocID = mhl.MonHocID, @NienKhoa = mhl.NienKhoa
        FROM dbo.tblEL_AssignToClass atc
        INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = atc.MonHocLopID
        WHERE atc.AssignmentID = @AssignmentID AND atc.IsDeleted = 0;
    END;

    IF @MonHocID IS NULL
    BEGIN
        SELECT TOP 1 @MonHocID = mhl.MonHocID, @NienKhoa = mhl.NienKhoa
        FROM dbo.tblEL_AssignToStudent ats
        INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = ats.MonHocLopID
        WHERE ats.AssignmentID = @AssignmentID AND ats.IsDeleted = 0;
    END;

    IF @MonHocID IS NULL
    BEGIN
        RAISERROR(N'Bài tập không tồn tại hoặc không hợp lệ.', 16, 1);
        RETURN;
    END;

    DECLARE @Items TABLE (
        AssignToClassID INT NULL,
        AssignToStudentID BIGINT NULL,
        ListTeacherPermission VARCHAR(500) NULL
    );

    IF @JsonPermissions IS NOT NULL AND LTRIM(RTRIM(@JsonPermissions)) <> ''
    BEGIN
        INSERT INTO @Items (AssignToClassID, AssignToStudentID, ListTeacherPermission)
        SELECT AssignToClassID, AssignToStudentID, ListTeacherPermission
        FROM OPENJSON(@JsonPermissions)
        WITH (
            AssignToClassID INT '$.AssignToClassID',
            AssignToStudentID BIGINT '$.AssignToStudentID',
            ListTeacherPermission VARCHAR(500) '$.ListTeacherPermission'
        );
    END;

    BEGIN TRY
        BEGIN TRAN;

        -- 1. Xóa và thêm mới quyền cho các Lớp có trong danh sách truyền lên
        IF EXISTS (SELECT 1 FROM @Items WHERE AssignToClassID IS NOT NULL)
        BEGIN
            DELETE tp
            FROM dbo.tblEL_Resoucre_TeacherPermissions tp
            INNER JOIN @Items it ON it.AssignToClassID = tp.AssignToClassID;

            INSERT INTO dbo.tblEL_Resoucre_TeacherPermissions
            (
                AssignToClassID,
                AssignToStudentID,
                IsGrade,
                IsEdit,
                CreateTime,
                CreateUser,
                GiaoVienID,
                MonHocID,
                Enable,
                NienKhoa
            )
            SELECT it.AssignToClassID,
                   NULL,
                   1,
                   1,
                   GETDATE(),
                   @sys_UserID,
                   LTRIM(RTRIM(s.value)),
                   @MonHocID,
                   1,
                   @NienKhoa
            FROM @Items it
            CROSS APPLY STRING_SPLIT(it.ListTeacherPermission, ',') s
            WHERE it.AssignToClassID IS NOT NULL
              AND LTRIM(RTRIM(ISNULL(s.value, ''))) <> '';
        END;

        -- 2. Xóa và thêm mới quyền cho các Học sinh có trong danh sách truyền lên
        IF EXISTS (SELECT 1 FROM @Items WHERE AssignToStudentID IS NOT NULL)
        BEGIN
            DELETE tp
            FROM dbo.tblEL_Resoucre_TeacherPermissions tp
            INNER JOIN @Items it ON it.AssignToStudentID = tp.AssignToStudentID;

            INSERT INTO dbo.tblEL_Resoucre_TeacherPermissions
            (
                AssignToClassID,
                AssignToStudentID,
                IsGrade,
                IsEdit,
                CreateTime,
                CreateUser,
                GiaoVienID,
                MonHocID,
                Enable,
                NienKhoa
            )
            SELECT NULL,
                   it.AssignToStudentID,
                   1,
                   1,
                   GETDATE(),
                   @sys_UserID,
                   LTRIM(RTRIM(s.value)),
                   @MonHocID,
                   1,
                   @NienKhoa
            FROM @Items it
            CROSS APPLY STRING_SPLIT(it.ListTeacherPermission, ',') s
            WHERE it.AssignToStudentID IS NOT NULL
              AND LTRIM(RTRIM(ISNULL(s.value, ''))) <> '';
        END;

        COMMIT TRAN;

        SELECT 1 AS Success, N'Cập nhật phân quyền giáo viên thành công' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH;
END;
