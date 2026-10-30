-- Cập nhật spAPI_EL_Teacher_GetMyContentLibrary để trả thêm thông tin chương trình học đã ánh xạ
CREATE   PROCEDURE [dbo].[spAPI_EL_Teacher_GetMyContentLibrary]
    @sys_UserID      VARCHAR(9),
    @KhoiID          INT,
    @MonHocID        INT,
    @SearchTerm      NVARCHAR(255),
    @NienKhoa        VARCHAR(10),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    SET @sys_UserID = [dbo].[fn_GetUser_LMS](@sys_UserID);

    -- Luôn lấy quyền active hiện tại của user làm nguồn chuẩn.
    -- Không để quyền truyền từ request cũ làm giáo viên thường bị xem nhầm như admin.
    SELECT TOP 1 @sys_SystemRight = SYS_SYSTEMRIGHT
    FROM dbo.tblEL_User_Assign
    WHERE SYS_USERID = @sys_UserID
      AND IsActive = 1;

    ;WITH AllContent AS
    (
        SELECT a.AssignmentID                     AS ResourceID
             , 'ASSIGNMENT'                       AS ResourceType
             , a.Title
             , a.Instructions
             , a.KhoiID
             , a.MonHocID
             , a.CreateUser                         AS NguoiUploadID
             , a.TuanHocID
             , a.Chuong
             , 3                                  AS Status_Internal
             , ISNULL(a.UpdateTime, a.CreateTime) AS LastUpdateTime
             , a.IsPublic
        FROM dbo.tblEL_Assignments a
        WHERE (
                  @sys_SystemRight IN (3, 9)
               OR a.CreateUser = @sys_UserID
               OR EXISTS (
                       SELECT 1
                       FROM dbo.tblEL_AssignToClass atc
                       INNER JOIN dbo.tblEL_Resoucre_TeacherPermissions rtp
                           ON rtp.AssignToClassID = atc.AssignToClassID
                          AND rtp.GiaoVienID = @sys_UserID
                          AND rtp.Enable = 1
                       WHERE atc.ResourceType = 'ASSIGNMENT'
                         AND atc.ResourceID = a.AssignmentID
                         AND atc.IsDeleted = 0
                    )
               OR EXISTS (
                       SELECT 1
                       FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                       WHERE rtp.GiaoVienID = @sys_UserID
                         AND rtp.Enable = 1
                         AND rtp.PermissionScope = 'SUBJECT'
                         AND rtp.MonHocID = a.MonHocID
                         AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = a.NienKhoa)
                    )
               )
          AND a.IsDeleted = 0
          AND (@NienKhoa IS NULL OR a.NienKhoa = TRY_CONVERT(INT, @NienKhoa))

        UNION ALL

        SELECT l.LessonID
             , 'LESSON'
             , l.Title
             , l.[Description]
             , l.KhoiID
             , l.MonHocID
             , l.CreateUser                         AS NguoiUploadID
             , l.TuanHocID
             , l.Chuong
             , l.Status
             , ISNULL(l.UpdateTime, l.CreateTime)
             , l.IsPublic
        FROM dbo.tblEL_Lessons l
        WHERE (
                  @sys_SystemRight IN (3, 9)
               OR l.CreateUser = @sys_UserID
               OR EXISTS (
                       SELECT 1
                       FROM dbo.tblEL_AssignToClass atc
                       INNER JOIN dbo.tblEL_Resoucre_TeacherPermissions rtp
                           ON rtp.AssignToClassID = atc.AssignToClassID
                          AND rtp.GiaoVienID = @sys_UserID
                          AND rtp.Enable = 1
                       WHERE atc.ResourceType = 'LESSON'
                         AND atc.ResourceID = l.LessonID
                         AND atc.IsDeleted = 0
                    )
               OR EXISTS (
                       SELECT 1
                       FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                       WHERE rtp.GiaoVienID = @sys_UserID
                         AND rtp.Enable = 1
                         AND rtp.PermissionScope = 'SUBJECT'
                         AND rtp.MonHocID = l.MonHocID
                         AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = l.NienKhoa)
                    )
               )
          AND l.IsDeleted  = 0
          AND (@NienKhoa IS NULL OR l.NienKhoa = TRY_CONVERT(INT, @NienKhoa))
          -- Bản sao gắn riêng với lần giao cho lớp không được hiển thị như một bài độc lập trong thư viện.
          AND NOT EXISTS (
                  SELECT 1
                  FROM dbo.tblEL_AssignToClass atcOverride
                  WHERE atcOverride.ResourceType = 'LESSON'
                    AND TRY_CONVERT(INT, JSON_VALUE(
                            CASE WHEN ISJSON(atcOverride.AssignmentConfig) = 1
                                 THEN atcOverride.AssignmentConfig ELSE N'{}' END,
                            '$.lessonOverrideId'
                        )) = l.LessonID
              )
    )
    , ClassAgg AS
    (
        SELECT atc.ResourceID
             , atc.ResourceType
             , COUNT(DISTINCT atc.MonHocLopID)                              AS ClassCount
             , STRING_AGG(COALESCE(l.TenLop, n.TenNhom), ', ')
                   WITHIN GROUP (ORDER BY COALESCE(l.TenLop, n.TenNhom))   AS ClassNames
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblMonHocLop mhl
            ON mhl.MonHocLopID = atc.MonHocLopID
        LEFT JOIN dbo.tblLop l
            ON l.LopID = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblNhom n
            ON n.NhomID = mhl.LopNhomID AND n.NienKhoa = @NienKhoa
        WHERE atc.IsDeleted = 0
        GROUP BY atc.ResourceID, atc.ResourceType
    )
    , ClassAggPublic AS
    (
        SELECT atc.ResourceID
             , atc.ResourceType
             , STRING_AGG(COALESCE(l.TenLop, n.TenNhom), ', ')
                   WITHIN GROUP (ORDER BY COALESCE(l.TenLop, n.TenNhom))   AS ClassNamesPublic
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblMonHocLop mhl
            ON mhl.MonHocLopID = atc.MonHocLopID
        LEFT JOIN dbo.tblLop l
            ON l.LopID = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblNhom n
            ON n.NhomID = mhl.LopNhomID AND n.NienKhoa = @NienKhoa
        WHERE atc.IsDeleted = 0
          AND atc.Status    = 1
        GROUP BY atc.ResourceID, atc.ResourceType
    )
    , StudentAgg AS
    (
        SELECT s.ResourceID
             , s.ResourceType
             , COUNT(DISTINCT s.HocSinhID)                                  AS StudentCount
             , STRING_AGG(
                   hs.Ho + ' ' + hs.Ten + ' (' + ISNULL(lp.TenLop, '') + ')',
                   ', '
               ) WITHIN GROUP (
                   ORDER BY hs.Ho + ' ' + hs.Ten
               )                                                            AS StudentNames
        FROM dbo.tblEL_AssignToStudent s
        JOIN dbo.tblHocSinh hs ON hs.HocSinhID = s.HocSinhID
        OUTER APPLY (
            SELECT TOP 1 l.TenLop
            FROM dbo.tblHocSinhLop hsl
            JOIN dbo.tblLop l
                ON l.LopID = hsl.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
            AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = hs.HocSinhID
              AND hsl.NienKhoa = @NienKhoa
              AND hsl.Enable = 1
        ) lp (TenLop)
        WHERE s.IsDeleted = 0
        GROUP BY s.ResourceID, s.ResourceType
    )
    , StudentAggPublic AS
    (
        SELECT s.ResourceID
             , s.ResourceType
             , STRING_AGG(
                   hs.Ho + ' ' + hs.Ten + ' (' + ISNULL(lp.TenLop, '') + ')',
                   ', '
               ) WITHIN GROUP (
                   ORDER BY hs.Ho + ' ' + hs.Ten
               )                                                            AS StudentNamesPublic
        FROM dbo.tblEL_AssignToStudent s
        JOIN dbo.tblHocSinh hs ON hs.HocSinhID = s.HocSinhID
        OUTER APPLY (
            SELECT TOP 1 l.TenLop
            FROM dbo.tblHocSinhLop hsl
            JOIN dbo.tblLop l
                ON l.LopID = hsl.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
            AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = hs.HocSinhID
              AND hsl.NienKhoa = @NienKhoa
              AND hsl.Enable = 1
        ) lp (TenLop)
        WHERE s.IsDeleted = 0
          AND s.Status    = 1
        GROUP BY s.ResourceID, s.ResourceType
    )
    , AssignedDetailsJson AS
    (
        SELECT ResourceID, ResourceType
             , (
                   SELECT *
                   FROM (
                       SELECT 'Class'                           AS Type
                            , COALESCE(l.TenLop, n.TenNhom)    AS TenLopHoacNhom
                            , mhl.LopNhomID                    AS LopHoacNhomID
                            , i.AssignToClassID
                            , NULL                             AS AssignToStudentID
                            , i.AssignmentID
                            , i.ResourceType
                            , i.ResourceID
                            , i.Status
                            , i.DueDate
                            , i.MaxScore
                            , i.LimitAssigned
                            , i.Is_Full_Quiz
                            , 1                                AS Is_AssignedToClass
                       FROM dbo.tblEL_AssignToClass i
                       JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = i.MonHocLopID
                       LEFT JOIN dbo.tblLop l
                           ON l.LopID = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
                       LEFT JOIN dbo.tblNhom n
                           ON n.NhomID = mhl.LopNhomID AND n.NienKhoa = @NienKhoa
                       WHERE i.ResourceID   = sub.ResourceID
                         AND i.ResourceType = sub.ResourceType
                         AND i.IsDeleted    = 0

                       UNION ALL

                       SELECT 'Student'
                            , hs.Ho + ' ' + hs.Ten + ' (' + ISNULL(lp.TenLop, '') + ')'
                            , CAST(hs.HocSinhID AS VARCHAR(20))
                            , NULL
                            , s.AssignToStudentID
                            , s.AssignmentID
                            , s.ResourceType
                            , s.ResourceID
                            , s.Status
                            , s.DueDate
                            , s.MaxScore
                            , s.LimitAssigned
                            , s.Is_Full_Quiz
                            , 0
                       FROM dbo.tblEL_AssignToStudent s
                       JOIN dbo.tblHocSinh hs ON hs.HocSinhID = s.HocSinhID
                       OUTER APPLY (
                           SELECT TOP 1 l.TenLop
                           FROM dbo.tblHocSinhLop hsl
                           JOIN dbo.tblLop l
                               ON l.LopID = hsl.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
                           AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = hs.HocSinhID
                             AND hsl.NienKhoa = @NienKhoa
                             AND hsl.Enable = 1
                       ) lp (TenLop)
                       WHERE s.ResourceID   = sub.ResourceID
                         AND s.ResourceType = sub.ResourceType
                         AND s.IsDeleted    = 0
                   ) AS Combined
                   FOR JSON PATH
               ) AS AssignedDetails
        FROM (
            SELECT ResourceID, ResourceType FROM dbo.tblEL_AssignToClass  WHERE IsDeleted = 0
            UNION
            SELECT ResourceID, ResourceType FROM dbo.tblEL_AssignToStudent WHERE IsDeleted = 0
        ) sub
    )

    SELECT ac.ResourceID
         , ac.ResourceType
         , ac.Title
         , ac.Instructions
         , mh.MonHocName
         , k.TenKhoiHoc                                               AS TenKhoi
         , ISNULL(ca.ClassCount, 0) + ISNULL(sa.StudentCount, 0)      AS AssignedClassCount
         , RTRIM(LTRIM(
               CONCAT(
                   ISNULL(ca.ClassNames, ''),
                   CASE WHEN ca.ClassNames IS NOT NULL AND sa.StudentNames IS NOT NULL
                        THEN ', ' ELSE '' END,
                   ISNULL(sa.StudentNames, '')
               )
           ))                                                          AS AssignedClassNames
         , RTRIM(LTRIM(
               CONCAT(
                   ISNULL(cap.ClassNamesPublic, ''),
                   CASE WHEN cap.ClassNamesPublic IS NOT NULL AND sap.StudentNamesPublic IS NOT NULL
                        THEN ', ' ELSE '' END,
                   ISNULL(sap.StudentNamesPublic, '')
               )
           ))                                                          AS AssignedClassNamesPublic
         , adj.AssignedDetails
         , CASE
               WHEN (ca.ResourceID IS NOT NULL OR sa.ResourceID IS NOT NULL) THEN 3
               WHEN ac.Status_Internal = 2 THEN 2
               ELSE 1
           END                                                         AS Status
         , ac.LastUpdateTime
         , ac.KhoiID
         , ac.MonHocID
         , ac.NguoiUploadID
         , gv.HoGV + N' ' + gv.TenGV                       AS NguoiUploadName
         , ac.TuanHocID
         , dbo.fnGetTuanHoc_HienThi(
               tht.Tuan, tht.ThangHoc, tht.NgayBatDau, tht.NgayKetThuc
           )                                                           AS Tuan_HienThi
         , ac.Chuong
         , CASE WHEN ac.ResourceType = 'ASSIGNMENT' THEN ac.ResourceID ELSE NULL END AS AssignmentID
         , ac.IsPublic
         , CASE
               WHEN ca.ResourceID IS NOT NULL THEN 1
               WHEN sa.ResourceID IS NOT NULL THEN 0
               ELSE NULL
           END                                                         AS Is_AssignedToClass
         -- Quyền thao tác được tính riêng với quyền nhìn thấy nội dung.
         -- Dòng SUBJECT chỉ xem có IsEdit/IsGrade = 0 nên không mở các thao tác quản lý.
         , CASE
               WHEN @sys_SystemRight IN (3, 9) OR ac.NguoiUploadID = @sys_UserID THEN 1
               WHEN EXISTS (
                       SELECT 1
                       FROM dbo.tblEL_AssignToClass atc
                       INNER JOIN dbo.tblEL_Resoucre_TeacherPermissions rtp
                           ON rtp.AssignToClassID = atc.AssignToClassID
                          AND rtp.GiaoVienID = @sys_UserID
                          AND rtp.Enable = 1
                          AND rtp.IsEdit = 1
                       WHERE atc.ResourceType = ac.ResourceType
                         AND atc.ResourceID = ac.ResourceID
                         AND atc.IsDeleted = 0
                    ) THEN 1
               WHEN EXISTS (
                       SELECT 1
                       FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                       WHERE rtp.GiaoVienID = @sys_UserID
                         AND rtp.Enable = 1
                         AND rtp.IsEdit = 1
                         AND rtp.PermissionScope = 'SUBJECT'
                         AND rtp.MonHocID = ac.MonHocID
                         AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = TRY_CONVERT(INT, @NienKhoa))
                    ) THEN 1
               ELSE 0
           END                                                         AS CanEdit
         , CASE
               WHEN @sys_SystemRight IN (3, 9) OR ac.NguoiUploadID = @sys_UserID THEN 1
               WHEN EXISTS (
                       SELECT 1
                       FROM dbo.tblEL_AssignToClass atc
                       INNER JOIN dbo.tblEL_Resoucre_TeacherPermissions rtp
                           ON rtp.AssignToClassID = atc.AssignToClassID
                          AND rtp.GiaoVienID = @sys_UserID
                          AND rtp.Enable = 1
                          AND rtp.IsGrade = 1
                       WHERE atc.ResourceType = ac.ResourceType
                         AND atc.ResourceID = ac.ResourceID
                         AND atc.IsDeleted = 0
                    ) THEN 1
               WHEN EXISTS (
                       SELECT 1
                       FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                       WHERE rtp.GiaoVienID = @sys_UserID
                         AND rtp.Enable = 1
                         AND rtp.IsGrade = 1
                         AND rtp.PermissionScope = 'SUBJECT'
                         AND rtp.MonHocID = ac.MonHocID
                         AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = TRY_CONVERT(INT, @NienKhoa))
                    ) THEN 1
               ELSE 0
           END                                                         AS CanGrade

    FROM AllContent ac
    LEFT JOIN dbo.tblMonHoc    mh  ON mh.MonHocID  = ac.MonHocID
    LEFT JOIN dbo.tblGiaoVien  gv  ON gv.GiaoVienID = ac.NguoiUploadID
    LEFT JOIN dbo.tblKhoi      k   ON k.KhoiID     = ac.KhoiID
    LEFT JOIN dbo.tblTuanHocTap tht ON tht.TuanHocID = ac.TuanHocID
    LEFT JOIN ClassAgg         ca  ON ca.ResourceID   = ac.ResourceID AND ca.ResourceType   = ac.ResourceType
    LEFT JOIN ClassAggPublic   cap ON cap.ResourceID  = ac.ResourceID AND cap.ResourceType  = ac.ResourceType
    LEFT JOIN StudentAgg       sa  ON sa.ResourceID   = ac.ResourceID AND sa.ResourceType   = ac.ResourceType
    LEFT JOIN StudentAggPublic sap ON sap.ResourceID  = ac.ResourceID AND sap.ResourceType  = ac.ResourceType
    LEFT JOIN AssignedDetailsJson adj ON adj.ResourceID = ac.ResourceID AND adj.ResourceType = ac.ResourceType

    WHERE (@KhoiID    IS NULL OR ac.KhoiID   = @KhoiID)
      AND (@MonHocID  IS NULL OR ac.MonHocID = @MonHocID)
      AND (@SearchTerm IS NULL OR ac.Title LIKE '%' + @SearchTerm + '%')

     ORDER BY 
        ac.KhoiID,
        ac.MonHocID,
        tht.NgayBatDau DESC,
        CASE 
            WHEN ac.ResourceType = 'LESSON' THEN 0 
            ELSE 1 
        END,
        TRY_CAST(ac.Chuong AS INT),
        ac.Chuong,
        ac.LastUpdateTime DESC;
END;
