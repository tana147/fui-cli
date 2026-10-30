CREATE PROCEDURE dbo.spAPI_LMS_SyncDiemLog_Start
    @RequestID UNIQUEIDENTIFIER,
    @LockActionID UNIQUEIDENTIFIER,
    @CapID INT,
    @KhoiID INT,
    @NienKhoa INT,
    @LopChonID VARCHAR(50),
    @LopChonTen NVARCHAR(100),
    @MonHocLopID INT,
    @MonHocID INT,
    @MonHocCode VARCHAR(50),
    @TemplateBangDiemID INT,
    @LoaiDiem VARCHAR(20),
    @HocKy TINYINT,
    @DataPayload NVARCHAR(MAX),
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF @RequestID IS NULL OR @LockActionID IS NULL
    BEGIN
        RAISERROR('RequestID va LockActionID la bat buoc.', 16, 1);
        RETURN;
    END;

    IF NULLIF(LTRIM(RTRIM(@SYS_USERID)), '') IS NULL
    BEGIN
        RAISERROR('Khong xac dinh duoc nguoi dung LMS thuc hien dong bo.', 16, 1);
        RETURN;
    END;

    IF @HocKy NOT IN (1, 2)
    BEGIN
        RAISERROR('HocKy phai la 1 hoac 2.', 16, 1);
        RETURN;
    END;

    IF ISJSON(@DataPayload) <> 1 OR LEFT(LTRIM(@DataPayload), 1) <> '['
    BEGIN
        RAISERROR('DataPayload phai la mang JSON cua cac dong diem gui QLDiem.', 16, 1);
        RETURN;
    END;

    DECLARE @DataRowCount INT = (SELECT COUNT(*) FROM OPENJSON(@DataPayload));
    DECLARE @StudentCount INT =
    (
        SELECT COUNT(DISTINCT TRY_CONVERT(INT, JSON_VALUE(payload.value, '$.HocSinhID')))
        FROM OPENJSON(@DataPayload) AS payload
    );
    IF @DataRowCount = 0 OR @StudentCount = 0
    BEGIN
        RAISERROR('Khong the tao log dong bo voi DataPayload rong.', 16, 1);
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM OPENJSON(@DataPayload) AS payload
        WHERE TRY_CONVERT(INT, JSON_VALUE(payload.value, '$.HocSinhID')) IS NULL
    )
    BEGIN
        RAISERROR('Moi dong DataPayload phai co HocSinhID hop le.', 16, 1);
        RETURN;
    END;

    DECLARE @Created TABLE
    (
        SyncDiemLogID BIGINT,
        RequestedAt DATETIMEOFFSET(3)
    );
    DECLARE @RequestedByName NVARCHAR(100);
    SELECT @RequestedByName = NULLIF(
        LTRIM(RTRIM(ISNULL(teacher.HoGV, '') + ' ' + ISNULL(teacher.TenGV, ''))),
        ''
    )
    FROM dbo.tblGiaoVien AS teacher
    WHERE teacher.GiaoVienID = @SYS_USERID;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.tbl_LOG_LMS_SyncDiem
        (
            RequestID, LockActionID, CapID, KhoiID, NienKhoa,
            LopChonID, LopChonTen, MonHocLopID, MonHocID, MonHocCode,
            TemplateBangDiemID, LoaiDiem, HocKy, DataPayload,
            StudentCount, DataRowCount, SyncStatus, RequestedBy, RequestedByName, RequestedAt
        )
        OUTPUT INSERTED.SyncDiemLogID, INSERTED.RequestedAt
            INTO @Created (SyncDiemLogID, RequestedAt)
        VALUES
        (
            @RequestID, @LockActionID, @CapID, @KhoiID, @NienKhoa,
            @LopChonID, @LopChonTen, @MonHocLopID, @MonHocID, @MonHocCode,
            @TemplateBangDiemID, @LoaiDiem, @HocKy, @DataPayload,
            @StudentCount, @DataRowCount, 'Started', @SYS_USERID, @RequestedByName, SYSDATETIMEOFFSET()
        );

        INSERT INTO dbo.tbl_LOG_LMS_SyncDiem_Detail
        (
            SyncDiemLogID, RowNumber, LopID, TenLop, SoDanhBo, HocSinhID,
            MonHocCode, LoaiDiem, ThuTuNhom, ThuTuCotDiem, MaCotDiem,
            KetQua, HocKy, Sort, RequestRowJson
        )
        SELECT
            created.SyncDiemLogID,
            TRY_CONVERT(INT, payload.[key]) + 1,
            JSON_VALUE(payload.value, '$.LopID'),
            JSON_VALUE(payload.value, '$.TenLop'),
            JSON_VALUE(payload.value, '$.SoDanhBo'),
            TRY_CONVERT(INT, JSON_VALUE(payload.value, '$.HocSinhID')),
            JSON_VALUE(payload.value, '$.MonHocCode'),
            JSON_VALUE(payload.value, '$.LoaiDiem'),
            TRY_CONVERT(INT, JSON_VALUE(payload.value, '$.ThuTuNhom')),
            TRY_CONVERT(INT, JSON_VALUE(payload.value, '$.ThuTuCotDiem')),
            JSON_VALUE(payload.value, '$.MaCotDiem'),
            JSON_VALUE(payload.value, '$.KetQua'),
            JSON_VALUE(payload.value, '$.HocKy'),
            TRY_CONVERT(INT, JSON_VALUE(payload.value, '$.Sort')),
            payload.value
        FROM OPENJSON(@DataPayload) AS payload
        CROSS JOIN @Created AS created;

        -- Payload có một dòng cho mỗi ô điểm; chọn nhiều cột thì số dòng lớn hơn số học sinh.
        IF @@ROWCOUNT <> @DataRowCount
        BEGIN
            RAISERROR('Khong tao du dong log chi tiet theo DataPayload.', 16, 1);
        END;

        COMMIT TRANSACTION;

        SELECT
            header.SyncDiemLogID,
            header.RequestID,
            header.SyncStatus,
            header.RequestedBy,
            header.RequestedAt,
            header.StudentCount,
            header.DataRowCount
        FROM dbo.tbl_LOG_LMS_SyncDiem AS header
        INNER JOIN @Created AS created ON created.SyncDiemLogID = header.SyncDiemLogID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
