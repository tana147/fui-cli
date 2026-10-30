--[dbo].[spAPI_XepBangDiem_ChuyenLop_ByHocSinhID] 19100221 , 'N251005'
CREATE PROC [dbo].[spAPI_XepBangDiem_ChuyenLop_ByHocSinhID]
    @HocSinhID     INT
  , @NhomID_Chuyen NVARCHAR(50)
  , @NienKhoa      INT
  , @MonHocID      INT
  , @SYS_USERID    VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TemplateBangDiemID_Current INT           = 0
          , @TemplateBangDiemID_Chuyen  INT           = 0
          , @NhomID_Current             NVARCHAR(50)  = N''
          , @MonHocLopID_Chuyen         INT           = 0
          , @IsSameTemplate             BIT           = 0
          , @MsgError                   NVARCHAR(MAX) = N'';

    ------------------------------------------------------------
    -- 🔹 Lấy nhóm hiện tại của học sinh
    ------------------------------------------------------------
    SELECT TOP 1
           @NhomID_Current = hsn.NhomID
    FROM
           dbo.tblHocSinhNhom hsn
           JOIN dbo.tblNhom   n ON n.NhomID   = hsn.NhomID
                               AND n.NienKhoa = @NienKhoa
                               AND n.MonHocID = @MonHocID
    WHERE
           hsn.Enable   = 1
      AND  hsn.HocSinhID = @HocSinhID;

    SELECT TOP 1
           @MonHocLopID_Chuyen = MonHocLopID
    FROM
           dbo.tblMonHocLop
    WHERE
           LopNhomID = @NhomID_Chuyen
      AND  NienKhoa   = @NienKhoa
      AND  Enable     = 1;

    IF (@NhomID_Current IS NULL)
    BEGIN
        SET @MsgError = N'Học sinh chưa thuộc nhóm nào trong niên khóa ' + CAST(@NienKhoa AS NVARCHAR);
        RAISERROR(@MsgError, 16, 1);
        RETURN;
    END;

    ------------------------------------------------------------
    -- 🔹 Lấy TemplateBangDiemID của nhóm hiện tại
    ------------------------------------------------------------
    SELECT TOP 1
           @TemplateBangDiemID_Current = ml.TemplateBangDiemID
    FROM
           dbo.tblNhom           n
           JOIN dbo.tblMonHocLop ml ON ml.LopNhomID = n.NhomID
    WHERE
           n.NhomID = @NhomID_Current;

    ------------------------------------------------------------
    -- 🔹 Lấy TemplateBangDiemID của nhóm chuyển đến
    ------------------------------------------------------------
    SELECT @TemplateBangDiemID_Chuyen = ml.TemplateBangDiemID
    FROM
           dbo.tblNhom           n
           JOIN dbo.tblMonHocLop ml ON ml.LopNhomID = n.NhomID
    WHERE
           n.NhomID = @NhomID_Chuyen;

    ------------------------------------------------------------
    -- 🔹 Kiểm tra điều kiện
    ------------------------------------------------------------
    IF (@NhomID_Current = @NhomID_Chuyen)
    BEGIN
        SET @MsgError = N'Bạn đang chọn cùng nhóm';
        RAISERROR(@MsgError, 16, 1);
        RETURN;
    END;
    ------------------------------------------------------------
    -- 🔹 Tiến hành map & copy điểm (khi Template khác nhau)
    ------------------------------------------------------------
    DECLARE @Table TABLE
    (
        HocSinhID        INT
      , MonHocLopID      INT
      , CotDiemID_New    INT
      , MaCotDiem_New    NVARCHAR(200)
      , CotDiemID_Old    INT
      , MaCotDiem_Old    NVARCHAR(200)
      , KetQuaDanhGia_VI NVARCHAR(4000)
      , Lop_TinhTrangID  INT
      , ThuTuNhom        INT
      , ThuTuCotDiem     INT
    );

    IF (@MonHocID = 76)
    BEGIN
        INSERT INTO @Table
        SELECT kqht.HocSinhID
             , @MonHocLopID_Chuyen AS MonHocLopID
             , ct_new.CotDiemID
             , ct_new.MaCotDiem
             , ct_old.CotDiemID
             , ct_old.MaCotDiem
             , kqht.KetQuaDanhGia_VI
             , (
                   SELECT TOP 1
                          Lop_TinhTrangID
                   FROM
                          dbo.tblLop_TinhTrang
                   WHERE
                          Enable       = 1
                     AND  MaNhomCotDiem = ct_new.MaNhomCotDiem
                     AND  MonHocLopID   = @MonHocLopID_Chuyen
                   ORDER BY
                          Lop_TinhTrangID DESC
               )                   AS Lop_TinhTrangID
             , ct_old.ThuTuNhom
             , ct_old.ThuTuCotDiem
        FROM
               dbo.tblKetQuaHocTap              kqht
               JOIN dbo.TemplateBangDiemChiTiet ct_old ON ct_old.CotDiemID          = kqht.CotDiemID
                                                      AND ct_old.Enable             = 1
               JOIN dbo.TemplateBangDiemChiTiet ct_new ON ct_new.MaCotDiem          = ct_old.MaCotDiem
                                                      AND ct_new.TemplateBangDiemID = @TemplateBangDiemID_Chuyen
                                                      AND ct_new.Enable             = 1
               JOIN dbo.tblMonHocLop            mhl ON mhl.MonHocLopID              = kqht.MonHocLopID
                                                   AND mhl.NienKhoa                 = @NienKhoa
                                                   AND mhl.Enable                   = 1
                                                   AND mhl.MonHocID                 = @MonHocID
        WHERE
               kqht.HocSinhID = @HocSinhID
          AND  kqht.Enable     = 1
          AND  kqht.NienKhoa   = @NienKhoa;
    END;
    ELSE
    BEGIN
        INSERT INTO @Table
        SELECT kqht.HocSinhID
             , @MonHocLopID_Chuyen AS MonHocLopID
             , ct_new.CotDiemID
             , ct_new.MaCotDiem
             , ct_old.CotDiemID
             , ct_old.MaCotDiem
             , kqht.KetQuaDanhGia_VI
             , kqht.Lop_TinhTrangID
             , ct_old.ThuTuNhom
             , ct_old.ThuTuCotDiem
        FROM
               dbo.tblKetQuaHocTap              kqht
               JOIN dbo.TemplateBangDiemChiTiet ct_old ON ct_old.CotDiemID          = kqht.CotDiemID
                                                      AND ct_old.Enable             = 1
               JOIN dbo.TemplateBangDiemChiTiet ct_new ON ct_new.MaCotDiem          = ct_old.MaCotDiem
                                                      AND ct_new.CotDiemID          = ct_old.CotDiemID
                                                      AND ct_new.TemplateBangDiemID = @TemplateBangDiemID_Chuyen
                                                      AND ct_new.Enable             = 1
        WHERE
               kqht.HocSinhID = @HocSinhID
          AND  kqht.Enable     = 1
          AND  kqht.NienKhoa   = @NienKhoa;
    END;

    ------------------------------------------------------------
    -- 🔹 Xuất kết quả (debug hoặc insert thật)
    ------------------------------------------------------------
    INSERT INTO dbo.tblKetQuaHocTap
    (
        MonHocLopID
      , HocSinhID
      , LopID
      , NienKhoa
      , CotDiemID
      , KetQuaDanhGia_VI
      , KetQuaDanhGia_EN
      , Lop_TinhTrangID
      , Enable
      , CreateUser
      , CreateTime
      , NhapDiemUser
      , NhapDiemTime
    )
    SELECT MonHocLopID
         , HocSinhID
         , @NhomID_Chuyen   AS LopID
         , @NienKhoa        AS NienKhoa
         , CotDiemID_New    AS CotDiemID
         , KetQuaDanhGia_VI
         , KetQuaDanhGia_VI AS KetQuaDanhGia_EN
         , Lop_TinhTrangID
         , 1                AS [Enable]
         , @SYS_USERID      AS CreateUser
         , GETDATE()        AS CreateTime
         , @SYS_USERID      AS NhapDiemUser
         , GETDATE()        AS NhapDiemTime
    FROM
           @Table;
END;
