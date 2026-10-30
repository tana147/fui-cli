-- [dbo].[spAPI_KQHT_MonHocLop_Ins] 3015, 'N241001', 76, 78, N'[{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1859,"KetQuaDanhGia_VI":10,"KetQuaDanhGia_EN":10,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1860,"KetQuaDanhGia_VI":10,"KetQuaDanhGia_EN":10,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1861,"KetQuaDanhGia_VI":8,"KetQuaDanhGia_EN":8,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1862,"KetQuaDanhGia_VI":10,"KetQuaDanhGia_EN":10,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1863,"KetQuaDanhGia_VI":10,"KetQuaDanhGia_EN":10,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1864,"KetQuaDanhGia_VI":9,"KetQuaDanhGia_EN":9,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1865,"KetQuaDanhGia_VI":7,"KetQuaDanhGia_EN":7,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1866,"KetQuaDanhGia_VI":0.3,"KetQuaDanhGia_EN":0.3,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1867,"KetQuaDanhGia_VI":0.5,"KetQuaDanhGia_EN":0.5,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":24300016,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1868,"KetQuaDanhGia_VI":0,"KetQuaDanhGia_EN":0,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1859,"KetQuaDanhGia_VI":5,"KetQuaDanhGia_EN":5,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1860,"KetQuaDanhGia_VI":10,"KetQuaDanhGia_EN":10,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1861,"KetQuaDanhGia_VI":10,"KetQuaDanhGia_EN":10,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1862,"KetQuaDanhGia_VI":10,"KetQuaDanhGia_EN":10,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1863,"KetQuaDanhGia_VI":10,"KetQuaDanhGia_EN":10,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1864,"KetQuaDanhGia_VI":9,"KetQuaDanhGia_EN":9,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1865,"KetQuaDanhGia_VI":9,"KetQuaDanhGia_EN":9,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1866,"KetQuaDanhGia_VI":0.5,"KetQuaDanhGia_EN":0.5,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1867,"KetQuaDanhGia_VI":0.5,"KetQuaDanhGia_EN":0.5,"Is_Reject":"","ReasonReject":"","IsError":0},{"HocSinhID":17100225,"LopID":"N241001","NienKhoa":2024,"CotDiemID":1868,"KetQuaDanhGia_VI":0,"KetQuaDanhGia_EN":0,"Is_Reject":"","ReasonReject":"","IsError":0}]', 'NA0000022', 9

CREATE PROC [dbo].[spAPI_KQHT_MonHocLop_Ins_BK]
    @NienKhoa           INT = 2024
  , @MonHocLopID        INT
  , @LopID              VARCHAR(10)
  , @MonHocID           INT
  , @TemplateBangDiemID INT
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
            KQHTID           INT -- Giả sử KQHTID là kiểu INT, điều chỉnh kiểu dữ liệu nếu cần
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
             , @MonHocLopID                            AS MonHocLopID
             , JSON_VALUE(Value, '$.HocSinhID')        AS HocSinhID
             , @LopID                                  AS LopID
             , @NienKhoa                               AS NienKhoa
             , JSON_VALUE(Value, '$.CotDiemID')        AS CotDiemID
             , JSON_VALUE(Value, '$.KetQuaDanhGia_VI') AS KetQuaDanhGia_VI
             , JSON_VALUE(Value, '$.KetQuaDanhGia_EN') AS KetQuaDanhGia_EN
        FROM
               OPENJSON(@KetQuaObjArr);

        --60 Lịch sử và Địa lí
        --56 Khoa học tự nhiên

        --UPDATE dữ liệu cho các bản ghi đã tồn tại (dựa vào KQHTID)
        IF (@SYS_USERID IN ('NA0000022'))
        BEGIN
            UPDATE target
            SET    target.KetQuaDanhGia_VI = source.KetQuaDanhGia_VI
                 , target.KetQuaDanhGia_EN = source.KetQuaDanhGia_EN
            FROM
                   dbo.tblKetQuaHocTap    target
                   INNER JOIN @TempKetQua AS source ON target.KQHTID = source.KQHTID;
        END;
        ELSE
        BEGIN
            IF @MonHocID IN (60, 56)
            BEGIN
                UPDATE target
                SET    target.KetQuaDanhGia_VI = source.KetQuaDanhGia_VI
                     , target.KetQuaDanhGia_EN = source.KetQuaDanhGia_EN
                     , target.UpdateUser = @SYS_USERID
                     , target.UpdateTime = GETDATE()
                     , target.NhapDiemUser = @SYS_USERID
                     , target.NhapDiemTime = GETDATE()
                FROM
                       dbo.tblKetQuaHocTap    target
                       INNER JOIN @TempKetQua AS source ON target.KQHTID = source.KQHTID
                WHERE
                       target.NhapDiemUser = @SYS_USERID;
            END;
            ELSE
            BEGIN
                UPDATE target
                SET    target.KetQuaDanhGia_VI = source.KetQuaDanhGia_VI
                     , target.KetQuaDanhGia_EN = source.KetQuaDanhGia_EN
                     , target.UpdateUser = @SYS_USERID
                     , target.UpdateTime = GETDATE()
                     , target.NhapDiemUser = @SYS_USERID
                     , target.NhapDiemTime = GETDATE()
                FROM
                       dbo.tblKetQuaHocTap    target
                       INNER JOIN @TempKetQua AS source ON target.KQHTID = source.KQHTID;
            END;
        END;




        --INSERT dữ liệu cho các bản ghi chưa tồn tại
        --(Khi KQHTID là NULL hoặc không tồn tại trong bảng)
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
             , 1 -- Enable
             , @SYS_USERID
             , GETDATE()
             , @SYS_USERID
             , GETDATE()
        FROM
               @TempKetQua                            AS source
               INNER JOIN dbo.TemplateBangDiemChiTiet bd ON source.CotDiemID        = bd.CotDiemID
                                                        AND bd.Enable               = 1
               INNER JOIN dbo.tblMonHocLop            mhl ON mhl.TemplateBangDiemID = bd.TemplateBangDiemID
                                                         AND mhl.LopNhomID          = @LopID
                                                         AND mhl.Enable             = 1
                                                         AND mhl.NienKhoa           = source.NienKhoa
        WHERE
               NOT EXISTS
        (
            SELECT 1
            FROM
                   [dbo].[tblKetQuaHocTap]                a
                   INNER JOIN dbo.TemplateBangDiemChiTiet bd ON source.CotDiemID        = bd.CotDiemID
                                                            AND bd.Enable               = 1
                   INNER JOIN dbo.tblMonHocLop            mhl ON mhl.TemplateBangDiemID = bd.TemplateBangDiemID
                                                             AND mhl.LopNhomID          = @LopID
                                                             AND mhl.Enable             = 1
                                                             AND mhl.NienKhoa           = source.NienKhoa
            WHERE
                   a.HocSinhID  = source.HocSinhID
              AND  a.MonHocLopID = mhl.MonHocLopID
              AND  a.CotDiemID   = source.CotDiemID
              AND  a.LopID       = source.LopID
              AND  a.Enable      = 1
        );

        --DECLARE @tblFormula TABLE
        --(
        --    CotDiemID     INT
        --  , GiaTriCotDiem NVARCHAR(50)
        --  , Formula       NVARCHAR(MAX)
        --);
        --INSERT INTO @tblFormula
        --(
        --    CotDiemID
        --  , GiaTriCotDiem
        --  , Formula
        --)
        --SELECT CotDiemID
        --     , GiaTriCotDiem
        --     , Formula
        --FROM
        --       dbo.TemplateBangDiemChiTiet
        --WHERE
        --       TemplateBangDiemID = @TemplateBangDiemID
        --  AND  LoaiCotDiem         = N'Công thức'
        --ORDER BY
        --       ThuTuNhom
        --     , ThuTuCotDiem;

        ---- Lấy danh sách học sinh từ JSON
        --DECLARE @HocSinhList TABLE
        --(
        --    HocSinhID INT
        --);
        --INSERT INTO @HocSinhList
        --(
        --    HocSinhID
        --)
        --SELECT DISTINCT
        --       JSON_VALUE(Value, '$.HocSinhID')
        --FROM
        --       OPENJSON(@KetQuaObjArr);

        ---- Biến để xử lý logic
        --DECLARE @HocSinhID INT;
        --DECLARE @CotDiemID INT;
        --DECLARE @GiaTriCotDiem NVARCHAR(50);
        --DECLARE @Formula NVARCHAR(MAX);
        --DECLARE @Result NVARCHAR(MAX);
        --DECLARE @ResultFormular NVARCHAR(MAX);

        ---- Lặp qua từng cột công thức
        --DECLARE FormulaCursor CURSOR FOR
        --SELECT CotDiemID
        --     , GiaTriCotDiem
        --     , Formula
        --FROM
        --       @tblFormula;

        --OPEN FormulaCursor;
        --FETCH NEXT FROM FormulaCursor
        --INTO @CotDiemID
        --   , @GiaTriCotDiem
        --   , @Formula;

        --WHILE @@FETCH_STATUS = 0
        --BEGIN
        --    -- Lặp qua từng học sinh
        --    DECLARE HocSinhCursor CURSOR FOR SELECT HocSinhID FROM @HocSinhList;

        --    OPEN HocSinhCursor;
        --    FETCH NEXT FROM HocSinhCursor
        --    INTO @HocSinhID;

        --    WHILE @@FETCH_STATUS = 0
        --    BEGIN
        --        -- Gọi thủ tục Pro_GetMark để tính toán
        --        DECLARE @TinhTrang_CotDiem INT;
        --        SET @TinhTrang_CotDiem =
        --        (
        --            SELECT ISNULL(TinhTrang, 0)
        --            FROM
        --                   dbo.tblKetQuaHocTap KQ
        --            WHERE
        --                   KQ.HocSinhID = @HocSinhID
        --              AND  MonHocLopID   = @MonHocLopID
        --              AND  CotDiemID     = @CotDiemID
        --        );
        --        IF @TinhTrang_CotDiem < 2 --NẾU CỘT ĐÓ ĐÃ CHỐT ĐIỂM THÌ KO UPDATE NỮA
        --        BEGIN
        --            EXEC dbo.Pro_GetMark @formular = @Formula
        --                               , @giaTriCotDiem = @GiaTriCotDiem
        --                               , @studentId = @HocSinhID
        --                               , @lopid = @LopID
        --                               , @monhoclopid = @MonHocLopID
        --                               , @templatebangdiemid = @TemplateBangDiemID
        --                               , @Result = @Result OUTPUT
        --                               , @ResultFormular = @ResultFormular OUTPUT;

        --            -- Cập nhật kết quả vào bảng tblKetQuaHocTap
        --            UPDATE dbo.tblKetQuaHocTap
        --            SET    KetQuaDanhGia_VI = @Result
        --                 , UpdateTime = GETDATE()
        --                 , UpdateUser = @SYS_USERID
        --            WHERE
        --                   HocSinhID  = @HocSinhID
        --              AND  CotDiemID   = @CotDiemID
        --              AND  LopID       = @LopID
        --              AND  MonHocLopID = @MonHocLopID;
        --            IF @@ROWCOUNT = 0
        --            BEGIN
        --                INSERT INTO dbo.tblKetQuaHocTap
        --                (
        --                    [MonHocLopID]
        --                  , [HocSinhID]
        --                  , [LopID]
        --                  , [NienKhoa]
        --                  , [CotDiemID]
        --                  , [KetQuaDanhGia_VI]
        --                  , [KetQuaDanhGia_EN]
        --                  , [CreateUser]
        --                  , CreateTime
        --                )
        --                VALUES
        --                (
        --                    @MonHocLopID
        --                  , @HocSinhID
        --                  , @LopID
        --                  , @NienKhoa
        --                  , @CotDiemID
        --                  , @Result
        --                  , @Result
        --                  , @SYS_USERID
        --                  , GETDATE()
        --                );
        --            END;

        --        END;


        --        FETCH NEXT FROM HocSinhCursor
        --        INTO @HocSinhID;
        --    END;

        --    CLOSE HocSinhCursor;
        --    DEALLOCATE HocSinhCursor;

        --    FETCH NEXT FROM FormulaCursor
        --    INTO @CotDiemID
        --       , @GiaTriCotDiem
        --       , @Formula;
        --END;

        --CLOSE FormulaCursor;
        --DEALLOCATE FormulaCursor;

        -- Commit giao dịch
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback giao dịch nếu có lỗi
        ROLLBACK TRANSACTION;

        -- Log lỗi nếu cần
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;

END;