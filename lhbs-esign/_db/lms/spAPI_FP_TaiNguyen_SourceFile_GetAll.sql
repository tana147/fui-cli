CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_SourceFile_GetAll]
    @KhoiID INT,
    @MonHocID INT,
    @sys_UserID VARCHAR(50),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

;WITH SourceFiles AS
    (
        SELECT
            l.LessonID AS ResourceID,
            'LESSON' AS ResourceType,
            'HOC_LIEU' AS NguonTaiNguyenCode,
            COALESCE(NULLIF(src.LmsFileID, ''), src.OriginalFileID) AS FileID,
            src.FileName,
            CASE WHEN NULLIF(src.LmsFileID, '') IS NULL THEN src.FileURL ELSE '/FileData/' + src.LmsFileID END AS FileURL,
            src.ContentType,
            COALESCE(src.FileSize, src.SourceSize) AS FileSize,
            l.KhoiID,
            l.MonHocID,
            l.CreateUser AS NguoiUploadID,
            l.CreateTime,
            l.Title AS ContentTitle,
            l.Chuong AS ContentChapter,
            e.ElementType,
            e.SortOrder AS ElementSortOrder
        FROM dbo.tblEL_Lessons l
        INNER JOIN dbo.tblEL_Elements e ON e.LessonID = l.LessonID AND e.IsDeleted = 0
        CROSS APPLY OPENJSON(e.ElementData, '$.sources')
        WITH
        (
            OriginalFileID NVARCHAR(500) '$.id',
            LmsFileID NVARCHAR(500) '$.resourceFileId',
            FileName NVARCHAR(500) '$.name',
            FileURL NVARCHAR(2000) '$.source',
            ContentType NVARCHAR(100) '$.contentType',
            FileSize BIGINT '$.fileSize',
            SourceSize BIGINT '$.size'
        ) src
        WHERE l.IsDeleted = 0
          AND (
                @sys_SystemRight IN (3, 9)
                OR l.CreateUser = @sys_UserID
                OR (
                    ISNULL(@KhoiID, 0) <> 0
                    AND ISNULL(@MonHocID, 0) <> 0
                    AND l.KhoiID = @KhoiID
                    AND l.MonHocID = @MonHocID
                )
              )

        UNION ALL

        SELECT
            a.AssignmentID,
            'ASSIGNMENT',
            'GIAO_BAI',
            COALESCE(NULLIF(src.LmsFileID, ''), src.OriginalFileID),
            src.FileName,
            CASE WHEN NULLIF(src.LmsFileID, '') IS NULL THEN src.FileURL ELSE '/FileData/' + src.LmsFileID END,
            src.ContentType,
            COALESCE(src.FileSize, src.SourceSize),
            a.KhoiID,
            a.MonHocID,
            a.CreateUser,
            a.CreateTime,
            a.Title,
            NULL,
            NULL,
            NULL
        FROM dbo.tblEL_Assignments a
        CROSS APPLY OPENJSON(a.AssignmentConfig, '$.groups') g
        CROSS APPLY OPENJSON(JSON_QUERY(g.value, '$.media.sourceFiles.file'))
        WITH
        (
            OriginalFileID NVARCHAR(500) '$.id',
            LmsFileID NVARCHAR(500) '$.resourceFileId',
            FileName NVARCHAR(500) '$.name',
            FileURL NVARCHAR(2000) '$.source',
            ContentType NVARCHAR(100) '$.contentType',
            FileSize BIGINT '$.fileSize',
            SourceSize BIGINT '$.size'
        ) src
        WHERE a.IsDeleted = 0
          AND (
                @sys_SystemRight IN (3, 9)
                OR a.CreateUser = @sys_UserID
                OR (
                    ISNULL(@KhoiID, 0) <> 0
                    AND ISNULL(@MonHocID, 0) <> 0
                    AND a.KhoiID = @KhoiID
                    AND a.MonHocID = @MonHocID
                )
              )

        UNION ALL

        SELECT
            a.AssignmentID,
            'ASSIGNMENT',
            'GIAO_BAI',
            COALESCE(NULLIF(src.LmsFileID, ''), src.OriginalFileID),
            src.FileName,
            CASE WHEN NULLIF(src.LmsFileID, '') IS NULL THEN src.FileURL ELSE '/FileData/' + src.LmsFileID END,
            src.ContentType,
            COALESCE(src.FileSize, src.SourceSize),
            a.KhoiID,
            a.MonHocID,
            a.CreateUser,
            a.CreateTime,
            a.Title,
            NULL,
            NULL,
            NULL
        FROM dbo.tblEL_Assignments a
        CROSS APPLY OPENJSON(a.AssignmentConfig, '$.groups') g
        CROSS APPLY OPENJSON(JSON_QUERY(g.value, '$.media.sourceFiles.image'))
        WITH
        (
            OriginalFileID NVARCHAR(500) '$.id',
            LmsFileID NVARCHAR(500) '$.resourceFileId',
            FileName NVARCHAR(500) '$.name',
            FileURL NVARCHAR(2000) '$.source',
            ContentType NVARCHAR(100) '$.contentType',
            FileSize BIGINT '$.fileSize',
            SourceSize BIGINT '$.size'
        ) src
        WHERE a.IsDeleted = 0
          AND (
                @sys_SystemRight IN (3, 9)
                OR a.CreateUser = @sys_UserID
                OR (
                    ISNULL(@KhoiID, 0) <> 0
                    AND ISNULL(@MonHocID, 0) <> 0
                    AND a.KhoiID = @KhoiID
                    AND a.MonHocID = @MonHocID
                )
              )

        UNION ALL

        SELECT
            a.AssignmentID,
            'ASSIGNMENT',
            'GIAO_BAI',
            COALESCE(NULLIF(src.LmsFileID, ''), src.OriginalFileID),
            src.FileName,
            CASE WHEN NULLIF(src.LmsFileID, '') IS NULL THEN src.FileURL ELSE '/FileData/' + src.LmsFileID END,
            src.ContentType,
            COALESCE(src.FileSize, src.SourceSize),
            a.KhoiID,
            a.MonHocID,
            a.CreateUser,
            a.CreateTime,
            a.Title,
            NULL,
            NULL,
            NULL
        FROM dbo.tblEL_Assignments a
        CROSS APPLY OPENJSON(a.AssignmentConfig, '$.groups') g
        CROSS APPLY OPENJSON(g.value, '$.questions') q
        CROSS APPLY OPENJSON(JSON_QUERY(q.value, '$.config.media.sourceFiles.file'))
        WITH
        (
            OriginalFileID NVARCHAR(500) '$.id',
            LmsFileID NVARCHAR(500) '$.resourceFileId',
            FileName NVARCHAR(500) '$.name',
            FileURL NVARCHAR(2000) '$.source',
            ContentType NVARCHAR(100) '$.contentType',
            FileSize BIGINT '$.fileSize',
            SourceSize BIGINT '$.size'
        ) src
        WHERE a.IsDeleted = 0
          AND (
                @sys_SystemRight IN (3, 9)
                OR a.CreateUser = @sys_UserID
                OR (
                    ISNULL(@KhoiID, 0) <> 0
                    AND ISNULL(@MonHocID, 0) <> 0
                    AND a.KhoiID = @KhoiID
                    AND a.MonHocID = @MonHocID
                )
              )

        UNION ALL

        SELECT
            a.AssignmentID,
            'ASSIGNMENT',
            'GIAO_BAI',
            COALESCE(NULLIF(src.LmsFileID, ''), src.OriginalFileID),
            src.FileName,
            CASE WHEN NULLIF(src.LmsFileID, '') IS NULL THEN src.FileURL ELSE '/FileData/' + src.LmsFileID END,
            src.ContentType,
            COALESCE(src.FileSize, src.SourceSize),
            a.KhoiID,
            a.MonHocID,
            a.CreateUser,
            a.CreateTime,
            a.Title,
            NULL,
            NULL,
            NULL
        FROM dbo.tblEL_Assignments a
        CROSS APPLY OPENJSON(a.AssignmentConfig, '$.groups') g
        CROSS APPLY OPENJSON(g.value, '$.questions') q
        CROSS APPLY OPENJSON(JSON_QUERY(q.value, '$.config.media.sourceFiles.image'))
        WITH
        (
            OriginalFileID NVARCHAR(500) '$.id',
            LmsFileID NVARCHAR(500) '$.resourceFileId',
            FileName NVARCHAR(500) '$.name',
            FileURL NVARCHAR(2000) '$.source',
            ContentType NVARCHAR(100) '$.contentType',
            FileSize BIGINT '$.fileSize',
            SourceSize BIGINT '$.size'
        ) src
        WHERE a.IsDeleted = 0
          AND (
                @sys_SystemRight IN (3, 9)
                OR a.CreateUser = @sys_UserID
                OR (
                    ISNULL(@KhoiID, 0) <> 0
                    AND ISNULL(@MonHocID, 0) <> 0
                    AND a.KhoiID = @KhoiID
                    AND a.MonHocID = @MonHocID
                )
              )
    )
    SELECT DISTINCT
        sf.ResourceID, sf.ResourceType, sf.NguonTaiNguyenCode,
        sf.FileID, sf.FileName, sf.FileURL, sf.ContentType, sf.FileSize,
        sf.ContentTitle, sf.ContentChapter, sf.ElementType, sf.ElementSortOrder,
        CASE
            WHEN sf.ResourceType = 'LESSON' THEN CONCAT(sf.ContentTitle,
                CASE WHEN NULLIF(sf.ContentChapter, '') IS NULL THEN '' ELSE N' / ' + sf.ContentChapter END,
                CASE WHEN NULLIF(sf.ElementType, '') IS NULL THEN '' ELSE N' / ' + sf.ElementType END)
            WHEN sf.ResourceType = 'ASSIGNMENT' THEN sf.ContentTitle
            ELSE NULL
        END AS ThuocNoiDung,
        sf.KhoiID, sf.MonHocID, sf.NguoiUploadID, sf.CreateTime,
        mh.MonHocName, k.TenKhoiHoc AS TenKhoi,
        gv.HoGV + N' ' + gv.TenGV AS NguoiUploadName
    FROM SourceFiles sf
    LEFT JOIN dbo.tblMonHoc mh ON mh.MonHocID = sf.MonHocID
    LEFT JOIN dbo.tblKhoi k ON k.KhoiID = sf.KhoiID
    LEFT JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = sf.NguoiUploadID
    WHERE ISNULL(sf.FileID, '') <> ''
      AND (ISNULL(@KhoiID, 0) = 0 OR sf.KhoiID = @KhoiID)
      AND (ISNULL(@MonHocID, 0) = 0 OR sf.MonHocID = @MonHocID)
    ORDER BY sf.KhoiID, sf.MonHocID, sf.CreateTime DESC, sf.FileName;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_SourceFile_GetAll] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_SourceFile_GetAll] FROM [public];
