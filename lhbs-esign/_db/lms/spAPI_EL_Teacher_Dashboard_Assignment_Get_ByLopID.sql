CREATE PROC [dbo].[spAPI_EL_Teacher_Dashboard_Assignment_Get_ByLopID]
    @LopID           VARCHAR(20)
  , @NienKhoa        INT
  , @HocKi           INT
  , @SYS_USERID      VARCHAR(9)
  , @SYS_SYSTEMRIGHT INT
AS
BEGIN
    SELECT @SYS_USERID      = SYS_USERID
         , @SYS_SYSTEMRIGHT = SYS_SystemRight
    FROM
           dbo.Table_GetUser_LMS(@SYS_USERID, @SYS_SYSTEMRIGHT);

    DECLARE @Table_MonHocID TABLE
    (
        MonHocID INT
    );
    INSERT INTO @Table_MonHocID
    SELECT DISTINCT
           MonHocID
    FROM
           dbo.tblEL_GiaoVienLop
    WHERE
           GiaoVienID = @SYS_USERID
      AND  Enable      = 1
      AND  HocKy       = @HocKi
      AND  NienKhoa    = @NienKhoa
    UNION
    SELECT DISTINCT
           MonHocID
    FROM
           dbo.tblGiaoVienLop
    WHERE
           GiaoVienID = @SYS_USERID
      AND  Enable      = 1
      AND  HocKy       = @HocKi
      AND  NienKhoa    = @NienKhoa
    UNION
    SELECT DISTINCT
           MonHocID
    FROM
           dbo.tblEL_Resoucre_TeacherPermissions
    WHERE
           GiaoVienID = @SYS_USERID;
    SELECT asm.AssignmentID
         , atc.AssignToClassID
         , asm.Title
         , asm.Chuong
         , asm.MonHocID
         , mh.TenMonHoc_HienThi                                                          AS MonHocName
         , asm.KhoiID
         , mhl.LopNhomID                                                                 AS LopID
         , dbo.fnGetTuanHoc_HienThi(th.Tuan, th.ThangHoc, th.NgayBatDau, th.NgayKetThuc) AS Tuan_HienThi
         , CASE
                WHEN th.TuanTrongNam = DATEPART(WEEK, GETDATE()) THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
           END                                                                           AS Is_Tuan_Active
         , atc.DueDate
         , TotalHS.TotalStudents
         , SUM(CASE WHEN s.SubmissionStatus >= 2 THEN 1 ELSE 0 END)                      AS SubmittedCount
         , SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END)   AS PendingGradingCount
         , SUM(CASE WHEN s.SubmissionStatus = 4 THEN 1 ELSE 0 END)                       AS GradedCount
         , CASE
                WHEN SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END) > 0
                 AND atc.DueDate > GETDATE() THEN 'PENDING_GRADING'
                WHEN atc.DueDate < GETDATE() THEN 'OVERDUE'
                ELSE 'UPCOMING'
           END                                                                           AS Status
         , 'CLASS'                                                                       AS AssignType
         , gv.HoGV + ' ' + gv.TenGV                                                      AS TenGiaoVien -- Thêm tên GV
         , CASE WHEN atc.CreateUser = @SYS_USERID THEN 1 ELSE 0 END                      AS IsMyContent -- Đánh dấu
         , CAST(ISNULL(atc.IsHided, 0) AS INT)                                           AS IsHided
    FROM
           dbo.tblEL_AssignToClass          atc
           INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = atc.AssignmentID
                                               AND ISNULL(asm.IsDev, 0) <> 1
                                               AND asm.IsDeleted = 0
                                               AND asm.MonHocID IN
                                                   (
                                                       SELECT MonHocID
                                                       FROM
                                                              @Table_MonHocID
                                                   )
           INNER JOIN dbo.tblMonHocLop      mhl ON mhl.MonHocLopID = atc.MonHocLopID
                                               AND mhl.Enable = 1
                                               AND mhl.NienKhoa = @NienKhoa
                                               AND mhl.LopNhomID = @LopID
           INNER JOIN dbo.tblMonHoc         mh ON mh.MonHocID = mhl.MonHocID
                                              AND mh.Enable = 1
           INNER JOIN dbo.tblTuanHocTap     th ON th.TuanHocID = asm.TuanHocID
           LEFT JOIN dbo.tblGiaoVien        gv ON gv.GiaoVienID = atc.CreateUser
           LEFT JOIN dbo.tblEL_Submissions  s ON s.AssignToClassID = atc.AssignToClassID
                                             AND s.IsDeleted = 0
           OUTER APPLY
    (
        SELECT COUNT(*) AS TotalStudents
        FROM
               (
                   SELECT hsl.HocSinhID
                   FROM
                          dbo.tblHocSinhLop   hsl
                          JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
                                                AND hs.TinhTrang = 0
                   WHERE
                          hsl.LopID = mhl.LopNhomID
                     AND  (hsl.NienKhoa = @NienKhoa OR hsl.NienKhoa IS NULL)
                     AND  hsl.Enable = 1
                   UNION ALL
                   SELECT hsn.HocSinhID
                   FROM
                          dbo.tblHocSinhNhom  hsn
                          JOIN dbo.tblNhom    n  ON hsn.NhomID = n.NhomID
                                                AND n.NienKhoa = @NienKhoa
                          JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID
                                                AND hs.TinhTrang = 0
                   WHERE
                          hsn.NhomID = mhl.LopNhomID
                     AND  hsn.Enable  = 1
               ) x
    )                                       TotalHS
    WHERE
           atc.IsDeleted = 0
      AND
           (
               atc.CreateUser = @SYS_USERID
          OR   @SYS_SYSTEMRIGHT IN (3, 5, 9)
          OR   atc.AssignToClassID IN
               (
                   SELECT AssignToClassID
                   FROM
                          tblEL_Resoucre_TeacherPermissions
                   WHERE
                          Enable    = 1
                     AND  GiaoVienID = @SYS_USERID
               )
          OR EXISTS (
              -- Quyền SUBJECT mở quyền xem bài trong dashboard theo môn/niên khóa.
              SELECT 1
              FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
              WHERE rtp.Enable = 1
                AND rtp.GiaoVienID = @SYS_USERID
                AND rtp.PermissionScope = 'SUBJECT'
                AND rtp.MonHocID = ISNULL(asm.MonHocID, mhl.MonHocID)
                AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa)
          )
           )
    GROUP BY
           asm.AssignmentID
         , asm.Title
         , asm.Chuong
         , asm.MonHocID
         , CASE
                WHEN th.TuanTrongNam = DATEPART(WEEK, GETDATE()) THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
           END
         , mh.TenMonHoc_HienThi
         , asm.KhoiID
         , atc.AssignToClassID
         , mhl.LopNhomID
         , dbo.fnGetTuanHoc_HienThi(th.Tuan, th.ThangHoc, th.NgayBatDau, th.NgayKetThuc)
         , atc.DueDate
         , gv.HoGV + ' ' + gv.TenGV
         , CASE WHEN atc.CreateUser = @SYS_USERID THEN 1 ELSE 0 END -- Đánh dấu
         , TotalHS.TotalStudents
         , ISNULL(atc.IsHided, 0);

END;
