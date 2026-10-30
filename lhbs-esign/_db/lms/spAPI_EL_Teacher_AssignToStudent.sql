--EXEC [dbo].[spAPI_EL_Teacher_AssignToStudent] 744, '[{"LopID":"N251201","HocSinhID":23300048,"DueDate":"2025-12-18 18:30:00","MaxScore":1,"Status":1,"ResourceType":"ASSIGNMENT","ResourceID":744,"LimitAssigned":1,"Is_Full_Quiz":1}]','MAN'
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_AssignToStudent]
    @AssignmentID     INT
  , @JsonStudentItems NVARCHAR(MAX)
  , @sys_UserID       VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    --------------------------------------------------------------------
    -- STEP 0: KHAI BÃO BIáº¾N VÃ€ Báº¢NG Táº M
    --------------------------------------------------------------------
    DECLARE @MonHocID                  INT
          , @AssignmentConfig          NVARCHAR(MAX)
          , @AssignmentConfig_NoAnswer NVARCHAR(MAX);

    DECLARE @JsonItems TABLE
    (
        LopID         VARCHAR(100)
      , Status        INT
      , DueDate       DATETIME
      , MaxScore      DECIMAL(5, 2)
      , ResourceType  NVARCHAR(50)
      , ResourceID    INT
      , LimitAssigned INT
      , Is_Full_Quiz  BIT
      , HocSinhID     INT
    );

    DECLARE @Affected TABLE
    (
        Action            NVARCHAR(10)
      , AssignToStudentID INT
      , AssignmentID      INT
      , MonHocLopID       INT
      , HocSinhID         INT
      , DueDate           DATETIME
      , MaxScore          DECIMAL(5, 2)
      , Status            INT
      , ResourceType      NVARCHAR(50)
      , ResourceID        INT
      , LimitAssigned     INT
      , Is_Full_Quiz      BIT
    );

     -- Báº£ng há»©ng káº¿t quáº£ tblThongBao
    DECLARE @Ins_ThongBao TABLE
    (
            SubmissionID INT
        , ThongBao_TemplateID INT
        , NguoiNhan Varchar(9)
        , ThoiGianNhan DATETIME
    )

    CREATE TABLE #NewSubmissions
    (
        SubmissionID INT
      , HocSinhID    VARCHAR(9)
    );

    --------------------------------------------------------------------
    -- STEP 1: PARSE JSON
    --------------------------------------------------------------------
    INSERT INTO @JsonItems
    (
        LopID
      , Status
      , DueDate
      , MaxScore
      , ResourceType
      , ResourceID
      , LimitAssigned
      , Is_Full_Quiz
      , HocSinhID
    )
    SELECT JSON_VALUE([Value], '$.LopID')
         , JSON_VALUE([Value], '$.Status')
         , TRY_CONVERT(DATETIME, JSON_VALUE([Value], '$.DueDate'))
         , TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE([Value], '$.MaxScore'))
         , JSON_VALUE([Value], '$.ResourceType')
         , JSON_VALUE([Value], '$.ResourceID')
         , JSON_VALUE([Value], '$.LimitAssigned')
         , JSON_VALUE([Value], '$.Is_Full_Quiz')
         , JSON_VALUE([Value], '$.HocSinhID')
    FROM
           OPENJSON(@JsonStudentItems);

    IF EXISTS
    (
        SELECT 1
        FROM
               @JsonItems
        WHERE
               HocSinhID IS NULL
    )
    BEGIN
        RAISERROR('JSON khÃ´ng há»£p lá»‡: thiáº¿u HocSinhID', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------------------
    -- STEP 2: Láº¤Y MONHOCID + CONFIG (TÃ™Y THEO RESOURCE TYPE)
    --------------------------------------------------------------------
    IF EXISTS
    (
        SELECT 1
        FROM
               @JsonItems
        WHERE
               ResourceType = 'ASSIGNMENT'
    )
    BEGIN
        SELECT @MonHocID                  = MonHocID
             , @AssignmentConfig          = AssignmentConfig
             , @AssignmentConfig_NoAnswer = AssignmentConfig_NoAnswer
        FROM
               dbo.tblEL_Assignments
        WHERE
               AssignmentID = @AssignmentID;
    END;
    ELSE IF EXISTS
    (
        SELECT 1
        FROM
               @JsonItems
        WHERE
               ResourceType = 'LESSON'
    )
    BEGIN
        SELECT @MonHocID                  = MonHocID
             , @AssignmentConfig          = NULL
             , @AssignmentConfig_NoAnswer = NULL
        FROM
               dbo.tblEL_Lessons
        WHERE
               LessonID = @AssignmentID;
    END;

    IF @MonHocID IS NULL
    BEGIN
        RAISERROR('Resource khÃ´ng tá»“n táº¡i hoáº·c khÃ´ng há»£p lá»‡.', 16, 1);
        RETURN;
    END

    --------------------------------------------------------------------
    -- STEP 3: MAP LopID â†’ MonHocLopID
    --------------------------------------------------------------------
    ;
    WITH MHL AS
    (
        SELECT COALESCE(mhl.MonHocLopID, mhl_fallback.MonHocLopID) AS MonHocLopID
             , ji.HocSinhID
             , ji.DueDate
             , ji.Status
             , ji.MaxScore
             , ji.ResourceType
             , ji.ResourceID
             , ji.LimitAssigned
             , ji.Is_Full_Quiz
        FROM
               @JsonItems                  ji
               LEFT JOIN dbo.tblMonHocLop mhl ON mhl.LopNhomID = ji.LopID
                                              AND mhl.MonHocID  = @MonHocID
               OUTER APPLY (
                   SELECT TOP 1 mhl2.MonHocLopID
                   FROM dbo.tblMonHocLop mhl2
                   WHERE mhl2.LopNhomID = ji.LopID
               ) mhl_fallback
    )
       , Dedup AS
    (
        SELECT MonHocLopID
             , HocSinhID
             , MAX(DueDate)                   AS DueDate
             , MAX(Status)                    AS Status
             , MAX(MaxScore)                  AS MaxScore
             , MAX(ResourceType)              AS ResourceType
             , MAX(ResourceID)                AS ResourceID
             , MAX(LimitAssigned)             AS LimitAssigned
             , MAX(CAST(Is_Full_Quiz AS INT)) AS Is_Full_Quiz
        FROM
               MHL
        GROUP BY
               MonHocLopID
             , HocSinhID
    )
    --------------------------------------------------------------------
    -- STEP 4: MERGE AssignToStudent
    --------------------------------------------------------------------
    MERGE dbo.tblEL_AssignToStudent AS target
    USING Dedup AS source
    ON (
           target.AssignmentID = @AssignmentID
     AND   target.HocSinhID = source.HocSinhID
	 AND target.IsDeleted = 0
       )
    WHEN MATCHED THEN UPDATE SET DueDate = ISNULL(source.DueDate, target.DueDate)
                               , MaxScore = ISNULL(source.MaxScore, target.MaxScore)
                               , Status = ISNULL(source.Status, target.Status)
                               , ResourceType = source.ResourceType
                               , ResourceID = source.ResourceID
                               -- Đồng bộ cấu hình cho bản giao cá nhân đã tồn tại để lượt mới
                               -- dùng đúng RANDOM pool; bài giảng không có config nên giữ giá trị cũ.
                               , AssignmentConfig = CASE WHEN source.ResourceType = 'ASSIGNMENT'
                                                         THEN @AssignmentConfig
                                                         ELSE target.AssignmentConfig END
                               , AssignmentConfig_NoAnswer = CASE WHEN source.ResourceType = 'ASSIGNMENT'
                                                                   THEN @AssignmentConfig_NoAnswer
                                                                   ELSE target.AssignmentConfig_NoAnswer END
                               , LimitAssigned = source.LimitAssigned
                               , Is_Full_Quiz = source.Is_Full_Quiz
                               , UpdateUser = @sys_UserID
                               , UpdateTime = GETDATE()
                               , IsDeleted = 0
    WHEN NOT MATCHED THEN INSERT
                          (
                              AssignmentID                            , MonHocLopID
                            , AssignmentConfig
                            , AssignmentConfig_NoAnswer
                            , HocSinhID
                            , DueDate
                            , MaxScore
                            , Status
                            , ResourceType
                            , ResourceID
							, NienKhoa
                            , LimitAssigned
                            , Is_Full_Quiz
                            , CreateUser
                          )
                          VALUES
                          (
                              @AssignmentID
                            , source.MonHocLopID
                            , @AssignmentConfig
                            , @AssignmentConfig_NoAnswer
                            , source.HocSinhID
                            , source.DueDate
                            , source.MaxScore
                            , source.Status
                            , source.ResourceType
                            , source.ResourceID
							, dbo.fn_GetNienKhoa_HienTai()
                            , source.LimitAssigned
                            , source.Is_Full_Quiz
                            , @sys_UserID
                          )
    OUTPUT $action
         , inserted.AssignToStudentID
         , inserted.AssignmentID
         , inserted.MonHocLopID
         , inserted.HocSinhID
         , inserted.DueDate
         , inserted.MaxScore
         , inserted.Status
         , inserted.ResourceType
         , inserted.ResourceID
         , inserted.LimitAssigned
         , inserted.Is_Full_Quiz
    INTO @Affected;

    --------------------------------------------------------------------
    -- STEP 5: INSERT SUBMISSION TRÆ¯á»šC KHI Gá»¬I THÃ”NG BÃO
    --------------------------------------------------------------------
    INSERT INTO dbo.tblEL_Submissions
    (
        AssignToStudentID
    , AssignToClassID
      , HocSinhID
      , SubmissionStatus
      , LanNop
      , IsDeleted
      , CreateTime
      , CreateUser
    )
    OUTPUT inserted.SubmissionID
         , inserted.HocSinhID
    INTO #NewSubmissions
    (
        SubmissionID
      , HocSinhID
    )
    SELECT ats.AssignToStudentID
        , -1
         , ats.HocSinhID
         , 0 -- chÆ°a ná»™p
         , 1 -- sá»‘ láº§n ná»™p
         , 0
         , GETDATE()
         , @sys_UserID
    FROM
           @Affected ats;

    --------------------------------------------------------------------
    -- STEP 6: Gá»¬I THÃ”NG BÃO SAU KHI CÃ“ SUBMISSIONID
    --------------------------------------------------------------------
    DECLARE @SID  INT
          , @HSID VARCHAR(9);

    DECLARE cur CURSOR FOR
    SELECT SubmissionID
         , HocSinhID
    FROM
           #NewSubmissions;

    OPEN cur;
    FETCH NEXT FROM cur
    INTO @SID
       , @HSID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @ThongBao_ID INT
         INSERT INTO dbo.tblEL_ThongBao
            (
               ThongBao_TemplateID
	          , ResourceID
	          , ResourceType
              , NguoiNhan
              , ThoiGianNhan
	          , NguoiGiao
	          , ThoiGianGiao
            )
            VALUES
            (
                1 -- ThongBao_TemplateID - int 
	          , @SID
	          , 'SUBMISSION'
              , @HSID           -- ThoiGianNhan - datetime
              , GETDATE()            -- IsDeleted - bit
	          , @SYS_USERID
	          , GETDATE()
            );
            SET @ThongBao_ID = SCOPE_IDENTITY(); 

        
        
            PRINT( CAST(dbo.fn_CallAPI_SendToME(@ThongBao_ID) as nvarchar(max)))

        FETCH NEXT FROM cur
        INTO @SID, @HSID;
    END;

    CLOSE cur;
    DEALLOCATE cur;

    --------------------------------------------------------------------
    -- STEP 7: TRẢ KẾT QUẢ
    --------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM @Affected)
    BEGIN
        SELECT 0                                          AS Success
             , N'Không thể giao bài: Không tìm thấy phân công lớp/nhóm phù hợp trong hệ thống.' AS Message;
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM @JsonItems WHERE ResourceType = 'LESSON')
    BEGIN
        UPDATE dbo.tblEL_Lessons
        SET Status = 3, UpdateTime = GETDATE(), UpdateUser = @sys_UserID
        WHERE LessonID = @AssignmentID;
    END;

    SELECT Success = 1
         , Message = N'Giao bài cho học sinh thành công.';

    SELECT *
    FROM
           @Affected
    ORDER BY
           AssignToStudentID;

END;
