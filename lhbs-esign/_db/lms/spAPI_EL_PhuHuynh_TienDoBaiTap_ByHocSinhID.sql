-- [dbo].[spAPI_EL_PhuHuynh_TienDoBaiTap_ByHocSinhID] 23300048
CREATE PROC [dbo].[spAPI_EL_PhuHuynh_TienDoBaiTap_ByHocSinhID]
  @HocSinhID INT,
  @NienKhoa INT
AS
BEGIN
    ;WITH SubmissionHistory AS
    (
        SELECT
            asm.AssignmentID,
            atc.MaxScore,
            asm.Title,
            dbo.fnGetTuanHoc_HienThi(th.Tuan, th.ThangHoc, th.NgayBatDau, th.NgayKetThuc) AS TuanHienThi,
            mh.TenMonHoc_HienThi,
            s.SubmissionID,
            s.Score,
            s.SubmissionTime,
            s.SubmissionStatus,
            s.LanNop,
            COUNT(*) OVER (PARTITION BY asm.AssignmentID) AS SoLanNop,
            ROW_NUMBER() OVER
            (
                PARTITION BY asm.AssignmentID
                ORDER BY ISNULL(s.LanNop, 0) DESC, s.SubmissionTime DESC, s.SubmissionID DESC
            ) AS rn,
            mh.Icon,
            mh.Color
        FROM dbo.tblEL_Submissions s
            INNER JOIN dbo.tblEL_AssignToClass atc
                ON atc.AssignToClassID = s.AssignToClassID
                AND atc.IsDeleted = 0
            INNER JOIN dbo.tblEL_Assignments asm
                ON asm.AssignmentID = atc.AssignmentID
                AND asm.IsDeleted = 0
                AND ISNULL(asm.IsDev, 0) <> 1
            INNER JOIN dbo.tblTuanHocTap th
                ON th.TuanHocID = asm.TuanHocID
            INNER JOIN dbo.tblMonHoc mh
                ON mh.MonHocID = asm.MonHocID
                AND mh.Enable = 1
        WHERE s.HocSinhID = @HocSinhID
          AND asm.NienKhoa = @NienKhoa
          AND s.IsDeleted = 0
    )
    SELECT
        AssignmentID,
        MaxScore,
        Title,
        TuanHienThi,
        TenMonHoc_HienThi,
        SubmissionID,
        Score,
        SubmissionTime,
        SubmissionStatus,
        LanNop,
        SoLanNop,
        CASE WHEN rn = 1 THEN 1 ELSE 0 END AS IsLatest,
        Icon,
        Color
    FROM SubmissionHistory
    ORDER BY AssignmentID, ISNULL(LanNop, 0), SubmissionID;
END
