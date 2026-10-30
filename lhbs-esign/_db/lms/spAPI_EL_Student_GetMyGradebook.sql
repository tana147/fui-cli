CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetMyGradebook]
    @MonHocID INT,
	@HocSinhID INT,
	@NienKhoa INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- =================================================================================
    -- == BƯỚC CHUẨN BỊ: Lấy tất cả LỚP và NHÓM của học sinh vào bảng tạm           ==
    -- =================================================================================
    DECLARE @MyUnits TABLE (UnitID VARCHAR(100));
    INSERT INTO @MyUnits (UnitID)
    SELECT hsl.LopID FROM dbo.tblHocSinhLop hsl 
    JOIN dbo.tblLop l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = @HocSinhID AND hsl.Enable = 1 AND hsl.NienKhoa = @NienKhoa
    UNION
    SELECT hsn.NhomID FROM dbo.tblHocSinhNhom hsn 
    JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    WHERE hsn.HocSinhID = @HocSinhID AND hsn.Enable = 1;

    -- Kiểm tra nếu học sinh không thuộc lớp/nhóm nào thì trả về rỗng
    IF NOT EXISTS (SELECT 1 FROM @MyUnits)
    BEGIN
        SELECT TOP 0 * FROM dbo.tblEL_AssignToClass; -- Bảng 1 rỗng
        SELECT @HocSinhID AS HocSinhID, (SELECT Ho + ' ' + Ten FROM tblHocSinh WHERE HocSinhID = @HocSinhID) AS HoTen; -- Bảng 2 thông tin HS
        SELECT TOP 0 * FROM dbo.tblEL_Submissions; -- Bảng 3 rỗng
        RETURN;
    END

    -- === BẢNG 1: TRẢ VỀ DANH SÁCH BÀI TẬP (Header)===
    SELECT DISTINCT
        atc.AssignToClassID,
        a.Title AS AssignmentTitle,
        atc.MaxScore,
		atc.DueDate
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT'
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
                              AND mhl.NienKhoa = @NienKhoa
    WHERE mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits) 
      AND mhl.MonHocID = @MonHocID 
      AND atc.IsDeleted = 0
    ORDER BY atc.DueDate;

    -- === BẢNG 2: Thông tin Học sinh ===
    SELECT @HocSinhID AS HocSinhID, (SELECT Ho+ ' '+ Ten AS HoTen FROM tblHocSinh WHERE HocSinhID = @HocSinhID) AS HoTen;

    -- === BẢNG 3: DỮ LIỆU ĐIỂM SỐ CÁ NHÂN  ===
    -- AttemptMaxScore NULL cho flow thường/legacy; chỉ RANDOM pool có mẫu số riêng.
    -- Bảng điểm chọn lượt tốt nhất theo tỷ lệ Score / AttemptMaxScore.
    ;WITH RankedSubmissions AS (
        SELECT
            s.AssignToClassID,
            s.Score,
            COALESCE(s.AttemptMaxScore, atc.MaxScore) AS AttemptMaxScore,
            s.LanNop,
            ROW_NUMBER() OVER (
                PARTITION BY s.AssignToClassID
                ORDER BY
                    CASE WHEN s.SubmissionStatus = 4 THEN 0 ELSE 1 END,
                    CASE WHEN COALESCE(s.AttemptMaxScore, atc.MaxScore, 0) > 0
                         THEN ISNULL(s.Score, 0) / COALESCE(s.AttemptMaxScore, atc.MaxScore)
                         ELSE -1 END DESC,
                    ISNULL(s.LanNop, 1) DESC,
                    s.SubmissionID DESC
            ) AS rn
        FROM dbo.tblEL_Submissions s
        JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID AND atc.IsDeleted = 0
        JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
                                  AND mhl.NienKhoa = @NienKhoa
        WHERE s.HocSinhID = @HocSinhID
          AND s.IsDeleted = 0
          AND mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)
          AND mhl.MonHocID = @MonHocID
    )
    SELECT
        AssignToClassID,
        Score,
        AttemptMaxScore,
        LanNop
    FROM RankedSubmissions
    WHERE rn = 1;
END;
