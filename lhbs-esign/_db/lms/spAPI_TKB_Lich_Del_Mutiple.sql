CREATE PROCEDURE dbo.spAPI_TKB_Lich_Del_Mutiple
    @JsonIDs NVARCHAR(MAX),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'Bạn không có quyền chỉnh sửa thời khóa biểu.', 16, 1);
        RETURN;
    END;
    IF ISJSON(@JsonIDs) <> 1
    BEGIN
        RAISERROR(N'Danh sách tiết cần xóa không hợp lệ.', 16, 1);
        RETURN;
    END;

    DECLARE @IDs TABLE (TKBLichID INT NOT NULL PRIMARY KEY);
    INSERT INTO @IDs(TKBLichID)
    SELECT DISTINCT TRY_CONVERT(INT, CASE WHEN LEFT(LTRIM([value]), 1) = '{'
        THEN JSON_VALUE([value], '$.TKBLichID') ELSE [value] END)
    FROM OPENJSON(@JsonIDs)
    WHERE TRY_CONVERT(INT, CASE WHEN LEFT(LTRIM([value]), 1) = '{'
        THEN JSON_VALUE([value], '$.TKBLichID') ELSE [value] END) IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM @IDs)
    BEGIN
        RAISERROR(N'Không có tiết hợp lệ để xóa.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @LockResult INT;
        EXEC @LockResult = sys.sp_getapplock
            @Resource = N'TKB-PRESCHOOL-SCHEDULE-WRITE',
            @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
        IF @LockResult < 0 RAISERROR(N'Không khóa được lịch để kiểm tra. Vui lòng thử lại.', 16, 1);

        IF EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich AS D WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN @IDs AS I ON I.TKBLichID = D.TKBLichID
            INNER JOIN dbo.tblTKB_Lich AS L WITH (UPDLOCK, HOLDLOCK)
                ON L.NienKhoa = D.NienKhoa AND L.MaDonVi = D.MaDonVi
               AND ((L.LopHocID = D.LopHocID) OR (L.LopHocID IS NULL AND L.Lop = D.Lop))
               AND L.Thu = D.Thu AND L.BuoiID = 2 AND L.Tiet >= 2
               AND (L.TuanID IS NULL OR L.TuanID = 0 OR D.TuanID IS NULL OR L.TuanID = D.TuanID)
            WHERE ISNULL(D.CapHoc, 0) = 0 AND D.BuoiID = 2 AND D.Tiet = 1
              AND NOT EXISTS (SELECT 1 FROM @IDs AS X WHERE X.TKBLichID = L.TKBLichID)
        )
            RAISERROR(N'Không thể xóa Hoạt động khác khi lớp vẫn còn tiết chiều phía sau.', 16, 1);

        IF EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich AS D WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN @IDs AS I ON I.TKBLichID = D.TKBLichID
            INNER JOIN dbo.tblTKB_Lich AS L WITH (UPDLOCK, HOLDLOCK)
                ON L.NienKhoa = D.NienKhoa AND L.MaDonVi = D.MaDonVi
               AND ((L.LopHocID = D.LopHocID) OR (L.LopHocID IS NULL AND L.Lop = D.Lop))
               AND L.Thu = D.Thu AND L.BuoiID = 2 AND L.Tiet > 2
               AND (L.TuanID IS NULL OR L.TuanID = 0 OR D.TuanID IS NULL OR L.TuanID = D.TuanID)
            WHERE ISNULL(D.CapHoc, 0) = 0 AND D.BuoiID = 2 AND D.Tiet = 2
              AND NOT EXISTS (SELECT 1 FROM @IDs AS X WHERE X.TKBLichID = L.TKBLichID)
        )
            RAISERROR(N'Không thể xóa tiết học thứ 2 khi lớp vẫn còn tiết chiều phía sau.', 16, 1);

        DELETE L FROM dbo.tblTKB_Lich AS L INNER JOIN @IDs AS I ON I.TKBLichID = L.TKBLichID;
        DECLARE @DeletedCount INT = @@ROWCOUNT;
        COMMIT TRANSACTION;
        SELECT @DeletedCount AS DeletedCount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH;
END
