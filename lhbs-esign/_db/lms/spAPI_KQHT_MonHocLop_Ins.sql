
CREATE PROC [dbo].[spAPI_KQHT_MonHocLop_Ins]
    @NienKhoa           INT
  , @MonHocLopID        INT
  , @LopID              VARCHAR(10)
  , @MonHocID           INT
  , @TemplateBangDiemID INT
  , @MaNhomCotDiem      VARCHAR(200)
  , @KetQuaObjArr       NVARCHAR(MAX)
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tính hợp lệ của JSON đầu vào
    IF ISJSON(@KetQuaObjArr) = 0
    BEGIN
        RAISERROR('Dữ liệu JSON không hợp lệ.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Tạo bảng tạm để lưu trữ dữ liệu từ JSON
        DECLARE @TempKetQua TABLE
        (
            KQHTID           INT
          , KhoaCotDiemID    INT
          , MonHocLopID      INT
          , HocSinhID        INT
          , LopID            VARCHAR(20)
          , NienKhoa         INT
          , CotDiemID        INT
          , KetQuaDanhGia_VI NVARCHAR(1000)
          , KetQuaDanhGia_EN NVARCHAR(1000)
        );

        -- Chèn dữ liệu từ JSON vào bảng tạm
        INSERT INTO @TempKetQua
        SELECT JSON_VALUE(Value, '$.KQHTID')           AS KQHTID
             , JSON_VALUE(Value, '$.KhoaCotDiemID')    AS KhoaCotDiemID
             , @MonHocLopID                            AS MonHocLopID
             , JSON_VALUE(Value, '$.HocSinhID')        AS HocSinhID
             , @LopID                                  AS LopID
             , @NienKhoa                               AS NienKhoa
             , JSON_VALUE(Value, '$.CotDiemID')        AS CotDiemID
             , JSON_VALUE(Value, '$.KetQuaDanhGia_VI') AS KetQuaDanhGia_VI
             , JSON_VALUE(Value, '$.KetQuaDanhGia_EN') AS KetQuaDanhGia_EN
        FROM   OPENJSON(@KetQuaObjArr);

        -- Chỉ eTest gửi marker này khi xử lý phúc khảo; request khác vẫn chặn cột điểm đã khóa.
        DECLARE @AllowLockedScoreOverwrite BIT =
            CASE
                WHEN EXISTS
                (
                    SELECT 1
                    FROM   OPENJSON(@KetQuaObjArr) AS scoreRow
                    WHERE  JSON_VALUE(scoreRow.[value], '$.AllowLockedScoreOverwrite') = '1'
                ) THEN 1
                ELSE 0
            END;

        -- DTB do QLDiem trả về được ghi vào cột DiemTB_HK1/HK2 kể cả khi cột đã khóa.
        -- Marker này không tự khóa cột mới; trạng thái hiện tại được giữ nguyên ở bước cập nhật khóa bên dưới.
        DECLARE @AllowLockedAverageOverwrite BIT =
            CASE
                WHEN EXISTS
                (
                    SELECT 1
                    FROM   OPENJSON(@KetQuaObjArr) AS scoreRow
                    WHERE  JSON_VALUE(scoreRow.[value], '$.AllowLockedAverageOverwrite') = '1'
                ) THEN 1
                ELSE 0
            END;

        IF ISNULL(@AllowLockedAverageOverwrite, 0) = 1
        BEGIN
            -- Chỉ chấp nhận marker nếu mọi dòng trong request đều mang marker, tránh mở khóa cho batch lẫn cột khác.
            IF EXISTS
            (
                SELECT 1
                FROM   OPENJSON(@KetQuaObjArr) AS scoreRow
                WHERE  ISNULL(JSON_VALUE(scoreRow.[value], '$.AllowLockedAverageOverwrite'), '') <> '1'
            )
            BEGIN
                RAISERROR(N'AllowLockedAverageOverwrite phải có trên mọi dòng của request.', 16, 1);
                RETURN;
            END;

            -- Không cho marker DTB dùng để ghi đè các cột điểm khác.
            IF EXISTS
            (
                SELECT 1
                FROM   @TempKetQua AS scoreRow
                       LEFT JOIN dbo.TemplateBangDiemChiTiet AS columnTemplate
                           ON columnTemplate.CotDiemID = scoreRow.CotDiemID
                          AND columnTemplate.Enable = 1
                WHERE  columnTemplate.CotDiemID IS NULL
                   OR  columnTemplate.MaCotDiem NOT IN ('DiemTB_HK1', 'DiemTB_HK2')
            )
            BEGIN
                RAISERROR(N'AllowLockedAverageOverwrite chỉ áp dụng cho DiemTB_HK1 và DiemTB_HK2.', 16, 1);
                RETURN;
            END;
        END;

        -- Mặc định chặn cột đã khóa; chỉ eTest và marker DTB hệ thống mới được ghi giá trị vào cột khóa.
        IF ISNULL(@AllowLockedScoreOverwrite, 0) = 0
           AND ISNULL(@AllowLockedAverageOverwrite, 0) = 0
        BEGIN
            DECLARE @LockedInfo NVARCHAR(MAX) = N'';

            SELECT @LockedInfo = @LockedInfo +
                   N'HocSinhID: '  + CAST(t.HocSinhID AS VARCHAR)  +
                   N' - CotDiemID: ' + CAST(t.CotDiemID AS VARCHAR) +
                   N' - MaCotDiem: ' + ct.MaCotDiem + N'; '
            FROM   @TempKetQua                            t
                   INNER JOIN dbo.tblKetQuaHocTap         kqht ON kqht.KQHTID       = t.KQHTID AND kqht.Enable = 1 AND kqht.NienKhoa = @NienKhoa
                   INNER JOIN dbo.tblKhoaCotDiem          kcd  ON kcd.KhoaCotDiemID  = kqht.KhoaCotDiemID AND kcd.Enable = 1
                   INNER JOIN dbo.TemplateBangDiemChiTiet ct   ON ct.CotDiemID      = t.CotDiemID AND ct.Enable = 1
            WHERE  kcd.TinhTrang = 1;

            IF LEN(@LockedInfo) > 0
            BEGIN
                ROLLBACK TRANSACTION;
                RAISERROR(N'Các cột điểm đã bị khóa, không thể lưu: %s', 16, 1, @LockedInfo);
                RETURN;
            END;
        END;

	 
        -- UPDATE dữ liệu cho các bản ghi đã tồn tại (dựa vào KQHTID)
        IF (@SYS_USERID IN ('NA0000022'))
        BEGIN
            UPDATE target
            SET    target.KetQuaDanhGia_VI = source.KetQuaDanhGia_VI
                 , target.KetQuaDanhGia_EN = source.KetQuaDanhGia_EN
            FROM   dbo.tblKetQuaHocTap    target
                   INNER JOIN @TempKetQua AS source ON target.KQHTID = source.KQHTID;
        END;
        ELSE IF ISNULL(@AllowLockedAverageOverwrite, 0) = 1
        BEGIN
            -- DTB hệ thống không phụ thuộc người nhập ban đầu; giữ NhapDiemUser/Time là dấu vết nhập tay.
            UPDATE target
            SET    target.KetQuaDanhGia_VI = source.KetQuaDanhGia_VI
                 , target.KetQuaDanhGia_EN = source.KetQuaDanhGia_EN
                 , target.UpdateUser       = @SYS_USERID
                 , target.UpdateTime       = GETDATE()
            FROM   dbo.tblKetQuaHocTap    target
                   INNER JOIN @TempKetQua AS source ON target.KQHTID = source.KQHTID;
        END;
        ELSE
        BEGIN
            IF @MonHocID IN (60, 56)
            BEGIN
                UPDATE target
                SET    target.KetQuaDanhGia_VI = source.KetQuaDanhGia_VI
                     , target.KetQuaDanhGia_EN = source.KetQuaDanhGia_EN
                     , target.UpdateUser       = @SYS_USERID
                     , target.UpdateTime       = GETDATE()
                     , target.NhapDiemUser     = @SYS_USERID
                     , target.NhapDiemTime     = GETDATE()
                FROM   dbo.tblKetQuaHocTap    target
                       INNER JOIN @TempKetQua AS source ON target.KQHTID = source.KQHTID
                WHERE  target.NhapDiemUser = @SYS_USERID;
            END;
            ELSE
            BEGIN
                UPDATE target
                SET    target.KetQuaDanhGia_VI = source.KetQuaDanhGia_VI
                     , target.KetQuaDanhGia_EN = source.KetQuaDanhGia_EN
                     , target.UpdateUser       = @SYS_USERID
                     , target.UpdateTime       = GETDATE()
                     , target.NhapDiemUser     = @SYS_USERID
                     , target.NhapDiemTime     = GETDATE()
                FROM   dbo.tblKetQuaHocTap    target
                       INNER JOIN @TempKetQua AS source ON target.KQHTID = source.KQHTID;
            END;
        END;

        -- INSERT dữ liệu cho các bản ghi chưa tồn tại
        INSERT INTO [dbo].[tblKetQuaHocTap]
        (
            MonHocLopID
          , HocSinhID
          , LopID
          , NienKhoa
          , CotDiemID
          , KetQuaDanhGia_VI
          , KetQuaDanhGia_EN
          , Enable
          , [CreateUser]
          , [CreateTime]
          , NhapDiemUser
          , NhapDiemTime
        )
        SELECT mhl.MonHocLopID
             , source.HocSinhID
             , source.LopID
             , source.NienKhoa
             , source.CotDiemID
             , source.KetQuaDanhGia_VI
             , source.KetQuaDanhGia_EN
             , 1
             , @SYS_USERID
             , GETDATE()
             , @SYS_USERID
             , GETDATE()
        FROM   @TempKetQua                            AS source
               INNER JOIN dbo.TemplateBangDiemChiTiet bd  ON source.CotDiemID       = bd.CotDiemID
                                                         AND bd.Enable              = 1
               INNER JOIN dbo.tblMonHocLop            mhl ON mhl.TemplateBangDiemID = bd.TemplateBangDiemID
                                                         AND mhl.LopNhomID          = @LopID
                                                         AND mhl.Enable             = 1
                                                         AND mhl.NienKhoa           = source.NienKhoa
        WHERE  NOT EXISTS
        (
            SELECT 1
            FROM   [dbo].[tblKetQuaHocTap]                a
                   INNER JOIN dbo.TemplateBangDiemChiTiet bd2  ON source.CotDiemID        = bd2.CotDiemID
                                                              AND bd2.Enable              = 1
                   INNER JOIN dbo.tblMonHocLop            mhl2 ON mhl2.TemplateBangDiemID = bd2.TemplateBangDiemID
                                                              AND mhl2.LopNhomID          = @LopID
                                                              AND mhl2.Enable             = 1
                                                              AND mhl2.NienKhoa           = source.NienKhoa
            WHERE  a.HocSinhID   = source.HocSinhID
              AND  a.MonHocLopID  = mhl2.MonHocLopID
              AND  a.CotDiemID    = source.CotDiemID
              AND  a.LopID        = source.LopID
              AND  a.Enable       = 1
        );

        -- Thêm và cập nhật khóa cột điểm
        DECLARE @Table_MaCotDiem TABLE
        (
            CotDiemID     INT
          , MaCotDiem     VARCHAR(200)
          , KhoaCotDiemID INT
        );
        DECLARE @Table_KhoaCotDiemID TABLE
        (
            KhoaCotDiemID INT
        );

        INSERT INTO @Table_MaCotDiem
        SELECT temp.CotDiemID
             , ct.MaCotDiem
             , NULL
        FROM   @TempKetQua                            temp
               INNER JOIN dbo.TemplateBangDiemChiTiet ct ON ct.CotDiemID = temp.CotDiemID
                                                        AND ct.Enable    = 1;

        DECLARE @i         INT = 1;
        DECLARE @Max       INT;
        DECLARE @MaCotDiem VARCHAR(200);

        SELECT @Max = COUNT(*)
        FROM   @Table_MaCotDiem;

        WHILE @i <= @Max
        BEGIN
            DECLARE @IsKhoaCotDiem BIT = 0;

            SELECT @MaCotDiem = MaCotDiem
            FROM
            (
                SELECT MaCotDiem
                     , ROW_NUMBER() OVER (ORDER BY MaCotDiem) AS rn
                FROM   @Table_MaCotDiem
            ) t
            WHERE  rn = @i;

            -- eTest vẫn khóa cột sau lần lưu đầu; marker DTB không vào nhánh này nên giữ nguyên trạng thái hiện tại.
            IF @AllowLockedScoreOverwrite = 1
               AND NOT EXISTS
               (
                   SELECT 1
                   FROM   dbo.tblKhoaCotDiem
                   WHERE  LopID        = @LopID
                     AND  MonHocLopID  = @MonHocLopID
                     AND  MaCotDiem    = @MaCotDiem
                     AND  Enable       = 1
                     AND  TinhTrang    = 1
               )
            BEGIN
                SET @IsKhoaCotDiem = 1;
            END;

            INSERT INTO @Table_KhoaCotDiemID
            EXEC dbo.spAPI_KhoaCotDiem_Ins_And_Upd
                  @LopID         = @LopID
                , @MonHocLopID   = @MonHocLopID
                , @MaCotDiem     = @MaCotDiem
                , @IsKhoaCotDiem = @IsKhoaCotDiem
                , @SYS_USERID    = @SYS_USERID;

            UPDATE tmcd
            SET    tmcd.KhoaCotDiemID =
                   (
                       SELECT TOP 1 KhoaCotDiemID
                       FROM   @Table_KhoaCotDiemID
                   )
            FROM   @Table_MaCotDiem tmcd
            WHERE  tmcd.MaCotDiem = @MaCotDiem;

            SET @i += 1;
            DELETE @Table_KhoaCotDiemID;
        END;

        -- Cập nhật KhoaCotDiemID vào bảng chính
        UPDATE kqht
        SET    KhoaCotDiemID = t.KhoaCotDiemID
        FROM   dbo.tblKetQuaHocTap         kqht
               INNER JOIN @Table_MaCotDiem t ON t.CotDiemID = kqht.CotDiemID
        WHERE  MonHocLopID = @MonHocLopID
          AND  NienKhoa    = @NienKhoa;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;

END;
