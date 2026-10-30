CREATE PROC [dbo].[spAPI_BaoCaoLMS_Dashboard_By_MonHocID_KhoiID]
    @NienKhoa INT,
    @MonHocID INT,
    @KhoiID INT
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------
    -- 1️⃣ Bài tập giao theo lớp
    ------------------------------
    WITH SubmissionStats AS (
        SELECT
            l.TenLop,
            l.LopID,
            asm.AssignmentID,
            asm.Title,
            atc.MaxScore,
            s.Score,
			s.AssignToClassID,
			s.AssignToStudentID
        FROM dbo.tblEL_AssignToClass atc
        INNER JOIN dbo.tblEL_Assignments asm 
            ON asm.AssignmentID = atc.AssignmentID AND asm.IsDeleted = 0
        INNER JOIN dbo.tblMonHocLop mhl 
            ON mhl.MonHocLopID = atc.MonHocLopID 
               AND mhl.Enable = 1 
               AND mhl.NienKhoa = @NienKhoa 
               AND mhl.MonHocID = @MonHocID
        INNER JOIN dbo.tblLop l 
            ON mhl.LopNhomID = l.LopID 
               AND l.NienKhoa = @NienKhoa 
               AND l.KhoiID = @KhoiID
        LEFT JOIN dbo.tblEL_Submissions s 
            ON s.AssignToClassID = atc.AssignToClassID 
               AND s.IsDeleted = 0
        WHERE atc.IsDeleted = 0
    ),
    Ranked AS (
        SELECT *,
            ROW_NUMBER() OVER(PARTITION BY TenLop, AssignmentID ORDER BY Score) AS rn_asc,
            ROW_NUMBER() OVER(PARTITION BY TenLop, AssignmentID ORDER BY Score DESC) AS rn_desc
        FROM SubmissionStats
    ),
    HocSinhTheoLop AS (
        SELECT LopID, COUNT(*) AS SoLuongHocSinh
        FROM dbo.tblHocSinhLop
        WHERE NienKhoa = @NienKhoa AND Enable = 1
        GROUP BY LopID
    )
    SELECT
        s.TenLop,
        s.LopID,
        s.AssignmentID,
		s.AssignToClassID,
		s.AssignToStudentID,
        s.Title,
        s.MaxScore,
        hsl.SoLuongHocSinh,
        COUNT(s.Score) AS SoHocSinhDaNop,
        SUM(CASE WHEN s.Score IS NOT NULL THEN 1 ELSE 0 END) AS SoHocSinhCoDiem,
        ROUND(AVG(s.Score * 1.0), 2) AS DiemTB,
        MAX(CASE WHEN rn_asc = rn_desc OR rn_asc + 1 = rn_desc OR rn_asc = rn_desc + 1 THEN Score END) AS DiemTrungVi,
        CASE WHEN SUM(CASE WHEN s.Score IS NULL THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END AS ConHocSinhChuaNop,
        N'Lớp' AS LoaiGiaoBaiTap
    FROM Ranked s
    LEFT JOIN HocSinhTheoLop hsl ON hsl.LopID = s.LopID
    GROUP BY s.TenLop, s.LopID, s.AssignmentID, s.Title, s.MaxScore, hsl.SoLuongHocSinh,	s.AssignToClassID,
		s.AssignToStudentID

    UNION ALL

    ------------------------------
    -- 2️⃣ Bài tập giao theo học sinh
    ------------------------------
    SELECT
        s2.TenLop,
        s2.LopID,
        s2.AssignmentID,
		s2.AssignToClassID,
		s2.AssignToStudentID,
        s2.Title,
        s2.MaxScore,
        hsl2.SoLuongHocSinh, 
        COUNT(s2.Score) AS SoHocSinhDaNop,
        SUM(CASE WHEN s2.Score IS NOT NULL THEN 1 ELSE 0 END) AS SoHocSinhCoDiem,
        ROUND(AVG(s2.Score * 1.0), 2) AS DiemTB,
        MAX(CASE WHEN rn_asc = rn_desc OR rn_asc + 1 = rn_desc OR rn_asc = rn_desc + 1 THEN Score END) AS DiemTrungVi,
        CASE WHEN SUM(CASE WHEN s2.Score IS NULL THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END AS ConHocSinhChuaNop,
        N'Học sinh' AS LoaiGiaoBaiTap
    FROM (
        SELECT *,
            ROW_NUMBER() OVER(PARTITION BY TenLop, AssignmentID ORDER BY Score) AS rn_asc,
            ROW_NUMBER() OVER(PARTITION BY TenLop, AssignmentID ORDER BY Score DESC) AS rn_desc
        FROM (
            SELECT
				
                l.TenLop,
                l.LopID,
                asm.AssignmentID,
                asm.Title,
                ats.MaxScore,
                s.Score,
					s.AssignToClassID,
		s.AssignToStudentID
            FROM dbo.tblEL_AssignToStudent ats
            INNER JOIN dbo.tblEL_Assignments asm 
                ON asm.AssignmentID = ats.AssignmentID AND asm.IsDeleted = 0
            INNER JOIN dbo.tblMonHocLop mhl 
                ON mhl.MonHocLopID = ats.MonHocLopID 
                   AND mhl.Enable = 1 
                   AND mhl.NienKhoa = @NienKhoa 
                   AND mhl.MonHocID = @MonHocID
            INNER JOIN dbo.tblLop l 
                ON mhl.LopNhomID = l.LopID 
                   AND l.NienKhoa = @NienKhoa 
                   AND l.KhoiID = @KhoiID
            LEFT JOIN dbo.tblEL_Submissions s 
                ON s.AssignToStudentID = ats.AssignToStudentID 
                   AND s.IsDeleted = 0
            WHERE ats.IsDeleted = 0
        ) AS t
    ) AS s2
    LEFT JOIN (
        SELECT LopID, COUNT(*) AS SoLuongHocSinh
        FROM dbo.tblHocSinhLop
        WHERE NienKhoa = @NienKhoa AND Enable = 1
        GROUP BY LopID
    ) hsl2 ON hsl2.LopID = s2.LopID
    GROUP BY s2.TenLop, s2.LopID, s2.AssignmentID, s2.Title, s2.MaxScore, hsl2.SoLuongHocSinh, 	s2.AssignToClassID,
		s2.AssignToStudentID

    ORDER BY TenLop, AssignmentID;
 
	--Lấy giáo viên theo lớp hiển thị bài tập
	SELECT l.LopID
		 , l.TenLop
		 , pc.GiaoVienID
		 , (
			SELECT COUNT(*) FROM dbo.tblEL_Assignments asm
			WHERE asm.IsDeleted = 0 
				AND asm.CreateUser = pc.GiaoVienID
				AND asm.KhoiID = @KhoiID
				AND asm.NienKhoa = @NienKhoa
		 ) AS SoLuongBT_Tao
		 , (
			SELECT COUNT( DISTINCT atc.AssignmentID) 
			FROM dbo.tblEL_AssignToClass atc
				INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = atc.AssignmentID AND asm.KhoiID = @KhoiID AND asm.NienKhoa = @NienKhoa
			WHERE atc.IsDeleted = 0 AND atc.CreateUser = pc.GiaoVienID
		 ) AS SoLuongBT_Giao
		 , (
			SELECT COUNT( DISTINCT atc.AssignmentID) FROM dbo.tblEL_AssignToClass atc
				INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = atc.AssignmentID AND asm.KhoiID = @KhoiID AND asm.NienKhoa = @NienKhoa
				INNER JOIN dbo.tblEL_Submissions s ON s.AssignToClassID = atc.AssignToClassID AND s.IsDeleted = 0 AND s.SubmissionStatus = 4
			WHERE atc.IsDeleted = 0 AND atc.CreateUser = pc.GiaoVienID
		 ) AS  SoLuongBT_HoanThanh
	FROM
		   dbo.tblLop                                                         AS l
		   CROSS APPLY dbo.fn_GetGiaoVienTheoMonLop(@MonHocID, l.LopID, @NienKhoa, '', 9) AS pc
	WHERE
		   l.NienKhoa = @NienKhoa
	  AND  l.Enable    = 1
	  AND  l.KhoiID    = @KhoiID
	ORDER BY l.TenLop

END
