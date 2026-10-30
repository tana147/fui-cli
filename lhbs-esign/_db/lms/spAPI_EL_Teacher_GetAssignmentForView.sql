-- [dbo].[spAPI_EL_Teacher_GetAssignmentForView] 958,0,'NA0000022',9

CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentForView]
    @AssignmentID    INT
  , @AssignToClassID INT = 0
  , @sys_UserID      VARCHAR(9)
  ,@sys_SystemRight INT
AS
BEGIN
	
		SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID)
      
    IF @AssignToClassID > 0
    BEGIN

        DECLARE @SubmissionID INT = 0;
        SELECT @SubmissionID = SubmissionID
        FROM
               dbo.tblEL_Submissions
        WHERE
               AssignToClassID = @AssignToClassID AND IsDeleted = 0;

        --IF @SubmissionID > 0
        --BEGIN
        --    RAISERROR(N'Đã có học sinh đang làm bài. Bạn không thể sửa bài ', 16, 1);
        --    RETURN;
        --END;

        SELECT atc.AssignmentID
             , asm.Title
             , asm.Instructions
             , asm.MonHocID
             , mh.MonHocName
             , asm.KhoiID
             , ISNULL(atc.AssignmentConfig, asm.AssignmentConfig) AS AssignmentConfig
			, ISNULL(atc.AssignmentConfig_NoAnswer, asm.AssignmentConfig_NoAnswer) AS AssignmentConfig_NoAnswer 
             , asm.NienKhoa
             , asm.HocKi
			 , asm.IntegrationSource
        FROM
               dbo.tblEL_AssignToClass          AS atc
               INNER JOIN dbo.tblEL_Assignments AS asm ON asm.AssignmentID = atc.AssignmentID
                                                      AND asm.IsDeleted    = 0
               INNER JOIN dbo.tblMonHoc         AS mh ON mh.MonHocID       = asm.MonHocID
                                                     AND mh.Enable         = 1
        WHERE
               atc.AssignToClassID = @AssignToClassID
          AND  atc.IsDeleted        = 0;
    END;
    ELSE
    BEGIN

        IF NOT EXISTS
        (
            SELECT TOP 1
                   *
            FROM
                   dbo.tblEL_Assignments
            WHERE
                   AssignmentID = @AssignmentID
        )
        BEGIN
            RAISERROR(N'Bạn không có quyền chỉnh sửa bài tập này', 16, 1);
            RETURN;
        END;
        SELECT asm.AssignmentID
             , asm.Title
             , asm.Instructions
             , asm.MonHocID
             , mh.MonHocName
             , asm.KhoiID
             , asm.AssignmentConfig
			 , asm.AssignmentConfig_NoAnswer
             , asm.NienKhoa
             , asm.HocKi
			 , asm.IntegrationSource
        FROM
               dbo.tblEL_Assignments    AS asm
               INNER JOIN dbo.tblMonHoc AS mh ON mh.MonHocID = asm.MonHocID
                                           --  AND mh.Enable   = 1
        WHERE
               asm.AssignmentID = @AssignmentID
          AND  asm.IsDeleted     = 0;
    END;
END;
