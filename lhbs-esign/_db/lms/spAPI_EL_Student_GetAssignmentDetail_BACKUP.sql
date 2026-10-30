CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetAssignmentDetail_backup]--  183, '17100127'
    @AssignToClassID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HocSinhID_INT INT = CAST(RIGHT(@sys_UserID, 8) AS INT);
    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @AssignedUnitID VARCHAR(10);

    IF @AssignToClassID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài.', 16, 1);
        RETURN;
    END

    -- Lấy ra Lớp/Nhóm mà bài tập này được giao
    SELECT @AssignedUnitID = mhl.LopNhomID 
    FROM dbo.tblEL_AssignToClass atc 
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID and atc.IsDeleted = 0;

    -- Kiểm tra xem học sinh có thực sự thuộc Lớp/Nhóm được giao bài này không.
    IF @AssignedUnitID IS NULL OR NOT EXISTS (
        SELECT 1 FROM (
            -- Lấy tất cả Lớp/Nhóm của học sinh
            SELECT l.LopID AS UnitID FROM dbo.tblHocSinhLop hsl JOIN dbo.tblLop l ON hsl.LopID = l.LopID WHERE hsl.HocSinhID = @HocSinhID_INT AND hsl.Enable = 1 AND l.NienKhoa = @NienKhoa_HienTai
            UNION
            SELECT n.NhomID FROM dbo.tblHocSinhNhom hsn JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID WHERE hsn.HocSinhID = @HocSinhID_INT AND hsn.Enable = 1 AND n.NienKhoa = @NienKhoa_HienTai
        ) AS MyUnits
        WHERE MyUnits.UnitID = @AssignedUnitID
    )
    BEGIN
        RAISERROR(N'[Unauthorized] Bạn không có quyền truy cập bài tập này.', 16, 1);
        RETURN;
    END

    
	 -- === BƯỚC CHUẨN BỊ ===
    DECLARE @OriginalAssignmentConfig NVARCHAR(MAX);
    DECLARE @SubmissionStatus TINYINT;
    DECLARE @ProcessedAssignmentConfig NVARCHAR(MAX);

    SELECT @OriginalAssignmentConfig = atc.AssignmentConfig FROM dbo.tblEL_AssignToClass AS atc WHERE atc.AssignToClassID = @AssignToClassID;
    SELECT @SubmissionStatus = SubmissionStatus FROM dbo.tblEL_Submissions WHERE AssignToClassID = @AssignToClassID AND HocSinhID = @HocSinhID_INT;

    SET @ProcessedAssignmentConfig = @OriginalAssignmentConfig;
    IF ISNULL(@SubmissionStatus, 0) < 4
    BEGIN
        -- =================================================================
        -- == LOGIC MỚI: Xé nhỏ JSON và Dựng lại (Tương thích SQL 2016)   ==
        -- =================================================================
        SELECT @ProcessedAssignmentConfig = (
            SELECT
                JSON_VALUE(@OriginalAssignmentConfig, '$.version') AS version,
                JSON_VALUE(@OriginalAssignmentConfig, '$.type') AS type,
                (
                    SELECT 
                        g.id, g.title, g.description, JSON_QUERY(g.media_json) AS media,
                        (
                            SELECT
                                q.id, q.type, q.label, q.ordinalNumber, q.points, q.gradingType,
                                -- Bắt đầu dựng lại object 'config' MÀ KHÔNG CÓ ĐÁP ÁN
                                (
                                    SELECT
                                        JSON_QUERY(q.config_json, '$.media') AS media,
                                        JSON_VALUE(q.config_json, '$.isAdvanced') AS isAdvanced,
                                        JSON_VALUE(q.config_json, '$.questionText') AS questionText,
                                        JSON_VALUE(q.config_json, '$.statement') AS statement,
                                        -- Dựng lại mảng 'options' mà không có các trường đáp án
                                        JSON_QUERY(
                                            (SELECT id, text FROM OPENJSON(JSON_QUERY(q.config_json, '$.options')) WITH (id VARCHAR(100) '$.id', text NVARCHAR(MAX) '$.text') FOR JSON PATH)
                                        ) AS options,
                                        -- Dựng lại mảng 'parts' mà không có trường 'acceptedAnswers'
                                        JSON_QUERY(
                                            (SELECT type, value, id FROM OPENJSON(JSON_QUERY(q.config_json, '$.parts')) WITH (type VARCHAR(20) '$.type', value NVARCHAR(MAX) '$.value', id VARCHAR(100) '$.id') FOR JSON PATH)
                                        ) AS parts,
                                        -- Dựng lại các cột A, B cho câu ghép nối
                                        JSON_QUERY(q.config_json, '$.columnA') AS columnA,
                                        JSON_QUERY(q.config_json, '$.columnB') AS columnB
                                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                                ) AS config
                            FROM OPENJSON(g.questions_json) WITH (
                                id VARCHAR(100) '$.id', type VARCHAR(50) '$.type', label NVARCHAR(100) '$.label',
                                ordinalNumber INT '$.ordinalNumber', points DECIMAL(5,2) '$.points',
                                gradingType VARCHAR(50) '$.gradingType', config_json NVARCHAR(MAX) '$.config' AS JSON
                            ) AS q
                            FOR JSON PATH
                        ) AS questions
                    FROM OPENJSON(@OriginalAssignmentConfig, '$.groups') WITH (
                        id VARCHAR(100) '$.id', title NVARCHAR(255) '$.title',
                        description NVARCHAR(MAX) '$.description', media_json NVARCHAR(MAX) '$.media' AS JSON,
                        questions_json NVARCHAR(MAX) '$.questions' AS JSON
                    ) AS g
                    FOR JSON PATH
                ) AS groups
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END;

    -- === Bảng 1: Thông tin Assignment (Đề bài) ===
    SELECT 
        atc.AssignmentID, asm.Title, asm.Instructions, 
		@ProcessedAssignmentConfig AS AssignmentConfig,
		--atc.AssignmentConfig,
        atc.DueDate, atc.MaxScore, mh.MonHocName,
        atc.AssignToClassID, asm.KhoiID, asm.MonHocID
    FROM dbo.tblEL_AssignToClass AS atc
    INNER JOIN dbo.tblEL_Assignments AS asm ON atc.ResourceID = asm.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' and asm.IsDeleted = 0
    INNER JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    INNER JOIN dbo.tblMonHoc mh ON asm.MonHocID = mh.MonHocID
    WHERE atc.AssignToClassID = @AssignToClassID and atc.IsDeleted = 0;
    
    -- === Bảng 2: Thông tin Submission (Bài làm) ===
    SELECT TOP 1
        SubmissionID, SubmissionContent, SubmissionStatus, 
        Score, TeacherComment, GradedDate, GradedByTeacherID
    FROM dbo.tblEL_Submissions 
    WHERE AssignToClassID = @AssignToClassID AND HocSinhID = @HocSinhID_INT;

END
