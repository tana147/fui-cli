CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetSubmissionStatusByStudent_old]
    @AssignToClassID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
   IF @sys_UserID = 'NA0000022'
	BEGIN
		SET @sys_UserID = 'NV0000907'
	END
    DECLARE @AssignmentID INT, @LopID VARCHAR(10);

    -- Lấy thông tin từ lần giao bài và kiểm tra quyền
    SELECT 
        @AssignmentID = atc.AssignmentID,
        @LopID = mhl.LopNhomID
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID AND atc.CreateUser = @sys_UserID;

    IF @AssignmentID IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Không tìm thấy lần giao bài hoặc bạn không có quyền xem.', 16, 1);
        RETURN;
    END
    
    -- === Bảng kết quả: Danh sách học sinh và trạng thái nộp bài ===
    SELECT 
        hs.HocSinhID,
        hsl.SoDanhBo,
        hs.Ho + ' ' + hs.Ten as HoTen,
        s.SubmissionID,
        s.SubmissionTime,
        s.SubmissionStatus,
        s.Score,
        s.GradedDate,
        -- Tính toán trạng thái chi tiết
        CASE
            WHEN s.SubmissionStatus = 1 THEN 'NOT_SUBMITTED'
			WHEN s.SubmissionStatus = 2 THEN 'SUBMITTED'
            WHEN s.SubmissionStatus = 3 THEN 'SAVE_DRAFT'
			WHEN s.SubmissionStatus = 4 THEN 'GRADED'
            ELSE 'NOT_SUBMITTED'
        END AS Status,
        (
            SELECT ar.QuestionID_InJSON
            FROM dbo.tblEL_Analytics_QuestionResults ar
            WHERE ar.SubmissionID = s.SubmissionID AND ar.IsCorrect = 0
            FOR JSON PATH
        ) AS IncorrectQuestionsJSON
    FROM 
        dbo.tblHocSinhLop hsl
    JOIN 
        dbo.tblHocSinh hs ON hsl.HocSinhID = hs.HocSinhID AND hs.TinhTrang = 0 -- Đang học
    LEFT JOIN
        dbo.tblEL_Submissions s ON hsl.HocSinhID = s.HocSinhID AND s.AssignToClassID = @AssignToClassID AND s.IsDeleted = 0
    WHERE 
        hsl.LopID = @LopID AND hsl.Enable = 1
    ORDER BY
        hsl.SoDanhBo, hs.Ten;
END
