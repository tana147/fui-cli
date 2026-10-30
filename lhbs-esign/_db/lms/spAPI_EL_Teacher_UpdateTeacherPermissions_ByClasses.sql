CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_UpdateTeacherPermissions_ByClasses]
    @AssignmentID INT,
    @ListAssignToClassID VARCHAR(MAX),
    @ListAssignToStudentID VARCHAR(MAX),
    @ListTeacherPermission VARCHAR(500),
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

    -- Bảng danh sách AssignToClassID cần cập nhật
    DECLARE @TargetClasses TABLE (AssignToClassID INT PRIMARY KEY);

    IF @ListAssignToClassID IS NOT NULL 
       AND LTRIM(RTRIM(@ListAssignToClassID)) <> '' 
       AND UPPER(LTRIM(RTRIM(@ListAssignToClassID))) <> 'ALL'
    BEGIN
        INSERT INTO @TargetClasses (AssignToClassID)
        SELECT DISTINCT CAST(LTRIM(RTRIM(value)) AS INT)
        FROM STRING_SPLIT(@ListAssignToClassID, ',')
        WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
    END
    ELSE IF UPPER(LTRIM(RTRIM(ISNULL(@ListAssignToClassID, '')))) = 'ALL'
    BEGIN
        INSERT INTO @TargetClasses (AssignToClassID)
        SELECT DISTINCT AssignToClassID
        FROM dbo.tblEL_AssignToClass
        WHERE AssignmentID = @AssignmentID
          AND IsDeleted = 0;
    END;

    -- Bảng danh sách AssignToStudentID cần cập nhật
    DECLARE @TargetStudents TABLE (AssignToStudentID BIGINT PRIMARY KEY);

    IF @ListAssignToStudentID IS NOT NULL 
       AND LTRIM(RTRIM(@ListAssignToStudentID)) <> '' 
       AND UPPER(LTRIM(RTRIM(@ListAssignToStudentID))) <> 'ALL'
    BEGIN
        INSERT INTO @TargetStudents (AssignToStudentID)
        SELECT DISTINCT CAST(LTRIM(RTRIM(value)) AS BIGINT)
        FROM STRING_SPLIT(@ListAssignToStudentID, ',')
        WHERE TRY_CAST(LTRIM(RTRIM(value)) AS BIGINT) IS NOT NULL;
    END
    ELSE IF UPPER(LTRIM(RTRIM(ISNULL(@ListAssignToStudentID, '')))) = 'ALL'
    BEGIN
        INSERT INTO @TargetStudents (AssignToStudentID)
        SELECT DISTINCT AssignToStudentID
        FROM dbo.tblEL_AssignToStudent
        WHERE AssignmentID = @AssignmentID
          AND IsDeleted = 0;
    END;

    -- Nếu cả 2 đều không truyền cụ thể và không phải rỗng cố ý
    IF NOT EXISTS (SELECT 1 FROM @TargetClasses) AND NOT EXISTS (SELECT 1 FROM @TargetStudents)
    BEGIN
        INSERT INTO @TargetClasses (AssignToClassID)
        SELECT DISTINCT AssignToClassID
        FROM dbo.tblEL_AssignToClass
        WHERE AssignmentID = @AssignmentID AND IsDeleted = 0;

        INSERT INTO @TargetStudents (AssignToStudentID)
        SELECT DISTINCT AssignToStudentID
        FROM dbo.tblEL_AssignToStudent
        WHERE AssignmentID = @AssignmentID AND IsDeleted = 0;
    END;

    IF NOT EXISTS (SELECT 1 FROM @TargetClasses) AND NOT EXISTS (SELECT 1 FROM @TargetStudents)
    BEGIN
        RAISERROR(N'Không tìm thấy lớp hoặc học sinh nào đã giao cho bài tập này.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        -- 1. Cập nhật quyền cho LỚP (nếu có TargetClasses)
        IF EXISTS (SELECT 1 FROM @TargetClasses)
        BEGIN
            DELETE tp
            FROM dbo.tblEL_Resoucre_TeacherPermissions tp
            INNER JOIN @TargetClasses tc ON tc.AssignToClassID = tp.AssignToClassID;

            IF @ListTeacherPermission IS NOT NULL AND LTRIM(RTRIM(@ListTeacherPermission)) <> ''
            BEGIN
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
                SELECT tc.AssignToClassID,
                       NULL,
                       1,
                       1,
                       GETDATE(),
                       @sys_UserID,
                       LTRIM(RTRIM(s.value)),
                       @MonHocID,
                       1,
                       @NienKhoa
                FROM @TargetClasses tc
                CROSS JOIN STRING_SPLIT(@ListTeacherPermission, ',') s
                WHERE LTRIM(RTRIM(s.value)) <> '';
            END;
        END;

        -- 2. Cập nhật quyền cho HỌC SINH (nếu có TargetStudents)
        IF EXISTS (SELECT 1 FROM @TargetStudents)
        BEGIN
            DELETE tp
            FROM dbo.tblEL_Resoucre_TeacherPermissions tp
            INNER JOIN @TargetStudents ts ON ts.AssignToStudentID = tp.AssignToStudentID;

            IF @ListTeacherPermission IS NOT NULL AND LTRIM(RTRIM(@ListTeacherPermission)) <> ''
            BEGIN
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
                       ts.AssignToStudentID,
                       1,
                       1,
                       GETDATE(),
                       @sys_UserID,
                       LTRIM(RTRIM(s.value)),
                       @MonHocID,
                       1,
                       @NienKhoa
                FROM @TargetStudents ts
                CROSS JOIN STRING_SPLIT(@ListTeacherPermission, ',') s
                WHERE LTRIM(RTRIM(s.value)) <> '';
            END;
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