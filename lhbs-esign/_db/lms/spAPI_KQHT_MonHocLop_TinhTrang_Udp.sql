CREATE PROC [dbo].[spAPI_KQHT_MonHocLop_TinhTrang_Udp]
	@NienKhoa INT,
    --@HocSinhID       INT
    @MonHocLopID      INT
  , @LopID            VARCHAR(10)
  , @TinhTrang        INT
  --, @Semester        VARCHAR(10)
  , @List_MonHocLopID VARCHAR(100) NULL
  , @Suffix_Semester  VARCHAR(10)
  , @MaNhomCotDiem    NVARCHAR(100)
  , @ReasonReject     NVARCHAR(4000)
  , @SYS_UserID       VARCHAR(9)
AS
BEGIN
    --0: Chưa lưu, 
    --1: Lưu tạm, 
    --2: GVBM gửi điểm, 
    --3: GVCN từ chối gửi điểm bộ môn, 
    --4: GVCN gửi điểm, 
    --5: Tổ trưởng từ chối, 
    --6: Tổ trưởng Gửi BGH, 
    --7: BGH từ chối, 
    --8: BGH duyệt (Công bố phụ huynh)

    --1: Lưu tạm, --2: GVBM gửi điểm, 
    IF (
           @TinhTrang = 1
      OR   @TinhTrang = 2
       )
    BEGIN

        --Chỉnh các Tình trạng trước cho Enable = 0
        UPDATE dbo.tblLop_TinhTrang
        SET    Enable = 0
             , UpdateUser = @SYS_UserID
             , UpdateTime = GETDATE()
        WHERE
               LopID        = @LopID
          AND  TinhTrang     = @TinhTrang
          AND  MonHocLopID   = @MonHocLopID
          AND  MaNhomCotDiem = @MaNhomCotDiem;

        DECLARE @Table_Lop_TinhTrang TABLE
        (
            Lop_TinhTrangID INT
        );

        DECLARE @Is_GVCN_DaDuyet BIT = 0;
        IF EXISTS
        (
            SELECT *
            FROM
                   dbo.tblLop_TinhTrang
            WHERE
                   LopID          = @LopID
              AND  MaNhomCotDiem   = @MaNhomCotDiem
              AND  Is_GVCN_DaDuyet = 1
              AND  Enable          = 1
        )
        BEGIN
            SET @Is_GVCN_DaDuyet = 1;
        END;

        INSERT INTO dbo.tblLop_TinhTrang
        (
            LopID
          , MonHocLopID
          , MaNhomCotDiem
          , TinhTrang
          , NoiDungNhanXet
          , Is_GVCN_DaDuyet
          , Enable
          , CreateUser
          , CreateTime
        )
        OUTPUT Inserted.Lop_TinhTrangID
        INTO @Table_Lop_TinhTrang
        VALUES
        (
            @LopID         -- LopID - int
          , @MonHocLopID   -- MonHocLopID - int
          , @MaNhomCotDiem -- MaNhomCotDiem - varchar(100)
          , CASE
                 WHEN @Is_GVCN_DaDuyet = 1
                  AND EXISTS
    (
        SELECT *
        FROM
               dbo.tblGiaoVienLop
        WHERE
               GiaoVienID = @SYS_UserID
          AND  LopID       = @LopID
          AND  MonHocID IN
               (
                   SELECT MonHocID
                   FROM
                         dbo.tblMonHocLop
                   WHERE
                         MonHocLopID = @MonHocLopID
               )
          AND  VaiTro      = 1
    )     THEN       4
                 WHEN @Is_GVCN_DaDuyet = 1
                  AND EXISTS
    (
        SELECT *
        FROM
               dbo.tblGiaoVienLop
        WHERE
               GiaoVienID = @SYS_UserID
          AND  LopID       = @LopID
          AND  MonHocID IN
               (
                   SELECT MonHocID
                   FROM
                         dbo.tblMonHocLop
                   WHERE
                         MonHocLopID = @MonHocLopID
               )
          AND  VaiTro      = 3
    )     THEN       2
                 ELSE @TinhTrang
            END            -- TinhTrang - int
          , @ReasonReject  -- NoiDungNhanXet - nvarchar(4000)
          , @Is_GVCN_DaDuyet
          , 1
          , @SYS_UserID    -- CreateUser - varchar(9)
          , GETDATE()      -- CreateTime - datetime
        );

        UPDATE kqht
        SET    kqht.Lop_TinhTrangID =
               (
                   SELECT TOP 1
                          Lop_TinhTrangID
                   FROM
                          @Table_Lop_TinhTrang
               )
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID     = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem = @MaNhomCotDiem
                                                          AND t.Enable        = 1
        WHERE
               kqht.NienKhoa   = @NienKhoa
          AND  kqht.LopID       = @LopID
          AND  kqht.MonHocLopID = @MonHocLopID
          AND  kqht.Enable      = 1;
    END;

    --3: GVCN từ chối gửi điểm bộ môn, 
    IF (@TinhTrang = 3)
    BEGIN 
        --Chỉnh các Tình trạng trước cho Enable = 0
        UPDATE dbo.tblLop_TinhTrang
        SET    Enable = 0
             , UpdateUser = @SYS_UserID
             , UpdateTime = GETDATE()
        WHERE
               LopID    = @LopID
          AND  TinhTrang = @TinhTrang;

        DECLARE @Table_Lop_TinhTrang_3 TABLE
        (
            Lop_TinhTrangID INT
        );

        INSERT INTO dbo.tblLop_TinhTrang
        (
            LopID
          , MonHocLopID
          , MaNhomCotDiem
          , TinhTrang
          , NoiDungNhanXet
          , Is_GVCN_DaDuyet
          , Enable
          , CreateUser
          , CreateTime
        )
        OUTPUT Inserted.Lop_TinhTrangID
        INTO @Table_Lop_TinhTrang_3
        SELECT DISTINCT
               kqht.LopID
             , kqht.MonHocLopID
             , t.MaNhomCotDiem
             , @TinhTrang
             , @ReasonReject
             , null
             , 1
             , @SYS_UserID
             , GETDATE()
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.MonHocLopID IN
               (
                   SELECT value
                   FROM
                         STRING_SPLIT(@List_MonHocLopID, ',') AS value
               ) -- Bên giao diện chỉ cần chọn 1 số môn lớp để gắn TinhTrang chứ ko cần phải gắn tình trạng hết môn
          AND  kqht.Enable    = 1;

        UPDATE kqht
        SET    kqht.Lop_TinhTrangID = t5.Lop_TinhTrangID
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
               INNER JOIN dbo.tblLop_TinhTrang        AS t5 ON t5.LopID         = kqht.LopID
                                                           AND t5.MonHocLopID   = kqht.MonHocLopID
                                                           AND t5.MonHocLopID   = mhl.MonHocLopID
                                                           AND t5.MaNhomCotDiem = t.MaNhomCotDiem
                                                           AND t5.TinhTrang     = @TinhTrang
                                                           AND t5.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.MonHocLopID IN
               (
                   SELECT value
                   FROM
                         STRING_SPLIT(@List_MonHocLopID, ',') AS value
               ) -- Bên giao diện chỉ cần chọn 1 số môn lớp để gắn TinhTrang chứ ko cần phải gắn tình trạng hết môn
          AND  kqht.Enable    = 1;
    END;

    --4: GVCN gửi điểm, 
    IF (@TinhTrang = 4)
    BEGIN
        --Chỉnh các Tình trạng trước cho Enable = 0
        UPDATE dbo.tblLop_TinhTrang
        SET    Enable = 0
             , UpdateUser = @SYS_UserID
             , UpdateTime = GETDATE()
        WHERE
               LopID    = @LopID
          AND  TinhTrang = @TinhTrang;

        -- Tạo bảng tạm để lưu ID của các bản ghi mới
        DECLARE @Table_Lop_TinhTrang_4 TABLE
        (
            Lop_TinhTrangID INT
        );

        -- Chèn dữ liệu mới vào tblLop_TinhTrang và lấy ID vào bảng tạm
        INSERT INTO dbo.tblLop_TinhTrang
        (
            LopID
          , MonHocLopID
          , MaNhomCotDiem
          , TinhTrang
          , NoiDungNhanXet
          , Is_GVCN_DaDuyet
          , Enable
          , CreateUser
          , CreateTime
        )
        OUTPUT Inserted.Lop_TinhTrangID
        INTO @Table_Lop_TinhTrang_4
        SELECT DISTINCT
               kqht.LopID
             , kqht.MonHocLopID
             , t.MaNhomCotDiem
             , @TinhTrang
             , NULL
             , 1
             , 1
             , @SYS_UserID
             , GETDATE()
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.Enable    = 1;

        -- Cập nhật Lop_TinhTrangID vào tblKetQuaHocTap
        UPDATE kqht
        SET    kqht.Lop_TinhTrangID = t4.Lop_TinhTrangID
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
               INNER JOIN dbo.tblLop_TinhTrang        AS t4 ON t4.LopID         = kqht.LopID
                                                           AND t4.MonHocLopID   = kqht.MonHocLopID
                                                           AND t4.MonHocLopID   = mhl.MonHocLopID
                                                           AND t4.MaNhomCotDiem = t.MaNhomCotDiem
                                                           AND t4.TinhTrang     = @TinhTrang
                                                           AND t4.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.Enable    = 1;
    END;

    --5: Tổ trưởng từ chối, => Do Tổ trưởng gửi hoặc từ chối là hết tất cả các môn của 1 lớp
    IF (@TinhTrang = 5)
    BEGIN
        --Chỉnh các Tình trạng trước cho Enable = 0
        UPDATE dbo.tblLop_TinhTrang
        SET    Enable = 0
             , UpdateUser = @SYS_UserID
             , UpdateTime = GETDATE()
        WHERE
               LopID    = @LopID
          AND  TinhTrang = @TinhTrang;

        -- Tạo bảng tạm để lưu ID của các bản ghi mới
        DECLARE @Table_Lop_TinhTrang_5 TABLE
        (
            Lop_TinhTrangID INT
        );

        -- Chèn dữ liệu mới vào tblLop_TinhTrang và lấy ID vào bảng tạm
        INSERT INTO dbo.tblLop_TinhTrang
        (
            LopID
          , MonHocLopID
          , MaNhomCotDiem
          , TinhTrang
          , NoiDungNhanXet
          , Is_GVCN_DaDuyet
          , Enable
          , CreateUser
          , CreateTime
        )
        OUTPUT Inserted.Lop_TinhTrangID
        INTO @Table_Lop_TinhTrang_5
        SELECT DISTINCT
               kqht.LopID
             , kqht.MonHocLopID
             , t.MaNhomCotDiem
             , @TinhTrang
             , @ReasonReject
             , 1
             , 1
             , @SYS_UserID
             , GETDATE()
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.MonHocLopID IN
               (
                   SELECT value
                   FROM
                         STRING_SPLIT(@List_MonHocLopID, ',') AS value
               ) -- Bên giao diện chỉ cần chọn 1 số môn lớp để gắn TinhTrang chứ ko cần phải gắn tình trạng hết môn
          AND  kqht.Enable    = 1;

        -- Cập nhật Lop_TinhTrangID vào tblKetQuaHocTap
        UPDATE kqht
        SET    kqht.Lop_TinhTrangID = t5.Lop_TinhTrangID
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
               INNER JOIN dbo.tblLop_TinhTrang        AS t5 ON t5.LopID         = kqht.LopID
                                                           AND t5.MonHocLopID   = kqht.MonHocLopID
                                                           AND t5.MonHocLopID   = mhl.MonHocLopID
                                                           AND t5.MaNhomCotDiem = t.MaNhomCotDiem
                                                           AND t5.TinhTrang     = @TinhTrang
                                                           AND t5.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.MonHocLopID IN
               (
                   SELECT value
                   FROM
                         STRING_SPLIT(@List_MonHocLopID, ',') AS value
               ) -- Bên giao diện chỉ cần chọn 1 số môn lớp để gắn TinhTrang chứ ko cần phải gắn tình trạng hết môn
          AND  kqht.Enable    = 1;
    END;

    --6: Tổ trưởng Gửi BGH, => Do Tổ trưởng gửi hoặc từ chối là hết tất cả các môn của 1 lớp
    IF (@TinhTrang = 6)
    BEGIN
        --Chỉnh các Tình trạng trước cho Enable = 0
        UPDATE dbo.tblLop_TinhTrang
        SET    Enable = 0
             , UpdateUser = @SYS_UserID
             , UpdateTime = GETDATE()
        WHERE
               LopID    = @LopID
          AND  TinhTrang = @TinhTrang;

        -- Tạo bảng tạm để lưu ID của các bản ghi mới
        DECLARE @Table_Lop_TinhTrang_6 TABLE
        (
            Lop_TinhTrangID INT
        );

        -- Chèn dữ liệu mới vào tblLop_TinhTrang và lấy ID vào bảng tạm
        INSERT INTO dbo.tblLop_TinhTrang
        (
            LopID
          , MonHocLopID
          , MaNhomCotDiem
          , TinhTrang
          , NoiDungNhanXet
          , Is_GVCN_DaDuyet
          , Enable
          , CreateUser
          , CreateTime
        )
        OUTPUT Inserted.Lop_TinhTrangID
        INTO @Table_Lop_TinhTrang_6
        SELECT DISTINCT
               kqht.LopID
             , kqht.MonHocLopID
             , t.MaNhomCotDiem
             , @TinhTrang
             , NULL
             , 1
             , 1
             , @SYS_UserID
             , GETDATE()
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.Enable    = 1;

        -- Cập nhật Lop_TinhTrangID vào tblKetQuaHocTap
        UPDATE kqht
        SET    kqht.Lop_TinhTrangID = t6.Lop_TinhTrangID
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
               INNER JOIN dbo.tblLop_TinhTrang        AS t6 ON t6.LopID         = kqht.LopID
                                                           AND t6.MonHocLopID   = kqht.MonHocLopID
                                                           AND t6.MonHocLopID   = mhl.MonHocLopID
                                                           AND t6.MaNhomCotDiem = t.MaNhomCotDiem
                                                           AND t6.TinhTrang     = @TinhTrang
                                                           AND t6.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.Enable    = 1;
    END;

    --7: BGH từ chối,  
    IF (@TinhTrang = 7)
    BEGIN
        --Chỉnh các Tình trạng trước cho Enable = 0
        UPDATE dbo.tblLop_TinhTrang
        SET    Enable = 0
             , UpdateUser = @SYS_UserID
             , UpdateTime = GETDATE()
        WHERE
               LopID    = @LopID
          AND  TinhTrang = @TinhTrang;

        -- Tạo bảng tạm để lưu ID của các bản ghi mới
        DECLARE @Table_Lop_TinhTrang_7 TABLE
        (
            Lop_TinhTrangID INT
        );

        -- Chèn dữ liệu mới vào tblLop_TinhTrang và lấy ID vào bảng tạm
        INSERT INTO dbo.tblLop_TinhTrang
        (
            LopID
          , MonHocLopID
          , MaNhomCotDiem
          , TinhTrang
          , NoiDungNhanXet
          , Is_GVCN_DaDuyet
          , Enable
          , CreateUser
          , CreateTime
        )
        OUTPUT Inserted.Lop_TinhTrangID
        INTO @Table_Lop_TinhTrang_7
        SELECT DISTINCT
               kqht.LopID
             , kqht.MonHocLopID
             , t.MaNhomCotDiem
             , @TinhTrang
             , @ReasonReject
             , 1
             , 1
             , @SYS_UserID
             , GETDATE()
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.MonHocLopID IN
               (
                   SELECT value
                   FROM
                         STRING_SPLIT(@List_MonHocLopID, ',') AS value
               ) -- Bên giao diện chỉ cần chọn 1 số môn lớp để gắn TinhTrang chứ ko cần phải gắn tình trạng hết môn
          AND  kqht.Enable    = 1;

        -- Cập nhật Lop_TinhTrangID vào tblKetQuaHocTap
        UPDATE kqht
        SET    kqht.Lop_TinhTrangID = t7.Lop_TinhTrangID
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
               INNER JOIN dbo.tblLop_TinhTrang        AS t7 ON t7.LopID         = kqht.LopID
                                                           AND t7.MonHocLopID   = kqht.MonHocLopID
                                                           AND t7.MonHocLopID   = mhl.MonHocLopID
                                                           AND t7.MaNhomCotDiem = t.MaNhomCotDiem
                                                           AND t7.TinhTrang     = @TinhTrang
                                                           AND t7.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.MonHocLopID IN
               (
                   SELECT value
                   FROM
                         STRING_SPLIT(@List_MonHocLopID, ',') AS value
               ) -- Bên giao diện chỉ cần chọn 1 số môn lớp để gắn TinhTrang chứ ko cần phải gắn tình trạng hết môn
          AND  kqht.Enable    = 1;
    END;

    --8: BGH duyệt (Công bố phụ huynh)
    IF (@TinhTrang = 8)
    BEGIN
        --Chỉnh các Tình trạng trước cho Enable = 0
        UPDATE dbo.tblLop_TinhTrang
        SET    Enable = 0
             , UpdateUser = @SYS_UserID
             , UpdateTime = GETDATE()
        WHERE
               LopID    = @LopID
          AND  TinhTrang = @TinhTrang;

        -- Tạo bảng tạm để lưu ID của các bản ghi mới
        DECLARE @Table_Lop_TinhTrang_8 TABLE
        (
            Lop_TinhTrangID INT,
            LopID VARCHAR(10),
            MonHocLopID INT,
            MaNhomCotDiem NVARCHAR(100)
        );

        -- Chèn dữ liệu mới vào tblLop_TinhTrang và lấy ID vào bảng tạm
        INSERT INTO dbo.tblLop_TinhTrang
        (
            LopID
          , MonHocLopID
          , MaNhomCotDiem
          , TinhTrang
          , NoiDungNhanXet
          , Is_GVCN_DaDuyet
          , Enable
          , CreateUser
          , CreateTime
        )
        OUTPUT Inserted.Lop_TinhTrangID
             , Inserted.LopID
             , Inserted.MonHocLopID
             , Inserted.MaNhomCotDiem
        INTO @Table_Lop_TinhTrang_8
        SELECT DISTINCT
               kqht.LopID
             , kqht.MonHocLopID
             , t.MaNhomCotDiem
             , @TinhTrang
             , NULL
             , 1
             , 1
             , @SYS_UserID
             , GETDATE()
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.Enable    = 1;

        -- Cập nhật Lop_TinhTrangID vào tblKetQuaHocTap
        UPDATE kqht
        SET    kqht.Lop_TinhTrangID = t8.Lop_TinhTrangID
        FROM
               dbo.tblKetQuaHocTap                    AS kqht
               INNER JOIN dbo.TemplateBangDiemChiTiet AS t ON t.CotDiemID       = kqht.CotDiemID
                                                          AND t.MaNhomCotDiem LIKE '%' + @Suffix_Semester
                                                          AND t.Enable          = 1
               INNER JOIN dbo.tblMonHocLop            AS mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                                            AND mhl.LopNhomID   = kqht.LopID
                                                            AND mhl.Enable      = 1
               INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID      = mhl.MonHocID
                                                           AND mh.Enable        = 1
               INNER JOIN dbo.tblLop_TinhTrang        AS t8 ON t8.LopID         = kqht.LopID
                                                           AND t8.MonHocLopID   = kqht.MonHocLopID
                                                           AND t8.MonHocLopID   = mhl.MonHocLopID
                                                           AND t8.MaNhomCotDiem = t.MaNhomCotDiem
                                                           AND t8.TinhTrang     = @TinhTrang
                                                           AND t8.Enable        = 1
        WHERE
               kqht.NienKhoa = @NienKhoa
          AND  kqht.LopID     = @LopID
          AND  kqht.Enable    = 1;

        -- Chụp đầy đủ điểm sau khi gắn trạng thái 8 để các lần lưu nháp sau không đổi dữ liệu phụ huynh đang xem.
        INSERT INTO dbo.tbl_LOG_KetQuaHocTap
        (
            KQHTID,
            MonHocLopID,
            HocSinhID,
            LopID,
            NienKhoa,
            CotDiemID,
            KetQuaDanhGia_VI,
            KetQuaDanhGia_EN,
            Lop_TinhTrangID,
            TinhTrang,
            Is_Edit,
            Enable,
            CreateUser,
            CreateTime,
            UpdateUser,
            UpdateTime,
            NhapDiemUser,
            NhapDiemTime,
            KhoaCotDiemID,
            IsPublishedSnapshot
        )
        SELECT kqht.KQHTID,
               kqht.MonHocLopID,
               kqht.HocSinhID,
               kqht.LopID,
               kqht.NienKhoa,
               kqht.CotDiemID,
               kqht.KetQuaDanhGia_VI,
               kqht.KetQuaDanhGia_EN,
               kqht.Lop_TinhTrangID,
               kqht.TinhTrang,
               kqht.Is_Edit,
               kqht.Enable,
               kqht.CreateUser,
               kqht.CreateTime,
               kqht.UpdateUser,
               kqht.UpdateTime,
               kqht.NhapDiemUser,
               kqht.NhapDiemTime,
               kqht.KhoaCotDiemID,
               1
        FROM dbo.tblKetQuaHocTap AS kqht
        INNER JOIN @Table_Lop_TinhTrang_8 AS published
            ON published.Lop_TinhTrangID = kqht.Lop_TinhTrangID
           AND published.LopID = kqht.LopID
           AND published.MonHocLopID = kqht.MonHocLopID
        INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct
            ON tbdct.CotDiemID = kqht.CotDiemID
           AND tbdct.MaNhomCotDiem = published.MaNhomCotDiem
           AND tbdct.Enable = 1
        WHERE kqht.NienKhoa = @NienKhoa
          AND kqht.Enable = 1;
    END;
END;
