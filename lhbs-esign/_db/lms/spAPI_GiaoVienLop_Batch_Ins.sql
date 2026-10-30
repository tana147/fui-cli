CREATE PROCEDURE [dbo].[spAPI_GiaoVienLop_Batch_Ins]
    @PhanCongInput NVARCHAR(MAX),
    @Sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra JSON hợp lệ
    IF ISJSON(@PhanCongInput) = 0
    BEGIN
        RAISERROR('JSON không hợp lệ', 16, 1);
        RETURN;
    END

    -- Bảng tạm để lưu dữ liệu từ JSON
    DECLARE @TempGiaoVienLop TABLE (
        GiaoVienID VARCHAR(10),
        KhoiID INT,
        LopID VARCHAR(9),
        MonHocID INT,
        MaDonVi INT,
        [Enable] BIT,
        VaiTro INT,
        NienKhoa INT,
        ToGiangDayID INT,
        GhiChu NVARCHAR(500),
        RowNum INT,
        IsUnique BIT DEFAULT 1,
        HocKy INT
    );

    -- Bảng để lưu các bản ghi bị trùng
    DECLARE @DuplicateRecords TABLE (
        GiaoVienID VARCHAR(10),
        KhoiID INT,
        LopID VARCHAR(9),
        MonHocID INT,
        VaiTro INT,
        NienKhoa INT,
        DuplicateReason NVARCHAR(255),
        HocKy INT
    );

    -- Parse JSON và insert vào bảng tạm
    ;WITH JsonCTE AS (
        SELECT 
            JSON_VALUE(value, '$.GiaoVienID') AS GiaoVienID,
            CAST(JSON_VALUE(value, '$.KhoiID') AS INT) AS KhoiID,
            CAST(
                CASE 
                    WHEN CAST(JSON_VALUE(value, '$.VaiTro') AS INT) = 2 
                    THEN '0'  
                    ELSE JSON_VALUE(value, '$.LopID') 
                END 
            AS VARCHAR(9)) AS LopID,
            CASE 
                WHEN CAST(JSON_VALUE(value, '$.VaiTro') AS INT) = 2 
                THEN 0 
                ELSE CAST(JSON_VALUE(value, '$.MonHocID') AS INT) 
            END AS MonHocID,
            CAST(JSON_VALUE(value, '$.MaDonVi') AS INT) AS MaDonVi,
            CAST(JSON_VALUE(value, '$.Enable') AS BIT) AS [Enable],
            CAST(JSON_VALUE(value, '$.VaiTro') AS INT) AS VaiTro,
            CAST(JSON_VALUE(value, '$.NienKhoa') AS INT) AS NienKhoa,
            CAST(JSON_VALUE(value, '$.ToGiangDayID') AS INT) AS ToGiangDayID,
            JSON_VALUE(value, '$.GhiChu') AS GhiChu,
            CAST(JSON_VALUE(value, '$.HocKi') AS INT) AS HocKy,
            ROW_NUMBER() OVER (
                PARTITION BY 
                    JSON_VALUE(value, '$.GiaoVienID'), 
                    JSON_VALUE(value, '$.LopID'), 
                    JSON_VALUE(value, '$.VaiTro'),
                    JSON_VALUE(value, '$.HocKi')
                ORDER BY (SELECT NULL)
            ) AS RowNum
        FROM OPENJSON(@PhanCongInput)
    )
    INSERT INTO @TempGiaoVienLop(
        GiaoVienID, KhoiID, LopID, MonHocID, 
        MaDonVi, [Enable], VaiTro, NienKhoa, 
        ToGiangDayID, GhiChu, RowNum, HocKy
    )
    SELECT 
        GiaoVienID, KhoiID, LopID, MonHocID, 
        MaDonVi, [Enable], VaiTro, NienKhoa, 
        ToGiangDayID, GhiChu, RowNum, HocKy
    FROM JsonCTE;

    -- Với phân công theo lớp, KhoiID chuẩn phải lấy từ tblLop theo LopID và niên khóa.
    -- Không dùng mù giá trị KhoiID từ client để ngăn dữ liệu bị ghi nhầm sang khối khác.
    UPDATE t
    SET t.KhoiID = l.KhoiID
    FROM @TempGiaoVienLop AS t
    INNER JOIN dbo.tblLop AS l
        ON l.LopID = t.LopID
       AND l.NienKhoa = t.NienKhoa
       AND l.Enable = 1
    WHERE t.VaiTro IN (1, 3)
      AND t.LopID <> '0';

    -- Kiểm tra nếu không có dữ liệu hợp lệ
    IF NOT EXISTS (SELECT 1 FROM @TempGiaoVienLop)
    BEGIN
        RAISERROR('Không có dữ liệu hợp lệ để thêm mới', 16, 1);
        RETURN;
    END

    -- Kiểm tra trùng lặp với các điều kiện chi tiết
    ;WITH DuplicateCheck AS (
        SELECT 
            t.GiaoVienID, 
            t.KhoiID, 
            t.LopID, 
            t.MonHocID,
            t.VaiTro,
            t.NienKhoa,
            t.HocKy,
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM dbo.tblGiaoVienLop gvl 
                    WHERE gvl.GiaoVienID = t.GiaoVienID 
                      AND gvl.KhoiID = t.KhoiID 
                      AND gvl.LopID = t.LopID 
                      AND gvl.MonHocID = t.MonHocID 
                      AND gvl.VaiTro = t.VaiTro 
                      AND gvl.NienKhoa = t.NienKhoa
                      AND gvl.HocKy = t.HocKy
                      AND gvl.Enable = 1
                ) THEN 1
                ELSE 0
            END AS IsDuplicate,
            'Trùng toàn bộ thông tin' AS DuplicateReason
        FROM @TempGiaoVienLop t
    )
    -- Cập nhật trạng thái trùng lặp và ghi lại các bản ghi trùng
    UPDATE t
    SET IsUnique = CASE WHEN dc.IsDuplicate = 1 THEN 0 ELSE 1 END
    OUTPUT 
        DELETED.GiaoVienID, 
        DELETED.KhoiID, 
        DELETED.LopID, 
        DELETED.MonHocID,
        DELETED.VaiTro,
        DELETED.NienKhoa,
        dc.DuplicateReason,
        DELETED.HocKy
    INTO @DuplicateRecords
    FROM @TempGiaoVienLop t
    INNER JOIN DuplicateCheck dc ON 
        t.GiaoVienID = dc.GiaoVienID AND
        t.KhoiID = dc.KhoiID AND
        t.LopID = dc.LopID AND
        t.MonHocID = dc.MonHocID AND
        t.VaiTro = dc.VaiTro AND
        t.NienKhoa = dc.NienKhoa AND
        t.HocKy = dc.HocKy
    WHERE dc.IsDuplicate = 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- In ra các bản ghi trùng để kiểm tra
        PRINT '==== DANH SÁCH BẢN GHI TRÙNG ====';
        SELECT 
            GiaoVienID, 
            KhoiID, 
            LopID, 
            MonHocID,
            VaiTro, 
            NienKhoa,
            DuplicateReason,
            HocKy
        FROM @DuplicateRecords;

        -- Insert dữ liệu mới (chỉ những bản ghi chưa trùng)
        INSERT INTO [dbo].[tblGiaoVienLop](
            GiaoVienID, KhoiID, LopID, MonHocID, 
            MaDonVi, [Enable], VaiTro, NienKhoa, 
            ToGiangDayID, GhiChu, CreateUser, CreateTime, HocKy
        )
        SELECT 
            GiaoVienID, KhoiID, LopID, MonHocID, 
            MaDonVi, [Enable], VaiTro, NienKhoa, 
            ToGiangDayID, GhiChu, @Sys_UserID, GETDATE(), HocKy
        FROM @TempGiaoVienLop
        WHERE RowNum = 1 AND IsUnique = 1;

        -- Kiểm tra số dòng đã thêm
        DECLARE @InsertedRows INT = @@ROWCOUNT;
        
        IF @InsertedRows = 0
        BEGIN
            PRINT 'Không có dòng mới nào được thêm - Tất cả đều trùng lặp';
            ROLLBACK TRANSACTION;
            RAISERROR('Không có dòng mới nào được thêm', 16, 1);
            RETURN;
        END
        ELSE
        BEGIN
            PRINT CONCAT('Đã thêm mới ', @InsertedRows, ' dòng');
        END

        -- ĐỒNG BỘ GVCN SANG BẢNG tblLop:
        -- Nếu trong các bản ghi được insert có phân công GVCN (VaiTro = 1), cập nhật tblLop.GVCN
        UPDATE L
        SET L.GVCN = T.GiaoVienID,
            L.UpdateUser = @Sys_UserID,
            L.UpdateTime = GETDATE()
        FROM dbo.tblLop L
        INNER JOIN @TempGiaoVienLop T ON L.LopID = T.LopID AND L.NienKhoa = T.NienKhoa
        WHERE T.VaiTro = 1 AND T.RowNum = 1 AND T.IsUnique = 1;

        COMMIT TRANSACTION;

        -- Trả về số dòng đã thêm và danh sách các bản ghi bị trùng
        SELECT 
            @InsertedRows AS InsertedRowCount,
            (SELECT COUNT(*) FROM @DuplicateRecords) AS DuplicateRowCount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Xử lý lỗi và trả về thông báo lỗi
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
