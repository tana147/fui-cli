CREATE PROCEDURE [dbo].[spAPI_TienDo_GiaoBai_DetailClassByAssignToClassID]
    @AssignToClassID BIGINT,
    @GiaoVienID VARCHAR(9)
AS
BEGIN
DECLARE @sys_UserID  VARCHAR(9) = @GiaoVienID
    DECLARE @LopHoacNhomID VARCHAR(10);
    DECLARE @AssignmentID_Check INT; 

    -- Bước 1: Lấy ID của Lớp/Nhóm và kiểm tra quyền 
    SELECT 
        @AssignmentID_Check = atc.ResourceID, 
        @LopHoacNhomID = mhl.LopNhomID
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID AND atc.CreateUser = @sys_UserID and atc.IsDeleted = 0;

    IF @AssignmentID_Check IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Không tìm thấy lần giao bài hoặc bạn không có quyền xem.', 16, 1);
        RETURN;
    END
    
    -- Bước 2: Dùng CTE để lấy danh sách học sinh từ cả Lớp và Nhóm
    ;WITH UnitStudents AS (
        -- Lấy học sinh từ LỚP, nếu ID khớp
        SELECT HocSinhID, SoDanhBo
        FROM dbo.tblHocSinhLop
        WHERE LopID = @LopHoacNhomID AND Enable = 1

        UNION -- Dùng UNION để loại bỏ trùng lặp nếu học sinh vừa ở trong lớp, vừa ở trong nhóm
        
        -- Lấy học sinh từ NHÓM, nếu ID khớp
        SELECT HocSinhID, SoDanhBo
        FROM dbo.tblHocSinhNhom
        WHERE NhomID = @LopHoacNhomID AND Enable = 1
    )

    -- Bước 3: Join danh sách học sinh đã chuẩn hóa với kết quả nộp bài
    SELECT 
        us.HocSinhID,
        us.SoDanhBo,
        hs.Ho + ' ' + hs.Ten as HoTen,
        s.SubmissionID,
        s.SubmissionTime,
        s.SubmissionStatus,
		s.SubmissionContent,
        s.Score,
        s.GradedDate,
		lcb.Reason,
        CASE
            WHEN s.SubmissionStatus = 4 THEN 'GRADED'      -- Đã chấm (Status 3 hoặc 4)
			WHEN s.SubmissionStatus = 3 THEN 'SAVE_DRAFT'      -- Đã chấm (Status 3 hoặc 4)
            WHEN s.SubmissionStatus = 2 THEN 'SUBMITTED'    -- Đã nộp
            WHEN s.SubmissionStatus = 1 THEN 'IN_PROGRESS'  -- Đang làm nháp
			WHEN s.SubmissionStatus = 0 AND (ISNULL(lcb.Reason, '' ) <> '') THEN 'RESUBMIT'   
            ELSE 'NOT_SUBMITTED'                             -- Chưa làm
        END AS Status,
        (
            SELECT ar.QuestionID_InJSON
            FROM dbo.tblEL_Analytics_QuestionResults ar
            WHERE ar.SubmissionID = s.SubmissionID AND ar.IsCorrect = 0
            FOR JSON PATH
        ) AS IncorrectQuestionsJSON
    FROM UnitStudents us
    JOIN dbo.tblHocSinh hs ON us.HocSinhID = hs.HocSinhID AND hs.TinhTrang = 0 -- Đang học
    LEFT JOIN dbo.tblEL_Submissions s ON us.HocSinhID = s.HocSinhID AND s.AssignToClassID = @AssignToClassID AND s.IsDeleted = 0
	LEFT JOIN dbo.tblEL_Log_ChamBai AS lcb ON lcb.Log_ChamBaiID = s.Log_ChamBaiID
    ORDER BY
        us.SoDanhBo, hs.Ten;

		--Lấy Thông tin bài assignmentToClass
		SELECT [AssignToClassID],
			[AssignmentConfig],
			[AssignmentConfig_NoAnswer],
			[StartDate],
			[DueDate],
			[MaxScore],
			[ResourceType],
			[ResourceID],
			[NienKhoa],
			[Status]
		FROM tblEL_AssignToClass where AssignToClassID = @AssignToClassID
END
