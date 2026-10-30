CREATE PROC spAPI_spAPI_TemplateBangDiemChiTiet_DSCotDiem_Del_By_MaNhomCotDiem
    @TemplateBangDiemID INT
  , @MaNhomCotDiem      NVARCHAR(100)
  , @SYS_USERID         VARCHAR(9)
AS
BEGIN
    UPDATE dbo.TemplateBangDiemChiTiet
    SET    Enable = 0
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           TemplateBangDiemID = @TemplateBangDiemID
      AND  MaNhomCotDiem       = @MaNhomCotDiem;
END;