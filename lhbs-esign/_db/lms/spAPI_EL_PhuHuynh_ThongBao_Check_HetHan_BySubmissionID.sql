CREATE PROC [dbo].[spAPI_EL_PhuHuynh_ThongBao_Check_HetHan_BySubmissionID]
    @SubmissionID INT
  , @sys_UserID   VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Khai báo biến bảng
    DECLARE @SubmissionsOverDue TABLE
    (
        HocSinhID      VARCHAR(9)
      , SubmissionID   INT
      , AssignmentType VARCHAR(10)
      , DueDate        DATETIME
    );

    -- Chèn dữ liệu từ AssignToClass
    INSERT INTO @SubmissionsOverDue
    (
        HocSinhID
      , SubmissionID
      , AssignmentType
      , DueDate
    )
    SELECT s.HocSinhID
         , s.SubmissionID
         , 'Class'
         , atc.DueDate
    FROM
           dbo.tblEL_Submissions              s
           INNER JOIN dbo.tblEL_AssignToClass atc ON atc.AssignToClassID = s.AssignToClassID
                                                 AND atc.IsDeleted       = 0
           INNER JOIN dbo.tblEL_Assignments   asm ON asm.AssignmentID    = atc.AssignmentID
                                                 --AND ISNULL(asm.IsDev, 0) <> 1
                                                 AND asm.IsDeleted       = 0
    WHERE
           s.SubmissionStatus <> 4
      AND
           (
               s.SubmissionID      = @SubmissionID
          OR   @SubmissionID       = 0
           );

    -- Chèn dữ liệu từ AssignToStudent
    INSERT INTO @SubmissionsOverDue
    (
        HocSinhID
      , SubmissionID
      , AssignmentType
      , DueDate
    )
    SELECT s.HocSinhID
         , s.SubmissionID
         , 'Student'
         , ats.DueDate
    FROM
           dbo.tblEL_Submissions                s
           INNER JOIN dbo.tblEL_AssignToStudent ats ON ats.AssignToStudentID = s.AssignToStudentID
                                                   AND ats.IsDeleted         = 0
           INNER JOIN dbo.tblEL_Assignments     asm ON asm.AssignmentID      = ats.AssignmentID
                                                   -- AND ISNULL(asm.IsDev, 0)  <> 1
                                                   AND asm.IsDeleted         = 0
    WHERE
           s.SubmissionStatus <> 4
      AND
           (
               s.SubmissionID      = @SubmissionID
          OR   @SubmissionID       = 0
           );

    -- Chọn các Submission chưa có thông báo
    DECLARE @NewNotifications TABLE
    (
        HocSinhID    VARCHAR(9)
      , SubmissionID INT
      , DueDate      DATETIME
    );

    INSERT INTO @NewNotifications
    (
        HocSinhID
      , SubmissionID
      , DueDate
    )
    SELECT s.HocSinhID
         , s.SubmissionID
         , s.DueDate
    FROM
           @SubmissionsOverDue          s
           LEFT JOIN dbo.tblEL_ThongBao tb ON s.SubmissionID = tb.SubmissionID;
    --WHERE
    --       tb.ThongBaoID IS NULL;

    -- Tạo thông báo cho các submission chưa có thông báo
    DECLARE @HocSinhID  VARCHAR(9)
          , @SubID      INT
          , @DueDate    DATETIME
          , @TemplateID INT;
    DECLARE @Now DATETIMEOFFSET = DATEADD(HOUR, 7, SYSUTCDATETIME());
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT HocSinhID
         , SubmissionID
         , DueDate
    FROM
           @NewNotifications;

    OPEN cur;
    FETCH NEXT FROM cur
    INTO @HocSinhID
       , @SubID
       , @DueDate;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Giờ hiện tại VN
        SET @TemplateID = CASE
                               WHEN @DueDate <= @Now THEN 10 -- Hết hạn
                               ELSE 11                       -- Nhắc nhở
                          END;

        EXEC dbo.spAPI_ThongBao_Ins @ResourceID = @SubID
                                  , @ResourceType = 'SUBMISSION'
                                  , @ThongBao_TemplateID = @TemplateID
                                  , @NguoiNhan = @HocSinhID
                                  , @SYS_USERID = @sys_UserID;

        FETCH NEXT FROM cur
        INTO @HocSinhID
           , @SubID
           , @DueDate;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;
