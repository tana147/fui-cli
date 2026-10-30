 --[dbo].[spAPI_AUTH_LMS_KetQuaHocTap]
 --@LoaiDiem  = 'TX',
 --@CapHoc = 2,
 --@HocKy = 'HK2'

CREATE PROC [dbo].[spAPI_AUTH_LMS_KetQuaHocTap]
    @LoaiDiem NVARCHAR(50) --C2_C3 TX, DiemGK, DiemCK, DiemTB
                           --C1 Diem, MucDoDanhGia, NhanXet
  , @CapHoc   INT
  , @HocKy    VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();

    DECLARE @Result TABLE
    (
        LopID        VARCHAR(40)
      , TenLop       NVARCHAR(50)
      , SoDanhBo     NVARCHAR(100)
      , HocSinhID    INT
      , MonHocCode   NVARCHAR(50)
      , LoaiDiem     NVARCHAR(20)
      , ThuTuNhom    INT
      , ThuTuCotDiem INT
      , MaCotDiem    NVARCHAR(100)
      , KetQua       NVARCHAR(MAX)
      , HocKy        NVARCHAR(100)
      , Sort         INT
    );

    -- Table to store LopIDs for looping
    DECLARE @LopList TABLE
    (
        LopID VARCHAR(40)
    );

    -- Get all LopIDs for the given CapHoc and NienKhoa
    INSERT INTO @LopList
    (
        LopID
    )
    SELECT LopID
    FROM
           dbo.tblLop
    WHERE
           CapID   = @CapHoc
      AND  NienKhoa = @NienKhoa
      AND  Enable   = 1;

    -- Declare cursor variables
    DECLARE @CurrentLopID VARCHAR(40);

    -- Create cursor to loop through each LopID
    DECLARE lop_cursor CURSOR FOR SELECT LopID FROM @LopList;

    OPEN lop_cursor;
    FETCH NEXT FROM lop_cursor
    INTO @CurrentLopID;

    -- Loop through each LopID
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Call the child stored procedure and insert results
        INSERT INTO @Result
        EXEC dbo.spAPI_AUTH_LMS_KetQuaHocTap_Lop @LopID = @CurrentLopID
                                               , @HocKy = @HocKy
                                               , @NienKhoa = @NienKhoa;

        FETCH NEXT FROM lop_cursor
        INTO @CurrentLopID;
    END;

    CLOSE lop_cursor;
    DEALLOCATE lop_cursor;

    -- Return the final result set
    SELECT LopID
         , TenLop
         , SoDanhBo
         , HocSinhID
         , MonHocCode
         , LoaiDiem
         , ThuTuNhom
         , ThuTuCotDiem
         , MaCotDiem
         , KetQua
         , HocKy
         , Sort
    FROM
           @Result
    WHERE
           LoaiDiem  = @LoaiDiem
       OR  (@LoaiDiem is NULL OR @LoaiDiem = '')
    ORDER BY
           Sort
         , LopID
         , HocSinhID;

END;
