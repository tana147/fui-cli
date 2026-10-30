CREATE PROC [dbo].[spAPI_BaoCaoLMS_DiemTrungVi_By_LopID] 
    @LopID NVARCHAR(100), 
	@MonHocID INT,
	@NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
    BEGIN
        RAISERROR(N'NienKhoa là bắt buộc khi tra điểm theo LopID.', 16, 1);
        RETURN;
    END;

    DECLARE @IsNhom BIT = 1;
    IF TRY_CONVERT(INT, @LopID) IS NOT NULL
        SET @IsNhom = 0;

    -------------------------------------------------------------------------
    -- ================ TRƯỜNG HỢP NHÓM ====================================
    -------------------------------------------------------------------------
    IF (@IsNhom = 1)
    BEGIN
        SELECT 
            x.HocSinhID,
            x.HoTen,
            x.AssignmentID,
            x.Title,
            x.MedianScore,
            x.MedianMaxScore,
            x.SL_Lam,
            ROUND((x.MedianScore / NULLIF(x.MedianMaxScore,0)) * 100, 2) AS PercentScore,
            x.SoTT
        FROM (
            SELECT 
                s.HocSinhID,
                hs.Ho + ' ' + hs.Ten AS HoTen,
                asm.AssignmentID,
                asm.Title,
				hsn.SoTT,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY s.Score)
                    OVER (PARTITION BY s.HocSinhID, asm.AssignmentID) AS MedianScore,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY atc.MaxScore)
                    OVER (PARTITION BY s.HocSinhID, asm.AssignmentID) AS MedianMaxScore,
                COUNT(*) OVER (PARTITION BY s.HocSinhID, asm.AssignmentID) AS SL_Lam
            FROM dbo.tblEL_Submissions s
                INNER JOIN dbo.tblEL_AssignToClass atc 
                    ON atc.AssignToClassID = s.AssignToClassID AND atc.IsDeleted = 0
                    AND atc.NienKhoa = @NienKhoa
                INNER JOIN dbo.tblEL_Assignments asm
                    ON asm.AssignmentID = atc.AssignmentID AND asm.IsDeleted = 0 AND asm.MonHocID = @MonHocID
                INNER JOIN dbo.tblHocSinhNhom hsn
                    ON hsn.HocSinhID = s.HocSinhID AND hsn.Enable = 1
                INNER JOIN dbo.tblNhom n
                    ON n.NhomID = hsn.NhomID AND n.Enable = 1 AND n.NhomID = @LopID AND n.MonHocID = @MonHocID
                    AND n.NienKhoa = @NienKhoa
                INNER JOIN dbo.tblHocSinh hs 
                    ON hs.HocSinhID = s.HocSinhID AND hs.TinhTrang = 0
            WHERE s.IsDeleted = 0
              AND s.SubmissionStatus = 4
        ) AS x
        GROUP BY 
            x.HocSinhID, x.HoTen,
            x.AssignmentID, x.Title,
				x.SoTT,
            x.MedianScore, x.MedianMaxScore, x.SL_Lam;
    END

    -------------------------------------------------------------------------
    -- ================ TRƯỜNG HỢP LỚP =====================================
    -------------------------------------------------------------------------
    ELSE
    BEGIN
        SELECT 
            x.HocSinhID,
            x.HoTen,
            x.AssignmentID,
            x.Title,
            x.MedianScore,
            x.MedianMaxScore,
            x.SL_Lam,
            ROUND((x.MedianScore / NULLIF(x.MedianMaxScore,0)) * 100, 2) AS PercentScore,
            x.SoDanhBo
        FROM (
            SELECT 
                s.HocSinhID,
                hs.Ho + ' ' + hs.Ten AS HoTen,
                hsl.SoDanhBo,
                asm.AssignmentID,
                asm.Title,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY s.Score)
                    OVER (PARTITION BY s.HocSinhID, asm.AssignmentID) AS MedianScore,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY atc.MaxScore)
                    OVER (PARTITION BY s.HocSinhID, asm.AssignmentID) AS MedianMaxScore,
                COUNT(*) OVER (PARTITION BY s.HocSinhID, asm.AssignmentID) AS SL_Lam
            FROM dbo.tblEL_Submissions s
                INNER JOIN dbo.tblEL_AssignToClass atc 
                    ON atc.AssignToClassID = s.AssignToClassID AND atc.IsDeleted = 0
                    AND atc.NienKhoa = @NienKhoa
                INNER JOIN dbo.tblEL_Assignments asm
                    ON asm.AssignmentID = atc.AssignmentID AND asm.IsDeleted = 0 AND asm.MonHocID = @MonHocID
                INNER JOIN dbo.tblHocSinhLop hsl
                    ON hsl.HocSinhID = s.HocSinhID AND hsl.Enable = 1 AND hsl.LopID = @LopID AND hsl.NienKhoa = @NienKhoa
                INNER JOIN dbo.tblLop l
                    ON l.LopID = hsl.LopID AND l.NienKhoa = hsl.NienKhoa
                    AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
                INNER JOIN dbo.tblHocSinh hs 
                    ON hs.HocSinhID = s.HocSinhID AND hs.TinhTrang = 0
            WHERE s.IsDeleted = 0
              AND s.SubmissionStatus = 4
        ) AS x
        GROUP BY 
            x.SoDanhBo,
            x.HocSinhID, x.HoTen,
            x.AssignmentID, x.Title,
            x.MedianScore, x.MedianMaxScore, x.SL_Lam;
    END
END;
