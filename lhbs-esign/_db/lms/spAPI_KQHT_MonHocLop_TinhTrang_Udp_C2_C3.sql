CREATE PROC [dbo].[spAPI_KQHT_MonHocLop_TinhTrang_Udp_C2_C3]
@NienKhoa INT = 2024,
    @LopID         VARCHAR(10)
  , @MonHocLopID   INT
  , @MaNhomCotDiem VARCHAR(100)
  , @TinhTrang     INT
  , @ReasonReject  NVARCHAR(4000)
  , @SYS_USERID    VARCHAR(9)
AS
BEGIN
    --0: Chưa lưu
    --1: Lưu tạm
    --2: Gửi điểm BGH
    --3: Từ chối điểm
    --4: Duyệt điểm
    UPDATE dbo.tblLop_TinhTrang
    SET    Enable = 0
         , UpdateUser = @SYS_USERID
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

    INSERT INTO dbo.tblLop_TinhTrang
    (
        LopID
      , MonHocLopID
      , MaNhomCotDiem
      , TinhTrang
      , NoiDungNhanXet
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
      , @TinhTrang
      , @ReasonReject  -- NoiDungNhanXet - nvarchar(4000)
      , 1
      , @SYS_USERID    -- CreateUser - varchar(9)
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