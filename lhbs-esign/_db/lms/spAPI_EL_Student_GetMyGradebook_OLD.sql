-- FILE: spAPI_EL_Student_GetMyGradebook.sql
-- =================================================================================
-- Description:    Lấy sổ điểm cá nhân của học sinh cho một môn học cụ thể,
--                 dữ liệu đã được pivot để hiển thị dạng crosstab.
-- API Endpoint:   POST lms/el_student_getmygradebook
-- Ví dụ Body:     { "MonHocID": 1 }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetMyGradebook_OLD]
    @MonHocID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @HocSinhID INT = CAST(RIGHT(@sys_UserID,8) AS INT);
    DECLARE @LopID VARCHAR(10);
    DECLARE @SqlStatement NVARCHAR(MAX), @PivotColumns NVARCHAR(MAX);

    -- Xác định lớp của học sinh
    SELECT TOP 1 @LopID = hsl.LopID FROM dbo.tblHocSinhLop hsl
    INNER JOIN tblLop l ON l.LopID = hsl.LopID AND l.NienKhoa = hsl.NienKhoa AND l.NienKhoa = dbo.fn_GetNienKhoa_HienTai()
    WHERE HocSinhID = @HocSinhID AND hsl.Enable = 1;
    IF @LopID IS NULL BEGIN RETURN; END

    -- === BẢNG 1: TRẢ VỀ DANH SÁCH BÀI TẬP (để dựng Header) ===
    SELECT DISTINCT
        atc.AssignToClassID,
        a.Title AS AssignmentTitle,
        atc.MaxScore,
		atc.DueDate
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE mhl.LopNhomID = @LopID AND mhl.MonHocID = @MonHocID AND atc.IsDeleted = 0
    ORDER BY atc.DueDate;

    -- === BẢNG 2: DỮ LIỆU ĐIỂM SỐ CÁ NHÂN ===
    -- Lấy dữ liệu điểm của học sinh vào bảng tạm
    IF OBJECT_ID('tempdb..#StudentGrades') IS NOT NULL DROP TABLE #StudentGrades;
    SELECT
        atc.AssignToClassID,
        s.Score
    INTO #StudentGrades
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    LEFT JOIN dbo.tblEL_Submissions s ON atc.AssignToClassID = s.AssignToClassID AND s.HocSinhID = @HocSinhID
    WHERE mhl.LopNhomID = @LopID AND mhl.MonHocID = @MonHocID AND atc.IsDeleted = 0;
    
    -- Trả về một dòng duy nhất chứa điểm của học sinh
    SELECT @HocSinhID AS HocSinhID, (SELECT Ho+ ' '+ Ten AS HoTen FROM tblHocSinh WHERE HocSinhID = @HocSinhID) AS HoTen;
    -- Bảng này sẽ được xử lý tiếp ở frontend, nhưng SP vẫn trả về 2 bảng cho nhất quán
    SELECT * FROM #StudentGrades;

    DROP TABLE #StudentGrades;
END
