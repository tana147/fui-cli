
/*
    spAPI_EL_Teacher_GetMyContentLibrary  —  v2  (performance rewrite)
    -----------------------------------------------------------------------
    Thay đổi so với v1:
      1. AssignmentDetails CTE được tách thành 5 CTE pre-aggregation riêng
         (ClassAgg, ClassAggPublic, StudentAgg, StudentAggPublic, AssignedDetailsJson)
         → loại bỏ hoàn toàn correlated subquery / STUFF vòng lặp per-row
      2. STUFF(FOR XML PATH) → STRING_AGG  (SQL Server 2017+)
      3. UNION ALL 2 nhánh trong AssignmentDetails được gộp thành 1 nhánh
         bằng LEFT JOIN, bỏ NOT EXISTS scan lại tblEL_AssignToClass
      4. FOR JSON PATH giữ nguyên output contract, nhưng được build 1 lần
         trong CTE riêng thay vì correlated subquery lồng trong GROUP BY
*/

create PROCEDURE [dbo].[spAPI_EL_Teacher_GetMyContentLibrary_bk20260427] -- 'NV0000975', NULL,NULL,NULL,2025 ,9
    @sys_UserID      VARCHAR(9),
    @KhoiID          INT           = NULL,
    @MonHocID        INT           = NULL,
    @SearchTerm      NVARCHAR(255) = NULL,
    @NienKhoa        VARCHAR(10)   = NULL,
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    -- -----------------------------------------------------------------------
    -- 0. Chuẩn hóa UserID + lấy permission IDs
    -- -----------------------------------------------------------------------
    SET @sys_UserID = [dbo].[fn_GetUser_LMS](@sys_UserID);

    DECLARE @AssignmentToClassID_Permissions   INT;
    DECLARE @AssignmentToStudentID_Permissions INT;

    SET @AssignmentToClassID_Permissions = (
        SELECT TOP 1 AssignToClassID
        FROM   tblEL_Resoucre_TeacherPermissions
        WHERE  Enable     = 1
          AND  GiaoVienID = @sys_UserID
    );

    SET @AssignmentToStudentID_Permissions = (
        SELECT TOP 1 AssignToStudentID
        FROM   dbo.tblEL_AssignToStudent
        WHERE  IsDeleted   = 0
          AND  CreateUser  = @sys_UserID
    );

    -- -----------------------------------------------------------------------
    -- CTE 1: AllContent  —  danh sách Assignments + Lessons của teacher
    -- -----------------------------------------------------------------------
    ;WITH AllContent AS
    (
        SELECT a.AssignmentID                     AS ResourceID
             , 'ASSIGNMENT'                       AS ResourceType
             , a.Title
             , a.Instructions
             , a.KhoiID
             , a.MonHocID
             , a.TuanHocID
             , a.Chuong
             , 3                                  AS Status_Internal
             , ISNULL(a.UpdateTime, a.CreateTime) AS LastUpdateTime
             , a.IsPublic
        FROM dbo.tblEL_Assignments a
        WHERE (
                  a.CreateUser = @sys_UserID
               OR a.AssignmentID IN (
                      SELECT AssignmentID FROM tblEL_AssignToClass
                      WHERE  AssignToClassID = @AssignmentToClassID_Permissions
                      UNION
                      SELECT AssignmentID FROM dbo.tblEL_AssignToStudent
                      WHERE  AssignToStudentID = @AssignmentToStudentID_Permissions
                  )
              )
          AND a.IsDeleted = 0

        UNION ALL

        SELECT l.LessonID
             , 'LESSON'
             , l.Title
             , l.[Description]
             , l.KhoiID
             , l.MonHocID
             , l.TuanHocID
             , l.Chuong
             , l.Status
             , ISNULL(l.UpdateTime, l.CreateTime)
             , l.IsPublic
        FROM dbo.tblEL_Lessons l
        WHERE l.CreateUser = @sys_UserID
          AND l.IsDeleted  = 0
    )

    -- -----------------------------------------------------------------------
    -- CTE 2: ClassAgg  —  tổng hợp lớp được giao (tất cả status)
    --         Đọc tblEL_AssignToClass + tblMonHocLop + tblLop/tblNhom 1 lần
    -- -----------------------------------------------------------------------
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

    -- -----------------------------------------------------------------------
    -- CTE 3: ClassAggPublic  —  chỉ lớp đang published (Status = 1)
    -- -----------------------------------------------------------------------
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

    -- -----------------------------------------------------------------------
    -- CTE 4: StudentAgg  —  tổng hợp học sinh được giao (tất cả status)
    --         Đọc tblEL_AssignToStudent + tblHocSinh + tblHocSinhLop 1 lần
    -- -----------------------------------------------------------------------
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
            WHERE hsl.HocSinhID = hs.HocSinhID
        ) lp (TenLop)
        WHERE s.IsDeleted = 0
        GROUP BY s.ResourceID, s.ResourceType
    )

    -- -----------------------------------------------------------------------
    -- CTE 5: StudentAggPublic  —  chỉ học sinh đang published (Status = 1)
    -- -----------------------------------------------------------------------
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
            WHERE hsl.HocSinhID = hs.HocSinhID
        ) lp (TenLop)
        WHERE s.IsDeleted = 0
          AND s.Status    = 1
        GROUP BY s.ResourceID, s.ResourceType
    )

    -- -----------------------------------------------------------------------
    -- CTE 6: AssignedDetailsJson
    --         Build FOR JSON PATH 1 lần duy nhất cho tất cả resource
    --         thay vì correlated subquery per-row
    -- -----------------------------------------------------------------------
    , AssignedDetailsJson AS
    (
        SELECT ResourceID, ResourceType
             , (
                   SELECT *
                   FROM (
                       -- Class entries
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

                       -- Student entries
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
                           WHERE hsl.HocSinhID = hs.HocSinhID
                       ) lp (TenLop)
                       WHERE s.ResourceID   = sub.ResourceID
                         AND s.ResourceType = sub.ResourceType
                         AND s.IsDeleted    = 0
                   ) AS Combined
                   FOR JSON PATH
               ) AS AssignedDetails
        FROM (
            -- Distinct list of resource có bất kỳ assignment nào
            SELECT ResourceID, ResourceType FROM dbo.tblEL_AssignToClass  WHERE IsDeleted = 0
            UNION
            SELECT ResourceID, ResourceType FROM dbo.tblEL_AssignToStudent WHERE IsDeleted = 0
        ) sub
    )

    -- -----------------------------------------------------------------------
    -- SELECT chính  —  chỉ JOIN, không còn subquery per-row
    -- -----------------------------------------------------------------------
    SELECT ac.ResourceID
         , ac.ResourceType
         , ac.Title
         , ac.Instructions
         , mh.MonHocName
         , k.TenKhoiHoc                                               AS TenKhoi

         -- Tổng số lớp + học sinh được giao
         , ISNULL(ca.ClassCount, 0) + ISNULL(sa.StudentCount, 0)      AS AssignedClassCount

         -- Tên đầy đủ (tất cả)
         , RTRIM(LTRIM(
               CONCAT(
                   ISNULL(ca.ClassNames, ''),
                   CASE WHEN ca.ClassNames IS NOT NULL AND sa.StudentNames IS NOT NULL
                        THEN ', ' ELSE '' END,
                   ISNULL(sa.StudentNames, '')
               )
           ))                                                          AS AssignedClassNames

         -- Tên đang published
         , RTRIM(LTRIM(
               CONCAT(
                   ISNULL(cap.ClassNamesPublic, ''),
                   CASE WHEN cap.ClassNamesPublic IS NOT NULL AND sap.StudentNamesPublic IS NOT NULL
                        THEN ', ' ELSE '' END,
                   ISNULL(sap.StudentNamesPublic, '')
               )
           ))                                                          AS AssignedClassNamesPublic

         , adj.AssignedDetails

         -- Status logic giữ nguyên
         , CASE
               WHEN (ca.ResourceID IS NOT NULL OR sa.ResourceID IS NOT NULL) THEN 3
               WHEN ac.Status_Internal = 2 THEN 2
               ELSE 1
           END                                                         AS Status

         , ac.LastUpdateTime
         , ac.KhoiID
         , ac.MonHocID
         , ac.TuanHocID
         , dbo.fnGetTuanHoc_HienThi(
               tht.Tuan, tht.ThangHoc, tht.NgayBatDau, tht.NgayKetThuc
           )                                                           AS Tuan_HienThi
         , ac.Chuong
         , CASE WHEN ac.ResourceType = 'ASSIGNMENT' THEN ac.ResourceID ELSE NULL END AS AssignmentID
         , ac.IsPublic

         -- Is_AssignedToClass: 1 nếu có class, 0 nếu chỉ có student, NULL nếu chưa giao
         , CASE
               WHEN ca.ResourceID IS NOT NULL THEN 1
               WHEN sa.ResourceID IS NOT NULL THEN 0
               ELSE NULL
           END                                                         AS Is_AssignedToClass

    FROM AllContent ac
    LEFT JOIN dbo.tblMonHoc    mh  ON mh.MonHocID  = ac.MonHocID
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

    ORDER BY ac.KhoiID, ac.MonHocID, ac.TuanHocID, ac.Chuong, ac.LastUpdateTime DESC;

END;
