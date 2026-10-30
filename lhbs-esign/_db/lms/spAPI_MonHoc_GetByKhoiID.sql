--[spAPI_MonHoc_GetByKhoiID] 1
CREATE PROC [dbo].[spAPI_MonHoc_GetByKhoiID]
    @KhoiID          INT
  , @NienKhoa        INT
  , @HocKi           INT
  , @IncludeGroupNames BIT
  , @SYS_USERID      VARCHAR(9)
  , @Sys_GroupID     INT
  , @sys_SystemRight INT
AS
BEGIN
    -- KhoiID = 0 is the report dropdown contract: read grades 6-12 in one pass,
    -- then collapse repeated subject assignments once instead of issuing seven API calls.
    IF (@KhoiID = 0)
    BEGIN
        ;WITH MonHocTheoKhoi AS
        (
            SELECT mh.MonHocID,
                   mh.MonHocName,
                   mhl.TemplateBangDiemID,
                   l.KhoiID,
                   mh.Sort
            FROM dbo.tblMonHocLop AS mhl
            INNER JOIN dbo.tblLop AS l
                ON l.LopID = mhl.LopNhomID
               AND l.NienKhoa = @NienKhoa
               AND l.Enable = 1
               AND l.KhoiID BETWEEN 6 AND 12
            INNER JOIN dbo.tblMonHoc AS mh
                ON mh.MonHocID = mhl.MonHocID
            WHERE mhl.Enable = 1
              AND mhl.NienKhoa = @NienKhoa
              AND (l.KhoiID >= 10 OR mhl.TemplateBangDiemID > 0)
              AND
              (
                  @sys_SystemRight IN (3, 5, 9)
                  OR EXISTS
                  (
                      SELECT 1
                      FROM dbo.tblGiaoVienLop AS gvl
                      WHERE gvl.GiaoVienID = @SYS_USERID
                        AND gvl.MonHocID = mhl.MonHocID
                        AND gvl.Enable = 1
                        AND gvl.HocKy = @HocKi
                  )
              )

            UNION ALL

            SELECT mh.MonHocID,
                   mh.MonHocName,
                   mhl.TemplateBangDiemID,
                   n.KhoiID,
                   mh.Sort
            FROM dbo.tblNhom AS n
            INNER JOIN dbo.tblMonHocLop AS mhl
                ON mhl.Enable = 1
               AND mhl.NienKhoa = @NienKhoa
               AND mhl.LopNhomID = n.NhomID
            INNER JOIN dbo.tblMonHoc AS mh
                ON mh.MonHocID = mhl.MonHocID
            WHERE n.NienKhoa = @NienKhoa
              AND n.Enable = 1
              AND n.KhoiID BETWEEN 10 AND 12
              AND n.IsNhomLMS_GiaoBai = 0
              AND
              (
                  @sys_SystemRight IN (3, 5, 9)
                  OR
                  (
                      mh.Enable = 1
                      AND mhl.ChiaTheoLop = 0
                      AND EXISTS
                      (
                          SELECT 1
                          FROM dbo.tblGiaoVienLop AS gvl
                          WHERE gvl.GiaoVienID = @SYS_USERID
                            AND gvl.LopID = n.NhomID
                            AND gvl.Enable = 1
                            AND gvl.NienKhoa = @NienKhoa
                            AND gvl.HocKy = @HocKi
                      )
                  )
              )
        )
        SELECT MonHocID,
               MonHocName,
               MIN(TemplateBangDiemID) AS TemplateBangDiemID,
               MIN(KhoiID) AS KhoiID,
               CASE WHEN MIN(KhoiID) >= 10 THEN 3 ELSE 2 END AS CapID,
               MIN(Sort) AS Sort
        FROM MonHocTheoKhoi
        GROUP BY MonHocID, MonHocName
        ORDER BY MIN(Sort), MonHocName;

        RETURN;
    END;

    IF @sys_SystemRight IN (3, 5, 9)
    BEGIN
        IF (@KhoiID >= 10)
        BEGIN
            SELECT t.MonHocID
                 , t.MonHocName
                 , t.TemplateBangDiemID
                 , t.Sort
                 , CASE WHEN @IncludeGroupNames = 1 THEN
                       STUFF((
                           SELECT N', ' + groupNames.TenNhom
                           FROM
                           (
                               SELECT DISTINCT n2.TenNhom
                               FROM dbo.tblMonHocLop AS mhl2
                               INNER JOIN dbo.tblNhom AS n2
                                   ON n2.NhomID = mhl2.LopNhomID
                               WHERE mhl2.MonHocID = t.MonHocID
                                 AND mhl2.TemplateBangDiemID = t.TemplateBangDiemID
                                 AND mhl2.NienKhoa = @NienKhoa
                                 AND mhl2.Enable = 1
                                 AND n2.NienKhoa = @NienKhoa
                                 AND n2.KhoiID = @KhoiID
                                 AND n2.Enable = 1
                                 AND n2.IsNhomLMS_GiaoBai = 0
                           ) AS groupNames
                           ORDER BY groupNames.TenNhom
                           FOR XML PATH(''), TYPE
                       ).value('.', 'NVARCHAR(MAX)'), 1, 2, N'')
                   ELSE NULL END AS NhomNameList
            FROM
                   (
                       SELECT DISTINCT
                              mh.MonHocID
                            , mh.MonHocName
                            , mhl.TemplateBangDiemID
                            , mh.Sort
                       FROM
                              dbo.tblMonHocLop         AS mhl
                              INNER JOIN dbo.tblLop    AS l ON l.LopID      = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
                                                           AND l.Enable     = 1
                                                           AND l.KhoiID     = @KhoiID
                              INNER JOIN dbo.tblMonHoc AS mh ON mh.MonHocID = mhl.MonHocID
                       WHERE
                              mhl.Enable  = 1
                         AND  mhl.NienKhoa = @NienKhoa
                       UNION
                       SELECT DISTINCT
                              mh.MonHocID
                            , mh.MonHocName
                            , mhl.TemplateBangDiemID
                            , mh.Sort
                       FROM
                              dbo.tblNhom                 AS n
                              INNER JOIN dbo.tblMonHocLop AS mhl ON mhl.Enable    = 1
                                                                AND mhl.NienKhoa  = @NienKhoa
                                                                --and mhl.ChiaTheoLop = 0 
                                                                AND mhl.LopNhomID = n.NhomID
                              INNER JOIN dbo.tblMonHoc    AS mh ON mh.MonHocID    = mhl.MonHocID
                       WHERE
                              n.NienKhoa         = @NienKhoa
                         AND  n.Enable            = 1
                         AND  n.KhoiID            = @KhoiID
                         AND  n.IsNhomLMS_GiaoBai = 0
                   ) AS t
            ORDER BY
                   t.Sort;
        END;
        ELSE
        BEGIN
            SELECT DISTINCT
                   mh.MonHocID
                 , mh.MonHocName
                 , mhl.TemplateBangDiemID
                 , mh.Sort
            FROM
                   dbo.tblMonHocLop         AS mhl
                   INNER JOIN dbo.tblLop    AS l ON l.LopID      = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
                                                AND l.Enable     = 1
                                                AND l.KhoiID     = @KhoiID
                   INNER JOIN dbo.tblMonHoc AS mh ON mh.MonHocID = mhl.MonHocID
            WHERE
                   mhl.Enable            = 1
              AND  mhl.NienKhoa           = @NienKhoa
              AND  mhl.TemplateBangDiemID > 0
            ORDER BY
                   mh.Sort;
        END;
    END;
    ELSE
    BEGIN
        IF (@KhoiID >= 10)
        BEGIN
            SELECT t.MonHocID
                 , t.MonHocName
                 , t.TemplateBangDiemID
                 , CASE WHEN @IncludeGroupNames = 1 THEN
                       STUFF((
                           SELECT N', ' + groupNames.TenNhom
                           FROM
                           (
                               SELECT DISTINCT n2.TenNhom
                               FROM dbo.tblMonHocLop AS mhl2
                               INNER JOIN dbo.tblNhom AS n2
                                   ON n2.NhomID = mhl2.LopNhomID
                               WHERE mhl2.MonHocID = t.MonHocID
                                 AND mhl2.TemplateBangDiemID = t.TemplateBangDiemID
                                 AND mhl2.NienKhoa = @NienKhoa
                                 AND mhl2.Enable = 1
                                 AND n2.NienKhoa = @NienKhoa
                                 AND n2.KhoiID = @KhoiID
                                 AND n2.Enable = 1
                                 AND n2.IsNhomLMS_GiaoBai = 0
                                 AND EXISTS
                                 (
                                     SELECT 1
                                     FROM dbo.tblGiaoVienLop AS gvl2
                                     WHERE gvl2.GiaoVienID = @SYS_USERID
                                       AND gvl2.LopID = n2.NhomID
                                       AND gvl2.Enable = 1
                                       AND gvl2.NienKhoa = @NienKhoa
                                       AND gvl2.HocKy = @HocKi
                                 )
                           ) AS groupNames
                           ORDER BY groupNames.TenNhom
                           FOR XML PATH(''), TYPE
                       ).value('.', 'NVARCHAR(MAX)'), 1, 2, N'')
                   ELSE NULL END AS NhomNameList
            FROM
            (
                SELECT DISTINCT
                       mh.MonHocID
                     , mh.MonHocName
                     , mhl.TemplateBangDiemID
                FROM dbo.tblMonHocLop AS mhl
                INNER JOIN dbo.tblLop AS l
                    ON l.LopID = mhl.LopNhomID
                   AND l.NienKhoa = @NienKhoa
                   AND l.Enable = 1
                   AND l.KhoiID = @KhoiID
                INNER JOIN dbo.tblMonHoc AS mh
                    ON mh.MonHocID = mhl.MonHocID
                INNER JOIN dbo.tblGiaoVienLop AS gvl
                    ON gvl.GiaoVienID = @SYS_USERID
                   AND gvl.MonHocID = mhl.MonHocID
                   AND gvl.Enable = 1
                   AND gvl.HocKy = @HocKi
                WHERE mhl.Enable = 1
                  AND mhl.NienKhoa = @NienKhoa

                UNION

                SELECT DISTINCT
                       mh.MonHocID
                     , mh.MonHocName
                     , mhl.TemplateBangDiemID
                FROM dbo.tblNhom AS n
                INNER JOIN dbo.tblGiaoVienLop AS gvl
                    ON gvl.GiaoVienID = @SYS_USERID
                   AND gvl.LopID = n.NhomID
                   AND gvl.Enable = 1
                   AND gvl.NienKhoa = @NienKhoa
                   AND gvl.HocKy = @HocKi
                INNER JOIN dbo.tblMonHocLop AS mhl
                    ON mhl.Enable = 1
                   AND mhl.NienKhoa = @NienKhoa
                   AND mhl.ChiaTheoLop = 0
                   AND mhl.LopNhomID = n.NhomID
                INNER JOIN dbo.tblMonHoc AS mh
                    ON mh.MonHocID = mhl.MonHocID
                   AND mh.Enable = 1
                WHERE n.NienKhoa = @NienKhoa
                  AND n.Enable = 1
                  AND n.KhoiID = @KhoiID
            ) AS t
            ORDER BY t.MonHocName, t.TemplateBangDiemID;
        END;
        ELSE
        BEGIN
            SELECT DISTINCT
                   mh.MonHocID
                 , mh.MonHocName
                 , mhl.TemplateBangDiemID
                 , mh.Sort
            FROM
                   dbo.tblMonHocLop              AS mhl
                   INNER JOIN dbo.tblLop         AS l ON l.LopID          = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
                                                     AND l.Enable         = 1
                                                     AND l.KhoiID         = @KhoiID
                   INNER JOIN dbo.tblMonHoc      AS mh ON mh.MonHocID     = mhl.MonHocID
                   INNER JOIN dbo.tblGiaoVienLop AS gvl ON gvl.GiaoVienID = @SYS_USERID
                                                       AND gvl.MonHocID   = mhl.MonHocID
                                                       AND gvl.HocKy      = @HocKi
            WHERE
                   mhl.Enable            = 1
              AND  mhl.NienKhoa           = @NienKhoa
              AND  mhl.TemplateBangDiemID > 0
            ORDER BY
                   mh.Sort;
        END;
    END;
END;
