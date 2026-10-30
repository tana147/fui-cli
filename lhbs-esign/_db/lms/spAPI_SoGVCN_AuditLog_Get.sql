CREATE PROCEDURE dbo.spAPI_SoGVCN_AuditLog_Get
    @NienKhoa INT,
    @KhoiID INT,
    @LopID VARCHAR(20),
    @Ngay VARCHAR(10),
    @NgayTu VARCHAR(10),
    @NgayDen VARCHAR(10),
    @Gio VARCHAR(5),
    @TableName VARCHAR(128),
    @AuditAction CHAR(1),
    @Limit INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Các tham số lọc rỗng/0 được quy về NULL để API có thể truyền thống nhất từ UI.
    SET @NienKhoa = NULLIF(@NienKhoa, 0);
    SET @KhoiID = NULLIF(@KhoiID, 0);
    SET @LopID = NULLIF(LTRIM(RTRIM(@LopID)), '');
    SET @Ngay = NULLIF(LTRIM(RTRIM(@Ngay)), '');
    SET @NgayTu = NULLIF(LTRIM(RTRIM(@NgayTu)), '');
    SET @NgayDen = NULLIF(LTRIM(RTRIM(@NgayDen)), '');
    SET @Gio = NULLIF(LTRIM(RTRIM(@Gio)), '');
    SET @TableName = NULLIF(LTRIM(RTRIM(@TableName)), '');
    SET @AuditAction = NULLIF(UPPER(LTRIM(RTRIM(@AuditAction))), '');

    IF @TableName IS NOT NULL AND RIGHT(@TableName, 4) = '_Log'
        SET @TableName = LEFT(@TableName, LEN(@TableName) - 4);

    IF @Limit IS NULL OR @Limit < 1
        SET @Limit = 500;
    ELSE IF @Limit > 2000
        SET @Limit = 2000;

    -- Tương thích API cũ: nếu chỉ truyền Ngay thì coi đó là một khoảng chỉ có một ngày.
    IF @NgayTu IS NULL AND @NgayDen IS NULL AND @Ngay IS NOT NULL
    BEGIN
        SET @NgayTu = @Ngay;
        SET @NgayDen = @Ngay;
    END;

    DECLARE @FilterDateFrom DATE = COALESCE(
        TRY_CONVERT(DATE, @NgayTu, 23),
        TRY_CONVERT(DATE, @NgayTu, 103),
        TRY_CONVERT(DATE, @NgayTu)
    );
    DECLARE @FilterDateTo DATE = COALESCE(
        TRY_CONVERT(DATE, @NgayDen, 23),
        TRY_CONVERT(DATE, @NgayDen, 103),
        TRY_CONVERT(DATE, @NgayDen)
    );

    -- Nếu người dùng nhập ngược hai đầu mốc thì tự hoán đổi để bộ lọc vẫn có nghĩa.
    IF @FilterDateFrom IS NOT NULL
       AND @FilterDateTo IS NOT NULL
       AND @FilterDateFrom > @FilterDateTo
    BEGIN
        DECLARE @SwapDate DATE = @FilterDateFrom;
        SET @FilterDateFrom = @FilterDateTo;
        SET @FilterDateTo = @SwapDate;
    END;

    DECLARE @FilterHour INT = NULL;
    IF @Gio IS NOT NULL
    BEGIN
        SET @FilterHour = TRY_CONVERT(INT, LEFT(@Gio, 2));
        IF @FilterHour NOT BETWEEN 0 AND 23
            SET @FilterHour = NULL;
    END;

    CREATE TABLE #AuditLog
    (
        SourceTable NVARCHAR(128) NOT NULL,
        AuditID BIGINT NOT NULL,
        SoGVCNID INT NULL,
        NienKhoa INT NULL,
        KhoiID INT NULL,
        LopID VARCHAR(20) NULL,
        AuditAction CHAR(1) NOT NULL,
        AuditActionName NVARCHAR(30) NOT NULL,
        AuditTime DATETIME NULL,
        AuditTimeText VARCHAR(19) NULL,
        AuditUser VARCHAR(20) NULL,
        AuditUserName NVARCHAR(200) NULL,
        AuditTab VARCHAR(100) NULL,
        AuditCapID INT NULL,
        AuditBatchID UNIQUEIDENTIFIER NULL,
        AuditMode VARCHAR(20) NULL,
        AuditEvent VARCHAR(50) NULL,
        SnapshotJson NVARCHAR(MAX) NULL
    );

    DECLARE @CurrentLogTable SYSNAME;
    DECLARE @ObjectID INT;
    DECLARE @SourceTable NVARCHAR(128);
    DECLARE @FullTable NVARCHAR(300);
    DECLARE @JsonColumns NVARCHAR(MAX);
    DECLARE @SoGVCNExpr NVARCHAR(200);
    DECLARE @Sql NVARCHAR(MAX);

    DECLARE audit_table_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT t.name, t.object_id
        FROM sys.tables t
        INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE s.name = 'dbo'
          AND t.name LIKE 'tblSoGVCN%[_]Log'
        ORDER BY t.name;

    OPEN audit_table_cursor;
    FETCH NEXT FROM audit_table_cursor INTO @CurrentLogTable, @ObjectID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SourceTable = LEFT(@CurrentLogTable, LEN(@CurrentLogTable) - 4);
        SET @FullTable = N'dbo.' + QUOTENAME(@CurrentLogTable);

        -- Snapshot và mọi trường lọc đều lấy từ chính bản ghi *_Log.
        SELECT @JsonColumns = STUFF((
            SELECT N', lj.' + QUOTENAME(c.name) + N' AS ' + QUOTENAME(c.name)
            FROM sys.columns c
            WHERE c.object_id = @ObjectID
              AND c.name NOT IN
              (
                  'AuditID', 'AuditAction', 'AuditTime', 'AuditUser',
                  'AuditTab', 'AuditCapID', 'AuditBatchID', 'AuditMode',
                  'AuditEvent', 'AuditNienKhoa', 'AuditKhoiID',
                  'AuditLopID', 'AuditUserName'
              )
            ORDER BY c.column_id
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

        SET @SoGVCNExpr = CASE
            WHEN @CurrentLogTable = 'tblSoGVCNKeHoachTuan_Log' THEN N'NULL'
            ELSE N'l.SoGVCNID'
        END;

        SET @Sql = N'
            INSERT INTO #AuditLog
            (
                SourceTable, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
                AuditAction, AuditActionName, AuditTime, AuditTimeText,
                AuditUser, AuditUserName, AuditTab, AuditCapID, AuditBatchID,
                AuditMode, AuditEvent, SnapshotJson
            )
            SELECT
                @pSourceTable,
                l.AuditID,
                ' + @SoGVCNExpr + N',
                l.AuditNienKhoa,
                l.AuditKhoiID,
                l.AuditLopID,
                l.AuditAction,
                CASE l.AuditAction
                    WHEN ''I'' THEN N''Thêm''
                    WHEN ''U'' THEN N''Cập nhật''
                    WHEN ''D'' THEN N''Xóa''
                    ELSE N''Khác''
                END,
                l.AuditTime,
                CONVERT(VARCHAR(19), l.AuditTime, 120),
                l.AuditUser,
                COALESCE(
                    NULLIF(l.AuditUserName, N''''),
                    NULLIF(l.AuditUser, ''''),
                    N''unknown/unavailable''
                ),
                l.AuditTab,
                l.AuditCapID,
                l.AuditBatchID,
                l.AuditMode,
                l.AuditEvent,
                (SELECT ' + @JsonColumns + N'
                 FROM ' + @FullTable + N' lj
                 WHERE lj.AuditID = l.AuditID
                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
            FROM ' + @FullTable + N' l
            WHERE (@pTableName IS NULL OR @pTableName = @pSourceTable)
              AND (@pNienKhoa IS NULL OR l.AuditNienKhoa = @pNienKhoa)
              AND (@pKhoiID IS NULL OR l.AuditKhoiID = @pKhoiID)
              AND (@pLopID IS NULL OR l.AuditLopID = @pLopID)
              -- Dùng mốc đầu ngày kế tiếp để bao trọn toàn bộ ngày kết thúc.
              AND (@pFilterDateFrom IS NULL OR l.AuditTime >= @pFilterDateFrom)
              AND (@pFilterDateTo IS NULL OR l.AuditTime < DATEADD(DAY, 1, @pFilterDateTo))
              AND (@pFilterHour IS NULL OR DATEPART(HOUR, l.AuditTime) = @pFilterHour)
              AND (@pAuditAction IS NULL OR l.AuditAction = @pAuditAction);';

        EXEC sys.sp_executesql
            @Sql,
            N'@pSourceTable NVARCHAR(128), @pTableName VARCHAR(128), @pNienKhoa INT,
              @pKhoiID INT, @pLopID VARCHAR(20), @pFilterDateFrom DATE,
              @pFilterDateTo DATE,
              @pFilterHour INT, @pAuditAction CHAR(1)',
            @pSourceTable = @SourceTable,
            @pTableName = @TableName,
            @pNienKhoa = @NienKhoa,
            @pKhoiID = @KhoiID,
            @pLopID = @LopID,
            @pFilterDateFrom = @FilterDateFrom,
            @pFilterDateTo = @FilterDateTo,
            @pFilterHour = @FilterHour,
            @pAuditAction = @AuditAction;

        FETCH NEXT FROM audit_table_cursor INTO @CurrentLogTable, @ObjectID;
    END;

    CLOSE audit_table_cursor;
    DEALLOCATE audit_table_cursor;

    SELECT TOP (@Limit)
        SourceTable,
        AuditID,
        SoGVCNID,
        NienKhoa,
        KhoiID,
        LopID,
        AuditAction,
        AuditActionName,
        AuditTime,
        AuditTimeText,
        AuditUser,
        AuditUserName,
        AuditTab,
        AuditCapID,
        AuditBatchID,
        AuditMode,
        AuditEvent,
        SnapshotJson
    FROM #AuditLog
    ORDER BY AuditTime DESC, AuditID DESC;
END;
