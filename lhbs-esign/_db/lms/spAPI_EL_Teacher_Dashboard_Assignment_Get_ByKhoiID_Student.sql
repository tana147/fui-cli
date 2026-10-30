
CREATE PROC [dbo].[spAPI_EL_Teacher_Dashboard_Assignment_Get_ByKhoiID_Student]
    @KhoiID          INT
  , @NienKhoa        INT
  , @HocKi           INT
  , @SYS_USERID      VARCHAR(9)
  , @SYS_SYSTEMRIGHT INT
AS
BEGIN
    SELECT @SYS_USERID      = SYS_USERID
         , @SYS_SYSTEMRIGHT = SYS_SystemRight
    FROM dbo.Table_GetUser_LMS(@SYS_USERID, @SYS_SYSTEMRIGHT);

    DECLARE @Table_MonHocID TABLE (MonHocID INT);

    INSERT INTO @Table_MonHocID
    SELECT DISTINCT MonHocID FROM dbo.tblEL_GiaoVienLop
    WHERE GiaoVienID = @SYS_USERID AND Enable = 1 AND HocKy = @HocKi
    UNION
    SELECT DISTINCT MonHocID FROM dbo.tblGiaoVienLop
    WHERE GiaoVienID = @SYS_USERID AND Enable = 1 AND HocKy = @HocKi
    UNION
    SELECT DISTINCT MonHocID FROM dbo.tblEL_Resoucre_TeacherPermissions
    WHERE GiaoVienID = @SYS_USERID;

    SELECT
        asm.AssignmentID
      , asm.Title
      , asm.Chuong
      , asm.MonHocID
      , mh.TenMonHoc_HienThi                                                             AS MonHocName
      , asm.KhoiID
      , dbo.fnGetTuanHoc_HienThi(th.Tuan, th.ThangHoc, th.NgayBatDau, th.NgayKetThuc)   AS Tuan_HienThi
      , CASE
            WHEN th.TuanTrongNam = DATEPART(WEEK, GETDATE()) THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END                                                                              AS Is_Tuan_Active
      , ats.DueDate

      -- Route chấm theo học sinh cần đúng khóa giao bài; AssignmentID chỉ là
      -- bài nguồn và không thể thay thế cho AssignToStudentID.
      , MAX(ats.AssignToStudentID)                                                 AS AssignToStudentID

      -- Đếm tổng học sinh DISTINCT được giao assignment này trong khối
      , COUNT(DISTINCT ats.HocSinhID)                                                    AS TotalStudents
      , SUM(CASE WHEN s.SubmissionStatus >= 2 THEN 1 ELSE 0 END)                         AS SubmittedCount
      , SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END)      AS PendingGradingCount
      , SUM(CASE WHEN s.SubmissionStatus = 4 THEN 1 ELSE 0 END)                         AS GradedCount
      , CASE
            WHEN SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END) > 0
             AND ats.DueDate > GETDATE() THEN 'PENDING_GRADING'
            WHEN ats.DueDate < GETDATE()  THEN 'OVERDUE'
            ELSE 'UPCOMING'
        END                                                                              AS Status
      , 'STUDENT'                                                                        AS AssignType
      , gv.HoGV + ' ' + gv.TenGV                                                        AS TenGiaoVien
      , CASE WHEN ats.CreateUser = @SYS_USERID THEN 1 ELSE 0 END                        AS IsMyContent
      , CAST(ISNULL(ats.IsHided, 0) AS INT)                                              AS IsHided

    FROM dbo.tblEL_AssignToStudent           ats

        INNER JOIN dbo.tblEL_Assignments     asm ON asm.AssignmentID    = ats.AssignmentID
                                                AND ISNULL(asm.IsDev,0) <> 1
                                                AND asm.IsDeleted        = 0
                                                AND asm.MonHocID IN (SELECT MonHocID FROM @Table_MonHocID)

        -- Chỉ dùng để FILTER học sinh thuộc khối @KhoiID, không group theo lớp
        INNER JOIN dbo.tblHocSinhLop         hsl ON hsl.HocSinhID = ats.HocSinhID
                                                AND hsl.Enable     = 1
        INNER JOIN dbo.tblLop                l   ON l.LopID    = hsl.LopID
                                                AND l.NienKhoa = @NienKhoa
                                                AND l.KhoiID   = @KhoiID
                                                AND l.Enable   = 1

        AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblHocSinh            hs  ON hs.HocSinhID = ats.HocSinhID
                                                AND hs.TinhTrang  = 0

        INNER JOIN dbo.tblMonHocLop          mhl ON mhl.MonHocLopID = ats.MonHocLopID
                                                AND mhl.Enable       = 1
                                                AND mhl.NienKhoa     = @NienKhoa

        INNER JOIN dbo.tblMonHoc             mh  ON mh.MonHocID = mhl.MonHocID
                                                AND mh.Enable    = 1

        INNER JOIN dbo.tblTuanHocTap         th  ON th.TuanHocID = asm.TuanHocID

        LEFT JOIN  dbo.tblGiaoVien           gv  ON gv.GiaoVienID = ats.CreateUser

        LEFT JOIN  dbo.tblEL_Submissions     s   ON s.AssignToStudentID = ats.AssignToStudentID
                                                AND s.IsDeleted          = 0

    WHERE ats.IsDeleted = 0
      AND ats.NienKhoa  = @NienKhoa
      AND (
          ats.CreateUser = @SYS_USERID
          OR @SYS_SYSTEMRIGHT IN (3, 5, 9)
          OR EXISTS (
              SELECT 1
              FROM tblEL_Resoucre_TeacherPermissions rtp
              INNER JOIN dbo.tblEL_AssignToClass atc
                  ON  atc.AssignToClassID = rtp.AssignToClassID
                  AND atc.AssignmentID    = ats.AssignmentID
                  AND atc.MonHocLopID     = ats.MonHocLopID
                  AND atc.IsDeleted       = 0
              WHERE rtp.Enable     = 1
                AND rtp.GiaoVienID = @SYS_USERID
          )
          OR EXISTS (
              -- Quyền SUBJECT mở quyền xem bài giao theo học sinh trong môn được cấp.
              SELECT 1
              FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
              WHERE rtp.Enable = 1
                AND rtp.GiaoVienID = @SYS_USERID
                AND rtp.PermissionScope = 'SUBJECT'
                AND rtp.MonHocID = asm.MonHocID
                AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa)
          )
      )

    GROUP BY
        asm.AssignmentID
      , asm.Title
      , asm.Chuong
      , asm.MonHocID
      , mh.TenMonHoc_HienThi
      , asm.KhoiID
      , CASE
            WHEN th.TuanTrongNam = DATEPART(WEEK, GETDATE()) THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END
      , dbo.fnGetTuanHoc_HienThi(th.Tuan, th.ThangHoc, th.NgayBatDau, th.NgayKetThuc)
      , ats.DueDate
      , gv.HoGV + ' ' + gv.TenGV
      , CASE WHEN ats.CreateUser = @SYS_USERID THEN 1 ELSE 0 END
      , ISNULL(ats.IsHided, 0);

END;
