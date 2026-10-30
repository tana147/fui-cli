CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_AssignToClasses_CLASS]
    @AssignmentID          INT
  , @JsonClassItems        NVARCHAR(MAX) -- '[{"LopID":1001,"DueDate":"2025-08-20 23:59","MaxScore":10.0}, ...]'
  , @ListTeacherPermission VARCHAR(200)
  , @sys_UserID            VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @AssignmentConfig_Original NVARCHAR(MAX);
    DECLARE @AssignmentConfig_Original_NoAnswer NVARCHAR(MAX);
    DECLARE @MonHocID INT;
    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();


    -- Bảng hứng kết quả MERGE
    DECLARE @Affected TABLE
    (
        Action          NVARCHAR(10) -- 'INSERT' | 'UPDATE'
      , AssignToClassID INT          -- PK của tblEL_AssignToClass
      , AssignmentID    INT
      , Status          INT
      , MonHocLopID     INT
      , DueDate         DATETIME
      , MaxScore        DECIMAL(5, 2)
      , ResourceType    NVARCHAR(50) -- Thêm ResourceType
      , ResourceID      INT          -- Thêm ResourceID
      , LimitAssigned   INT
      , Is_Full_Quiz    BIT
    );

    -- Bảng hứng kết quả tblThongBao
    DECLARE @Ins_ThongBao TABLE
    (
        SubmissionID        INT
      , ThongBao_TemplateID INT
      , NguoiNhan           VARCHAR(9)
      , ThoiGianNhan        DATETIME
    );

    BEGIN TRY
        BEGIN TRAN;

        -- 1) Lấy MonHocID và AssignmentConfig từ đề gốc
        IF EXISTS
        (
            SELECT 1
            FROM
                   OPENJSON(@JsonClassItems)
            WHERE
                   JSON_VALUE([Value], '$.ResourceType') = 'ASSIGNMENT'
        )
        BEGIN
            SELECT @MonHocID                           = MonHocID
                 , @AssignmentConfig_Original          = AssignmentConfig
                 , @AssignmentConfig_Original_NoAnswer = AssignmentConfig_NoAnswer
            FROM
                   dbo.tblEL_Assignments
            WHERE
                   AssignmentID = @AssignmentID;
        END;
        ELSE IF EXISTS
        (
            SELECT 1
            FROM
                   OPENJSON(@JsonClassItems)
            WHERE
                   JSON_VALUE([Value], '$.ResourceType') = 'LESSON'
        )
        BEGIN
            SELECT @MonHocID                  = MonHocID
                 , @AssignmentConfig_Original = NULL
            FROM
                   dbo.tblEL_Lessons
            WHERE
                   LessonID = @AssignmentID;
        END;

        IF @MonHocID IS NULL
        BEGIN
            RAISERROR(N'Resource không tồn tại hoặc không hợp lệ.', 16, 1);
            RETURN;
        END;

        -- 2) Parse JSON: lấy LopID + DueDate + MaxScore, map ra MonHocLopID
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
        );

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
        )
        SELECT CAST(JSON_VALUE([Value], '$.LopID') AS VARCHAR(100))
             , CAST(JSON_VALUE([Value], '$.Status') AS INT)
             , TRY_CONVERT(DATETIME, JSON_VALUE([Value], '$.DueDate'))
             , TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE([Value], '$.MaxScore'))
             , CAST(JSON_VALUE([Value], '$.ResourceType') AS NVARCHAR(50))
             , CAST(JSON_VALUE([Value], '$.ResourceID') AS INT)
             , CAST(JSON_VALUE([Value], '$.LimitAssigned') AS INT)
             , CAST(JSON_VALUE([Value], '$.Is_Full_Quiz') AS BIT)
        FROM
               OPENJSON(@JsonClassItems);

        -- Validate dữ liệu JSON
        IF EXISTS
        (
            SELECT 1
            FROM
                   @JsonItems
            WHERE
                   LopID IS NULL
               OR  ResourceType IS NULL
               OR  @AssignmentID IS NULL
        )
        BEGIN
            RAISERROR(N'Dữ liệu JSON không hợp lệ: thiếu LopID / ResourceType / AssignmentID.', 16, 1);
            ROLLBACK TRAN;
            RETURN;
        END;

        WITH MonHocLopList AS
        (
            SELECT mhl.MonHocLopID
                 , ji.DueDate
                 , ji.Status
                 , ji.MaxScore
                 , ji.ResourceType
                 , ji.ResourceID
                 , ji.LimitAssigned
                 , ji.Is_Full_Quiz
            FROM
                   @JsonItems                  ji
                   INNER JOIN dbo.tblMonHocLop mhl ON mhl.LopNhomID = ji.LopID
                                                  AND mhl.MonHocID  = @MonHocID
                                                  AND mhl.NienKhoa  = @NienKhoa_HienTai
        )
           -- Gom trùng theo MonHocLopID để tránh lỗi "update the same row more than once"
           , SourceDedup AS
        (
            SELECT MonHocLopID
                 , MAX(DueDate)       AS DueDate      -- hoặc chọn MIN/ giá trị mới nhất tùy quy tắc
                 , MAX(MaxScore)      AS MaxScore
                 , MAX(Status)        AS Status
                 , MAX(ResourceType)  AS ResourceType -- Thêm ResourceType
                 , MAX(ResourceID)    AS ResourceID   -- Thêm ResourceID
                 , MAX(LimitAssigned) AS LimitAssigned
                 , Is_Full_Quiz       AS Is_Full_Quiz
            FROM
                   MonHocLopList
            GROUP BY
                   MonHocLopID
                 , Is_Full_Quiz
        )

        -- 3) MERGE vào tblEL_AssignToClass theo từng lớp
        MERGE dbo.tblEL_AssignToClass WITH (HOLDLOCK) AS target
        USING
        (
            SELECT MonHocLopID
                 , DueDate
                 , MaxScore
                 , Status
                 , ResourceType
                 , ResourceID
                 , LimitAssigned
                 , Is_Full_Quiz
            FROM
                   SourceDedup
        ) AS source
        ON (
               target.AssignmentID = @AssignmentID
         AND   target.MonHocLopID = source.MonHocLopID
         AND   target.IsDeleted = 0
           )
        WHEN MATCHED THEN UPDATE SET DueDate = ISNULL(source.DueDate, target.DueDate)
                                   , MaxScore = ISNULL(source.MaxScore, target.MaxScore)
                                   , Status = ISNULL(source.Status, target.Status)
                                   , ResourceType = ISNULL(source.ResourceType, target.ResourceType)
                                   , ResourceID = ISNULL(source.ResourceID, target.ResourceID)
                                   -- Bản giao lớp có thể đã tồn tại trước khi giáo viên đổi cấu hình đề.
                                   -- Đồng bộ cả hai bản config để lượt làm mới đọc được RANDOM pool;
                                   -- resource LESSON phải giữ nguyên vì không có AssignmentConfig.
                                   , AssignmentConfig = CASE WHEN source.ResourceType = 'ASSIGNMENT'
                                                             THEN @AssignmentConfig_Original
                                                             ELSE target.AssignmentConfig END
                                   , AssignmentConfig_NoAnswer = CASE WHEN source.ResourceType = 'ASSIGNMENT'
                                                                       THEN @AssignmentConfig_Original_NoAnswer
                                                                       ELSE target.AssignmentConfig_NoAnswer END
                                   , UpdateTime = GETDATE()
                                   , UpdateUser = @sys_UserID
                                   , IsDeleted = 0
                                   , LimitAssigned = source.LimitAssigned
                                   , Is_Full_Quiz = source.Is_Full_Quiz
        WHEN NOT MATCHED THEN INSERT
                              (
                                  AssignmentID
                                , MonHocLopID
                                , AssignmentConfig
                                , AssignmentConfig_NoAnswer
                                , DueDate
                                , MaxScore
                                , ResourceType
                                , ResourceID
                                , NienKhoa
                                , CreateUser
                                , Status
                                , LimitAssigned
                                , Is_Full_Quiz
                              )
                              VALUES
                              (
                                  @AssignmentID
                                , source.MonHocLopID
                                , @AssignmentConfig_Original
                                , @AssignmentConfig_Original_NoAnswer
                                , source.DueDate
                                , source.MaxScore
                                , source.ResourceType
                                , source.ResourceID
                                , dbo.fn_GetNienKhoa_HienTai()
                                , @sys_UserID
                                , source.Status
                                , source.LimitAssigned
                                , source.Is_Full_Quiz
                              )
        OUTPUT $action AS Action
             , inserted.AssignToClassID
             , inserted.AssignmentID
             , inserted.MonHocLopID
             , inserted.DueDate
             , inserted.Status
             , inserted.MaxScore
             , inserted.ResourceType
             , inserted.ResourceID
             , inserted.LimitAssigned
             , inserted.Is_Full_Quiz
        INTO @Affected
        (
            Action
          , AssignToClassID
          , AssignmentID
          , MonHocLopID
          , DueDate
          , Status
          , MaxScore
          , ResourceType
          , ResourceID
          , LimitAssigned
          , Is_Full_Quiz
        );

        COMMIT TRAN;

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

        -- Kết quả: 1) Thông điệp  2) Danh sách các ID bị tác động (INSERT/UPDATE)
        SELECT 1                                          AS Success
             , N'Đã giao bài thành công (theo từng lớp).' AS Message;

        SELECT Action
             , AssignToClassID
             , AssignmentID
             , MonHocLopID
             , DueDate
             , MaxScore
             , Status
             , ResourceType -- Thêm ResourceType
             , ResourceID   -- Thêm ResourceID
             , LimitAssigned
             , Is_Full_Quiz
        FROM
               @Affected
        ORDER BY
               AssignToClassID;

        ---------------------------------------------------------------------
        -- TẠO BẢNG CHỨA HỌC SINH VÀ THÔNG TIN THÔNG BÁO (SUBMISSIONID = NULL ban đầu)
        ---------------------------------------------------------------------
        DECLARE @Table_HocSinhID TABLE
        (
            SubmissionID        INT NULL
          , ThongBao_TemplateID INT
          , NguoiNhan           VARCHAR(9)
          , ThoiGianNhan        DATETIME
        );

        -- Insert từ tblHocSinhLop
        INSERT INTO @Table_HocSinhID
        (
            SubmissionID
          , ThongBao_TemplateID
          , NguoiNhan
          , ThoiGianNhan
        )
        SELECT NULL          AS SubmissionID
             , 1             AS ThongBao_TemplateID
             , hsl.HocSinhID AS NguoiNhan
             , GETDATE()     AS ThoiGianNhan
        FROM
               dbo.tblHocSinhLop         hsl
               INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
                                           AND hs.TinhTrang = 0
        WHERE
               hsl.LopID IN
               (
                   SELECT LopID
                   FROM
                          @JsonItems
               )
          AND  hsl.NienKhoa = @NienKhoa_HienTai
          AND  hsl.Enable   = 1
          AND  hsl.HocSinhID IS NOT NULL
        UNION
        SELECT NULL          AS SubmissionID
             , 1             AS ThongBao_TemplateID
             , hsn.HocSinhID AS NguoiNhan
             , GETDATE()     AS ThoiGianNhan
        FROM
               dbo.tblHocSinhNhom        hsn
               INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID
                                           AND hs.TinhTrang = 0
        WHERE
               hsn.NhomID IN
               (
                   SELECT LopID
                   FROM
                          @JsonItems
               )
          AND  hsn.Enable   = 1
          AND  hsn.HocSinhID IS NOT NULL;



        ---------------------------------------------------------------------
        -- TẠO submision và bắt các SubmissionID vừa sinh
        ---------------------------------------------------------------------
        DECLARE @InsertedSubmission TABLE
        (
            SubmissionID    INT
          , HocSinhID       VARCHAR(9)
          , AssignToClassID INT
        );

        INSERT INTO dbo.tblEL_Submissions
        (
            AssignToClassID
          , HocSinhID
          , SubmissionStatus
          , LanNop
          , IsDeleted
          , CreateTime
          , CreateUser
        )
        OUTPUT inserted.SubmissionID
             , inserted.HocSinhID
             , inserted.AssignToClassID
        INTO @InsertedSubmission
        (
            SubmissionID
          , HocSinhID
          , AssignToClassID
        )
        SELECT a.AssignToClassID
             , t.NguoiNhan
             , 0                                    AS SubmissionStatus
             , 1                                    AS LanNop
             , 0                                    AS IsDeleted
             , GETDATE()                            AS CreateTime
             , t.NguoiNhan                          AS CreateUser
        FROM
               @Affected                    a
               INNER JOIN dbo.tblMonHocLop  mhl ON mhl.MonHocLopID = a.MonHocLopID
                                               AND mhl.Enable      = 1
                                               AND mhl.NienKhoa    = @NienKhoa_HienTai
               INNER JOIN (
                   SELECT hsl.LopID AS UnitID, CAST(hsl.HocSinhID AS VARCHAR(9)) AS NguoiNhan
                   FROM dbo.tblHocSinhLop hsl
                   WHERE hsl.NienKhoa = @NienKhoa_HienTai AND hsl.Enable = 1
                   UNION
                   SELECT hsn.NhomID AS UnitID, CAST(hsn.HocSinhID AS VARCHAR(9)) AS NguoiNhan
                   FROM dbo.tblHocSinhNhom hsn
                   WHERE hsn.Enable = 1
               ) t ON t.UnitID = mhl.LopNhomID;

        -- Cập nhật lại SubmissionID vào @Table_HocSinhID theo HocSinhID
        UPDATE t
        SET    t.SubmissionID = s.SubmissionID
        FROM
               @Table_HocSinhID               t
               INNER JOIN @InsertedSubmission s ON t.NguoiNhan = s.HocSinhID;

        -- Gắn thông báo (bây giờ @Table_HocSinhID.SubmissionID đã được gán)
        INSERT INTO dbo.tblEL_ThongBao
        (
            SubmissionID
          , ThongBao_TemplateID
          , NguoiNhan
          , ThoiGianNhan
        )
        OUTPUT inserted.SubmissionID
             , inserted.ThongBao_TemplateID
             , inserted.NguoiNhan
             , inserted.ThoiGianNhan
        INTO @Ins_ThongBao
        SELECT SubmissionID
             , ThongBao_TemplateID
             , NguoiNhan
             , ThoiGianNhan
        FROM
               @Table_HocSinhID;



        -- Danh sách giáo viên quản lý của một bài phải là trạng thái hiện tại
        -- của form Giao bài. Khi giao lại bài, xóa quyền cũ trên các lớp vừa
        -- tác động trước rồi mới ghi lại danh sách mới; nếu danh sách rỗng thì
        -- quyền cũ cũng phải được thu hồi.
        DELETE tp
        FROM dbo.tblEL_Resoucre_TeacherPermissions tp
        INNER JOIN @Affected af ON af.AssignToClassID = tp.AssignToClassID;

        -- Phân quyền cho giáo viên
        IF @ListTeacherPermission IS NOT NULL
       AND @ListTeacherPermission <> ''
        BEGIN
            INSERT INTO tblEL_Resoucre_TeacherPermissions
            (
                AssignToClassID
              , IsGrade
              , IsEdit
              , CreateTime
              , CreateUser
              , GiaoVienID
              , MonHocID
              , NienKhoa
              , Enable
            )
            SELECT af.AssignToClassID
                 , 1
                 , 1
                 , GETDATE()
                 , @sys_UserID
                 , LTRIM(RTRIM(value)) AS GiaoVienID
                 , @MonHocID
                 , NULL
                 , 1
            FROM
                   STRING_SPLIT(@ListTeacherPermission, ',')
                   CROSS JOIN @Affected af;
        END;



    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        SELECT Success     = 0
             , Message     = N'Lỗi khi giao bài: ' + ERROR_MESSAGE()
             , ErrorNumber = ERROR_NUMBER()
             , ErrorState  = ERROR_STATE()
             , ErrorLine   = ERROR_LINE();
    END CATCH;
END;
