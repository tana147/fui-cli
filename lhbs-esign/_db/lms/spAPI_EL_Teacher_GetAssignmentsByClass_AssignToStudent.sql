CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentsByClass_AssignToStudent]
    @sys_UserID      VARCHAR(9)
  , @HocKi           INT
  , @sys_SystemRight INT
  , @KhoiID          INT
  , @MonHocID        INT
  , @NienKhoa        INT
AS
BEGIN
    -- Lấy thông tin user và quyền hệ thống
    SELECT @sys_UserID      = SYS_USERID
         , @sys_SystemRight = SYS_SystemRight
    FROM
           Table_GetUser_LMS(@sys_UserID, @sys_SystemRight);

    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
        SET @NienKhoa = dbo.fn_GetNienKhoa_HienTai();

    -- CTE: Các môn học của giáo viên dạy trong khối này
    DECLARE @MonHocLopIDs TABLE
    (
        MonHocLopID INT
    );
    INSERT INTO @MonHocLopIDs
    (
        MonHocLopID
    )
    SELECT MonHocLopID
    FROM
           tblGiaoVienLop          gvl
           INNER JOIN tblMonHocLop mhl ON mhl.MonHocID  = gvl.MonHocID
                                      AND mhl.LopNhomID = gvl.LopID
                                      AND mhl.NienKhoa  = @NienKhoa
                                      AND mhl.Enable    = 1
                                      AND gvl.NienKhoa  = @NienKhoa
           INNER JOIN tblLop       l   ON l.LopID       = gvl.LopID
                                    AND l.KhoiID        = @KhoiID
                                    AND l.NienKhoa      = @NienKhoa
                                    AND l.Enable        = 1
    WHERE
           GiaoVienID  = @sys_UserID
      AND  gvl.Enable   = 1
      AND  gvl.HocKy    = @HocKi
      AND  gvl.MonHocID = @MonHocID
    UNION
    SELECT MonHocLopID
    FROM
           tblEL_GiaoVienLop       gvl
           INNER JOIN tblMonHocLop mhl ON mhl.MonHocID  = gvl.MonHocID
                                      AND mhl.LopNhomID = gvl.LopID
                                      AND mhl.NienKhoa  = @NienKhoa
                                      AND mhl.Enable    = 1
                                      AND gvl.NienKhoa  = @NienKhoa
           INNER JOIN tblNhom      n   ON n.NhomID      = gvl.LopID
                                    AND n.KhoiID        = @KhoiID
                                    AND n.MonHocID      = @MonHocID
                                    AND n.NienKhoa      = @NienKhoa
                                    AND n.Enable        = 1
    WHERE
           GiaoVienID  = @sys_UserID
      AND  gvl.Enable   = 1
      AND  gvl.HocKy    = @HocKi
      AND  gvl.MonHocID = @MonHocID;

    -- Lấy danh sách các lần giao bài cho học sinh trong tất cả lớp của khối
    ;
    WITH CTE AS
    (
        -- Lấy từ tblLop (lớp thường)
        SELECT ats.AssignToStudentID
             , a.Title AS AssignmentTitle
             , ats.AssignmentConfig
             , ats.LimitAssigned
             , ats.CreateTime
             , ats.AssignmentID
             , l.TenLop
             , ats.Is_Full_Quiz
        FROM
               dbo.tblEL_AssignToStudent  ats
               JOIN dbo.tblMonHocLop      mhl ON ats.MonHocLopID = mhl.MonHocLopID
                                             AND mhl.NienKhoa   = @NienKhoa
                                             AND mhl.Enable     = 1
               JOIN dbo.tblLop            l   ON l.LopID        = mhl.LopNhomID
                                             AND l.NienKhoa     = @NienKhoa
                                             AND l.Enable       = 1
               JOIN dbo.tblEL_Assignments a   ON ats.ResourceID = a.AssignmentID
        WHERE
               l.KhoiID        = @KhoiID
          AND  ISNULL(a.MonHocID, mhl.MonHocID) = @MonHocID
          AND  ats.ResourceType = 'ASSIGNMENT'
          AND  ats.IsDeleted    = 0
          AND  a.IsDeleted      = 0
          -- Điều kiện bảo mật
          AND
               (
                   ats.CreateUser   = @sys_UserID
              OR   @sys_SystemRight IN (3, 5, 9)
              OR   ats.MonHocLopID IN
                   (
                       SELECT MonHocLopID
                       FROM
                              @MonHocLopIDs
                   )
              OR   ats.AssignToStudentID IN
                   (
                       SELECT AssignToStudentID
                       FROM
                              tblEL_Resoucre_TeacherPermissions
                       WHERE
                              Enable    = 1
                         AND  GiaoVienID = @sys_UserID
                   )
              OR   EXISTS (
                       -- Quyền SUBJECT cho phép xem bài giao theo học sinh của môn đó.
                       SELECT 1
                       FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                       WHERE rtp.Enable = 1
                         AND rtp.GiaoVienID = @sys_UserID
                         AND rtp.PermissionScope = 'SUBJECT'
                         AND rtp.MonHocID = ISNULL(a.MonHocID, mhl.MonHocID)
                         AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa)
                   )
               )
        UNION

        -- Lấy từ tblNhom (nhóm)
        SELECT ats.AssignToStudentID
             , a.Title   AS AssignmentTitle
             , ats.AssignmentConfig
             , ats.LimitAssigned
             , ats.CreateTime
             , ats.AssignmentID
             , n.TenNhom AS TenLop
			 , ats.Is_Full_Quiz
        FROM
               dbo.tblEL_AssignToStudent  ats
               JOIN dbo.tblMonHocLop      mhl ON ats.MonHocLopID = mhl.MonHocLopID
                                             AND mhl.NienKhoa   = @NienKhoa
                                             AND mhl.Enable     = 1
               JOIN dbo.tblNhom           n   ON n.NhomID       = mhl.LopNhomID
                                             AND n.NienKhoa     = @NienKhoa
                                             AND n.Enable       = 1
               JOIN dbo.tblEL_Assignments a   ON ats.ResourceID = a.AssignmentID
        WHERE
               n.KhoiID        = @KhoiID
          AND  ISNULL(a.MonHocID, ISNULL(n.MonHocID, mhl.MonHocID)) = @MonHocID
          AND  ats.ResourceType = 'ASSIGNMENT'
          AND  ats.IsDeleted    = 0
          AND  a.IsDeleted      = 0
          -- Điều kiện bảo mật
          AND
               (
                   ats.CreateUser   = @sys_UserID
              OR   @sys_SystemRight IN (3, 5, 9)
              OR   ats.MonHocLopID IN
                   (
                       SELECT MonHocLopID
                       FROM
                              @MonHocLopIDs
                   )
              OR   ats.AssignToStudentID IN
                   (
                       SELECT AssignToStudentID
                       FROM
                              tblEL_Resoucre_TeacherPermissions
                       WHERE
                              Enable    = 1
                         AND  GiaoVienID = @sys_UserID
                   )
              OR   EXISTS (
                       -- Giữ cùng chính sách quyền SUBJECT cho nhánh nhóm.
                       SELECT 1
                       FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                       WHERE rtp.Enable = 1
                         AND rtp.GiaoVienID = @sys_UserID
                         AND rtp.PermissionScope = 'SUBJECT'
                         AND rtp.MonHocID = ISNULL(a.MonHocID, ISNULL(n.MonHocID, mhl.MonHocID))
                         AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa)
                   )
               )
    )

    -- GROUP BY để loại bỏ duplicate
    SELECT MAX(AssignToStudentID)   AS AssignToStudentID -- Lấy 1 AssignToStudentID bất kỳ
         , AssignmentID
         , MAX(AssignmentTitle)     AS AssignmentTitle
         , MAX(AssignmentConfig)    AS AssignmentConfig
         , MAX(LimitAssigned)       AS LimitAssigned
         , MAX(CreateTime)          AS CreateTime
         , STRING_AGG(TenLop, ', ') AS TenLop            -- Gộp tất cả tên lớp thành chuỗi
		   , CAST(MAX(CAST(Is_Full_Quiz AS INT)) AS BIT) AS Is_Full_Quiz
         , STRING_AGG(CAST(AssignToStudentID AS VARCHAR(20)), ',') AS AllAssignToStudentIDs
    FROM
           CTE
    GROUP BY
           AssignmentID
    ORDER BY
           MAX(CreateTime) DESC;
END;
