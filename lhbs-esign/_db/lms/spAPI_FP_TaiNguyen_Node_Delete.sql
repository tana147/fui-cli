CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_Node_Delete]
    @NoiDungID INT,
    @sys_UserID VARCHAR(50),
    @sys_SystemRight INT,
    @sys_FunctionRight VARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;
    
    
SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @HocLieuID INT;
    DECLARE @CanManageAllResources BIT = CASE WHEN dbo.fn_CheckUserPermission(
        @sys_SystemRight,
        @sys_FunctionRight,
        '[3][5][9]',
        NULL
    ) = 1 THEN 1 ELSE 0 END;

    SELECT @HocLieuID = nd.HocLieuID
    FROM dbo.tblNoiDungHocLieu_FP nd
    INNER JOIN dbo.tblHocLieu_FP hl ON hl.HocLieuID = nd.HocLieuID
    WHERE nd.NoiDungID = @NoiDungID
      AND nd.Is_Xoa = 0
      AND hl.Loai = 'TAI_NGUYEN'
      AND (@CanManageAllResources = 1 OR hl.CreateUser = @sys_UserID)
      AND hl.Is_Xoa = 0;

    IF @HocLieuID IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'[Unauthorized]Bạn không có quyền thực hiện chức năng quản lý tài nguyên này.', 16, 1);
        RETURN;
    END;

    DECLARE @NodesToDelete TABLE (NoiDungID INT PRIMARY KEY);
    DECLARE @FileIDs TABLE (FileID VARCHAR(100) PRIMARY KEY, StorageCode VARCHAR(50) NOT NULL);
    DECLARE @OrphanFileIDs TABLE (FileID VARCHAR(100) PRIMARY KEY, StorageCode VARCHAR(50) NOT NULL);

    ;WITH NodesToDelete AS (
        SELECT NoiDungID
        FROM dbo.tblNoiDungHocLieu_FP
        WHERE NoiDungID = @NoiDungID
        UNION ALL
        SELECT child.NoiDungID
        FROM dbo.tblNoiDungHocLieu_FP child
        INNER JOIN NodesToDelete parent ON child.ParentID = parent.NoiDungID
        WHERE child.HocLieuID = @HocLieuID AND child.Is_Xoa = 0
    )
    INSERT INTO @NodesToDelete (NoiDungID)
    SELECT NoiDungID FROM NodesToDelete;

    INSERT INTO @FileIDs (FileID, StorageCode)
    SELECT CASE WHEN ISJSON(nd.DataJson) = 1 THEN JSON_VALUE(nd.DataJson, '$.fileId') END,
           MAX(COALESCE(CASE WHEN ISJSON(nd.DataJson) = 1 THEN JSON_VALUE(nd.DataJson, '$.storage') END, 'LEGACY'))
    FROM dbo.tblNoiDungHocLieu_FP nd
    INNER JOIN @NodesToDelete deletedNode ON deletedNode.NoiDungID = nd.NoiDungID
    -- Chỉ lấy fileId của node quản lý tài nguyên; storage đi cùng metadata để xóa đúng kho đã upload.
    WHERE nd.NguonTaiNguyenCode IN ('QUAN_LY_TAI_NGUYEN', 'CONTENT_HUB')
      AND NULLIF(CASE WHEN ISJSON(nd.DataJson) = 1 THEN JSON_VALUE(nd.DataJson, '$.fileId') END, '') IS NOT NULL
    GROUP BY CASE WHEN ISJSON(nd.DataJson) = 1 THEN JSON_VALUE(nd.DataJson, '$.fileId') END;

    UPDATE dbo.tblNoiDungHocLieu_FP
    SET Is_Xoa = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE NoiDungID IN (SELECT NoiDungID FROM @NodesToDelete);

    -- Chỉ xóa file sau khi node đã soft-delete và file không còn được nội dung nào tham chiếu.
    INSERT INTO @OrphanFileIDs (FileID, StorageCode)
    SELECT fileItem.FileID, fileItem.StorageCode
    FROM @FileIDs fileItem
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.tblNoiDungHocLieu_FP nd
        WHERE nd.Is_Xoa = 0
          AND CASE WHEN ISJSON(nd.DataJson) = 1 THEN JSON_VALUE(nd.DataJson, '$.fileId') END = fileItem.FileID
    )
      AND NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_Lessons l
        INNER JOIN dbo.tblEL_Elements e ON e.LessonID = l.LessonID AND e.IsDeleted = 0
        WHERE l.IsDeleted = 0
          AND CHARINDEX('"' + fileItem.FileID + '"', CONVERT(NVARCHAR(MAX), e.ElementData)) > 0
    )
      AND NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_Assignments a
        WHERE a.IsDeleted = 0
          AND CHARINDEX('"' + fileItem.FileID + '"', CONVERT(NVARCHAR(MAX), a.AssignmentConfig)) > 0
    );

    -- File upload mới của Content Hub dùng đúng dbo.FileData; không dò/xóa sang kho khác.
    DELETE fd
    FROM dbo.FileData fd
    INNER JOIN @OrphanFileIDs fileItem ON fileItem.FileID = fd.FileID
    WHERE fileItem.StorageCode = 'LMS_DB_FILEDATA';

    -- Chỉ dùng wrapper LMS_FileData cho dữ liệu cũ/metadata đã ghi rõ kho LMS-LHBS-file.
    -- INSERT INTO giúp không phát sinh thêm result set từ SP con ra tAPI.
    DECLARE @FileID VARCHAR(100);
    DECLARE @DeleteResult TABLE (FILE_ID VARCHAR(100), DELETED BIT, STORAGE VARCHAR(100));
    DECLARE file_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT FileID FROM @OrphanFileIDs WHERE StorageCode <> 'LMS_DB_FILEDATA';

    OPEN file_cursor;
    FETCH NEXT FROM file_cursor INTO @FileID;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DELETE FROM @DeleteResult;
        INSERT INTO @DeleteResult (FILE_ID, DELETED, STORAGE)
        EXEC dbo.spAPI_LMS_FileData_Delete @sys_UserID = @sys_UserID, @FileID = @FileID;
        FETCH NEXT FROM file_cursor INTO @FileID;
    END;
    CLOSE file_cursor;
    DEALLOCATE file_cursor;

    COMMIT TRANSACTION;
    SELECT Success = 1;
END;
IF USER_NAME() <> N'lmslhbs' AND USER_NAME() <> N'dbo'
    GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Node_Delete] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Node_Delete] FROM [public];
