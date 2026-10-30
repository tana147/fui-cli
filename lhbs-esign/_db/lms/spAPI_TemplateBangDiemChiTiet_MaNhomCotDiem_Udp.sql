CREATE PROC [dbo].[spAPI_TemplateBangDiemChiTiet_MaNhomCotDiem_Udp]
    @TemplateBangDiemID    INT
  -----
  , @MaNhomCotDiem         NVARCHAR(50)
  , @MaNhomCotDiem_Udp     NVARCHAR(50)
  , @TenNhomCotDiem_VI_Udp NVARCHAR(500)
  , @TenNhomCotDiem_EN_Udp NVARCHAR(500)
  , @ThuTuNhom_Udp         INT
  , @Semester_Udp          VARCHAR(3)
  , @SYS_USERID            VARCHAR(9)
AS
BEGIN
    DECLARE @Table TABLE
    (
        CotDiemID INT
    );
    INSERT INTO @Table
    (
        CotDiemID
    )
    SELECT CotDiemID
    FROM
           dbo.TemplateBangDiemChiTiet
    WHERE
           TemplateBangDiemID = @TemplateBangDiemID
      AND  MaNhomCotDiem       = @MaNhomCotDiem;

    UPDATE dbo.TemplateBangDiemChiTiet
    SET    ThuTuNhom = @ThuTuNhom_Udp
         , MaNhomCotDiem = @MaNhomCotDiem_Udp
         , TenNhomCotDiem_VI = @TenNhomCotDiem_VI_Udp
         , TenNhomCotDiem_EN = @TenNhomCotDiem_EN_Udp
         , Semester = @Semester_Udp
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    FROM
           dbo.TemplateBangDiemChiTiet AS tbdct
           INNER JOIN @Table           AS t ON t.CotDiemID = tbdct.CotDiemID;
END;
